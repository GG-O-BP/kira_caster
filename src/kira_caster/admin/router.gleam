import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import kira_caster/event_bus
import kira_caster/storage/repository.{type Repository}
import kira_caster/util/time
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  repo: Repository,
  start_time: Int,
  admin_key: String,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  case check_auth(req, admin_key) {
    False -> wisp.response(401) |> wisp.string_body("Unauthorized")
    True -> route(req, repo, start_time, bus)
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

fn route(
  req: Request,
  repo: Repository,
  start_time: Int,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
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
    http.Post, ["plugins"] -> handle_set_plugin(req, repo, bus)
    http.Get, ["settings"] -> handle_get_settings(repo)
    http.Post, ["settings"] -> handle_set_setting(req, repo, bus)
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
            #("last_attendance", json.int(u.last_attendance)),
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
        #("description", json.string(plugin_description(name))),
        #("enabled", json.bool(!is_in_list(name, disabled))),
      ])
    })
  wisp.json_response(json.to_string(body), 200)
}

fn handle_get_settings(repo: Repository) -> Response {
  case repo.get_all_settings() {
    Ok(settings) -> {
      let body =
        json.array(settings, fn(s) {
          json.object([
            #("key", json.string(s.0)),
            #("value", json.string(s.1)),
          ])
        })
      wisp.json_response(json.to_string(body), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn handle_set_setting(
  req: Request,
  repo: Repository,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use key <- decode.field("key", decode.string)
    use value <- decode.field("value", decode.string)
    decode.success(#(key, value))
  }
  case decode.run(body, decoder) {
    Ok(#(key, value)) ->
      case repo.set_setting(key, value) {
        Ok(Nil) -> {
          case key, bus {
            "cooldown_ms", Some(b) ->
              case int.parse(value) {
                Ok(ms) -> event_bus.set_cooldown(b, ms)
                Error(_) -> Nil
              }
            _, _ -> Nil
          }
          wisp.json_response(
            json.to_string(
              json.object([
                #("key", json.string(key)),
                #("value", json.string(value)),
              ]),
            ),
            200,
          )
        }
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn plugin_description(name: String) -> String {
  case name {
    "attendance" -> "출석 체크 (하루 1회, 포인트 보상)"
    "points" -> "포인트 조회 및 순위"
    "minigame" -> "미니게임 (주사위, 가위바위보)"
    "filter" -> "채팅 필터 (금칙어 관리)"
    "custom_command" -> "커스텀 명령어"
    "uptime" -> "봇 가동 시간 조회"
    "vote" -> "투표 시스템"
    "roulette" -> "룰렛 (확률 기반 포인트)"
    "quiz" -> "퀴즈 (DB + 내장 문제)"
    "timer" -> "타이머 (비동기 알림)"
    _ -> ""
  }
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

fn handle_set_plugin(
  req: Request,
  repo: Repository,
  bus: Option(process.Subject(event_bus.EventBusMessage)),
) -> Response {
  use body <- wisp.require_json(req)
  let decoder = {
    use name <- decode.field("name", decode.string)
    use enabled <- decode.field("enabled", decode.bool)
    decode.success(#(name, enabled))
  }
  case decode.run(body, decoder) {
    Ok(#(name, enabled)) ->
      case repo.set_plugin_enabled(name, enabled) {
        Ok(Nil) -> {
          // 이벤트 버스에 즉시 반영
          case bus {
            Some(b) ->
              case repo.get_disabled_plugins() {
                Ok(disabled) -> event_bus.set_disabled_plugins(b, disabled)
                Error(_) -> Nil
              }
            None -> Nil
          }
          wisp.json_response(
            json.to_string(
              json.object([
                #("name", json.string(name)),
                #("enabled", json.bool(enabled)),
              ]),
            ),
            200,
          )
        }
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("invalid request body")
  }
}

fn handle_dashboard() -> Response {
  let html = "<!DOCTYPE html>
<html lang=\"ko\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>kira_caster 관리 대시보드</title>
  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
  <link href=\"https://fonts.googleapis.com/css2?family=Quicksand:wght@400;600;700&family=Roboto:wght@400;500&display=swap\" rel=\"stylesheet\">" <> "<style>" <> dashboard_css() <> "</style>
</head>" <> dashboard_body() <> "</html>"
  wisp.html_response(html, 200)
}

fn dashboard_css() -> String {
  "
    :root {
      --color-primary: #FD719B;
      --color-secondary: #FD9371;
      --color-pink-light: #FD99B8;
      --gradient-main: linear-gradient(92.54deg, #FF608F 5.84%, #FBB35E 95.21%);
      --gradient-secondary: linear-gradient(92.54deg, #FD719B 5.84%, #FD9371 95.21%);
      --color-success: #00C199;
      --color-warning: #F8C03A;
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
    .loading { color: var(--color-text); text-align: center; padding: 20px; }
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
  </div>
  <div id=\"status\" class=\"panel active\"><div id=\"status-info\">로딩중...</div></div>
  <div id=\"users\" class=\"panel\"><div class=\"form-row\"><input id=\"user-search\" placeholder=\"유저 검색...\" oninput=\"filterUsers()\"><button class=\"success\" onclick=\"exportUsers()\">CSV 내보내기</button></div><table id=\"users-table\"><thead><tr><th>유저</th><th>포인트</th><th>출석</th><th>최근출석</th></tr></thead><tbody></tbody></table></div>
  <div id=\"words\" class=\"panel\"><div class=\"form-row\"><input id=\"new-word\" placeholder=\"금칙어\"><button onclick=\"addWord()\">추가</button></div><table id=\"words-table\"><thead><tr><th>단어</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"commands\" class=\"panel\"><div class=\"form-row\"><input id=\"cmd-name\" placeholder=\"이름\"><input id=\"cmd-resp\" placeholder=\"응답\"><button onclick=\"addCmd()\">추가</button></div><table id=\"cmds-table\"><thead><tr><th>명령어</th><th>응답</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"quizzes\" class=\"panel\"><div class=\"form-row\"><input id=\"quiz-q\" placeholder=\"문제\"><input id=\"quiz-a\" placeholder=\"정답1,정답2,...\"><input id=\"quiz-r\" placeholder=\"보상\" type=\"number\" value=\"10\" style=\"width:60px\"><button onclick=\"addQuiz()\">추가</button></div><table id=\"quiz-table\"><thead><tr><th>문제</th><th>정답</th><th>보상</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"votes\" class=\"panel\"><div class=\"form-row\"><input id=\"vote-topic\" placeholder=\"투표 주제\"><input id=\"vote-options\" placeholder=\"선택지1,선택지2,...\"><button onclick=\"startVote()\">투표 시작</button></div><div id=\"vote-info\" style=\"margin-top:12px\">로딩중...</div></div>
  <div id=\"plugins\" class=\"panel\"><table id=\"plugins-table\"><thead><tr><th>플러그인</th><th>설명</th><th>상태</th><th></th></tr></thead><tbody></tbody></table></div>
  <div id=\"settings\" class=\"panel\"><div id=\"settings-form\">로딩중...</div></div>
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
      var interval = (activeTab === 'status' || activeTab === 'votes') ? 5000 : 15000;
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
        document.querySelector('#cmds-table tbody').innerHTML = d.length ? d.map(function(c) { return '<tr><td>!' + esc(c.name) + '</td><td>' + esc(c.response) + '</td><td><button class=\\\"danger\\\" onclick=\\\"delCmd(\\'' + esc(c.name) + '\\')\\\">삭제</button></td></tr>'; }).join('') : empty(3);
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
      }
      } catch(e) { }
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

    load('status');
    startAutoRefresh();
  "
}
