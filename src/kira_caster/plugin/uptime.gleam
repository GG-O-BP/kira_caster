import gleam/int
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/util/time

pub fn new(start_time_ms: Int) -> Plugin {
  Plugin(name: "uptime", handle_event: fn(event) {
    handle(start_time_ms, event)
  })
}

fn handle(start_time_ms: Int, event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "업타임", args: _, role: _) -> {
      let elapsed_s = { time.now_ms() - start_time_ms } / 1000
      let hours = elapsed_s / 3600
      let minutes = { elapsed_s % 3600 } / 60
      let seconds = elapsed_s % 60
      let msg =
        "가동 시간: "
        <> int.to_string(hours)
        <> "시간 "
        <> int.to_string(minutes)
        <> "분 "
        <> int.to_string(seconds)
        <> "초"
      [plugin.PluginResponse(plugin: "uptime", message: msg)]
    }
    _ -> []
  }
}
