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
