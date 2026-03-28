@external(erlang, "kira_caster_ffi", "log_info")
pub fn info(msg: String) -> Nil

@external(erlang, "kira_caster_ffi", "log_warn")
pub fn warn(msg: String) -> Nil

@external(erlang, "kira_caster_ffi", "log_error")
pub fn error(msg: String) -> Nil
