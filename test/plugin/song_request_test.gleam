import gleam/list
import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/song_request
import kira_caster/storage/repository.{Repository, SongData}

fn song_repo() -> repository.Repository {
  let base = repository.mock_repo([])
  Repository(
    ..base,
    get_song_queue: fn() {
      Ok([
        SongData(
          id: 1,
          video_id: "abc12345678",
          title: "Test Song",
          duration_seconds: 200,
          requested_by: "alice",
          position: 0,
          created_at: 0,
        ),
      ])
    },
    get_setting: fn(key) {
      case key {
        "song_current_id" -> Ok("1")
        "song_current_version" -> Ok("0")
        _ -> Error(repository.NotFound)
      }
    },
  )
}

fn empty_song_repo() -> repository.Repository {
  repository.mock_repo([])
}

pub fn request_song_success_test() {
  let repo = empty_song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["https://youtu.be/dQw4w9WgXcQ"],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "song_request", message: msg)] -> {
      assert {
        case msg {
          "dQw4w9WgXcQ" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn request_song_invalid_url_test() {
  let repo = empty_song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["invalid"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "유효하지 않은 YouTube URL입니다.",
      ),
    ]
}

pub fn request_song_duplicate_prevented_test() {
  let base = empty_song_repo()
  let repo =
    Repository(
      ..base,
      has_song_with_video_id: fn(_vid) { Ok(True) },
      get_setting: fn(key) {
        case key {
          "song_prevent_duplicate" -> Ok("true")
          _ -> Error(repository.NotFound)
        }
      },
    )
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["https://youtu.be/dQw4w9WgXcQ"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "이 곡 이미 대기열에 있당 ㅋㅋ",
      ),
    ]
}

pub fn request_song_user_limit_test() {
  let base = empty_song_repo()
  let repo =
    Repository(..base, get_songs_by_user: fn(_user) {
      Ok([
        SongData(
          id: 1,
          video_id: "abc12345678",
          title: "T",
          duration_seconds: 0,
          requested_by: "alice",
          position: 0,
          created_at: 0,
        ),
      ])
    })
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["https://youtu.be/dQw4w9WgXcQ"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "신청 한도 넘었어용 ㅠㅠ (최대 1곡)",
      ),
    ]
}

pub fn request_song_insufficient_points_test() {
  let base = empty_song_repo()
  let repo =
    Repository(
      ..base,
      get_setting: fn(key) {
        case key {
          "song_cost_points" -> Ok("100")
          _ -> Error(repository.NotFound)
        }
      },
      get_user: fn(_uid) {
        Ok(repository.UserData(
          user_id: "alice",
          points: 50,
          attendance_count: 0,
          last_attendance: 0,
        ))
      },
    )
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["https://youtu.be/dQw4w9WgXcQ"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "포인트가 모자라용 ㅠㅠ (필요: 100, 보유: 50)",
      ),
    ]
}

pub fn request_song_with_points_deduction_test() {
  let base = empty_song_repo()
  let repo =
    Repository(
      ..base,
      get_setting: fn(key) {
        case key {
          "song_cost_points" -> Ok("10")
          _ -> Error(repository.NotFound)
        }
      },
      get_user: fn(_uid) {
        Ok(repository.UserData(
          user_id: "alice",
          points: 100,
          attendance_count: 0,
          last_attendance: 0,
        ))
      },
    )
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["https://youtu.be/dQw4w9WgXcQ"],
        role: permission.Viewer,
      ),
    )
  assert list.length(events) == 2
  case events {
    [
      plugin.PluginResponse(plugin: "song_request", message: _),
      plugin.PointsChange(user: "alice", amount: -10, reason: "song_request"),
    ] -> Nil
    _ -> panic as "Expected PluginResponse + PointsChange"
  }
}

pub fn skip_requires_moderator_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "노래",
        args: ["스킵"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "헐 이건 관리자만 할 수 있어용 ㅠ",
      ),
    ]
}

pub fn clear_requires_moderator_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "노래",
        args: ["비우기"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "헐 이건 관리자만 할 수 있어용 ㅠ",
      ),
    ]
}

pub fn clear_as_moderator_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "노래",
        args: ["비우기"],
        role: permission.Moderator,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "song_request", message: "대기열 싹 비웠당!"),
    ]
}

pub fn list_empty_queue_test() {
  let repo = empty_song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["목록"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "대기열이 비어있당 곡을 넣어줘용!",
      ),
    ]
}

pub fn list_with_songs_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["목록"],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "song_request", message: msg)] -> {
      assert {
        case msg {
          "대기열이에용!\n" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn current_song_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: ["현재"],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "song_request", message: msg)] -> {
      assert {
        case msg {
          "지금 듣고 있는 거 " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn help_message_test() {
  let repo = empty_song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "노래",
        args: [],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "song_request", message: msg)] -> {
      assert {
        case msg {
          "이렇게 써줘용 " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected help message"
  }
}

pub fn unrelated_event_ignored_test() {
  let repo = empty_song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "hello",
        channel: "test",
        channel_id: option.None,
      ),
    )
  assert events == []
}

pub fn remove_requires_moderator_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "노래",
        args: ["삭제", "1"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "song_request",
        message: "헐 이건 관리자만 할 수 있어용 ㅠ",
      ),
    ]
}

pub fn remove_as_moderator_test() {
  let repo = song_repo()
  let p = song_request.new(repo, "")
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "노래",
        args: ["삭제", "1"],
        role: permission.Moderator,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "song_request", message: msg)] -> {
      assert {
        case msg {
          "Test Song" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected deletion success message"
  }
}
