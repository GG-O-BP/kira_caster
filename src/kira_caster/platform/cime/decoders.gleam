import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/string
import kira_caster/platform/cime/types.{
  type Category, type ChannelInfo, type ChatSendResponse, type ChatSettings,
  type CimeError, type Follower, type LiveInfo, type LiveSetting,
  type LiveStatus, type PageInfo, type RestrictedChannel, type SessionResponse,
  type StreamKey, type StreamingRole, type Subscriber, type TokenResponse,
  type UserMe, Category, ChannelInfo, ChatSendResponse, ChatSettings, Follower,
  JsonDecodeError, LiveInfo, LiveSetting, LiveStatus, PageInfo,
  RestrictedChannel, SessionResponse, StreamKey, StreamingRole, Subscriber,
  TokenResponse, UserMe,
}

pub fn decode_content(
  json_string: String,
  content_decoder: Decoder(a),
) -> Result(a, CimeError) {
  let envelope_decoder =
    decode.field("content", content_decoder, fn(content) {
      decode.success(content)
    })
  json.parse(json_string, envelope_decoder)
  |> map_decode_error
}

pub fn decode_content_data(
  json_string: String,
  item_decoder: Decoder(a),
) -> Result(List(a), CimeError) {
  let decoder =
    decode.field(
      "content",
      decode.field("data", decode.list(item_decoder), fn(data) {
        decode.success(data)
      }),
      fn(data) { decode.success(data) },
    )
  json.parse(json_string, decoder)
  |> map_decode_error
}

pub fn decode_content_data_with_page(
  json_string: String,
  item_decoder: Decoder(a),
) -> Result(#(List(a), PageInfo), CimeError) {
  let decoder =
    decode.field(
      "content",
      {
        use data <- decode.field("data", decode.list(item_decoder))
        use next <- decode.field(
          "page",
          decode.field("next", decode.optional(decode.string), fn(n) {
            decode.success(n)
          }),
        )
        decode.success(#(data, PageInfo(next:)))
      },
      fn(result) { decode.success(result) },
    )
  json.parse(json_string, decoder)
  |> map_decode_error
}

pub fn token_response_decoder() -> Decoder(TokenResponse) {
  use access_token <- decode.field("accessToken", decode.string)
  use refresh_token <- decode.field("refreshToken", decode.string)
  use token_type <- decode.field("tokenType", decode.string)
  use expires_in <- decode.field("expiresIn", decode.string)
  use scope <- decode.field("scope", decode.string)
  decode.success(TokenResponse(
    access_token:,
    refresh_token:,
    token_type:,
    expires_in:,
    scope:,
  ))
}

pub fn user_me_decoder() -> Decoder(UserMe) {
  use channel_id <- decode.field("channelId", decode.string)
  use channel_name <- decode.field("channelName", decode.string)
  use channel_handle <- decode.field("channelHandle", decode.string)
  use channel_image_url <- decode.field(
    "channelImageUrl",
    decode.optional(decode.string),
  )
  decode.success(UserMe(
    channel_id:,
    channel_name:,
    channel_handle:,
    channel_image_url:,
  ))
}

pub fn channel_info_decoder() -> Decoder(ChannelInfo) {
  use channel_id <- decode.field("channelId", decode.string)
  use channel_name <- decode.field("channelName", decode.string)
  use channel_handle <- decode.field("channelHandle", decode.string)
  use channel_image_url <- decode.field(
    "channelImageUrl",
    decode.optional(decode.string),
  )
  use channel_description <- decode.field("channelDescription", decode.string)
  use follower_count <- decode.field("followerCount", decode.int)
  decode.success(ChannelInfo(
    channel_id:,
    channel_name:,
    channel_handle:,
    channel_image_url:,
    channel_description:,
    follower_count:,
  ))
}

pub fn follower_decoder() -> Decoder(Follower) {
  use channel_id <- decode.field("channelId", decode.string)
  use channel_name <- decode.field("channelName", decode.string)
  use channel_handle <- decode.field("channelHandle", decode.string)
  use created_date <- decode.field("createdDate", decode.string)
  decode.success(Follower(
    channel_id:,
    channel_name:,
    channel_handle:,
    created_date:,
  ))
}

pub fn subscriber_decoder() -> Decoder(Subscriber) {
  use channel_id <- decode.field("channelId", decode.string)
  use channel_name <- decode.field("channelName", decode.string)
  use channel_handle <- decode.field("channelHandle", decode.string)
  use month <- decode.field("month", decode.int)
  use tier_no <- decode.field("tierNo", decode.int)
  use created_date <- decode.field("createdDate", decode.string)
  decode.success(Subscriber(
    channel_id:,
    channel_name:,
    channel_handle:,
    month:,
    tier_no:,
    created_date:,
  ))
}

pub fn streaming_role_decoder() -> Decoder(StreamingRole) {
  use manager_channel_id <- decode.field("managerChannelId", decode.string)
  use manager_channel_name <- decode.field("managerChannelName", decode.string)
  use manager_channel_handle <- decode.field(
    "managerChannelHandle",
    decode.string,
  )
  use user_role <- decode.field("userRole", decode.string)
  use created_date <- decode.field("createdDate", decode.string)
  decode.success(StreamingRole(
    manager_channel_id:,
    manager_channel_name:,
    manager_channel_handle:,
    user_role:,
    created_date:,
  ))
}

pub fn live_info_decoder() -> Decoder(LiveInfo) {
  use live_id <- decode.field("liveId", decode.string)
  use live_title <- decode.field("liveTitle", decode.string)
  use live_thumbnail_image_url <- decode.field(
    "liveThumbnailImageUrl",
    decode.optional(decode.string),
  )
  use concurrent_user_count <- decode.field("concurrentUserCount", decode.int)
  use opened_date <- decode.field("openedDate", decode.optional(decode.string))
  use adult <- decode.field("adult", decode.bool)
  use tags <- decode.field("tags", decode.list(decode.string))
  use category_type <- decode.field(
    "categoryType",
    decode.optional(decode.string),
  )
  use live_category <- decode.field(
    "liveCategory",
    decode.optional(decode.string),
  )
  use live_category_value <- decode.field(
    "liveCategoryValue",
    decode.optional(decode.string),
  )
  use channel_id <- decode.field("channelId", decode.string)
  use channel_name <- decode.field("channelName", decode.string)
  use channel_handle <- decode.field("channelHandle", decode.string)
  use channel_image_url <- decode.field(
    "channelImageUrl",
    decode.optional(decode.string),
  )
  decode.success(LiveInfo(
    live_id:,
    live_title:,
    live_thumbnail_image_url:,
    concurrent_user_count:,
    opened_date:,
    adult:,
    tags:,
    category_type:,
    live_category:,
    live_category_value:,
    channel_id:,
    channel_name:,
    channel_handle:,
    channel_image_url:,
  ))
}

pub fn live_setting_decoder() -> Decoder(LiveSetting) {
  use default_live_title <- decode.field("defaultLiveTitle", decode.string)
  use category <- decode.field("category", decode.optional(category_decoder()))
  use tags <- decode.field("tags", decode.list(decode.string))
  decode.success(LiveSetting(default_live_title:, category:, tags:))
}

pub fn live_status_decoder() -> Decoder(LiveStatus) {
  use is_live <- decode.field("isLive", decode.bool)
  use title <- decode.field("title", decode.optional(decode.string))
  use opened_at <- decode.field("openedAt", decode.optional(decode.string))
  decode.success(LiveStatus(is_live:, title:, opened_at:))
}

pub fn stream_key_decoder() -> Decoder(StreamKey) {
  use stream_key <- decode.field("streamKey", decode.string)
  decode.success(StreamKey(stream_key:))
}

pub fn chat_settings_decoder() -> Decoder(ChatSettings) {
  use allowed_group <- decode.field("allowedGroup", decode.string)
  use min_follower_minutes <- decode.field("minFollowerMinutes", decode.int)
  use subscriber_immediate_chat <- decode.field(
    "subscriberImmediateChat",
    decode.bool,
  )
  decode.success(ChatSettings(
    allowed_group:,
    min_follower_minutes:,
    subscriber_immediate_chat:,
  ))
}

pub fn category_decoder() -> Decoder(Category) {
  use category_id <- decode.field("categoryId", decode.string)
  use category_type <- decode.field("categoryType", decode.string)
  use category_value <- decode.field("categoryValue", decode.string)
  use poster_image_url <- decode.field(
    "posterImageUrl",
    decode.optional(decode.string),
  )
  decode.success(Category(
    category_id:,
    category_type:,
    category_value:,
    poster_image_url:,
  ))
}

pub fn restricted_channel_decoder() -> Decoder(RestrictedChannel) {
  use restricted_channel_id <- decode.field(
    "restrictedChannelId",
    decode.string,
  )
  use name <- decode.field("name", decode.string)
  use handle <- decode.field("handle", decode.string)
  use block_date <- decode.field("blockDate", decode.string)
  use release_date <- decode.field(
    "releaseDate",
    decode.optional(decode.string),
  )
  decode.success(RestrictedChannel(
    restricted_channel_id:,
    name:,
    handle:,
    block_date:,
    release_date:,
  ))
}

pub fn session_response_decoder() -> Decoder(SessionResponse) {
  use url <- decode.field("url", decode.string)
  decode.success(SessionResponse(url:))
}

pub fn chat_send_response_decoder() -> Decoder(ChatSendResponse) {
  use message_id <- decode.field("messageId", decode.string)
  decode.success(ChatSendResponse(message_id:))
}

fn map_decode_error(result: Result(a, json.DecodeError)) -> Result(a, CimeError) {
  case result {
    Ok(value) -> Ok(value)
    Error(e) -> Error(JsonDecodeError(string.inspect(e)))
  }
}
