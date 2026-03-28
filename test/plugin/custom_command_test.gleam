import kira_caster/core/permission
import kira_caster/plugin/custom_command
import kira_caster/plugin/plugin
import kira_caster/storage/repository

pub fn moderator_add_command_test() {
  let repo = repository.mock_repo([])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "명령",
        args: ["추가", "인사", "안녕하세요!"],
        role: permission.Moderator,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "'인사' 명령이 등록되었습니다.",
      ),
    ]
}

pub fn viewer_cannot_add_command_test() {
  let repo = repository.mock_repo([])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "명령",
        args: ["추가", "test", "response"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "권한이 없습니다. (관리자 전용)",
      ),
    ]
}

pub fn moderator_delete_command_test() {
  let repo = repository.mock_repo([])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "명령",
        args: ["삭제", "인사"],
        role: permission.Moderator,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "'인사' 명령이 삭제되었습니다.",
      ),
    ]
}

pub fn custom_command_lookup_test() {
  let repo = repository.mock_repo_with_commands([], [#("인사", "안녕하세요!")])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "인사",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "custom_command", message: "안녕하세요!"),
    ]
}

pub fn unknown_command_ignored_test() {
  let repo = repository.mock_repo([])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "없는명령",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events == []
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}

pub fn template_variable_substitution_test() {
  let repo =
    repository.mock_repo_with_commands([], [
      #("인사", "{{user}}님 안녕하세요!"),
    ])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "인사",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "custom_command", message: "alice님 안녕하세요!"),
    ]
}

pub fn template_with_args_test() {
  let repo =
    repository.mock_repo_with_commands([], [
      #("에코", "{{user}}님이 말했습니다: {{args}}"),
    ])
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "bob",
        name: "에코",
        args: ["hello", "world"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "bob님이 말했습니다: hello world",
      ),
    ]
}

pub fn template_with_conditional_test() {
  let repo =
    repository.mock_repo_with_commands([], [
      #(
        "환영",
        "{{if args}}{{args}}에 오신 {{user}}님 환영!{{else}}{{user}}님 환영합니다!{{end}}",
      ),
    ])
  let p = custom_command.new(repo)
  // With args
  let events1 =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "환영",
        args: ["스트리밍"],
        role: permission.Viewer,
      ),
    )
  assert events1
    == [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "스트리밍에 오신 alice님 환영!",
      ),
    ]
  // Without args
  let events2 =
    plugin.handle(
      p,
      plugin.Command(user: "bob", name: "환영", args: [], role: permission.Viewer),
    )
  assert events2
    == [
      plugin.PluginResponse(plugin: "custom_command", message: "bob님 환영합니다!"),
    ]
}

pub fn template_with_points_test() {
  let repo =
    repository.mock_repo_with_commands(
      [repository.UserData("alice", 500, 10, 0)],
      [#("내정보", "{{user}}: {{points}}pt, 출석 {{attendance}}회")],
    )
  let p = custom_command.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "내정보",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "alice: 500pt, 출석 10회",
      ),
    ]
}
