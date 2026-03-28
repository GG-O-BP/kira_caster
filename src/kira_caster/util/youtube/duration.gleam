import gleam/int
import gleam/string

pub fn parse_iso8601_duration(duration: String) -> Int {
  let s = case string.starts_with(duration, "PT") {
    True -> string.drop_start(duration, 2)
    False -> duration
  }
  let #(hours, rest) = extract_component(s, "H")
  let #(minutes, rest2) = extract_component(rest, "M")
  let #(seconds, _) = extract_component(rest2, "S")
  hours * 3600 + minutes * 60 + seconds
}

fn extract_component(s: String, marker: String) -> #(Int, String) {
  case string.split(s, marker) {
    [num_str, rest] ->
      case int.parse(num_str) {
        Ok(n) -> #(n, rest)
        Error(_) -> #(0, s)
      }
    _ -> #(0, s)
  }
}

pub fn format_duration(seconds: Int) -> String {
  let h = seconds / 3600
  let m = { seconds % 3600 } / 60
  let s = seconds % 60
  case h > 0 {
    True -> int.to_string(h) <> ":" <> pad_zero(m) <> ":" <> pad_zero(s)
    False -> int.to_string(m) <> ":" <> pad_zero(s)
  }
}

fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}
