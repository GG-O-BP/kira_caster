-module(kira_caster_ffi).
-export([now_ms/0]).

now_ms() -> os:system_time(millisecond).
