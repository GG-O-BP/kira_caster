import kira_caster/logger

pub fn info_does_not_crash_test() {
  logger.info("test info message")
}

pub fn warn_does_not_crash_test() {
  logger.warn("test warn message")
}

pub fn error_does_not_crash_test() {
  logger.error("test error message")
}
