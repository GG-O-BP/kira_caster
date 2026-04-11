import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/attendance
import kira_caster/plugin/plugin
import kira_caster/storage/repository.{UserData}
import kira_caster/util/time

pub fn attendance_new_user_test() {
  let repo = repository.mock_repo([])
  let p = attendance.new(repo, 10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "출석",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "alice 출석 완료당! (총 1회, +10포인트)",
      ),
    ]
}

pub fn attendance_existing_user_test() {
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "bob",
        points: 50,
        attendance_count: 5,
        last_attendance: 0,
      ),
    ])
  let p = attendance.new(repo, 10)
  let events =
    plugin.handle(
      p,
      plugin.Command(user: "bob", name: "출석", args: [], role: permission.Viewer),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "bob 출석 완료당! (총 6회, +10포인트)",
      ),
    ]
}

pub fn duplicate_attendance_blocked_test() {
  let now = time.now_ms()
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "alice",
        points: 10,
        attendance_count: 1,
        last_attendance: now,
      ),
    ])
  let p = attendance.new(repo, 10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "출석",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "alice님, 오늘 이미 출석했잖아용 ㅋㅋ",
      ),
    ]
}

pub fn attendance_next_day_allowed_test() {
  // last_attendance set to yesterday (epoch day 0, which is far in the past)
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "alice",
        points: 10,
        attendance_count: 1,
        last_attendance: 1000,
      ),
    ])
  let p = attendance.new(repo, 10)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "출석",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "alice 출석 완료당! (총 2회, +10포인트)",
      ),
    ]
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = attendance.new(repo, 10)
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
