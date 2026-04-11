import gleam/int
import gleam/string
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "subscription_alert", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.Subscription(user:, channel_id: _, month:, tier:, message:) ->
      handle_subscription(user, month, tier, message)
    _ -> []
  }
}

fn handle_subscription(
  user: String,
  month: Int,
  tier: Int,
  message: String,
) -> List(Event) {
  let tier_text = case tier {
    1 -> ""
    n -> " (" <> int.to_string(n) <> "티어)"
  }

  let duration_text = case month {
    1 -> "첫 구독이당"
    n -> int.to_string(n) <> "개월 연속 구독이에용"
  }

  let special = case month >= 6 {
    True -> " 완전 오래 구독해줬당 ㅎㅎ!"
    False -> ""
  }

  let msg_text = case string.is_empty(message) {
    True -> ""
    False -> " \"" <> message <> "\""
  }

  let alert =
    user <> "님이 " <> duration_text <> tier_text <> "!" <> special <> msg_text

  [plugin.PluginResponse(plugin: "subscription_alert", message: alert)]
}
