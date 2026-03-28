-module(kira_caster_ffi).
-export([now_ms/0, get_env/1, log_info/1, log_warn/1, log_error/1]).

now_ms() -> os:system_time(millisecond).

get_env(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> {error, nil};
        Value -> {ok, list_to_binary(Value)}
    end.

log_info(Msg) -> logger:info("~ts", [Msg]), nil.
log_warn(Msg) -> logger:warning("~ts", [Msg]), nil.
log_error(Msg) -> logger:error("~ts", [Msg]), nil.
