import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/string
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  repo: Repository,
  start_time: Int,
  admin_key: String,
) -> Response {
  case check_auth(req, admin_key) {
    False -> wisp.response(401) |> wisp.string_body("Unauthorized")
    True -> route(req, repo, start_time)
  }
}

fn check_auth(req: Request, admin_key: String) -> Bool {
  case admin_key {
    "" -> True
    key -> {
      case request.get_header(req, "authorization") {
        Ok(value) -> value == "Bearer " <> key
        Error(_) -> False
      }
    }
  }
}

fn route(req: Request, repo: Repository, start_time: Int) -> Response {
  case req.method, request.path_segments(req) {
    http.Get, ["status"] -> handle_status(start_time)
    http.Get, ["users"] -> handle_users(repo)
    http.Get, ["banned-words"] -> handle_banned_words(repo)
    http.Get, ["commands"] -> handle_commands(repo)
    http.Post, ["banned-words"] -> handle_add_banned_word(req, repo)
    http.Delete, ["banned-words"] -> handle_remove_banned_word(req, repo)
    http.Post, ["commands"] -> handle_set_command(req, repo)
    http.Delete, ["commands"] -> handle_delete_command(req, repo)
    http.Get, ["votes"] -> handle_get_votes(repo)
    http.Post, ["votes"] -> handle_start_vote(req, repo)
    http.Delete, ["votes"] -> handle_end_vote(repo)
    http.Get, ["quizzes"] -> handle_get_quizzes(repo)
    http.Post, ["quizzes"] -> handle_add_quiz(req, repo)
    http.Delete, ["quizzes"] -> handle_delete_quiz(req, repo)
    http.Get, ["plugins"] -> handle_get_plugins(repo)
    http.Post, ["plugins"] -> handle_set_plugin(req, repo)
    http.Get, [] -> handle_dashboard()
    _, _ -> wisp.not_found()
  }
}

fn handle_status(start_time: Int) -> Response {
  let uptime_s = { time.now_ms() - start_time } / 1000
  let body =
    json.object([
      #("status", json.string("running")),
      #("uptime_seconds", json.int(uptime_s)),
    ])
  wisp.json_response(json.to_string(body), 200)
}

fn handle_users(repo: Repository) -> Response {
  case repo.get_all_users() {
    Ok(users) -> {
      let body =
        json.array(users, fn(u) {
          json.object([
            #("user_id", json.string(u.user_id)),
            #("points", json.int(u.points)),
            #("attendance_count", json.int(u.attendance_count)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_banned_words(repo: Repository) -> Response {
  case repo.get_banned_words() {
    Ok(words) -> {
      let body = json.array(words, json.string)
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_commands(repo: Repository) -> Response {
  case repo.get_all_commands() {
    Ok(commands) -> {
      let body =
        json.array(commands, fn(c) {
          json.object([
            #("name", json.string(c.0)),
            #("response", json.string(c.1)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_add_banned_word(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("word", decode.string, fn(w) { decode.success(w) })
  case decode.run(body, decoder) {
    Ok(word) ->
      case repo.add_banned_word(string.lowercase(word)) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("added", json.string(word))])),
            201,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_remove_banned_word(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("word", decode.string, fn(w) { decode.success(w) })
  case decode.run(body, decoder) {
    Ok(word) ->
      case repo.remove_banned_word(string.lowercase(word)) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("removed", json.string(word))])),
            200,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_set_command(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use name <- decode.field("name", decode.string)
    use response <- decode.field("response", decode.string)
    decode.success(#(name, response))
  }
  case decode.run(body, decoder) {
    Ok(#(name, response)) ->
      case repo.set_command(name, response) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("name", json.string(name)),
                #("response", json.string(response)),
              ]),
            ),
            201,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_delete_command(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = decode.field("name", decode.string, fn(n) { decode.success(n) })
  case decode.run(body, decoder) {
    Ok(name) ->
      case repo.delete_command(name) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("deleted", json.string(name))])),
            200,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_get_votes(repo: Repository) -> Response {
  case repo.get_active_vote() {
    Ok(#(topic, options)) -> {
      let results = case repo.get_vote_results() {
        Ok(r) -> r
        Error(_) -> []
      }
      let body =
        json.object([
          #("active", json.bool(True)),
          #("topic", json.string(topic)),
          #("options", json.array(options, json.string)),
          #(
            "results",
            json.array(results, fn(r) {
              json.object([
                #("choice", json.string(r.0)),
                #("count", json.int(r.1)),
              ])
            }),
          ),
        ])
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) ->
      wisp.json_response(
        json.to_string(json.object([#("active", json.bool(False))])),
        200,
      )
  }
}

fn handle_start_vote(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use topic <- decode.field("topic", decode.string)
    use options <- decode.field("options", decode.list(decode.string))
    decode.success(#(topic, options))
  }
  case decode.run(body, decoder) {
    Ok(#(topic, options)) ->
      case list.length(options) >= 2 {
        False -> wisp.bad_request("at least 2 options required")
        True ->
          case repo.start_vote(topic, options) {
            Ok(Nil) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("topic", json.string(topic)),
                    #("options", json.array(options, json.string)),
                  ]),
                ),
                201,
              )
            Error(_) -> wisp.internal_server_error()
          }
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_end_vote(repo: Repository) -> Response {
  case repo.get_active_vote() {
    Error(_) ->
      wisp.json_response(
        json.to_string(json.object([#("error", json.string("no active vote"))])),
        404,
      )
    Ok(#(topic, _)) -> {
      let results = case repo.get_vote_results() {
        Ok(r) -> r
        Error(_) -> []
      }
      let _ = repo.end_vote()
      let body =
        json.object([
          #("ended", json.string(topic)),
          #(
            "results",
            json.array(results, fn(r) {
              json.object([
                #("choice", json.string(r.0)),
                #("count", json.int(r.1)),
              ])
            }),
          ),
        ])
      wisp.json_response(json.to_string(body), 200)
    }
  }
}

fn handle_get_quizzes(repo: Repository) -> Response {
  case repo.get_all_quizzes() {
    Ok(quizzes) -> {
      let body =
        json.array(quizzes, fn(q) {
          json.object([
            #("question", json.string(q.0)),
            #("answer", json.string(q.1)),
            #("reward", json.int(q.2)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_add_quiz(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use question <- decode.field("question", decode.string)
    use answer <- decode.field("answer", decode.string)
    use reward <- decode.field("reward", decode.int)
    decode.success(#(question, answer, reward))
  }
  case decode.run(body, decoder) {
    Ok(#(question, answer, reward)) ->
      case repo.add_quiz(question, answer, reward) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("question", json.string(question)),
                #("answer", json.string(answer)),
                #("reward", json.int(reward)),
              ]),
            ),
            201,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_delete_quiz(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder =
    decode.field("question", decode.string, fn(q) { decode.success(q) })
  case decode.run(body, decoder) {
    Ok(question) ->
      case repo.delete_quiz(question) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(json.object([#("deleted", json.string(question))])),
            200,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_get_plugins(repo: Repository) -> Response {
  let all_plugins = [
    "attendance", "points", "minigame", "filter", "custom_command", "uptime",
    "vote", "roulette", "quiz", "timer",
  ]
  let disabled = case repo.get_disabled_plugins() {
    Ok(d) -> d
    Error(_) -> []
  }
  let body =
    json.array(all_plugins, fn(name) {
      json.object([
        #("name", json.string(name)),
        #("enabled", json.bool(!is_in_list(name, disabled))),
      ])
    })
  wisp.json_response(json.to_string(body), 200)
}

fn is_in_list(item: String, items: List(String)) -> Bool {
  case items {
    [] -> False
    [first, ..rest] ->
      case first == item {
        True -> True
        False -> is_in_list(item, rest)
      }
  }
}

fn handle_set_plugin(req: Request, repo: Repository) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use name <- decode.field("name", decode.string)
    use enabled <- decode.field("enabled", decode.bool)
    decode.success(#(name, enabled))
  }
  case decode.run(body, decoder) {
    Ok(#(name, enabled)) ->
      case repo.set_plugin_enabled(name, enabled) {
        Ok(Nil) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("name", json.string(name)),
                #("enabled", json.bool(enabled)),
              ]),
            ),
            200,
          )
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_dashboard() -> Response {
  let html =
    "<!DOCTYPE html>
<html lang=\"ko\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>kira_caster 관리 대시보드</title>
  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
  <link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&family=Roboto:wght@400;500&display=swap\" rel=\"stylesheet\">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Quicksand', Hiragino Sans, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif; background: #fff; color: #54577A; padding: 20px; }
    h1 { background: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 20px; font-weight: 700; }
    .tabs { display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; }
    .tab { padding: 8px 16px; background: #fff; border: 1px solid #E9EAEE; border-radius: 20px; cursor: pointer; color: #54577A; font-weight: 600; transition: all .2s; }
    .tab:hover { border-color: #FD719B; color: #FD719B; }
    .tab.active { background: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%); color: #fff; border-color: transparent; }
    .panel { display: none; background: rgba(255,255,255,0.75); border: 1px solid #E9EAEE; border-radius: 12px; padding: 20px; }
    .panel.active { display: block; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #E9EAEE; }
    th { color: #FD719B; font-weight: 600; }
    button { padding: 6px 14px; background: linear-gradient(92.54deg, #FD719B 5.84%, #FD9371 95.21%); color: #fff; border: none; border-radius: 20px; cursor: pointer; font-family: inherit; font-weight: 600; transition: opacity .2s; }
    button:hover { opacity: 0.85; }
    button.danger { background: #F77061; }
    button.success { background: #00C199; }
    input { padding: 8px 12px; background: #fff; color: #54577A; border: 1px solid #E9EAEE; border-radius: 8px; font-family: inherit; }
    input:focus { outline: none; border-color: #FD719B; }
    .form-row { display: flex; gap: 8px; margin-top: 10px; align-items: center; flex-wrap: wrap; }
    #status-info { font-size: 1.1em; font-family: 'Roboto', sans-serif; }
    td .on { color: #00C199; font-weight: 600; }
    td .off { color: #F77061; font-weight: 600; }
  </style>
</head>
<body>
  <h1>kira_caster 관리 대시보드</h1>
  <div class=\"tabs\">
    <div class=\"tab active\" onclick=\"showTab('status')\">상태</div>
    <div class=\"tab\" onclick=\"showTab('users')\">유저</div>
    <div class=\"tab\" onclick=\"showTab('words')\">금칙어</div>
    <div class=\"tab\" onclick=\"showTab('commands')\">명령어</div>
    <div class=\"tab\" onclick=\"showTab('quizzes')\">퀴즈</div>
    <div class=\"tab\" onclick=\"showTab('votes')\">투표</div>
    <div class=\"tab\" onclick=\"showTab('plugins')\">플러그인</div>
  </div>
  <div id=\"status\" class=\"panel active\"><div id=\"status-info\">로딩중...</div></div>
  <div id=\"users\" class=\"panel\"><table id=\"users-table\"><thead><tr><th>유저</th><th>포인트</th><th>출석</th></tr></thead><tbody></tbody></table></div>
  <div id=\"words\" class=\"panel\"><div class=\"form-row\"><input id=\"new-word\" placeholder=\"금칙어\"><button onclick=\"addWord()\">추가</button></div><table id=\"words-table\"><thead><tr><th>단어</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"commands\" class=\"panel\"><div class=\"form-row\"><input id=\"cmd-name\" placeholder=\"이름\"><input id=\"cmd-resp\" placeholder=\"응답\"><button onclick=\"addCmd()\">추가</button></div><table id=\"cmds-table\"><thead><tr><th>명령어</th><th>응답</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"quizzes\" class=\"panel\"><div class=\"form-row\"><input id=\"quiz-q\" placeholder=\"문제\"><input id=\"quiz-a\" placeholder=\"정답1,정답2,...\"><input id=\"quiz-r\" placeholder=\"보상\" type=\"number\" value=\"10\" style=\"width:60px\"><button onclick=\"addQuiz()\">추가</button></div><table id=\"quiz-table\"><thead><tr><th>문제</th><th>정답</th><th>보상</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"votes\" class=\"panel\"><div id=\"vote-info\">로딩중...</div></div>
  <div id=\"plugins\" class=\"panel\"><table id=\"plugins-table\"><thead><tr><th>플러그인</th><th>상태</th><th></th></tr></thead><tbody></tbody></table></div>
  <script>
    const base = '';
    function showTab(name) {
      document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.getElementById(name).classList.add('active');
      event.target.classList.add('active');
      load(name);
    }
    async function api(method, path, body) {
      const opts = {method, headers: {'Content-Type': 'application/json'}};
      if (body) opts.body = JSON.stringify(body);
      return fetch(base + path, opts).then(r => r.json());
    }
    async function load(tab) {
      if (tab === 'status') {
        const d = await api('GET', '/status');
        const h = Math.floor(d.uptime_seconds / 3600);
        const m = Math.floor((d.uptime_seconds % 3600) / 60);
        const s = d.uptime_seconds % 60;
        document.getElementById('status-info').innerHTML = `상태: ${d.status}<br>가동 시간: ${h}시간 ${m}분 ${s}초`;
      } else if (tab === 'users') {
        const d = await api('GET', '/users');
        document.querySelector('#users-table tbody').innerHTML = d.map(u => `<tr><td>${u.user_id}</td><td>${u.points}</td><td>${u.attendance_count}</td></tr>`).join('');
      } else if (tab === 'words') {
        const d = await api('GET', '/banned-words');
        document.querySelector('#words-table tbody').innerHTML = d.map(w => `<tr><td>${w}</td><td><button class=\"danger\" onclick=\"delWord('${w}')\">삭제</button></td></tr>`).join('');
      } else if (tab === 'commands') {
        const d = await api('GET', '/commands');
        document.querySelector('#cmds-table tbody').innerHTML = d.map(c => `<tr><td>!${c.name}</td><td>${c.response}</td><td><button class=\"danger\" onclick=\"delCmd('${c.name}')\">삭제</button></td></tr>`).join('');
      } else if (tab === 'quizzes') {
        const d = await api('GET', '/quizzes');
        document.querySelector('#quiz-table tbody').innerHTML = d.map(q => `<tr><td>${q.question}</td><td>${q.answer}</td><td>${q.reward}pt</td><td><button class=\"danger\" onclick=\"delQuiz('${q.question}')\">삭제</button></td></tr>`).join('');
      } else if (tab === 'votes') {
        const d = await api('GET', '/votes');
        if (!d.active) { document.getElementById('vote-info').textContent = '진행중인 투표가 없습니다.'; return; }
        let html = `<strong>${d.topic}</strong><br>`;
        if (d.results && d.results.length) html += d.results.map(r => `${r.choice}: ${r.count}표`).join('<br>');
        else html += '아직 투표가 없습니다.';
        document.getElementById('vote-info').innerHTML = html;
      } else if (tab === 'plugins') {
        const d = await api('GET', '/plugins');
        document.querySelector('#plugins-table tbody').innerHTML = d.map(p => `<tr><td>${p.name}</td><td><span class=\"${p.enabled ? 'on' : 'off'}\">${p.enabled ? 'ON' : 'OFF'}</span></td><td><button class=\"${p.enabled ? 'danger' : 'success'}\" onclick=\"togglePlugin('${p.name}', ${!p.enabled})\">${p.enabled ? '비활성화' : '활성화'}</button></td></tr>`).join('');
      }
    }
    async function addWord() { await api('POST', '/banned-words', {word: document.getElementById('new-word').value}); document.getElementById('new-word').value = ''; load('words'); }
    async function delWord(w) { if(!confirm('삭제할까요?')) return; await api('DELETE', '/banned-words', {word: w}); load('words'); }
    async function addCmd() { await api('POST', '/commands', {name: document.getElementById('cmd-name').value, response: document.getElementById('cmd-resp').value}); document.getElementById('cmd-name').value = ''; document.getElementById('cmd-resp').value = ''; load('commands'); }
    async function delCmd(n) { if(!confirm('삭제할까요?')) return; await api('DELETE', '/commands', {name: n}); load('commands'); }
    async function addQuiz() { await api('POST', '/quizzes', {question: document.getElementById('quiz-q').value, answer: document.getElementById('quiz-a').value, reward: parseInt(document.getElementById('quiz-r').value)||10}); document.getElementById('quiz-q').value = ''; document.getElementById('quiz-a').value = ''; load('quizzes'); }
    async function delQuiz(q) { if(!confirm('삭제할까요?')) return; await api('DELETE', '/quizzes', {question: q}); load('quizzes'); }
    async function togglePlugin(n, enabled) { await api('POST', '/plugins', {name: n, enabled: enabled}); load('plugins'); }
    load('status');
  </script>
</body>
</html>"
  wisp.html_response(html, 200)
}
