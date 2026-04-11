import gleam/dynamic/decode
import gleam/json
import gleam/string
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_banned_words(repo: Repository) -> Response {
  case repo.get_banned_words() {
    Ok(words) -> {
      let body = json.array(words, json.string)
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> error_json("금칙어 목록을 불러올 수 없습니다")
  }
}

pub fn handle_add_banned_word(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("word", decode.string, fn(w) { decode.success(w) })
  case decode.run(body, decoder) {
    Ok(word) ->
      case repo.add_banned_word(string.lowercase(word)) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("added", json.string(word))])),
            201,
          )
        Error(_) -> error_json("단어 추가에 실패했습니다. 이미 등록된 단어일 수 있습니다")
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

pub fn handle_remove_banned_word(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("word", decode.string, fn(w) { decode.success(w) })
  case decode.run(body, decoder) {
    Ok(word) ->
      case repo.remove_banned_word(string.lowercase(word)) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("removed", json.string(word))])),
            200,
          )
        Error(_) -> error_json("단어 삭제에 실패했습니다")
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
