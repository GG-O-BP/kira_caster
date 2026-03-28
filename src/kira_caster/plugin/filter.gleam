import gleam/list
import gleam/string
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new(banned_words: List(String)) -> Plugin {
  Plugin(name: "filter", handle_event: fn(event) { handle(banned_words, event) })
}

pub fn default() -> Plugin {
  new(["spam", "홍보", "광고"])
}

fn handle(banned_words: List(String), event: Event) -> List(Event) {
  case event {
    plugin.ChatMessage(user:, content:, channel: _) ->
      case contains_banned_word(content, banned_words) {
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

fn contains_banned_word(content: String, banned_words: List(String)) -> Bool {
  let lower = string.lowercase(content)
  list.any(banned_words, fn(word) { string.contains(lower, word) })
}
