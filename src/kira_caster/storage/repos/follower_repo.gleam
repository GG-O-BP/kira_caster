import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, QueryError}
import sqlight

pub fn get_known_followers(
  conn: sqlight.Connection,
) -> Result(List(String), StorageError) {
  sqlight.query(
    "SELECT channel_id FROM follower_cache",
    on: conn,
    with: [],
    expecting: decode.field(0, decode.string, fn(id) { decode.success(id) }),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn add_known_follower(
  conn: sqlight.Connection,
  channel_id: String,
  channel_name: String,
  first_seen_at: Int,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR IGNORE INTO follower_cache (channel_id, channel_name, first_seen_at)
     VALUES (?, ?, ?)",
    on: conn,
    with: [
      sqlight.text(channel_id),
      sqlight.text(channel_name),
      sqlight.int(first_seen_at),
    ],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}
