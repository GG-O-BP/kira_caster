import gleam/int
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository, UserData}
import kira_caster/util/time

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
  let now = time.now_ms()
  let today = now / 86_400_000
  let current = case repo.get_user(user) {
    Ok(data) -> data
    Error(_) ->
      UserData(
        user_id: user,
        points: 0,
        attendance_count: 0,
        last_attendance: 0,
      )
  }
  let last_day = current.last_attendance / 86_400_000
  case today == last_day && current.last_attendance > 0 {
    True -> [
      plugin.PluginResponse(
        plugin: "attendance",
        message: user <> "님, 오늘 이미 출석했잖아용 ㅋㅋ",
      ),
    ]
    False -> {
      let updated =
        UserData(
          ..current,
          attendance_count: current.attendance_count + 1,
          points: current.points + reward_points,
          last_attendance: now,
        )
      case repo.save_user(updated) {
        Ok(Nil) -> [
          plugin.PluginResponse(
            plugin: "attendance",
            message: user
              <> " 출석 완료당! (총 "
              <> int.to_string(updated.attendance_count)
              <> "회, +"
              <> int.to_string(reward_points)
              <> "포인트)",
          ),
        ]
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "attendance",
            message: "앗 출석하다가 뭔가 잘못됐어 ㅠㅠ",
          ),
        ]
      }
    }
  }
}
