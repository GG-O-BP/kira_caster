import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import kira_caster/logger
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime/types.{type TokenStatus, TokenStatus}
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time

pub type TokenMessage {
  GetAccessToken(reply: Subject(Result(String, String)))
  SetAuthCode(code: String, reply: Subject(Result(Nil, String)))
  RefreshNow(reply: Subject(Result(Nil, String)))
  GetStatus(reply: Subject(TokenStatus))
  RevokeAndClear(reply: Subject(Result(Nil, String)))
  ScheduledRefresh
}

pub type TokenState {
  TokenState(
    access_token: Option(String),
    refresh_token: Option(String),
    expires_at: Int,
    api: CimeApi,
    repo: Repository,
    subject: Subject(TokenMessage),
  )
}

pub fn start(
  api: CimeApi,
  repo: Repository,
) -> Result(actor.Started(Subject(TokenMessage)), actor.StartError) {
  actor.new_with_initialiser(5000, fn(subject) {
    let state =
      TokenState(
        access_token: None,
        refresh_token: None,
        expires_at: 0,
        api:,
        repo:,
        subject:,
      )
    let state = try_restore_token(state)
    actor.initialised(state)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
}

fn handle_message(
  state: TokenState,
  message: TokenMessage,
) -> actor.Next(TokenState, TokenMessage) {
  case message {
    GetAccessToken(reply) -> {
      let now = time.now_ms()
      case state.access_token {
        Some(token) if state.expires_at > now -> {
          process.send(reply, Ok(token))
          actor.continue(state)
        }
        _ -> {
          // Try refresh
          case state.refresh_token {
            Some(refresh) -> {
              case state.api.refresh_token(refresh) {
                Ok(token_resp) -> {
                  let new_state = apply_token_response(state, token_resp)
                  process.send(reply, Ok(token_resp.access_token))
                  actor.continue(new_state)
                }
                Error(e) -> {
                  process.send(
                    reply,
                    Error("Token refresh failed: " <> inspect_error(e)),
                  )
                  actor.continue(state)
                }
              }
            }
            None -> {
              process.send(reply, Error("Not authenticated"))
              actor.continue(state)
            }
          }
        }
      }
    }

    SetAuthCode(code:, reply:) -> {
      case state.api.exchange_code(code) {
        Ok(token_resp) -> {
          let new_state = apply_token_response(state, token_resp)
          logger.info("OAuth token acquired successfully")
          process.send(reply, Ok(Nil))
          actor.continue(new_state)
        }
        Error(e) -> {
          process.send(
            reply,
            Error("Token exchange failed: " <> inspect_error(e)),
          )
          actor.continue(state)
        }
      }
    }

    RefreshNow(reply) -> {
      case state.refresh_token {
        Some(refresh) -> {
          case state.api.refresh_token(refresh) {
            Ok(token_resp) -> {
              let new_state = apply_token_response(state, token_resp)
              process.send(reply, Ok(Nil))
              actor.continue(new_state)
            }
            Error(e) -> {
              process.send(reply, Error("Refresh failed: " <> inspect_error(e)))
              actor.continue(state)
            }
          }
        }
        None -> {
          process.send(reply, Error("No refresh token"))
          actor.continue(state)
        }
      }
    }

    GetStatus(reply) -> {
      let authenticated = option.is_some(state.access_token)
      process.send(
        reply,
        TokenStatus(authenticated:, expires_at: state.expires_at, scopes: ""),
      )
      actor.continue(state)
    }

    RevokeAndClear(reply) -> {
      case state.access_token {
        Some(token) -> {
          let _ = state.api.revoke_token(token, "access_token")
          Nil
        }
        None -> Nil
      }
      let _ = state.repo.set_setting("cime_refresh_token", "")
      process.send(reply, Ok(Nil))
      logger.info("OAuth tokens revoked")
      actor.continue(
        TokenState(
          ..state,
          access_token: None,
          refresh_token: None,
          expires_at: 0,
        ),
      )
    }

    ScheduledRefresh -> {
      case state.refresh_token {
        Some(refresh) -> {
          case state.api.refresh_token(refresh) {
            Ok(token_resp) -> {
              logger.info("Token auto-refreshed")
              let new_state = apply_token_response(state, token_resp)
              actor.continue(new_state)
            }
            Error(e) -> {
              logger.warn("Token auto-refresh failed: " <> inspect_error(e))
              actor.continue(state)
            }
          }
        }
        None -> actor.continue(state)
      }
    }
  }
}

fn apply_token_response(
  state: TokenState,
  resp: types.TokenResponse,
) -> TokenState {
  let now = time.now_ms()
  let expires_in_ms = case int.parse(resp.expires_in) {
    Ok(secs) -> secs * 1000
    Error(_) -> 3_600_000
  }
  let expires_at = now + expires_in_ms

  // Persist refresh token
  let _ = state.repo.set_setting("cime_refresh_token", resp.refresh_token)

  // Schedule auto-refresh 5 minutes before expiry
  let refresh_delay = expires_in_ms - 300_000
  let refresh_delay = case refresh_delay > 0 {
    True -> refresh_delay
    False -> 60_000
  }
  process.send_after(state.subject, refresh_delay, ScheduledRefresh)

  TokenState(
    ..state,
    access_token: Some(resp.access_token),
    refresh_token: Some(resp.refresh_token),
    expires_at:,
  )
}

fn try_restore_token(state: TokenState) -> TokenState {
  case state.repo.get_setting("cime_refresh_token") {
    Ok(refresh) if refresh != "" -> {
      logger.info("Restoring OAuth session from saved refresh token...")
      case state.api.refresh_token(refresh) {
        Ok(token_resp) -> {
          logger.info("OAuth session restored")
          apply_token_response(state, token_resp)
        }
        Error(e) -> {
          logger.warn("Failed to restore OAuth session: " <> inspect_error(e))
          state
        }
      }
    }
    _ -> state
  }
}

fn inspect_error(e: types.CimeError) -> String {
  case e {
    types.HttpError(reason:) -> "HTTP error: " <> reason
    types.ApiError(status:, message:) ->
      "API error " <> int.to_string(status) <> ": " <> message
    types.JsonDecodeError(reason:) -> "JSON decode error: " <> reason
  }
}

// Public helpers for synchronous calls

pub fn get_access_token(
  manager: Subject(TokenMessage),
) -> Result(String, String) {
  process.call(manager, 10_000, GetAccessToken)
}

pub fn set_auth_code(
  manager: Subject(TokenMessage),
  code: String,
) -> Result(Nil, String) {
  process.call(manager, 30_000, SetAuthCode(code:, reply: _))
}

pub fn get_status(manager: Subject(TokenMessage)) -> TokenStatus {
  process.call(manager, 5000, GetStatus)
}

pub fn revoke_and_clear(manager: Subject(TokenMessage)) -> Result(Nil, String) {
  process.call(manager, 10_000, RevokeAndClear)
}
