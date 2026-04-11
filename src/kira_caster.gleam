import gleam/erlang/process
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import kira_caster/admin/router
import kira_caster/admin/server as admin_server
import kira_caster/config_loader
import kira_caster/core/permission
import kira_caster/event_bus
import kira_caster/logger
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime_adapter
import kira_caster/platform/mock_adapter
import kira_caster/plugin/attendance
import kira_caster/plugin/block
import kira_caster/plugin/broadcast_control
import kira_caster/plugin/custom_command
import kira_caster/plugin/donation_alert
import kira_caster/plugin/filter
import kira_caster/plugin/follower
import kira_caster/plugin/minigame
import kira_caster/plugin/plugin
import kira_caster/plugin/points
import kira_caster/plugin/quiz
import kira_caster/plugin/roulette
import kira_caster/plugin/song_request
import kira_caster/plugin/subscription_alert
import kira_caster/plugin/timer
import kira_caster/plugin/uptime
import kira_caster/plugin/vote
import kira_caster/plugin_registry.{type PluginRegistry}
import kira_caster/storage/repository
import kira_caster/storage/sqlight_repo
import kira_caster/supervisor
import kira_caster/util/time

pub fn main() -> Nil {
  case start() {
    Ok(Nil) -> logger.info("kira_caster running")
    Error(reason) -> {
      logger.error("앗 시작 실패했어 ㅠㅠ: " <> reason)
      logger.error("해결 방법: .env 파일이나 환경변수 확인해줘용")
    }
  }
}

fn start() -> Result(Nil, String) {
  let base_config = config_loader.load()
  let start_time = time.now_ms()

  use repo <- result.try(
    sqlight_repo.new(base_config.db_path)
    |> result.map_error(fn(_) {
      "앗 데이터베이스를 못 열었어 ㅠㅠ (경로: "
      <> base_config.db_path
      <> "). 파일 경로랑 쓰기 권한 확인해줘용"
    }),
  )

  // DB에 저장된 설정을 config에 병합 (DB 설정이 우선, 없으면 환경변수/기본값)
  let config = config_loader.apply_db_settings(base_config, repo)

  use #(_sup, bus, bus_name) <- result.try(
    supervisor.start(config)
    |> result.map_error(fn(_) {
      "앗 내부 서비스를 못 켰어 ㅠㅠ Erlang/OTP가 잘 설치됐는지 확인해줘용"
    }),
  )

  // Adapter selection: cime or mock
  let #(adapter, cime_api, get_token, token_mgr, ws_mgr) = case
    config.cime_client_id
  {
    "" -> {
      logger.info("CIME_CLIENT_ID not set, using mock adapter")
      let adapter = mock_adapter.new()
      #(adapter, None, None, None, None)
    }
    _ -> {
      logger.info("CIME credentials found, connecting to ci.me...")
      case cime_adapter.new(config, repo, bus) {
        Ok(conn) -> {
          logger.info("ci.me adapter initialized")
          #(
            conn.adapter,
            Some(conn.api),
            Some(conn.get_token),
            Some(conn.token_manager),
            Some(conn.ws_manager),
          )
        }
        Error(reason) -> {
          logger.warn(
            "ci.me adapter failed: " <> reason <> ", falling back to mock",
          )
          let adapter = mock_adapter.new()
          #(adapter, None, None, None, None)
        }
      }
    }
  }

  use _ <- result.try(
    adapter.connect()
    |> result.map_error(fn(_) { "앗 어댑터 연결이 안 됐어 ㅠㅠ 네트워크 확인해줘용" }),
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
    |> plugin_registry.register(fn() { vote.new(repo) })
    |> plugin_registry.register(fn() { roulette.new() })
    |> plugin_registry.register(fn() { quiz.new(repo) })
    |> plugin_registry.register(fn() { timer.new(make_response_handler()) })
    |> plugin_registry.register(fn() {
      song_request.new(repo, config.youtube_api_key)
    })
    // Always register event-based plugins
    |> plugin_registry.register(fn() { donation_alert.new(repo) })
    |> plugin_registry.register(fn() { subscription_alert.new() })
    // Register cime-dependent plugins when available
    |> register_cime_plugins(cime_api, get_token, repo, config.cime_channel_id)

  subscribe_all(bus, registry, make_response_handler)

  // Load disabled plugins from DB
  case repo.get_disabled_plugins() {
    Ok(disabled) -> event_bus.set_disabled_plugins(bus, disabled)
    Error(_) -> Nil
  }

  let bus_pid = event_bus.get_pid(bus)
  process.spawn(fn() {
    watch_bus(bus_pid, bus_name, registry, make_response_handler)
  })

  let router_ctx =
    router.RouterContext(
      repo:,
      start_time:,
      admin_key: config.admin_key,
      config:,
      bus: Some(bus),
      token_manager: token_mgr,
      cime_api:,
      get_token:,
      ws_manager: ws_mgr,
    )

  case admin_server.start(router_ctx, config) {
    Ok(Nil) -> Nil
    Error(e) -> logger.warn("Admin dashboard failed: " <> e)
  }

  case cime_api {
    Some(_) -> logger.info("kira_caster started with ci.me adapter")
    None -> {
      logger.info("kira_caster started with mock adapter")
      // Dispatch test commands in mock mode (すとぷり members)
      list.each(["나나모리", "제루", "리누", "사토미", "코론", "루토"], fn(member) {
        event_bus.dispatch(
          bus,
          plugin.Command(
            user: member,
            name: "출석",
            args: [],
            role: permission.Viewer,
          ),
        )
      })
      event_bus.dispatch(
        bus,
        plugin.Command(
          user: "제루",
          name: "포인트",
          args: [],
          role: permission.Viewer,
        ),
      )
    }
  }

  process.sleep(100)
  process.sleep_forever()
  Ok(Nil)
}

fn register_cime_plugins(
  registry: PluginRegistry,
  cime_api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
  repo: repository.Repository,
  channel_id: String,
) -> PluginRegistry {
  case cime_api, get_token {
    Some(api), Some(gt) ->
      registry
      |> plugin_registry.register(fn() {
        broadcast_control.new(gt, api, channel_id)
      })
      |> plugin_registry.register(fn() { block.new(gt, api) })
      |> plugin_registry.register(fn() { follower.new(repo, gt, api) })
    _, _ -> registry
  }
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
