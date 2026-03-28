import gleam/dynamic/decode
import gleam/int
import gleam/order
import gleam/result
import kira_caster/storage/repository.{
  type SongData, type StorageError, NotFound, QueryError, SongData,
}
import kira_caster/util/time
import sqlight

fn song_data_decoder() -> decode.Decoder(SongData) {
  use id <- decode.field(0, decode.int)
  use video_id <- decode.field(1, decode.string)
  use title <- decode.field(2, decode.string)
  use duration_seconds <- decode.field(3, decode.int)
  use requested_by <- decode.field(4, decode.string)
  use position <- decode.field(5, decode.int)
  use created_at <- decode.field(6, decode.int)
  decode.success(SongData(
    id:,
    video_id:,
    title:,
    duration_seconds:,
    requested_by:,
    position:,
    created_at:,
  ))
}

pub fn get_song_queue(
  conn: sqlight.Connection,
) -> Result(List(SongData), StorageError) {
  sqlight.query(
    "SELECT id, video_id, title, duration_seconds, requested_by, position, created_at FROM song_queue ORDER BY position ASC",
    on: conn,
    with: [],
    expecting: song_data_decoder(),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn add_song(
  conn: sqlight.Connection,
  video_id: String,
  title: String,
  duration: Int,
  user: String,
) -> Result(SongData, StorageError) {
  use max_rows <- result.try(
    sqlight.query(
      "SELECT COALESCE(MAX(position), -1) FROM song_queue",
      on: conn,
      with: [],
      expecting: decode.field(0, decode.int, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  let next_pos = case max_rows {
    [m, ..] -> m + 1
    [] -> 0
  }
  let now = time.now_ms()
  use _ <- result.try(
    sqlight.query(
      "INSERT INTO song_queue (video_id, title, duration_seconds, requested_by, position, created_at) VALUES (?, ?, ?, ?, ?, ?)",
      on: conn,
      with: [
        sqlight.text(video_id),
        sqlight.text(title),
        sqlight.int(duration),
        sqlight.text(user),
        sqlight.int(next_pos),
        sqlight.int(now),
      ],
      expecting: decode.success(Nil),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  use id_rows <- result.try(
    sqlight.query(
      "SELECT last_insert_rowid()",
      on: conn,
      with: [],
      expecting: decode.field(0, decode.int, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  let new_id = case id_rows {
    [id, ..] -> id
    [] -> 0
  }
  Ok(SongData(
    id: new_id,
    video_id:,
    title:,
    duration_seconds: duration,
    requested_by: user,
    position: next_pos,
    created_at: now,
  ))
}

pub fn remove_song(
  conn: sqlight.Connection,
  id: Int,
) -> Result(Nil, StorageError) {
  use pos_rows <- result.try(
    sqlight.query(
      "SELECT position FROM song_queue WHERE id = ?",
      on: conn,
      with: [sqlight.int(id)],
      expecting: decode.field(0, decode.int, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case pos_rows {
    [pos, ..] -> {
      use _ <- result.try(
        sqlight.query(
          "DELETE FROM song_queue WHERE id = ?",
          on: conn,
          with: [sqlight.int(id)],
          expecting: decode.success(Nil),
        )
        |> result.map_error(fn(e) { QueryError(e.message) }),
      )
      sqlight.query(
        "UPDATE song_queue SET position = position - 1 WHERE position > ?",
        on: conn,
        with: [sqlight.int(pos)],
        expecting: decode.success(Nil),
      )
      |> result.map_error(fn(e) { QueryError(e.message) })
      |> result.replace(Nil)
    }
    [] -> Error(NotFound)
  }
}

pub fn clear_song_queue(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  sqlight.exec("DELETE FROM song_queue", on: conn)
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn reorder_song(
  conn: sqlight.Connection,
  id: Int,
  new_pos: Int,
) -> Result(Nil, StorageError) {
  use pos_rows <- result.try(
    sqlight.query(
      "SELECT position FROM song_queue WHERE id = ?",
      on: conn,
      with: [sqlight.int(id)],
      expecting: decode.field(0, decode.int, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case pos_rows {
    [old_pos, ..] -> {
      case old_pos == new_pos {
        True -> Ok(Nil)
        False -> {
          let #(shift_sql, shift_params) = case int.compare(new_pos, old_pos) {
            order.Lt -> #(
              "UPDATE song_queue SET position = position + 1 WHERE position >= ? AND position < ?",
              [sqlight.int(new_pos), sqlight.int(old_pos)],
            )
            _ -> #(
              "UPDATE song_queue SET position = position - 1 WHERE position > ? AND position <= ?",
              [sqlight.int(old_pos), sqlight.int(new_pos)],
            )
          }
          use _ <- result.try(
            sqlight.query(
              shift_sql,
              on: conn,
              with: shift_params,
              expecting: decode.success(Nil),
            )
            |> result.map_error(fn(e) { QueryError(e.message) }),
          )
          sqlight.query(
            "UPDATE song_queue SET position = ? WHERE id = ?",
            on: conn,
            with: [sqlight.int(new_pos), sqlight.int(id)],
            expecting: decode.success(Nil),
          )
          |> result.map_error(fn(e) { QueryError(e.message) })
          |> result.replace(Nil)
        }
      }
    }
    [] -> Error(NotFound)
  }
}

pub fn get_songs_by_user(
  conn: sqlight.Connection,
  user: String,
) -> Result(List(SongData), StorageError) {
  sqlight.query(
    "SELECT id, video_id, title, duration_seconds, requested_by, position, created_at FROM song_queue WHERE requested_by = ? ORDER BY position ASC",
    on: conn,
    with: [sqlight.text(user)],
    expecting: song_data_decoder(),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn has_song_with_video_id(
  conn: sqlight.Connection,
  video_id: String,
) -> Result(Bool, StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT COUNT(*) FROM song_queue WHERE video_id = ?",
      on: conn,
      with: [sqlight.text(video_id)],
      expecting: decode.field(0, decode.int, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [count, ..] -> Ok(count > 0)
    [] -> Ok(False)
  }
}
