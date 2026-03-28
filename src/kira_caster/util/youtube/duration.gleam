import gleam/int
import gleetube/util as gleetube_util

pub fn parse_iso8601_duration(duration: String) -> Int {
  case gleetube_util.parse_duration(duration) {
    Ok(seconds) -> seconds
    Error(_) -> 0
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
