pub type Event {
  ChatMessage(user: String, content: String, channel: String)
  Command(user: String, name: String, args: List(String))
  PluginResponse(plugin: String, message: String)
  SystemEvent(kind: String, data: String)
}

pub type Plugin {
  Plugin(name: String, handle_event: fn(Event) -> List(Event))
}

pub type PluginError {
  HandlerFailed(reason: String)
}

pub fn new(name: String, handler: fn(Event) -> List(Event)) -> Plugin {
  Plugin(name: name, handle_event: handler)
}

pub fn handle(plugin: Plugin, event: Event) -> List(Event) {
  plugin.handle_event(event)
}

pub fn noop_handler(_event: Event) -> List(Event) {
  []
}
