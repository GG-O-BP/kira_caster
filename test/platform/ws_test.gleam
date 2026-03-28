import kira_caster/platform/ws

pub fn initial_state_test() {
  assert ws.initial_state() == ws.Disconnected
}

pub fn connect_success_test() {
  let assert Ok(ws.Connected) =
    ws.transition(ws.Disconnected, ws.ConnectSuccess)
}

pub fn connect_failure_test() {
  let assert Error(ws.ConnectionFailed(_)) =
    ws.transition(ws.Disconnected, ws.ConnectFailure("timeout"))
}

pub fn disconnect_test() {
  let assert Ok(ws.Disconnected) = ws.transition(ws.Connected, ws.Disconnect)
}

pub fn connected_failure_triggers_reconnect_test() {
  let assert Ok(ws.Reconnecting(attempts: 1)) =
    ws.transition(ws.Connected, ws.ConnectFailure("dropped"))
}

pub fn reconnect_success_test() {
  let assert Ok(ws.Connected) =
    ws.transition(ws.Reconnecting(attempts: 3), ws.ConnectSuccess)
}

pub fn reconnect_increments_attempts_test() {
  let assert Ok(ws.Reconnecting(attempts: 3)) =
    ws.transition(ws.Reconnecting(attempts: 2), ws.ReconnectAttempt)
}

pub fn reconnect_max_attempts_exceeded_test() {
  let assert Error(ws.ConnectionFailed(_)) =
    ws.transition(ws.Reconnecting(attempts: 5), ws.ReconnectAttempt)
}

pub fn invalid_transition_test() {
  let assert Error(ws.ConnectionFailed(_)) =
    ws.transition(ws.Disconnected, ws.Disconnect)
}
