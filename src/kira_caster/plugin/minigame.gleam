import gleam/int
import gleam/order
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}

pub fn new() -> Plugin {
  Plugin(name: "minigame", handle_event: handle)
}

fn handle(event: Event) -> List(Event) {
  case event {
    plugin.Command(user:, name: "게임", args: ["주사위", ..], role: _) ->
      play_dice(user)
    plugin.Command(user: _, name: "게임", args: _, role: _) -> [
      plugin.PluginResponse(plugin: "minigame", message: "사용법: !게임 주사위"),
    ]
    _ -> []
  }
}

fn play_dice(user: String) -> List(Event) {
  let player = int.random(6) + 1
  let house = int.random(6) + 1
  let dice_str = int.to_string(player) <> " vs " <> int.to_string(house)
  case int.compare(player, house) {
    order.Gt -> [
      plugin.PluginResponse(
        plugin: "minigame",
        message: user <> " 승리! [" <> dice_str <> "] (+50포인트)",
      ),
      plugin.PointsChange(user: user, amount: 50, reason: "dice_win"),
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
        message: user <> " 패배... [" <> dice_str <> "] (-20포인트)",
      ),
      plugin.PointsChange(user: user, amount: -20, reason: "dice_loss"),
    ]
  }
}
