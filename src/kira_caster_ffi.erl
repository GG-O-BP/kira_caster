-module(kira_caster_ffi).
-export([now_ms/0, get_env/1, log_info/1, log_warn/1, log_error/1,
         compile_gleam/2, call_command/3, unload_command/1,
         ensure_custom_project/0]).

now_ms() -> os:system_time(millisecond).

get_env(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> {error, nil};
        Value -> {ok, list_to_binary(Value)}
    end.

log_info(Msg) -> logger:info("~ts", [Msg]), nil.
log_warn(Msg) -> logger:warning("~ts", [Msg]), nil.
log_error(Msg) -> logger:error("~ts", [Msg]), nil.

%% --- Advanced Gleam Commands ---

custom_project_dir() ->
    case os:getenv("KIRA_CUSTOM_CMD_DIR") of
        false -> "/tmp/kira_custom_commands";
        Dir -> Dir
    end.

ensure_custom_project() ->
    Dir = custom_project_dir(),
    SrcDir = filename:join(Dir, "src"),
    GleamToml = filename:join(Dir, "gleam.toml"),
    ok = filelib:ensure_dir(filename:join(SrcDir, "dummy")),
    case filelib:is_regular(GleamToml) of
        true -> {ok, nil};
        false ->
            Content = <<"name = \"kira_custom_commands\"\n"
                        "version = \"0.1.0\"\n"
                        "target = \"erlang\"\n\n"
                        "[dependencies]\n"
                        "gleam_stdlib = \">= 0.44.0\"\n">>,
            case file:write_file(GleamToml, Content) of
                ok ->
                    Cmd = "cd " ++ Dir ++ " && gleam deps download 2>&1",
                    os:cmd(Cmd),
                    {ok, nil};
                {error, Reason} ->
                    {error, list_to_binary(io_lib:format("~p", [Reason]))}
            end
    end.

compile_gleam(Name, SourceCode) ->
    try
        do_compile_gleam(Name, SourceCode)
    catch
        _:Reason ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

do_compile_gleam(Name, SourceCode) ->
    Dir = custom_project_dir(),
    ModName = <<"kira_cmd_", Name/binary>>,
    FileName = binary_to_list(<<ModName/binary, ".gleam">>),
    FilePath = filename:join([Dir, "src", FileName]),
    ok = file:write_file(FilePath, SourceCode),
    Cmd = "cd " ++ Dir ++ " && gleam build 2>&1",
    Output = os:cmd(Cmd),
    OutputBin = list_to_binary(Output),
    %% Check if compilation succeeded
    case binary:match(OutputBin, <<"Compiled">>) of
        nomatch ->
            %% Clean up failed file
            file:delete(FilePath),
            {error, OutputBin};
        _ ->
            %% Find and load the .beam file
            EbinDir = filename:join([Dir, "build", "dev", "erlang",
                                     "kira_custom_commands", "ebin"]),
            ModAtom = binary_to_atom(ModName, utf8),
            BeamFile = filename:join(EbinDir,
                binary_to_list(<<ModName/binary, ".beam">>)),
            case file:read_file(BeamFile) of
                {ok, Binary} ->
                    code:purge(ModAtom),
                    {module, ModAtom} = code:load_binary(ModAtom, BeamFile, Binary),
                    {ok, nil};
                {error, ReadErr} ->
                    {error, list_to_binary(io_lib:format("beam load failed: ~p", [ReadErr]))}
            end
    end.

call_command(Name, User, Args) ->
    ModAtom = binary_to_atom(<<"kira_cmd_", Name/binary>>, utf8),
    try
        Result = ModAtom:handle(User, Args),
        {ok, Result}
    catch
        _:Reason ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

unload_command(Name) ->
    ModAtom = binary_to_atom(<<"kira_cmd_", Name/binary>>, utf8),
    code:purge(ModAtom),
    code:delete(ModAtom),
    %% Also remove source file
    Dir = custom_project_dir(),
    FileName = binary_to_list(<<"kira_cmd_", Name/binary, ".gleam">>),
    FilePath = filename:join([Dir, "src", FileName]),
    file:delete(FilePath),
    nil.
