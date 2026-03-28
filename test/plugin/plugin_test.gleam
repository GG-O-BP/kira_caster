import kira_caster/plugin/plugin

pub fn noop_handler_returns_empty_test() {
  let events = plugin.noop_handler(plugin.ChatMessage("alice", "hi", "main"))
  assert events == []
}

pub fn plugin_handle_delegates_test() {
  let p =
    plugin.new("test", fn(_event) { [plugin.PluginResponse("test", "ok")] })
  let events = plugin.handle(p, plugin.ChatMessage("alice", "hi", "main"))
  assert events == [plugin.PluginResponse("test", "ok")]
}

pub fn plugin_name_test() {
  let p = plugin.new("my_plugin", plugin.noop_handler)
  assert p.name == "my_plugin"
}
