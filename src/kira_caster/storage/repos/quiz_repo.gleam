import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, QueryError}
import sqlight

pub fn add_quiz(
  conn: sqlight.Connection,
  question: String,
  answer: String,
  reward: Int,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR REPLACE INTO quizzes (question, answer, reward) VALUES (?, ?, ?)",
    on: conn,
    with: [sqlight.text(question), sqlight.text(answer), sqlight.int(reward)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn delete_quiz(
  conn: sqlight.Connection,
  question: String,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "DELETE FROM quizzes WHERE question = ?",
    on: conn,
    with: [sqlight.text(question)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

pub fn get_all_quizzes(
  conn: sqlight.Connection,
) -> Result(List(#(String, String, Int)), StorageError) {
  sqlight.query(
    "SELECT question, answer, reward FROM quizzes",
    on: conn,
    with: [],
    expecting: {
      use question <- decode.field(0, decode.string)
      use answer <- decode.field(1, decode.string)
      use reward <- decode.field(2, decode.int)
      decode.success(#(question, answer, reward))
    },
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

pub fn get_quiz_count(conn: sqlight.Connection) -> Result(Int, StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT COUNT(*) FROM quizzes",
      on: conn,
      with: [],
      expecting: decode.field(0, decode.int, fn(c) { decode.success(c) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [count, ..] -> Ok(count)
    [] -> Ok(0)
  }
}
