import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/option.{type Option}
import kira_caster/admin/auth
import kira_caster/admin/handlers/command_handler
import kira_caster/admin/handlers/filter_handler
import kira_caster/admin/handlers/plugin_handler
import kira_caster/admin/handlers/quiz_handler
import kira_caster/admin/handlers/settings_handler
import kira_caster/admin/handlers/song_handler
import kira_caster/admin/handlers/status_handler
import kira_caster/admin/handlers/user_handler
import kira_caster/admin/handlers/vote_handler
import kira_caster/admin/views/dashboard_page
import kira_caster/admin/views/player_page
import kira_caster/event_bus
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  repo: Repository,
  start_time: Int,
  admin_key: String,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  case request.path_segments(req) {
    ["player"] -> player_page.handle_player_page()
    ["songs", ..] -> song_handler.route_songs(req, repo)
    _ ->
      case auth.check_auth(req, admin_key) {
        False -> wisp.response(401) |> wisp.string_body("Unauthorized")
        True -> route(req, repo, start_time, bus)
      }
  }
}

fn route(
  req: Request,
  repo: Repository,
  start_time: Int,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  case req.method, request.path_segments(req) {
    http.Get, ["status"] -> status_handler.handle_status(start_time)
    http.Get, ["users"] -> user_handler.handle_users(repo)
    http.Get, ["banned-words"] -> filter_handler.handle_banned_words(repo)
    http.Get, ["commands"] -> command_handler.handle_commands(repo)
    http.Post, ["banned-words"] ->
      filter_handler.handle_add_banned_word(req, repo)
    http.Delete, ["banned-words"] ->
      filter_handler.handle_remove_banned_word(req, repo)
    http.Post, ["commands"] -> command_handler.handle_set_command(req, repo)
    http.Delete, ["commands"] ->
      command_handler.handle_delete_command(req, repo)
    http.Get, ["votes"] -> vote_handler.handle_get_votes(repo)
    http.Post, ["votes"] -> vote_handler.handle_start_vote(req, repo)
    http.Delete, ["votes"] -> vote_handler.handle_end_vote(repo)
    http.Get, ["quizzes"] -> quiz_handler.handle_get_quizzes(repo)
    http.Post, ["quizzes"] -> quiz_handler.handle_add_quiz(req, repo)
    http.Delete, ["quizzes"] -> quiz_handler.handle_delete_quiz(req, repo)
    http.Get, ["plugins"] -> plugin_handler.handle_get_plugins(repo)
    http.Post, ["plugins"] -> plugin_handler.handle_set_plugin(req, repo, bus)
    http.Get, ["settings"] -> settings_handler.handle_get_settings(repo)
    http.Post, ["settings"] ->
      settings_handler.handle_set_setting(req, repo, bus)
    http.Post, ["commands", "advanced"] ->
      command_handler.handle_add_advanced_command(req, repo)
    http.Post, ["commands", "compile"] ->
      command_handler.handle_compile_command(req, repo)
    http.Get, [] -> dashboard_page.handle_dashboard()
    _, _ -> wisp.not_found()
  }
}
