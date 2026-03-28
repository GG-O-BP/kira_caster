import gleam/io
import kira_caster/platform/mock_adapter

pub fn main() -> Nil {
  let adapter = mock_adapter.new()
  case adapter.connect() {
    Ok(Nil) -> {
      io.println("kira_caster started with mock adapter")
      case adapter.send_message("Bot is online!") {
        Ok(Nil) -> Nil
        Error(_) -> io.println("Failed to send startup message")
      }
    }
    Error(_) -> io.println("Failed to connect")
  }
}
