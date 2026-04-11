import gleam/option
import kira_caster/core/permission
import kira_caster/plugin/filter
import kira_caster/plugin/plugin
import kira_caster/storage/repository

pub fn default_blocks_spam_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "spam spam",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events
    == [
      plugin.SystemEvent(
        kind: "filter_blocked",
        data: "Message from alice blocked",
      ),
    ]
}

pub fn default_blocks_korean_ad_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "bob",
        content: "무료 홍보합니다",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events
    == [
      plugin.SystemEvent(
        kind: "filter_blocked",
        data: "Message from bob blocked",
      ),
    ]
}

pub fn clean_message_passes_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "charlie",
        content: "안녕하세요!",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events == []
}

pub fn case_insensitive_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "SPAM HERE",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events
    == [
      plugin.SystemEvent(
        kind: "filter_blocked",
        data: "Message from alice blocked",
      ),
    ]
}

pub fn custom_banned_words_test() {
  let p = filter.new(repository.mock_repo([]), ["bad", "evil"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "this is bad stuff",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events
    == [
      plugin.SystemEvent(
        kind: "filter_blocked",
        data: "Message from alice blocked",
      ),
    ]
}

pub fn custom_words_dont_match_default_test() {
  let p = filter.new(repository.mock_repo([]), ["bad"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "spam here",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events == []
}

pub fn db_words_checked_test() {
  let repo = repository.mock_repo_with_words([], ["금칙어"])
  let p = filter.new(repo, [])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "여기에 금칙어 있음",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events
    == [
      plugin.SystemEvent(
        kind: "filter_blocked",
        data: "Message from alice blocked",
      ),
    ]
}

pub fn unrelated_event_ignored_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "alice",
        name: "test",
        args: [],
        role: permission.Viewer,
      ),
    )
  assert events == []
}

pub fn moderator_add_word_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "필터",
        args: ["추가", "나쁜말"],
        role: permission.Moderator,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "filter", message: "'나쁜말' 추가했당!"),
    ]
}

pub fn viewer_cannot_add_word_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "필터",
        args: ["추가", "test"],
        role: permission.Viewer,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(plugin: "filter", message: "헐 이건 관리자만 할 수 있어용 ㅠ"),
    ]
}

pub fn moderator_remove_word_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "필터",
        args: ["삭제", "spam"],
        role: permission.Moderator,
      ),
    )
  assert events
    == [
      plugin.PluginResponse(
        plugin: "filter",
        message: "'spam' 삭제했당!",
      ),
    ]
}

pub fn multiple_banned_words_single_event_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "spam 그리고 광고",
        channel: "main",
        channel_id: option.None,
      ),
    )
  assert events
    == [
      plugin.SystemEvent(
        kind: "filter_blocked",
        data: "Message from alice blocked",
      ),
    ]
}

pub fn moderator_list_words_test() {
  let p = filter.default(repository.mock_repo([]), ["spam", "홍보", "광고"])
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "필터",
        args: ["목록"],
        role: permission.Moderator,
      ),
    )
  case events {
    [plugin.PluginResponse(plugin: "filter", message: msg)] -> {
      assert {
        case msg {
          "금지어 목록이에용 " <> _ -> True
          _ -> False
        }
      }
    }
    _ -> panic as "Expected single PluginResponse"
  }
}
