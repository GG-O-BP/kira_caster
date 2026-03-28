import gleam/int
import kira_caster/core/config.{type Config, Config}

@external(erlang, "kira_caster_ffi", "get_env")
fn get_env(name: String) -> Result(String, Nil)

pub fn load() -> Config {
  let d = config.default()
  Config(
    db_path: get_string("KIRA_DB_PATH", d.db_path),
    cooldown_ms: get_int("KIRA_COOLDOWN_MS", d.cooldown_ms),
    default_banned_words: d.default_banned_words,
    attendance_points: get_int("KIRA_ATTENDANCE_POINTS", d.attendance_points),
    dice_win_points: get_int("KIRA_DICE_WIN_POINTS", d.dice_win_points),
    dice_loss_points: get_int("KIRA_DICE_LOSS_POINTS", d.dice_loss_points),
    rps_win_points: get_int("KIRA_RPS_WIN_POINTS", d.rps_win_points),
    rps_loss_points: get_int("KIRA_RPS_LOSS_POINTS", d.rps_loss_points),
    max_reconnect_attempts: get_int(
      "KIRA_MAX_RECONNECT",
      d.max_reconnect_attempts,
    ),
    admin_port: get_int("KIRA_ADMIN_PORT", d.admin_port),
    admin_key: get_string("KIRA_ADMIN_KEY", d.admin_key),
    secret_key_base: get_string("KIRA_SECRET_KEY", d.secret_key_base),
  )
}

fn get_string(name: String, fallback: String) -> String {
  case get_env(name) {
    Ok(val) -> val
    Error(_) -> fallback
  }
}

fn get_int(name: String, fallback: Int) -> Int {
  case get_env(name) {
    Ok(val) ->
      case int.parse(val) {
        Ok(n) -> n
        Error(_) -> fallback
      }
    Error(_) -> fallback
  }
}
