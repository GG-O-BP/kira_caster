import kira_caster/core/config

pub fn default_values_test() {
  let c = config.default()
  assert c.db_path == "kira_caster.db"
  assert c.cooldown_ms == 5000
  assert c.attendance_points == 10
  assert c.dice_win_points == 50
  assert c.dice_loss_points == -20
  assert c.rps_win_points == 30
  assert c.rps_loss_points == -10
  assert c.max_reconnect_attempts == 5
  assert c.admin_port == 8080
}

pub fn default_banned_words_test() {
  let c = config.default()
  assert c.default_banned_words == ["spam", "홍보", "광고"]
}
