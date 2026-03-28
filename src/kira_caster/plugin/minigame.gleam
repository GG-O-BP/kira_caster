import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "minigame", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "게임", args: _) ->
      todo as "minigame: implement game logic"
    _ -> []
  }
}
