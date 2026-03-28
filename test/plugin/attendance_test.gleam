import kira_caster/plugin/attendance
import kira_caster/plugin/plugin
import kira_caster/storage/repository.{UserData}

pub fn attendance_new_user_test() {
  let repo = repository.mock_repo([])
  let p = attendance.new(repo)
  let events =
    plugin.handle(p, plugin.Command(user: "alice", name: "출석", args: []))
  assert events
    == [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "alice 출석 완료! (총 1회, +10포인트)",
      ),
    ]
}

pub fn attendance_existing_user_test() {
  let repo =
    repository.mock_repo([
      UserData(user_id: "bob", points: 50, attendance_count: 5),
    ])
  let p = attendance.new(repo)
  let events =
    plugin.handle(p, plugin.Command(user: "bob", name: "출석", args: []))
  assert events
    == [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "bob 출석 완료! (총 6회, +10포인트)",
      ),
    ]
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = attendance.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}
