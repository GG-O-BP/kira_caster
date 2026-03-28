import gleam/io
import gleam/result
import kira_caster/event_bus
import kira_caster/platform/mock_adapter
import kira_caster/plugin/attendance
import kira_caster/plugin/filter
import kira_caster/plugin/minigame
import kira_caster/plugin/plugin
import kira_caster/plugin/points
import kira_caster/storage/sqlight_repo

pub fn main() -> Nil {
  case start() {
    Ok(Nil) -> io.println("kira_caster running")
    Error(reason) -> io.println("Startup failed: " <> reason)
  }
}

fn start() -> Result(Nil, String) {
  use repo <- result.try(
    sqlight_repo.new("kira_caster.db")
    |> result.map_error(fn(_) { "Failed to open database" }),
  )
  use started <- result.try(
    event_bus.start()
    |> result.map_error(fn(_) { "Failed to start event bus" }),
  )
  let bus = started.data

  event_bus.subscribe(bus, attendance.new(repo))
  event_bus.subscribe(bus, points.new(repo))
  event_bus.subscribe(bus, minigame.new())
  event_bus.subscribe(bus, filter.default())

  let adapter = mock_adapter.new()
  use _ <- result.try(
    adapter.connect()
    |> result.map_error(fn(_) { "Failed to connect adapter" }),
  )

  event_bus.set_response_handler(bus, fn(event) {
    case event {
      plugin.PluginResponse(_, message) -> {
        let _ = adapter.send_message(message)
        Nil
      }
      _ -> Nil
    }
  })

  io.println("kira_caster started with mock adapter")

  event_bus.dispatch(bus, plugin.Command(user: "alice", name: "출석", args: []))
  event_bus.dispatch(bus, plugin.Command(user: "bob", name: "포인트", args: []))
  event_bus.dispatch(
    bus,
    plugin.Command(user: "charlie", name: "게임", args: ["주사위"]),
  )
  event_bus.dispatch(
    bus,
    plugin.ChatMessage(user: "spammer", content: "spam spam", channel: "main"),
  )

  Ok(Nil)
}
