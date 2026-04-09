import wisp.{type Response}

pub fn handle_dashboard() -> Response {
  let html = "<!DOCTYPE html>
<html lang=\"ko\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>kira_caster 관리 대시보드</title>
  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
  <link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&family=Roboto:wght@400;500&display=swap\" rel=\"stylesheet\">
" <> "<style>" <> dashboard_css() <> "</style>
</head>" <> dashboard_body() <> "</html>"
  wisp.html_response(html, 200)
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
    input { padding: 8px 12px; background: var(--color-bg); color: var(--color-text); border: 1px solid var(--color-border); border-radius: var(--radius-input); font-family: inherit; }
    input:focus { outline: none; border-color: var(--color-primary); }
    .form-row { display: flex; gap: 8px; margin-top: 10px; align-items: center; flex-wrap: wrap; }
    #status-info { font-size: 1.1em; font-family: var(--font-number); }
    td .on { color: var(--color-success); font-weight: 600; }
    td .off { color: var(--color-error); font-weight: 600; }
    .tag { display: inline-block; padding: 2px 8px; margin: 2px; background: rgba(253,113,155,0.15); color: var(--color-primary); border-radius: 10px; font-size: 0.85em; }
    .empty { color: var(--color-border); text-align: center; padding: 20px; }
    .error { color: var(--color-error); text-align: center; padding: 10px; }
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
    .cm-editor { border: 1px solid var(--color-border); border-radius: var(--radius-input); font-size: 0.85em; min-height: 120px; max-height: 300px; overflow: auto; }
    .cm-editor.cm-focused { outline: none; border-color: var(--color-primary); }
    .cm-editor .cm-scroller { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
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

fn dashboard_body() -> String {
  "
<body>
  <h1>kira_caster 관리 대시보드</h1>
  <div class=\"tabs\">
    <div class=\"tab active\" onclick=\"showTab('status',this)\">상태</div>
    <div class=\"tab\" onclick=\"showTab('users',this)\">유저</div>
    <div class=\"tab\" onclick=\"showTab('words',this)\">금칙어</div>
    <div class=\"tab\" onclick=\"showTab('commands',this)\">명령어</div>
    <div class=\"tab\" onclick=\"showTab('quizzes',this)\">퀴즈</div>
    <div class=\"tab\" onclick=\"showTab('votes',this)\">투표</div>
    <div class=\"tab\" onclick=\"showTab('plugins',this)\">플러그인</div>
    <div class=\"tab\" onclick=\"showTab('settings',this)\">설정</div>
    <div class=\"tab\" onclick=\"showTab('songs',this)\">신청곡</div>
    <div class=\"tab\" onclick=\"showTab('cime-auth',this)\">씨미 연동</div>
    <div class=\"tab\" onclick=\"showTab('broadcast',this)\">방송 설정</div>
    <div class=\"tab\" onclick=\"showTab('chat-settings',this)\">채팅 설정</div>
    <div class=\"tab\" onclick=\"showTab('block-manage',this)\">차단 관리</div>
    <div class=\"tab\" onclick=\"showTab('channel-info',this)\">채널 정보</div>
  </div>
  <div id=\"status\" class=\"panel active\"><div id=\"status-info\">로딩중...</div></div>
  <div id=\"users\" class=\"panel\"><div class=\"form-row\"><input id=\"user-search\" placeholder=\"유저 검색...\" oninput=\"filterUsers()\"><button class=\"success\" onclick=\"exportUsers()\">CSV 내보내기</button></div><table id=\"users-table\"><thead><tr><th>유저</th><th>포인트</th><th>출석</th><th>최근출석</th></tr></thead><tbody></tbody></table></div>
  <div id=\"words\" class=\"panel\"><div class=\"form-row\"><input id=\"new-word\" placeholder=\"금칙어\"><button onclick=\"addWord()\">추가</button></div><table id=\"words-table\"><thead><tr><th>단어</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"commands\" class=\"panel\"><div class=\"form-row\"><select id=\"cmd-type\" onchange=\"toggleCmdType()\" style=\"padding:8px;border:1px solid var(--color-border);border-radius:var(--radius-input);font-family:inherit\"><option value=\"text\">텍스트/템플릿</option><option value=\"gleam\">고급 (Gleam)</option></select><input id=\"cmd-name\" placeholder=\"이름\"></div><div id=\"cmd-text-form\" class=\"form-row\"><input id=\"cmd-resp\" placeholder=\"응답 ({{user}}, {{args}} 사용 가능)\" style=\"flex:1\"><button onclick=\"addCmd()\">추가</button></div><div id=\"cmd-gleam-form\" style=\"display:none;margin-top:10px\"><div id=\"cmd-editor\"></div></div><div id=\"cmd-gleam-form2\" class=\"form-row\" style=\"display:none\"><button onclick=\"addAdvancedCmd()\">컴파일 및 추가</button></div><table id=\"cmds-table\"><thead><tr><th>명령어</th><th>유형</th><th>응답/소스</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"quizzes\" class=\"panel\"><div class=\"form-row\"><input id=\"quiz-q\" placeholder=\"문제\"><input id=\"quiz-a\" placeholder=\"정답1,정답2,...\"><input id=\"quiz-r\" placeholder=\"보상\" type=\"number\" value=\"10\" style=\"width:60px\"><button onclick=\"addQuiz()\">추가</button></div><table id=\"quiz-table\"><thead><tr><th>문제</th><th>정답</th><th>보상</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"votes\" class=\"panel\"><div class=\"form-row\"><input id=\"vote-topic\" placeholder=\"투표 주제\"><input id=\"vote-options\" placeholder=\"선택지1,선택지2,...\"><button onclick=\"startVote()\">투표 시작</button></div><div id=\"vote-info\" style=\"margin-top:12px\">로딩중...</div></div>
  <div id=\"plugins\" class=\"panel\"><table id=\"plugins-table\"><thead><tr><th>플러그인</th><th>설명</th><th>상태</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"settings\" class=\"panel\"><div id=\"settings-form\">로딩중...</div></div>
  <div id=\"songs\" class=\"panel\">
    <div style=\"margin-bottom:16px\">
      <h3 style=\"margin-bottom:8px\">현재 재생</h3>
      <div id=\"song-current\" style=\"padding:10px;background:rgba(253,113,155,.1);border-radius:8px;margin-bottom:8px\">없음</div>
      <div class=\"form-row\">
        <button onclick=\"songPrev()\">이전</button>
        <button onclick=\"songReplay()\">처음부터</button>
        <button onclick=\"songNext()\">다음</button>
        <a href=\"/player\" target=\"_blank\" style=\"margin-left:auto;color:var(--color-info);text-decoration:none;font-size:13px\">플레이어 열기</a>
      </div>
    </div>
    <div style=\"margin-bottom:16px\">
      <h3 style=\"margin-bottom:8px\">곡 추가</h3>
      <div class=\"form-row\"><input id=\"song-url\" placeholder=\"YouTube URL\"><button onclick=\"addSong()\">추가</button></div>
    </div>
    <div style=\"margin-bottom:16px\">
      <h3 style=\"margin-bottom:8px\">대기열</h3>
      <table id=\"songs-table\"><thead><tr><th>#</th><th>제목</th><th>신청자</th><th>길이</th><th></th></tr></thead><tbody></tbody></table>
    </div>
    <div>
      <h3 style=\"margin-bottom:8px\">신청곡 설정</h3>
      <div id=\"song-settings-form\"></div>
    </div>
  </div>
  <div id=\"cime-auth\" class=\"panel\">
    <h3 style=\"margin-bottom:12px\">씨미 OAuth 연동</h3>
    <div id=\"cime-auth-status\" style=\"padding:12px;background:rgba(253,113,155,.08);border-radius:8px;margin-bottom:12px\">로딩중...</div>
    <div class=\"form-row\">
      <button class=\"success\" onclick=\"cimeConnect()\">연결하기</button>
      <button class=\"danger\" onclick=\"cimeDisconnect()\">연결 해제</button>
    </div>
  </div>
  <div id=\"broadcast\" class=\"panel\">
    <h3 style=\"margin-bottom:12px\">방송 제목</h3>
    <div class=\"form-row\" style=\"margin-top:0\"><input id=\"bc-title\" placeholder=\"방송 제목\" style=\"flex:1\"><button onclick=\"saveBcTitle()\">변경</button></div>
    <h3 style=\"margin-top:16px;margin-bottom:12px\">태그</h3>
    <div id=\"bc-tags\" style=\"margin-bottom:8px\"></div>
    <div class=\"form-row\" style=\"margin-top:0\"><input id=\"bc-new-tag\" placeholder=\"새 태그\"><button onclick=\"addBcTag()\">추가</button></div>
    <h3 style=\"margin-top:16px;margin-bottom:12px\">카테고리</h3>
    <div id=\"bc-current-cat\" style=\"margin-bottom:8px;font-size:0.9em;color:var(--color-text)\"></div>
    <div class=\"form-row\" style=\"margin-top:0;position:relative\"><input id=\"bc-cat-search\" placeholder=\"카테고리 검색\" oninput=\"searchCategories()\" style=\"flex:1\"><div id=\"bc-cat-dropdown\" style=\"display:none;position:absolute;top:100%;left:0;right:0;background:#fff;border:1px solid var(--color-border);border-radius:var(--radius-input);max-height:200px;overflow-y:auto;z-index:20;margin-top:4px\"></div></div>
  </div>
  <div id=\"chat-settings\" class=\"panel\">
    <h3 style=\"margin-bottom:12px\">채팅 설정</h3>
    <div id=\"chat-settings-form\" style=\"padding:12px;background:rgba(253,113,155,.08);border-radius:8px\">로딩중...</div>
  </div>
  <div id=\"block-manage\" class=\"panel\">
    <h3 style=\"margin-bottom:12px\">차단 관리</h3>
    <div class=\"form-row\" style=\"margin-top:0;margin-bottom:12px\"><input id=\"block-target\" placeholder=\"차단할 채널 ID\"><button class=\"danger\" onclick=\"addBlock()\">차단</button></div>
    <table id=\"block-table\"><thead><tr><th>채널 ID</th><th>닉네임</th><th>차단일</th><th></th></tr></thead><tbody></tbody></table>
  </div>
  <div id=\"channel-info\" class=\"panel\">
    <h3 style=\"margin-bottom:12px\">봇 계정 정보</h3>
    <div id=\"ch-bot-info\" style=\"padding:12px;background:rgba(253,113,155,.08);border-radius:8px;margin-bottom:16px\">로딩중...</div>
    <h3 style=\"margin-bottom:12px\">방송 상태</h3>
    <div id=\"ch-live-status\" style=\"padding:12px;background:rgba(253,113,155,.08);border-radius:8px;margin-bottom:16px\">로딩중...</div>
    <h3 style=\"margin-bottom:12px\">스트림 키</h3>
    <div id=\"ch-stream-key\" style=\"padding:12px;background:rgba(253,113,155,.08);border-radius:8px\">로딩중...</div>
  </div>
  <div id=\"toast-container\" class=\"toast-container\"></div>
  <script>" <> dashboard_js() <> "</script>
</body>"
}

fn dashboard_js() -> String {
  "
    const base = '';
    let activeTab = 'status';
    let autoRefreshInterval = null;
    let allUsers = [];
    var gleamEditor = null;
    var gleamEditorReady = false;

    // Load CM6 + Gleam language via ESM
    async function initGleamEditor(container, initialValue) {
      if (gleamEditorReady) return;
      try {
        var [cmView, cmState, cmLang, cmGleam] = await Promise.all([
          import('https://esm.sh/@codemirror/view@6'),
          import('https://esm.sh/@codemirror/state@6'),
          import('https://esm.sh/@codemirror/language@6'),
          import('https://esm.sh/@exercism/codemirror-lang-gleam@2')
        ]);
        var cmCmds = await import('https://esm.sh/@codemirror/commands@6');
        var cmSearch = await import('https://esm.sh/@codemirror/search@6');

        gleamEditor = new cmView.EditorView({
          doc: initialValue,
          extensions: [
            cmView.lineNumbers(),
            cmView.highlightActiveLine(),
            cmView.highlightSpecialChars(),
            cmView.drawSelection(),
            cmView.keymap.of([
              ...cmCmds.defaultKeymap,
              cmCmds.indentWithTab,
            ]),
            cmState.EditorState.tabSize.of(2),
            cmLang.indentOnInput(),
            cmLang.bracketMatching(),
            cmGleam.gleam(),
            cmView.EditorView.theme({
              '&': { fontSize: '0.9em' },
              '.cm-content': { fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace' },
              '.cm-gutters': { background: '#f8f8f8', borderRight: '1px solid var(--color-border)' },
            }),
          ],
          parent: container,
        });
        gleamEditorReady = true;
      } catch(e) {
        toast('Gleam 에디터 로드에 실패했습니다.', 'error');
      }
    }

    function toast(message, type) {
      type = type || 'success';
      const el = document.createElement('div');
      el.className = 'toast ' + type;
      el.textContent = message;
      document.getElementById('toast-container').appendChild(el);
      requestAnimationFrame(function() { el.classList.add('show'); });
      setTimeout(function() {
        el.classList.remove('show');
        setTimeout(function() { el.remove(); }, 300);
      }, 3000);
    }

    function showTab(name, el) {
      document.querySelectorAll('.panel').forEach(function(p) { p.classList.remove('active'); });
      document.querySelectorAll('.tab').forEach(function(t) { t.classList.remove('active'); });
      document.getElementById(name).classList.add('active');
      if (el) el.classList.add('active');
      activeTab = name;
      load(name);
      startAutoRefresh();
    }

    function startAutoRefresh() {
      if (autoRefreshInterval) clearInterval(autoRefreshInterval);
      var interval = (activeTab === 'status' || activeTab === 'votes' || activeTab === 'songs' || activeTab === 'channel-info') ? 5000 : 15000;
      autoRefreshInterval = setInterval(function() { load(activeTab); }, interval);
    }

    async function api(method, path, body) {
      const opts = {method: method, headers: {'Content-Type': 'application/json'}};
      if (body) opts.body = JSON.stringify(body);
      const r = await fetch(base + path, opts);
      if (!r.ok) throw new Error(r.status);
      return r.json();
    }

    function tags(csv) { return csv.split(',').map(function(t) { return '<span class=\\\"tag\\\">' + t.trim() + '</span>'; }).join(''); }
    function empty(cols) { return '<tr><td colspan=\\\"' + cols + '\\\" class=\\\"empty\\\">데이터가 없습니다</td></tr>'; }
    function esc(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

    function renderUsers(users) {
      document.querySelector('#users-table tbody').innerHTML = users.length ? users.map(function(u) {
        var lastDate = u.last_attendance ? new Date(u.last_attendance).toLocaleDateString('ko-KR') : '-';
        return '<tr><td>' + esc(u.user_id) + '</td><td>' + u.points + '</td><td>' + u.attendance_count + '</td><td>' + lastDate + '</td></tr>';
      }).join('') : empty(4);
    }

    function filterUsers() {
      var q = document.getElementById('user-search').value.toLowerCase();
      var filtered = allUsers.filter(function(u) { return u.user_id.toLowerCase().indexOf(q) !== -1; });
      renderUsers(filtered);
    }

    async function load(tab) {
      try {
      if (tab === 'status') {
        const d = await api('GET', '/status');
        const h = Math.floor(d.uptime_seconds / 3600);
        const m = Math.floor((d.uptime_seconds % 3600) / 60);
        const s = d.uptime_seconds % 60;
        document.getElementById('status-info').innerHTML = '상태: ' + d.status + '<br>가동 시간: ' + h + '시간 ' + m + '분 ' + s + '초';
      } else if (tab === 'users') {
        const d = await api('GET', '/users');
        allUsers = d;
        var q = document.getElementById('user-search').value;
        if (q) { filterUsers(); } else { renderUsers(d); }
      } else if (tab === 'words') {
        const d = await api('GET', '/banned-words');
        document.querySelector('#words-table tbody').innerHTML = d.length ? d.map(function(w) { return '<tr><td>' + esc(w) + '</td><td><button class=\\\"danger\\\" onclick=\\\"delWord(\\'' + esc(w) + '\\')\\\">삭제</button></td></tr>'; }).join('') : empty(2);
      } else if (tab === 'commands') {
        const d = await api('GET', '/commands');
        document.querySelector('#cmds-table tbody').innerHTML = d.length ? d.map(function(c) {
          var typeLabel = c.type === 'gleam' ? '<span class=\\\"tag\\\" style=\\\"background:var(--color-info);color:#fff\\\">Gleam</span>' : '<span class=\\\"tag\\\">텍스트</span>';
          var content = c.type === 'gleam' ? '<code style=\\\"font-size:0.8em\\\">' + esc(c.source_code || '').substring(0, 50) + '...</code>' : esc(c.response);
          var actions = '<button class=\\\"danger\\\" onclick=\\\"delCmd(\\'' + esc(c.name) + '\\')\\\">삭제</button>';
          if (c.type === 'gleam') actions = '<button class=\\\"success\\\" onclick=\\\"compileCmd(\\'' + esc(c.name) + '\\')\\\">재컴파일</button> ' + actions;
          return '<tr><td>!' + esc(c.name) + '</td><td>' + typeLabel + '</td><td>' + content + '</td><td>' + actions + '</td></tr>';
        }).join('') : empty(4);
      } else if (tab === 'quizzes') {
        const d = await api('GET', '/quizzes');
        document.querySelector('#quiz-table tbody').innerHTML = d.length ? d.map(function(q) { return '<tr><td>' + esc(q.question) + '</td><td>' + tags(q.answer) + '</td><td>' + q.reward + 'pt</td><td><button class=\\\"danger\\\" onclick=\\\"delQuiz(\\'' + esc(q.question) + '\\')\\\">삭제</button></td></tr>'; }).join('') : empty(4);
      } else if (tab === 'votes') {
        const d = await api('GET', '/votes');
        if (!d.active) { document.getElementById('vote-info').innerHTML = '<div class=\\\"empty\\\">진행중인 투표가 없습니다.</div>'; return; }
        var total = d.results && d.results.length ? d.results.reduce(function(sum, r) { return sum + r.count; }, 0) : 0;
        var html = '<strong>' + esc(d.topic) + '</strong> <span class=\\\"tag\\\" style=\\\"background:var(--color-success);color:#fff\\\">실시간</span> <button class=\\\"danger\\\" onclick=\\\"endVote()\\\">투표 종료</button>';
        html += '<div style=\\\"margin:8px 0;color:var(--color-text)\\\">총 ' + total + '표</div>';
        if (d.results && d.results.length) {
          html += d.results.map(function(r) {
            var pct = total > 0 ? Math.round(r.count/total*100) : 0;
            return '<div class=\\\"vote-result\\\"><div class=\\\"vote-label\\\"><span>' + esc(r.choice) + '</span><span>' + r.count + '표 (' + pct + '%)</span></div><div class=\\\"bar-wrap\\\"><div class=\\\"bar-fill\\\" style=\\\"width:' + pct + '%\\\"></div></div></div>';
          }).join('');
        } else { html += '<div class=\\\"empty\\\">아직 투표가 없습니다.</div>'; }
        document.getElementById('vote-info').innerHTML = html;
      } else if (tab === 'plugins') {
        const d = await api('GET', '/plugins');
        document.querySelector('#plugins-table tbody').innerHTML = d.map(function(p) { return '<tr><td>' + p.name + '</td><td style=\\\"color:var(--color-text);font-size:0.85em\\\">' + (p.description || '') + '</td><td><span class=\\\"' + (p.enabled ? 'on' : 'off') + '\\\">' + (p.enabled ? 'ON' : 'OFF') + '</span></td><td><button class=\\\"' + (p.enabled ? 'danger' : 'success') + '\\\" onclick=\\\"togglePlugin(\\'' + p.name + '\\', ' + !p.enabled + ')\\\">' + (p.enabled ? '비활성화' : '활성화') + '</button></td></tr>'; }).join('');
      } else if (tab === 'settings') {
        var d = await api('GET', '/settings');
        var defaults = {cooldown_ms:'5000',attendance_points:'10',dice_win_points:'50',dice_loss_points:'-20',rps_win_points:'30',rps_loss_points:'-10'};
        var labels = {cooldown_ms:'쿨다운 (ms)',attendance_points:'출석 포인트',dice_win_points:'주사위 승리 포인트',dice_loss_points:'주사위 패배 포인트',rps_win_points:'가위바위보 승리 포인트',rps_loss_points:'가위바위보 패배 포인트'};
        var saved = {};
        d.forEach(function(s) { saved[s.key] = s.value; });
        var keys = Object.keys(defaults);
        var html = keys.map(function(k) {
          var val = saved[k] || defaults[k];
          return '<div class=\\\"form-row\\\"><label style=\\\"min-width:180px;font-weight:600\\\">' + labels[k] + '</label><input id=\\\"setting-' + k + '\\\" type=\\\"number\\\" value=\\\"' + esc(val) + '\\\" style=\\\"width:100px\\\"><button onclick=\\\"saveSetting(\\'' + k + '\\')\\\">저장</button></div>';
        }).join('');
        document.getElementById('settings-form').innerHTML = html;
      } else if (tab === 'songs') {
        var cur = await api('GET', '/songs/current');
        if (cur.current) {
          document.getElementById('song-current').innerHTML = '<strong>' + esc(cur.current.title) + '</strong> - ' + esc(cur.current.requested_by) + ' (' + fmtDur(cur.current.duration_seconds) + ')';
        } else {
          document.getElementById('song-current').innerHTML = '재생 중인 곡이 없습니다';
        }
        var songs = await api('GET', '/songs');
        var curId = cur.current ? cur.current.id : null;
        document.querySelector('#songs-table tbody').innerHTML = songs.length ? songs.map(function(s, i) {
          var playing = s.id === curId ? ' style=\\\"background:rgba(253,113,155,.12)\\\"' : '';
          return '<tr' + playing + '><td>' + (i+1) + '</td><td>' + esc(s.title) + '</td><td>' + esc(s.requested_by) + '</td><td>' + fmtDur(s.duration_seconds) + '</td><td>'
            + (i > 0 ? '<button onclick=\\\"songMove(' + s.id + ',' + (s.position-1) + ')\\\">▲</button> ' : '')
            + (i < songs.length-1 ? '<button onclick=\\\"songMove(' + s.id + ',' + (s.position+1) + ')\\\">▼</button> ' : '')
            + '<button class=\\\"danger\\\" onclick=\\\"songDel(' + s.id + ')\\\">삭제</button></td></tr>';
        }).join('') : empty(5);
        loadSongSettings();
      } else if (tab === 'cime-auth') {
        var d = await api('GET', '/oauth/status');
        var statusColor = d.authenticated ? 'var(--color-success)' : 'var(--color-error)';
        var statusText = d.authenticated ? '연결됨' : '연결 안 됨';
        var html = '<div style=\\\"display:flex;align-items:center;gap:8px;margin-bottom:8px\\\"><span style=\\\"display:inline-block;width:10px;height:10px;border-radius:50%;background:' + statusColor + '\\\"></span><strong style=\\\"color:' + statusColor + '\\\">' + statusText + '</strong></div>';
        if (d.authenticated && d.expires_at) {
          html += '<div style=\\\"font-size:0.85em;color:var(--color-text)\\\">토큰 만료: ' + new Date(d.expires_at).toLocaleString('ko-KR') + '</div>';
        }
        if (d.authenticated && d.channel_name) {
          html += '<div style=\\\"font-size:0.85em;color:var(--color-text);margin-top:4px\\\">채널: ' + esc(d.channel_name) + '</div>';
        }
        document.getElementById('cime-auth-status').innerHTML = html;
      } else if (tab === 'broadcast') {
        var d = await api('GET', '/cime/live-setting');
        document.getElementById('bc-title').value = d.defaultLiveTitle || '';
        var tagsHtml = (d.tags || []).map(function(t) {
          return '<span class=\\\"tag\\\" style=\\\"cursor:pointer\\\" onclick=\\\"removeBcTag(\\'' + esc(t) + '\\')\\\">' + esc(t) + ' x</span>';
        }).join(' ');
        document.getElementById('bc-tags').innerHTML = tagsHtml || '<span class=\\\"empty\\\" style=\\\"padding:4px\\\">태그 없음</span>';
        document.getElementById('bc-current-cat').innerHTML = d.categoryName ? '현재: <strong>' + esc(d.categoryName) + '</strong>' : '카테고리 미설정';
        window._bcCurrentTags = d.tags || [];
      } else if (tab === 'chat-settings') {
        var d = await api('GET', '/cime/chat-settings');
        var slowChecked = d.slowMode ? ' checked' : '';
        var followerChecked = d.allowedGroup === 'FOLLOWER' ? ' checked' : '';
        var html = '<div class=\\\"form-row\\\" style=\\\"margin-top:0\\\"><label style=\\\"min-width:160px;font-weight:600\\\">슬로우 모드</label><input type=\\\"checkbox\\\" id=\\\"cs-slow\\\"' + slowChecked + ' style=\\\"width:auto;min-height:auto\\\"><input id=\\\"cs-slow-sec\\\" type=\\\"number\\\" value=\\\"' + (d.slowModeSeconds || 5) + '\\\" style=\\\"width:80px\\\" placeholder=\\\"초\\\"><span style=\\\"font-size:0.85em\\\">초</span></div>';
        html += '<div class=\\\"form-row\\\"><label style=\\\"min-width:160px;font-weight:600\\\">팔로워 전용</label><input type=\\\"checkbox\\\" id=\\\"cs-follower\\\"' + followerChecked + ' style=\\\"width:auto;min-height:auto\\\"></div>';
        html += '<div class=\\\"form-row\\\" style=\\\"margin-top:12px\\\"><button onclick=\\\"saveChatSettings()\\\">저장</button></div>';
        document.getElementById('chat-settings-form').innerHTML = html;
      } else if (tab === 'block-manage') {
        var d = await api('GET', '/cime/blocked-users');
        document.querySelector('#block-table tbody').innerHTML = d.length ? d.map(function(b) {
          var date = b.blockedAt ? new Date(b.blockedAt).toLocaleDateString('ko-KR') : '-';
          return '<tr><td>' + esc(b.channelId || '') + '</td><td>' + esc(b.nickname || '') + '</td><td>' + date + '</td><td><button class=\\\"danger\\\" onclick=\\\"removeBlock(\\'' + esc(b.channelId) + '\\')\\\">해제</button></td></tr>';
        }).join('') : empty(4);
      } else if (tab === 'channel-info') {
        var ch = await api('GET', '/cime/channel-info');
        var chHtml = '<div style=\\\"display:flex;align-items:center;gap:12px\\\">';
        if (ch.imageUrl) chHtml += '<img src=\\\"' + esc(ch.imageUrl) + '\\\" style=\\\"width:48px;height:48px;border-radius:50%;border:2px solid var(--color-primary)\\\">';
        chHtml += '<div><div style=\\\"font-weight:700\\\">' + esc(ch.name || '-') + '</div><div style=\\\"font-size:0.85em;color:var(--color-text)\\\">' + esc(ch.handle || '') + '</div></div></div>';
        document.getElementById('ch-bot-info').innerHTML = chHtml;
        var live = await api('GET', '/cime/live-status');
        var liveColor = live.isLive ? 'var(--color-success)' : 'var(--color-error)';
        var liveText = live.isLive ? '방송 중' : '오프라인';
        var liveHtml = '<div style=\\\"display:flex;align-items:center;gap:8px\\\"><span style=\\\"display:inline-block;width:10px;height:10px;border-radius:50%;background:' + liveColor + '\\\"></span><strong style=\\\"color:' + liveColor + '\\\">' + liveText + '</strong></div>';
        if (live.isLive && live.title) liveHtml += '<div style=\\\"font-size:0.85em;margin-top:4px\\\">' + esc(live.title) + '</div>';
        if (live.isLive && live.viewerCount !== undefined) liveHtml += '<div style=\\\"font-size:0.85em;margin-top:2px\\\">시청자: ' + live.viewerCount + '명</div>';
        document.getElementById('ch-live-status').innerHTML = liveHtml;
        try {
          var sk = await api('GET', '/cime/stream-key');
          document.getElementById('ch-stream-key').innerHTML = '<div style=\\\"display:flex;align-items:center;gap:8px\\\"><code id=\\\"sk-value\\\" style=\\\"letter-spacing:2px\\\">********</code><button onclick=\\\"toggleStreamKey()\\\">표시</button></div>';
          window._streamKey = sk.streamKey || '';
          window._streamKeyVisible = false;
        } catch(e) { document.getElementById('ch-stream-key').innerHTML = '<span class=\\\"empty\\\">스트림 키를 가져올 수 없습니다</span>'; }
      }
      } catch(e) { }
    }

    function fmtDur(sec) {
      if (!sec) return '0:00';
      var h = Math.floor(sec/3600), m = Math.floor((sec%3600)/60), s = sec%60;
      return h > 0 ? h+':'+String(m).padStart(2,'0')+':'+String(s).padStart(2,'0') : m+':'+String(s).padStart(2,'0');
    }

    async function addWord() {
      try {
        var v = document.getElementById('new-word').value.trim();
        if (!v) { toast('금칙어를 입력해주세요.', 'error'); return; }
        await api('POST', '/banned-words', {word: v});
        document.getElementById('new-word').value = '';
        toast('금칙어가 추가되었습니다.', 'success');
        load('words');
      } catch(e) { toast('금칙어 추가에 실패했습니다.', 'error'); }
    }
    async function delWord(w) {
      if (!confirm('삭제할까요?')) return;
      try {
        await api('DELETE', '/banned-words', {word: w});
        toast('금칙어가 삭제되었습니다.', 'success');
        load('words');
      } catch(e) { toast('삭제에 실패했습니다.', 'error'); }
    }
    async function addCmd() {
      try {
        var n = document.getElementById('cmd-name').value.trim();
        var r = document.getElementById('cmd-resp').value.trim();
        if (!n || !r) { toast('이름과 응답을 모두 입력해주세요.', 'error'); return; }
        await api('POST', '/commands', {name: n, response: r});
        document.getElementById('cmd-name').value = '';
        document.getElementById('cmd-resp').value = '';
        toast('명령어가 추가되었습니다.', 'success');
        load('commands');
      } catch(e) { toast('명령어 추가에 실패했습니다.', 'error'); }
    }
    async function delCmd(n) {
      if (!confirm('삭제할까요?')) return;
      try {
        await api('DELETE', '/commands', {name: n});
        toast('명령어가 삭제되었습니다.', 'success');
        load('commands');
      } catch(e) { toast('삭제에 실패했습니다.', 'error'); }
    }
    async function addQuiz() {
      try {
        var q = document.getElementById('quiz-q').value.trim();
        var a = document.getElementById('quiz-a').value.trim();
        var r = parseInt(document.getElementById('quiz-r').value) || 0;
        if (!q || !a) { toast('문제와 정답을 모두 입력해주세요.', 'error'); return; }
        if (r <= 0) { toast('보상은 양수여야 합니다.', 'error'); return; }
        await api('POST', '/quizzes', {question: q, answer: a, reward: r});
        document.getElementById('quiz-q').value = '';
        document.getElementById('quiz-a').value = '';
        toast('퀴즈가 추가되었습니다.', 'success');
        load('quizzes');
      } catch(e) { toast('퀴즈 추가에 실패했습니다.', 'error'); }
    }
    async function delQuiz(q) {
      if (!confirm('삭제할까요?')) return;
      try {
        await api('DELETE', '/quizzes', {question: q});
        toast('퀴즈가 삭제되었습니다.', 'success');
        load('quizzes');
      } catch(e) { toast('삭제에 실패했습니다.', 'error'); }
    }
    async function togglePlugin(n, enabled) {
      try {
        await api('POST', '/plugins', {name: n, enabled: enabled});
        toast(n + ' 플러그인이 ' + (enabled ? '활성화' : '비활성화') + '되었습니다.', 'success');
        load('plugins');
      } catch(e) { toast('플러그인 변경에 실패했습니다.', 'error'); }
    }
    async function startVote() {
      try {
        var t = document.getElementById('vote-topic').value.trim();
        var o = document.getElementById('vote-options').value.split(',').map(function(s) { return s.trim(); }).filter(function(s) { return s; });
        if (!t || o.length < 2) { toast('주제와 2개 이상의 선택지를 입력해주세요.', 'error'); return; }
        await api('POST', '/votes', {topic: t, options: o});
        document.getElementById('vote-topic').value = '';
        document.getElementById('vote-options').value = '';
        toast('투표가 시작되었습니다.', 'success');
        load('votes');
      } catch(e) { toast('투표 시작에 실패했습니다.', 'error'); }
    }
    async function endVote() {
      if (!confirm('투표를 종료할까요?')) return;
      try {
        await api('DELETE', '/votes');
        toast('투표가 종료되었습니다.', 'success');
        load('votes');
      } catch(e) { toast('투표 종료에 실패했습니다.', 'error'); }
    }

    function toggleCmdType() {
      var type = document.getElementById('cmd-type').value;
      document.getElementById('cmd-text-form').style.display = type === 'text' ? 'flex' : 'none';
      document.getElementById('cmd-gleam-form').style.display = type === 'gleam' ? 'block' : 'none';
      document.getElementById('cmd-gleam-form2').style.display = type === 'gleam' ? 'flex' : 'none';
      if (type === 'gleam' && !gleamEditorReady) {
        var defaultCode = 'import gleam/string\\n\\npub fn handle(user: String, args: List(String)) -> String {\\n  case args {\\n    _ -> user <> \"님 안녕!\"\\n  }\\n}\\n';
        initGleamEditor(document.getElementById('cmd-editor'), defaultCode);
      }
    }

    async function addAdvancedCmd() {
      try {
        var n = document.getElementById('cmd-name').value.trim();
        var src = gleamEditor.state.doc.toString();
        if (!n || !src.trim()) { toast('이름과 소스 코드를 입력해주세요.', 'error'); return; }
        var result = await api('POST', '/commands/advanced', {name: n, source_code: src});
        if (result.compiled) {
          toast('고급 명령 \\'' + n + '\\' 컴파일 및 등록 완료!', 'success');
        } else {
          toast('저장됨, 컴파일 실패: ' + (result.error || ''), 'error');
        }
        document.getElementById('cmd-name').value = '';
        if (gleamEditor) gleamEditor.dispatch({changes: {from: 0, to: gleamEditor.state.doc.length, insert: ''}});
        load('commands');
      } catch(e) { toast('고급 명령 추가에 실패했습니다.', 'error'); }
    }

    async function compileCmd(n) {
      try {
        var result = await api('POST', '/commands/compile', {name: n});
        if (result.compiled) {
          toast(n + ' 재컴파일 성공!', 'success');
        } else {
          toast('재컴파일 실패: ' + (result.error || ''), 'error');
        }
      } catch(e) { toast('재컴파일에 실패했습니다.', 'error'); }
    }

    async function saveSetting(key) {
      try {
        var val = document.getElementById('setting-' + key).value.trim();
        if (!val) { toast('값을 입력해주세요.', 'error'); return; }
        await api('POST', '/settings', {key: key, value: val});
        toast(key + ' 설정이 저장되었습니다.', 'success');
      } catch(e) { toast('설정 저장에 실패했습니다.', 'error'); }
    }

    function exportCSV(data, columns, labels, filename) {
      var header = labels.join(',');
      var rows = data.map(function(row) {
        return columns.map(function(c) { return '\"' + String(row[c] || '').replace(/\"/g, '\"\"') + '\"'; }).join(',');
      });
      var csv = [header].concat(rows).join('\\n');
      var blob = new Blob(['\\uFEFF' + csv], {type: 'text/csv;charset=utf-8;'});
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url; a.download = filename; a.click();
      URL.revokeObjectURL(url);
    }

    function exportUsers() { exportCSV(allUsers, ['user_id','points','attendance_count'], ['유저','포인트','출석'], 'users.csv'); }

    // --- Song request functions ---
    async function songNext() {
      try { await api('POST', '/songs/next'); toast('다음 곡으로 이동', 'success'); load('songs'); } catch(e) { toast('오류', 'error'); }
    }
    async function songPrev() {
      try { await api('POST', '/songs/previous'); toast('이전 곡으로 이동', 'success'); load('songs'); } catch(e) { toast('오류', 'error'); }
    }
    async function songReplay() {
      try { await api('POST', '/songs/replay'); toast('처음부터 재생', 'success'); load('songs'); } catch(e) { toast('오류', 'error'); }
    }
    async function songDel(id) {
      if (!confirm('이 곡을 삭제할까요?')) return;
      try { await api('DELETE', '/songs', {id: id}); toast('삭제됨', 'success'); load('songs'); } catch(e) { toast('삭제 실패', 'error'); }
    }
    async function songMove(id, newPos) {
      try { await api('POST', '/songs/reorder', {id: id, new_position: newPos}); load('songs'); } catch(e) { toast('이동 실패', 'error'); }
    }
    async function addSong() {
      var url = document.getElementById('song-url').value.trim();
      if (!url) { toast('URL을 입력해주세요.', 'error'); return; }
      var vid = parseVideoId(url);
      if (!vid) { toast('유효하지 않은 YouTube URL입니다.', 'error'); return; }
      try {
        await api('POST', '/songs', {video_id: vid, title: vid, duration_seconds: 0, requested_by: 'dashboard'});
        document.getElementById('song-url').value = '';
        toast('곡이 추가되었습니다.', 'success');
        load('songs');
      } catch(e) { toast('추가 실패', 'error'); }
    }
    function parseVideoId(url) {
      var m = url.match(/(?:youtube\\.com\\/(?:watch\\?v=|embed\\/)|youtu\\.be\\/)([\\w-]{11})/);
      if (m) return m[1];
      if (/^[\\w-]{11}$/.test(url)) return url;
      return null;
    }
    var songSettingsDefs = {
      song_max_per_user: {label:'유저당 최대 신청 수', def:'1', type:'number'},
      song_count_playing: {label:'재생 중인 곡도 제한에 포함', def:'false', type:'bool'},
      song_cost_points: {label:'신청 포인트 비용 (0=무료)', def:'0', type:'number'},
      song_prevent_duplicate: {label:'중복 곡 방지', def:'false', type:'bool'},
      song_max_duration: {label:'최대 영상 길이(초, 0=무제한)', def:'0', type:'number'}
    };
    async function loadSongSettings() {
      var d = await api('GET', '/settings');
      var saved = {};
      d.forEach(function(s) { saved[s.key] = s.value; });
      var html = Object.keys(songSettingsDefs).map(function(k) {
        var def = songSettingsDefs[k];
        var val = saved[k] || def.def;
        if (def.type === 'bool') {
          return '<div class=\\\"form-row\\\"><label style=\\\"min-width:200px;font-weight:600\\\">' + def.label + '</label><select id=\\\"ss-' + k + '\\\" style=\\\"padding:6px;border:1px solid var(--color-border);border-radius:4px\\\"><option value=\\\"false\\\"' + (val !== 'true' ? ' selected' : '') + '>아니오</option><option value=\\\"true\\\"' + (val === 'true' ? ' selected' : '') + '>예</option></select><button onclick=\\\"saveSongSetting(\\'' + k + '\\')\\\">저장</button></div>';
        }
        return '<div class=\\\"form-row\\\"><label style=\\\"min-width:200px;font-weight:600\\\">' + def.label + '</label><input id=\\\"ss-' + k + '\\\" type=\\\"number\\\" value=\\\"' + esc(val) + '\\\" style=\\\"width:100px\\\"><button onclick=\\\"saveSongSetting(\\'' + k + '\\')\\\">저장</button></div>';
      }).join('');
      document.getElementById('song-settings-form').innerHTML = html;
    }
    async function saveSongSetting(key) {
      var el = document.getElementById('ss-' + key);
      var val = el.tagName === 'SELECT' ? el.value : el.value;
      try { await api('POST', '/settings', {key: key, value: val}); toast('설정 저장됨', 'success'); } catch(e) { toast('저장 실패', 'error'); }
    }

    // --- Cime Auth functions ---
    function cimeConnect() {
      window.open(base + '/oauth/authorize', '_blank');
    }
    async function cimeDisconnect() {
      if (!confirm('씨미 연동을 해제할까요?')) return;
      try { await api('POST', '/oauth/disconnect'); toast('연동이 해제되었습니다.', 'success'); load('cime-auth'); } catch(e) { toast('연동 해제에 실패했습니다.', 'error'); }
    }

    // --- Broadcast setting functions ---
    async function saveBcTitle() {
      var title = document.getElementById('bc-title').value.trim();
      if (!title) { toast('방송 제목을 입력해주세요.', 'error'); return; }
      try { await api('PATCH', '/cime/live-setting', {defaultLiveTitle: title}); toast('방송 제목이 변경되었습니다.', 'success'); } catch(e) { toast('변경에 실패했습니다.', 'error'); }
    }
    async function addBcTag() {
      var tag = document.getElementById('bc-new-tag').value.trim();
      if (!tag) { toast('태그를 입력해주세요.', 'error'); return; }
      var tags = (window._bcCurrentTags || []).slice();
      if (tags.indexOf(tag) !== -1) { toast('이미 존재하는 태그입니다.', 'error'); return; }
      tags.push(tag);
      try { await api('PATCH', '/cime/live-setting', {tags: tags}); document.getElementById('bc-new-tag').value = ''; toast('태그가 추가되었습니다.', 'success'); load('broadcast'); } catch(e) { toast('태그 추가에 실패했습니다.', 'error'); }
    }
    async function removeBcTag(tag) {
      var tags = (window._bcCurrentTags || []).filter(function(t) { return t !== tag; });
      try { await api('PATCH', '/cime/live-setting', {tags: tags}); toast('태그가 삭제되었습니다.', 'success'); load('broadcast'); } catch(e) { toast('태그 삭제에 실패했습니다.', 'error'); }
    }
    var _catSearchTimer = null;
    function searchCategories() {
      clearTimeout(_catSearchTimer);
      var kw = document.getElementById('bc-cat-search').value.trim();
      var dd = document.getElementById('bc-cat-dropdown');
      if (!kw) { dd.style.display = 'none'; return; }
      _catSearchTimer = setTimeout(async function() {
        try {
          var d = await api('GET', '/cime/categories?keyword=' + encodeURIComponent(kw));
          if (!d.length) { dd.innerHTML = '<div style=\\\"padding:8px;color:var(--color-text);font-size:0.85em\\\">결과 없음</div>'; dd.style.display = 'block'; return; }
          dd.innerHTML = d.map(function(c) {
            return '<div style=\\\"padding:8px 12px;cursor:pointer;font-size:0.9em;border-bottom:1px solid var(--color-border)\\\" onmouseover=\\\"this.style.background=\\'.rgba(253,113,155,.08)\\'\\\" onmouseout=\\\"this.style.background=\\'\\' \\\" onclick=\\\"selectCategory(\\'' + esc(c.id) + '\\',\\'' + esc(c.name) + '\\')\\\">' + esc(c.name) + '</div>';
          }).join('');
          dd.style.display = 'block';
        } catch(e) { dd.style.display = 'none'; }
      }, 300);
    }
    async function selectCategory(id, name) {
      try {
        await api('PATCH', '/cime/live-setting', {categoryId: id});
        document.getElementById('bc-cat-dropdown').style.display = 'none';
        document.getElementById('bc-cat-search').value = '';
        toast('카테고리가 변경되었습니다: ' + name, 'success');
        load('broadcast');
      } catch(e) { toast('카테고리 변경에 실패했습니다.', 'error'); }
    }

    // --- Chat settings functions ---
    async function saveChatSettings() {
      var slow = document.getElementById('cs-slow').checked;
      var sec = parseInt(document.getElementById('cs-slow-sec').value) || 5;
      var follower = document.getElementById('cs-follower').checked;
      var body = {slowMode: slow, slowModeSeconds: sec, allowedGroup: follower ? 'FOLLOWER' : 'ALL'};
      try { await api('PUT', '/cime/chat-settings', body); toast('채팅 설정이 저장되었습니다.', 'success'); load('chat-settings'); } catch(e) { toast('채팅 설정 저장에 실패했습니다.', 'error'); }
    }

    // --- Block management functions ---
    async function addBlock() {
      var target = document.getElementById('block-target').value.trim();
      if (!target) { toast('차단할 채널 ID를 입력해주세요.', 'error'); return; }
      try { await api('POST', '/cime/block', {targetChannelId: target}); document.getElementById('block-target').value = ''; toast('차단되었습니다.', 'success'); load('block-manage'); } catch(e) { toast('차단에 실패했습니다.', 'error'); }
    }
    async function removeBlock(channelId) {
      if (!confirm('차단을 해제할까요?')) return;
      try { await api('DELETE', '/cime/block', {targetChannelId: channelId}); toast('차단이 해제되었습니다.', 'success'); load('block-manage'); } catch(e) { toast('차단 해제에 실패했습니다.', 'error'); }
    }

    // --- Channel info functions ---
    function toggleStreamKey() {
      var el = document.getElementById('sk-value');
      if (window._streamKeyVisible) {
        el.textContent = '********';
        window._streamKeyVisible = false;
      } else {
        el.textContent = window._streamKey || '(없음)';
        window._streamKeyVisible = true;
      }
    }

    load('status');
    startAutoRefresh();
  "
}
