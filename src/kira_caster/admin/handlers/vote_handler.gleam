import gleam/dynamic/decode
import gleam/json
import gleam/list
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_get_votes(repo: Repository) -> Response {
  case repo.get_active_vote() {
    Ok(#(topic, options)) -> {
      let results = case repo.get_vote_results() {
        Ok(r) -> r
        Error(_) -> []
      }
      let body =
        json.object([
          #("active", json.bool(True)),
          #("topic", json.string(topic)),
          #("options", json.array(options, json.string)),
          #(
            "results",
            json.array(results, fn(r) {
              json.object([
                #("choice", json.string(r.0)),
                #("count", json.int(r.1)),
              ])
            }),
          ),
        ])
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) ->
      wisp.json_response(
        json.to_string(json.object([#("active", json.bool(False))])),
        200,
      )
  }
}

pub fn handle_start_vote(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use topic <- decode.field("topic", decode.string)
    use options <- decode.field("options", decode.list(decode.string))
    decode.success(#(topic, options))
  }
  case decode.run(body, decoder) {
    Ok(#(topic, options)) ->
      case list.length(options) >= 2 {
        False -> wisp.bad_request("at least 2 options required")
        True ->
          case repo.start_vote(topic, options) {
            Ok(Nil) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("topic", json.string(topic)),
                    #("options", json.array(options, json.string)),
                  ]),
                ),
                201,
              )
            Error(_) -> wisp.internal_server_error()
          }
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

pub fn handle_end_vote(repo: Repository) -> Response {
  case repo.get_active_vote() {
    Error(_) ->
      wisp.json_response(
        json.to_string(json.object([#("error", json.string("no active vote"))])),
        404,
      )
    Ok(#(topic, _)) -> {
      let results = case repo.get_vote_results() {
        Ok(r) -> r
        Error(_) -> []
      }
      let _ = repo.end_vote()
      let body =
        json.object([
          #("ended", json.string(topic)),
          #(
            "results",
            json.array(results, fn(r) {
              json.object([
                #("choice", json.string(r.0)),
                #("count", json.int(r.1)),
              ])
            }),
          ),
        ])
      wisp.json_response(json.to_string(body), 200)
    }
  }
}
