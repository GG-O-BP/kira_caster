import kira_caster/util/time

pub fn now_ms_returns_positive_test() {
  assert time.now_ms() > 0
}

pub fn now_ms_is_monotonic_test() {
  let first = time.now_ms()
  let second = time.now_ms()
  assert second >= first
}
