import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/string
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  repo: Repository,
  start_time: Int,
  admin_key: String,
) -> Response {
  case check_auth(req, admin_key) {
    False -> wisp.response(401) |> wisp.string_body("Unauthorized")
    True -> route(req, repo, start_time)
  }
}

fn check_auth(req: Request, admin_key: String) -> Bool {
  case admin_key {
    "" -> True
    key -> {
      case request.get_header(req, "authorization") {
        Ok(value) -> value == "Bearer " <> key
        Error(_) -> False
      }
    }
  }
}

fn route(req: Request, repo: Repository, start_time: Int) -> Response {
  case req.method, request.path_segments(req) {
    http.Get, ["status"] -> handle_status(start_time)
    http.Get, ["users"] -> handle_users(repo)
    http.Get, ["banned-words"] -> handle_banned_words(repo)
    http.Get, ["commands"] -> handle_commands(repo)
    http.Post, ["banned-words"] -> handle_add_banned_word(req, repo)
    http.Delete, ["banned-words"] -> handle_remove_banned_word(req, repo)
    http.Post, ["commands"] -> handle_set_command(req, repo)
    http.Delete, ["commands"] -> handle_delete_command(req, repo)
    _, _ -> wisp.not_found()
  }
}

fn handle_status(start_time: Int) -> Response {
  let uptime_s = { time.now_ms() - start_time } / 1000
  let body =
    json.object([
      #("status", json.string("running")),
      #("uptime_seconds", json.int(uptime_s)),
    ])
  wisp.json_response(json.to_string(body), 200)
}

fn handle_users(repo: Repository) -> Response {
  case repo.get_all_users() {
    Ok(users) -> {
      let body =
        json.array(users, fn(u) {
          json.object([
            #("user_id", json.string(u.user_id)),
            #("points", json.int(u.points)),
            #("attendance_count", json.int(u.attendance_count)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_banned_words(repo: Repository) -> Response {
  case repo.get_banned_words() {
    Ok(words) -> {
      let body = json.array(words, json.string)
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_commands(repo: Repository) -> Response {
  case repo.get_all_commands() {
    Ok(commands) -> {
      let body =
        json.array(commands, fn(c) {
          json.object([
            #("name", json.string(c.0)),
            #("response", json.string(c.1)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_add_banned_word(req: Request, repo: Repository) -> Response {
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
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_remove_banned_word(req: Request, repo: Repository) -> Response {
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
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_set_command(req: Request, repo: Repository) -> Response {
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
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_delete_command(req: Request, repo: Repository) -> Response {
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
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}
