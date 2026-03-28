import gleam/string
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "filter", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.ChatMessage(user:, content:, channel: _) ->
      case contains_banned_word(content) {
        True -> [
          plugin.SystemEvent(
            kind: "filter_blocked",
            data: "Message from " <> user <> " blocked",
          ),
        ]
        False -> []
      }
    _ -> []
  }
}

fn contains_banned_word(content: String) -> Bool {
  let lower = string.lowercase(content)
  string.contains(lower, "spam")
}
