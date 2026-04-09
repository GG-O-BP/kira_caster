import gleam/option
import kira_caster/plugin/plugin
import kira_caster/plugin/subscription_alert

pub fn first_subscription_shows_first_test() {
  let p = subscription_alert.new()
  let events =
    plugin.handle(
      p,
      plugin.Subscription(
        user: "bob",
        channel_id: "ch456",
        month: 1,
        tier: 1,
        message: "구독합니다!",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "subscription_alert", message: msg)] =
    events
  let assert True = msg == "bob님이 첫 구독! \"구독합니다!\""
}

pub fn multi_month_shows_consecutive_test() {
  let p = subscription_alert.new()
  let events =
    plugin.handle(
      p,
      plugin.Subscription(
        user: "charlie",
        channel_id: "ch789",
        month: 3,
        tier: 1,
        message: "",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "subscription_alert", message: msg)] =
    events
  let assert True = msg == "charlie님이 3개월 연속 구독!"
}

pub fn tier_above_one_shows_tier_info_test() {
  let p = subscription_alert.new()
  let events =
    plugin.handle(
      p,
      plugin.Subscription(
        user: "dave",
        channel_id: "ch101",
        month: 2,
        tier: 3,
        message: "",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "subscription_alert", message: msg)] =
    events
  let assert True = msg == "dave님이 2개월 연속 구독 (3티어)!"
}

pub fn long_term_subscriber_shows_special_test() {
  let p = subscription_alert.new()
  let events =
    plugin.handle(
      p,
      plugin.Subscription(
        user: "eve",
        channel_id: "ch202",
        month: 6,
        tier: 1,
        message: "오래 봤네요",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "subscription_alert", message: msg)] =
    events
  let assert True = msg == "eve님이 6개월 연속 구독! 장기 구독자입니다! \"오래 봤네요\""
}

pub fn unrelated_event_ignored_test() {
  let p = subscription_alert.new()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "hello",
        channel: "main",
        channel_id: option.None,
      ),
    )
  let assert [] = events
}
