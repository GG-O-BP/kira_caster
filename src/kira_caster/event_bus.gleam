import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import kira_caster/plugin/plugin.{type Event, type Plugin}

pub type EventBusMessage {
  Dispatch(event: Event)
  Subscribe(plugin: Plugin)
  Unsubscribe(plugin_name: String)
  Shutdown
}

pub type EventBusState {
  EventBusState(plugins: List(Plugin))
}

pub fn start() -> Result(
  actor.Started(Subject(EventBusMessage)),
  actor.StartError,
) {
  actor.new(EventBusState(plugins: []))
  |> actor.on_message(handle_message)
  |> actor.start
}

pub fn dispatch(bus: Subject(EventBusMessage), event: Event) -> Nil {
  process.send(bus, Dispatch(event))
}

pub fn subscribe(bus: Subject(EventBusMessage), plugin: Plugin) -> Nil {
  process.send(bus, Subscribe(plugin))
}

fn handle_message(
  state: EventBusState,
  message: EventBusMessage,
) -> actor.Next(EventBusState, EventBusMessage) {
  case message {
    Dispatch(event) -> {
      dispatch_to_plugins(state.plugins, event)
      actor.continue(state)
    }
    Subscribe(plugin) ->
      actor.continue(EventBusState(plugins: [plugin, ..state.plugins]))
    Unsubscribe(name) ->
      actor.continue(EventBusState(
        plugins: state.plugins
        |> remove_plugin(name),
      ))
    Shutdown -> actor.stop()
  }
}

fn dispatch_to_plugins(plugins: List(Plugin), event: Event) -> Nil {
  case plugins {
    [] -> Nil
    [p, ..rest] -> {
      plugin.handle(p, event)
      dispatch_to_plugins(rest, event)
    }
  }
}

fn remove_plugin(plugins: List(Plugin), name: String) -> List(Plugin) {
  case plugins {
    [] -> []
    [p, ..rest] ->
      case p.name == name {
        True -> rest
        False -> [p, ..remove_plugin(rest, name)]
      }
  }
}
