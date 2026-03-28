import gleam/list
import kira_caster/core/permission
import kira_caster/plugin/minigame
import kira_caster/plugin/plugin

pub fn dice_game_returns_response_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "게임",
        args: ["주사위"],
        role: permission.Viewer,
      ),
    )
  // Win/loss: 2 events (PluginResponse + PointsChange), draw: 1 event
  let len = list.length(events)
  assert len == 1 || len == 2
  case events {
    [plugin.PluginResponse(plugin: "minigame", message: _), ..] -> Nil
    _ -> panic as "Expected PluginResponse from minigame as first event"
  }
}

pub fn help_message_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "게임",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "minigame",
        message: "사용법: !게임 주사위 / !게임 가위바위보 <가위|바위|보>",
      ),
    ]
}

pub fn unknown_game_shows_help_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "게임",
        args: ["unknown"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "minigame",
        message: "사용법: !게임 주사위 / !게임 가위바위보 <가위|바위|보>",
      ),
    ]
}

pub fn rps_valid_choice_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "게임",
        args: ["가위바위보", "가위"],
        role: permission.Viewer,
      ),
    )
  let len = list.length(events)
  assert len == 1 || len == 2
  case events {
    [plugin.PluginResponse(plugin: "minigame", message: _), ..] -> Nil
    _ -> panic as "Expected PluginResponse from minigame"
  }
}

pub fn rps_invalid_choice_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "게임",
        args: ["가위바위보", "돌"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "minigame",
        message: "가위, 바위, 보 중 하나를 선택해주세요.",
      ),
    ]
}

pub fn rps_rock_returns_response_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "bob",
        name: "게임",
        args: ["가위바위보", "바위"],
        role: permission.Viewer,
      ),
    )
  let len = list.length(events)
  assert len == 1 || len == 2
}

pub fn rps_paper_returns_response_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "charlie",
        name: "게임",
        args: ["가위바위보", "보"],
        role: permission.Viewer,
      ),
    )
  let len = list.length(events)
  assert len == 1 || len == 2
}

pub fn unrelated_event_ignored_test() {
  let p = minigame.new(50, -20, 30, -10)
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}
