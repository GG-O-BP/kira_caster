import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, QueryError}
import sqlight

pub fn get_disabled_plugins(
  conn: sqlight.Connection,
) -> Result(List(String), StorageError) {
  sqlight.query(
    "SELECT name FROM plugin_settings WHERE enabled = 0",
    on: conn,
    with: [],
    expecting: decode.field(0, decode.string, fn(n) { decode.success(n) }),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn set_plugin_enabled(
  conn: sqlight.Connection,
  name: String,
  enabled: Bool,
) -> Result(Nil, StorageError) {
  let val = case enabled {
    True -> 1
    False -> 0
  }
  sqlight.query(
    "INSERT OR REPLACE INTO plugin_settings (name, enabled) VALUES (?, ?)",
    on: conn,
    with: [sqlight.text(name), sqlight.int(val)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}
