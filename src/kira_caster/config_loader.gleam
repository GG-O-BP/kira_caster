import gleam/int
import gleam/list
import kira_caster/core/config.{type Config, Config}
import kira_caster/storage/repository.{type Repository}

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
    youtube_api_key: get_string("KIRA_YOUTUBE_API_KEY", d.youtube_api_key),
    cime_client_id: get_string("CIME_CLIENT_ID", d.cime_client_id),
    cime_client_secret: get_string("CIME_CLIENT_SECRET", d.cime_client_secret),
    cime_redirect_uri: get_string("CIME_REDIRECT_URI", d.cime_redirect_uri),
    cime_channel_id: get_string("CIME_CHANNEL_ID", d.cime_channel_id),
  )
}

/// DB settings 테이블에서 저장된 설정을 읽어 config에 병합합니다.
/// DB에 저장된 설정(UI 입력)이 우선 적용됩니다.
/// DB에 값이 없는 경우 환경변수 또는 기본값이 사용됩니다.
pub fn apply_db_settings(config: Config, repo: Repository) -> Config {
  case repo.get_all_settings() {
    Ok(settings) -> merge_settings(config, settings)
    Error(_) -> config
  }
}

fn merge_settings(config: Config, settings: List(#(String, String))) -> Config {
  let get = fn(key: String, fallback: String) -> String {
    case find_setting(settings, key) {
      "" -> fallback
      val -> val
    }
  }

  let get_int = fn(key: String, fallback: Int) -> Int {
    case find_setting(settings, key) {
      "" -> fallback
      val ->
        case int.parse(val) {
          Ok(n) -> n
          Error(_) -> fallback
        }
    }
  }

  // DB 설정(UI 입력)이 우선. DB에 값이 없으면 환경변수/기본값 사용.
  // db_path, admin_port, secret_key_base는 부트스트랩 전용 (DB 접근 전 필요)
  Config(
    ..config,
    admin_key: get("admin_key", config.admin_key),
    cime_client_id: get("cime_client_id", config.cime_client_id),
    cime_client_secret: get("cime_client_secret", config.cime_client_secret),
    cime_redirect_uri: get("cime_redirect_uri", config.cime_redirect_uri),
    cime_channel_id: get("cime_channel_id", config.cime_channel_id),
    youtube_api_key: get("youtube_api_key", config.youtube_api_key),
    cooldown_ms: get_int("cooldown_ms", config.cooldown_ms),
    attendance_points: get_int("attendance_points", config.attendance_points),
    dice_win_points: get_int("dice_win_points", config.dice_win_points),
    dice_loss_points: get_int("dice_loss_points", config.dice_loss_points),
    rps_win_points: get_int("rps_win_points", config.rps_win_points),
    rps_loss_points: get_int("rps_loss_points", config.rps_loss_points),
    max_reconnect_attempts: get_int(
      "max_reconnect_attempts",
      config.max_reconnect_attempts,
    ),
  )
}

fn find_setting(settings: List(#(String, String)), key: String) -> String {
  case list.find(settings, fn(s) { s.0 == key }) {
    Ok(#(_, v)) -> v
    Error(_) -> ""
  }
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
