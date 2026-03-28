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
      let auth = request.get_header(req, "authorization")
      case auth {
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
    http.Post, ["banned-words", word] -> handle_add_banned_word(repo, word)
    http.Delete, ["banned-words", word] -> handle_remove_banned_word(repo, word)
    http.Post, ["commands", name, response] ->
      handle_set_command(repo, name, response)
    http.Delete, ["commands", name] -> handle_delete_command(repo, name)
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

fn handle_add_banned_word(repo: Repository, word: String) -> Response {
  case repo.add_banned_word(string.lowercase(word)) {
    Ok(Nil) -> {
      let body = json.object([#("added", json.string(word))])
      wisp.json_response(json.to_string(body), 201)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_remove_banned_word(repo: Repository, word: String) -> Response {
  case repo.remove_banned_word(string.lowercase(word)) {
    Ok(Nil) -> {
      let body = json.object([#("removed", json.string(word))])
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_set_command(
  repo: Repository,
  name: String,
  response: String,
) -> Response {
  case repo.set_command(name, response) {
    Ok(Nil) -> {
      let body =
        json.object([
          #("name", json.string(name)),
          #("response", json.string(response)),
        ])
      wisp.json_response(json.to_string(body), 201)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_delete_command(repo: Repository, name: String) -> Response {
  case repo.delete_command(name) {
    Ok(Nil) -> {
      let body = json.object([#("deleted", json.string(name))])
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}
