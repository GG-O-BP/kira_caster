import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import kira_caster/plugin/plugin.{type Event, type Plugin}

pub type EventBusMessage {
  Dispatch(event: Event)
  Subscribe(plugin: Plugin)
  Unsubscribe(plugin_name: String)
  SetResponseHandler(handler: fn(Event) -> Nil)
  Shutdown
}

pub type EventBusState {
  EventBusState(
    plugins: List(Plugin),
    bus_subject: Subject(EventBusMessage),
    on_response: Option(fn(Event) -> Nil),
  )
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

pub fn shutdown(bus: Subject(EventBusMessage)) -> Nil {
  process.send(bus, Shutdown)
}

fn handle_message(
  state: EventBusState,
  message: EventBusMessage,
) -> actor.Next(EventBusState, EventBusMessage) {
  case message {
    Dispatch(event) -> {
      let responses = collect_responses(state.plugins, event)
      deliver_responses(state, responses)
      actor.continue(state)
    }
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
    Shutdown -> actor.stop()
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
