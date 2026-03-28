import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/result
import kira_caster/storage/repository.{type StorageError, NotFound, QueryError}
import sqlight

pub fn get_command(
  conn: sqlight.Connection,
  name: String,
) -> Result(String, StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT response FROM custom_commands WHERE name = ?",
      on: conn,
      with: [sqlight.text(name)],
      expecting: decode.field(0, decode.string, fn(r) { decode.success(r) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [response, ..] -> Ok(response)
    [] -> Error(NotFound)
  }
}

pub fn set_command(
  conn: sqlight.Connection,
  name: String,
  response: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR REPLACE INTO custom_commands (name, response) VALUES (?, ?)",
    on: conn,
    with: [sqlight.text(name), sqlight.text(response)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn delete_command(
  conn: sqlight.Connection,
  name: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "DELETE FROM custom_commands WHERE name = ?",
    on: conn,
    with: [sqlight.text(name)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn get_all_commands(
  conn: sqlight.Connection,
) -> Result(List(#(String, String)), StorageError) {
  sqlight.query(
    "SELECT name, response FROM custom_commands",
    on: conn,
    with: [],
    expecting: {
      use name <- decode.field(0, decode.string)
      use response <- decode.field(1, decode.string)
      decode.success(#(name, response))
    },
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn get_command_with_type(
  conn: sqlight.Connection,
  name: String,
) -> Result(#(String, String, Option(String)), StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT response, command_type, source_code FROM custom_commands WHERE name = ?",
      on: conn,
      with: [sqlight.text(name)],
      expecting: {
        use response <- decode.field(0, decode.string)
        use command_type <- decode.field(1, decode.string)
        use source_code <- decode.field(2, decode.optional(decode.string))
        decode.success(#(response, command_type, source_code))
      },
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [row, ..] -> Ok(row)
    [] -> Error(NotFound)
  }
}

pub fn set_advanced_command(
  conn: sqlight.Connection,
  name: String,
  source_code: String,
  fallback_response: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR REPLACE INTO custom_commands (name, response, command_type, source_code) VALUES (?, ?, 'gleam', ?)",
    on: conn,
    with: [
      sqlight.text(name),
      sqlight.text(fallback_response),
      sqlight.text(source_code),
    ],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn get_all_commands_detailed(
  conn: sqlight.Connection,
) -> Result(List(#(String, String, String, Option(String))), StorageError) {
  sqlight.query(
    "SELECT name, response, command_type, source_code FROM custom_commands",
    on: conn,
    with: [],
    expecting: {
      use name <- decode.field(0, decode.string)
      use response <- decode.field(1, decode.string)
      use command_type <- decode.field(2, decode.string)
      use source_code <- decode.field(3, decode.optional(decode.string))
      decode.success(#(name, response, command_type, source_code))
    },
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}
