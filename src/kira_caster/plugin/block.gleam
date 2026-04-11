import gleam/list
import gleam/string
import kira_caster/core/permission
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new(get_token: fn() -> Result(String, String), api: CimeApi) -> Plugin {
  Plugin(name: "block", handle_event: fn(event) {
    handle(get_token, api, event)
  })
}

fn handle(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  event: Event,
) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "차단", args: [target], role:) ->
      handle_block(get_token, api, target, role)
    plugin.Command(user: _, name: "차단해제", args: [target], role:) ->
      handle_unblock(get_token, api, target, role)
    plugin.Command(user: _, name: "차단목록", args: _, role:) ->
      handle_list(get_token, api, role)
    // Auto-block from filter plugin
    plugin.SystemEvent(kind: "auto_block", data: channel_id) ->
      handle_auto_block(get_token, api, channel_id)
    _ -> []
  }
}

fn respond(message: String) -> List(Event) {
  [plugin.PluginResponse(plugin: "block", message:)]
}

fn require_mod(role: permission.Role, f: fn() -> List(Event)) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Ok(Nil) -> f()
    Error(_) -> respond("헐 이건 관리자만 할 수 있어용 ㅠ")
  }
}

fn handle_block(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  target: String,
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case get_token() {
      Ok(token) ->
        case api.block_user(token, target) {
          Ok(Nil) -> respond(target <> " 차단했당!")
          Error(_) -> respond("앗 차단하다 에러났어 ㅠㅠ")
        }
      Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
    }
  })
}

fn handle_unblock(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  target: String,
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case get_token() {
      Ok(token) ->
        case api.unblock_user(token, target) {
          Ok(Nil) -> respond(target <> " 차단 풀어줬당!")
          Error(_) -> respond("앗 차단 풀다 에러났어 ㅠㅠ")
        }
      Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
    }
  })
}

fn handle_list(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  role: permission.Role,
) -> List(Event) {
  require_mod(role, fn() {
    case get_token() {
      Ok(token) ->
        case api.get_blocked_users(token, 20, option.None) {
          Ok(#(users, _)) ->
            case users {
              [] -> respond("차단된 유저가 없당")
              _ -> {
                let names =
                  list.map(users, fn(u) { u.name <> "(" <> u.handle <> ")" })
                respond("차단 목록이에용 " <> string.join(names, ", "))
              }
            }
          Error(_) -> respond("앗 차단 목록 불러오다 에러났어 ㅠㅠ")
        }
      Error(_) -> respond("앗 인증 토큰을 못 가져왔어 ㅠㅠ")
    }
  })
}

fn handle_auto_block(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  channel_id: String,
) -> List(Event) {
  case string.is_empty(channel_id) {
    True -> []
    False ->
      case get_token() {
        Ok(token) -> {
          let _ = api.block_user(token, channel_id)
          [
            plugin.PluginResponse(
              plugin: "block",
              message: "필터 위반이라 자동으로 차단했당!",
            ),
          ]
        }
        Error(_) -> []
      }
  }
}

import gleam/option
