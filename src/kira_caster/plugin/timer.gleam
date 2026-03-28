import gleam/erlang/process
import gleam/int
import gleam/string
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new(on_response: fn(plugin.Event) -> Nil) -> Plugin {
  Plugin(name: "timer", handle_event: fn(event) { handle(on_response, event) })
}

fn handle(on_response: fn(plugin.Event) -> Nil, event: Event) -> List(Event) {
  case event {
    plugin.Command(user:, name: "타이머", args: [seconds_str, ..rest], role: _) ->
      start_timer(on_response, user, seconds_str, rest)
    plugin.Command(user: _, name: "타이머", args: _, role: _) -> [
      plugin.PluginResponse(plugin: "timer", message: "사용법: !타이머 <초> [메시지]"),
    ]
    _ -> []
  }
}

fn start_timer(
  on_response: fn(plugin.Event) -> Nil,
  user: String,
  seconds_str: String,
  rest: List(String),
) -> List(Event) {
  case int.parse(seconds_str) {
    Error(_) -> [
      plugin.PluginResponse(plugin: "timer", message: "초 단위 숫자를 입력해주세요."),
    ]
    Ok(seconds) ->
      case seconds > 0 && seconds <= 3600 {
        False -> [
          plugin.PluginResponse(plugin: "timer", message: "1~3600초 사이로 설정해주세요."),
        ]
        True -> {
          let msg = case rest {
            [] -> user <> "님의 타이머가 울렸습니다!"
            _ -> user <> "님: " <> string.join(rest, " ")
          }
          process.spawn(fn() {
            process.sleep(seconds * 1000)
            on_response(plugin.PluginResponse(plugin: "timer", message: msg))
          })
          [
            plugin.PluginResponse(
              plugin: "timer",
              message: int.to_string(seconds) <> "초 타이머가 설정되었습니다.",
            ),
          ]
        }
      }
  }
}
