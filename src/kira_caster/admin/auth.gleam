import gleam/http/request
import wisp.{type Request, type Response}

pub fn check_auth(req: Request, admin_key: String) -> Bool {
  case admin_key {
    "" -> True
    key -> {
      // 1. Cookie session check
      case wisp.get_cookie(req, "kira_session", wisp.Signed) {
        Ok(val) if val == key -> True
        _ -> {
          // 2. Bearer token fallback (API compatibility)
          case request.get_header(req, "authorization") {
            Ok(value) -> value == "Bearer " <> key
            Error(_) -> False
          }
        }
      }
    }
  }
}

pub fn set_session(
  response: Response,
  req: Request,
  admin_key: String,
) -> Response {
  wisp.set_cookie(
    response,
    req,
    "kira_session",
    admin_key,
    wisp.Signed,
    60 * 60 * 24 * 30,
  )
}

pub fn clear_session(response: Response, req: Request) -> Response {
  wisp.set_cookie(response, req, "kira_session", "", wisp.Signed, 0)
}
