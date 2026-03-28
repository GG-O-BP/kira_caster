/// WebSocket connection management.
/// Will use stratus package when platform integration begins.
pub type WsState {
  Disconnected
  Connected
  Reconnecting(attempts: Int)
}

pub type WsError {
  ConnectionFailed(reason: String)
  MessageSendFailed(reason: String)
}

pub fn initial_state() -> WsState {
  Disconnected
}
