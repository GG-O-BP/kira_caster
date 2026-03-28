import gleam/list
import kira_caster/plugin/plugin
import kira_caster/plugin_registry

pub fn new_registry_empty_test() {
  let registry = plugin_registry.new()
  let plugins = plugin_registry.build_plugins(registry)
  assert plugins == []
}

pub fn register_and_build_test() {
  let registry =
    plugin_registry.new()
    |> plugin_registry.register(fn() {
      plugin.new("test_a", plugin.noop_handler)
    })
    |> plugin_registry.register(fn() {
      plugin.new("test_b", plugin.noop_handler)
    })
  let plugins = plugin_registry.build_plugins(registry)
  assert list.length(plugins) == 2
}

pub fn build_creates_fresh_instances_test() {
  let registry =
    plugin_registry.new()
    |> plugin_registry.register(fn() {
      plugin.new("fresh", plugin.noop_handler)
    })
  let p1 = plugin_registry.build_plugins(registry)
  let p2 = plugin_registry.build_plugins(registry)
  assert list.length(p1) == 1
  assert list.length(p2) == 1
}
