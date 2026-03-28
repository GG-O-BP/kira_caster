import kira_caster/core/config
import kira_caster/event_bus
import kira_caster/supervisor

pub fn supervisor_starts_successfully_test() {
  let assert Ok(#(_sup, bus, _name)) = supervisor.start(config.default())
  event_bus.shutdown(bus)
}
