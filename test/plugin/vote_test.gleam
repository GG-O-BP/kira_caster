import kira_caster/core/permission
import kira_caster/plugin/plugin
import kira_caster/plugin/vote
import kira_caster/storage/repository

pub fn moderator_start_vote_test() {
  let repo = repository.mock_repo([])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "투표",
        args: ["시작", "좋아하는 색", "빨강", "파랑"],
        role: permission.Moderator,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "vote", message: msg)] -> {
      assert {
        case msg {
          "투표 시작: " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn viewer_cannot_start_vote_test() {
  let repo = repository.mock_repo([])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "투표",
        args: ["시작", "주제", "A", "B"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "vote", message: "권한이 없습니다. (관리자 전용)"),
    ]
}

pub fn cast_vote_no_active_test() {
  let repo = repository.mock_repo([])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "투표",
        args: ["빨강"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "vote", message: "현재 진행 중인 투표가 없습니다."),
    ]
}

pub fn cast_vote_with_active_test() {
  let repo = repository.mock_repo_with_vote([], "좋아하는 색", ["빨강", "파랑"], [])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "투표",
        args: ["빨강"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "vote", message: "alice님이 '빨강'에 투표했습니다."),
    ]
}

pub fn cast_vote_invalid_choice_test() {
  let repo = repository.mock_repo_with_vote([], "좋아하는 색", ["빨강", "파랑"], [])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "투표",
        args: ["초록"],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "vote", message: msg)] -> {
      assert {
        case msg {
          "'초록'" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn vote_results_test() {
  let repo =
    repository.mock_repo_with_vote([], "좋아하는 색", ["빨강", "파랑"], [
      #("빨강", 3),
      #("파랑", 1),
    ])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "투표",
        args: ["결과"],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "vote", message: msg)] -> {
      assert {
        case msg {
          "투표 '" <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn help_message_test() {
  let repo = repository.mock_repo([])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "투표",
        args: [],
        role: permission.Viewer,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "vote", message: msg)] -> {
      assert {
        case msg {
          "사용법: " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}

pub fn unrelated_event_ignored_test() {
  let repo = repository.mock_repo([])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "hello", channel: "main"),
    )
  assert events == []
}

pub fn start_vote_one_option_rejected_test() {
  let repo = repository.mock_repo([])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "투표",
        args: ["시작", "주제", "A"],
        role: permission.Moderator,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "vote", message: "선택지를 2개 이상 입력해주세요."),
    ]
}

pub fn viewer_cannot_end_vote_test() {
  let repo = repository.mock_repo_with_vote([], "주제", ["A", "B"], [#("A", 1)])
  let p = vote.new(repo)
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "투표",
        args: ["종료"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "vote", message: "권한이 없습니다. (관리자 전용)"),
    ]
}
