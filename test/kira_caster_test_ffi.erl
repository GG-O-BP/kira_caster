-module(kira_caster_test_ffi).
-export([clean_custom_commands/0]).

clean_custom_commands() ->
    Dir = case os:getenv("KIRA_CUSTOM_CMD_DIR") of
        false -> "/tmp/kira_custom_commands";
        D -> D
    end,
    SrcDir = filename:join(Dir, "src"),
    case file:list_dir(SrcDir) of
        {ok, Files} ->
            lists:foreach(fun(F) ->
                case lists:suffix(".gleam", F) of
                    true -> file:delete(filename:join(SrcDir, F));
                    false -> ok
                end
            end, Files);
        _ -> ok
    end,
    nil.
