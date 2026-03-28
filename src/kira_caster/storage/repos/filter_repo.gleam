import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, QueryError}
import sqlight

pub fn get_banned_words(
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

pub fn add_banned_word(
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

pub fn remove_banned_word(
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
