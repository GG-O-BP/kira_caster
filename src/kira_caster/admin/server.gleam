import gleam/erlang/process
import gleam/http/request
import gleam/int
import gleam/json
import gleam/option.{Some}
import kira_caster/admin/dashboard/app as dashboard_app
import kira_caster/admin/dashboard/model.{type Msg, DashboardContext}
import kira_caster/admin/router
import kira_caster/core/config.{type Config}
import kira_caster/logger
import lustre.{type RuntimeMessage}
import lustre/server_component.{type ClientMessage}
import mist
import wisp/wisp_mist

type WsState {
  WsState(
    runtime_subject: process.Subject(RuntimeMessage(Msg)),
    client_subject: process.Subject(ClientMessage(Msg)),
  )
}

pub fn start(ctx: router.RouterContext, config: Config) -> Result(Nil, String) {
  let wisp_handler =
    wisp_mist.handler(
      fn(req) { router.handle_request(req, ctx) },
      config.secret_key_base,
    )

  let handler = fn(req) {
    case request.path_segments(req) {
      ["ws", "dashboard"] -> handle_dashboard_ws(req, ctx)
      _ -> wisp_handler(req)
    }
  }

  case
    handler
    |> mist.new
    |> mist.port(config.admin_port)
    |> mist.start
  {
    Ok(_) -> {
      logger.info("=====================================")
      logger.info("  kira_caster 대시보드")
      logger.info("  http://localhost:" <> int.to_string(config.admin_port))
      logger.info("=====================================")
      Ok(Nil)
    }
    Error(_) -> Error("Failed to start admin server")
  }
}

fn handle_dashboard_ws(req, ctx: router.RouterContext) {
  let dashboard_ctx =
    DashboardContext(
      repo: ctx.repo,
      start_time: ctx.start_time,
      config: ctx.config,
      cime_api: ctx.cime_api,
      get_token: ctx.get_token,
      bus: ctx.bus,
      ws_manager: ctx.ws_manager,
    )

  let app = dashboard_app.create()

  mist.websocket(
    request: req,
    on_init: fn(_conn) {
      let assert Ok(runtime) = lustre.start_server_component(app, dashboard_ctx)
      let runtime_subject = server_component.subject(runtime)

      let client_subject = process.new_subject()
      process.send(
        runtime_subject,
        server_component.register_subject(client_subject),
      )

      let selector =
        process.new_selector()
        |> process.select(client_subject)

      #(WsState(runtime_subject, client_subject), Some(selector))
    },
    handler: fn(state: WsState, ws_msg, conn) {
      case ws_msg {
        mist.Text(json_str) -> {
          case
            json.parse(json_str, server_component.runtime_message_decoder())
          {
            Ok(runtime_msg) -> process.send(state.runtime_subject, runtime_msg)
            Error(_) -> Nil
          }
          mist.continue(state)
        }
        mist.Custom(client_msg) -> {
          let encoded =
            json.to_string(server_component.client_message_to_json(client_msg))
          let _ = mist.send_text_frame(conn, encoded)
          mist.continue(state)
        }
        mist.Closed -> mist.stop()
        mist.Shutdown -> mist.stop()
        mist.Binary(_) -> mist.continue(state)
      }
    },
    on_close: fn(state) {
      process.send(state.runtime_subject, lustre.shutdown())
      Nil
    },
  )
}
