import gleam/erlang/process.{type Name, type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervision
import kira_caster/core/cooldown.{type CooldownMap}
import kira_caster/plugin/plugin.{type Event, type Plugin}

pub type EventBusMessage {
  Dispatch(event: Event)
  Subscribe(plugin: Plugin)
  Unsubscribe(plugin_name: String)
  SetResponseHandler(handler: fn(Event) -> Nil)
  SetCooldown(ms: Int)
  Shutdown
}

pub type EventBusState {
  EventBusState(
    plugins: List(Plugin),
    bus_subject: Subject(EventBusMessage),
    on_response: Option(fn(Event) -> Nil),
    cooldowns: CooldownMap,
    cooldown_ms: Int,
  )
}

@external(erlang, "kira_caster_ffi", "now_ms")
fn now_ms() -> Int

pub fn start_named(
  name: Name(EventBusMessage),
) -> Result(actor.Started(Subject(EventBusMessage)), actor.StartError) {
  actor.new_with_initialiser(1000, fn(subject) {
    actor.initialised(EventBusState(
      plugins: [],
      bus_subject: subject,
      on_response: None,
      cooldowns: cooldown.new(),
      cooldown_ms: 5000,
    ))
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.named(name)
  |> actor.start
}

pub fn child_spec(
  name: Name(EventBusMessage),
) -> supervision.ChildSpecification(Subject(EventBusMessage)) {
  supervision.worker(run: fn() { start_named(name) })
}

pub fn start() -> Result(
  actor.Started(Subject(EventBusMessage)),
  actor.StartError,
) {
  actor.new_with_initialiser(1000, fn(subject) {
    actor.initialised(EventBusState(
      plugins: [],
      bus_subject: subject,
      on_response: None,
      cooldowns: cooldown.new(),
      cooldown_ms: 5000,
    ))
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
}

pub fn dispatch(bus: Subject(EventBusMessage), event: Event) -> Nil {
  process.send(bus, Dispatch(event))
}

pub fn subscribe(bus: Subject(EventBusMessage), plugin: Plugin) -> Nil {
  process.send(bus, Subscribe(plugin))
}

pub fn unsubscribe(bus: Subject(EventBusMessage), plugin_name: String) -> Nil {
  process.send(bus, Unsubscribe(plugin_name))
}

pub fn set_response_handler(
  bus: Subject(EventBusMessage),
  handler: fn(Event) -> Nil,
) -> Nil {
  process.send(bus, SetResponseHandler(handler))
}

pub fn set_cooldown(bus: Subject(EventBusMessage), ms: Int) -> Nil {
  process.send(bus, SetCooldown(ms))
}

pub fn shutdown(bus: Subject(EventBusMessage)) -> Nil {
  process.send(bus, Shutdown)
}

fn handle_message(
  state: EventBusState,
  message: EventBusMessage,
) -> actor.Next(EventBusState, EventBusMessage) {
  case message {
    Dispatch(event) -> handle_dispatch(state, event)
    Subscribe(plugin) ->
      actor.continue(EventBusState(..state, plugins: [plugin, ..state.plugins]))
    Unsubscribe(name) ->
      actor.continue(
        EventBusState(
          ..state,
          plugins: list.filter(state.plugins, fn(p) { p.name != name }),
        ),
      )
    SetResponseHandler(handler) ->
      actor.continue(EventBusState(..state, on_response: Some(handler)))
    SetCooldown(ms) -> actor.continue(EventBusState(..state, cooldown_ms: ms))
    Shutdown -> actor.stop()
  }
}

fn handle_dispatch(
  state: EventBusState,
  event: Event,
) -> actor.Next(EventBusState, EventBusMessage) {
  case event {
    plugin.Command(user:, name:, args: _, role: _) -> {
      let key = user <> ":" <> name
      let now = now_ms()
      case cooldown.check(state.cooldowns, key, now, state.cooldown_ms) {
        Ok(Nil) -> {
          let responses = collect_responses(state.plugins, event)
          deliver_responses(state, responses)
          let new_cooldowns = cooldown.record_use(state.cooldowns, key, now)
          actor.continue(EventBusState(..state, cooldowns: new_cooldowns))
        }
        Error(cooldown.OnCooldown(remaining)) -> {
          let msg =
            user
            <> "님, "
            <> int.to_string(remaining / 1000)
            <> "초 후에 다시 시도해주세요."
          case state.on_response {
            Some(handler) ->
              handler(plugin.PluginResponse(plugin: "system", message: msg))
            None -> Nil
          }
          actor.continue(state)
        }
      }
    }
    _ -> {
      let responses = collect_responses(state.plugins, event)
      deliver_responses(state, responses)
      actor.continue(state)
    }
  }
}

fn collect_responses(plugins: List(Plugin), event: Event) -> List(Event) {
  list.flat_map(plugins, fn(p) { plugin.handle(p, event) })
}

fn deliver_responses(state: EventBusState, responses: List(Event)) -> Nil {
  list.each(responses, fn(event) {
    case event {
      plugin.PluginResponse(_, _) -> {
        case state.on_response {
          Some(handler) -> handler(event)
          None -> Nil
        }
      }
      _ -> process.send(state.bus_subject, Dispatch(event))
    }
  })
}
