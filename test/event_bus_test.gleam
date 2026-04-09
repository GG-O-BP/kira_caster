import gleam/erlang/process
import gleam/option
import kira_caster/core/permission
import kira_caster/event_bus
import kira_caster/plugin/plugin.{Plugin}

pub fn start_and_shutdown_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data
  event_bus.shutdown(bus)
}

pub fn subscribe_and_dispatch_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data

  let test_subject = process.new_subject()
  let test_plugin =
    Plugin(name: "test", handle_event: fn(event) {
      case event {
        plugin.Command(user: _, name: "ping", args: _, role: _) -> [
          plugin.PluginResponse(plugin: "test", message: "pong"),
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

  let assert Ok(response) = process.receive(test_subject, 500)
  let assert plugin.PluginResponse(plugin: "test", message: "pong") = response

  event_bus.shutdown(bus)
}

pub fn unsubscribe_removes_plugin_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data

  let test_subject = process.new_subject()
  let test_plugin =
    Plugin(name: "removable", handle_event: fn(_event) {
      [plugin.PluginResponse(plugin: "removable", message: "here")]
    })

  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  event_bus.unsubscribe(bus, "removable")

  event_bus.dispatch(
    bus,
    plugin.ChatMessage(
      user: "a",
      content: "hi",
      channel: "c",
      channel_id: option.None,
    ),
  )

  let result = process.receive(test_subject, 100)
  assert result == Error(Nil)

  event_bus.shutdown(bus)
}

pub fn disabled_plugin_not_called_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data

  let test_subject = process.new_subject()
  let test_plugin =
    Plugin(name: "disableable", handle_event: fn(_event) {
      [
        plugin.PluginResponse(
          plugin: "disableable",
          message: "should not appear",
        ),
      ]
    })

  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  event_bus.set_disabled_plugins(bus, ["disableable"])

  event_bus.dispatch(
    bus,
    plugin.ChatMessage(
      user: "a",
      content: "hi",
      channel: "c",
      channel_id: option.None,
    ),
  )

  let result = process.receive(test_subject, 100)
  assert result == Error(Nil)

  event_bus.shutdown(bus)
}

pub fn re_enable_plugin_receives_events_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data

  let test_subject = process.new_subject()
  let test_plugin =
    Plugin(name: "toggle", handle_event: fn(event) {
      case event {
        plugin.ChatMessage(_, _, _, _) -> [
          plugin.PluginResponse(plugin: "toggle", message: "got it"),
        ]
        _ -> []
      }
    })

  event_bus.subscribe(bus, test_plugin)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  // Disable
  event_bus.set_disabled_plugins(bus, ["toggle"])

  event_bus.dispatch(
    bus,
    plugin.ChatMessage(
      user: "a",
      content: "hi",
      channel: "c",
      channel_id: option.None,
    ),
  )

  let disabled_result = process.receive(test_subject, 100)
  assert disabled_result == Error(Nil)

  // Re-enable
  event_bus.set_disabled_plugins(bus, [])

  event_bus.dispatch(
    bus,
    plugin.ChatMessage(
      user: "a",
      content: "hello",
      channel: "c",
      channel_id: option.None,
    ),
  )

  let assert Ok(response) = process.receive(test_subject, 500)
  let assert plugin.PluginResponse(plugin: "toggle", message: "got it") =
    response

  event_bus.shutdown(bus)
}

pub fn multiple_plugins_test() {
  let assert Ok(started) = event_bus.start()
  let bus = started.data

  let test_subject = process.new_subject()

  let plugin_a =
    Plugin(name: "a", handle_event: fn(event) {
      case event {
        plugin.Command(_, "test", _, _) -> [
          plugin.PluginResponse(plugin: "a", message: "from_a"),
        ]
        _ -> []
      }
    })
  let plugin_b =
    Plugin(name: "b", handle_event: fn(event) {
      case event {
        plugin.Command(_, "test", _, _) -> [
          plugin.PluginResponse(plugin: "b", message: "from_b"),
        ]
        _ -> []
      }
    })

  event_bus.subscribe(bus, plugin_a)
  event_bus.subscribe(bus, plugin_b)
  event_bus.set_response_handler(bus, fn(event) {
    process.send(test_subject, event)
  })

  event_bus.dispatch(
    bus,
    plugin.Command(user: "u", name: "test", args: [], role: permission.Viewer),
  )

  let assert Ok(_r1) = process.receive(test_subject, 500)
  let assert Ok(_r2) = process.receive(test_subject, 500)

  event_bus.shutdown(bus)
}
