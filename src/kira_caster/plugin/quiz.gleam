import gleam/int
import gleam/string
import kira_caster/core/permission
import kira_caster/core/quiz_data
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository}

pub fn new(repo: Repository) -> Plugin {
  Plugin(name: "quiz", handle_event: fn(event) { handle(repo, event) })
}

fn handle(repo: Repository, event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "퀴즈", args: ["시작"], role:) ->
      handle_start(repo, role)
    plugin.Command(user:, name: "퀴즈", args: [answer], role: _) ->
      handle_answer(repo, user, answer)
    plugin.Command(user: _, name: "퀴즈", args: _, role: _) -> [
      plugin.PluginResponse(plugin: "quiz", message: "이렇게 써줘용 !퀴즈 시작 / !퀴즈 <답>"),
    ]
    _ -> []
  }
}

fn handle_start(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(plugin: "quiz", message: "헐 이건 관리자만 할 수 있어용 ㅠ"),
    ]
    Ok(Nil) -> {
      // DB 퀴즈가 있으면 DB에서, 없으면 내장 데이터에서 출제
      let #(question, answers_str, reward) = case repo.get_quiz_count() {
        Ok(count) if count > 0 ->
          case repo.get_all_quizzes() {
            Ok(db_quizzes) -> {
              let idx = int.random(count)
              case list_at(db_quizzes, idx) {
                Ok(#(q, a, r)) -> #(q, a, r)
                Error(_) -> fallback_quiz()
              }
            }
            Error(_) -> fallback_quiz()
          }
        _ -> fallback_quiz()
      }
      let _ =
        repo.set_command(
          "__quiz_answer",
          answers_str <> "|" <> int.to_string(reward),
        )
      [
        plugin.PluginResponse(plugin: "quiz", message: "퀴즈 나간당! " <> question),
      ]
    }
  }
}

fn handle_answer(repo: Repository, user: String, answer: String) -> List(Event) {
  case repo.get_command("__quiz_answer") {
    Error(_) -> [
      plugin.PluginResponse(plugin: "quiz", message: "지금 진행 중인 퀴즈가 없당.."),
    ]
    Ok(data) ->
      case string.split_once(data, "|") {
        Error(_) -> []
        Ok(#(answers_str, reward_str)) -> {
          let correct_answers = string.split(answers_str, ",")
          case is_correct(answer, correct_answers) {
            False -> []
            True -> {
              let reward = case int.parse(reward_str) {
                Ok(n) -> n
                Error(_) -> 10
              }
              let _ = repo.delete_command("__quiz_answer")
              [
                plugin.PluginResponse(
                  plugin: "quiz",
                  message: user <> "님 정답이당!! ㅋㅋ (+" <> int.to_string(reward) <> "포인트)",
                ),
                plugin.PointsChange(user: user, amount: reward, reason: "quiz"),
              ]
            }
          }
        }
      }
  }
}

fn fallback_quiz() -> #(String, String, Int) {
  let quizzes = quiz_data.all()
  let idx = int.random(quiz_data.count())
  case list_at(quizzes, idx) {
    Ok(q) -> #(q.question, join_answers(q.answers), q.reward)
    Error(_) -> #("1 + 1 = ?", "2", 10)
  }
}

fn list_at(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [], _ -> Error(Nil)
    [first, ..], 0 -> Ok(first)
    [_, ..rest], n -> list_at(rest, n - 1)
  }
}

fn join_answers(answers: List(String)) -> String {
  case answers {
    [] -> ""
    [a] -> a
    [a, ..rest] -> a <> "," <> join_answers(rest)
  }
}

fn is_correct(answer: String, correct_answers: List(String)) -> Bool {
  let normalized = normalize(answer)
  case correct_answers {
    [] -> False
    [first, ..rest] ->
      case normalize(first) == normalized {
        True -> True
        False -> is_correct(answer, rest)
      }
  }
}

fn normalize(text: String) -> String {
  text
  |> string.lowercase
  |> string.replace(" ", "")
}
