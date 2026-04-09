import gleam/int
import gleam/list
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time

pub fn new(
  repo: Repository,
  get_token: fn() -> Result(String, String),
  api: CimeApi,
) -> Plugin {
  Plugin(name: "follower", handle_event: fn(event) {
    handle(repo, get_token, api, event)
  })
}

fn handle(
  repo: Repository,
  get_token: fn() -> Result(String, String),
  api: CimeApi,
  event: Event,
) -> List(Event) {
  case event {
    plugin.SystemEvent(kind: "follower_poll_tick", data: _) ->
      handle_poll(repo, get_token, api)
    plugin.Command(user: _, name: "팔로워", args: _, role: _) ->
      handle_follower_count(get_token, api)
    _ -> []
  }
}

fn handle_poll(
  repo: Repository,
  get_token: fn() -> Result(String, String),
  api: CimeApi,
) -> List(Event) {
  case get_token() {
    Ok(token) ->
      case api.get_followers(token, 0, 50) {
        Ok(followers) -> {
          case repo.get_known_followers() {
            Ok(known) -> {
              let now = time.now_ms()
              let new_followers =
                list.filter(followers, fn(f) {
                  !list.contains(known, f.channel_id)
                })
              // Add new followers to cache
              list.each(new_followers, fn(f) {
                let _ =
                  repo.add_known_follower(f.channel_id, f.channel_name, now)
                Nil
              })
              // Generate welcome messages
              list.map(new_followers, fn(f) {
                plugin.PluginResponse(
                  plugin: "follower",
                  message: f.channel_name <> "님이 팔로우했습니다! 환영합니다!",
                )
              })
            }
            Error(_) -> []
          }
        }
        Error(_) -> []
      }
    Error(_) -> []
  }
}

fn handle_follower_count(
  get_token: fn() -> Result(String, String),
  api: CimeApi,
) -> List(Event) {
  case get_token() {
    Ok(token) ->
      case api.get_followers(token, 0, 1) {
        Ok(followers) -> {
          let count = list.length(followers)
          [
            plugin.PluginResponse(
              plugin: "follower",
              message: "현재 팔로워: " <> int.to_string(count) <> "명",
            ),
          ]
        }
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "follower",
            message: "팔로워 수를 조회할 수 없습니다.",
          ),
        ]
      }
    Error(_) -> [
      plugin.PluginResponse(plugin: "follower", message: "인증 토큰을 가져올 수 없습니다."),
    ]
  }
}
