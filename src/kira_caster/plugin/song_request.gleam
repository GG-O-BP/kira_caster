import gleam/int
import gleam/list
import gleam/string
import kira_caster/core/permission
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository, type SongData}
import kira_caster/util/youtube

pub fn new(repo: Repository, youtube_api_key: String) -> Plugin {
  Plugin(name: "song_request", handle_event: fn(event) {
    handle(repo, youtube_api_key, event)
  })
}

fn handle(repo: Repository, api_key: String, event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "노래", args: ["목록", ..], role: _) ->
      handle_list(repo)
    plugin.Command(user: _, name: "노래", args: ["현재"], role: _) ->
      handle_current(repo)
    plugin.Command(user: _, name: "노래", args: ["스킵"], role:) ->
      handle_skip(repo, role)
    plugin.Command(user: _, name: "노래", args: ["삭제", num], role:) ->
      handle_remove(repo, role, num)
    plugin.Command(user: _, name: "노래", args: ["비우기"], role:) ->
      handle_clear(repo, role)
    plugin.Command(user:, name: "노래", args: [url], role: _) ->
      handle_request(repo, api_key, user, url)
    plugin.Command(user: _, name: "노래", args: _, role: _) -> [
      resp(
        "사용법: !노래 <YouTube URL> / !노래 목록 / !노래 현재 / !노래 스킵 / !노래 삭제 <번호> / !노래 비우기",
      ),
    ]
    _ -> []
  }
}

fn handle_request(
  repo: Repository,
  api_key: String,
  user: String,
  url: String,
) -> List(Event) {
  case youtube.parse_video_id(url) {
    Error(e) -> [resp(e)]
    Ok(video_id) -> {
      let prevent_dup = get_setting_bool(repo, "song_prevent_duplicate", False)
      case prevent_dup {
        True ->
          case repo.has_song_with_video_id(video_id) {
            Ok(True) -> [resp("이미 대기열에 있는 곡입니다.")]
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
  let max_per_user = get_setting_int(repo, "song_max_per_user", 1)
  case repo.get_songs_by_user(user) {
    Error(_) -> [resp("대기열 조회 중 오류가 발생했습니다.")]
    Ok(user_songs) -> {
      let count = list.length(user_songs)
      let count = case get_setting_bool(repo, "song_count_playing", False) {
        True -> count
        False -> {
          let current_id = get_setting_str(repo, "song_current_id", "")
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
          resp("신청 한도를 초과했습니다. (최대 " <> int.to_string(max_per_user) <> "곡)"),
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
  let cost = get_setting_int(repo, "song_cost_points", 0)
  case cost > 0 {
    True ->
      case repo.get_user(user) {
        Ok(u) ->
          case u.points >= cost {
            True -> fetch_and_add(repo, api_key, user, video_id, cost)
            False -> [
              resp(
                "포인트가 부족합니다. (필요: "
                <> int.to_string(cost)
                <> ", 보유: "
                <> int.to_string(u.points)
                <> ")",
              ),
            ]
          }
        Error(_) -> [
          resp("포인트가 부족합니다. (필요: " <> int.to_string(cost) <> ")"),
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
      let max_dur = get_setting_int(repo, "song_max_duration", 0)
      case max_dur > 0 && info.duration_seconds > max_dur {
        True -> [
          resp("영상이 너무 깁니다. (최대 " <> youtube.format_duration(max_dur) <> ")"),
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
                <> ") 이(가) 대기열에 추가되었습니다."
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
            Error(_) -> [resp("대기열 추가 중 오류가 발생했습니다.")]
          }
      }
    }
  }
}

fn handle_list(repo: Repository) -> List(Event) {
  case repo.get_song_queue() {
    Error(_) -> [resp("대기열 조회 중 오류가 발생했습니다.")]
    Ok([]) -> [resp("대기열이 비어 있습니다.")]
    Ok(songs) -> {
      let current_id = get_setting_str(repo, "song_current_id", "")
      let lines =
        songs
        |> list.take(5)
        |> list.index_map(fn(s, i) {
          let prefix = case int.to_string(s.id) == current_id {
            True -> "> "
            False -> "  "
          }
          prefix
          <> int.to_string(i + 1)
          <> ". "
          <> s.title
          <> " ("
          <> youtube.format_duration(s.duration_seconds)
          <> ") - "
          <> s.requested_by
        })
      let total = list.length(songs)
      let footer = case total > 5 {
        True -> "\n... 외 " <> int.to_string(total - 5) <> "곡"
        False -> ""
      }
      [resp("대기열:\n" <> string.join(lines, "\n") <> footer)]
    }
  }
}

fn handle_current(repo: Repository) -> List(Event) {
  let current_id = get_setting_str(repo, "song_current_id", "")
  case current_id {
    "" -> [resp("현재 재생 중인 곡이 없습니다.")]
    _ ->
      case repo.get_song_queue() {
        Ok(songs) ->
          case list.find(songs, fn(s) { int.to_string(s.id) == current_id }) {
            Ok(s) -> [
              resp(
                "현재 재생: "
                <> s.title
                <> " ("
                <> youtube.format_duration(s.duration_seconds)
                <> ") - "
                <> s.requested_by,
              ),
            ]
            Error(_) -> [resp("현재 재생 중인 곡이 없습니다.")]
          }
        Error(_) -> [resp("대기열 조회 중 오류가 발생했습니다.")]
      }
  }
}

fn handle_skip(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("권한이 없습니다. (관리자 전용)")]
    Ok(Nil) -> {
      case advance_song(repo, Forward) {
        Ok(next) -> [
          resp("다음 곡: " <> format_song(next)),
        ]
        Error("end") -> {
          let _ = repo.set_setting("song_current_id", "")
          [resp("대기열의 마지막 곡입니다.")]
        }
        Error(_) -> [resp("스킵 처리 중 오류가 발생했습니다.")]
      }
    }
  }
}

fn handle_remove(
  repo: Repository,
  role: permission.Role,
  num_str: String,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("권한이 없습니다. (관리자 전용)")]
    Ok(Nil) ->
      case int.parse(num_str) {
        Error(_) -> [resp("번호를 입력해주세요. (예: !노래 삭제 1)")]
        Ok(num) ->
          case repo.get_song_queue() {
            Ok(songs) ->
              case list_at(songs, num - 1) {
                Ok(song) ->
                  case repo.remove_song(song.id) {
                    Ok(Nil) -> [
                      resp(song.title <> " 이(가) 대기열에서 삭제되었습니다."),
                    ]
                    Error(_) -> [resp("삭제 중 오류가 발생했습니다.")]
                  }
                Error(_) -> [resp("해당 번호의 곡이 없습니다.")]
              }
            Error(_) -> [resp("대기열 조회 중 오류가 발생했습니다.")]
          }
      }
  }
}

fn handle_clear(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("권한이 없습니다. (관리자 전용)")]
    Ok(Nil) ->
      case repo.clear_song_queue() {
        Ok(Nil) -> {
          let _ = repo.set_setting("song_current_id", "")
          let _ = repo.set_setting("song_current_version", "0")
          [resp("대기열이 초기화되었습니다.")]
        }
        Error(_) -> [resp("초기화 중 오류가 발생했습니다.")]
      }
  }
}

// --- helpers ---

type Direction {
  Forward
  Backward
}

fn advance_song(repo: Repository, dir: Direction) -> Result(SongData, String) {
  case repo.get_song_queue() {
    Error(_) -> Error("queue_error")
    Ok([]) -> Error("end")
    Ok(songs) -> {
      let current_id = get_setting_str(repo, "song_current_id", "")
      let next = case current_id {
        "" ->
          case dir {
            Forward -> list.first(songs)
            Backward -> list.last(songs)
          }
        _ -> find_adjacent(songs, current_id, dir)
      }
      case next {
        Ok(s) -> {
          let _ = repo.set_setting("song_current_id", int.to_string(s.id))
          bump_version(repo)
          Ok(s)
        }
        Error(_) -> Error("end")
      }
    }
  }
}

fn find_adjacent(
  songs: List(SongData),
  current_id: String,
  dir: Direction,
) -> Result(SongData, Nil) {
  do_find_adjacent(songs, current_id, dir, None)
}

type MaybeItem(a) {
  None
  Found(a)
}

fn do_find_adjacent(
  songs: List(SongData),
  current_id: String,
  dir: Direction,
  prev: MaybeItem(SongData),
) -> Result(SongData, Nil) {
  case songs {
    [] -> Error(Nil)
    [s, ..rest] ->
      case int.to_string(s.id) == current_id {
        True ->
          case dir {
            Forward ->
              case rest {
                [next, ..] -> Ok(next)
                [] -> Error(Nil)
              }
            Backward ->
              case prev {
                Found(p) -> Ok(p)
                None -> Error(Nil)
              }
          }
        False -> do_find_adjacent(rest, current_id, dir, Found(s))
      }
  }
}

fn bump_version(repo: Repository) -> Nil {
  let v = get_setting_int(repo, "song_current_version", 0)
  let _ = repo.set_setting("song_current_version", int.to_string(v + 1))
  Nil
}

fn format_song(s: SongData) -> String {
  s.title
  <> " ("
  <> youtube.format_duration(s.duration_seconds)
  <> ") - "
  <> s.requested_by
}

fn resp(msg: String) -> Event {
  plugin.PluginResponse(plugin: "song_request", message: msg)
}

fn get_setting_int(repo: Repository, key: String, default: Int) -> Int {
  case repo.get_setting(key) {
    Ok(val) ->
      case int.parse(val) {
        Ok(n) -> n
        Error(_) -> default
      }
    Error(_) -> default
  }
}

fn get_setting_bool(repo: Repository, key: String, default: Bool) -> Bool {
  case repo.get_setting(key) {
    Ok("true") -> True
    Ok("false") -> False
    _ -> default
  }
}

fn get_setting_str(repo: Repository, key: String, default: String) -> String {
  case repo.get_setting(key) {
    Ok(val) -> val
    Error(_) -> default
  }
}

fn list_at(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [], _ -> Error(Nil)
    [first, ..], 0 -> Ok(first)
    [_, ..rest], n -> list_at(rest, n - 1)
  }
}
