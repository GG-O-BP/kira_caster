import gleam/list
import kira_caster/admin/views/setup_page
import kira_caster/storage/repository.{type Repository}
import wisp.{type Request, type Response}

@external(erlang, "kira_caster_ffi", "restart_application")
fn restart_application() -> Nil

pub fn is_setup_complete(repo: Repository) -> Bool {
  case repo.get_setting("setup_complete") {
    Ok("true") -> True
    _ -> False
  }
}

pub fn handle_setup(req: Request, repo: Repository) -> Response {
  case wisp.get_query(req) |> list.find(fn(p) { p.0 == "skip" }) {
    Ok(_) -> handle_skip(repo)
    Error(_) -> setup_page.handle_setup("", False)
  }
}

pub fn handle_setup_submit(req: Request, repo: Repository) -> Response {
  use form <- wisp.require_form(req)
  let vals = form.values

  let admin_key = find_value(vals, "admin_key")
  let cime_client_id = find_value(vals, "cime_client_id")
  let cime_client_secret = find_value(vals, "cime_client_secret")

  // Save non-empty values to DB settings
  save_if_set(repo, "admin_key", admin_key)
  save_if_set(repo, "cime_client_id", cime_client_id)
  save_if_set(repo, "cime_client_secret", cime_client_secret)

  // Redirect URI: auto-set default when client_id is provided
  case cime_client_id {
    "" -> Nil
    _ -> {
      let _ =
        repo.set_setting(
          "cime_redirect_uri",
          "http://localhost:8080/oauth/callback",
        )
      Nil
    }
  }

  // Mark setup as complete
  let _ = repo.set_setting("setup_complete", "true")

  // Trigger auto-restart (2 second delay in FFI to allow response)
  restart_application()

  setup_page.handle_setup_done()
}

fn handle_skip(repo: Repository) -> Response {
  let _ = repo.set_setting("setup_complete", "true")
  wisp.redirect("/")
}

fn find_value(values: List(#(String, String)), key: String) -> String {
  case list.find(values, fn(v) { v.0 == key }) {
    Ok(#(_, v)) -> v
    Error(_) -> ""
  }
}

fn save_if_set(repo: Repository, key: String, value: String) -> Nil {
  case value {
    "" -> Nil
    v -> {
      let _ = repo.set_setting(key, v)
      Nil
    }
  }
}
