import gleam/string

pub fn parse_video_id(url: String) -> Result(String, String) {
  let url = string.trim(url)
  case url {
    "https://youtu.be/" <> rest | "http://youtu.be/" <> rest ->
      rest |> strip_query_and_fragment |> validate_video_id
    _ ->
      case
        string.contains(url, "youtube.com/watch")
        || string.contains(url, "youtube.com/embed")
      {
        True -> extract_from_youtube_url(url)
        False ->
          case string.length(url) == 11 && is_video_id_chars(url) {
            True -> Ok(url)
            False -> Error("유효하지 않은 YouTube URL입니다.")
          }
      }
  }
}

fn extract_from_youtube_url(url: String) -> Result(String, String) {
  case string.contains(url, "/embed/") {
    True -> {
      case string.split(url, "/embed/") {
        [_, rest, ..] -> rest |> strip_query_and_fragment |> validate_video_id
        _ -> Error("유효하지 않은 YouTube URL입니다.")
      }
    }
    False -> {
      case string.split(url, "v=") {
        [_, rest, ..] -> rest |> strip_ampersand |> validate_video_id
        _ -> Error("유효하지 않은 YouTube URL입니다.")
      }
    }
  }
}

fn strip_query_and_fragment(s: String) -> String {
  s |> split_first("?") |> split_first("#") |> split_first("/")
}

fn strip_ampersand(s: String) -> String {
  s |> split_first("&") |> split_first("#")
}

fn split_first(s: String, sep: String) -> String {
  case string.split(s, sep) {
    [first, ..] -> first
    [] -> s
  }
}

fn validate_video_id(id: String) -> Result(String, String) {
  case string.length(id) == 11 && is_video_id_chars(id) {
    True -> Ok(id)
    False -> Error("유효하지 않은 YouTube 영상 ID입니다.")
  }
}

fn is_video_id_chars(s: String) -> Bool {
  s
  |> string.to_graphemes
  |> do_check_chars
}

fn do_check_chars(chars: List(String)) -> Bool {
  case chars {
    [] -> True
    [c, ..rest] ->
      case is_alnum_or_special(c) {
        True -> do_check_chars(rest)
        False -> False
      }
  }
}

fn is_alnum_or_special(c: String) -> Bool {
  case c {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "0"
    | "1"
    | "2"
    | "3"
    | "4"
    | "5"
    | "6"
    | "7"
    | "8"
    | "9"
    | "-"
    | "_" -> True
    _ -> False
  }
}
