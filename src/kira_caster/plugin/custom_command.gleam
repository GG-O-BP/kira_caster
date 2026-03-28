import gleam/dict
import gleam/int
import gleam/option.{Some}
import gleam/string
import kira_caster/core/permission
import kira_caster/core/template
import kira_caster/plugin/advanced_command
import kira_caster/plugin/plugin.{type Event, type Plugin, Plugin}
import kira_caster/storage/repository.{type Repository}

pub fn new(repo: Repository) -> Plugin {
  Plugin(name: "custom_command", handle_event: fn(event) { handle(repo, event) })
}

fn handle(repo: Repository, event: Event) -> List(Event) {
  case event {
    plugin.Command(user: _, name: "명령", args: ["추가", cmd_name, ..rest], role:) ->
      handle_add(repo, role, cmd_name, string.join(rest, " "))
    plugin.Command(user: _, name: "명령", args: ["삭제", cmd_name], role:) ->
      handle_delete(repo, role, cmd_name)
    plugin.Command(user: _, name: "명령", args: ["목록"], role:) ->
      handle_list(repo, role)
    plugin.Command(user: _, name: "명령", args: ["고급추가", cmd_name, ..rest], role:) ->
      handle_add_advanced(repo, role, cmd_name, string.join(rest, " "))
    plugin.Command(user: _, name: "명령", args: ["고급삭제", cmd_name], role:) ->
      handle_delete_advanced(repo, role, cmd_name)
    plugin.Command(user:, name:, args:, role: _) ->
      try_custom_response(repo, name, user, args)
    _ -> []
  }
}

fn handle_add(
  repo: Repository,
  role: permission.Role,
  name: String,
  response: String,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "권한이 없습니다. (관리자 전용)",
      ),
    ]
    Ok(Nil) ->
      case response {
        "" -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "사용법: !명령 추가 <이름> <응답>",
          ),
        ]
        _ ->
          case repo.set_command(name, response) {
            Ok(Nil) -> [
              plugin.PluginResponse(
                plugin: "custom_command",
                message: "'" <> name <> "' 명령이 등록되었습니다.",
              ),
            ]
            Error(_) -> [
              plugin.PluginResponse(
                plugin: "custom_command",
                message: "명령 등록 중 오류가 발생했습니다.",
              ),
            ]
          }
      }
  }
}

fn handle_delete(
  repo: Repository,
  role: permission.Role,
  name: String,
) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "권한이 없습니다. (관리자 전용)",
      ),
    ]
    Ok(Nil) ->
      case repo.delete_command(name) {
        Ok(Nil) -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "'" <> name <> "' 명령이 삭제되었습니다.",
          ),
        ]
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "명령 삭제 중 오류가 발생했습니다.",
          ),
        ]
      }
  }
}

fn handle_list(repo: Repository, role: permission.Role) -> List(Event) {
  case permission.check(role, permission.Moderator) {
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "권한이 없습니다. (관리자 전용)",
      ),
    ]
    Ok(Nil) ->
      case repo.get_all_commands() {
        Ok(commands) -> {
          let msg = case commands {
            [] -> "등록된 명령이 없습니다."
            _ -> "명령 목록: " <> string.join(list_map_commands(commands), ", ")
          }
          [plugin.PluginResponse(plugin: "custom_command", message: msg)]
        }
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "명령 조회 중 오류가 발생했습니다.",
          ),
        ]
      }
  }
}

fn list_map_commands(commands: List(#(String, String))) -> List(String) {
  case commands {
    [] -> []
    [#(name, _), ..rest] -> ["!" <> name, ..list_map_commands(rest)]
  }
}

fn try_custom_response(
  repo: Repository,
  name: String,
  user: String,
  args: List(String),
) -> List(Event) {
  case repo.get_command_with_type(name) {
    Ok(#(_response, "gleam", Some(_source))) ->
      try_gleam_response(name, user, args)
    Ok(#(response, _, _)) ->
      try_template_response(response, name, user, args, repo)
    Error(_) ->
      // Fallback to get_command for backward compatibility
      case repo.get_command(name) {
        Ok(response) -> try_template_response(response, name, user, args, repo)
        Error(_) -> []
      }
  }
}

fn try_template_response(
  response: String,
  name: String,
  user: String,
  args: List(String),
  repo: Repository,
) -> List(Event) {
  let context = build_context(repo, user, name, args)
  let message = case template.render(response, context) {
    Ok(rendered) -> rendered
    Error(_) -> response
  }
  [plugin.PluginResponse(plugin: "custom_command", message:)]
}

fn try_gleam_response(
  name: String,
  user: String,
  args: List(String),
) -> List(Event) {
  case advanced_command.execute(name, user, args) {
    Ok(result) -> [
      plugin.PluginResponse(plugin: "custom_command", message: result),
    ]
    Error(e) -> [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: advanced_command.error_to_string(e),
      ),
    ]
  }
}

fn handle_add_advanced(
  repo: Repository,
  role: permission.Role,
  name: String,
  source: String,
) -> List(Event) {
  case permission.check(role, permission.Broadcaster) {
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "권한이 없습니다. (방송자 전용)",
      ),
    ]
    Ok(Nil) ->
      case source {
        "" -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "사용법: !명령 고급추가 <이름> <Gleam 코드>",
          ),
        ]
        _ ->
          case repo.set_advanced_command(name, source, "실행 오류") {
            Ok(Nil) ->
              case advanced_command.compile_and_load(name, source) {
                Ok(Nil) -> [
                  plugin.PluginResponse(
                    plugin: "custom_command",
                    message: "고급 명령 '" <> name <> "' 컴파일 및 등록 완료.",
                  ),
                ]
                Error(e) -> [
                  plugin.PluginResponse(
                    plugin: "custom_command",
                    message: "저장 완료, " <> advanced_command.error_to_string(e),
                  ),
                ]
              }
            Error(_) -> [
              plugin.PluginResponse(
                plugin: "custom_command",
                message: "고급 명령 저장 중 오류가 발생했습니다.",
              ),
            ]
          }
      }
  }
}

fn handle_delete_advanced(
  repo: Repository,
  role: permission.Role,
  name: String,
) -> List(Event) {
  case permission.check(role, permission.Broadcaster) {
    Error(_) -> [
      plugin.PluginResponse(
        plugin: "custom_command",
        message: "권한이 없습니다. (방송자 전용)",
      ),
    ]
    Ok(Nil) -> {
      advanced_command.unload(name)
      case repo.delete_command(name) {
        Ok(Nil) -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "고급 명령 '" <> name <> "' 삭제 완료.",
          ),
        ]
        Error(_) -> [
          plugin.PluginResponse(
            plugin: "custom_command",
            message: "고급 명령 삭제 중 오류가 발생했습니다.",
          ),
        ]
      }
    }
  }
}

fn build_context(
  repo: Repository,
  user: String,
  command: String,
  args: List(String),
) -> dict.Dict(String, String) {
  let ctx =
    dict.new()
    |> dict.insert("user", user)
    |> dict.insert("command", command)
    |> dict.insert("args", string.join(args, " "))
  let ctx = insert_args_indexed(ctx, args, 0)
  case repo.get_user(user) {
    Ok(user_data) ->
      ctx
      |> dict.insert("points", int.to_string(user_data.points))
      |> dict.insert("attendance", int.to_string(user_data.attendance_count))
    Error(_) -> ctx
  }
}

fn insert_args_indexed(
  ctx: dict.Dict(String, String),
  args: List(String),
  index: Int,
) -> dict.Dict(String, String) {
  case args {
    [] -> ctx
    [first, ..rest] ->
      insert_args_indexed(
        dict.insert(ctx, "args." <> int.to_string(index), first),
        rest,
        index + 1,
      )
  }
}
