import gleam/int
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository, UserData}

pub fn new(repo: Repository, reward_points: Int) -> Plugin {
  Plugin(name: "attendance", handle_event: fn(event) {
    handle(repo, reward_points, event)
  })
}

fn handle(repo: Repository, reward_points: Int, event: Event) -> List(Event) {
  case event {
    plugin.Command(user:, name: "출석", args: _, role: _) ->
      record_attendance(repo, reward_points, user)
    _ -> []
  }
}

fn record_attendance(
  repo: Repository,
  reward_points: Int,
  user: String,
) -> List(Event) {
  let current = case repo.get_user(user) {
    Ok(data) -> data
    Error(_) -> UserData(user_id: user, points: 0, attendance_count: 0)
  }
  let updated =
    UserData(
      ..current,
      attendance_count: current.attendance_count + 1,
      points: current.points + reward_points,
    )
  case repo.save_user(updated) {
    Ok(Nil) -> [
      plugin.PluginResponse(
        plugin: "attendance",
        message: user
          <> " 출석 완료! (총 "
          <> int.to_string(updated.attendance_count)
          <> "회, +"
          <> int.to_string(reward_points)
          <> "포인트)",
      ),
    ]
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "attendance",
        message: "출석 처리 중 오류가 발생했습니다.",
      ),
    ]
  }
}
