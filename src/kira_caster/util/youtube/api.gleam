import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import kira_caster/util/youtube/duration

pub type VideoInfo {
  VideoInfo(video_id: String, title: String, duration_seconds: Int)
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
        duration_seconds: duration.parse_iso8601_duration(duration_str),
      ))
    Ok([]) -> Error("영상을 찾을 수 없습니다.")
    Error(_) -> Error("YouTube API 응답 파싱에 실패했습니다.")
  }
}
