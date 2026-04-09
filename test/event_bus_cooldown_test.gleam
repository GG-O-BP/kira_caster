import gleam/erlang/process
import gleam/option
import kira_caster/core/permission
import kira_caster/event_bus
import kira_caster/plugin/plugin.{Plugin}

pub fn first_command_passes_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data
  let test_subject = process.new_subject()

  event_bus.set_cooldown(bus, 5000)

  let test_plugin =
    Plugin(name: "echo", handle_event: fn(event) {
      case event {
        plugin.Command(user: _, name: "ping", args: _, role: _) -> [
          plugin.PluginResponse(plugin: "echo", message: "pong"),
        ]
        _ -> []
      }
    })
  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  event_bus.dispatch(
    bus,
    plugin.Command(
      user: "alice",
      name: "ping",
      args: [],
      role: permission.Viewer,
    ),
  )

  let assert Ok(plugin.PluginResponse(plugin: "echo", message: "pong")) =
    process.receive(test_subject, 500)

  event_bus.shutdown(bus)
}

pub fn same_user_command_blocked_by_cooldown_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data
  let test_subject = process.new_subject()

  event_bus.set_cooldown(bus, 60_000)

  let test_plugin =
    Plugin(name: "echo", handle_event: fn(event) {
      case event {
        plugin.Command(user: _, name: "ping", args: _, role: _) -> [
          plugin.PluginResponse(plugin: "echo", message: "pong"),
        ]
        _ -> []
      }
    })
  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  // First call
  event_bus.dispatch(
    bus,
    plugin.Command(
      user: "alice",
      name: "ping",
      args: [],
      role: permission.Viewer,
    ),
  )
  let assert Ok(plugin.PluginResponse(plugin: "echo", message: "pong")) =
    process.receive(test_subject, 500)

  // Second call (same user, same command) - should be blocked
  event_bus.dispatch(
    bus,
    plugin.Command(
      user: "alice",
      name: "ping",
      args: [],
      role: permission.Viewer,
    ),
  )
  let assert Ok(plugin.PluginResponse(plugin: "system", message: _)) =
    process.receive(test_subject, 500)

  event_bus.shutdown(bus)
}

pub fn different_user_not_blocked_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data
  let test_subject = process.new_subject()

  event_bus.set_cooldown(bus, 60_000)

  let test_plugin =
    Plugin(name: "echo", handle_event: fn(event) {
      case event {
        plugin.Command(user: _, name: "ping", args: _, role: _) -> [
          plugin.PluginResponse(plugin: "echo", message: "pong"),
        ]
        _ -> []
      }
    })
  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  // Alice's call
  event_bus.dispatch(
    bus,
    plugin.Command(
      user: "alice",
      name: "ping",
      args: [],
      role: permission.Viewer,
    ),
  )
  let assert Ok(plugin.PluginResponse(plugin: "echo", message: "pong")) =
    process.receive(test_subject, 500)

  // Bob's call - different user, should pass
  event_bus.dispatch(
    bus,
    plugin.Command(user: "bob", name: "ping", args: [], role: permission.Viewer),
  )
  let assert Ok(plugin.PluginResponse(plugin: "echo", message: "pong")) =
    process.receive(test_subject, 500)

  event_bus.shutdown(bus)
}

pub fn chat_message_not_affected_by_cooldown_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data
  let test_subject = process.new_subject()

  event_bus.set_cooldown(bus, 60_000)

  let test_plugin =
    Plugin(name: "echo", handle_event: fn(event) {
      case event {
        plugin.ChatMessage(user: _, content: _, channel: _, channel_id: _) -> [
          plugin.PluginResponse(plugin: "echo", message: "chat"),
        ]
        _ -> []
      }
    })
  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  // First chat message
  event_bus.dispatch(
    bus,
    plugin.ChatMessage(
      user: "alice",
      content: "hi",
      channel: "main",
      channel_id: option.None,
    ),
  )
  let assert Ok(plugin.PluginResponse(plugin: "echo", message: "chat")) =
    process.receive(test_subject, 500)

  // Second chat message - should NOT be blocked
  event_bus.dispatch(
    bus,
    plugin.ChatMessage(
      user: "alice",
      content: "hi again",
      channel: "main",
      channel_id: option.None,
    ),
  )
  let assert Ok(plugin.PluginResponse(plugin: "echo", message: "chat")) =
    process.receive(test_subject, 500)

  event_bus.shutdown(bus)
}
