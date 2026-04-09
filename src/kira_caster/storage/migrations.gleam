import gleam/dynamic/decode
import gleam/result
import kira_caster/storage/repository.{type StorageError, QueryError}
import sqlight

pub fn run_migrations(conn: sqlight.Connection) -> Result(Nil, StorageError) {
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
  use _ <- result.try(case version2 < 2 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS plugin_settings (name TEXT PRIMARY KEY, enabled INTEGER NOT NULL DEFAULT 1)",
      ))
      set_schema_version(conn, 2)
    }
    False -> Ok(Nil)
  })
  use version3 <- result.try(get_schema_version(conn))
  use _ <- result.try(case version3 < 3 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)",
      ))
      set_schema_version(conn, 3)
    }
    False -> Ok(Nil)
  })
  use version4 <- result.try(get_schema_version(conn))
  use _ <- result.try(case version4 < 4 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "ALTER TABLE custom_commands ADD COLUMN command_type TEXT NOT NULL DEFAULT 'text'",
      ))
      use _ <- result.try(exec(
        conn,
        "ALTER TABLE custom_commands ADD COLUMN source_code TEXT",
      ))
      set_schema_version(conn, 4)
    }
    False -> Ok(Nil)
  })
  use version5 <- result.try(get_schema_version(conn))
  use _ <- result.try(case version5 < 5 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS song_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id TEXT NOT NULL,
        title TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        requested_by TEXT NOT NULL,
        position INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )",
      ))
      set_schema_version(conn, 5)
    }
    False -> Ok(Nil)
  })
  use version6 <- result.try(get_schema_version(conn))
  case version6 < 6 {
    True -> {
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS donation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        channel_id TEXT,
        user_nickname TEXT,
        amount TEXT NOT NULL,
        message TEXT,
        donation_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )",
      ))
      use _ <- result.try(exec(
        conn,
        "CREATE TABLE IF NOT EXISTS follower_cache (
        channel_id TEXT PRIMARY KEY,
        channel_name TEXT NOT NULL,
        first_seen_at INTEGER NOT NULL
      )",
      ))
      set_schema_version(conn, 6)
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
