import kira_caster/event_bus
import kira_caster/supervisor

pub fn supervisor_starts_successfully_test() {
  let assert Ok(#(_sup, bus)) = supervisor.start()
  event_bus.shutdown(bus)
}
