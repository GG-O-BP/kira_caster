import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn route_songs(req: Request, repo: Repository) -> Response {
  case req.method, request.path_segments(req) {
    http.Get, ["songs"] -> handle_get_songs(repo)
    http.Post, ["songs"] -> handle_add_song(req, repo)
    http.Delete, ["songs"] -> handle_remove_song(req, repo)
    http.Post, ["songs", "reorder"] -> handle_reorder_song(req, repo)
    http.Get, ["songs", "current"] -> handle_get_current_song(repo)
    http.Post, ["songs", "next"] -> handle_next_song(repo)
    http.Post, ["songs", "previous"] -> handle_prev_song(repo)
    http.Post, ["songs", "replay"] -> handle_replay_song(repo)
    _, _ -> wisp.not_found()
  }
}

fn song_to_json(s: repository.SongData) -> json.Json {
  json.object([
    #("id", json.int(s.id)),
    #("video_id", json.string(s.video_id)),
    #("title", json.string(s.title)),
    #("duration_seconds", json.int(s.duration_seconds)),
    #("requested_by", json.string(s.requested_by)),
    #("position", json.int(s.position)),
  ])
}

fn handle_get_songs(repo: Repository) -> Response {
  case repo.get_song_queue() {
    Ok(songs) ->
      wisp.json_response(json.to_string(json.array(songs, song_to_json)), 200)
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_add_song(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use video_id <- decode.field("video_id", decode.string)
    use title <- decode.field("title", decode.string)
    use duration <- decode.field("duration_seconds", decode.int)
    use requested_by <- decode.optional_field(
      "requested_by",
      "dashboard",
      decode.string,
    )
    decode.success(#(video_id, title, duration, requested_by))
  }
  case decode.run(body, decoder) {
    Ok(#(video_id, title, duration, requested_by)) ->
      case repo.add_song(video_id, title, duration, requested_by) {
        Ok(song) -> wisp.json_response(json.to_string(song_to_json(song)), 201)
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_remove_song(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("id", decode.int, fn(id) { decode.success(id) })
  case decode.run(body, decoder) {
    Ok(id) ->
      case repo.remove_song(id) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("deleted", json.int(id))])),
            200,
          )
        Error(_) -> wisp.response(404) |> wisp.string_body("song not found")
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_reorder_song(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use id <- decode.field("id", decode.int)
    use new_position <- decode.field("new_position", decode.int)
    decode.success(#(id, new_position))
  }
  case decode.run(body, decoder) {
    Ok(#(id, new_position)) ->
      case repo.reorder_song(id, new_position) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("ok", json.bool(True))])),
            200,
          )
        Error(_) -> wisp.response(404) |> wisp.string_body("song not found")
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_get_current_song(repo: Repository) -> Response {
  let current_id = get_song_setting(repo, "song_current_id", "")
  let version = get_song_setting(repo, "song_current_version", "0")
  case current_id {
    "" ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("current", json.null()),
            #("version", json.string(version)),
          ]),
        ),
        200,
      )
    _ ->
      case repo.get_song_queue() {
        Ok(songs) ->
          case list.find(songs, fn(s) { int.to_string(s.id) == current_id }) {
            Ok(s) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("current", song_to_json(s)),
                    #("version", json.string(version)),
                  ]),
                ),
                200,
              )
            Error(_) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("current", json.null()),
                    #("version", json.string(version)),
                  ]),
                ),
                200,
              )
          }
        Error(_) -> wisp.internal_server_error()
      }
  }
}

fn handle_next_song(repo: Repository) -> Response {
  advance_and_respond(repo, "forward")
}

fn handle_prev_song(repo: Repository) -> Response {
  advance_and_respond(repo, "backward")
}

fn handle_replay_song(repo: Repository) -> Response {
  let v = get_song_setting(repo, "song_current_version", "0")
  let next_v = case int.parse(v) {
    Ok(n) -> int.to_string(n + 1)
    Error(_) -> "1"
  }
  let _ = repo.set_setting("song_current_version", next_v)
  handle_get_current_song(repo)
}

fn advance_and_respond(repo: Repository, direction: String) -> Response {
  case repo.get_song_queue() {
    Error(_) -> wisp.internal_server_error()
    Ok(songs) -> {
      let current_id = get_song_setting(repo, "song_current_id", "")
      let next = case current_id {
        "" ->
          case direction {
            "forward" -> list.first(songs)
            _ -> list.last(songs)
          }
        _ -> find_adjacent_song(songs, current_id, direction)
      }
      case next {
        Ok(s) -> {
          let _ = repo.set_setting("song_current_id", int.to_string(s.id))
          let v = get_song_setting(repo, "song_current_version", "0")
          let next_v = case int.parse(v) {
            Ok(n) -> int.to_string(n + 1)
            Error(_) -> "1"
          }
          let _ = repo.set_setting("song_current_version", next_v)
          wisp.json_response(
            json.to_string(
              json.object([
                #("current", song_to_json(s)),
                #("version", json.string(next_v)),
              ]),
            ),
            200,
          )
        }
        Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("current", json.null()),
                #(
                  "version",
                  json.string(get_song_setting(
                    repo,
                    "song_current_version",
                    "0",
                  )),
                ),
              ]),
            ),
            200,
          )
      }
    }
  }
}

fn find_adjacent_song(
  songs: List(repository.SongData),
  current_id: String,
  direction: String,
) -> Result(repository.SongData, Nil) {
  do_find_adjacent_song(songs, current_id, direction, None)
}

fn do_find_adjacent_song(
  songs: List(repository.SongData),
  current_id: String,
  direction: String,
  prev: Option(repository.SongData),
) -> Result(repository.SongData, Nil) {
  case songs {
    [] -> Error(Nil)
    [s, ..rest] ->
      case int.to_string(s.id) == current_id {
        True ->
          case direction {
            "forward" ->
              case rest {
                [next, ..] -> Ok(next)
                [] -> Error(Nil)
              }
            _ ->
              case prev {
                Some(p) -> Ok(p)
                None -> Error(Nil)
              }
          }
        False -> do_find_adjacent_song(rest, current_id, direction, Some(s))
      }
  }
}

fn get_song_setting(repo: Repository, key: String, default: String) -> String {
  case repo.get_setting(key) {
    Ok(val) -> val
    Error(_) -> default
  }
}
