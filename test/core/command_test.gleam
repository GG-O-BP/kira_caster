import kira_caster/core/command
import kira_caster/core/message

pub fn parse_valid_command_test() {
  let msg = message.new("alice", "!ping")
  let assert Ok(cmd) = command.parse(msg)
  assert cmd.name == "ping"
  assert cmd.args == []
}

pub fn parse_command_with_args_test() {
  let msg = message.new("alice", "!points add 10")
  let assert Ok(cmd) = command.parse(msg)
  assert cmd.name == "points"
  assert cmd.args == ["add", "10"]
}

pub fn parse_command_lowercase_test() {
  let msg = message.new("alice", "!PING")
  let assert Ok(cmd) = command.parse(msg)
  assert cmd.name == "ping"
}

pub fn parse_not_a_command_test() {
  let msg = message.new("alice", "hello world")
  let assert Error(command.NotACommand) = command.parse(msg)
}

pub fn parse_empty_command_test() {
  let msg = message.new("alice", "!")
  let assert Error(command.EmptyCommand) = command.parse(msg)
}
