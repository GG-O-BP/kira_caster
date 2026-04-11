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
    tail: setup_script(),
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
          text("설정 저장 완료당!"),
        ]),
        html.div([attribute.class("setup-done")], [
          html.div(
            [
              attr(
                "style",
                "width:32px;height:32px;border:3px solid #E9EAEE;border-top-color:#FD719B;border-radius:50%;animation:spin 0.8s linear infinite;margin:16px auto",
              ),
            ],
            [],
          ),
          html.p([], [text("설정 저장했당 잠깐만 기다려줘용...")]),
          html.p(
            [attr("style", "margin-top:12px;font-size:0.85em;color:#888")],
            [text("5초쯤 지나면 자동으로 넘어가니까 이 화면 안 닫아도 돼용 ㅎㅎ")],
          ),
        ]),
      ]),
    ]),
  ])
}

fn setup_script() -> String {
  "<script>function copyUri(btn){var t=document.getElementById('redirect-uri');if(t){navigator.clipboard.writeText(t.textContent).then(function(){btn.textContent='복사했당!';setTimeout(function(){btn.textContent='복사'},2000)}).catch(function(){var r=document.createRange();r.selectNodeContents(t);var s=window.getSelection();s.removeAllRanges();s.addRange(r);document.execCommand('copy');btn.textContent='복사했당!';setTimeout(function(){btn.textContent='복사'},2000)})}}function togglePw(id,btn){var i=document.getElementById(id);if(i){if(i.type==='password'){i.type='text';btn.textContent='숨기긔'}else{i.type='password';btn.textContent='보긔'}}}</script>"
}

fn setup_body(message: String, _is_success: Bool) -> Element(Nil) {
  fragment([
    html.div([attribute.class("setup-container")], [
      html.div([attribute.class("setup-card")], [
        html.h1([attribute.class("setup-title")], [text("kira_caster")]),
        html.p([attribute.class("setup-subtitle")], [
          text("어머 처음이당! 같이 설정하자 ㅎㅎ"),
        ]),
        case message {
          "" -> text("")
          msg -> html.div([attribute.class("setup-error")], [text(msg)])
        },
        html.form([attr("method", "POST"), attr("action", "/setup")], [
          // Step 1: Admin password
          html.div([attribute.class("setup-section")], [
            html.h3([], [text("1. 관리자 비밀번호 정하기")]),
            html.p([attribute.class("setup-hint")], [
              text("대시보드 들어갈 때 쓸 비밀번호야용"),
            ]),
            html.p(
              [
                attr(
                  "style",
                  "font-size:0.82em;color:var(--color-error);margin-bottom:8px;line-height:1.4",
                ),
              ],
              [
                text("비밀번호 안 정하면 아무나 들어올 수 있어서 위험하거든용 ㅠㅠ 꼭 정해줘잉!"),
              ],
            ),
            html.div(
              [
                attr("style", "display:flex;gap:8px;align-items:center"),
              ],
              [
                html.input([
                  attribute.type_("password"),
                  attr("name", "admin_key"),
                  attr("id", "admin-key-input"),
                  attribute.placeholder("비밀번호를 여기에"),
                  attr("style", "flex:1"),
                ]),
                html.button(
                  [
                    attribute.type_("button"),
                    attr("onclick", "togglePw('admin-key-input',this)"),
                    attr(
                      "style",
                      "padding:8px 14px;font-size:0.85em;margin-top:0;white-space:nowrap",
                    ),
                  ],
                  [text("보긔")],
                ),
              ],
            ),
          ]),
          // Step 2: CIME settings
          html.div([attribute.class("setup-section")], [
            html.h3([], [text("2. 씨미(ci.me) 연결하기")]),
            html.p([attribute.class("setup-hint")], [
              text(
                "씨미 방송이랑 연결하면 채팅에서 봇이 자동으로 대답해줘용 지금 안 해도 나중에 할 수 있으니까 걱정 ㄴㄴ!",
              ),
            ]),
            html.div([attribute.class("setup-guide")], [
              html.p([attr("style", "font-weight:600;margin-bottom:6px")], [
                text("준비하는 방법!"),
              ]),
              html.ol([attr("style", "padding-left:20px;line-height:1.8")], [
                html.li([], [
                  text("아래 '씨미 개발자 센터 열기' 버튼 눌러줘용 (씨미 로그인이 필요해용)"),
                ]),
                html.li([], [
                  text("오른쪽 위에 '새 앱 만들기' 버튼 눌러줘용"),
                ]),
                html.li([], [
                  text("앱 이름은 아무거나 넣어도 돼용 ㅎㅎ"),
                ]),
                html.li([], [
                  text("'Redirect URI' 칸에 아래 주소를 복사해서 넣어줘용"),
                ]),
                html.li([], [
                  text("앱 만들면 '앱 ID'랑 '비밀키'가 나오거든용 그거 아래 칸에 넣어주면 돼용"),
                ]),
              ]),
              html.div(
                [
                  attr(
                    "style",
                    "display:flex;gap:8px;align-items:center;margin:10px 0",
                  ),
                ],
                [
                  html.code(
                    [
                      attr("id", "redirect-uri"),
                      attr(
                        "style",
                        "flex:1;padding:6px 10px;background:rgba(253,113,155,0.1);border-radius:4px;font-size:0.88em",
                      ),
                    ],
                    [text("http://localhost:9693/oauth/callback")],
                  ),
                  html.button(
                    [
                      attribute.type_("button"),
                      attr("onclick", "copyUri(this)"),
                      attr(
                        "style",
                        "padding:6px 14px;font-size:0.85em;white-space:nowrap",
                      ),
                    ],
                    [text("복사")],
                  ),
                ],
              ),
              html.a(
                [
                  attribute.href("https://developers.ci.me/applications"),
                  attr("target", "_blank"),
                  attribute.class("guide-link"),
                ],
                [text("씨미 개발자 센터 열기")],
              ),
            ]),
            html.input([
              attr("name", "cime_client_id"),
              attribute.placeholder("앱 ID - 개발자 센터에서 복사한 거"),
            ]),
            html.div(
              [
                attr("style", "display:flex;gap:8px;align-items:center"),
              ],
              [
                html.input([
                  attr("name", "cime_client_secret"),
                  attribute.placeholder("앱 비밀키 - 개발자 센터에서 복사한 거"),
                  attribute.type_("password"),
                  attr("id", "cime-secret-input"),
                  attr("style", "flex:1"),
                ]),
                html.button(
                  [
                    attribute.type_("button"),
                    attr("onclick", "togglePw('cime-secret-input',this)"),
                    attr(
                      "style",
                      "padding:8px 14px;font-size:0.85em;margin-top:0;white-space:nowrap",
                    ),
                  ],
                  [text("보긔")],
                ),
              ],
            ),
            el("details", [], [
              el(
                "summary",
                [
                  attr(
                    "style",
                    "font-size:0.85em;color:var(--color-primary);cursor:pointer;font-weight:600;margin-top:8px",
                  ),
                ],
                [text("이게 뭔뎅??")],
              ),
              html.p([attribute.class("setup-hint")], [
                text(
                  "씨미에서 봇 쓰려면 '앱'을 만들어야 하거든용 새 계정 만드는 거랑 비슷해용 ㅎㅎ 앱 ID랑 비밀키는 봇의 아이디/비밀번호라고 생각하면 돼용! 위에 주소(Redirect URI)는 그냥 복사해서 붙여넣기만 하면 되고, 채널 정보는 연결하면 알아서 가져와용",
                ),
              ]),
            ]),
          ]),
          html.button([attribute.type_("submit")], [text("설정 끝!")]),
          html.div([attr("style", "text-align:center;margin-top:16px")], [
            html.a(
              [
                attribute.href("/setup?skip=true"),
                attribute.class("skip-link"),
              ],
              [text("씨미 없이 일단 시작하긔")],
            ),
            html.p(
              [
                attr("style", "font-size:0.78em;color:#aaa;margin-top:6px"),
              ],
              [
                text("나중에 대시보드에서 언제든 연결할 수 있으니까 걱정 ㄴㄴ용"),
              ],
            ),
          ]),
        ]),
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
    @keyframes spin { to { transform: rotate(360deg); } }
  "
}
