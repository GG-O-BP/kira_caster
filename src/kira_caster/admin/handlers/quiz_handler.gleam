import gleam/dynamic/decode
import gleam/json
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_get_quizzes(repo: Repository) -> Response {
  case repo.get_all_quizzes() {
    Ok(quizzes) -> {
      let body =
        json.array(quizzes, fn(q) {
          json.object([
            #("question", json.string(q.0)),
            #("answer", json.string(q.1)),
            #("reward", json.int(q.2)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

pub fn handle_add_quiz(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use question <- decode.field("question", decode.string)
    use answer <- decode.field("answer", decode.string)
    use reward <- decode.field("reward", decode.int)
    decode.success(#(question, answer, reward))
  }
  case decode.run(body, decoder) {
    Ok(#(question, answer, reward)) ->
      case repo.add_quiz(question, answer, reward) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("question", json.string(question)),
                #("answer", json.string(answer)),
                #("reward", json.int(reward)),
              ]),
            ),
            201,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

pub fn handle_delete_quiz(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder =
    decode.field("question", decode.string, fn(q) { decode.success(q) })
  case decode.run(body, decoder) {
    Ok(question) ->
      case repo.delete_quiz(question) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("deleted", json.string(question))])),
            200,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}
