import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "attendance", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.Command(user:, name: "출석", args: _) -> [
      plugin.PluginResponse(plugin: "attendance", message: user <> " 출석 완료!"),
    ]
    _ -> []
  }
}
