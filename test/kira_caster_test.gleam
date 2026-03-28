import gleeunit
import kira_caster/core/message
import kira_caster/platform/mock_adapter

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn mock_adapter_connects_test() {
  let adapter = mock_adapter.new()
  let assert Ok(Nil) = adapter.connect()
}

pub fn mock_adapter_sends_test() {
  let adapter = mock_adapter.new()
  let assert Ok(Nil) = adapter.send_message("hello")
}

pub fn message_creation_test() {
  let msg = message.new("test_user", "!hello")
  assert message.is_command(msg) == True
}
