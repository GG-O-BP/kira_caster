import gleam/int
import gleam/list
import gleam/string
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository, type UserData}

pub fn new(repo: Repository) -> Plugin {
  Plugin(name: "points", handle_event: fn(event) { handle(repo, event) })
}

fn handle(repo: Repository, event: Event) -> List(Event) {
  case event {
    plugin.Command(user:, name: "포인트", args: []) -> check_balance(repo, user)
    plugin.Command(user: _, name: "포인트", args: ["순위", ..]) -> show_ranking(repo)
    _ -> []
  }
}

fn check_balance(repo: Repository, user: String) -> List(Event) {
  let points = case repo.get_user(user) {
    Ok(data) -> data.points
    Error(_) -> 0
  }
  [
    plugin.PluginResponse(
      plugin: "points",
      message: user <> "님의 포인트: " <> int.to_string(points),
    ),
  ]
}

fn show_ranking(repo: Repository) -> List(Event) {
  case repo.get_all_users() {
    Ok(users) -> {
      let sorted =
        list.sort(users, fn(a: UserData, b: UserData) {
          int.compare(b.points, a.points)
        })
      let top5 = list.take(sorted, 5)
      let lines =
        list.index_map(top5, fn(u, i) {
          int.to_string(i + 1)
          <> ". "
          <> u.user_id
          <> " - "
          <> int.to_string(u.points)
          <> "pt"
        })
      let message = case lines {
        [] -> "등록된 유저가 없습니다."
        _ -> "포인트 순위:\n" <> string.join(lines, "\n")
      }
      [plugin.PluginResponse(plugin: "points", message:)]
    }
    Error(_) -> [
      plugin.PluginResponse(plugin: "points", message: "순위 조회에 실패했습니다."),
    ]
  }
}
