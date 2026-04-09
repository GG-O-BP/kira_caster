import gleam/option.{type Option}

pub type CimeError {
  HttpError(reason: String)
  ApiError(status: Int, message: String)
  JsonDecodeError(reason: String)
}

pub type TokenResponse {
  TokenResponse(
    access_token: String,
    refresh_token: String,
    token_type: String,
    expires_in: String,
    scope: String,
  )
}

pub type UserMe {
  UserMe(
    channel_id: String,
    channel_name: String,
    channel_handle: String,
    channel_image_url: Option(String),
  )
}

pub type ChannelInfo {
  ChannelInfo(
    channel_id: String,
    channel_name: String,
    channel_handle: String,
    channel_image_url: Option(String),
    channel_description: String,
    follower_count: Int,
  )
}

pub type Follower {
  Follower(
    channel_id: String,
    channel_name: String,
    channel_handle: String,
    created_date: String,
  )
}

pub type Subscriber {
  Subscriber(
    channel_id: String,
    channel_name: String,
    channel_handle: String,
    month: Int,
    tier_no: Int,
    created_date: String,
  )
}

pub type StreamingRole {
  StreamingRole(
    manager_channel_id: String,
    manager_channel_name: String,
    manager_channel_handle: String,
    user_role: String,
    created_date: String,
  )
}

pub type LiveInfo {
  LiveInfo(
    live_id: String,
    live_title: String,
    live_thumbnail_image_url: Option(String),
    concurrent_user_count: Int,
    opened_date: Option(String),
    adult: Bool,
    tags: List(String),
    category_type: Option(String),
    live_category: Option(String),
    live_category_value: Option(String),
    channel_id: String,
    channel_name: String,
    channel_handle: String,
    channel_image_url: Option(String),
  )
}

pub type LiveSetting {
  LiveSetting(
    default_live_title: String,
    category: Option(Category),
    tags: List(String),
  )
}

pub type LiveStatus {
  LiveStatus(is_live: Bool, title: Option(String), opened_at: Option(String))
}

pub type StreamKey {
  StreamKey(stream_key: String)
}

pub type ChatSettings {
  ChatSettings(
    allowed_group: String,
    min_follower_minutes: Int,
    subscriber_immediate_chat: Bool,
  )
}

pub type Category {
  Category(
    category_id: String,
    category_type: String,
    category_value: String,
    poster_image_url: Option(String),
  )
}

pub type RestrictedChannel {
  RestrictedChannel(
    restricted_channel_id: String,
    name: String,
    handle: String,
    block_date: String,
    release_date: Option(String),
  )
}

pub type SessionResponse {
  SessionResponse(url: String)
}

pub type ChatSendResponse {
  ChatSendResponse(message_id: String)
}

pub type TokenStatus {
  TokenStatus(authenticated: Bool, expires_at: Int, scopes: String)
}

pub type PageInfo {
  PageInfo(next: Option(String))
}
