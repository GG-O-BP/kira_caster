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
    admin_key: String,
    secret_key_base: String,
    youtube_api_key: String,
    cime_client_id: String,
    cime_client_secret: String,
    cime_redirect_uri: String,
    cime_channel_id: String,
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
    admin_port: 9693,
    admin_key: "",
    secret_key_base: "kira_caster_default_secret_key_please_change_in_production",
    youtube_api_key: "",
    cime_client_id: "",
    cime_client_secret: "",
    cime_redirect_uri: "",
    cime_channel_id: "",
  )
}
