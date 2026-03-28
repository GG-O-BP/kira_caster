import gleam/list
import kira_caster/plugin/minigame
import kira_caster/plugin/plugin

pub fn dice_game_returns_response_test() {
  let p = minigame.new()
  let events =
    plugin.handle(p, plugin.Command(user: "alice", name: "게임", args: ["주사위"]))
  assert list.length(events) == 1
  case events {
    [plugin.PluginResponse(plugin: "minigame", message: _)] -> Nil
    _ -> panic as "Expected PluginResponse from minigame"
  }
}

pub fn help_message_test() {
  let p = minigame.new()
  let events =
    plugin.handle(p, plugin.Command(user: "alice", name: "게임", args: []))
  assert events
    == [
      plugin.PluginResponse(plugin: "minigame", message: "사용법: !게임 주사위"),
    ]
}

pub fn unknown_game_shows_help_test() {
  let p = minigame.new()
  let events =
    plugin.handle(
      p,
      plugin.Command(user: "alice", name: "게임", args: ["unknown"]),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "minigame", message: "사용법: !게임 주사위"),
    ]
}

pub fn unrelated_event_ignored_test() {
  let p = minigame.new()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}
