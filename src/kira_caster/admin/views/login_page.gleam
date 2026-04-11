import kira_caster/admin/views/layout
import lustre/attribute.{attribute as attr}
import lustre/element.{type Element, fragment, text}
import lustre/element/html
import wisp.{type Response}

pub fn handle_login(error_message: String) -> Response {
  layout.page(
    title: "kira_caster 로그인",
    head: login_head(),
    body: login_body(error_message),
    tail: "",
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
          html.input([
            attribute.type_("password"),
            attr("name", "password"),
            attribute.placeholder("비밀번호"),
            attr("autofocus", ""),
            attr("required", ""),
          ]),
          html.button([attribute.type_("submit")], [text("로그인")]),
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
    input[type='password'] { padding: 12px 16px; border: 1px solid var(--color-border); border-radius: var(--radius-input); font-family: inherit; font-size: 1em; text-align: center; }
    input[type='password']:focus { outline: none; border-color: var(--color-primary); }
    button { padding: 12px; background: var(--gradient-secondary); color: #fff; border: none; border-radius: var(--radius-pill); cursor: pointer; font-family: inherit; font-weight: 600; font-size: 1em; transition: opacity .2s; }
    button:hover { opacity: 0.85; }
  "
}
