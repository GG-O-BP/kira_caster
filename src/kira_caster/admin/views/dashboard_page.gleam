import kira_caster/admin/views/layout
import lustre/element.{type Element, fragment}
import lustre/server_component
import wisp.{type Response}

pub fn handle_dashboard() -> Response {
  layout.page(
    title: "kira_caster 관리 대시보드",
    head: dashboard_head(),
    body: dashboard_body(),
    tail: code_editor_script(),
  )
}

fn dashboard_head() -> String {
  "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"
  <> "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"
  <> "<link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&family=Roboto:wght@400;500&display=swap\" rel=\"stylesheet\">"
  <> "<style>"
  <> "@font-face { font-family: 'CloudSansCode'; src: url('https://cdn.jsdelivr.net/gh/projectnoonnu/2408@1.0/goorm-sans-code.woff2') format('woff2'); font-weight: normal; font-display: swap; }"
  <> dashboard_css()
  <> "</style>"
}

fn dashboard_body() -> Element(Nil) {
  fragment([
    server_component.script(),
    server_component.element([server_component.route("/ws/dashboard")], []),
  ])
}

fn code_editor_script() -> String {
  "<script type='module'>
import {EditorView, keymap, lineNumbers, highlightActiveLine, highlightActiveLineGutter, highlightSpecialChars, drawSelection, dropCursor, rectangularSelection, crosshairCursor, placeholder as cmPlaceholder} from 'https://esm.sh/@codemirror/view@6';
import {EditorState} from 'https://esm.sh/@codemirror/state@6';
import {syntaxHighlighting, defaultHighlightStyle, indentOnInput, bracketMatching, foldGutter, foldKeymap} from 'https://esm.sh/@codemirror/language@6';
import {defaultKeymap, history, historyKeymap} from 'https://esm.sh/@codemirror/commands@6';
import {closeBrackets, closeBracketsKeymap, autocompletion, completionKeymap} from 'https://esm.sh/@codemirror/autocomplete@6';
import {searchKeymap, highlightSelectionMatches} from 'https://esm.sh/@codemirror/search@6';
import {gleam} from 'https://esm.sh/@exercism/codemirror-lang-gleam@2';
var basicSetup = [
  lineNumbers(), highlightActiveLineGutter(), highlightSpecialChars(), history(),
  foldGutter(), drawSelection(), dropCursor(), EditorState.allowMultipleSelections.of(true),
  indentOnInput(), syntaxHighlighting(defaultHighlightStyle, {fallback: true}),
  bracketMatching(), closeBrackets(), autocompletion(), rectangularSelection(),
  crosshairCursor(), highlightActiveLine(), highlightSelectionMatches(),
  keymap.of([...closeBracketsKeymap, ...defaultKeymap, ...searchKeymap, ...historyKeymap, ...foldKeymap, ...completionKeymap]),
];
class CodeEditorElement extends HTMLElement {
  constructor() { super(); this._value = ''; this._updating = false; }
  connectedCallback() {
    if (Object.prototype.hasOwnProperty.call(this, 'value')) { this._value = this.value; delete this.value; }
    this.addEventListener('input', (e) => { if (e.target !== this) e.stopPropagation(); }, true);
    this.style.display = 'block';
    this.style.marginTop = '10px';
    var root = this.getRootNode();
    var ph = this.getAttribute('placeholder') || '';
    var exts = [
      ...basicSetup,
      gleam(),
      EditorView.updateListener.of((update) => {
        if (update.docChanged && !this._updating) {
          this._value = update.state.doc.toString();
          this.dispatchEvent(new Event('input', {bubbles: true}));
        }
      }),
      EditorView.theme({
        '&': { border: '1px solid #E9EAEE', borderRadius: '8px', fontSize: '14px' },
        '& .cm-content, & .cm-gutters': { fontFamily: \"'CloudSansCode', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace\" },
        '&.cm-focused': { outline: 'none', borderColor: '#FD719B' },
        '.cm-scroller': { minHeight: '200px', overflow: 'auto' },
        '.cm-gutters': { borderRight: '1px solid #E9EAEE', background: '#fafafa' },
        '.cm-activeLine': { background: 'rgba(253,113,155,0.04)' },
        '.cm-activeLineGutter': { background: 'rgba(253,113,155,0.08)' },
      }),
    ];
    if (ph) exts.push(cmPlaceholder(ph));
    this.editor = new EditorView({ doc: this._value, extensions: exts, parent: this, root: root });
  }
  disconnectedCallback() { if (this.editor) { this.editor.destroy(); this.editor = null; } }
  get value() { return this.editor ? this.editor.state.doc.toString() : this._value; }
  set value(v) {
    this._value = v || '';
    if (!this.editor || this.editor.hasFocus || this._value === this.editor.state.doc.toString()) return;
    this._updating = true;
    this.editor.dispatch({ changes: {from: 0, to: this.editor.state.doc.length, insert: this._value} });
    this._updating = false;
  }
}
customElements.define('code-editor', CodeEditorElement);
</script>"
}

fn dashboard_css() -> String {
  "
    :root {
      --color-primary: #FD719B;
      --color-coral: #FD9371;
      --color-light-pink: #FD99B8;
      --gradient-main: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%);
      --gradient-secondary: linear-gradient(92.54deg, #FD719B 5.84%, #FD9371 95.21%);
      --color-success: #00C199;
      --color-warning: #F8C03A;
      --color-error: #F77061;
      --color-info: #3B9FFA;
      --color-link: #007AFF;
      --color-text: #54577A;
      --color-border: #E9EAEE;
      --color-bg: #FFFFFF;
      --color-black: #000000;
      --color-glass: rgba(255,255,255,0.75);
      --color-glass-light: rgba(255,255,255,0.1);
      --color-overlay: rgba(0,0,0,0.5);
      --yuruka-font: 'Quicksand', sans-serif;
      --quicksand-font: 'Quicksand', sans-serif;
      --font-body: Hiragino Sans, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif;
      --font-number: 'Roboto', sans-serif;
      --font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', monospace;
      --radius-pill: 20px;
      --radius-card: 12px;
      --radius-input: 8px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font-body); background: var(--color-bg); color: var(--color-text); padding: 20px; }
    h1 { font-family: var(--yuruka-font); background: var(--gradient-main); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 0; font-weight: 700; }
    .header-row { display: flex; align-items: center; gap: 12px; margin-bottom: 20px; flex-wrap: wrap; }
    .mode-badge { display: inline-block; padding: 4px 12px; border-radius: var(--radius-pill); font-size: 0.75em; font-weight: 600; }
    .mode-badge.cime { background: rgba(0,193,153,0.15); color: var(--color-success); }
    .mode-badge.mock { background: rgba(84,87,122,0.1); color: var(--color-text); }
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
    button.primary { background: var(--gradient-main); }
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
    .toast.warning { background: var(--color-warning); }
    h3 { font-family: var(--yuruka-font); font-weight: 700; }
    a { color: var(--color-link); text-decoration: none; font-weight: 600; transition: color .2s; }
    a:hover { color: var(--color-primary); }
    .dot { display: inline-flex; align-items: center; gap: 6px; font-weight: 600; }
    .dot::before { content: ''; width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
    .dot.green { color: var(--color-success); }
    .dot.green::before { background: var(--color-success); }
    .dot.red { color: var(--color-error); }
    .dot.red::before { background: var(--color-error); }
    .dot.yellow { color: var(--color-warning); }
    .dot.yellow::before { background: var(--color-warning); }
    .category-btn { background: var(--color-bg); color: var(--color-text); border: 1px solid var(--color-border); margin: 4px; transition: all .2s; }
    .category-btn:hover { border-color: var(--color-primary); color: var(--color-primary); background: rgba(253,113,155,0.08); }
    .tab-divider { width: 1px; height: 20px; background: var(--color-border); margin: 0 4px; flex-shrink: 0; align-self: center; }
    .tab-group-label { font-size: 0.75em; color: var(--color-primary); padding: 0 4px; white-space: nowrap; align-self: center; font-weight: 700; letter-spacing: 0.3px; }
    .welcome-card { margin-top:16px; padding:20px; background:rgba(253,113,155,0.06); border:1px solid rgba(253,113,155,0.15); border-radius:var(--radius-card); }
    .welcome-steps { display:flex; flex-direction:column; gap:8px; }
    .welcome-step { display:flex; gap:12px; align-items:center; padding:10px 12px; background:var(--color-bg); border:1px solid var(--color-border); border-radius:var(--radius-input); cursor:pointer; transition:all .2s; }
    .welcome-step:hover { border-color:var(--color-primary); background:rgba(253,113,155,0.04); }
    .welcome-step-num { width:28px; height:28px; background:var(--gradient-secondary); color:#fff; border-radius:50%; display:flex; align-items:center; justify-content:center; font-weight:700; font-size:0.85em; flex-shrink:0; }
    .tag-remove { background: none; color: var(--color-primary); border: none; padding: 0 4px; margin-left: 4px; font-size: 0.85em; min-height: auto; }
    .tag-remove:hover { color: var(--color-error); }
    select:focus { outline: none; border-color: var(--color-primary); }
    .loading-overlay { display: flex; justify-content: center; padding: 40px 0; }
    .spinner { width: 32px; height: 32px; border: 3px solid var(--color-border); border-top-color: var(--color-primary); border-radius: 50%; animation: spin 0.8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    @media (max-width: 600px) {
      body { padding: 10px; }
      .tabs { flex-direction: row; overflow-x: auto; flex-wrap: nowrap; position: sticky; top: 0; background: var(--color-bg); z-index: 10; padding-bottom: 8px; -webkit-overflow-scrolling: touch; scrollbar-width: none; }
      .tabs::-webkit-scrollbar { display: none; }
      .tab { text-align: center; white-space: nowrap; flex-shrink: 0; min-height: 44px; display: flex; align-items: center; justify-content: center; }
      .tab-group-label { display: none; }
      .tab-divider { display: none; }
      .form-row { flex-direction: column; }
      .form-row input { width: 100%; }
      .panel { padding: 12px; overflow-x: auto; }
      table { font-size: 0.85em; }
      button { min-height: 44px; padding: 10px 18px; }
      input { min-height: 44px; }
    }
  "
}
