import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option.{type Option, None, Some}
import kira_caster/admin/views/layout
import kira_caster/core/config.{type Config}
import kira_caster/logger
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime/token_manager.{type TokenMessage}
import kira_caster/storage/repository.{type Repository}
import lustre/attribute.{attribute as attr}
import lustre/element.{fragment, text}
import lustre/element/html
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
  cime_api: Option(CimeApi),
  repo: Repository,
) -> Response {
  let code = wisp.get_query(req) |> find_param("code")
  case code, token_mgr {
    Some(auth_code), Some(mgr) -> {
      case token_manager.set_auth_code(mgr, auth_code) {
        Ok(Nil) -> {
          // Auto-fetch channel ID after successful auth
          auto_fetch_channel_id(mgr, cime_api, repo)
          oauth_result_page(
            True,
            "씨미 연동 완료!",
            "씨미 계정이 성공적으로 연결되었습니다. 대시보드에서 모든 기능을 사용할 수 있습니다.",
          )
        }
        Error(_reason) ->
          oauth_result_page(
            False,
            "씨미 연동 실패",
            "씨미 인증에 실패했습니다. 대시보드 설정에서 앱 ID와 비밀키가 올바른지 확인한 후 다시 시도해주세요.",
          )
      }
    }
    None, _ ->
      oauth_result_page(
        False,
        "씨미 연동 실패",
        "씨미에서 인증 정보를 받지 못했습니다. 대시보드의 씨미 연동 탭에서 다시 시도해주세요.",
      )
    _, None ->
      oauth_result_page(
        False,
        "씨미 연동 준비 안 됨",
        "씨미 연동이 아직 준비되지 않았습니다. 대시보드 설정에서 씨미 앱 ID와 비밀키를 먼저 입력한 후 프로그램을 재시작해주세요.",
      )
  }
}

fn oauth_result_page(success: Bool, title: String, message: String) -> Response {
  let head =
    "<link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&display=swap\" rel=\"stylesheet\">"
    <> "<style>"
    <> ":root{--color-primary:#FD719B;--gradient-main:linear-gradient(92.54deg,#FF608F 5.84%,#FBB35E 95.21%);--color-success:#00C199;--color-error:#F77061;--color-text:#54577A;--color-border:#E9EAEE;--color-bg:#FFFFFF;--radius-card:12px;--radius-pill:20px;--font-body:Hiragino Sans,ui-sans-serif,system-ui,-apple-system,sans-serif}"
    <> "*{box-sizing:border-box;margin:0;padding:0}body{font-family:var(--font-body);background:var(--color-bg);color:var(--color-text);display:flex;justify-content:center;align-items:center;min-height:100vh;padding:20px}"
    <> ".card{max-width:440px;width:100%;background:var(--color-bg);border:1px solid var(--color-border);border-radius:var(--radius-card);padding:40px 32px;text-align:center}"
    <> "h1{font-family:'Quicksand',sans-serif;background:var(--gradient-main);-webkit-background-clip:text;-webkit-text-fill-color:transparent;font-weight:700;font-size:2em;margin-bottom:16px}"
    <> ".msg{padding:12px 16px;border-radius:8px;margin-bottom:16px;font-weight:600;font-size:0.95em}"
    <> ".msg.ok{background:rgba(0,193,153,0.1);color:var(--color-success)}"
    <> ".msg.err{background:rgba(247,112,97,0.1);color:var(--color-error)}"
    <> "p{color:var(--color-text);font-size:0.9em;line-height:1.6;margin-bottom:20px}"
    <> "a{display:inline-block;padding:12px 24px;background:linear-gradient(92.54deg,#FD719B 5.84%,#FD9371 95.21%);color:#fff;border-radius:var(--radius-pill);font-weight:600;text-decoration:none;transition:opacity .2s}a:hover{opacity:0.85}"
    <> "</style>"
  let status_class = case success {
    True -> "msg ok"
    False -> "msg err"
  }
  layout.page(
    title: "kira_caster - " <> title,
    head: head,
    body: fragment([
      html.div([attribute.class("card")], [
        html.h1([], [text("kira_caster")]),
        html.div([attribute.class(status_class)], [text(title)]),
        html.p([], [text(message)]),
        html.a([attribute.href("/"), attr("style", "")], [
          text("대시보드로 이동"),
        ]),
      ]),
    ]),
    tail: "",
  )
}

fn auto_fetch_channel_id(
  mgr: Subject(TokenMessage),
  cime_api: Option(CimeApi),
  repo: Repository,
) -> Nil {
  case cime_api {
    Some(api) -> {
      case token_manager.get_access_token(mgr) {
        Ok(token) -> {
          case api.get_me(token) {
            Ok(me) -> {
              let _ = repo.set_setting("cime_channel_id", me.channel_id)
              logger.info(
                "채널 ID 자동 조회 완료: "
                <> me.channel_name
                <> " ("
                <> me.channel_id
                <> ")",
              )
              Nil
            }
            Error(_) -> {
              logger.warn("채널 ID 자동 조회 실패: API 호출 오류")
              Nil
            }
          }
        }
        Error(_) -> {
          logger.warn("채널 ID 자동 조회 실패: 토큰 조회 오류")
          Nil
        }
      }
    }
    None -> Nil
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
