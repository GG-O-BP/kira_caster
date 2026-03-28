import kira_caster/util/youtube

// --- parse_video_id ---

pub fn parse_watch_url_test() {
  assert youtube.parse_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    == Ok("dQw4w9WgXcQ")
}

pub fn parse_watch_url_with_params_test() {
  assert youtube.parse_video_id(
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLx",
    )
    == Ok("dQw4w9WgXcQ")
}

pub fn parse_short_url_test() {
  assert youtube.parse_video_id("https://youtu.be/dQw4w9WgXcQ")
    == Ok("dQw4w9WgXcQ")
}

pub fn parse_short_url_with_params_test() {
  assert youtube.parse_video_id("https://youtu.be/dQw4w9WgXcQ?t=42")
    == Ok("dQw4w9WgXcQ")
}

pub fn parse_embed_url_test() {
  assert youtube.parse_video_id("https://www.youtube.com/embed/dQw4w9WgXcQ")
    == Ok("dQw4w9WgXcQ")
}

pub fn parse_music_url_test() {
  assert youtube.parse_video_id("https://music.youtube.com/watch?v=dQw4w9WgXcQ")
    == Ok("dQw4w9WgXcQ")
}

pub fn parse_bare_id_test() {
  assert youtube.parse_video_id("dQw4w9WgXcQ") == Ok("dQw4w9WgXcQ")
}

pub fn parse_invalid_url_test() {
  assert youtube.parse_video_id("not-a-url") == Error("유효하지 않은 YouTube URL입니다.")
}

pub fn parse_empty_test() {
  assert youtube.parse_video_id("") == Error("유효하지 않은 YouTube URL입니다.")
}

pub fn parse_http_short_url_test() {
  assert youtube.parse_video_id("http://youtu.be/dQw4w9WgXcQ")
    == Ok("dQw4w9WgXcQ")
}

// --- parse_iso8601_duration ---

pub fn duration_minutes_seconds_test() {
  assert youtube.parse_iso8601_duration("PT4M33S") == 273
}

pub fn duration_hours_minutes_seconds_test() {
  assert youtube.parse_iso8601_duration("PT1H2M3S") == 3723
}

pub fn duration_seconds_only_test() {
  assert youtube.parse_iso8601_duration("PT45S") == 45
}

pub fn duration_hours_only_test() {
  assert youtube.parse_iso8601_duration("PT1H") == 3600
}

pub fn duration_minutes_only_test() {
  assert youtube.parse_iso8601_duration("PT10M") == 600
}

// --- format_duration ---

pub fn format_short_test() {
  assert youtube.format_duration(65) == "1:05"
}

pub fn format_long_test() {
  assert youtube.format_duration(3723) == "1:02:03"
}

pub fn format_zero_test() {
  assert youtube.format_duration(0) == "0:00"
}
