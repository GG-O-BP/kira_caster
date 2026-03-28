import kira_caster/platform/adapter.{Adapter}

pub fn send_delegates_to_function_field_test() {
  let test_adapter =
    Adapter(
      send_message: fn(_msg) { Ok(Nil) },
      connect: fn() { Ok(Nil) },
      disconnect: fn() { Ok(Nil) },
    )
  let assert Ok(Nil) = adapter.send(test_adapter, "test message")
}

pub fn send_propagates_error_test() {
  let test_adapter =
    Adapter(
      send_message: fn(_msg) { Error(adapter.SendFailed(reason: "test error")) },
      connect: fn() { Ok(Nil) },
      disconnect: fn() { Ok(Nil) },
    )
  let assert Error(adapter.SendFailed(reason: "test error")) =
    adapter.send(test_adapter, "test")
}

pub fn connect_delegates_test() {
  let test_adapter =
    Adapter(
      send_message: fn(_msg) { Ok(Nil) },
      connect: fn() { Ok(Nil) },
      disconnect: fn() { Ok(Nil) },
    )
  let assert Ok(Nil) = test_adapter.connect()
}
