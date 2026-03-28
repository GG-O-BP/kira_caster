import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{
  type StorageError, type UserData, NotFound, QueryError, UserData,
}
import sqlight

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

pub fn get_user(
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

pub fn save_user(
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

pub fn get_all_users(
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
