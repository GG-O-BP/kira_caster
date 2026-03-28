pub type Config {
  Config(
    db_path: String,
    cooldown_ms: Int,
    default_banned_words: List(String),
    attendance_points: Int,
    dice_win_points: Int,
    dice_loss_points: Int,
    rps_win_points: Int,
    rps_loss_points: Int,
    max_reconnect_attempts: Int,
    admin_port: Int,
  )
}

pub fn default() -> Config {
  Config(
    db_path: "kira_caster.db",
    cooldown_ms: 5000,
    default_banned_words: ["spam", "홍보", "광고"],
    attendance_points: 10,
    dice_win_points: 50,
    dice_loss_points: -20,
    rps_win_points: 30,
    rps_loss_points: -10,
    max_reconnect_attempts: 5,
    admin_port: 8080,
  )
}
