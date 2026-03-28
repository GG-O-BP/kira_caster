import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string

pub type VideoInfo {
  VideoInfo(video_id: String, title: String, duration_seconds: Int)
}

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

pub fn fetch_video_info(
  api_key: String,
  video_id: String,
) -> Result(VideoInfo, String) {
  case api_key {
    "" -> Ok(VideoInfo(video_id:, title: video_id, duration_seconds: 0))
    _ -> do_fetch_video_info(api_key, video_id)
  }
}

fn do_fetch_video_info(
  api_key: String,
  video_id: String,
) -> Result(VideoInfo, String) {
  let url =
    "https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id="
    <> video_id
    <> "&key="
    <> api_key
  use req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { "잘못된 URL입니다." }),
  )
  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_) { "YouTube API 요청에 실패했습니다." }),
  )
  parse_api_response(resp.body, video_id)
}

fn parse_api_response(
  body: String,
  video_id: String,
) -> Result(VideoInfo, String) {
  let items_decoder = {
    use title <- decode.field(
      "snippet",
      decode.field("title", decode.string, fn(t) { decode.success(t) }),
    )
    use duration <- decode.field(
      "contentDetails",
      decode.field("duration", decode.string, fn(d) { decode.success(d) }),
    )
    decode.success(#(title, duration))
  }
  let decoder =
    decode.field("items", decode.list(items_decoder), fn(items) {
      decode.success(items)
    })
  case json.parse(body, decoder) {
    Ok([#(title, duration_str), ..]) ->
      Ok(VideoInfo(
        video_id:,
        title:,
        duration_seconds: parse_iso8601_duration(duration_str),
      ))
    Ok([]) -> Error("영상을 찾을 수 없습니다.")
    Error(_) -> Error("YouTube API 응답 파싱에 실패했습니다.")
  }
}

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
