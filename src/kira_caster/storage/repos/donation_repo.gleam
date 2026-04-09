import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, QueryError}
import sqlight

pub fn save_donation(
  conn: sqlight.Connection,
  channel_id: String,
  user_nickname: String,
  amount: String,
  message: String,
  donation_type: String,
  created_at: Int,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT INTO donation_history (channel_id, user_nickname, amount, message, donation_type, created_at)
     VALUES (?, ?, ?, ?, ?, ?)",
    on: conn,
    with: [
      sqlight.text(channel_id),
      sqlight.text(user_nickname),
      sqlight.text(amount),
      sqlight.text(message),
      sqlight.text(donation_type),
      sqlight.int(created_at),
    ],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn get_donation_ranking(
  conn: sqlight.Connection,
  limit: Int,
) -> Result(List(#(String, String)), StorageError) {
  let decoder =
    decode.field(0, decode.string, fn(nickname) {
      decode.field(1, decode.string, fn(total) {
        decode.success(#(nickname, total))
      })
    })

  sqlight.query(
    "SELECT user_nickname, CAST(SUM(CAST(amount AS INTEGER)) AS TEXT) as total
     FROM donation_history
     WHERE channel_id IS NOT NULL
     GROUP BY user_nickname
     ORDER BY SUM(CAST(amount AS INTEGER)) DESC
     LIMIT ?",
    on: conn,
    with: [sqlight.int(limit)],
    expecting: decoder,
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}
