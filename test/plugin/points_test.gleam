import kira_caster/plugin/plugin
import kira_caster/plugin/points
import kira_caster/storage/repository.{UserData}

pub fn check_balance_test() {
  let repo =
    repository.mock_repo([
      UserData(user_id: "alice", points: 150, attendance_count: 3),
    ])
  let p = points.new(repo)
  let events =
    plugin.handle(p, plugin.Command(user: "alice", name: "포인트", args: []))
  assert events
    == [
      plugin.PluginResponse(plugin: "points", message: "alice님의 포인트: 150"),
    ]
}

pub fn check_balance_unknown_user_test() {
  let repo = repository.mock_repo([])
  let p = points.new(repo)
  let events =
    plugin.handle(p, plugin.Command(user: "nobody", name: "포인트", args: []))
  assert events
    == [
      plugin.PluginResponse(plugin: "points", message: "nobody님의 포인트: 0"),
    ]
}

pub fn ranking_test() {
  let repo =
    repository.mock_repo([
      UserData(user_id: "alice", points: 100, attendance_count: 1),
      UserData(user_id: "bob", points: 200, attendance_count: 2),
    ])
  let p = points.new(repo)
  let events =
    plugin.handle(p, plugin.Command(user: "alice", name: "포인트", args: ["순위"]))
  case events {
    [plugin.PluginResponse(plugin: "points", message: msg)] -> {
      assert {
        case msg {
          "포인트 순위:\n" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = points.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}
