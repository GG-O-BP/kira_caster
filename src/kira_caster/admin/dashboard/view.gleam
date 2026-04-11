import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import kira_caster/admin/dashboard/model.{
  type Model, type Msg, type Tab, type Toast,
}
import kira_caster/util/time
import lustre/attribute.{attribute as attr}
import lustre/element.{type Element, fragment, text}
import lustre/element/html
import lustre/event

// --- Main view --------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  fragment([
    html.div([attribute.class("header-row")], [
      html.h1([], [text("kira_caster 관리 대시보드")]),
      mode_badge(model.adapter_mode),
    ]),
    tabs_bar(model.active_tab, model.adapter_mode),
    html.div([attribute.class("panel active")], [
      case model.loading {
        True ->
          html.div([attribute.class("loading-overlay")], [
            html.div([attribute.class("spinner")], []),
          ])
        False -> text("")
      },
      active_panel(model),
    ]),
    toast_container(model.toasts),
  ])
}

fn mode_badge(mode: model.AdapterMode) -> Element(Msg) {
  case mode {
    model.CimeMode ->
      html.span(
        [
          attribute.class("mode-badge cime"),
          attr("title", "씨미 방송이랑 연결돼서 진짜 채팅에서 봇이 움직여용"),
        ],
        [text("씨미 연결됐당")],
      )
    model.MockMode ->
      html.span(
        [
          attribute.class("mode-badge mock"),
          attr("title", "씨미랑 아직 연결 안 됐어용 아래 '씨미 연동' 탭에서 연결해줘용"),
        ],
        [text("테스트 모드 — 씨미 아직이에용")],
      )
  }
}

// --- Tabs bar ---------------------------------------------------------------

fn tabs_bar(active: Tab, mode: model.AdapterMode) -> Element(Msg) {
  html.div(
    [attribute.class("tabs")],
    list.flatten([
      // 기본
      [
        tab_group_label("기본"),
        tab_btn("상태", model.Status, active),
        tab_btn("유저", model.Users, active),
        tab_btn("설정", model.Settings, active),
      ],
      // 채팅 관리
      [
        tab_divider(),
        tab_group_label("채팅 관리"),
        tab_btn("금칙어", model.Words, active),
        tab_btn("명령어", model.Commands, active),
        tab_btn("퀴즈", model.Quizzes, active),
        tab_btn("투표", model.Votes, active),
      ],
      // 엔터테인먼트
      [
        tab_divider(),
        tab_group_label("엔터테인먼트"),
        tab_btn("신청곡", model.Songs, active),
        tab_btn("플러그인", model.Plugins, active),
      ],
      // 씨미 연동 (MockMode에서는 연동 탭만 표시)
      case mode {
        model.CimeMode -> [
          tab_divider(),
          tab_group_label("씨미"),
          tab_btn("씨미 연동", model.CimeAuth, active),
          tab_btn("방송 설정", model.Broadcast, active),
          tab_btn("채팅 설정", model.ChatSettings, active),
          tab_btn("차단 관리", model.BlockManage, active),
          tab_btn("채널 정보", model.ChannelInfo, active),
        ]
        model.MockMode -> [
          tab_divider(),
          tab_btn("씨미 연동", model.CimeAuth, active),
        ]
      },
    ]),
  )
}

fn tab_divider() -> Element(Msg) {
  html.div([attribute.class("tab-divider")], [])
}

fn tab_group_label(label: String) -> Element(Msg) {
  html.span([attribute.class("tab-group-label")], [text(label)])
}

fn tab_btn(label: String, tab: Tab, active: Tab) -> Element(Msg) {
  html.div(
    [
      attribute.class(case tab == active {
        True -> "tab active"
        False -> "tab"
      }),
      event.on_click(model.SwitchTab(tab)),
    ],
    [text(label)],
  )
}

// --- Active panel dispatch --------------------------------------------------

fn active_panel(model: Model) -> Element(Msg) {
  let #(desc, content) = case model.active_tab {
    model.Status -> #("", status_view(model))
    model.Users -> #(
      "채팅에 참여한 시청자 목록이에용 포인트랑 출석 횟수도 볼 수 있당 ㅎㅎ",
      users_view(model),
    )
    model.Words -> #("여기에 추가한 단어가 채팅에 나오면 자동으로 삭제해줄게용", words_view(model))
    model.Commands -> #(
      "시청자가 !명령어 치면 봇이 자동으로 대답해줘용 예: !인사 → 안녕하세요!",
      commands_view(model),
    )
    model.Quizzes -> #("채팅에서 퀴즈 낼 수 있당! 정답 맞히면 포인트 받아용 ㅎㅎ", quizzes_view(model))
    model.Votes -> #("시청자한테 투표 받을 수 있당! 예: 오늘 할 게임 투표", votes_view(model))
    model.Plugins -> #("봇 기능을 켜고 끌 수 있어용 필요 없는 건 꺼두긔", plugins_view(model))
    model.Settings -> #("포인트, 명령어 간격 같은 세부 설정을 바꿀 수 있당", settings_view(model))
    model.Songs -> #("시청자가 신청한 YouTube 노래를 관리할 수 있당", songs_view(model))
    model.CimeAuth -> #("", cime_auth_view(model))
    model.Broadcast -> #("", broadcast_view(model))
    model.ChatSettings -> #("", chat_settings_view(model))
    model.BlockManage -> #("", block_manage_view(model))
    model.ChannelInfo -> #("", channel_info_view(model))
  }
  case desc {
    "" -> content
    d ->
      fragment([
        html.p(
          [attr("style", "font-size:0.85em;color:#888;margin-bottom:12px")],
          [text(d)],
        ),
        content,
      ])
  }
}

// --- 1. Status --------------------------------------------------------------

fn status_view(model: Model) -> Element(Msg) {
  let h = model.uptime_seconds / 3600
  let m = { model.uptime_seconds % 3600 } / 60
  let s = model.uptime_seconds % 60
  fragment([
    html.div([attr("style", "font-size:1.1em")], [
      html.div([attribute.class("form-row")], [
        html.span([attribute.class("dot green")], [text("열심히 일하는 중이에용")]),
        case model.adapter_mode {
          model.CimeMode -> connection_status_badge(model.connection_state)
          model.MockMode ->
            html.span([attr("style", "color:#888;font-size:0.85em")], [
              text("씨미랑 아직 안 연결됐어용 '씨미 연동'에서 연결해줘용"),
            ])
        },
      ]),
      html.div(
        [attr("style", "margin-top:12px;font-family:var(--font-number)")],
        [
          text(
            "가동 시간: "
            <> int.to_string(h)
            <> "시간 "
            <> int.to_string(m)
            <> "분 "
            <> int.to_string(s)
            <> "초",
          ),
        ],
      ),
    ]),
    case model.adapter_mode {
      model.MockMode ->
        html.div([attribute.class("welcome-card")], [
          html.h3([attr("style", "margin-bottom:12px;font-size:1.1em")], [
            text("kira_caster에 온 걸 환영해용!"),
          ]),
          html.p(
            [attr("style", "margin-bottom:12px;color:#888;line-height:1.5")],
            [
              text(
                "지금은 테스트 모드야 채팅방 연결 없이 봇 기능 미리 써볼 수 있당 ㅎㅎ 진짜 채팅방에서 쓰려면 아래 '씨미 연동'에서 연결해줘용",
              ),
            ],
          ),
          html.p(
            [attr("style", "margin-bottom:12px;color:#888;font-size:0.9em")],
            [text("이 순서로 해보긔!")],
          ),
          html.div([attribute.class("welcome-steps")], [
            welcome_step(
              "1",
              "씨미 연동 — 봇을 채팅방에 연결하긔",
              "씨미 계정 연결하면 진짜 방송 채팅에서 봇이 움직여용 여기 눌러줘용",
              model.CimeAuth,
            ),
            welcome_step(
              "2",
              "명령어 — 봇이 할 말 정하긔",
              "시청자가 !명령어 치면 봇이 대답해줘용 예: !인사 → '안녕하세요!'",
              model.Commands,
            ),
            welcome_step(
              "3",
              "설정 — 포인트랑 게임 규칙 바꾸긔",
              "출석 포인트, 게임 보상 같은 거 맘대로 바꿀 수 있당 ㅎㅎ",
              model.Settings,
            ),
          ]),
        ])
      model.CimeMode -> text("")
    },
  ])
}

fn welcome_step(
  num: String,
  title: String,
  desc: String,
  tab: Tab,
) -> Element(Msg) {
  html.div(
    [attribute.class("welcome-step"), event.on_click(model.SwitchTab(tab))],
    [
      html.span([attribute.class("welcome-step-num")], [text(num)]),
      html.div([], [
        html.strong([], [text(title)]),
        html.br([]),
        html.span([attr("style", "font-size:0.85em;color:#888")], [text(desc)]),
      ]),
    ],
  )
}

fn connection_status_badge(state: model.CimeConnectionState) -> Element(Msg) {
  case state {
    model.CsConnected ->
      html.span([attribute.class("dot green")], [text("씨미 연결됐당!")])
    model.CsDisconnected ->
      html.span([attribute.class("dot red")], [text("씨미 연결 끊겼어 ㅠㅠ")])
    model.CsReconnecting(attempt, max) ->
      html.span([attribute.class("dot yellow")], [
        text(
          "재연결 중 ("
          <> int.to_string(attempt)
          <> "/"
          <> int.to_string(max)
          <> ")",
        ),
      ])
  }
}

// --- 2. Users ---------------------------------------------------------------

fn users_view(model: Model) -> Element(Msg) {
  let filtered = case model.user_filter {
    "" -> model.users
    q ->
      list.filter(model.users, fn(u) {
        string.contains(string.lowercase(u.user_id), string.lowercase(q))
      })
  }
  fragment([
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.placeholder("유저 검색해보긔"),
        attribute.value(model.user_filter),
        event.on_input(model.UpdateUserFilter),
      ]),
    ]),
    html.table([], [
      html.thead([], [
        html.tr([], [th("유저"), th("포인트"), th("출석"), th("최근출석")]),
      ]),
      html.tbody([], case filtered {
        [] -> [empty_row(4)]
        users ->
          list.map(users, fn(u) {
            html.tr([], [
              html.td([], [text(u.user_id)]),
              html.td([], [text(int.to_string(u.points))]),
              html.td([], [text(int.to_string(u.attendance_count))]),
              html.td([], [
                text(case u.last_attendance {
                  0 -> "-"
                  _ -> time.format_ms(u.last_attendance)
                }),
              ]),
            ])
          })
      }),
    ]),
  ])
}

// --- 3. Words ---------------------------------------------------------------

fn words_view(model: Model) -> Element(Msg) {
  fragment([
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.placeholder("금칙어를 넣어줘용"),
        attribute.value(model.new_word),
        event.on_input(model.UpdateNewWord),
      ]),
      html.button([event.on_click(model.AddWord)], [text("추가")]),
    ]),
    html.table([], [
      html.thead([], [html.tr([], [th("단어"), th("")])]),
      html.tbody([], case model.words {
        [] -> [empty_row(2)]
        words ->
          list.map(words, fn(w) {
            html.tr([], [
              html.td([], [text(w)]),
              html.td([], [
                html.button(
                  [
                    attribute.class("danger"),
                    event.on_click(model.DeleteWord(w)),
                  ],
                  [text("삭제")],
                ),
              ]),
            ])
          })
      }),
    ]),
  ])
}

// --- 4. Commands ------------------------------------------------------------

fn commands_view(model: Model) -> Element(Msg) {
  fragment([
    html.div([attribute.class("form-row")], [
      html.select([on_change(model.UpdateCmdType)], [
        html.option(
          [
            attribute.value("text"),
            attribute.selected(model.cmd_type == model.TextCmd),
          ],
          "텍스트/템플릿",
        ),
        html.option(
          [
            attribute.value("gleam"),
            attribute.selected(model.cmd_type == model.GleamCmd),
          ],
          "고급 (Gleam)",
        ),
      ]),
      html.input([
        attribute.placeholder("명령어 이름을 넣어줘용"),
        attribute.value(model.cmd_name),
        event.on_input(model.UpdateCmdName),
      ]),
    ]),
    case model.cmd_type {
      model.TextCmd ->
        fragment([
          html.div([attribute.class("form-row")], [
            html.input([
              attribute.placeholder("응답 내용"),
              attribute.value(model.cmd_response),
              event.on_input(model.UpdateCmdResponse),
            ]),
            html.button([event.on_click(model.AddTextCmd)], [
              text(case model.editing_cmd {
                Some(_) -> "저장"
                None -> "추가"
              }),
            ]),
            case model.editing_cmd {
              Some(_) ->
                html.button([event.on_click(model.CancelEditCmd)], [
                  text("취소"),
                ])
              None -> text("")
            },
          ]),
          html.div(
            [
              attr(
                "style",
                "font-size:0.8em;color:#aaa;margin-top:4px;padding-left:4px",
              ),
            ],
            [
              text(
                "쓸 수 있는 변수이에용 {{user}} = 이름, {{points}} = 포인트, {{count}} = 출석 횟수",
              ),
            ],
          ),
        ])
      model.GleamCmd ->
        fragment([
          element.element(
            "code-editor",
            [
              attribute.property("value", json.string(model.cmd_source)),
              attr("placeholder", "Gleam 소스 코드를 여기에"),
              event.on_input(model.UpdateCmdSource),
            ],
            [],
          ),
          html.div([attribute.class("form-row")], [
            html.button([event.on_click(model.AddGleamCmd)], [
              text(case model.editing_cmd {
                Some(_) -> "컴파일하고 저장하긔"
                None -> "컴파일하고 추가하긔"
              }),
            ]),
            case model.editing_cmd {
              Some(_) ->
                html.button([event.on_click(model.CancelEditCmd)], [
                  text("취소"),
                ])
              None -> text("")
            },
          ]),
        ])
    },
    html.table([], [
      html.thead([], [
        html.tr([], [th("이름"), th("타입"), th("응답/소스"), th("")]),
      ]),
      html.tbody([], case model.commands {
        [] -> [empty_row(4)]
        cmds ->
          list.map(cmds, fn(c) {
            let #(name, response, cmd_type, _source) = c
            html.tr([], [
              html.td([], [text(name)]),
              html.td([], [text(cmd_type)]),
              html.td([], [text(response)]),
              html.td([], [
                html.button(
                  [event.on_click(model.EditCmd(name))],
                  [text("수정")],
                ),
                html.button(
                  [
                    attribute.class("danger"),
                    event.on_click(model.DeleteCmd(name)),
                  ],
                  [text("삭제")],
                ),
              ]),
            ])
          })
      }),
    ]),
  ])
}

fn on_change(msg: fn(String) -> Msg) -> attribute.Attribute(Msg) {
  event.on("change", {
    use value <- decode.subfield(["target", "value"], decode.string)
    decode.success(msg(value))
  })
}

// --- 5. Quizzes -------------------------------------------------------------

fn quizzes_view(model: Model) -> Element(Msg) {
  fragment([
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.placeholder("문제"),
        attribute.value(model.quiz_question),
        event.on_input(model.UpdateQuizQ),
      ]),
      html.input([
        attribute.placeholder("정답"),
        attribute.value(model.quiz_answer),
        event.on_input(model.UpdateQuizA),
      ]),
      html.input([
        attribute.placeholder("보상"),
        attribute.value(model.quiz_reward),
        attribute.type_("number"),
        event.on_input(model.UpdateQuizR),
      ]),
      html.button([event.on_click(model.AddQuiz)], [
        text(case model.editing_quiz {
          Some(_) -> "저장"
          None -> "추가"
        }),
      ]),
      case model.editing_quiz {
        Some(_) ->
          html.button([event.on_click(model.CancelEditQuiz)], [text("취소")])
        None -> text("")
      },
    ]),
    html.table([], [
      html.thead([], [
        html.tr([], [th("문제"), th("정답"), th("보상"), th("")]),
      ]),
      html.tbody([], case model.quizzes {
        [] -> [empty_row(4)]
        quizzes ->
          list.map(quizzes, fn(q) {
            let #(question, answer, reward) = q
            html.tr([], [
              html.td([], [text(question)]),
              html.td([], [
                html.span([attribute.class("tag")], [text(answer)]),
              ]),
              html.td([], [text(int.to_string(reward))]),
              html.td([], [
                html.button(
                  [event.on_click(model.EditQuiz(question))],
                  [text("수정")],
                ),
                html.button(
                  [
                    attribute.class("danger"),
                    event.on_click(model.DeleteQuiz(question)),
                  ],
                  [text("삭제")],
                ),
              ]),
            ])
          })
      }),
    ]),
  ])
}

// --- 6. Votes ---------------------------------------------------------------

fn votes_view(model: Model) -> Element(Msg) {
  case model.vote_active {
    False ->
      fragment([
        html.div([attribute.class("empty")], [
          text("진행 중인 투표가 없당"),
        ]),
        section_heading_top("새 투표"),
        html.div([attribute.class("form-row")], [
          html.input([
            attribute.placeholder("투표 주제를 넣어줘용"),
            attribute.value(model.vote_topic),
            event.on_input(model.UpdateVoteTopic),
          ]),
          html.input([
            attribute.placeholder("선택지 (쉼표로 구분해줘용)"),
            attribute.value(model.vote_options),
            event.on_input(model.UpdateVoteOptions),
          ]),
          html.button([event.on_click(model.StartVote)], [text("투표 시작하긔!")]),
        ]),
      ])
    True -> {
      let total = list.fold(model.vote_results, 0, fn(acc, r) { acc + r.count })
      fragment([
        html.div([], [
          html.strong([], [text(model.vote_topic_display)]),
          html.span([attribute.class("tag")], [text("실시간")]),
          html.button(
            [attribute.class("danger"), event.on_click(model.EndVote)],
            [text("투표 끝내긔")],
          ),
        ]),
        html.div(
          [],
          list.map(model.vote_results, fn(r) {
            let pct = case total > 0 {
              True -> r.count * 100 / total
              False -> 0
            }
            html.div([attribute.class("bar-wrap")], [
              html.div(
                [
                  attribute.class("bar-fill"),
                  attr("style", "width:" <> int.to_string(pct) <> "%"),
                ],
                [],
              ),
              html.span([], [
                text(
                  r.choice
                  <> " ("
                  <> int.to_string(r.count)
                  <> "표, "
                  <> int.to_string(pct)
                  <> "%)",
                ),
              ]),
            ])
          }),
        ),
      ])
    }
  }
}

// --- 7. Plugins -------------------------------------------------------------

fn plugins_view(model: Model) -> Element(Msg) {
  html.table([], [
    html.thead([], [
      html.tr([], [th("이름"), th("설명"), th("상태"), th("")]),
    ]),
    html.tbody([], case model.plugins {
      [] -> [empty_row(4)]
      plugins ->
        list.map(plugins, fn(p) {
          html.tr([], [
            html.td([], [text(p.name)]),
            html.td([], [text(p.description)]),
            html.td([], [
              html.span(
                [
                  attribute.class(case p.enabled {
                    True -> "on"
                    False -> "off"
                  }),
                ],
                [
                  text(case p.enabled {
                    True -> "ON"
                    False -> "OFF"
                  }),
                ],
              ),
            ]),
            html.td([], [
              case p.enabled {
                True ->
                  html.button(
                    [
                      attribute.class("danger"),
                      event.on_click(model.TogglePlugin(p.name, False)),
                    ],
                    [text("끄긔")],
                  )
                False ->
                  html.button(
                    [
                      attribute.class("success"),
                      event.on_click(model.TogglePlugin(p.name, True)),
                    ],
                    [text("켜긔")],
                  )
              },
            ]),
          ])
        })
    }),
  ])
}

// --- 8. Settings ------------------------------------------------------------

fn settings_view(model: Model) -> Element(Msg) {
  let system_defs = [
    #(
      "admin_key",
      "관리자 비밀번호",
      "",
      True,
      "이 관리 화면 들어갈 때 쓰는 비밀번호야 안 정하면 아무나 들어올 수 있으니까 꼭 정해줘잉",
    ),
    #(
      "cime_client_id",
      "씨미 Client ID",
      "",
      False,
      "씨미 개발자 센터(developers.ci.me)에서 앱 만들면 나오는 Client ID야",
    ),
    #(
      "cime_client_secret",
      "씨미 Client Secret",
      "",
      True,
      "씨미 개발자 센터에서 앱 만들면 나오는 Client Secret이야 절대 다른 사람한테 주면 안 돼용!!",
    ),
    #(
      "youtube_api_key",
      "YouTube API 키",
      "",
      False,
      "신청곡 제목이랑 길이 자동으로 가져올 때 써용 비워도 대부분 ㄱㅊ ㅎㅎ",
    ),
  ]
  let game_defs = [
    #(
      "cooldown_ms",
      "명령어 사용 간격",
      "5000",
      False,
      "같은 명령어 다시 쓸 때까지 기다리는 시간이에용 숫자가 크면 더 천천히 쓸 수 있당",
    ),
    #("attendance_points", "출석 보상", "10", False, "하루 한 번 출석하면 받는 포인트야"),
    #("dice_win_points", "주사위 이김 보상", "50", False, "주사위 이기면 받는 포인트야"),
    #(
      "dice_loss_points",
      "주사위 짐 감점",
      "-20",
      False,
      "주사위 지면 깎이는 포인트야 음수(-)로 넣어줘용",
    ),
    #("rps_win_points", "가위바위보 이김 보상", "30", False, "가위바위보 이기면 받는 포인트야"),
    #(
      "rps_loss_points",
      "가위바위보 짐 감점",
      "-10",
      False,
      "가위바위보 지면 깎이는 포인트야 음수(-)로 넣어줘용",
    ),
  ]
  fragment([
    section_heading("시스템 설정"),
    html.p([attr("style", "font-size:0.85em;color:#888;margin-bottom:8px")], [
      text("이 설정은 바꾸고 아래 '변경사항 적용' 버튼 눌러야 돼용 버튼 누르면 프로그램이 자동으로 다시 시작돼용!"),
    ]),
    html.div(
      [],
      list.map(system_defs, fn(def) {
        let #(key, label, default, is_secret, hint) = def
        setting_row(model, key, label, default, is_secret, hint)
      }),
    ),
    html.div([attr("style", "margin-top:12px")], [
      html.button(
        [attribute.class("primary"), event.on_click(model.RestartApp)],
        [text("변경사항 적용하긔 (재시작)")],
      ),
    ]),
    section_heading_top("게임 설정"),
    html.p([attr("style", "font-size:0.85em;color:#888;margin-bottom:8px")], [
      text("이건 저장하면 바로 적용돼용 재시작 안 해도 돼 ㅎㅎ"),
    ]),
    html.div(
      [],
      list.map(game_defs, fn(def) {
        let #(key, label, default, is_secret, hint) = def
        setting_row(model, key, label, default, is_secret, hint)
      }),
    ),
  ])
}

fn setting_row(
  model: Model,
  key: String,
  label: String,
  default: String,
  is_secret: Bool,
  hint: String,
) -> Element(Msg) {
  let val = find_setting(model.editing_settings, key, default)
  let is_visible = list.contains(model.show_secrets, key)
  html.div([attr("style", "margin-top:10px")], [
    html.div([attribute.class("form-row")], [
      html.label([attr("style", "min-width:180px;font-weight:600")], [
        text(label),
      ]),
      html.input([
        attribute.value(val),
        case is_secret && !is_visible {
          True -> attribute.type_("password")
          False -> attribute.type_("text")
        },
        event.on_input(fn(v) { model.UpdateSettingEdit(key, v) }),
        attr("style", "flex:1;min-width:120px"),
      ]),
      case is_secret {
        True ->
          html.button(
            [
              attr("style", "min-width:56px"),
              event.on_click(model.ToggleSecretVisible(key)),
            ],
            [
              text(case is_visible {
                True -> "숨기긔"
                False -> "보긔"
              }),
            ],
          )
        False -> text("")
      },
      html.button([event.on_click(model.SaveSetting(key, val))], [
        text("저장"),
      ]),
    ]),
    html.div(
      [
        attr(
          "style",
          "font-size:0.8em;color:#aaa;margin-top:2px;padding-left:4px",
        ),
      ],
      [text(hint), ms_hint(key, val)],
    ),
  ])
}

fn ms_hint(key: String, val: String) -> Element(Msg) {
  case key {
    "cooldown_ms" ->
      case int.parse(val) {
        Ok(ms) -> {
          let sec = ms / 1000
          let remainder = ms % 1000
          case sec, remainder {
            0, _ -> text(" (1초도 안 됨 ㅋㅋ)")
            s, 0 -> text(" → 약 " <> int.to_string(s) <> "초마다 명령어 쓸 수 있당")
            s, _ ->
              text(
                " → 약 "
                <> int.to_string(s)
                <> "."
                <> int.to_string(remainder / 100)
                <> "초마다 명령어 쓸 수 있당",
              )
          }
        }
        Error(_) -> text(" (숫자를 넣어줘용)")
      }
    _ -> text("")
  }
}

fn find_setting(
  settings: List(#(String, String)),
  key: String,
  default: String,
) -> String {
  case list.find(settings, fn(s) { s.0 == key }) {
    Ok(#(_, v)) -> v
    Error(_) -> default
  }
}

// --- 9. Songs ---------------------------------------------------------------

fn songs_view(model: Model) -> Element(Msg) {
  fragment([
    section_heading("현재 재생"),
    html.div([attribute.class("form-row")], case model.current_song {
      None -> [text("재생 중인 곡이 없당")]
      Some(song) -> [
        html.strong([], [text(song.title)]),
        html.span([], [
          text(
            " ("
            <> song.requested_by
            <> " / "
            <> fmt_duration(song.duration_seconds)
            <> ")",
          ),
        ]),
      ]
    }),
    html.div([attribute.class("form-row")], [
      html.button([event.on_click(model.SongPrev)], [text("이전")]),
      html.button([event.on_click(model.SongReplay)], [text("처음부터")]),
      html.button([event.on_click(model.SongNext)], [text("다음")]),
    ]),
    section_heading_top("곡 추가"),
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.placeholder(
          "YouTube 주소를 넣어줘용 (예: https://youtube.com/watch?v=...)",
        ),
        attribute.value(model.song_url),
        event.on_input(model.UpdateSongUrl),
      ]),
      html.button([event.on_click(model.AddSong)], [text("추가")]),
    ]),
    section_heading_top("대기열"),
    html.table([], [
      html.thead([], [
        html.tr([], [th("#"), th("제목"), th("신청자"), th("길이"), th("")]),
      ]),
      html.tbody([], case model.songs {
        [] -> [empty_row(5)]
        songs ->
          list.index_map(songs, fn(s, i) {
            html.tr([], [
              html.td([], [text(int.to_string(i + 1))]),
              html.td([], [text(s.title)]),
              html.td([], [text(s.requested_by)]),
              html.td([], [text(fmt_duration(s.duration_seconds))]),
              html.td([], [
                html.button(
                  [
                    attribute.class("danger"),
                    event.on_click(model.DeleteSong(s.id)),
                  ],
                  [text("삭제")],
                ),
              ]),
            ])
          })
      }),
    ]),
  ])
}

fn fmt_duration(sec: Int) -> String {
  let h = sec / 3600
  let m = { sec % 3600 } / 60
  let s = sec % 60
  case h > 0 {
    True -> int.to_string(h) <> ":" <> pad2(m) <> ":" <> pad2(s)
    False -> int.to_string(m) <> ":" <> pad2(s)
  }
}

fn pad2(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}

// --- 10. CIME Auth ----------------------------------------------------------

fn cime_auth_view(model: Model) -> Element(Msg) {
  fragment([
    section_heading("씨미 연동 상태"),
    html.div([attribute.class("form-row")], [
      case model.cime_authenticated {
        True -> html.span([attribute.class("dot green")], [text("연결됐당!")])
        False -> html.span([attribute.class("dot red")], [text("아직 안 연결됐어용")])
      },
    ]),
    case model.cime_authenticated {
      True ->
        fragment([
          html.div([attribute.class("form-row")], [
            html.span([], [text("채널: " <> model.cime_channel_name)]),
          ]),
          html.div([attribute.class("form-row")], [
            html.span([], [text("만료: " <> model.cime_expires_at)]),
          ]),
          html.div([attribute.class("form-row")], [
            html.button(
              [attribute.class("danger"), event.on_click(model.CimeDisconnect)],
              [text("연결 끊기")],
            ),
          ]),
        ])
      False ->
        html.div([attribute.class("form-row")], [
          html.a(
            [attribute.href("/oauth/authorize"), attr("target", "_blank")],
            [text("연결하긔!")],
          ),
        ])
    },
  ])
}

// --- 11. Broadcast ----------------------------------------------------------

fn broadcast_view(model: Model) -> Element(Msg) {
  fragment([
    section_heading("방송 제목"),
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.value(model.bc_title),
        attribute.placeholder("방송 제목"),
        event.on_input(model.UpdateBcTitle),
      ]),
      html.button([event.on_click(model.SaveBcTitle)], [text("저장")]),
    ]),
    section_heading_top("태그"),
    html.div(
      [attribute.class("form-row")],
      list.append(
        list.map(model.bc_tags, fn(tag) {
          html.span([attribute.class("tag")], [
            text(tag),
            html.button(
              [
                attribute.class("tag-remove"),
                event.on_click(model.RemoveBcTag(tag)),
              ],
              [text("x")],
            ),
          ])
        }),
        [
          html.input([
            attribute.placeholder("새 태그"),
            attribute.value(model.bc_new_tag),
            event.on_input(model.UpdateBcNewTag),
          ]),
          html.button([event.on_click(model.AddBcTag)], [text("추가")]),
        ],
      ),
    ),
    section_heading_top("카테고리"),
    html.div([attribute.class("form-row")], [
      html.span([], [text("현재: " <> model.bc_category_name)]),
    ]),
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.placeholder("카테고리 검색"),
        attribute.value(model.bc_cat_search),
        event.on_input(model.UpdateBcCatSearch),
      ]),
    ]),
    html.div(
      [],
      list.map(model.bc_categories, fn(cat) {
        let #(cat_id, cat_name) = cat
        html.button(
          [
            attribute.class("category-btn"),
            event.on_click(model.SelectCategory(cat_id, cat_name)),
          ],
          [text(cat_name)],
        )
      }),
    ),
  ])
}

// --- 12. Chat Settings ------------------------------------------------------

fn chat_settings_view(model: Model) -> Element(Msg) {
  fragment([
    section_heading("채팅 설정"),
    html.div([attribute.class("form-row")], [
      html.label([], [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(model.cs_slow_mode),
          event.on_check(model.UpdateSlowMode),
        ]),
        text(" 슬로우 모드"),
      ]),
    ]),
    html.div([attribute.class("form-row")], [
      html.label([], [text("슬로우 모드 간격 (초)")]),
      html.input([
        attribute.type_("number"),
        attribute.value(int.to_string(model.cs_slow_seconds)),
        event.on_input(model.UpdateSlowSeconds),
      ]),
    ]),
    html.div([attribute.class("form-row")], [
      html.label([], [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(model.cs_follower_only),
          event.on_check(model.UpdateFollowerOnly),
        ]),
        text(" 팔로워 전용 채팅"),
      ]),
    ]),
    html.div([attribute.class("form-row")], [
      html.button([event.on_click(model.SaveChatSettings)], [text("저장")]),
    ]),
  ])
}

// --- 13. Block Manage -------------------------------------------------------

fn block_manage_view(model: Model) -> Element(Msg) {
  fragment([
    section_heading("차단 관리"),
    html.div([attribute.class("form-row")], [
      html.input([
        attribute.placeholder("닉네임이나 채널 ID 넣어줘용"),
        attribute.value(model.block_target),
        event.on_input(model.UpdateBlockTarget),
      ]),
      html.button([event.on_click(model.AddBlock)], [text("차단")]),
    ]),
    html.table([], [
      html.thead([], [
        html.tr([], [th("채널 ID"), th("닉네임"), th("차단일"), th("")]),
      ]),
      html.tbody([], case model.blocked_users {
        [] -> [empty_row(4)]
        users ->
          list.map(users, fn(u) {
            let #(channel_id, nickname, blocked_at) = u
            html.tr([], [
              html.td([], [text(channel_id)]),
              html.td([], [text(nickname)]),
              html.td([], [text(blocked_at)]),
              html.td([], [
                html.button(
                  [
                    attribute.class("danger"),
                    event.on_click(model.RemoveBlock(channel_id)),
                  ],
                  [text("해제")],
                ),
              ]),
            ])
          })
      }),
    ]),
  ])
}

// --- 14. Channel Info -------------------------------------------------------

fn channel_info_view(model: Model) -> Element(Msg) {
  fragment([
    section_heading("채널 정보"),
    html.div([attribute.class("form-row")], [
      case model.ch_image_url {
        "" -> text("")
        url ->
          html.img([
            attr("src", url),
            attr("style", "width:48px;height:48px;border-radius:50%"),
          ])
      },
      html.div([], [
        html.strong([], [text(model.ch_name)]),
        html.br([]),
        html.span([], [text("@" <> model.ch_handle)]),
      ]),
    ]),
    section_heading_top("방송 상태"),
    html.div([attribute.class("form-row")], [
      case model.ch_live {
        True ->
          fragment([
            html.span([attribute.class("dot green")], [text("방송 중이에용")]),
            html.span([], [
              text(
                " - "
                <> model.ch_live_title
                <> " ("
                <> int.to_string(model.ch_viewer_count)
                <> "명 시청)",
              ),
            ]),
          ])
        False -> html.span([attribute.class("dot red")], [text("오프라인이에용")])
      },
    ]),
    section_heading_top("스트림 키"),
    html.div([attribute.class("form-row")], [
      case model.stream_key_visible {
        True ->
          html.span([attr("style", "font-family:var(--font-number)")], [
            text(model.stream_key),
          ])
        False -> html.span([], [text("********")])
      },
      html.button([event.on_click(model.ToggleStreamKey)], [
        text(case model.stream_key_visible {
          True -> "숨기긔"
          False -> "보긔"
        }),
      ]),
    ]),
  ])
}

// --- Helpers ----------------------------------------------------------------

fn th(label: String) -> Element(Msg) {
  html.th([], [text(label)])
}

fn empty_row(cols: Int) -> Element(Msg) {
  html.tr([], [
    html.td([attr("colspan", int.to_string(cols)), attribute.class("empty")], [
      text("아직 데이터가 없당"),
    ]),
  ])
}

fn toast_container(toasts: List(Toast)) -> Element(Msg) {
  html.div(
    [attribute.class("toast-container")],
    list.map(toasts, fn(t) {
      let cls = case t.toast_type {
        model.SuccessToast -> "toast show success"
        model.ErrorToast -> "toast show error"
      }
      html.div([attribute.class(cls)], [text(t.message)])
    }),
  )
}

fn section_heading(label: String) -> Element(Msg) {
  html.h3([attr("style", "margin-bottom:12px")], [text(label)])
}

fn section_heading_top(label: String) -> Element(Msg) {
  html.h3([attr("style", "margin-top:16px;margin-bottom:12px")], [text(label)])
}
