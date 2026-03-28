import gleam/string
import kira_caster/core/message.{type Message}

pub type Command {
  Command(name: String, args: List(String), raw_message: Message)
}

pub type ParseError {
  NotACommand
  EmptyCommand
}

pub fn parse(msg: Message) -> Result(Command, ParseError) {
  let content = msg.content
  case string.starts_with(content, "!") {
    False -> Error(NotACommand)
    True -> {
      let trimmed = string.drop_start(content, 1)
      case string.split(trimmed, " ") {
        [] -> Error(EmptyCommand)
        [""] -> Error(EmptyCommand)
        [name, ..args] ->
          Ok(Command(name: string.lowercase(name), args: args, raw_message: msg))
      }
    }
  }
}
