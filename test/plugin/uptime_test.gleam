import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/uptime
import kira_caster/util/time

pub fn uptime_responds_test() {
  let p = uptime.new(time.now_ms())
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "업타임",
        args: [],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "uptime", message: msg)] -> {
      assert {
        case msg {
          "켜진 지 " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse from uptime"
  }
}

pub fn unrelated_event_ignored_test() {
  let p = uptime.new(0)
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
