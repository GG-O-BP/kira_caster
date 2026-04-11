import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/option.{type Option}
import kira_caster/admin/auth
import kira_caster/admin/handlers/cime_handler
import kira_caster/admin/handlers/command_handler
import kira_caster/admin/handlers/filter_handler
import kira_caster/admin/handlers/oauth_handler
import kira_caster/admin/handlers/plugin_handler
import kira_caster/admin/handlers/quiz_handler
import kira_caster/admin/handlers/settings_handler
import kira_caster/admin/handlers/setup_handler
import kira_caster/admin/handlers/song_handler
import kira_caster/admin/handlers/status_handler
import kira_caster/admin/handlers/user_handler
import kira_caster/admin/handlers/vote_handler
import kira_caster/admin/views/dashboard_page
import kira_caster/admin/views/login_page
import kira_caster/admin/views/player_page
import kira_caster/core/config.{type Config}
import kira_caster/event_bus
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime/token_manager.{type TokenMessage}
import kira_caster/platform/cime/ws_manager.{type WsMessage}
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

pub type RouterContext {
  RouterContext(
    repo: Repository,
    start_time: Int,
    admin_key: String,
    config: Config,
    bus: Option(process.Subject(event_bus.EventBusMessage)),
    token_manager: Option(process.Subject(TokenMessage)),
    cime_api: Option(CimeApi),
    get_token: Option(fn() -> Result(String, String)),
    ws_manager: Option(process.Subject(WsMessage)),
  )
}

pub fn handle_request(req: Request, ctx: RouterContext) -> Response {
  case request.path_segments(req) {
    ["player"] -> player_page.handle_player_page()
    ["songs", ..] -> song_handler.route_songs(req, ctx.repo)
    // OAuth callback is unauthenticated (redirect from ci.me)
    ["oauth", "callback"] ->
      oauth_handler.handle_callback(
        req,
        ctx.token_manager,
        ctx.cime_api,
        ctx.repo,
      )
    // Setup wizard (unauthenticated, first-run only)
    ["setup"] -> handle_setup_route(req, ctx)
    // Login routes (unauthenticated)
    ["login"] -> handle_login(req, ctx)
    ["logout"] -> handle_logout(req)
    _ ->
      // First-run: redirect to setup wizard
      case setup_handler.is_setup_complete(ctx.repo) {
        False -> wisp.redirect("/setup")
        True ->
          case auth.check_auth(req, ctx.admin_key) {
            False -> {
              // If admin_key is set but not authenticated, show login page
              case ctx.admin_key {
                "" -> route(req, ctx)
                _ -> wisp.redirect("/login")
              }
            }
            True -> route(req, ctx)
          }
      }
  }
}

fn handle_setup_route(req: Request, ctx: RouterContext) -> Response {
  case setup_handler.is_setup_complete(ctx.repo) {
    True -> wisp.redirect("/")
    False ->
      case req.method {
        http.Get -> setup_handler.handle_setup(req, ctx.repo)
        http.Post -> setup_handler.handle_setup_submit(req, ctx.repo)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
  }
}

fn handle_login(req: Request, ctx: RouterContext) -> Response {
  case req.method {
    http.Get -> login_page.handle_login("")
    http.Post -> {
      use form <- wisp.require_form(req)
      let password = find_form_value(form.values, "password")
      case password {
        "" -> login_page.handle_login("비밀번호를 입력해주세요")
        pw ->
          case pw == ctx.admin_key {
            True -> {
              wisp.redirect("/")
              |> auth.set_session(req, ctx.admin_key)
            }
            False -> login_page.handle_login("비밀번호가 일치하지 않습니다")
          }
      }
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_logout(req: Request) -> Response {
  wisp.redirect("/login")
  |> auth.clear_session(req)
}

fn find_form_value(values: List(#(String, String)), key: String) -> String {
  case values {
    [] -> ""
    [#(k, v), ..] if k == key -> v
    [_, ..rest] -> find_form_value(rest, key)
  }
}

@external(erlang, "kira_caster_ffi", "restart_application")
fn restart_application() -> Nil

fn handle_restart() -> Response {
  restart_application()
  wisp.json_response("{\"ok\":true}", 200)
}

fn route(req: Request, ctx: RouterContext) -> Response {
  case req.method, request.path_segments(req) {
    http.Get, ["status"] -> status_handler.handle_status(ctx.start_time)
    http.Get, ["users"] -> user_handler.handle_users(ctx.repo)
    http.Get, ["banned-words"] -> filter_handler.handle_banned_words(ctx.repo)
    http.Get, ["commands"] -> command_handler.handle_commands(ctx.repo)
    http.Post, ["banned-words"] ->
      filter_handler.handle_add_banned_word(req, ctx.repo)
    http.Delete, ["banned-words"] ->
      filter_handler.handle_remove_banned_word(req, ctx.repo)
    http.Post, ["commands"] -> command_handler.handle_set_command(req, ctx.repo)
    http.Delete, ["commands"] ->
      command_handler.handle_delete_command(req, ctx.repo)
    http.Get, ["votes"] -> vote_handler.handle_get_votes(ctx.repo)
    http.Post, ["votes"] -> vote_handler.handle_start_vote(req, ctx.repo)
    http.Delete, ["votes"] -> vote_handler.handle_end_vote(ctx.repo)
    http.Get, ["quizzes"] -> quiz_handler.handle_get_quizzes(ctx.repo)
    http.Post, ["quizzes"] -> quiz_handler.handle_add_quiz(req, ctx.repo)
    http.Delete, ["quizzes"] -> quiz_handler.handle_delete_quiz(req, ctx.repo)
    http.Get, ["plugins"] -> plugin_handler.handle_get_plugins(ctx.repo)
    http.Post, ["plugins"] ->
      plugin_handler.handle_set_plugin(req, ctx.repo, ctx.bus)
    http.Get, ["settings"] -> settings_handler.handle_get_settings(ctx.repo)
    http.Post, ["settings"] ->
      settings_handler.handle_set_setting(req, ctx.repo, ctx.bus)
    http.Post, ["commands", "advanced"] ->
      command_handler.handle_add_advanced_command(req, ctx.repo)
    http.Post, ["commands", "compile"] ->
      command_handler.handle_compile_command(req, ctx.repo)
    // OAuth routes
    http.Get, ["oauth", "authorize"] ->
      oauth_handler.handle_authorize(req, ctx.config)
    http.Get, ["oauth", "status"] ->
      oauth_handler.handle_status(req, ctx.token_manager)
    http.Post, ["oauth", "disconnect"] ->
      oauth_handler.handle_disconnect(req, ctx.token_manager)
    // Cime API proxy routes
    http.Get, ["cime", "live-status"] ->
      cime_handler.handle_live_status(
        req,
        ctx.cime_api,
        ctx.config.cime_channel_id,
      )
    http.Get, ["cime", "live-setting"] ->
      cime_handler.handle_live_setting(req, ctx.cime_api, ctx.get_token)
    http.Patch, ["cime", "live-setting"] ->
      cime_handler.handle_update_live_setting(req, ctx.cime_api, ctx.get_token)
    http.Get, ["cime", "chat-settings"] ->
      cime_handler.handle_chat_settings(req, ctx.cime_api, ctx.get_token)
    http.Put, ["cime", "chat-settings"] ->
      cime_handler.handle_update_chat_settings(req, ctx.cime_api, ctx.get_token)
    http.Get, ["cime", "blocked-users"] ->
      cime_handler.handle_blocked_users(req, ctx.cime_api, ctx.get_token)
    http.Post, ["cime", "block"] ->
      cime_handler.handle_block_user(req, ctx.cime_api, ctx.get_token)
    http.Delete, ["cime", "block"] ->
      cime_handler.handle_unblock_user(req, ctx.cime_api, ctx.get_token)
    http.Get, ["cime", "channel-info"] ->
      cime_handler.handle_channel_info(req, ctx.cime_api, ctx.get_token)
    http.Get, ["cime", "stream-key"] ->
      cime_handler.handle_stream_key(req, ctx.cime_api, ctx.get_token)
    http.Get, ["cime", "categories"] ->
      cime_handler.handle_categories(req, ctx.cime_api)
    http.Post, ["restart"] -> handle_restart()
    http.Get, [] -> dashboard_page.handle_dashboard()
    _, _ -> wisp.not_found()
  }
}
