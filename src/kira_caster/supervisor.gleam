import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor.{type Supervisor} as supervisor
import kira_caster/core/config.{type Config}
import kira_caster/event_bus

pub fn start(
  config: Config,
) -> Result(
  #(
    actor.Started(Supervisor),
    process.Subject(event_bus.EventBusMessage),
    process.Name(event_bus.EventBusMessage),
  ),
  actor.StartError,
) {
  let bus_name = process.new_name(prefix: "kira_caster_event_bus")

  let result =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.restart_tolerance(intensity: 3, period: 5)
    |> supervisor.add(event_bus.child_spec(bus_name, config.cooldown_ms))
    |> supervisor.start

  case result {
    Ok(started) -> {
      let bus = process.named_subject(bus_name)
      Ok(#(started, bus, bus_name))
    }
    Error(e) -> Error(e)
  }
}
