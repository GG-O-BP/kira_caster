import gleam/json
import kira_caster/storage/repository.{type Repository}
import wisp.{type Response}

pub fn handle_users(repo: Repository) -> Response {
  case repo.get_all_users() {
    Ok(users) -> {
      let body =
        json.array(users, fn(u) {
          json.object([
            #("user_id", json.string(u.user_id)),
            #("points", json.int(u.points)),
            #("attendance_count", json.int(u.attendance_count)),
            #("last_attendance", json.int(u.last_attendance)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("status", json.string("error")),
            #("message", json.string("유저 목록을 불러올 수 없습니다")),
          ]),
        ),
        500,
      )
  }
}
