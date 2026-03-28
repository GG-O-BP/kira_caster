import kira_caster/core/cooldown

pub fn new_cooldown_allows_command_test() {
  let map = cooldown.new()
  let assert Ok(Nil) = cooldown.check(map, "ping", 1000, 5000)
}

pub fn used_command_on_cooldown_test() {
  let map = cooldown.new()
  let map = cooldown.record_use(map, "ping", 1000)
  let assert Error(cooldown.OnCooldown(remaining: 4000)) =
    cooldown.check(map, "ping", 2000, 5000)
}

pub fn cooldown_expired_test() {
  let map = cooldown.new()
  let map = cooldown.record_use(map, "ping", 1000)
  let assert Ok(Nil) = cooldown.check(map, "ping", 7000, 5000)
}

pub fn reset_clears_cooldown_test() {
  let map = cooldown.new()
  let map = cooldown.record_use(map, "ping", 1000)
  let map = cooldown.reset(map, "ping")
  let assert Ok(Nil) = cooldown.check(map, "ping", 1500, 5000)
}

pub fn different_commands_independent_test() {
  let map = cooldown.new()
  let map = cooldown.record_use(map, "ping", 1000)
  let assert Ok(Nil) = cooldown.check(map, "pong", 1500, 5000)
}
