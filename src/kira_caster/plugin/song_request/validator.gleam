import gleam/int
import gleam/list
import kira_caster/plugin/plugin.{type Event}
import kira_caster/plugin/song_request/formatter.{resp}
import kira_caster/plugin/song_request/settings
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/youtube

pub fn validate_and_add(
  repo: Repository,
  api_key: String,
  user: String,
  url: String,
) -> List(Event) {
  case youtube.parse_video_id(url) {
    Error(e) -> [resp(e)]
    Ok(video_id) -> {
      let prevent_dup =
        settings.get_setting_bool(repo, "song_prevent_duplicate", False)
      case prevent_dup {
        True ->
          case repo.has_song_with_video_id(video_id) {
            Ok(True) -> [resp("이 곡 이미 대기열에 있당 ㅋㅋ")]
            _ -> check_user_limit(repo, api_key, user, video_id)
          }
        False -> check_user_limit(repo, api_key, user, video_id)
      }
    }
  }
}

fn check_user_limit(
  repo: Repository,
  api_key: String,
  user: String,
  video_id: String,
) -> List(Event) {
  let max_per_user = settings.get_setting_int(repo, "song_max_per_user", 1)
  case repo.get_songs_by_user(user) {
    Error(_) -> [resp("앗 대기열 불러오다 에러났어 ㅠㅠ")]
    Ok(user_songs) -> {
      let count = list.length(user_songs)
      let count = case
        settings.get_setting_bool(repo, "song_count_playing", False)
      {
        True -> count
        False -> {
          let current_id = settings.get_setting_str(repo, "song_current_id", "")
          case current_id {
            "" -> count
            _ ->
              case
                list.any(user_songs, fn(s) { int.to_string(s.id) == current_id })
              {
                True -> count - 1
                False -> count
              }
          }
        }
      }
      case count >= max_per_user {
        True -> [
          resp("신청 한도 넘었어용 ㅠㅠ (최대 " <> int.to_string(max_per_user) <> "곡)"),
        ]
        False -> check_points_and_fetch(repo, api_key, user, video_id)
      }
    }
  }
}

fn check_points_and_fetch(
  repo: Repository,
  api_key: String,
  user: String,
  video_id: String,
) -> List(Event) {
  let cost = settings.get_setting_int(repo, "song_cost_points", 0)
  case cost > 0 {
    True ->
      case repo.get_user(user) {
        Ok(u) ->
          case u.points >= cost {
            True -> fetch_and_add(repo, api_key, user, video_id, cost)
            False -> [
              resp(
                "포인트가 모자라용 ㅠㅠ (필요: "
                <> int.to_string(cost)
                <> ", 보유: "
                <> int.to_string(u.points)
                <> ")",
              ),
            ]
          }
        Error(_) -> [
          resp("포인트가 모자라용 ㅠㅠ (필요: " <> int.to_string(cost) <> ")"),
        ]
      }
    False -> fetch_and_add(repo, api_key, user, video_id, 0)
  }
}

fn fetch_and_add(
  repo: Repository,
  api_key: String,
  user: String,
  video_id: String,
  cost: Int,
) -> List(Event) {
  case youtube.fetch_video_info(api_key, video_id) {
    Error(e) -> [resp(e)]
    Ok(info) -> {
      let max_dur = settings.get_setting_int(repo, "song_max_duration", 0)
      case max_dur > 0 && info.duration_seconds > max_dur {
        True -> [
          resp("영상이 너무 길당 ㅠㅠ (최대 " <> youtube.format_duration(max_dur) <> ")"),
        ]
        False ->
          case
            repo.add_song(
              info.video_id,
              info.title,
              info.duration_seconds,
              user,
            )
          {
            Ok(_song) -> {
              let msg =
                info.title
                <> " ("
                <> youtube.format_duration(info.duration_seconds)
                <> ") 대기열에 넣었당!"
              case cost > 0 {
                True -> [
                  resp(msg),
                  plugin.PointsChange(
                    user:,
                    amount: -cost,
                    reason: "song_request",
                  ),
                ]
                False -> [resp(msg)]
              }
            }
            Error(_) -> [resp("앗 대기열에 넣다가 에러났어 ㅠㅠ")]
          }
      }
    }
  }
}
