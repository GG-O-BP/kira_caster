import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/quiz
import kira_caster/storage/repository

pub fn quiz_start_moderator_test() {
  let repo = repository.mock_repo([])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "퀴즈",
        args: ["시작"],
        role: permission.Moderator,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "quiz", message: msg)] -> {
      assert {
        case msg {
          "퀴즈! " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse with quiz question"
  }
}

pub fn quiz_start_viewer_denied_test() {
  let repo = repository.mock_repo([])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "퀴즈",
        args: ["시작"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "quiz", message: "권한이 없습니다. (관리자 전용)"),
    ]
}

pub fn quiz_answer_no_active_test() {
  let repo = repository.mock_repo([])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "퀴즈",
        args: ["서울"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "quiz", message: "현재 진행 중인 퀴즈가 없습니다."),
    ]
}

pub fn quiz_answer_correct_test() {
  let repo =
    repository.mock_repo_with_commands([], [#("__quiz_answer", "서울|20")])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "퀴즈",
        args: ["서울"],
        role: permission.Viewer,
      ),
    )
  case events {
    [
      plugin.PluginResponse(plugin: "quiz", message: msg),
      plugin.PointsChange(user: "alice", amount: 20, reason: "quiz"),
    ] -> {
      assert {
        case msg {
          "alice" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected PluginResponse + PointsChange"
  }
}

pub fn quiz_answer_wrong_ignored_test() {
  let repo =
    repository.mock_repo_with_commands([], [#("__quiz_answer", "서울|20")])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "퀴즈",
        args: ["부산"],
        role: permission.Viewer,
      ),
    )
  assert events == []
}

pub fn help_message_test() {
  let repo = repository.mock_repo([])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "퀴즈",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "quiz", message: "사용법: !퀴즈 시작 / !퀴즈 <답>"),
    ]
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = quiz.new(repo)
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
  assert events == []
}

pub fn quiz_answer_case_insensitive_test() {
  let repo =
    repository.mock_repo_with_commands([], [#("__quiz_answer", "Seoul|20")])
  let p = quiz.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "퀴즈",
        args: ["SEOUL"],
        role: permission.Viewer,
      ),
    )
  case events {
    [
      plugin.PluginResponse(plugin: "quiz", message: _),
      plugin.PointsChange(user: "alice", amount: 20, reason: "quiz"),
    ] -> Nil
    _ ->
      panic as "Expected case-insensitive match with PluginResponse + PointsChange"
  }
}
