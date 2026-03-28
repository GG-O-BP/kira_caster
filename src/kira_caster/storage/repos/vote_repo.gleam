import gleam/dynamic/decode
import gleam/result
import gleam/string
import kira_caster/storage/repository.{type StorageError, NotFound, QueryError}
import sqlight

pub fn start_vote(
  conn: sqlight.Connection,
  topic: String,
  options: List(String),
) -> Result(Nil, StorageError) {
  use _ <- result.try(exec(conn, "UPDATE votes SET active = 0 WHERE active = 1"))
  sqlight.query(
    "INSERT INTO votes (topic, options, active) VALUES (?, ?, 1)",
    on: conn,
    with: [sqlight.text(topic), sqlight.text(string.join(options, "|"))],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn cast_vote(
  conn: sqlight.Connection,
  user_id: String,
  choice: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR REPLACE INTO vote_entries (user_id, choice, vote_id) SELECT ?, ?, id FROM votes WHERE active = 1",
    on: conn,
    with: [sqlight.text(user_id), sqlight.text(choice)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn get_vote_results(
  conn: sqlight.Connection,
) -> Result(List(#(String, Int)), StorageError) {
  sqlight.query(
    "SELECT ve.choice, COUNT(*) as cnt FROM vote_entries ve JOIN votes v ON ve.vote_id = v.id WHERE v.active = 1 GROUP BY ve.choice ORDER BY cnt DESC",
    on: conn,
    with: [],
    expecting: {
      use choice <- decode.field(0, decode.string)
      use count <- decode.field(1, decode.int)
      decode.success(#(choice, count))
    },
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn get_active_vote(
  conn: sqlight.Connection,
) -> Result(#(String, List(String)), StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT topic, options FROM votes WHERE active = 1 LIMIT 1",
      on: conn,
      with: [],
      expecting: {
        use topic <- decode.field(0, decode.string)
        use options_str <- decode.field(1, decode.string)
        decode.success(#(topic, string.split(options_str, "|")))
      },
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [vote, ..] -> Ok(vote)
    [] -> Error(NotFound)
  }
}

pub fn end_vote(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  use _ <- result.try(exec(conn, "UPDATE votes SET active = 0 WHERE active = 1"))
  Ok(Nil)
}

fn exec(conn: sqlight.Connection, sql: String) -> Result(Nil, StorageError) {
  sqlight.exec(sql, on: conn)
  |> result.map_error(fn(e) { QueryError(e.message) })
}
