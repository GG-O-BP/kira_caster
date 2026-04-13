import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/list
import gleam/result
import gleam/string
import kira_caster/platform/cime/types.{type CimeError, ApiError, HttpError}

const base_url = "https://ci.me"

const api_path = "/api/openapi"

pub fn get_with_client_auth(
  path: String,
  client_id: String,
  client_secret: String,
  query: List(#(String, String)),
) -> Result(String, CimeError) {
  let full_path = build_path(path, query)
  use req <- result.try(build_request(full_path, http.Get))
  let req =
    req
    |> request.set_header("client-id", client_id)
    |> request.set_header("client-secret", client_secret)
  send_and_extract(req)
}

pub fn get_with_bearer(
  path: String,
  token: String,
  query: List(#(String, String)),
) -> Result(String, CimeError) {
  let full_path = build_path(path, query)
  use req <- result.try(build_request(full_path, http.Get))
  let req = request.set_header(req, "authorization", "Bearer " <> token)
  send_and_extract(req)
}

pub fn post_json_with_bearer(
  path: String,
  token: String,
  body: String,
) -> Result(String, CimeError) {
  use req <- result.try(build_request(api_path <> path, http.Post))
  let req =
    req
    |> request.set_header("authorization", "Bearer " <> token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)
  send_and_extract(req)
}

pub fn post_json(path: String, body: String) -> Result(String, CimeError) {
  use req <- result.try(build_request(api_path <> path, http.Post))
  let req =
    req
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)
  send_and_extract(req)
}

pub fn put_json_with_bearer(
  path: String,
  token: String,
  body: String,
) -> Result(String, CimeError) {
  use req <- result.try(build_request(api_path <> path, http.Put))
  let req =
    req
    |> request.set_header("authorization", "Bearer " <> token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)
  send_and_extract(req)
}

pub fn patch_json_with_bearer(
  path: String,
  token: String,
  body: String,
) -> Result(String, CimeError) {
  use req <- result.try(build_request(api_path <> path, http.Patch))
  let req =
    req
    |> request.set_header("authorization", "Bearer " <> token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)
  send_and_extract(req)
}

pub fn delete_json_with_bearer(
  path: String,
  token: String,
  body: String,
) -> Result(String, CimeError) {
  use req <- result.try(build_request(api_path <> path, http.Delete))
  let req =
    req
    |> request.set_header("authorization", "Bearer " <> token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)
  send_and_extract(req)
}

pub fn get_no_auth(
  path: String,
  query: List(#(String, String)),
) -> Result(String, CimeError) {
  let full_path = build_path(path, query)
  use req <- result.try(build_request(full_path, http.Get))
  send_and_extract(req)
}

pub fn post_with_bearer_query(
  path: String,
  token: String,
  query: List(#(String, String)),
) -> Result(String, CimeError) {
  let full_path = build_path(api_path <> path, query)
  use req <- result.try(build_request(full_path, http.Post))
  let req =
    req
    |> request.set_header("authorization", "Bearer " <> token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body("{}")
  send_and_extract(req)
}

fn build_path(path: String, query: List(#(String, String))) -> String {
  case query {
    [] -> path
    _ -> {
      let qs =
        list.map(query, fn(pair) { pair.0 <> "=" <> pair.1 })
        |> string.join("&")
      path <> "?" <> qs
    }
  }
}

fn build_request(
  path: String,
  method: http.Method,
) -> Result(request.Request(String), CimeError) {
  request.to(base_url <> path)
  |> result.map(request.set_method(_, method))
  |> result.map_error(fn(_) { HttpError("Invalid URL: " <> path) })
}

fn send_and_extract(req: request.Request(String)) -> Result(String, CimeError) {
  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(e) { HttpError(string.inspect(e)) }),
  )
  handle_response(resp)
}

fn handle_response(resp: response.Response(String)) -> Result(String, CimeError) {
  case resp.status {
    status if status >= 200 && status < 300 -> Ok(resp.body)
    status -> {
      let message = extract_error_message(resp.body)
      Error(ApiError(status:, message:))
    }
  }
}

fn extract_error_message(body: String) -> String {
  // Simple string extraction from JSON error body
  case string.contains(body, "\"message\"") {
    True -> {
      case string.split(body, "\"message\":") {
        [_, rest] ->
          case string.split(rest, "\"") {
            [_, msg, ..] -> msg
            _ -> body
          }
        _ -> body
      }
    }
    False -> body
  }
}
