import gleam/list
import gleam/string
import kira_caster/core/permission
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository}

pub fn new(repo: Repository, default_words: List(String)) -> Plugin {
  Plugin(name: "filter", handle_event: fn(event) {
    handle(repo, default_words, event)
  })
}

pub fn default(repo: Repository, default_words: List(String)) -> Plugin {
  new(repo, default_words)
}

fn handle(
  repo: Repository,
  default_words: List(String),
  event: Event,
) -> List(Event) {
  case event {
    plugin.ChatMessage(user:, content:, channel: _) -> {
      let banned = get_all_banned(repo, default_words)
      case contains_banned_word(content, banned) {
        True -> [
          plugin.SystemEvent(
            kind: "filter_blocked",
            data: "Message from " <> user <> " blocked",
          ),
        ]
        False -> []
      }
    }
    plugin.Command(user: _, name: "필터", args: ["추가", word], role:) ->
      handle_add_word(repo, role, word)
    plugin.Command(user: _, name: "필터", args: ["삭제", word], role:) ->
      handle_remove_word(repo, role, word)
    plugin.Command(user: _, name: "필터", args: ["목록"], role:) ->
      handle_list_words(repo, default_words, role)
    _ -> []
  }
}

fn get_all_banned(repo: Repository, default_words: List(String)) -> List(String) {
  case repo.get_banned_words() {
    Ok(db_words) -> list.append(default_words, db_words)
    Error(_) -> default_words
  }
}

fn handle_add_word(
  repo: Repository,
  role: permission.Role,
  word: String,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(plugin: "filter", message: "권한이 없습니다. (관리자 전용)"),
    ]
    Ok(Nil) ->
      case repo.add_banned_word(string.lowercase(word)) {
        Ok(Nil) -> [
          plugin.PluginResponse(
            plugin: "filter",
            message: "'" <> word <> "' 단어를 필터에 추가했습니다.",
          ),
        ]
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "filter",
            message: "필터 추가 중 오류가 발생했습니다.",
          ),
        ]
      }
  }
}

fn handle_remove_word(
  repo: Repository,
  role: permission.Role,
  word: String,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(plugin: "filter", message: "권한이 없습니다. (관리자 전용)"),
    ]
    Ok(Nil) ->
      case repo.remove_banned_word(string.lowercase(word)) {
        Ok(Nil) -> [
          plugin.PluginResponse(
            plugin: "filter",
            message: "'" <> word <> "' 단어를 필터에서 삭제했습니다.",
          ),
        ]
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "filter",
            message: "필터 삭제 중 오류가 발생했습니다.",
          ),
        ]
      }
  }
}

fn handle_list_words(
  repo: Repository,
  default_words: List(String),
  role: permission.Role,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(plugin: "filter", message: "권한이 없습니다. (관리자 전용)"),
    ]
    Ok(Nil) -> {
      let all = get_all_banned(repo, default_words)
      let msg = case all {
        [] -> "등록된 금지어가 없습니다."
        _ -> "금지어 목록: " <> string.join(all, ", ")
      }
      [plugin.PluginResponse(plugin: "filter", message: msg)]
    }
  }
}

fn contains_banned_word(content: String, banned_words: List(String)) -> Bool {
  let lower = string.lowercase(content)
  list.any(banned_words, fn(word) { string.contains(lower, word) })
}
