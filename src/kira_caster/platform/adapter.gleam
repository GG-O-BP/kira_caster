pub type AdapterError {
  ConnectionFailed(reason: String)
  SendFailed(reason: String)
  NotConnected
}

pub type Adapter {
  Adapter(
    send_message: fn(String) -> Result(Nil, AdapterError),
    connect: fn() -> Result(Nil, AdapterError),
    disconnect: fn() -> Result(Nil, AdapterError),
  )
}

pub fn send(adapter: Adapter, message: String) -> Result(Nil, AdapterError) {
  adapter.send_message(message)
}
