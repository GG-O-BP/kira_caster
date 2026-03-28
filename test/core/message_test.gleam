import kira_caster/core/message

pub fn new_message_test() {
  let msg = message.new("alice", "hello world")
  assert msg.user == "alice"
  assert msg.content == "hello world"
  assert msg.source == message.Unknown
  assert msg.channel == "default"
}

pub fn is_command_true_test() {
  let msg = message.new("alice", "!ping")
  assert message.is_command(msg) == True
}

pub fn is_command_false_test() {
  let msg = message.new("alice", "hello")
  assert message.is_command(msg) == False
}

pub fn is_command_empty_test() {
  let msg = message.new("alice", "")
  assert message.is_command(msg) == False
}
