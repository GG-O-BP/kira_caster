import gleam/int
import gleam/list
import gleam/string
import kira_caster/core/permission
import kira_caster/plugin/plugin.{type Event}
import kira_caster/plugin/song_request/formatter.{format_song, resp}
import kira_caster/plugin/song_request/settings
import kira_caster/storage/repository.{type Repository, type SongData}
import kira_caster/util/youtube

pub fn handle_list(repo: Repository) -> List(Event) {
  case repo.get_song_queue() {
    Error(_) -> [resp("앗 대기열 불러오다 에러났어 ㅠㅠ")]
    Ok([]) -> [resp("대기열이 비어있당 곡을 넣어줘용!")]
    Ok(songs) -> {
      let current_id = settings.get_setting_str(repo, "song_current_id", "")
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
      [resp("대기열이에용!\n" <> string.join(lines, "\n") <> footer)]
    }
  }
}

pub fn handle_current(repo: Repository) -> List(Event) {
  let current_id = settings.get_setting_str(repo, "song_current_id", "")
  case current_id {
    "" -> [resp("지금 재생 중인 곡이 없당..")]
    _ ->
      case repo.get_song_queue() {
        Ok(songs) ->
          case list.find(songs, fn(s) { int.to_string(s.id) == current_id }) {
            Ok(s) -> [
              resp(
                "지금 듣고 있는 거 "
                <> s.title
                <> " ("
                <> youtube.format_duration(s.duration_seconds)
                <> ") - "
                <> s.requested_by,
              ),
            ]
            Error(_) -> [resp("지금 재생 중인 곡이 없당..")]
          }
        Error(_) -> [resp("앗 대기열 불러오다 에러났어 ㅠㅠ")]
      }
  }
}

pub fn handle_skip(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("헐 이건 관리자만 할 수 있어용 ㅠ")]
    Ok(Nil) -> {
      case advance_song(repo, Forward) {
        Ok(next) -> [
          resp("다음 곡이에용 " <> format_song(next)),
        ]
        Error("end") -> {
          let _ = repo.set_setting("song_current_id", "")
          [resp("이게 마지막 곡이에용!")]
        }
        Error(_) -> [resp("앗 스킵하다 에러났어 ㅠㅠ")]
      }
    }
  }
}

pub fn handle_remove(
  repo: Repository,
  role: permission.Role,
  num_str: String,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("헐 이건 관리자만 할 수 있어용 ㅠ")]
    Ok(Nil) ->
      case int.parse(num_str) {
        Error(_) -> [resp("번호를 넣어줘용 (예: !노래 삭제 1)")]
        Ok(num) ->
          case repo.get_song_queue() {
            Ok(songs) ->
              case settings.list_at(songs, num - 1) {
                Ok(song) ->
                  case repo.remove_song(song.id) {
                    Ok(Nil) -> [
                      resp(song.title <> " 대기열에서 삭제했당!"),
                    ]
                    Error(_) -> [resp("앗 삭제하다 에러났어 ㅠㅠ")]
                  }
                Error(_) -> [resp("그 번호에 곡이 없당..")]
              }
            Error(_) -> [resp("앗 대기열 불러오다 에러났어 ㅠㅠ")]
          }
      }
  }
}

pub fn handle_clear(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("헐 이건 관리자만 할 수 있어용 ㅠ")]
    Ok(Nil) ->
      case repo.clear_song_queue() {
        Ok(Nil) -> {
          let _ = repo.set_setting("song_current_id", "")
          let _ = repo.set_setting("song_current_version", "0")
          [resp("대기열 싹 비웠당!")]
        }
        Error(_) -> [resp("앗 초기화하다 에러났어 ㅠㅠ")]
      }
  }
}

pub fn handle_current_info(repo: Repository) -> Result(String, Nil) {
  let current_id = settings.get_setting_str(repo, "song_current_id", "")
  case current_id {
    "" -> Error(Nil)
    _ ->
      case repo.get_song_queue() {
        Ok(songs) ->
          case list.find(songs, fn(s) { int.to_string(s.id) == current_id }) {
            Ok(s) -> Ok(s.title)
            Error(_) -> Error(Nil)
          }
        Error(_) -> Error(Nil)
      }
  }
}

// --- navigation helpers ---

type Direction {
  Forward
  Backward
}

fn advance_song(repo: Repository, dir: Direction) -> Result(SongData, String) {
  case repo.get_song_queue() {
    Error(_) -> Error("queue_error")
    Ok([]) -> Error("end")
    Ok(songs) -> {
      let current_id = settings.get_setting_str(repo, "song_current_id", "")
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

type MaybeItem(a) {
  None
  Found(a)
}

fn find_adjacent(
  songs: List(SongData),
  current_id: String,
  dir: Direction,
) -> Result(SongData, Nil) {
  do_find_adjacent(songs, current_id, dir, None)
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
  let v = settings.get_setting_int(repo, "song_current_version", 0)
  let _ = repo.set_setting("song_current_version", int.to_string(v + 1))
  Nil
}
