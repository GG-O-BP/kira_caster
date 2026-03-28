import gleam/option
import gleetube
import gleetube/api as gleetube_api
import gleetube/util as gleetube_util

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
  let client = gleetube.new(api_key)
  case gleetube_api.get_video_by_id(client, [video_id]) {
    Error(_) -> Error("YouTube API 요청에 실패했습니다.")
    Ok(response) ->
      case response.items {
        [video, ..] -> {
          let title = case video.snippet {
            option.Some(snippet) ->
              case snippet.title {
                option.Some(t) -> t
                option.None -> video_id
              }
            option.None -> video_id
          }
          let duration_seconds = case video.content_details {
            option.Some(details) ->
              case details.duration {
                option.Some(d) ->
                  case gleetube_util.parse_duration(d) {
                    Ok(secs) -> secs
                    Error(_) -> 0
                  }
                option.None -> 0
              }
            option.None -> 0
          }
          Ok(VideoInfo(video_id:, title:, duration_seconds:))
        }
        [] -> Error("영상을 찾을 수 없습니다.")
      }
  }
}
