import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import kira_caster/core/config.{type Config}
import kira_caster/event_bus.{type EventBusMessage}
import kira_caster/platform/adapter.{type Adapter, Adapter}
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime/token_manager.{type TokenMessage}
import kira_caster/platform/cime/types
import kira_caster/platform/cime/ws_manager.{type WsMessage}
import kira_caster/storage/repository.{type Repository}

pub type CimeConnection {
  CimeConnection(
    adapter: Adapter,
    api: CimeApi,
    token_manager: Subject(TokenMessage),
    ws_manager: Subject(WsMessage),
    get_token: fn() -> Result(String, String),
  )
}

pub fn new(
  config: Config,
  repo: Repository,
  event_bus: Subject(EventBusMessage),
) -> Result(CimeConnection, String) {
  let api = api.new(config.cime_client_id, config.cime_client_secret)

  // Start token manager
  use token_started <- result.try(
    token_manager.start(api, repo)
    |> result.map_error(fn(_) { "Failed to start token manager" }),
  )
  let token_mgr = token_started.data

  // Start WS manager
  use ws_started <- result.try(
    ws_manager.start(
      token_mgr,
      api,
      event_bus,
      config.cime_channel_id,
      config.max_reconnect_attempts,
    )
    |> result.map_error(fn(_) { "Failed to start WS manager" }),
  )
  let ws_mgr = ws_started.data

  let get_token = fn() { token_manager.get_access_token(token_mgr) }

  let send_message = fn(message: String) {
    case get_token() {
      Ok(token) -> {
        // Split messages over 100 chars
        let parts = split_message(message, 100)
        send_parts(api, token, parts)
      }
      Error(e) -> Error(adapter.SendFailed("No token: " <> e))
    }
  }

  let connect_fn = fn() {
    ws_manager.connect(ws_mgr)
    Ok(Nil)
  }

  let disconnect_fn = fn() {
    ws_manager.disconnect(ws_mgr)
    let _ = token_manager.revoke_and_clear(token_mgr)
    Ok(Nil)
  }

  let adapter =
    Adapter(send_message:, connect: connect_fn, disconnect: disconnect_fn)

  Ok(CimeConnection(
    adapter:,
    api:,
    token_manager: token_mgr,
    ws_manager: ws_mgr,
    get_token:,
  ))
}

fn split_message(message: String, max_len: Int) -> List(String) {
  case string.length(message) <= max_len {
    True -> [message]
    False -> do_split(message, max_len, [])
  }
}

fn do_split(remaining: String, max_len: Int, acc: List(String)) -> List(String) {
  case string.length(remaining) <= max_len {
    True -> list.reverse([remaining, ..acc])
    False -> {
      let chunk = string.slice(remaining, 0, max_len)
      let rest = string.drop_start(remaining, max_len)
      do_split(rest, max_len, [chunk, ..acc])
    }
  }
}

fn send_parts(
  api: CimeApi,
  token: String,
  parts: List(String),
) -> Result(Nil, adapter.AdapterError) {
  case parts {
    [] -> Ok(Nil)
    [part, ..rest] -> {
      case api.send_chat(token, part) {
        Ok(_) -> send_parts(api, token, rest)
        Error(e) ->
          Error(adapter.SendFailed(
            "Chat send failed: " <> inspect_cime_error(e),
          ))
      }
    }
  }
}

fn inspect_cime_error(e: types.CimeError) -> String {
  case e {
    types.HttpError(reason:) -> reason
    types.ApiError(status:, message:) ->
      int.to_string(status) <> ": " <> message
    types.JsonDecodeError(reason:) -> reason
  }
}
