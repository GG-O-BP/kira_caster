import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import kira_caster/core/permission
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  channel_id: String,
) -> Plugin {
  Plugin(name: "broadcast_control", handle_event: fn(event) {
    handle(get_token, api, channel_id, event)
  })
}

fn handle(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  channel_id: String,
  event: Event,
) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "제목", args:, role:) ->
      handle_title(get_token, api, args, role)
    plugin.Command(user: _, name: "태그", args:, role:) ->
      handle_tags(get_token, api, args, role)
    plugin.Command(user: _, name: "카테고리", args:, role:) ->
      handle_category(get_token, api, args, role)
    plugin.Command(user: _, name: "슬로우모드", args:, role:) ->
      handle_slowmode(get_token, api, args, role)
    plugin.Command(user: _, name: "팔로워전용", args:, role:) ->
      handle_follower_only(get_token, api, args, role)
    plugin.Command(user: _, name: "공지", args:, role:) ->
      handle_notice(get_token, api, args, role)
    plugin.Command(user: _, name: "방송상태", args: _, role: _) ->
      handle_live_status(api, channel_id)
    plugin.Command(user: _, name: "라이브", args: _, role: _) ->
      handle_live_list(api)
    // Handle chat_notice system event from song_request
    plugin.SystemEvent(kind: "chat_notice", data:) ->
      handle_system_notice(get_token, api, data)
    _ -> []
  }
}

fn respond(message: String) -> List(Event) {
  [plugin.PluginResponse(plugin: "broadcast_control", message:)]
}

fn require_mod(role: permission.Role, f: fn() -> List(Event)) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Ok(Nil) -> f()
    Error(_) -> respond("권한이 없습니다. (관리자 전용)")
  }
}

fn handle_title(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  args: List(String),
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case args {
      [] -> respond("사용법: !제목 <새 제목>")
      _ -> {
        let title = string.join(args, " ")
        let body =
          json.to_string(
            json.object([#("defaultLiveTitle", json.string(title))]),
          )
        case get_token() {
          Ok(token) ->
            case api.update_live_setting(token, body) {
              Ok(Nil) -> respond("방송 제목을 '" <> title <> "'(으)로 변경했습니다.")
              Error(_) -> respond("제목 변경에 실패했습니다.")
            }
          Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
        }
      }
    }
  })
}

fn handle_tags(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  args: List(String),
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case args {
      [] -> respond("사용법: !태그 <태그1> <태그2> ... (최대 6개)")
      tags -> {
        let tags = list.take(tags, 6)
        let body =
          json.to_string(
            json.object([#("tags", json.array(tags, json.string))]),
          )
        case get_token() {
          Ok(token) ->
            case api.update_live_setting(token, body) {
              Ok(Nil) -> respond("태그를 변경했습니다: " <> string.join(tags, ", "))
              Error(_) -> respond("태그 변경에 실패했습니다.")
            }
          Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
        }
      }
    }
  })
}

fn handle_category(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  args: List(String),
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case args {
      [] -> respond("사용법: !카테고리 <검색어>")
      _ -> {
        let keyword = string.join(args, " ")
        case api.search_categories(keyword, 1) {
          Ok([cat, ..]) -> {
            let body =
              json.to_string(
                json.object([#("categoryId", json.string(cat.category_id))]),
              )
            case get_token() {
              Ok(token) ->
                case api.update_live_setting(token, body) {
                  Ok(Nil) ->
                    respond("카테고리를 '" <> cat.category_value <> "'(으)로 변경했습니다.")
                  Error(_) -> respond("카테고리 변경에 실패했습니다.")
                }
              Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
            }
          }
          Ok([]) -> respond("'" <> keyword <> "' 카테고리를 찾을 수 없습니다.")
          Error(_) -> respond("카테고리 검색에 실패했습니다.")
        }
      }
    }
  })
}

fn handle_slowmode(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  args: List(String),
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case args {
      ["끄기"] -> {
        let body =
          json.to_string(json.object([#("slowModeDelay", json.int(0))]))
        case get_token() {
          Ok(token) ->
            case api.update_chat_settings(token, body) {
              Ok(Nil) -> respond("슬로우모드를 해제했습니다.")
              Error(_) -> respond("슬로우모드 해제에 실패했습니다.")
            }
          Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
        }
      }
      [seconds_str] ->
        case int.parse(seconds_str) {
          Ok(seconds) -> {
            let body =
              json.to_string(
                json.object([#("slowModeDelay", json.int(seconds))]),
              )
            case get_token() {
              Ok(token) ->
                case api.update_chat_settings(token, body) {
                  Ok(Nil) ->
                    respond("슬로우모드를 " <> int.to_string(seconds) <> "초로 설정했습니다.")
                  Error(_) -> respond("슬로우모드 설정에 실패했습니다.")
                }
              Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
            }
          }
          Error(_) -> respond("사용법: !슬로우모드 <초> 또는 !슬로우모드 끄기")
        }
      _ -> respond("사용법: !슬로우모드 <초> 또는 !슬로우모드 끄기")
    }
  })
}

fn handle_follower_only(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  args: List(String),
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    let #(group, msg) = case args {
      ["끄기"] -> #("ALL", "팔로워전용 모드를 해제했습니다.")
      _ -> #("FOLLOWER", "팔로워전용 모드를 설정했습니다.")
    }
    let body =
      json.to_string(json.object([#("allowedGroup", json.string(group))]))
    case get_token() {
      Ok(token) ->
        case api.update_chat_settings(token, body) {
          Ok(Nil) -> respond(msg)
          Error(_) -> respond("채팅 설정 변경에 실패했습니다.")
        }
      Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
    }
  })
}

fn handle_notice(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  args: List(String),
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case args {
      [] -> respond("사용법: !공지 <메시지>")
      _ -> {
        let message = string.join(args, " ")
        case get_token() {
          Ok(token) ->
            case api.send_notice(token, message) {
              Ok(Nil) -> respond("공지를 등록했습니다.")
              Error(_) -> respond("공지 등록에 실패했습니다.")
            }
          Error(_) -> respond("인증 토큰을 가져올 수 없습니다.")
        }
      }
    }
  })
}

fn handle_live_status(api: CimeApi, channel_id: String) -> List(Event) {
  case api.get_live_status(channel_id) {
    Ok(status) ->
      case status.is_live {
        True -> {
          let title = case status.title {
            Some(t) -> t
            None -> "(제목 없음)"
          }
          let started = case status.opened_at {
            Some(t) -> " (시작: " <> t <> ")"
            None -> ""
          }
          respond("방송 중: " <> title <> started)
        }
        False -> respond("현재 방송 중이 아닙니다.")
      }
    Error(_) -> respond("방송 상태 조회에 실패했습니다.")
  }
}

fn handle_live_list(api: CimeApi) -> List(Event) {
  case api.get_lives(5, None) {
    Ok(#(lives, _)) ->
      case lives {
        [] -> respond("현재 방송 중인 채널이 없습니다.")
        _ -> {
          let entries =
            list.map(lives, fn(live) {
              live.channel_name
              <> " - "
              <> live.live_title
              <> " ("
              <> int.to_string(live.concurrent_user_count)
              <> "명)"
            })
          respond("라이브 목록: " <> string.join(entries, " | "))
        }
      }
    Error(_) -> respond("라이브 목록 조회에 실패했습니다.")
  }
}

fn handle_system_notice(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  data: String,
) -> List(Event) {
  case get_token() {
    Ok(token) -> {
      let _ = api.send_notice(token, data)
      []
    }
    Error(_) -> []
  }
}
