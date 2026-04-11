import gleam/int
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "roulette", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.Command(user:, name: "룰렛", args: _, role: _) -> spin(user)
    _ -> []
  }
}

fn spin(user: String) -> List(Event) {
  // 0-99 범위, 가중치: 꽝(40%), 보통(30%), 좋음(20%), 대박(10%)
  let roll = int.random(100)
  let #(label, points) = case roll {
    n if n < 10 -> #("대박이당!!", 100)
    n if n < 30 -> #("오 좋앙!", 30)
    n if n < 60 -> #("그냥 그렇당", 10)
    _ -> #("꽝이잖아 ㅠㅠ", -10)
  }
  let msg =
    user
    <> "님 룰렛 결과이에용 "
    <> label
    <> " ("
    <> case points >= 0 {
      True -> "+"
      False -> ""
    }
    <> int.to_string(points)
    <> "포인트)"
  [
    plugin.PluginResponse(plugin: "roulette", message: msg),
    plugin.PointsChange(user: user, amount: points, reason: "roulette"),
  ]
}
