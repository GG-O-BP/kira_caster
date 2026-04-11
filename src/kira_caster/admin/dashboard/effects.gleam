import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import kira_caster/admin/dashboard/model.{
  type DashboardContext, type Msg, type Tab,
}
import kira_caster/event_bus
import kira_caster/platform/cime/ws_manager
import kira_caster/platform/ws
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time
import lustre/effect.{type Effect}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn async(f: fn(fn(Msg) -> Nil) -> Nil) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = process.spawn(fn() { f(dispatch) })
    Nil
  })
}

fn crud(
  op: fn() -> Result(a, b),
  success_msg: String,
  error_msg: String,
) -> Effect(Msg) {
  async(fn(dispatch) {
    case op() {
      Ok(_) -> {
        dispatch(model.ShowToast(success_msg, model.SuccessToast))
        dispatch(model.OpDone(Ok(Nil)))
      }
      Error(_) -> dispatch(model.ShowToast(error_msg, model.ErrorToast))
    }
  })
}

// ---------------------------------------------------------------------------
// Timers
// ---------------------------------------------------------------------------

pub fn schedule_refresh() -> Effect(Msg) {
  async(fn(dispatch) {
    process.sleep(5000)
    dispatch(model.RefreshTick)
  })
}

pub fn dismiss_toast_after(id: Int) -> Effect(Msg) {
  async(fn(dispatch) {
    process.sleep(3000)
    dispatch(model.DismissToast(id))
  })
}

// ---------------------------------------------------------------------------
// Tab loader (dispatch)
// ---------------------------------------------------------------------------

pub fn load_tab(tab: Tab, ctx: DashboardContext) -> Effect(Msg) {
  case tab {
    model.Status -> load_status(ctx.start_time, ctx)
    model.Users -> load_users(ctx.repo)
    model.Words -> load_words(ctx.repo)
    model.Commands -> load_commands(ctx.repo)
    model.Quizzes -> load_quizzes(ctx.repo)
    model.Votes -> load_votes(ctx.repo)
    model.Plugins -> load_plugins(ctx.repo)
    model.Settings -> load_settings(ctx.repo)
    model.Songs -> load_songs(ctx.repo)
    model.CimeAuth -> load_auth_status(ctx)
    model.Broadcast -> load_broadcast(ctx)
    model.ChatSettings -> load_chat_settings(ctx)
    model.BlockManage -> load_blocked_users(ctx)
    model.ChannelInfo -> load_channel_info(ctx)
  }
}

// ---------------------------------------------------------------------------
// Tab loaders (private)
// ---------------------------------------------------------------------------

fn load_status(start_time: Int, ctx: DashboardContext) -> Effect(Msg) {
  async(fn(dispatch) {
    let uptime = { time.now_ms() - start_time } / 1000
    dispatch(model.StatusLoaded(uptime))

    // Also load connection status if ws_manager is available
    case ctx.ws_manager {
      Some(ws_mgr) -> {
        let status = ws_manager.get_connection_status(ws_mgr)
        let state = case status.state {
          ws.Connected -> model.CsConnected
          ws.Disconnected -> model.CsDisconnected
          ws.Reconnecting(n) -> model.CsReconnecting(n, status.max_reconnect)
        }
        dispatch(model.ConnectionStateLoaded(state))
      }
      None -> Nil
    }
  })
}

fn load_users(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_all_users() {
      Ok(users) -> dispatch(model.UsersLoaded(users))
      Error(_) -> Nil
    }
  })
}

fn load_words(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_banned_words() {
      Ok(words) -> dispatch(model.WordsLoaded(words))
      Error(_) -> Nil
    }
  })
}

fn load_commands(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_all_commands_detailed() {
      Ok(cmds) -> dispatch(model.CommandsLoaded(cmds))
      Error(_) -> Nil
    }
  })
}

fn load_quizzes(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_all_quizzes() {
      Ok(q) -> dispatch(model.QuizzesLoaded(q))
      Error(_) -> Nil
    }
  })
}

fn load_votes(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_active_vote() {
      Ok(#(topic, _options)) ->
        case repo.get_vote_results() {
          Ok(results) ->
            dispatch(model.VoteLoaded(
              True,
              topic,
              list.map(results, fn(r) { model.VoteResult(r.0, r.1) }),
            ))
          Error(_) -> dispatch(model.VoteLoaded(True, topic, []))
        }
      Error(_) -> dispatch(model.VoteLoaded(False, "", []))
    }
  })
}

fn load_plugins(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    let all_plugins = [
      #("attendance", "출석 체크"),
      #("points", "포인트 조회"),
      #("minigame", "미니게임"),
      #("filter", "채팅 필터"),
      #("custom_command", "커스텀 명령어"),
      #("uptime", "가동 시간"),
      #("vote", "투표"),
      #("roulette", "룰렛"),
      #("quiz", "퀴즈"),
      #("timer", "타이머"),
      #("song_request", "신청곡"),
      #("donation_alert", "후원 알림"),
      #("subscription_alert", "구독 알림"),
      #("broadcast_control", "방송 제어"),
      #("block", "차단 관리"),
      #("follower", "팔로워 추적"),
    ]
    case repo.get_disabled_plugins() {
      Ok(disabled) -> {
        let plugins =
          list.map(all_plugins, fn(p) {
            let enabled = !list.contains(disabled, p.0)
            model.PluginInfo(name: p.0, description: p.1, enabled: enabled)
          })
        dispatch(model.PluginsLoaded(plugins))
      }
      Error(_) -> Nil
    }
  })
}

fn load_settings(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_all_settings() {
      Ok(s) -> dispatch(model.SettingsLoaded(s))
      Error(_) -> Nil
    }
  })
}

fn load_songs(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_song_queue() {
      Ok(songs) -> {
        let current = case repo.get_setting("song_current_id") {
          Ok(id_str) ->
            case int.parse(id_str) {
              Ok(id) ->
                list.find(songs, fn(s) { s.id == id }) |> option.from_result
              Error(_) -> None
            }
          Error(_) -> None
        }
        let version = case repo.get_setting("song_current_version") {
          Ok(v) -> v
          Error(_) -> "0"
        }
        dispatch(model.SongsLoaded(songs, current, version))
      }
      Error(_) -> Nil
    }
  })
}

fn load_auth_status(_ctx: DashboardContext) -> Effect(Msg) {
  async(fn(dispatch) { dispatch(model.AuthStatusLoaded(False, "", "")) })
}

fn load_broadcast(ctx: DashboardContext) -> Effect(Msg) {
  case ctx.cime_api, ctx.get_token {
    Some(api), Some(get_tok) ->
      async(fn(dispatch) {
        case get_tok() {
          Ok(token) ->
            case api.get_live_setting(token) {
              Ok(s) -> {
                let cat_name = case s.category {
                  Some(c) -> c.category_value
                  None -> ""
                }
                dispatch(model.BroadcastLoaded(
                  s.default_live_title,
                  s.tags,
                  cat_name,
                ))
              }
              Error(_) -> dispatch(model.BroadcastLoaded("", [], ""))
            }
          Error(_) -> dispatch(model.BroadcastLoaded("", [], ""))
        }
      })
    _, _ -> async(fn(dispatch) { dispatch(model.BroadcastLoaded("", [], "")) })
  }
}

fn load_chat_settings(ctx: DashboardContext) -> Effect(Msg) {
  case ctx.cime_api, ctx.get_token {
    Some(api), Some(get_tok) ->
      async(fn(dispatch) {
        case get_tok() {
          Ok(token) ->
            case api.get_chat_settings(token) {
              Ok(s) -> {
                let slow_mode = s.allowed_group != "ALL"
                let follower = s.allowed_group == "FOLLOWER"
                dispatch(model.ChatSettingsLoaded(
                  slow_mode,
                  s.min_follower_minutes,
                  follower,
                ))
              }
              Error(_) -> dispatch(model.ChatSettingsLoaded(False, 0, False))
            }
          Error(_) -> dispatch(model.ChatSettingsLoaded(False, 0, False))
        }
      })
    _, _ ->
      async(fn(dispatch) { dispatch(model.ChatSettingsLoaded(False, 0, False)) })
  }
}

fn load_blocked_users(ctx: DashboardContext) -> Effect(Msg) {
  case ctx.cime_api, ctx.get_token {
    Some(api), Some(get_tok) ->
      async(fn(dispatch) {
        case get_tok() {
          Ok(token) ->
            case api.get_blocked_users(token, 100, None) {
              Ok(#(users, _page)) ->
                dispatch(
                  model.BlockedUsersLoaded(
                    list.map(users, fn(u) {
                      #(u.restricted_channel_id, u.name, u.block_date)
                    }),
                  ),
                )
              Error(_) -> dispatch(model.BlockedUsersLoaded([]))
            }
          Error(_) -> dispatch(model.BlockedUsersLoaded([]))
        }
      })
    _, _ -> async(fn(dispatch) { dispatch(model.BlockedUsersLoaded([])) })
  }
}

fn load_channel_info(ctx: DashboardContext) -> Effect(Msg) {
  effect.batch([load_bot_info(ctx), load_live_status(ctx), load_stream_key(ctx)])
}

fn load_bot_info(ctx: DashboardContext) -> Effect(Msg) {
  case ctx.cime_api, ctx.get_token {
    Some(api), Some(get_tok) ->
      async(fn(dispatch) {
        case get_tok() {
          Ok(token) ->
            case api.get_me(token) {
              Ok(me) ->
                dispatch(model.ChannelInfoLoaded(
                  me.channel_name,
                  me.channel_handle,
                  option.unwrap(me.channel_image_url, ""),
                ))
              Error(_) -> Nil
            }
          Error(_) -> Nil
        }
      })
    _, _ -> effect.none()
  }
}

fn load_live_status(ctx: DashboardContext) -> Effect(Msg) {
  case ctx.cime_api, ctx.get_token {
    Some(api), Some(get_tok) ->
      async(fn(dispatch) {
        case get_tok() {
          Ok(token) -> {
            let channel_id = ctx.config.cime_channel_id
            // get_live_status uses channel_id, not token, but we verify auth first
            let _ = token
            case api.get_live_status(channel_id) {
              Ok(s) ->
                dispatch(model.LiveStatusLoaded(
                  s.is_live,
                  option.unwrap(s.title, ""),
                  0,
                ))
              Error(_) -> Nil
            }
          }
          Error(_) -> Nil
        }
      })
    _, _ -> effect.none()
  }
}

fn load_stream_key(ctx: DashboardContext) -> Effect(Msg) {
  case ctx.cime_api, ctx.get_token {
    Some(api), Some(get_tok) ->
      async(fn(dispatch) {
        case get_tok() {
          Ok(token) ->
            case api.get_stream_key(token) {
              Ok(sk) -> dispatch(model.StreamKeyLoaded(sk.stream_key))
              Error(_) -> Nil
            }
          Error(_) -> Nil
        }
      })
    _, _ -> effect.none()
  }
}

// ---------------------------------------------------------------------------
// CRUD operations (public)
// ---------------------------------------------------------------------------

pub fn add_word(repo: Repository, word: String) -> Effect(Msg) {
  crud(
    fn() { repo.add_banned_word(string.lowercase(word)) },
    "단어 추가 완료",
    "단어 추가에 실패했습니다. 이미 등록된 단어일 수 있습니다",
  )
}

pub fn delete_word(repo: Repository, word: String) -> Effect(Msg) {
  crud(
    fn() { repo.remove_banned_word(word) },
    "단어 삭제 완료",
    "단어 삭제에 실패했습니다. 이미 삭제된 단어일 수 있습니다",
  )
}

pub fn add_command(
  repo: Repository,
  name: String,
  response: String,
) -> Effect(Msg) {
  crud(
    fn() { repo.set_command(name, response) },
    "명령어 추가 완료",
    "명령어 저장에 실패했습니다. 데이터베이스 오류가 발생했습니다",
  )
}

pub fn delete_command(repo: Repository, name: String) -> Effect(Msg) {
  crud(
    fn() { repo.delete_command(name) },
    "명령어 삭제 완료",
    "명령어 삭제에 실패했습니다. 이미 삭제된 명령어일 수 있습니다",
  )
}

pub fn add_advanced_command(
  repo: Repository,
  name: String,
  source: String,
) -> Effect(Msg) {
  crud(
    fn() { repo.set_advanced_command(name, source, "컴파일 오류") },
    "고급 명령어 추가 완료",
    "고급 명령어 저장에 실패했습니다. 소스 코드를 확인해주세요",
  )
}

pub fn add_quiz(
  repo: Repository,
  question: String,
  answer: String,
  reward: Int,
) -> Effect(Msg) {
  crud(
    fn() { repo.add_quiz(question, answer, reward) },
    "퀴즈 추가 완료",
    "퀴즈 추가에 실패했습니다. 같은 문제가 이미 등록되어 있을 수 있습니다",
  )
}

pub fn delete_quiz(repo: Repository, question: String) -> Effect(Msg) {
  crud(fn() { repo.delete_quiz(question) }, "퀴즈 삭제 완료", "퀴즈 삭제에 실패했습니다")
}

pub fn start_vote(
  repo: Repository,
  topic: String,
  options: List(String),
) -> Effect(Msg) {
  crud(
    fn() { repo.start_vote(topic, options) },
    "투표 시작 완료",
    "투표 시작에 실패했습니다. 이미 진행 중인 투표가 있을 수 있습니다",
  )
}

pub fn end_vote(repo: Repository) -> Effect(Msg) {
  crud(
    fn() { repo.end_vote() },
    "투표 종료 완료",
    "투표 종료에 실패했습니다. 진행 중인 투표가 없을 수 있습니다",
  )
}

pub fn toggle_plugin(
  repo: Repository,
  name: String,
  enabled: Bool,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Effect(Msg) {
  let label = case enabled {
    True -> "활성화"
    False -> "비활성화"
  }
  async(fn(dispatch) {
    case repo.set_plugin_enabled(name, enabled) {
      Ok(_) -> {
        case bus {
          Some(b) ->
            case repo.get_disabled_plugins() {
              Ok(disabled) -> event_bus.set_disabled_plugins(b, disabled)
              Error(_) -> Nil
            }
          None -> Nil
        }
        dispatch(model.ShowToast("플러그인 " <> label <> " 완료", model.SuccessToast))
        dispatch(model.OpDone(Ok(Nil)))
      }
      Error(_) ->
        dispatch(model.ShowToast("플러그인 상태 변경에 실패했습니다", model.ErrorToast))
    }
  })
}

pub fn save_setting(
  repo: Repository,
  key: String,
  value: String,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.set_setting(key, value) {
      Ok(_) -> {
        case key == "cooldown_ms", bus {
          True, Some(b) ->
            case int.parse(value) {
              Ok(ms) -> event_bus.set_cooldown(b, ms)
              Error(_) -> Nil
            }
          _, _ -> Nil
        }
        dispatch(model.ShowToast("설정 저장 완료", model.SuccessToast))
        dispatch(model.OpDone(Ok(Nil)))
      }
      Error(_) ->
        dispatch(model.ShowToast("설정 저장에 실패했습니다. 값을 확인해주세요", model.ErrorToast))
    }
  })
}

@external(erlang, "kira_caster_ffi", "restart_application")
fn do_restart() -> Nil

pub fn restart_app() -> Effect(Msg) {
  async(fn(dispatch) {
    dispatch(model.ShowToast("재시작 중... 잠시 후 페이지가 새로고침됩니다", model.SuccessToast))
    do_restart()
  })
}

pub fn delete_song(repo: Repository, id: Int) -> Effect(Msg) {
  crud(fn() { repo.remove_song(id) }, "곡 삭제 완료", "곡 삭제에 실패했습니다")
}

pub fn song_next(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_setting("song_current_id") {
      Ok(id_str) ->
        case int.parse(id_str) {
          Ok(current_id) ->
            case repo.get_song_queue() {
              Ok(songs) -> {
                // 현재 곡의 position 찾기
                let current_pos = list.find(songs, fn(s) { s.id == current_id })
                case current_pos {
                  Ok(current) -> {
                    // 다음 position의 곡 찾기
                    let next =
                      list.find(songs, fn(s) { s.position > current.position })
                    case next {
                      Ok(n) -> {
                        let _ =
                          repo.set_setting(
                            "song_current_id",
                            int.to_string(n.id),
                          )
                        // version 업데이트
                        let ver = case
                          repo.get_setting("song_current_version")
                        {
                          Ok(v) ->
                            case int.parse(v) {
                              Ok(vi) -> vi + 1
                              Error(_) -> 1
                            }
                          Error(_) -> 1
                        }
                        let _ =
                          repo.set_setting(
                            "song_current_version",
                            int.to_string(ver),
                          )
                        dispatch(model.OpDone(Ok(Nil)))
                      }
                      // 마지막 곡이면 무시
                      Error(_) -> dispatch(model.OpDone(Ok(Nil)))
                    }
                  }
                  Error(_) -> dispatch(model.OpDone(Ok(Nil)))
                }
              }
              Error(_) ->
                dispatch(model.ShowToast("곡 목록을 불러올 수 없습니다", model.ErrorToast))
            }
          Error(_) -> dispatch(model.OpDone(Ok(Nil)))
        }
      Error(_) -> dispatch(model.OpDone(Ok(Nil)))
    }
  })
}

pub fn song_prev(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    case repo.get_setting("song_current_id") {
      Ok(id_str) ->
        case int.parse(id_str) {
          Ok(current_id) ->
            case repo.get_song_queue() {
              Ok(songs) -> {
                let current_pos = list.find(songs, fn(s) { s.id == current_id })
                case current_pos {
                  Ok(current) -> {
                    // 이전 position의 곡 찾기 (position이 작은 것 중 가장 큰 것)
                    let prev =
                      songs
                      |> list.filter(fn(s) { s.position < current.position })
                      |> list.sort(fn(a, b) {
                        int.compare(b.position, a.position)
                      })
                      |> list.first
                    case prev {
                      Ok(p) -> {
                        let _ =
                          repo.set_setting(
                            "song_current_id",
                            int.to_string(p.id),
                          )
                        let ver = case
                          repo.get_setting("song_current_version")
                        {
                          Ok(v) ->
                            case int.parse(v) {
                              Ok(vi) -> vi + 1
                              Error(_) -> 1
                            }
                          Error(_) -> 1
                        }
                        let _ =
                          repo.set_setting(
                            "song_current_version",
                            int.to_string(ver),
                          )
                        dispatch(model.OpDone(Ok(Nil)))
                      }
                      // 첫 곡이면 무시
                      Error(_) -> dispatch(model.OpDone(Ok(Nil)))
                    }
                  }
                  Error(_) -> dispatch(model.OpDone(Ok(Nil)))
                }
              }
              Error(_) ->
                dispatch(model.ShowToast("곡 목록을 불러올 수 없습니다", model.ErrorToast))
            }
          Error(_) -> dispatch(model.OpDone(Ok(Nil)))
        }
      Error(_) -> dispatch(model.OpDone(Ok(Nil)))
    }
  })
}

pub fn song_replay(repo: Repository) -> Effect(Msg) {
  async(fn(dispatch) {
    let ver = case repo.get_setting("song_current_version") {
      Ok(v) ->
        case int.parse(v) {
          Ok(vi) -> vi + 1
          Error(_) -> 1
        }
      Error(_) -> 1
    }
    case repo.set_setting("song_current_version", int.to_string(ver)) {
      Ok(_) -> dispatch(model.OpDone(Ok(Nil)))
      Error(_) ->
        dispatch(model.ShowToast("곡 재생 상태를 저장할 수 없습니다", model.ErrorToast))
    }
  })
}

pub fn reorder_song(repo: Repository, id: Int, new_pos: Int) -> Effect(Msg) {
  crud(fn() { repo.reorder_song(id, new_pos) }, "순서 변경 완료", "순서 변경에 실패했습니다")
}

pub fn add_song(repo: Repository, video_id: String) -> Effect(Msg) {
  crud(
    fn() {
      repo.add_song(video_id, video_id, 0, "dashboard")
      |> result_to_nil
    },
    "곡 추가 완료",
    "곡 추가에 실패했습니다. URL을 확인해주세요",
  )
}

fn result_to_nil(result: Result(a, b)) -> Result(Nil, b) {
  case result {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(e)
  }
}
