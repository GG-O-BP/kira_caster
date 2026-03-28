import gleam/int
import gleam/order
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new(dice_win: Int, dice_loss: Int, rps_win: Int, rps_loss: Int) -> Plugin {
  Plugin(name: "minigame", handle_event: fn(event) {
    handle(dice_win, dice_loss, rps_win, rps_loss, event)
  })
}

fn handle(
  dice_win: Int,
  dice_loss: Int,
  rps_win: Int,
  rps_loss: Int,
  event: Event,
) -> List(Event) {
  case event {
    plugin.Command(user:, name: "게임", args: ["주사위", ..], role: _) ->
      play_dice(user, dice_win, dice_loss)
    plugin.Command(user:, name: "게임", args: ["가위바위보", choice, ..], role: _) ->
      play_rps(user, choice, rps_win, rps_loss)
    plugin.Command(user: _, name: "게임", args: _, role: _) -> [
      plugin.PluginResponse(
        plugin: "minigame",
        message: "사용법: !게임 주사위 / !게임 가위바위보 <가위|바위|보>",
      ),
    ]
    _ -> []
  }
}

fn play_dice(user: String, win_pts: Int, loss_pts: Int) -> List(Event) {
  let player = int.random(6) + 1
  let house = int.random(6) + 1
  let dice_str = int.to_string(player) <> " vs " <> int.to_string(house)
  case int.compare(player, house) {
    order.Gt -> [
      plugin.PluginResponse(
        plugin: "minigame",
        message: user
          <> " 승리! ["
          <> dice_str
          <> "] (+"
          <> int.to_string(win_pts)
          <> "포인트)",
      ),
      plugin.PointsChange(user: user, amount: win_pts, reason: "dice_win"),
    ]
    order.Eq -> [
      plugin.PluginResponse(
        plugin: "minigame",
        message: "무승부! [" <> dice_str <> "]",
      ),
    ]
    order.Lt -> [
      plugin.PluginResponse(
        plugin: "minigame",
        message: user
          <> " 패배... ["
          <> dice_str
          <> "] ("
          <> int.to_string(loss_pts)
          <> "포인트)",
      ),
      plugin.PointsChange(user: user, amount: loss_pts, reason: "dice_loss"),
    ]
  }
}

fn play_rps(
  user: String,
  choice: String,
  win_pts: Int,
  loss_pts: Int,
) -> List(Event) {
  case choice == "가위" || choice == "바위" || choice == "보" {
    False -> [
      plugin.PluginResponse(
        plugin: "minigame",
        message: "가위, 바위, 보 중 하나를 선택해주세요.",
      ),
    ]
    True -> {
      let opponent_idx = int.random(3)
      let opponent = case opponent_idx {
        0 -> "가위"
        1 -> "바위"
        _ -> "보"
      }
      let result_str = choice <> " vs " <> opponent
      case rps_result(choice, opponent) {
        Win -> [
          plugin.PluginResponse(
            plugin: "minigame",
            message: user
              <> " 승리! ["
              <> result_str
              <> "] (+"
              <> int.to_string(win_pts)
              <> "포인트)",
          ),
          plugin.PointsChange(user: user, amount: win_pts, reason: "rps_win"),
        ]
        Draw -> [
          plugin.PluginResponse(
            plugin: "minigame",
            message: "무승부! [" <> result_str <> "]",
          ),
        ]
        Lose -> [
          plugin.PluginResponse(
            plugin: "minigame",
            message: user
              <> " 패배... ["
              <> result_str
              <> "] ("
              <> int.to_string(loss_pts)
              <> "포인트)",
          ),
          plugin.PointsChange(user: user, amount: loss_pts, reason: "rps_loss"),
        ]
      }
    }
  }
}

type RpsResult {
  Win
  Draw
  Lose
}

fn rps_result(player: String, opponent: String) -> RpsResult {
  case player, opponent {
    p, o if p == o -> Draw
    "가위", "보" -> Win
    "바위", "가위" -> Win
    "보", "바위" -> Win
    _, _ -> Lose
  }
}
