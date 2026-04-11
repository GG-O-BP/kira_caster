import kira_caster/admin/views/layout
import lustre/attribute.{attribute as attr}
import lustre/element.{type Element, element as el, fragment, text}
import lustre/element/html
import wisp.{type Response}

pub fn handle_setup(message: String, is_success: Bool) -> Response {
  layout.page(
    title: "kira_caster 초기 설정",
    head: setup_head(),
    body: setup_body(message, is_success),
    tail: "",
  )
}

pub fn handle_setup_done() -> Response {
  layout.page(
    title: "kira_caster 설정 완료",
    head: setup_head() <> "<meta http-equiv=\"refresh\" content=\"5;url=/\">",
    body: setup_done_body(),
    tail: "",
  )
}

fn setup_head() -> String {
  "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"
  <> "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"
  <> "<link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&display=swap\" rel=\"stylesheet\">"
  <> "<style>"
  <> setup_css()
  <> "</style>"
}

fn setup_done_body() -> Element(Nil) {
  fragment([
    html.div([attribute.class("setup-container")], [
      html.div([attribute.class("setup-card")], [
        html.h1([attribute.class("setup-title")], [text("kira_caster")]),
        html.div([attribute.class("setup-success")], [
          text("설정이 저장되었습니다!"),
        ]),
        html.div([attribute.class("setup-done")], [
          html.p([], [text("설정을 적용하고 있습니다...")]),
          html.p(
            [attr("style", "margin-top:12px;font-size:0.85em;color:#888")],
            [text("잠시 후 자동으로 대시보드로 이동합니다.")],
          ),
        ]),
      ]),
    ]),
  ])
}

fn setup_body(message: String, is_success: Bool) -> Element(Nil) {
  fragment([
    html.div([attribute.class("setup-container")], [
      html.div([attribute.class("setup-card")], [
        html.h1([attribute.class("setup-title")], [text("kira_caster")]),
        html.p([attribute.class("setup-subtitle")], [
          text("처음 오셨군요! 기본 설정을 진행해주세요."),
        ]),
        case message {
          "" -> text("")
          msg ->
            html.div(
              [
                attribute.class(case is_success {
                  True -> "setup-success"
                  False -> "setup-error"
                }),
              ],
              [text(msg)],
            )
        },
        case is_success {
          True ->
            html.div([attribute.class("setup-done")], [
              html.p([], [
                text("프로그램을 재시작하면 설정이 적용됩니다."),
              ]),
              html.p(
                [attr("style", "margin-top:8px;font-size:0.85em;color:#888")],
                [
                  text("Docker: "),
                  html.code([], [text("docker compose restart")]),
                  html.br([]),
                  text("직접 실행: 프로그램을 종료 후 "),
                  html.code([], [text("gleam run")]),
                ],
              ),
            ])
          False ->
            html.form([attr("method", "POST"), attr("action", "/setup")], [
              // Step 1: Admin password
              html.div([attribute.class("setup-section")], [
                html.h3([], [text("1. 관리자 비밀번호")]),
                html.p([attribute.class("setup-hint")], [
                  text("대시보드 접속 시 사용할 비밀번호입니다. 비워두면 누구나 접근할 수 있습니다."),
                ]),
                html.input([
                  attribute.type_("password"),
                  attr("name", "admin_key"),
                  attribute.placeholder("비밀번호 (선택)"),
                ]),
              ]),
              // Step 2: CIME settings
              html.div([attribute.class("setup-section")], [
                html.h3([], [text("2. 씨미(ci.me) 연동")]),
                html.p([attribute.class("setup-hint")], [
                  text("씨미 스트리밍과 연동하려면 아래 정보를 입력하세요. 나중에 대시보드에서도 설정할 수 있습니다."),
                ]),
                html.div([attribute.class("setup-guide")], [
                  html.p([attr("style", "font-weight:600;margin-bottom:6px")], [
                    text("준비 방법:"),
                  ]),
                  html.ol([attr("style", "padding-left:20px;line-height:1.8")], [
                    html.li([], [
                      text("씨미 개발자 센터에 접속하세요"),
                    ]),
                    html.li([], [
                      text("\"새 앱 만들기\"를 클릭하세요"),
                    ]),
                    html.li([], [
                      text("앱 이름에 \"kira_caster\"를 입력하세요"),
                    ]),
                    html.li([], [
                      text("Redirect URI에 "),
                      html.code([], [
                        text("http://localhost:8080/oauth/callback"),
                      ]),
                      text(" 을 입력하세요"),
                    ]),
                    html.li([], [
                      text("앱을 생성하면 표시되는 앱 ID와 앱 비밀키를 아래에 입력하세요"),
                    ]),
                  ]),
                  html.a(
                    [
                      attribute.href("https://ci.me/developer"),
                      attr("target", "_blank"),
                      attribute.class("guide-link"),
                    ],
                    [text("씨미 개발자 센터 열기")],
                  ),
                ]),
                html.input([
                  attr("name", "cime_client_id"),
                  attribute.placeholder("앱 ID (Client ID) - 개발자 센터에서 복사"),
                ]),
                html.input([
                  attr("name", "cime_client_secret"),
                  attribute.placeholder("앱 비밀키 (Client Secret) - 개발자 센터에서 복사"),
                  attribute.type_("password"),
                ]),
                el("details", [], [
                  el("summary", [attribute.class("setup-hint")], [
                    text("이게 뭔가요?"),
                  ]),
                  html.p([attribute.class("setup-hint")], [
                    text(
                      "씨미에서 봇을 사용하려면 '앱'을 등록해야 합니다. 앱 ID와 비밀키는 봇이 씨미에 로그인할 때 사용하는 열쇠 같은 것입니다. 채널 ID는 연동 후 자동으로 가져옵니다.",
                    ),
                  ]),
                ]),
              ]),
              html.button([attribute.type_("submit")], [text("설정 완료")]),
              html.a(
                [
                  attribute.href("/setup?skip=true"),
                  attribute.class("skip-link"),
                ],
                [text("건너뛰고 테스트 모드로 시작")],
              ),
            ])
        },
      ]),
    ]),
  ])
}

fn setup_css() -> String {
  "
    :root {
      --color-primary: #FD719B;
      --gradient-main: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%);
      --gradient-secondary: linear-gradient(92.54deg, #FD719B 5.84%, #FD9371 95.21%);
      --color-success: #00C199;
      --color-error: #F77061;
      --color-text: #54577A;
      --color-border: #E9EAEE;
      --color-bg: #FFFFFF;
      --radius-card: 12px;
      --radius-input: 8px;
      --radius-pill: 20px;
      --font-body: Hiragino Sans, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font-body); background: var(--color-bg); color: var(--color-text); }
    .setup-container { display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }
    .setup-card { width: 100%; max-width: 480px; background: var(--color-bg); border: 1px solid var(--color-border); border-radius: var(--radius-card); padding: 40px 32px; }
    .setup-title { font-family: 'Quicksand', sans-serif; background: var(--gradient-main); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; font-weight: 700; font-size: 2em; margin-bottom: 8px; text-align: center; }
    .setup-subtitle { color: var(--color-text); font-size: 0.95em; margin-bottom: 24px; text-align: center; line-height: 1.5; }
    .setup-section { margin-bottom: 24px; }
    .setup-section h3 { font-family: 'Quicksand', sans-serif; font-weight: 700; margin-bottom: 6px; color: var(--color-primary); }
    .setup-hint { font-size: 0.85em; color: #888; margin-bottom: 10px; line-height: 1.4; }
    .setup-error { background: rgba(247,112,97,0.1); color: var(--color-error); padding: 10px 14px; border-radius: var(--radius-input); margin-bottom: 16px; font-size: 0.9em; font-weight: 600; text-align: center; }
    .setup-success { background: rgba(0,193,153,0.1); color: var(--color-success); padding: 10px 14px; border-radius: var(--radius-input); margin-bottom: 16px; font-size: 0.9em; font-weight: 600; text-align: center; }
    .setup-done { text-align: center; margin-top: 16px; line-height: 1.6; }
    .setup-done code { background: rgba(253,113,155,0.1); padding: 2px 8px; border-radius: 4px; font-size: 0.9em; }
    form { display: flex; flex-direction: column; gap: 10px; }
    input { padding: 12px 16px; border: 1px solid var(--color-border); border-radius: var(--radius-input); font-family: inherit; font-size: 0.95em; }
    input:focus { outline: none; border-color: var(--color-primary); }
    button { padding: 14px; background: var(--gradient-secondary); color: #fff; border: none; border-radius: var(--radius-pill); cursor: pointer; font-family: inherit; font-weight: 600; font-size: 1em; transition: opacity .2s; margin-top: 8px; }
    button:hover { opacity: 0.85; }
    .setup-guide { background: rgba(253,113,155,0.06); border: 1px solid rgba(253,113,155,0.15); border-radius: var(--radius-input); padding: 14px 16px; margin-bottom: 12px; font-size: 0.88em; color: var(--color-text); line-height: 1.5; }
    .guide-link { display: inline-block; margin-top: 10px; padding: 8px 16px; background: var(--gradient-secondary); color: #fff !important; border-radius: var(--radius-pill); font-size: 0.9em; font-weight: 600; text-decoration: none; transition: opacity .2s; }
    .guide-link:hover { opacity: 0.85; }
    details summary { cursor: pointer; color: var(--color-primary); font-weight: 600; }
    details summary:hover { opacity: 0.8; }
    details[open] summary { margin-bottom: 6px; }
    .skip-link { display: block; text-align: center; margin-top: 16px; color: #888; font-size: 0.85em; text-decoration: none; transition: color .2s; }
    .skip-link:hover { color: var(--color-primary); }
  "
}
