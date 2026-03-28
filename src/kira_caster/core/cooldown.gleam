import gleam/dict.{type Dict}

pub opaque type CooldownMap {
  CooldownMap(entries: Dict(String, Int))
}

pub type CooldownError {
  OnCooldown(remaining: Int)
}

pub fn new() -> CooldownMap {
  CooldownMap(entries: dict.new())
}

pub fn check(
  map: CooldownMap,
  command: String,
  now: Int,
  cooldown_ms: Int,
) -> Result(Nil, CooldownError) {
  case dict.get(map.entries, command) {
    Error(Nil) -> Ok(Nil)
    Ok(last_used) -> {
      let elapsed = now - last_used
      case elapsed >= cooldown_ms {
        True -> Ok(Nil)
        False -> Error(OnCooldown(remaining: cooldown_ms - elapsed))
      }
    }
  }
}

pub fn record_use(map: CooldownMap, command: String, now: Int) -> CooldownMap {
  CooldownMap(entries: dict.insert(map.entries, command, now))
}

pub fn reset(map: CooldownMap, command: String) -> CooldownMap {
  CooldownMap(entries: dict.delete(map.entries, command))
}
