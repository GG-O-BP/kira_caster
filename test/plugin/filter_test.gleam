import kira_caster/plugin/filter
import kira_caster/plugin/plugin

pub fn default_blocks_spam_test() {
  let p = filter.default()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "spam spam", channel: "main"),
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
  let p = filter.default()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "bob", content: "무료 홍보합니다", channel: "main"),
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
  let p = filter.default()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "charlie", content: "안녕하세요!", channel: "main"),
    )
  assert events == []
}

pub fn case_insensitive_test() {
  let p = filter.default()
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "SPAM HERE", channel: "main"),
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
  let p = filter.new(["bad", "evil"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "this is bad stuff",
        channel: "main",
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
  let p = filter.new(["bad"])
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(user: "alice", content: "spam here", channel: "main"),
    )
  assert events == []
}

pub fn unrelated_event_ignored_test() {
  let p = filter.default()
  let events =
    plugin.handle(p, plugin.Command(user: "alice", name: "test", args: []))
  assert events == []
}
