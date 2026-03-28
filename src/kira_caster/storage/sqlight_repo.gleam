import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{
  type Repository, type StorageError, type UserData, ConnectionError, NotFound,
  QueryError, Repository, UserData,
}
import sqlight

pub fn new(db_path: String) -> Result(Repository, StorageError) {
  use conn <- result.try(
    sqlight.open(db_path)
    |> result.map_error(fn(e) { ConnectionError(e.message) }),
  )
  use _ <- result.try(
    sqlight.exec(
      "CREATE TABLE IF NOT EXISTS users (
        user_id TEXT PRIMARY KEY,
        points INTEGER NOT NULL DEFAULT 0,
        attendance_count INTEGER NOT NULL DEFAULT 0,
        last_attendance INTEGER NOT NULL DEFAULT 0
      )",
      on: conn,
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  use _ <- result.try(
    sqlight.exec(
      "CREATE TABLE IF NOT EXISTS banned_words (
        word TEXT PRIMARY KEY
      )",
      on: conn,
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  use _ <- result.try(
    sqlight.exec(
      "CREATE TABLE IF NOT EXISTS custom_commands (
        name TEXT PRIMARY KEY,
        response TEXT NOT NULL
      )",
      on: conn,
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  Ok(
    Repository(
      get_user: fn(user_id) { get_user_impl(conn, user_id) },
      save_user: fn(user_data) { save_user_impl(conn, user_data) },
      get_all_users: fn() { get_all_users_impl(conn) },
      get_banned_words: fn() { get_banned_words_impl(conn) },
      add_banned_word: fn(word) { add_banned_word_impl(conn, word) },
      remove_banned_word: fn(word) { remove_banned_word_impl(conn, word) },
      get_command: fn(name) { get_command_impl(conn, name) },
      set_command: fn(name, response) { set_command_impl(conn, name, response) },
      delete_command: fn(name) { delete_command_impl(conn, name) },
      get_all_commands: fn() { get_all_commands_impl(conn) },
    ),
  )
}

fn user_data_decoder() -> decode.Decoder(UserData) {
  use user_id <- decode.field(0, decode.string)
  use points <- decode.field(1, decode.int)
  use attendance_count <- decode.field(2, decode.int)
  use last_attendance <- decode.field(3, decode.int)
  decode.success(UserData(
    user_id:,
    points:,
    attendance_count:,
    last_attendance:,
  ))
}

fn get_user_impl(
  conn: sqlight.Connection,
  user_id: String,
) -> Result(UserData, StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT user_id, points, attendance_count, last_attendance FROM users WHERE user_id = ?",
      on: conn,
      with: [sqlight.text(user_id)],
      expecting: user_data_decoder(),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [user, ..] -> Ok(user)
    [] -> Error(NotFound)
  }
}

fn save_user_impl(
  conn: sqlight.Connection,
  user_data: UserData,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR REPLACE INTO users (user_id, points, attendance_count, last_attendance) VALUES (?, ?, ?, ?)",
    on: conn,
    with: [
      sqlight.text(user_data.user_id),
      sqlight.int(user_data.points),
      sqlight.int(user_data.attendance_count),
      sqlight.int(user_data.last_attendance),
    ],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

fn get_all_users_impl(
  conn: sqlight.Connection,
) -> Result(List(UserData), StorageError) {
  sqlight.query(
    "SELECT user_id, points, attendance_count, last_attendance FROM users",
    on: conn,
    with: [],
    expecting: user_data_decoder(),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

fn get_banned_words_impl(
  conn: sqlight.Connection,
) -> Result(List(String), StorageError) {
  sqlight.query(
    "SELECT word FROM banned_words",
    on: conn,
    with: [],
    expecting: decode.field(0, decode.string, fn(w) { decode.success(w) }),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

fn add_banned_word_impl(
  conn: sqlight.Connection,
  word: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR IGNORE INTO banned_words (word) VALUES (?)",
    on: conn,
    with: [sqlight.text(word)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

fn remove_banned_word_impl(
  conn: sqlight.Connection,
  word: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "DELETE FROM banned_words WHERE word = ?",
    on: conn,
    with: [sqlight.text(word)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

fn get_command_impl(
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

fn set_command_impl(
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

fn delete_command_impl(
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

fn get_all_commands_impl(
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
