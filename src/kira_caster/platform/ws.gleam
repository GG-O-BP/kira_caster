pub type WsState {
  Disconnected
  Connected
  Reconnecting(attempts: Int)
}

pub type WsError {
  ConnectionFailed(reason: String)
  MessageSendFailed(reason: String)
}

pub type WsEvent {
  ConnectSuccess
  ConnectFailure(reason: String)
  Disconnect
  ReconnectAttempt
}

pub fn initial_state() -> WsState {
  Disconnected
}

pub fn max_reconnect_attempts() -> Int {
  5
}

pub fn transition(state: WsState, event: WsEvent) -> Result(WsState, WsError) {
  case state, event {
    Disconnected, ConnectSuccess -> Ok(Connected)
    Disconnected, ConnectFailure(reason) -> Error(ConnectionFailed(reason))
    Connected, Disconnect -> Ok(Disconnected)
    Connected, ConnectFailure(_) -> Ok(Reconnecting(attempts: 1))
    Reconnecting(_), ConnectSuccess -> Ok(Connected)
    Reconnecting(n), ReconnectAttempt ->
      case n >= max_reconnect_attempts() {
        True ->
          Error(ConnectionFailed(
            "max reconnect attempts (" <> "5" <> ") exceeded",
          ))
        False -> Ok(Reconnecting(attempts: n + 1))
      }
    _, _ -> Error(ConnectionFailed("invalid state transition"))
  }
}
