import gleam/option.{Some}
import kira_caster/core/template
import kira_caster/plugin/advanced_command
import kira_caster/plugin/custom_command/context
import kira_caster/plugin/plugin.{type Event}
import kira_caster/storage/repository.{type Repository}

pub fn try_custom_response(
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
  let ctx = context.build_context(repo, user, name, args)
  let message = case template.render(response, ctx) {
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
