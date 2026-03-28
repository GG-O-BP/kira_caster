import gleam/dynamic/decode
import gleam/result
import gleam/string
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
  use _ <- result.try(run_migrations(conn))
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
      start_vote: fn(topic, options) { start_vote_impl(conn, topic, options) },
      cast_vote: fn(user, choice) { cast_vote_impl(conn, user, choice) },
      get_vote_results: fn() { get_vote_results_impl(conn) },
      get_active_vote: fn() { get_active_vote_impl(conn) },
      end_vote: fn() { end_vote_impl(conn) },
      add_quiz: fn(q, a, r) { add_quiz_impl(conn, q, a, r) },
      delete_quiz: fn(q) { delete_quiz_impl(conn, q) },
      get_all_quizzes: fn() { get_all_quizzes_impl(conn) },
      get_quiz_count: fn() { get_quiz_count_impl(conn) },
      get_disabled_plugins: fn() { get_disabled_plugins_impl(conn) },
      set_plugin_enabled: fn(name, enabled) {
        set_plugin_enabled_impl(conn, name, enabled)
      },
    ),
  )
}

fn run_migrations(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  use _ <- result.try(exec(
    conn,
    "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY)",
  ))
  use version <- result.try(get_schema_version(conn))
  use _ <- result.try(case version < 1 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS users (
        user_id TEXT PRIMARY KEY,
        points INTEGER NOT NULL DEFAULT 0,
        attendance_count INTEGER NOT NULL DEFAULT 0,
        last_attendance INTEGER NOT NULL DEFAULT 0
      )",
      ))
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS banned_words (word TEXT PRIMARY KEY)",
      ))
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS custom_commands (name TEXT PRIMARY KEY, response TEXT NOT NULL)",
      ))
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS votes (id INTEGER PRIMARY KEY, topic TEXT NOT NULL, options TEXT NOT NULL, active INTEGER NOT NULL DEFAULT 1)",
      ))
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS vote_entries (user_id TEXT NOT NULL, choice TEXT NOT NULL, vote_id INTEGER NOT NULL, UNIQUE(user_id, vote_id))",
      ))
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS quizzes (question TEXT PRIMARY KEY, answer TEXT NOT NULL, reward INTEGER NOT NULL DEFAULT 10)",
      ))
      set_schema_version(conn, 1)
    }
    False -> Ok(Nil)
  })
  use version2 <- result.try(get_schema_version(conn))
  case version2 < 2 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS plugin_settings (name TEXT PRIMARY KEY, enabled INTEGER NOT NULL DEFAULT 1)",
      ))
      set_schema_version(conn, 2)
    }
    False -> Ok(Nil)
  }
}

fn get_schema_version(conn: sqlight.Connection) -> Result(Int, StorageError) {
  use rows <- result.try(
    sqlight.query(
      "SELECT version FROM schema_version ORDER BY version DESC LIMIT 1",
      on: conn,
      with: [],
      expecting: decode.field(0, decode.int, fn(v) { decode.success(v) }),
    )
    |> result.map_error(fn(e) { QueryError(e.message) }),
  )
  case rows {
    [v, ..] -> Ok(v)
    [] -> Ok(0)
  }
}

fn set_schema_version(
  conn: sqlight.Connection,
  version: Int,
) -> Result(Nil, StorageError) {
  sqlight.query(
    "INSERT OR IGNORE INTO schema_version (version) VALUES (?)",
    on: conn,
    with: [sqlight.int(version)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

fn exec(conn: sqlight.Connection, sql: String) -> Result(Nil, StorageError) {
  sqlight.exec(sql, on: conn)
  |> result.map_error(fn(e) { QueryError(e.message) })
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

fn start_vote_impl(
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

fn cast_vote_impl(
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

fn get_vote_results_impl(
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

fn get_active_vote_impl(
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

fn end_vote_impl(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  use _ <- result.try(exec(conn, "UPDATE votes SET active = 0 WHERE active = 1"))
  Ok(Nil)
}

fn add_quiz_impl(
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

fn delete_quiz_impl(
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

fn get_all_quizzes_impl(
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

fn get_quiz_count_impl(conn: sqlight.Connection) -> Result(Int, StorageError) {
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

fn get_disabled_plugins_impl(
  conn: sqlight.Connection,
) -> Result(List(String), StorageError) {
  sqlight.query(
    "SELECT name FROM plugin_settings WHERE enabled = 0",
    on: conn,
    with: [],
    expecting: decode.field(0, decode.string, fn(n) { decode.success(n) }),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
}

fn set_plugin_enabled_impl(
  conn: sqlight.Connection,
  name: String,
  enabled: Bool,
) -> Result(Nil, StorageError) {
  let val = case enabled {
    True -> 1
    False -> 0
  }
  sqlight.query(
    "INSERT OR REPLACE INTO plugin_settings (name, enabled) VALUES (?, ?)",
    on: conn,
    with: [sqlight.text(name), sqlight.int(val)],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}
