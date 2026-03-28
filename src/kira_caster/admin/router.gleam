import gleam/http
import gleam/http/request
import gleam/json
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  repo: Repository,
  start_time: Int,
) -> Response {
  case req.method, request.path_segments(req) {
    http.Get, ["status"] -> handle_status(start_time)
    http.Get, ["users"] -> handle_users(repo)
    http.Get, ["banned-words"] -> handle_banned_words(repo)
    http.Get, ["commands"] -> handle_commands(repo)
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
