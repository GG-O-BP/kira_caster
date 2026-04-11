import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/json
import gleam/option.{type Option, Some}
import kira_caster/event_bus
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_get_settings(repo: Repository) -> Response {
  case repo.get_all_settings() {
    Ok(settings) -> {
      let body =
        json.array(settings, fn(s) {
          json.object([
            #("key", json.string(s.0)),
            #("value", json.string(s.1)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> error_json("설정 목록을 불러올 수 없습니다. 프로그램을 재시작한 후 다시 시도해주세요")
  }
}

pub fn handle_set_setting(
  req: Request,
  repo: Repository,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use key <- decode.field("key", decode.string)
    use value <- decode.field("value", decode.string)
    decode.success(#(key, value))
  }
  case decode.run(body, decoder) {
    Ok(#(key, value)) ->
      case repo.set_setting(key, value) {
        Ok(Nil) -> {
          case key, bus {
            "cooldown_ms", Some(b) ->
              case int.parse(value) {
                Ok(ms) -> event_bus.set_cooldown(b, ms)
                Error(_) -> Nil
              }
            _, _ -> Nil
          }
          wisp.json_response(
            json.to_string(
              json.object([
                #("key", json.string(key)),
                #("value", json.string(value)),
              ]),
            ),
            200,
          )
        }
        Error(_) -> error_json("설정을 저장할 수 없습니다. 입력한 값이 올바른지 확인하고 다시 시도해주세요")
      }
    Error(_) -> bad_request_json("잘못된 요청입니다. 페이지를 새로고침한 후 다시 시도해주세요")
  }
}

fn error_json(message: String) -> Response {
  wisp.json_response(
    json.to_string(
      json.object([
        #("status", json.string("error")),
        #("message", json.string(message)),
      ]),
    ),
    500,
  )
}

fn bad_request_json(message: String) -> Response {
  wisp.json_response(
    json.to_string(
      json.object([
        #("status", json.string("error")),
        #("message", json.string(message)),
      ]),
    ),
    400,
  )
}
