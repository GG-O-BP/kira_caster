import gleam/erlang/process
import gleam/list
import gleam/result
import kira_caster/admin/server as admin_server
import kira_caster/config_loader
import kira_caster/core/permission
import kira_caster/event_bus
import kira_caster/logger
import kira_caster/platform/mock_adapter
import kira_caster/plugin/attendance
import kira_caster/plugin/custom_command
import kira_caster/plugin/filter
import kira_caster/plugin/minigame
import kira_caster/plugin/plugin
import kira_caster/plugin/points
import kira_caster/plugin/uptime
import kira_caster/plugin_registry.{type PluginRegistry}
import kira_caster/storage/sqlight_repo
import kira_caster/supervisor
import kira_caster/util/time

pub fn main() -> Nil {
  case start() {
    Ok(Nil) -> logger.info("kira_caster running")
    Error(reason) -> logger.error("Startup failed: " <> reason)
  }
}

fn start() -> Result(Nil, String) {
  let config = config_loader.load()
  let start_time = time.now_ms()

  use repo <- result.try(
    sqlight_repo.new(config.db_path)
    |> result.map_error(fn(_) { "Failed to open database" }),
  )
  use #(_sup, bus, bus_name) <- result.try(
    supervisor.start(config)
    |> result.map_error(fn(_) { "Failed to start supervisor" }),
  )

  let registry =
    plugin_registry.new()
    |> plugin_registry.register(fn() {
      attendance.new(repo, config.attendance_points)
    })
    |> plugin_registry.register(fn() { points.new(repo) })
    |> plugin_registry.register(fn() {
      minigame.new(
        config.dice_win_points,
        config.dice_loss_points,
        config.rps_win_points,
        config.rps_loss_points,
      )
    })
    |> plugin_registry.register(fn() {
      filter.default(repo, config.default_banned_words)
    })
    |> plugin_registry.register(fn() { custom_command.new(repo) })
    |> plugin_registry.register(fn() { uptime.new(start_time) })

  let adapter = mock_adapter.new()
  use _ <- result.try(
    adapter.connect()
    |> result.map_error(fn(_) { "Failed to connect adapter" }),
  )

  let make_response_handler = fn() {
    fn(event: plugin.Event) {
      case event {
        plugin.PluginResponse(_, message) -> {
          let _ = adapter.send_message(message)
          Nil
        }
        _ -> Nil
      }
    }
  }

  subscribe_all(bus, registry, make_response_handler)

  let bus_pid = event_bus.get_pid(bus)
  process.spawn(fn() {
    watch_bus(bus_pid, bus_name, registry, make_response_handler)
  })

  case admin_server.start(repo, config, start_time) {
    Ok(Nil) -> Nil
    Error(e) -> logger.warn("Admin dashboard failed: " <> e)
  }

  logger.info("kira_caster started with mock adapter")

  event_bus.dispatch(
    bus,
    plugin.Command(user: "alice", name: "출석", args: [], role: permission.Viewer),
  )
  event_bus.dispatch(
    bus,
    plugin.Command(user: "bob", name: "포인트", args: [], role: permission.Viewer),
  )
  event_bus.dispatch(
    bus,
    plugin.Command(
      user: "charlie",
      name: "게임",
      args: ["가위바위보", "바위"],
      role: permission.Viewer,
    ),
  )
  event_bus.dispatch(
    bus,
    plugin.Command(user: "dave", name: "업타임", args: [], role: permission.Viewer),
  )

  process.sleep(100)
  Ok(Nil)
}

fn subscribe_all(
  bus: process.Subject(event_bus.EventBusMessage),
  registry: PluginRegistry,
  make_response_handler: fn() -> fn(plugin.Event) -> Nil,
) -> Nil {
  let plugins = plugin_registry.build_plugins(registry)
  list.each(plugins, fn(p) { event_bus.subscribe(bus, p) })
  event_bus.set_response_handler(bus, make_response_handler())
}

fn watch_bus(
  bus_pid: process.Pid,
  bus_name: process.Name(event_bus.EventBusMessage),
  registry: PluginRegistry,
  make_response_handler: fn() -> fn(plugin.Event) -> Nil,
) -> Nil {
  let _monitor = process.monitor(bus_pid)
  let selector =
    process.new_selector()
    |> process.select_monitors(fn(down) { down })
  let _down = process.selector_receive_forever(selector)

  logger.warn("Event bus restarted, re-subscribing plugins...")
  process.sleep(200)

  let new_bus = process.named_subject(bus_name)
  subscribe_all(new_bus, registry, make_response_handler)

  let new_pid = event_bus.get_pid(new_bus)
  watch_bus(new_pid, bus_name, registry, make_response_handler)
}
