import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, NotFound, QueryError}
import sqlight

pub fn get_all_settings(
  conn: sqlight.Connection,
) -> Result(List(#(String, String)), StorageError) {
  sqlight.query(
    "SELECT key, value FROM settings",
    on: conn,
    with: [],
    expecting: {
      use key <- decode.field(0, decode.string)
      use value <- decode.field(1, decode.string)
      decode.success(#(key, value))
    },
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn get_setting(
  conn: sqlight.Connection,
  key: String,
) -> Result(String, StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT value FROM settings WHERE key = ?",
      on: conn,
      with: [sqlight.text(key)],
      expecting: decode.field(0, decode.string, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [value, ..] -> Ok(value)
    [] -> Error(NotFound)
  }
}

pub fn set_setting(
  conn: sqlight.Connection,
  key: String,
  value: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
    on: conn,
    with: [sqlight.text(key), sqlight.text(value)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}
