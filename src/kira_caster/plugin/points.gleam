import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "points", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "포인트", args: _) ->
      todo as "points: implement with storage repository"
    _ -> []
  }
}
