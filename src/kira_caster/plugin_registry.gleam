import gleam/list
import kira_caster/plugin/plugin.{type Plugin}

pub type PluginFactory =
  fn() -> Plugin

pub type PluginRegistry {
  PluginRegistry(factories: List(PluginFactory))
}

pub fn new() -> PluginRegistry {
  PluginRegistry(factories: [])
}

pub fn register(
  registry: PluginRegistry,
  factory: PluginFactory,
) -> PluginRegistry {
  PluginRegistry(factories: [factory, ..registry.factories])
}

pub fn build_plugins(registry: PluginRegistry) -> List(Plugin) {
  list.map(registry.factories, fn(f) { f() })
}
