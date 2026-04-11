import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time

pub fn new(repo: Repository) -> Plugin {
  Plugin(name: "donation_alert", handle_event: fn(event) { handle(repo, event) })
}

fn handle(repo: Repository, event: Event) -> List(Event) {
  case event {
    plugin.Donation(user:, channel_id:, amount:, message:, donation_type:) ->
      handle_donation(repo, user, channel_id, amount, message, donation_type)
    plugin.Command(user: _, name: "후원순위", args: _, role: _) ->
      handle_ranking(repo)
    _ -> []
  }
}

fn handle_donation(
  repo: Repository,
  user: String,
  channel_id: option.Option(String),
  amount: String,
  message: String,
  donation_type: String,
) -> List(Event) {
  // Save to history
  let cid = case channel_id {
    Some(id) -> id
    None -> ""
  }
  let now = time.now_ms()
  let _ = repo.save_donation(cid, user, amount, message, donation_type, now)

  // Format alert message
  let type_label = case donation_type {
    "VIDEO" -> " (영상 후원이에용)"
    _ -> ""
  }

  let alert = case channel_id {
    None ->
      "익명님이 "
      <> amount
      <> "빔 후원해줬당!"
      <> type_label
      <> format_donation_message(message)
    Some(_) ->
      user
      <> "님이 "
      <> amount
      <> "빔 후원해줬당!"
      <> type_label
      <> format_donation_message(message)
  }

  [plugin.PluginResponse(plugin: "donation_alert", message: alert)]
}

fn format_donation_message(message: String) -> String {
  case string.is_empty(message) {
    True -> ""
    False -> " \"" <> message <> "\""
  }
}

fn handle_ranking(repo: Repository) -> List(Event) {
  case repo.get_donation_ranking(5) {
    Ok(ranking) -> {
      case ranking {
        [] -> [
          plugin.PluginResponse(
            plugin: "donation_alert",
            message: "후원 기록이 없당..",
          ),
        ]
        _ -> {
          let entries =
            list.index_map(ranking, fn(entry, i) {
              int.to_string(i + 1) <> ". " <> entry.0 <> " - " <> entry.1 <> "빔"
            })
          let msg = "후원 순위이에용 " <> string.join(entries, " | ")
          [plugin.PluginResponse(plugin: "donation_alert", message: msg)]
        }
      }
    }
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "donation_alert",
        message: "앗 후원 순위 불러오다 에러났어 ㅠㅠ",
      ),
    ]
  }
}
