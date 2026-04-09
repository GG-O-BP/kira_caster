import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option.{type Option, None, Some}
import kira_caster/core/config.{type Config}
import kira_caster/platform/cime/token_manager.{type TokenMessage}
import wisp.{type Request, type Response}

pub fn handle_authorize(_req: Request, config: Config) -> Response {
  let url =
    "https://ci.me/auth/openapi/account-interlock?clientId="
    <> config.cime_client_id
    <> "&redirectUri="
    <> config.cime_redirect_uri
    <> "&state=kira_caster"
  wisp.redirect(url)
}

pub fn handle_callback(
  req: Request,
  token_mgr: Option(Subject(TokenMessage)),
) -> Response {
  let code = wisp.get_query(req) |> find_param("code")
  case code, token_mgr {
    Some(auth_code), Some(mgr) -> {
      case token_manager.set_auth_code(mgr, auth_code) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("status", json.string("ok")),
                #("message", json.string("인증 완료")),
              ]),
            ),
            200,
          )
        Error(reason) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("status", json.string("error")),
                #("message", json.string(reason)),
              ]),
            ),
            400,
          )
      }
    }
    None, _ ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("status", json.string("error")),
            #("message", json.string("code 파라미터가 필요합니다")),
          ]),
        ),
        400,
      )
    _, None ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("status", json.string("error")),
            #("message", json.string("토큰 매니저가 시작되지 않았습니다")),
          ]),
        ),
        503,
      )
  }
}

pub fn handle_status(
  _req: Request,
  token_mgr: Option(Subject(TokenMessage)),
) -> Response {
  case token_mgr {
    Some(mgr) -> {
      let status = token_manager.get_status(mgr)
      wisp.json_response(
        json.to_string(
          json.object([
            #("authenticated", json.bool(status.authenticated)),
            #("expires_at", json.int(status.expires_at)),
          ]),
        ),
        200,
      )
    }
    None ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("authenticated", json.bool(False)),
            #("message", json.string("씨미 연동 미설정")),
          ]),
        ),
        200,
      )
  }
}

pub fn handle_disconnect(
  _req: Request,
  token_mgr: Option(Subject(TokenMessage)),
) -> Response {
  case token_mgr {
    Some(mgr) -> {
      case token_manager.revoke_and_clear(mgr) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("status", json.string("ok")),
                #("message", json.string("연결 해제 완료")),
              ]),
            ),
            200,
          )
        Error(reason) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("status", json.string("error")),
                #("message", json.string(reason)),
              ]),
            ),
            500,
          )
      }
    }
    None ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("status", json.string("error")),
            #("message", json.string("토큰 매니저가 시작되지 않았습니다")),
          ]),
        ),
        503,
      )
  }
}

fn find_param(params: List(#(String, String)), key: String) -> Option(String) {
  case params {
    [] -> None
    [#(k, v), ..] if k == key -> Some(v)
    [_, ..rest] -> find_param(rest, key)
  }
}
