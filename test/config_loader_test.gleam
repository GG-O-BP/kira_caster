import kira_caster/config_loader
import kira_caster/core/config

pub fn load_returns_default_values_test() {
  let loaded = config_loader.load()
  let d = config.default()
  assert loaded.db_path == d.db_path
  assert loaded.cooldown_ms == d.cooldown_ms
  assert loaded.attendance_points == d.attendance_points
  assert loaded.dice_win_points == d.dice_win_points
  assert loaded.dice_loss_points == d.dice_loss_points
  assert loaded.rps_win_points == d.rps_win_points
  assert loaded.rps_loss_points == d.rps_loss_points
  assert loaded.max_reconnect_attempts == d.max_reconnect_attempts
  assert loaded.admin_port == d.admin_port
}

pub fn load_preserves_default_banned_words_test() {
  let loaded = config_loader.load()
  assert loaded.default_banned_words == ["spam", "홍보", "광고"]
}
