import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/plugin/song_request/formatter.{resp}
import kira_caster/plugin/song_request/queue
import kira_caster/plugin/song_request/validator
import kira_caster/storage/repository.{type Repository}

pub fn new(repo: Repository, youtube_api_key: String) -> Plugin {
  Plugin(name: "song_request", handle_event: fn(event) {
    handle(repo, youtube_api_key, event)
  })
}

fn handle(repo: Repository, api_key: String, event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "노래", args: ["목록", ..], role: _) ->
      queue.handle_list(repo)
    plugin.Command(user: _, name: "노래", args: ["현재"], role: _) ->
      queue.handle_current(repo)
    plugin.Command(user: _, name: "노래", args: ["스킵"], role:) ->
      queue.handle_skip(repo, role)
    plugin.Command(user: _, name: "노래", args: ["삭제", num], role:) ->
      queue.handle_remove(repo, role, num)
    plugin.Command(user: _, name: "노래", args: ["비우기"], role:) ->
      queue.handle_clear(repo, role)
    plugin.Command(user:, name: "노래", args: [url], role: _) ->
      validator.validate_and_add(repo, api_key, user, url)
    plugin.Command(user: _, name: "노래", args: _, role: _) -> [
      resp(
        "사용법: !노래 <YouTube URL> / !노래 목록 / !노래 현재 / !노래 스킵 / !노래 삭제 <번호> / !노래 비우기",
      ),
    ]
    _ -> []
  }
}
