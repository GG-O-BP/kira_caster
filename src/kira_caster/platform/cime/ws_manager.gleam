import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import kira_caster/core/permission
import kira_caster/event_bus.{type EventBusMessage}
import kira_caster/logger
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime/token_manager.{type TokenMessage}
import kira_caster/platform/ws
import kira_caster/plugin/plugin
import kira_caster/util/time

// FFI for WebSocket operations
@external(erlang, "cime_ws_ffi", "ws_connect")
fn ws_connect_ffi(url: String) -> Result(dynamic.Dynamic, String)

@external(erlang, "cime_ws_ffi", "ws_send")
fn ws_send_ffi(conn: dynamic.Dynamic, message: String) -> Result(Nil, String)

@external(erlang, "cime_ws_ffi", "ws_close")
fn ws_close_ffi(conn: dynamic.Dynamic) -> Result(Nil, String)

pub type WsMessage {
  Connect
  Disconnect
  WsReceived(data: String)
  SendPing
  CheckLifecycle
  WsDisconnected(reason: String)
  Reconnect
  GetConnectionStatus(reply: Subject(ConnectionStatus))
}

pub type ConnectionStatus {
  ConnectionStatus(
    state: ws.WsState,
    reconnect_attempt: Int,
    max_reconnect: Int,
  )
}

pub type WsSessionState {
  WsSessionState(
    session_key: Option(String),
    ws_connection: Option(dynamic.Dynamic),
    ws_state: ws.WsState,
    token_manager: Subject(TokenMessage),
    api: CimeApi,
    event_bus: Subject(EventBusMessage),
    channel_id: String,
    subject: Subject(WsMessage),
    session_created_at: Int,
    ws_connected_at: Int,
    max_reconnect: Int,
  )
}

pub fn start(
  token_manager: Subject(TokenMessage),
  api: CimeApi,
  event_bus: Subject(EventBusMessage),
  channel_id: String,
  max_reconnect: Int,
) -> Result(actor.Started(Subject(WsMessage)), actor.StartError) {
  actor.new_with_initialiser(5000, fn(subject) {
    let state =
      WsSessionState(
        session_key: None,
        ws_connection: None,
        ws_state: ws.Disconnected,
        token_manager:,
        api:,
        event_bus:,
        channel_id:,
        subject:,
        session_created_at: 0,
        ws_connected_at: 0,
        max_reconnect:,
      )
    actor.initialised(state)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
}

fn handle_message(
  state: WsSessionState,
  message: WsMessage,
) -> actor.Next(WsSessionState, WsMessage) {
  case message {
    Connect -> {
      case do_connect(state) {
        Ok(new_state) -> {
          logger.info("WebSocket connected to ci.me")
          // Start PING timer (every 55 seconds to be safe under 60s limit)
          process.send_after(new_state.subject, 55_000, SendPing)
          // Start lifecycle check timer (every 60 seconds)
          process.send_after(new_state.subject, 60_000, CheckLifecycle)
          actor.continue(new_state)
        }
        Error(reason) -> {
          logger.error("WebSocket connect failed: " <> reason)
          actor.continue(state)
        }
      }
    }

    Disconnect -> {
      let new_state = do_disconnect(state)
      logger.info("WebSocket disconnected")
      actor.continue(new_state)
    }

    WsReceived(data) -> {
      parse_and_dispatch(data, state.event_bus)
      actor.continue(state)
    }

    SendPing -> {
      case state.ws_connection {
        Some(conn) -> {
          let _ = ws_send_ffi(conn, "{\"type\":\"PING\"}")
          process.send_after(state.subject, 55_000, SendPing)
          Nil
        }
        None -> Nil
      }
      actor.continue(state)
    }

    CheckLifecycle -> {
      let now = time.now_ms()
      let new_state = case state.ws_state {
        ws.Connected -> {
          // WS max 2 hours = 7_200_000ms, reconnect at 110 min
          let ws_age = now - state.ws_connected_at
          case ws_age > 6_600_000 {
            True -> {
              logger.info("WS approaching 2-hour limit, reconnecting...")
              let disconnected = do_disconnect(state)
              case do_connect(disconnected) {
                Ok(s) -> s
                Error(_) -> disconnected
              }
            }
            False -> {
              // Session max 12 hours = 43_200_000ms, recreate at 11.5h
              let session_age = now - state.session_created_at
              case session_age > 41_400_000 {
                True -> {
                  logger.info(
                    "Session approaching 12-hour limit, recreating...",
                  )
                  let disconnected = do_disconnect(state)
                  case
                    do_connect(
                      WsSessionState(..disconnected, session_key: None),
                    )
                  {
                    Ok(s) -> s
                    Error(_) -> disconnected
                  }
                }
                False -> state
              }
            }
          }
        }
        _ -> state
      }
      process.send_after(new_state.subject, 60_000, CheckLifecycle)
      actor.continue(new_state)
    }

    WsDisconnected(reason) -> {
      logger.warn("WS disconnected: " <> reason)
      let new_ws_state =
        ws.transition(
          state.ws_state,
          ws.ConnectFailure(reason:),
          state.max_reconnect,
        )
      case new_ws_state {
        Ok(ws.Reconnecting(_)) -> {
          // Schedule reconnect with backoff
          process.send_after(state.subject, 5000, Reconnect)
          actor.continue(
            WsSessionState(
              ..state,
              ws_state: ws.Reconnecting(1),
              ws_connection: None,
            ),
          )
        }
        _ -> {
          logger.error("WS max reconnect attempts exceeded")
          actor.continue(
            WsSessionState(
              ..state,
              ws_state: ws.Disconnected,
              ws_connection: None,
            ),
          )
        }
      }
    }

    GetConnectionStatus(reply) -> {
      let attempt = case state.ws_state {
        ws.Reconnecting(n) -> n
        _ -> 0
      }
      process.send(
        reply,
        ConnectionStatus(
          state: state.ws_state,
          reconnect_attempt: attempt,
          max_reconnect: state.max_reconnect,
        ),
      )
      actor.continue(state)
    }

    Reconnect -> {
      logger.info("Attempting WS reconnect...")
      case do_connect(WsSessionState(..state, ws_connection: None)) {
        Ok(new_state) -> {
          logger.info("WS reconnected successfully")
          process.send_after(new_state.subject, 55_000, SendPing)
          actor.continue(new_state)
        }
        Error(reason) -> {
          logger.warn("WS reconnect failed: " <> reason)
          // Try again with exponential backoff
          case state.ws_state {
            ws.Reconnecting(n) if n < state.max_reconnect -> {
              let delay = { n + 1 } * 5000
              process.send_after(state.subject, delay, Reconnect)
              actor.continue(
                WsSessionState(..state, ws_state: ws.Reconnecting(n + 1)),
              )
            }
            _ -> {
              logger.error("WS reconnect gave up")
              actor.continue(WsSessionState(..state, ws_state: ws.Disconnected))
            }
          }
        }
      }
    }
  }
}

fn do_connect(state: WsSessionState) -> Result(WsSessionState, String) {
  // Get access token
  use token <- result.try(token_manager.get_access_token(state.token_manager))

  // Create session if needed
  let now = time.now_ms()
  use #(_session_key, session_created_at) <- result.try(case state.session_key {
    Some(key) -> Ok(#(key, state.session_created_at))
    None -> {
      use session_resp <- result.try(
        state.api.create_user_session(token)
        |> result.map_error(fn(_) { "Session creation failed" }),
      )
      // Extract session key from URL query string
      let key = extract_session_key(session_resp.url)
      Ok(#(key, now))
    }
  })

  // Get WS URL from session
  use ws_url <- result.try(case state.session_key {
    None -> {
      state.api.create_user_session(token)
      |> result.map(fn(resp) { resp.url })
      |> result.map_error(fn(_) { "Failed to get WS URL" })
    }
    Some(_) -> Ok("")
  })

  let _ws_url = ws_url

  // Connect WebSocket
  use token2 <- result.try(token_manager.get_access_token(state.token_manager))
  use session_resp <- result.try(
    state.api.create_user_session(token2)
    |> result.map_error(fn(_) { "Session creation failed" }),
  )

  use conn <- result.try(
    ws_connect_ffi(session_resp.url)
    |> result.map_error(fn(e) { "WS connect failed: " <> e }),
  )

  let actual_key = extract_session_key(session_resp.url)

  // Subscribe to events
  use _ <- result.try(subscribe_events(state.api, token, actual_key))

  // Start receiving messages in a separate process
  let bus = state.event_bus
  let subject = state.subject
  let ws_conn = conn
  process.spawn(fn() { ws_receive_loop(ws_conn, bus, subject) })

  Ok(
    WsSessionState(
      ..state,
      session_key: Some(actual_key),
      ws_connection: Some(conn),
      ws_state: ws.Connected,
      session_created_at:,
      ws_connected_at: now,
    ),
  )
}

fn do_disconnect(state: WsSessionState) -> WsSessionState {
  case state.ws_connection {
    Some(conn) -> {
      let _ = ws_close_ffi(conn)
      Nil
    }
    None -> Nil
  }
  WsSessionState(..state, ws_connection: None, ws_state: ws.Disconnected)
}

fn subscribe_events(
  api: CimeApi,
  token: String,
  session_key: String,
) -> Result(Nil, String) {
  use _ <- result.try(
    api.subscribe_event(token, session_key, "chat")
    |> result.map_error(fn(_) { "Failed to subscribe to chat" }),
  )
  use _ <- result.try(
    api.subscribe_event(token, session_key, "donation")
    |> result.map_error(fn(_) { "Failed to subscribe to donation" }),
  )
  use _ <- result.try(
    api.subscribe_event(token, session_key, "subscription")
    |> result.map_error(fn(_) { "Failed to subscribe to subscription" }),
  )
  Ok(Nil)
}

fn extract_session_key(url: String) -> String {
  case string.split(url, "sessionKey=") {
    [_, key_and_rest] ->
      case string.split(key_and_rest, "&") {
        [key, ..] -> key
        _ -> key_and_rest
      }
    _ -> ""
  }
}

fn ws_receive_loop(
  _conn: dynamic.Dynamic,
  bus: Subject(EventBusMessage),
  _ws_subject: Subject(WsMessage),
) -> Nil {
  // This is a simplified receive loop.
  // In practice, gun sends messages to the owning process.
  // The actual implementation listens via process.select for gun_ws messages.
  // For now, incoming messages are dispatched through the event bus.
  let selector =
    process.new_selector()
    |> process.select_other(fn(msg) { msg })

  receive_loop(selector, bus)
}

fn receive_loop(
  selector: process.Selector(dynamic.Dynamic),
  bus: Subject(EventBusMessage),
) -> Nil {
  let msg = process.selector_receive_forever(selector)
  // Try to decode as a gun_ws text frame
  case decode_gun_ws_frame(msg) {
    Ok(text) -> {
      parse_and_dispatch(text, bus)
      receive_loop(selector, bus)
    }
    Error(_) -> {
      // Ignore non-text messages (pong, etc.)
      receive_loop(selector, bus)
    }
  }
}

fn decode_gun_ws_frame(msg: dynamic.Dynamic) -> Result(String, Nil) {
  // gun sends {gun_ws, ConnPid, StreamRef, {text, Data}}
  let decoder =
    decode.field(
      3,
      decode.field(1, decode.string, fn(text) { decode.success(text) }),
      fn(text) { decode.success(text) },
    )
  case decode.run(msg, decoder) {
    Ok(text) -> Ok(text)
    Error(_) -> Error(Nil)
  }
}

fn parse_and_dispatch(text: String, bus: Subject(EventBusMessage)) -> Nil {
  // Parse JSON: {"event": "CHAT|DONATION|SUBSCRIPTION", "data": {...}}
  case parse_ws_event(text) {
    Ok(#("CHAT", data)) -> dispatch_chat(data, bus)
    Ok(#("DONATION", data)) -> dispatch_donation(data, bus)
    Ok(#("SUBSCRIPTION", data)) -> dispatch_subscription(data, bus)
    _ -> Nil
  }
}

fn parse_ws_event(text: String) -> Result(#(String, String), Nil) {
  let decoder =
    decode.field("event", decode.string, fn(event) { decode.success(event) })
  case json.parse(text, decoder) {
    Ok(event) -> Ok(#(event, text))
    Error(_) -> Error(Nil)
  }
}

fn dispatch_chat(data: String, bus: Subject(EventBusMessage)) -> Nil {
  let decoder = {
    use sender_channel_id <- decode.field(
      "data",
      decode.field("senderChannelId", decode.string, fn(id) {
        decode.success(id)
      }),
    )
    use nickname <- decode.field(
      "data",
      decode.field(
        "profile",
        decode.field("nickname", decode.string, fn(n) { decode.success(n) }),
        fn(n) { decode.success(n) },
      ),
    )
    use content <- decode.field(
      "data",
      decode.field("content", decode.string, fn(c) { decode.success(c) }),
    )
    use channel_id <- decode.field(
      "data",
      decode.field("channelId", decode.string, fn(id) { decode.success(id) }),
    )
    decode.success(#(nickname, content, channel_id, sender_channel_id))
  }

  case json.parse(data, decoder) {
    Ok(#(user, content, channel, sender_id)) -> {
      // Check if it's a command (starts with "!")
      case string.starts_with(content, "!") {
        True -> {
          case parse_command(content) {
            Ok(#(name, args)) ->
              event_bus.dispatch(
                bus,
                plugin.Command(user:, name:, args:, role: permission.Viewer),
              )
            Error(_) -> Nil
          }
        }
        False ->
          event_bus.dispatch(
            bus,
            plugin.ChatMessage(
              user:,
              content:,
              channel:,
              channel_id: Some(sender_id),
            ),
          )
      }
    }
    Error(_) -> Nil
  }
}

fn dispatch_donation(data: String, bus: Subject(EventBusMessage)) -> Nil {
  let decoder = {
    use donation_type <- decode.field(
      "data",
      decode.field("donationType", decode.string, fn(t) { decode.success(t) }),
    )
    use donator_channel_id <- decode.field(
      "data",
      decode.field("donatorChannelId", decode.optional(decode.string), fn(id) {
        decode.success(id)
      }),
    )
    use donator_nickname <- decode.field(
      "data",
      decode.field("donatorNickname", decode.optional(decode.string), fn(n) {
        decode.success(n)
      }),
    )
    use pay_amount <- decode.field(
      "data",
      decode.field("payAmount", decode.string, fn(a) { decode.success(a) }),
    )
    use donation_text <- decode.field(
      "data",
      decode.field("donationText", decode.string, fn(t) { decode.success(t) }),
    )
    decode.success(#(
      donation_type,
      donator_channel_id,
      donator_nickname,
      pay_amount,
      donation_text,
    ))
  }

  case json.parse(data, decoder) {
    Ok(#(dtype, channel_id, nickname, amount, message)) -> {
      let user = case nickname {
        Some(n) -> n
        None -> "익명"
      }
      event_bus.dispatch(
        bus,
        plugin.Donation(
          user:,
          channel_id:,
          amount:,
          message:,
          donation_type: dtype,
        ),
      )
    }
    Error(_) -> Nil
  }
}

fn dispatch_subscription(data: String, bus: Subject(EventBusMessage)) -> Nil {
  let decoder = {
    use subscriber_channel_id <- decode.field(
      "data",
      decode.field("subscriberChannelId", decode.string, fn(id) {
        decode.success(id)
      }),
    )
    use subscriber_name <- decode.field(
      "data",
      decode.field("subscriberChannelName", decode.string, fn(n) {
        decode.success(n)
      }),
    )
    use month <- decode.field(
      "data",
      decode.field("month", decode.int, fn(m) { decode.success(m) }),
    )
    use tier <- decode.field(
      "data",
      decode.field("tierNo", decode.int, fn(t) { decode.success(t) }),
    )
    use message <- decode.field(
      "data",
      decode.field("subscriptionMessage", decode.string, fn(m) {
        decode.success(m)
      }),
    )
    decode.success(#(
      subscriber_name,
      subscriber_channel_id,
      month,
      tier,
      message,
    ))
  }

  case json.parse(data, decoder) {
    Ok(#(user, channel_id, month, tier, message)) ->
      event_bus.dispatch(
        bus,
        plugin.Subscription(user:, channel_id:, month:, tier:, message:),
      )
    Error(_) -> Nil
  }
}

fn parse_command(content: String) -> Result(#(String, List(String)), Nil) {
  let trimmed = string.drop_start(content, 1)
  case string.split(trimmed, " ") {
    [name, ..args] -> Ok(#(name, args))
    [] -> Error(Nil)
  }
}

pub fn connect(manager: Subject(WsMessage)) -> Nil {
  process.send(manager, Connect)
}

pub fn disconnect(manager: Subject(WsMessage)) -> Nil {
  process.send(manager, Disconnect)
}

pub fn get_connection_status(manager: Subject(WsMessage)) -> ConnectionStatus {
  process.call(manager, 5000, GetConnectionStatus)
}
