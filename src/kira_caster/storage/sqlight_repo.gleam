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
        attendance_count INTEGER NOT NULL DEFAULT 0
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
    ),
  )
}

fn user_data_decoder() -> decode.Decoder(UserData) {
  use user_id <- decode.field(0, decode.string)
  use points <- decode.field(1, decode.int)
  use attendance_count <- decode.field(2, decode.int)
  decode.success(UserData(user_id:, points:, attendance_count:))
}

fn get_user_impl(
  conn: sqlight.Connection,
  user_id: String,
) -> Result(UserData, StorageError) {
  let result =
    sqlight.query(
      "SELECT user_id, points, attendance_count FROM users WHERE user_id = ?",
      on: conn,
      with: [sqlight.text(user_id)],
      expecting: user_data_decoder(),
    )
    |> result.map_error(fn(e) { QueryError(e.message) })
  use rows <- result.try(result)
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
    "INSERT OR REPLACE INTO users (user_id, points, attendance_count) VALUES (?, ?, ?)",
    on: conn,
    with: [
      sqlight.text(user_data.user_id),
      sqlight.int(user_data.points),
      sqlight.int(user_data.attendance_count),
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
    "SELECT user_id, points, attendance_count FROM users",
    on: conn,
    with: [],
    expecting: user_data_decoder(),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}
