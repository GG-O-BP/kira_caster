-module(cime_ws_ffi).
-export([ws_connect/1, ws_send/2, ws_close/1]).

%% Connect to a WebSocket URL (wss://host/path?query)
%% Returns {ok, ConnPid} or {error, Reason}
ws_connect(Url) ->
    try
        do_ws_connect(Url)
    catch
        Class:Reason:Stack ->
            {error, list_to_binary(io_lib:format("~p:~p ~p", [Class, Reason, Stack]))}
    end.

do_ws_connect(Url) ->
    UrlBin = case is_binary(Url) of true -> Url; false -> list_to_binary(Url) end,
    Parsed = uri_string:parse(UrlBin),
    Scheme = case maps:get(scheme, Parsed, <<>>) of
        S when is_binary(S) -> binary_to_atom(S, utf8);
        S when is_list(S) -> list_to_atom(S)
    end,
    Host = to_binary(maps:get(host, Parsed, <<>>)),
    Port = case maps:get(port, Parsed, undefined) of
        undefined ->
            case Scheme of
                wss -> 443;
                ws -> 80;
                _ -> 443
            end;
        P when is_integer(P) -> P
    end,
    Path = case maps:get(path, Parsed, <<"/">>) of
        <<>> -> <<"/">>;
        PBin when is_binary(PBin) -> PBin;
        PList when is_list(PList) -> list_to_binary(PList)
    end,
    Query = to_binary(maps:get(query, Parsed, <<>>)),
    FullPath = case Query of
        <<>> -> Path;
        _ -> <<Path/binary, "?", Query/binary>>
    end,
    TransportOpts = case Scheme of
        wss -> #{protocols => [http], transport => tls, tls_opts => [{verify, verify_none}]};
        ws -> #{protocols => [http]};
        _ -> #{protocols => [http], transport => tls, tls_opts => [{verify, verify_none}]}
    end,
    {ok, ConnPid} = gun:open(binary_to_list(Host), Port, TransportOpts),
    {ok, _Protocol} = gun:await_up(ConnPid, 10000),
    StreamRef = gun:ws_upgrade(ConnPid, FullPath, []),
    receive
        {gun_upgrade, ConnPid, StreamRef, [<<"websocket">>], _Headers} ->
            {ok, ConnPid};
        {gun_response, ConnPid, _, _, Status, _Headers} ->
            gun:close(ConnPid),
            {error, list_to_binary(io_lib:format("WS upgrade failed: ~p", [Status]))};
        {gun_error, ConnPid, StreamRef, Reason} ->
            gun:close(ConnPid),
            {error, list_to_binary(io_lib:format("WS error: ~p", [Reason]))}
    after 10000 ->
        gun:close(ConnPid),
        {error, <<"WS upgrade timeout">>}
    end.

to_binary(B) when is_binary(B) -> B;
to_binary(L) when is_list(L) -> list_to_binary(L);
to_binary(_) -> <<>>.

%% Send a text frame over WebSocket
ws_send(ConnPid, Message) ->
    try
        gun:ws_send(ConnPid, {text, Message}),
        {ok, nil}
    catch
        _:Reason ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

%% Close a WebSocket connection
ws_close(ConnPid) ->
    try
        gun:close(ConnPid),
        {ok, nil}
    catch
        _:_ -> {ok, nil}
    end.
