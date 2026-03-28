import gleam/string

pub type MessageSource {
  CiMe
  Mock
  Unknown
}

pub type Message {
  Message(
    user: String,
    content: String,
    source: MessageSource,
    timestamp: Int,
    channel: String,
  )
}

pub fn new(user: String, content: String) -> Message {
  Message(
    user: user,
    content: content,
    source: Unknown,
    timestamp: 0,
    channel: "default",
  )
}

pub fn is_command(message: Message) -> Bool {
  string.starts_with(message.content, "!")
}
