import gleam/erlang/process
import gleam/int
import gleam/option.{Some}
import kira_caster/admin/router
import kira_caster/core/config.{type Config}
import kira_caster/event_bus
import kira_caster/logger
import kira_caster/storage/repository.{type Repository}
import mist
import wisp/wisp_mist

pub fn start(
  repo: Repository,
  config: Config,
  start_time: Int,
  bus: process.Subject(event_bus.EventBusMessage),
) -> Result(Nil, String) {
  let handler = fn(req) {
    router.handle_request(req, repo, start_time, config.admin_key, Some(bus))
  }

  case
    handler
    |> wisp_mist.handler(config.secret_key_base)
    |> mist.new
    |> mist.port(config.admin_port)
    |> mist.start
  {
    Ok(_) -> {
      logger.info(
        "Admin dashboard running on port " <> int.to_string(config.admin_port),
      )
      Ok(Nil)
    }
    Error(_) -> Error("Failed to start admin server")
  }
}
