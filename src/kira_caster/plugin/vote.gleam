import gleam/string
import kira_caster/core/permission
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/plugin/vote/formatter
import kira_caster/storage/repository.{type Repository}

pub fn new(repo: Repository) -> Plugin {
  Plugin(name: "vote", handle_event: fn(event) { handle(repo, event) })
}

fn handle(repo: Repository, event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "투표", args: ["시작", topic, ..options], role:) ->
      handle_start(repo, role, topic, options)
    plugin.Command(user: _, name: "투표", args: ["결과"], role: _) ->
      handle_results(repo)
    plugin.Command(user: _, name: "투표", args: ["종료"], role:) ->
      handle_end(repo, role)
    plugin.Command(user:, name: "투표", args: [choice], role: _) ->
      handle_cast(repo, user, choice)
    plugin.Command(user: _, name: "투표", args: _, role: _) -> [
      resp("사용법: !투표 시작 <주제> <선택지1> <선택지2> ... / !투표 <선택지> / !투표 결과 / !투표 종료"),
    ]
    _ -> []
  }
}

fn resp(msg: String) -> Event {
  plugin.PluginResponse(plugin: "vote", message: msg)
}

fn handle_start(
  repo: Repository,
  role: permission.Role,
  topic: String,
  options: List(String),
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("권한이 없습니다. (관리자 전용)")]
    Ok(Nil) ->
      case options {
        [] | [_] -> [resp("선택지를 2개 이상 입력해주세요.")]
        _ ->
          case repo.start_vote(topic, options) {
            Ok(Nil) -> [
              resp(
                "투표 시작: "
                <> topic
                <> "\n선택지: "
                <> string.join(options, ", ")
                <> "\n'!투표 <선택지>'로 참여하세요!",
              ),
            ]
            Error(_) -> [resp("투표 시작 중 오류가 발생했습니다.")]
          }
      }
  }
}

fn handle_cast(repo: Repository, user: String, choice: String) -> List(Event) {
  case repo.get_active_vote() {
    Error(_) -> [resp("현재 진행 중인 투표가 없습니다.")]
    Ok(#(_topic, options)) ->
      case formatter.list_contains(options, choice) {
        False -> [
          resp(
            "'"
            <> choice
            <> "'은(는) 유효한 선택지가 아닙니다. 선택지: "
            <> string.join(options, ", "),
          ),
        ]
        True ->
          case repo.cast_vote(user, choice) {
            Ok(Nil) -> [
              resp(user <> "님이 '" <> choice <> "'에 투표했습니다."),
            ]
            Error(_) -> [resp("투표 처리 중 오류가 발생했습니다.")]
          }
      }
  }
}

fn handle_results(repo: Repository) -> List(Event) {
  case repo.get_active_vote() {
    Error(_) -> [resp("현재 진행 중인 투표가 없습니다.")]
    Ok(#(topic, _options)) ->
      case repo.get_vote_results() {
        Ok(results) -> {
          let lines = formatter.format_results(results)
          let msg = case lines {
            "" -> "투표 '" <> topic <> "' - 아직 투표가 없습니다."
            _ -> "투표 '" <> topic <> "' 결과:\n" <> lines
          }
          [resp(msg)]
        }
        Error(_) -> [resp("결과 조회 중 오류가 발생했습니다.")]
      }
  }
}

fn handle_end(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [resp("권한이 없습니다. (관리자 전용)")]
    Ok(Nil) ->
      case repo.get_active_vote() {
        Error(_) -> [resp("현재 진행 중인 투표가 없습니다.")]
        Ok(#(topic, _)) -> {
          let results_msg = case repo.get_vote_results() {
            Ok(results) -> formatter.format_results(results)
            Error(_) -> ""
          }
          let _ = repo.end_vote()
          let msg = case results_msg {
            "" -> "투표 '" <> topic <> "' 종료! 투표가 없었습니다."
            _ -> "투표 '" <> topic <> "' 최종 결과:\n" <> results_msg
          }
          [resp(msg)]
        }
      }
  }
}
