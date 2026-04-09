import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/option.{type Option, None, Some}
import kira_caster/event_bus
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_get_plugins(repo: Repository) -> Response {
  let all_plugins = [
    "attendance", "points", "minigame", "filter", "custom_command", "uptime",
    "vote", "roulette", "quiz", "timer", "song_request", "donation_alert",
    "subscription_alert", "broadcast_control", "block", "follower",
  ]
  let disabled = case repo.get_disabled_plugins() {
    Ok(d) -> d
    Error(_) -> []
  }
  let body =
    json.array(all_plugins, fn(name) {
      json.object([
        #("name", json.string(name)),
        #("description", json.string(plugin_description(name))),
        #("enabled", json.bool(!is_in_list(name, disabled))),
      ])
    })
  wisp.json_response(json.to_string(body), 200)
}

pub fn handle_set_plugin(
  req: Request,
  repo: Repository,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use name <- decode.field("name", decode.string)
    use enabled <- decode.field("enabled", decode.bool)
    decode.success(#(name, enabled))
  }
  case decode.run(body, decoder) {
    Ok(#(name, enabled)) ->
      case repo.set_plugin_enabled(name, enabled) {
        Ok(Nil) -> {
          case bus {
            Some(b) ->
              case repo.get_disabled_plugins() {
                Ok(disabled) -> event_bus.set_disabled_plugins(b, disabled)
                Error(_) -> Nil
              }
            None -> Nil
          }
          wisp.json_response(
            json.to_string(
              json.object([
                #("name", json.string(name)),
                #("enabled", json.bool(enabled)),
              ]),
            ),
            200,
          )
        }
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn plugin_description(name: String) -> String {
  case name {
    "attendance" -> "출석 체크 (하루 1회, 포인트 보상)"
    "points" -> "포인트 조회 및 순위"
    "minigame" -> "미니게임 (주사위, 가위바위보)"
    "filter" -> "채팅 필터 (금칙어 관리)"
    "custom_command" -> "커스텀 명령어"
    "uptime" -> "봇 가동 시간 조회"
    "vote" -> "투표 시스템"
    "roulette" -> "룰렛 (확률 기반 포인트)"
    "quiz" -> "퀴즈 (DB + 내장 문제)"
    "timer" -> "타이머 (비동기 알림)"
    "song_request" -> "신청곡 (YouTube 대기열)"
    "donation_alert" -> "후원 알림 (채팅/영상 후원)"
    "subscription_alert" -> "구독 알림"
    "broadcast_control" -> "방송 제어 (제목/태그/카테고리/슬로우모드/공지)"
    "block" -> "차단 관리 (유저 차단/해제)"
    "follower" -> "팔로워 추적 (신규 환영)"
    _ -> ""
  }
}

fn is_in_list(item: String, items: List(String)) -> Bool {
  case items {
    [] -> False
    [first, ..rest] ->
      case first == item {
        True -> True
        False -> is_in_list(item, rest)
      }
  }
}
