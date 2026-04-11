import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import kira_caster/plugin/advanced_command
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_commands(repo: Repository) -> Response {
  case repo.get_all_commands_detailed() {
    Ok(commands) -> {
      let body =
        json.array(commands, fn(c) {
          json.object([
            #("name", json.string(c.0)),
            #("response", json.string(c.1)),
            #("type", json.string(c.2)),
            #("source_code", case c.3 {
              Some(src) -> json.string(src)
              None -> json.null()
            }),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> error_json("명령어 목록을 불러올 수 없습니다")
  }
}

pub fn handle_set_command(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use name <- decode.field("name", decode.string)
    use response <- decode.field("response", decode.string)
    decode.success(#(name, response))
  }
  case decode.run(body, decoder) {
    Ok(#(name, response)) ->
      case repo.set_command(name, response) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("name", json.string(name)),
                #("response", json.string(response)),
              ]),
            ),
            201,
          )
        Error(_) -> error_json("명령어 저장에 실패했습니다. 데이터베이스 오류가 발생했습니다")
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

pub fn handle_delete_command(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("name", decode.string, fn(n) { decode.success(n) })
  case decode.run(body, decoder) {
    Ok(name) ->
      case repo.delete_command(name) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("deleted", json.string(name))])),
            200,
          )
        Error(_) -> error_json("명령어 삭제에 실패했습니다")
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

pub fn handle_add_advanced_command(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use name <- decode.field("name", decode.string)
    use source_code <- decode.field("source_code", decode.string)
    decode.success(#(name, source_code))
  }
  case decode.run(body, decoder) {
    Ok(#(name, source_code)) ->
      case repo.set_advanced_command(name, source_code, "실행 오류") {
        Ok(Nil) ->
          case advanced_command.compile_and_load(name, source_code) {
            Ok(Nil) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("name", json.string(name)),
                    #("compiled", json.bool(True)),
                  ]),
                ),
                201,
              )
            Error(e) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("name", json.string(name)),
                    #("compiled", json.bool(False)),
                    #("error", json.string(advanced_command.error_to_string(e))),
                  ]),
                ),
                201,
              )
          }
        Error(_) -> error_json("고급 명령어 저장에 실패했습니다. 소스 코드를 확인해주세요")
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

pub fn handle_compile_command(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("name", decode.string, fn(n) { decode.success(n) })
  case decode.run(body, decoder) {
    Ok(name) ->
      case repo.get_command_with_type(name) {
        Ok(#(_, "gleam", Some(source_code))) ->
          case advanced_command.compile_and_load(name, source_code) {
            Ok(Nil) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("name", json.string(name)),
                    #("compiled", json.bool(True)),
                  ]),
                ),
                200,
              )
            Error(e) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("compiled", json.bool(False)),
                    #("error", json.string(advanced_command.error_to_string(e))),
                  ]),
                ),
                200,
              )
          }
        Ok(_) -> wisp.bad_request("command is not an advanced command")
        Error(_) -> wisp.response(404) |> wisp.string_body("command not found")
      }
    Error(_) -> wisp.bad_request("invalid request body")
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
