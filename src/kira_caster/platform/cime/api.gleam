import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import kira_caster/platform/cime/decoders
import kira_caster/platform/cime/http_client
import kira_caster/platform/cime/types.{
  type Category, type ChannelInfo, type ChatSettings, type CimeError,
  type Follower, type LiveInfo, type LiveSetting, type LiveStatus, type PageInfo,
  type RestrictedChannel, type SessionResponse, type StreamKey,
  type StreamingRole, type Subscriber, type TokenResponse, type UserMe,
}

pub type CimeApi {
  CimeApi(
    exchange_code: fn(String) -> Result(TokenResponse, CimeError),
    refresh_token: fn(String) -> Result(TokenResponse, CimeError),
    revoke_token: fn(String, String) -> Result(Nil, CimeError),
    get_me: fn(String) -> Result(UserMe, CimeError),
    get_channels: fn(List(String)) -> Result(List(ChannelInfo), CimeError),
    get_followers: fn(String, Int, Int) -> Result(List(Follower), CimeError),
    get_subscribers: fn(String, Int, Int) -> Result(List(Subscriber), CimeError),
    get_streaming_roles: fn(String) -> Result(List(StreamingRole), CimeError),
    get_lives: fn(Int, Option(String)) ->
      Result(#(List(LiveInfo), PageInfo), CimeError),
    get_live_status: fn(String) -> Result(LiveStatus, CimeError),
    get_live_setting: fn(String) -> Result(LiveSetting, CimeError),
    update_live_setting: fn(String, String) -> Result(Nil, CimeError),
    get_stream_key: fn(String) -> Result(StreamKey, CimeError),
    send_chat: fn(String, String) -> Result(String, CimeError),
    send_notice: fn(String, String) -> Result(Nil, CimeError),
    get_chat_settings: fn(String) -> Result(ChatSettings, CimeError),
    update_chat_settings: fn(String, String) -> Result(Nil, CimeError),
    block_user: fn(String, String) -> Result(Nil, CimeError),
    unblock_user: fn(String, String) -> Result(Nil, CimeError),
    get_blocked_users: fn(String, Int, Option(String)) ->
      Result(#(List(RestrictedChannel), PageInfo), CimeError),
    search_categories: fn(String, Int) -> Result(List(Category), CimeError),
    create_user_session: fn(String) -> Result(SessionResponse, CimeError),
    subscribe_event: fn(String, String, String) -> Result(Nil, CimeError),
    unsubscribe_event: fn(String, String, String) -> Result(Nil, CimeError),
  )
}

pub fn new(client_id: String, client_secret: String) -> CimeApi {
  CimeApi(
    exchange_code: fn(code) { exchange_code(client_id, client_secret, code) },
    refresh_token: fn(refresh) {
      do_refresh_token(client_id, client_secret, refresh)
    },
    revoke_token: fn(token, token_type) {
      do_revoke_token(client_id, client_secret, token, token_type)
    },
    get_me: do_get_me,
    get_channels: fn(ids) { do_get_channels(client_id, client_secret, ids) },
    get_followers: do_get_followers,
    get_subscribers: do_get_subscribers,
    get_streaming_roles: do_get_streaming_roles,
    get_lives: fn(size, next) {
      do_get_lives(client_id, client_secret, size, next)
    },
    get_live_status: do_get_live_status,
    get_live_setting: do_get_live_setting,
    update_live_setting: do_update_live_setting,
    get_stream_key: do_get_stream_key,
    send_chat: do_send_chat,
    send_notice: do_send_notice,
    get_chat_settings: do_get_chat_settings,
    update_chat_settings: do_update_chat_settings,
    block_user: do_block_user,
    unblock_user: do_unblock_user,
    get_blocked_users: do_get_blocked_users,
    search_categories: fn(keyword, size) {
      do_search_categories(client_id, client_secret, keyword, size)
    },
    create_user_session: do_create_user_session,
    subscribe_event: do_subscribe_event,
    unsubscribe_event: do_unsubscribe_event,
  )
}

pub fn mock_api() -> CimeApi {
  CimeApi(
    exchange_code: fn(_) {
      Ok(types.TokenResponse(
        access_token: "mock_access",
        refresh_token: "mock_refresh",
        token_type: "Bearer",
        expires_in: "3600",
        scope: "all",
      ))
    },
    refresh_token: fn(_) {
      Ok(types.TokenResponse(
        access_token: "mock_access_refreshed",
        refresh_token: "mock_refresh",
        token_type: "Bearer",
        expires_in: "3600",
        scope: "all",
      ))
    },
    revoke_token: fn(_, _) { Ok(Nil) },
    get_me: fn(_) {
      Ok(types.UserMe(
        channel_id: "stpr_nanamori",
        channel_name: "왕!왕! 오무라이츄!",
        channel_handle: "rinu-ch",
        channel_image_url: None,
      ))
    },
    get_channels: fn(_) { Ok([]) },
    get_followers: fn(_, _, _) { Ok([]) },
    get_subscribers: fn(_, _, _) { Ok([]) },
    get_streaming_roles: fn(_) { Ok([]) },
    get_lives: fn(_, _) { Ok(#([], types.PageInfo(next: None))) },
    get_live_status: fn(_) {
      Ok(types.LiveStatus(
        is_live: True,
        title: Some("すとぷり 심야 잡담 방송"),
        opened_at: Some("2026-04-11T22:00:00Z"),
      ))
    },
    get_live_setting: fn(_) {
      Ok(
        types.LiveSetting(
          default_live_title: "すとぷり 심야 잡담 방송",
          category: Some(types.Category(
            category_id: "cat_talk",
            category_type: "TALK",
            category_value: "토크/잡담",
            poster_image_url: None,
          )),
          tags: ["すとぷり", "스토푸리", "잡담"],
        ),
      )
    },
    update_live_setting: fn(_, _) { Ok(Nil) },
    get_stream_key: fn(_) {
      Ok(types.StreamKey(stream_key: "stpr_live_20160604"))
    },
    send_chat: fn(_, _) { Ok("mock_msg_id") },
    send_notice: fn(_, _) { Ok(Nil) },
    get_chat_settings: fn(_) {
      Ok(types.ChatSettings(
        allowed_group: "ALL",
        min_follower_minutes: 0,
        subscriber_immediate_chat: True,
      ))
    },
    update_chat_settings: fn(_, _) { Ok(Nil) },
    block_user: fn(_, _) { Ok(Nil) },
    unblock_user: fn(_, _) { Ok(Nil) },
    get_blocked_users: fn(_, _, _) { Ok(#([], types.PageInfo(next: None))) },
    search_categories: fn(_, _) { Ok([]) },
    create_user_session: fn(_) {
      Ok(types.SessionResponse(url: "wss://mock/ws"))
    },
    subscribe_event: fn(_, _, _) { Ok(Nil) },
    unsubscribe_event: fn(_, _, _) { Ok(Nil) },
  )
}

// --- Private implementation functions ---

fn exchange_code(
  client_id: String,
  client_secret: String,
  code: String,
) -> Result(TokenResponse, CimeError) {
  let body =
    json.object([
      #("grantType", json.string("authorization_code")),
      #("clientId", json.string(client_id)),
      #("clientSecret", json.string(client_secret)),
      #("code", json.string(code)),
    ])
    |> json.to_string
  use raw <- result.try(http_client.post_json("/auth/v1/token", body))
  decoders.decode_content(raw, decoders.token_response_decoder())
}

fn do_refresh_token(
  client_id: String,
  client_secret: String,
  refresh: String,
) -> Result(TokenResponse, CimeError) {
  let body =
    json.object([
      #("grantType", json.string("refresh_token")),
      #("clientId", json.string(client_id)),
      #("clientSecret", json.string(client_secret)),
      #("refreshToken", json.string(refresh)),
    ])
    |> json.to_string
  use raw <- result.try(http_client.post_json("/auth/v1/token", body))
  decoders.decode_content(raw, decoders.token_response_decoder())
}

fn do_revoke_token(
  client_id: String,
  client_secret: String,
  token: String,
  token_type_hint: String,
) -> Result(Nil, CimeError) {
  let body =
    json.object([
      #("clientId", json.string(client_id)),
      #("clientSecret", json.string(client_secret)),
      #("token", json.string(token)),
      #("tokenTypeHint", json.string(token_type_hint)),
    ])
    |> json.to_string
  use _ <- result.try(http_client.post_json("/auth/v1/token/revoke", body))
  Ok(Nil)
}

fn do_get_me(token: String) -> Result(UserMe, CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer("/api/openapi/open/v1/users/me", token, []),
  )
  decoders.decode_content(raw, decoders.user_me_decoder())
}

fn do_get_channels(
  client_id: String,
  client_secret: String,
  ids: List(String),
) -> Result(List(ChannelInfo), CimeError) {
  let ids_str = string.join(ids, ",")
  use raw <- result.try(
    http_client.get_with_client_auth(
      "/api/openapi/open/v1/channels",
      client_id,
      client_secret,
      [#("channelIds", ids_str)],
    ),
  )
  decoders.decode_content_data(raw, decoders.channel_info_decoder())
}

fn do_get_followers(
  token: String,
  page: Int,
  size: Int,
) -> Result(List(Follower), CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer(
      "/api/openapi/open/v1/channels/followers",
      token,
      [#("page", int.to_string(page)), #("size", int.to_string(size))],
    ),
  )
  decoders.decode_content_data(raw, decoders.follower_decoder())
}

fn do_get_subscribers(
  token: String,
  page: Int,
  size: Int,
) -> Result(List(Subscriber), CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer(
      "/api/openapi/open/v1/channels/subscribers",
      token,
      [#("page", int.to_string(page)), #("size", int.to_string(size))],
    ),
  )
  decoders.decode_content_data(raw, decoders.subscriber_decoder())
}

fn do_get_streaming_roles(
  token: String,
) -> Result(List(StreamingRole), CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer(
      "/api/openapi/open/v1/channels/streaming-roles",
      token,
      [],
    ),
  )
  decoders.decode_content_data(raw, decoders.streaming_role_decoder())
}

fn do_get_lives(
  client_id: String,
  client_secret: String,
  size: Int,
  next: Option(String),
) -> Result(#(List(LiveInfo), PageInfo), CimeError) {
  let query = [#("size", int.to_string(size))]
  let query = case next {
    option.Some(cursor) -> [#("next", cursor), ..query]
    None -> query
  }
  use raw <- result.try(http_client.get_with_client_auth(
    "/api/openapi/open/v1/lives",
    client_id,
    client_secret,
    query,
  ))
  decoders.decode_content_data_with_page(raw, decoders.live_info_decoder())
}

fn do_get_live_status(channel_id: String) -> Result(LiveStatus, CimeError) {
  use raw <- result.try(
    http_client.get_no_auth(
      "/api/openapi/v1/" <> channel_id <> "/live-status",
      [],
    ),
  )
  decoders.decode_content(raw, decoders.live_status_decoder())
}

fn do_get_live_setting(token: String) -> Result(LiveSetting, CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer("/api/openapi/open/v1/lives/setting", token, []),
  )
  decoders.decode_content(raw, decoders.live_setting_decoder())
}

fn do_update_live_setting(token: String, body: String) -> Result(Nil, CimeError) {
  use _ <- result.try(http_client.patch_json_with_bearer(
    "/open/v1/lives/setting",
    token,
    body,
  ))
  Ok(Nil)
}

fn do_get_stream_key(token: String) -> Result(StreamKey, CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer("/api/openapi/open/v1/streams/key", token, []),
  )
  decoders.decode_content(raw, decoders.stream_key_decoder())
}

fn do_send_chat(token: String, message: String) -> Result(String, CimeError) {
  let body = json.to_string(json.object([#("message", json.string(message))]))
  use raw <- result.try(http_client.post_json_with_bearer(
    "/open/v1/chats/send",
    token,
    body,
  ))
  use resp <- result.try(decoders.decode_content(
    raw,
    decoders.chat_send_response_decoder(),
  ))
  Ok(resp.message_id)
}

fn do_send_notice(token: String, message: String) -> Result(Nil, CimeError) {
  let body = json.to_string(json.object([#("message", json.string(message))]))
  use _ <- result.try(http_client.post_json_with_bearer(
    "/open/v1/chats/notice",
    token,
    body,
  ))
  Ok(Nil)
}

fn do_get_chat_settings(token: String) -> Result(ChatSettings, CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer(
      "/api/openapi/open/v1/chats/settings",
      token,
      [],
    ),
  )
  decoders.decode_content(raw, decoders.chat_settings_decoder())
}

fn do_update_chat_settings(
  token: String,
  body: String,
) -> Result(Nil, CimeError) {
  use _ <- result.try(http_client.put_json_with_bearer(
    "/open/v1/chats/settings",
    token,
    body,
  ))
  Ok(Nil)
}

fn do_block_user(
  token: String,
  target_channel_id: String,
) -> Result(Nil, CimeError) {
  let body =
    json.to_string(
      json.object([#("targetChannelId", json.string(target_channel_id))]),
    )
  use _ <- result.try(http_client.post_json_with_bearer(
    "/open/v1/restrict-channels",
    token,
    body,
  ))
  Ok(Nil)
}

fn do_unblock_user(
  token: String,
  target_channel_id: String,
) -> Result(Nil, CimeError) {
  let body =
    json.to_string(
      json.object([#("targetChannelId", json.string(target_channel_id))]),
    )
  use _ <- result.try(http_client.delete_json_with_bearer(
    "/open/v1/restrict-channels",
    token,
    body,
  ))
  Ok(Nil)
}

fn do_get_blocked_users(
  token: String,
  size: Int,
  next: Option(String),
) -> Result(#(List(RestrictedChannel), PageInfo), CimeError) {
  let query = [#("size", int.to_string(size))]
  let query = case next {
    option.Some(cursor) -> [#("next", cursor), ..query]
    None -> query
  }
  use raw <- result.try(http_client.get_with_bearer(
    "/api/openapi/open/v1/restrict-channels",
    token,
    query,
  ))
  decoders.decode_content_data_with_page(
    raw,
    decoders.restricted_channel_decoder(),
  )
}

fn do_search_categories(
  client_id: String,
  client_secret: String,
  keyword: String,
  size: Int,
) -> Result(List(Category), CimeError) {
  let query = [#("size", int.to_string(size))]
  let query = case keyword {
    "" -> query
    k -> [#("keyword", k), ..query]
  }
  use raw <- result.try(http_client.get_with_client_auth(
    "/api/openapi/open/v1/categories/search",
    client_id,
    client_secret,
    query,
  ))
  decoders.decode_content_data(raw, decoders.category_decoder())
}

fn do_create_user_session(token: String) -> Result(SessionResponse, CimeError) {
  use raw <- result.try(
    http_client.get_with_bearer("/api/openapi/open/v1/sessions/auth", token, []),
  )
  decoders.decode_content(raw, decoders.session_response_decoder())
}

fn do_subscribe_event(
  token: String,
  session_key: String,
  event: String,
) -> Result(Nil, CimeError) {
  use _ <- result.try(
    http_client.post_with_bearer_query(
      "/open/v1/sessions/events/subscribe/" <> event,
      token,
      [#("sessionKey", session_key)],
    ),
  )
  Ok(Nil)
}

fn do_unsubscribe_event(
  token: String,
  session_key: String,
  event: String,
) -> Result(Nil, CimeError) {
  use _ <- result.try(
    http_client.post_with_bearer_query(
      "/open/v1/sessions/events/unsubscribe/" <> event,
      token,
      [#("sessionKey", session_key)],
    ),
  )
  Ok(Nil)
}
