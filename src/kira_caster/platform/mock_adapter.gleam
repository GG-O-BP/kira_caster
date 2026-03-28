import kira_caster/logger
import kira_caster/platform/adapter.{type Adapter, Adapter}

pub fn new() -> Adapter {
  Adapter(
    send_message: mock_send,
    connect: mock_connect,
    disconnect: mock_disconnect,
  )
}

fn mock_send(message: String) -> Result(Nil, adapter.AdapterError) {
  logger.info("[mock] Sending: " <> message)
  Ok(Nil)
}

fn mock_connect() -> Result(Nil, adapter.AdapterError) {
  logger.info("[mock] Connected")
  Ok(Nil)
}

fn mock_disconnect() -> Result(Nil, adapter.AdapterError) {
  logger.info("[mock] Disconnected")
  Ok(Nil)
}
