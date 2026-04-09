import gleam/option.{type Option}
import kira_caster/core/permission

pub type Event {
  ChatMessage(
    user: String,
    content: String,
    channel: String,
    channel_id: Option(String),
  )
  Command(user: String, name: String, args: List(String), role: permission.Role)
  PluginResponse(plugin: String, message: String)
  SystemEvent(kind: String, data: String)
  PointsChange(user: String, amount: Int, reason: String)
  Donation(
    user: String,
    channel_id: Option(String),
    amount: String,
    message: String,
    donation_type: String,
  )
  Subscription(
    user: String,
    channel_id: String,
    month: Int,
    tier: Int,
    message: String,
  )
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
