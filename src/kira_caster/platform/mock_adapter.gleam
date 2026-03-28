import gleam/io
import kira_caster/platform/adapter.{type Adapter, Adapter}

pub fn new() -> Adapter {
  Adapter(
    send_message: mock_send,
    connect: mock_connect,
    disconnect: mock_disconnect,
  )
}

fn mock_send(message: String) -> Result(Nil, adapter.AdapterError) {
  io.println("[mock] Sending: " <> message)
  Ok(Nil)
}

fn mock_connect() -> Result(Nil, adapter.AdapterError) {
  io.println("[mock] Connected")
  Ok(Nil)
}

fn mock_disconnect() -> Result(Nil, adapter.AdapterError) {
  io.println("[mock] Disconnected")
  Ok(Nil)
}
