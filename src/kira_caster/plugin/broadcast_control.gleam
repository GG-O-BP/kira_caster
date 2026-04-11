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
    Error(_) -> respond("헐 이건 관리자만 할 수 있어용 ㅠ")
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
      [] -> respond("이렇게 써줘용 !제목 <새 제목>")
      _ -> {
        let title = string.join(args, " ")
        let body =
          json.to_string(
            json.object([#("defaultLiveTitle", json.string(title))]),
          )
        case get_token() {
          Ok(token) ->
            case api.update_live_setting(token, body) {
              Ok(Nil) -> respond("방송 제목을 '" <> title <> "'(으)로 바꿨당!")
              Error(_) -> respond("앗 제목 바꾸다 에러났어 ㅠㅠ")
            }
          Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
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
      [] -> respond("이렇게 써줘용 !태그 <태그1> <태그2> ... (최대 6개)")
      tags -> {
        let tags = list.take(tags, 6)
        let body =
          json.to_string(
            json.object([#("tags", json.array(tags, json.string))]),
          )
        case get_token() {
          Ok(token) ->
            case api.update_live_setting(token, body) {
              Ok(Nil) -> respond("태그 바꿨당! " <> string.join(tags, ", "))
              Error(_) -> respond("앗 태그 바꾸다 에러났어 ㅠㅠ")
            }
          Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
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
      [] -> respond("이렇게 써줘용 !카테고리 <검색어>")
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
                    respond("카테고리를 '" <> cat.category_value <> "'(으)로 바꿨당!")
                  Error(_) -> respond("앗 카테고리 바꾸다 에러났어 ㅠㅠ")
                }
              Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
            }
          }
          Ok([]) -> respond("'" <> keyword <> "' 카테고리를 못 찾았어 ㅠㅠ")
          Error(_) -> respond("앗 카테고리 검색하다 에러났어 ㅠㅠ")
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
              Ok(Nil) -> respond("슬로우모드 껐당!")
              Error(_) -> respond("앗 슬로우모드 끄다 에러났어 ㅠㅠ")
            }
          Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
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
                    respond("슬로우모드 " <> int.to_string(seconds) <> "초로 맞췄당!")
                  Error(_) -> respond("앗 슬로우모드 설정하다 에러났어 ㅠㅠ")
                }
              Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
            }
          }
          Error(_) -> respond("이렇게 써줘용 !슬로우모드 <초> 또는 !슬로우모드 끄기")
        }
      _ -> respond("이렇게 써줘용 !슬로우모드 <초> 또는 !슬로우모드 끄기")
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
      ["끄기"] -> #("ALL", "팔로워전용 모드 껐당!")
      _ -> #("FOLLOWER", "팔로워전용 모드 켰당!")
    }
    let body =
      json.to_string(json.object([#("allowedGroup", json.string(group))]))
    case get_token() {
      Ok(token) ->
        case api.update_chat_settings(token, body) {
          Ok(Nil) -> respond(msg)
          Error(_) -> respond("앗 채팅 설정 바꾸다 에러났어 ㅠㅠ")
        }
      Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
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
      [] -> respond("이렇게 써줘용 !공지 <메시지>")
      _ -> {
        let message = string.join(args, " ")
        case get_token() {
          Ok(token) ->
            case api.send_notice(token, message) {
              Ok(Nil) -> respond("공지 올렸당!")
              Error(_) -> respond("앗 공지 올리다 에러났어 ㅠㅠ")
            }
          Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
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
            None -> "(제목 없당..)"
          }
          let started = case status.opened_at {
            Some(t) -> " (시작: " <> t <> ")"
            None -> ""
          }
          respond("방송 중이에용 " <> title <> started)
        }
        False -> respond("지금은 방송 안 하고 있당")
      }
    Error(_) -> respond("앗 방송 상태 불러오다 에러났어 ㅠㅠ")
  }
}

fn handle_live_list(api: CimeApi) -> List(Event) {
  case api.get_lives(5, None) {
    Ok(#(lives, _)) ->
      case lives {
        [] -> respond("지금 방송 중인 채널이 없당")
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
          respond("라이브 목록이에용 " <> string.join(entries, " | "))
        }
      }
    Error(_) -> respond("앗 라이브 목록 불러오다 에러났어 ㅠㅠ")
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
