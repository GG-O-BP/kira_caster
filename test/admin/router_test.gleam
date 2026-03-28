import gleam/http
import gleam/json
import gleam/option.{None}
import kira_caster/admin/router
import kira_caster/storage/repository
import wisp/simulate

fn handle(req) {
  let repo = repository.mock_repo([])
  router.handle_request(req, repo, 0, "", None)
}

fn handle_with_key(req) {
  let repo = repository.mock_repo([])
  router.handle_request(req, repo, 0, "secret123", None)
}

pub fn get_status_test() {
  let response =
    simulate.request(http.Get, "/status")
    |> handle
  assert response.status == 200
  let body = simulate.read_body(response)
  assert {
    case body {
      "{" <> _ -> True
      _ -> False
    }
  }
}

pub fn get_users_test() {
  let response =
    simulate.request(http.Get, "/users")
    |> handle
  assert response.status == 200
}

pub fn get_banned_words_test() {
  let response =
    simulate.request(http.Get, "/banned-words")
    |> handle
  assert response.status == 200
}

pub fn get_commands_test() {
  let response =
    simulate.request(http.Get, "/commands")
    |> handle
  assert response.status == 200
}

pub fn not_found_test() {
  let response =
    simulate.request(http.Get, "/unknown")
    |> handle
  assert response.status == 404
}

pub fn auth_required_no_header_test() {
  let response =
    simulate.request(http.Get, "/status")
    |> handle_with_key
  assert response.status == 401
}

pub fn auth_required_wrong_key_test() {
  let response =
    simulate.request(http.Get, "/status")
    |> simulate.header("authorization", "Bearer wrong")
    |> handle_with_key
  assert response.status == 401
}

pub fn auth_required_correct_key_test() {
  let response =
    simulate.request(http.Get, "/status")
    |> simulate.header("authorization", "Bearer secret123")
    |> handle_with_key
  assert response.status == 200
}

pub fn post_banned_word_test() {
  let response =
    simulate.request(http.Post, "/banned-words")
    |> simulate.json_body(json.object([#("word", json.string("test"))]))
    |> handle
  assert response.status == 201
}

pub fn delete_banned_word_test() {
  let response =
    simulate.request(http.Delete, "/banned-words")
    |> simulate.json_body(json.object([#("word", json.string("test"))]))
    |> handle
  assert response.status == 200
}

pub fn post_command_test() {
  let response =
    simulate.request(http.Post, "/commands")
    |> simulate.json_body(
      json.object([
        #("name", json.string("인사")),
        #("response", json.string("안녕!")),
      ]),
    )
    |> handle
  assert response.status == 201
}

pub fn delete_command_test() {
  let response =
    simulate.request(http.Delete, "/commands")
    |> simulate.json_body(json.object([#("name", json.string("인사"))]))
    |> handle
  assert response.status == 200
}

pub fn get_votes_no_active_test() {
  let response =
    simulate.request(http.Get, "/votes")
    |> handle
  assert response.status == 200
}

pub fn post_votes_test() {
  let response =
    simulate.request(http.Post, "/votes")
    |> simulate.json_body(
      json.object([
        #("topic", json.string("좋아하는 색")),
        #("options", json.array(["빨강", "파랑"], json.string)),
      ]),
    )
    |> handle
  assert response.status == 201
}

pub fn delete_votes_no_active_test() {
  let response =
    simulate.request(http.Delete, "/votes")
    |> handle
  assert response.status == 404
}

pub fn get_quizzes_test() {
  let response =
    simulate.request(http.Get, "/quizzes")
    |> handle
  assert response.status == 200
}

pub fn post_quiz_test() {
  let response =
    simulate.request(http.Post, "/quizzes")
    |> simulate.json_body(
      json.object([
        #("question", json.string("1+1=?")),
        #("answer", json.string("2")),
        #("reward", json.int(10)),
      ]),
    )
    |> handle
  assert response.status == 201
}

pub fn delete_quiz_test() {
  let response =
    simulate.request(http.Delete, "/quizzes")
    |> simulate.json_body(json.object([#("question", json.string("1+1=?"))]))
    |> handle
  assert response.status == 200
}

pub fn get_plugins_test() {
  let response =
    simulate.request(http.Get, "/plugins")
    |> handle
  assert response.status == 200
}

pub fn set_plugin_enabled_test() {
  let response =
    simulate.request(http.Post, "/plugins")
    |> simulate.json_body(
      json.object([
        #("name", json.string("attendance")),
        #("enabled", json.bool(False)),
      ]),
    )
    |> handle
  assert response.status == 200
}

pub fn get_dashboard_html_test() {
  let response =
    simulate.request(http.Get, "/")
    |> handle
  assert response.status == 200
}
