import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/donation_alert
import kira_caster/plugin/plugin
import kira_caster/storage/repository

pub fn named_user_donation_formats_alert_test() {
  let repo = repository.mock_repo([])
  let p = donation_alert.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Donation(
        user: "alice",
        channel_id: option.Some("ch123"),
        amount: "10000",
        message: "응원!",
        donation_type: "CHAT",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "donation_alert", message: msg)] =
    events
  let assert True = msg == "alice님이 10000빔을 후원했습니다! \"응원!\""
}

pub fn anonymous_donation_shows_anonymous_test() {
  let repo = repository.mock_repo([])
  let p = donation_alert.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Donation(
        user: "someone",
        channel_id: option.None,
        amount: "5000",
        message: "화이팅",
        donation_type: "CHAT",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "donation_alert", message: msg)] =
    events
  let assert True = msg == "익명님이 5000빔을 후원했습니다! \"화이팅\""
}

pub fn video_donation_shows_label_test() {
  let repo = repository.mock_repo([])
  let p = donation_alert.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Donation(
        user: "bob",
        channel_id: option.Some("ch456"),
        amount: "20000",
        message: "",
        donation_type: "VIDEO",
      ),
    )
  let assert [plugin.PluginResponse(plugin: "donation_alert", message: msg)] =
    events
  let assert True = msg == "bob님이 20000빔을 후원했습니다! (영상 후원)"
}

pub fn ranking_command_empty_test() {
  let repo = repository.mock_repo([])
  let p = donation_alert.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "후원순위",
        args: [],
        role: permission.Viewer,
      ),
    )
  let assert [plugin.PluginResponse(plugin: "donation_alert", message: msg)] =
    events
  let assert True = msg == "후원 기록이 없습니다."
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = donation_alert.new(repo)
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
