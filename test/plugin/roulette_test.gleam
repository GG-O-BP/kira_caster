import gleam/list
import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/roulette

pub fn roulette_returns_response_and_points_test() {
  let p = roulette.new()
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "룰렛",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert list.length(events) == 2
  case events {
    [
      plugin.PluginResponse(plugin: "roulette", message: _),
      plugin.PointsChange(user: "alice", amount: _, reason: "roulette"),
    ] -> Nil
    _ -> panic as "Expected PluginResponse + PointsChange"
  }
}

pub fn roulette_message_contains_user_test() {
  let p = roulette.new()
  let events =
    plugin.handle(
      p,
      plugin.Command(user: "bob", name: "룰렛", args: [], role: permission.Viewer),
    )
  case events {
    [plugin.PluginResponse(plugin: "roulette", message: msg), ..] -> {
      assert {
        case msg {
          "bob" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected PluginResponse"
  }
}

pub fn unrelated_event_ignored_test() {
  let p = roulette.new()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}
