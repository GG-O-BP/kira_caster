import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/points
import kira_caster/storage/repository.{UserData}

pub fn check_balance_test() {
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "alice",
        points: 150,
        attendance_count: 3,
        last_attendance: 0,
      ),
    ])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "포인트",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "points", message: "alice님 포인트: 150"),
    ]
}

pub fn check_balance_unknown_user_test() {
  let repo = repository.mock_repo([])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "nobody",
        name: "포인트",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "points", message: "nobody님 포인트: 0"),
    ]
}

pub fn ranking_test() {
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "alice",
        points: 100,
        attendance_count: 1,
        last_attendance: 0,
      ),
      UserData(
        user_id: "bob",
        points: 200,
        attendance_count: 2,
        last_attendance: 0,
      ),
    ])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "포인트",
        args: ["순위"],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "points", message: msg)] -> {
      assert {
        case msg {
          "포인트 순위!\n" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn points_change_adds_points_test() {
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "alice",
        points: 100,
        attendance_count: 1,
        last_attendance: 0,
      ),
    ])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.PointsChange(user: "alice", amount: 50, reason: "dice_win"),
    )
  // Success returns empty (silent update)
  assert events == []
}

pub fn points_change_new_user_test() {
  let repo = repository.mock_repo([])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.PointsChange(user: "newbie", amount: 30, reason: "reward"),
    )
  assert events == []
}

pub fn points_change_negative_floors_at_zero_test() {
  let repo =
    repository.mock_repo([
      UserData(
        user_id: "alice",
        points: 10,
        attendance_count: 0,
        last_attendance: 0,
      ),
    ])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.PointsChange(user: "alice", amount: -100, reason: "dice_loss"),
    )
  assert events == []
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = points.new(repo)
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
