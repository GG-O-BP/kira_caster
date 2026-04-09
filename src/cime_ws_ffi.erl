-module(cime_ws_ffi).
-export([ws_connect/1, ws_send/2, ws_close/1]).

%% Connect to a WebSocket URL (wss://host/path?query)
%% Returns {ok, ConnPid} or {error, Reason}
ws_connect(Url) ->
    try
        do_ws_connect(Url)
    catch
        _:Reason ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

do_ws_connect(Url) ->
    UrlStr = binary_to_list(Url),
    {ok, {Scheme, _UserInfo, Host, Port, Path, Query}} = http_uri:parse(UrlStr, [{scheme_defaults, [{wss, 443}, {ws, 80}]}]),
    TransportOpts = case Scheme of
        wss -> #{protocols => [http], transport => tls, tls_opts => [{verify, verify_none}]};
        ws -> #{protocols => [http]}
    end,
    {ok, ConnPid} = gun:open(list_to_binary(Host), Port, TransportOpts),
    {ok, _Protocol} = gun:await_up(ConnPid, 10000),
    FullPath = case Query of
        [] -> Path;
        _ -> Path ++ Query
    end,
    StreamRef = gun:ws_upgrade(ConnPid, list_to_binary(FullPath), []),
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
