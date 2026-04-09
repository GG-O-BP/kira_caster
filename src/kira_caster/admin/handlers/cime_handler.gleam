import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import kira_caster/platform/cime/api.{type CimeApi}
import wisp.{type Request, type Response}

pub fn handle_live_status(
  _req: Request,
  api: Option(CimeApi),
  channel_id: String,
) -> Response {
  case api {
    None -> service_unavailable()
    Some(a) -> {
      case a.get_live_status(channel_id) {
        Ok(status) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("isLive", json.bool(status.is_live)),
                #("title", case status.title {
                  Some(t) -> json.string(t)
                  None -> json.null()
                }),
                #("openedAt", case status.opened_at {
                  Some(t) -> json.string(t)
                  None -> json.null()
                }),
              ]),
            ),
            200,
          )
        Error(_) -> api_error("방송 상태 조회 실패")
      }
    }
  }
}

pub fn handle_live_setting(
  _req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      case gt() {
        Ok(token) ->
          case a.get_live_setting(token) {
            Ok(setting) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #(
                      "defaultLiveTitle",
                      json.string(setting.default_live_title),
                    ),
                    #("tags", json.array(setting.tags, json.string)),
                    #("category", case setting.category {
                      Some(cat) ->
                        json.object([
                          #("categoryId", json.string(cat.category_id)),
                          #("categoryValue", json.string(cat.category_value)),
                        ])
                      None -> json.null()
                    }),
                  ]),
                ),
                200,
              )
            Error(_) -> api_error("방송 설정 조회 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_update_live_setting(
  req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      use body <- wisp.require_json(req)
      case gt() {
        Ok(token) ->
          case a.update_live_setting(token, string.inspect(body)) {
            Ok(Nil) -> ok_response("방송 설정 변경 완료")
            Error(_) -> api_error("방송 설정 변경 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_chat_settings(
  _req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      case gt() {
        Ok(token) ->
          case a.get_chat_settings(token) {
            Ok(settings) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("allowedGroup", json.string(settings.allowed_group)),
                    #(
                      "minFollowerMinutes",
                      json.int(settings.min_follower_minutes),
                    ),
                    #(
                      "subscriberImmediateChat",
                      json.bool(settings.subscriber_immediate_chat),
                    ),
                  ]),
                ),
                200,
              )
            Error(_) -> api_error("채팅 설정 조회 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_update_chat_settings(
  req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      use body <- wisp.require_json(req)
      case gt() {
        Ok(token) ->
          case a.update_chat_settings(token, string.inspect(body)) {
            Ok(Nil) -> ok_response("채팅 설정 변경 완료")
            Error(_) -> api_error("채팅 설정 변경 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_blocked_users(
  _req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      case gt() {
        Ok(token) ->
          case a.get_blocked_users(token, 50, None) {
            Ok(#(users, _page)) ->
              wisp.json_response(
                json.to_string(
                  json.array(users, fn(u) {
                    json.object([
                      #("channelId", json.string(u.restricted_channel_id)),
                      #("name", json.string(u.name)),
                      #("handle", json.string(u.handle)),
                      #("blockDate", json.string(u.block_date)),
                    ])
                  }),
                ),
                200,
              )
            Error(_) -> api_error("차단 목록 조회 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_block_user(
  req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      use json_body <- wisp.require_json(req)
      let target =
        json.parse(
          string.inspect(json_body),
          decode.field("targetChannelId", decode.string, fn(id) {
            decode.success(id)
          }),
        )
      case target, gt() {
        Ok(channel_id), Ok(token) ->
          case a.block_user(token, channel_id) {
            Ok(Nil) -> ok_response("차단 완료")
            Error(_) -> api_error("차단 실패")
          }
        _, _ -> api_error("요청 처리 실패")
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_unblock_user(
  req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      use json_body <- wisp.require_json(req)
      let target =
        json.parse(
          string.inspect(json_body),
          decode.field("targetChannelId", decode.string, fn(id) {
            decode.success(id)
          }),
        )
      case target, gt() {
        Ok(channel_id), Ok(token) ->
          case a.unblock_user(token, channel_id) {
            Ok(Nil) -> ok_response("차단 해제 완료")
            Error(_) -> api_error("차단 해제 실패")
          }
        _, _ -> api_error("요청 처리 실패")
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_channel_info(
  _req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      case gt() {
        Ok(token) ->
          case a.get_me(token) {
            Ok(me) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("channelId", json.string(me.channel_id)),
                    #("channelName", json.string(me.channel_name)),
                    #("channelHandle", json.string(me.channel_handle)),
                    #("channelImageUrl", case me.channel_image_url {
                      Some(url) -> json.string(url)
                      None -> json.null()
                    }),
                  ]),
                ),
                200,
              )
            Error(_) -> api_error("채널 정보 조회 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_stream_key(
  _req: Request,
  api: Option(CimeApi),
  get_token: Option(fn() -> Result(String, String)),
) -> Response {
  case api, get_token {
    Some(a), Some(gt) -> {
      case gt() {
        Ok(token) ->
          case a.get_stream_key(token) {
            Ok(key) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("streamKey", json.string(key.stream_key)),
                  ]),
                ),
                200,
              )
            Error(_) -> api_error("스트림 키 조회 실패")
          }
        Error(e) -> api_error(e)
      }
    }
    _, _ -> service_unavailable()
  }
}

pub fn handle_categories(req: Request, api: Option(CimeApi)) -> Response {
  case api {
    Some(a) -> {
      let keyword =
        wisp.get_query(req)
        |> list.find(fn(p) { p.0 == "keyword" })
        |> option.from_result
        |> option.map(fn(p) { p.1 })
        |> option.unwrap("")
      case a.search_categories(keyword, 20) {
        Ok(cats) ->
          wisp.json_response(
            json.to_string(
              json.array(cats, fn(c) {
                json.object([
                  #("categoryId", json.string(c.category_id)),
                  #("categoryType", json.string(c.category_type)),
                  #("categoryValue", json.string(c.category_value)),
                  #("posterImageUrl", case c.poster_image_url {
                    Some(url) -> json.string(url)
                    None -> json.null()
                  }),
                ])
              }),
            ),
            200,
          )
        Error(_) -> api_error("카테고리 검색 실패")
      }
    }
    None -> service_unavailable()
  }
}

fn ok_response(message: String) -> Response {
  wisp.json_response(
    json.to_string(
      json.object([
        #("status", json.string("ok")),
        #("message", json.string(message)),
      ]),
    ),
    200,
  )
}

fn api_error(message: String) -> Response {
  wisp.json_response(
    json.to_string(
      json.object([
        #("status", json.string("error")),
        #("message", json.string(message)),
      ]),
    ),
    500,
  )
}

fn service_unavailable() -> Response {
  wisp.json_response(
    json.to_string(
      json.object([
        #("status", json.string("error")),
        #("message", json.string("씨미 연동이 설정되지 않았습니다")),
      ]),
    ),
    503,
  )
}
