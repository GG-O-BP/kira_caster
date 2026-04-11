import kira_caster/admin/views/layout
import lustre/attribute.{attribute as attr}
import lustre/element.{type Element, element as el, fragment, text}
import lustre/element/html
import wisp.{type Response}

pub fn handle_login(error_message: String) -> Response {
  layout.page(
    title: "kira_caster 로그인",
    head: login_head(),
    body: login_body(error_message),
    tail: "<script>function togglePw(){var i=document.getElementById('login-pw');var b=event.target;if(i){if(i.type==='password'){i.type='text';b.textContent='숨기기'}else{i.type='password';b.textContent='보기'}}}</script>",
  )
}

fn login_head() -> String {
  "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"
  <> "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"
  <> "<link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&display=swap\" rel=\"stylesheet\">"
  <> "<style>"
  <> login_css()
  <> "</style>"
}

fn login_body(error_message: String) -> Element(Nil) {
  fragment([
    html.div([attribute.class("login-container")], [
      html.div([attribute.class("login-card")], [
        html.h1([attribute.class("login-title")], [text("kira_caster")]),
        html.p([attribute.class("login-subtitle")], [
          text("관리 대시보드에 접속하려면 비밀번호를 입력해주세요"),
        ]),
        case error_message {
          "" -> text("")
          msg -> html.div([attribute.class("login-error")], [text(msg)])
        },
        html.form([attr("method", "POST"), attr("action", "/login")], [
          html.div(
            [
              attr("style", "display:flex;gap:8px;align-items:center"),
            ],
            [
              html.input([
                attribute.type_("password"),
                attr("name", "password"),
                attr("id", "login-pw"),
                attribute.placeholder("비밀번호"),
                attr("autofocus", ""),
                attr("required", ""),
                attr("style", "flex:1"),
              ]),
              html.button(
                [
                  attribute.type_("button"),
                  attr("onclick", "togglePw()"),
                  attr(
                    "style",
                    "padding:8px 14px;font-size:0.85em;white-space:nowrap",
                  ),
                ],
                [text("보기")],
              ),
            ],
          ),
          html.button([attribute.type_("submit")], [text("로그인")]),
        ]),
        html.div([attr("style", "margin-top:20px;text-align:center")], [
          el("details", [], [
            el(
              "summary",
              [
                attr(
                  "style",
                  "font-size:0.85em;color:#888;cursor:pointer;list-style:none",
                ),
              ],
              [text("비밀번호를 잊으셨나요?")],
            ),
            html.div(
              [
                attr(
                  "style",
                  "font-size:0.82em;color:#888;margin-top:8px;line-height:1.8;text-align:left",
                ),
              ],
              [
                html.p([attr("style", "margin-bottom:6px")], [
                  text("비밀번호를 초기화하는 방법:"),
                ]),
                html.ol([attr("style", "padding-left:20px;margin-bottom:8px")], [
                  html.li([], [text("프로그램을 종료하세요")]),
                  html.li([], [
                    text("같은 폴더에 있는 "),
                    html.code(
                      [
                        attr(
                          "style",
                          "background:rgba(253,113,155,0.1);padding:2px 6px;border-radius:4px",
                        ),
                      ],
                      [text("kira_caster.db")],
                    ),
                    text(" 파일의 이름을 "),
                    html.code(
                      [
                        attr(
                          "style",
                          "background:rgba(253,113,155,0.1);padding:2px 6px;border-radius:4px",
                        ),
                      ],
                      [text("kira_caster.db.backup")],
                    ),
                    text("으로 변경하세요"),
                  ]),
                  html.li([], [
                    text("프로그램을 다시 시작하면 초기 설정 화면이 나타납니다"),
                  ]),
                ]),
                html.p([attr("style", "color:#aaa;font-size:0.95em")], [
                  text("원래 파일(.backup)은 남아있으니 필요하면 되돌릴 수 있습니다."),
                ]),
              ],
            ),
          ]),
        ]),
      ]),
    ]),
  ])
}

fn login_css() -> String {
  "
    :root {
      --color-primary: #FD719B;
      --gradient-main: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%);
      --gradient-secondary: linear-gradient(92.54deg, #FD719B 5.84%, #FD9371 95.21%);
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
    .login-container { display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }
    .login-card { width: 100%; max-width: 380px; background: var(--color-bg); border: 1px solid var(--color-border); border-radius: var(--radius-card); padding: 40px 32px; text-align: center; }
    .login-title { font-family: 'Quicksand', sans-serif; background: var(--gradient-main); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; font-weight: 700; font-size: 2em; margin-bottom: 8px; }
    .login-subtitle { color: var(--color-text); font-size: 0.9em; margin-bottom: 24px; line-height: 1.5; }
    .login-error { background: rgba(247,112,97,0.1); color: var(--color-error); padding: 10px 14px; border-radius: var(--radius-input); margin-bottom: 16px; font-size: 0.9em; font-weight: 600; }
    form { display: flex; flex-direction: column; gap: 12px; }
    input[type='password'], input[type='text'] { padding: 12px 16px; border: 1px solid var(--color-border); border-radius: var(--radius-input); font-family: inherit; font-size: 1em; text-align: center; }
    input[type='password']:focus, input[type='text']:focus { outline: none; border-color: var(--color-primary); }
    button { padding: 12px; background: var(--gradient-secondary); color: #fff; border: none; border-radius: var(--radius-pill); cursor: pointer; font-family: inherit; font-weight: 600; font-size: 1em; transition: opacity .2s; }
    button:hover { opacity: 0.85; }
  "
}
