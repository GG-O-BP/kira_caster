import kira_caster/admin/views/layout
import lustre/element.{type Element, fragment}
import lustre/server_component
import wisp.{type Response}

pub fn handle_dashboard() -> Response {
  layout.page(
    title: "kira_caster 관리 대시보드",
    head: dashboard_head(),
    body: dashboard_body(),
    tail: "",
  )
}

fn dashboard_head() -> String {
  "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"
  <> "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"
  <> "<link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&family=Roboto:wght@400;500&display=swap\" rel=\"stylesheet\">"
  <> "<style>"
  <> dashboard_css()
  <> "</style>"
}

fn dashboard_body() -> Element(Nil) {
  fragment([
    server_component.script(),
    server_component.element([server_component.route("/ws/dashboard")], []),
  ])
}

fn dashboard_css() -> String {
  "
    :root {
      --color-primary: #FD719B;
      --gradient-main: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%);
      --gradient-secondary: linear-gradient(92.54deg, #FD719B 5.84%, #FD9371 95.21%);
      --color-success: #00C199;
      --color-error: #F77061;
      --color-info: #3B9FFA;
      --color-text: #54577A;
      --color-border: #E9EAEE;
      --color-bg: #FFFFFF;
      --color-glass: rgba(255,255,255,0.75);
      --font-body: 'Quicksand', Hiragino Sans, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif;
      --font-number: 'Roboto', sans-serif;
      --radius-pill: 20px;
      --radius-card: 12px;
      --radius-input: 8px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font-body); background: var(--color-bg); color: var(--color-text); padding: 20px; }
    h1 { background: var(--gradient-main); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 20px; font-weight: 700; }
    .tabs { display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; }
    .tab { padding: 8px 16px; background: var(--color-bg); border: 1px solid var(--color-border); border-radius: var(--radius-pill); cursor: pointer; color: var(--color-text); font-weight: 600; transition: all .2s; }
    .tab:hover { border-color: var(--color-primary); color: var(--color-primary); }
    .tab.active { background: var(--gradient-main); color: #fff; border-color: transparent; }
    .panel { display: none; background: var(--color-glass); border: 1px solid var(--color-border); border-radius: var(--radius-card); padding: 20px; }
    .panel.active { display: block; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--color-border); }
    th { color: var(--color-primary); font-weight: 600; }
    button { padding: 6px 14px; background: var(--gradient-secondary); color: #fff; border: none; border-radius: var(--radius-pill); cursor: pointer; font-family: inherit; font-weight: 600; transition: opacity .2s; }
    button:hover { opacity: 0.85; }
    button.danger { background: var(--color-error); }
    button.success { background: var(--color-success); }
    input, textarea { padding: 8px 12px; background: var(--color-bg); color: var(--color-text); border: 1px solid var(--color-border); border-radius: var(--radius-input); font-family: inherit; }
    input:focus, textarea:focus { outline: none; border-color: var(--color-primary); }
    select { padding: 8px 12px; border: 1px solid var(--color-border); border-radius: var(--radius-input); font-family: inherit; }
    .form-row { display: flex; gap: 8px; margin-top: 10px; align-items: center; flex-wrap: wrap; }
    td .on { color: var(--color-success); font-weight: 600; }
    td .off { color: var(--color-error); font-weight: 600; }
    .tag { display: inline-block; padding: 2px 8px; margin: 2px; background: rgba(253,113,155,0.15); color: var(--color-primary); border-radius: 10px; font-size: 0.85em; }
    .empty { color: var(--color-border); text-align: center; padding: 20px; }
    .bar-wrap { background: var(--color-border); border-radius: 6px; height: 20px; margin-top: 4px; overflow: hidden; }
    .bar-fill { background: var(--gradient-secondary); height: 100%; border-radius: 6px; transition: width .3s; }
    .vote-result { margin: 8px 0; }
    .vote-label { display: flex; justify-content: space-between; font-size: 0.9em; margin-bottom: 2px; }
    .toast-container { position: fixed; top: 20px; right: 20px; z-index: 1000; }
    .toast { padding: 12px 20px; border-radius: var(--radius-input); color: #fff; font-weight: 600; margin-bottom: 8px; opacity: 0; transform: translateX(100%); transition: all 0.3s ease; font-family: var(--font-body); }
    .toast.show { opacity: 1; transform: translateX(0); }
    .toast.success { background: var(--color-success); }
    .toast.error { background: var(--color-error); }
    .toast.info { background: var(--color-info); }
    @media (max-width: 600px) {
      body { padding: 10px; }
      .tabs { flex-direction: row; overflow-x: auto; flex-wrap: nowrap; position: sticky; top: 0; background: var(--color-bg); z-index: 10; padding-bottom: 8px; }
      .tab { text-align: center; white-space: nowrap; flex-shrink: 0; min-height: 44px; display: flex; align-items: center; justify-content: center; }
      .form-row { flex-direction: column; }
      .form-row input { width: 100%; }
      .panel { padding: 12px; overflow-x: auto; }
      table { font-size: 0.85em; }
      button { min-height: 44px; padding: 10px 18px; }
      input { min-height: 44px; }
    }
  "
}
