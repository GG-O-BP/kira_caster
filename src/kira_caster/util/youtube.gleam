import kira_caster/util/youtube/api
import kira_caster/util/youtube/duration
import kira_caster/util/youtube/url_parser

pub type VideoInfo =
  api.VideoInfo

pub fn parse_video_id(url: String) -> Result(String, String) {
  url_parser.parse_video_id(url)
}

pub fn fetch_video_info(
  api_key: String,
  video_id: String,
) -> Result(api.VideoInfo, String) {
  api.fetch_video_info(api_key, video_id)
}

pub fn parse_iso8601_duration(duration_str: String) -> Int {
  duration.parse_iso8601_duration(duration_str)
}

pub fn format_duration(seconds: Int) -> String {
  duration.format_duration(seconds)
}
