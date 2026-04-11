import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/timer

fn noop_handler(_event: plugin.Event) -> Nil {
  Nil
}

pub fn timer_set_test() {
  let p = timer.new(noop_handler)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "타이머",
        args: ["5"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "timer", message: "5초 타이머 맞춰놨당!"),
    ]
}

pub fn timer_invalid_seconds_test() {
  let p = timer.new(noop_handler)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "타이머",
        args: ["abc"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "timer", message: "초 단위로 숫자를 넣어줘용"),
    ]
}

pub fn timer_out_of_range_test() {
  let p = timer.new(noop_handler)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "타이머",
        args: ["9999"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "timer", message: "1~3600초 사이로 해줘용"),
    ]
}

pub fn timer_help_test() {
  let p = timer.new(noop_handler)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "타이머",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "timer", message: "이렇게 써줘용 !타이머 <초> [메시지]"),
    ]
}

pub fn unrelated_event_ignored_test() {
  let p = timer.new(noop_handler)
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
