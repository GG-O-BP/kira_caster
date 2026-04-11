import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/string
import kira_caster/core/quiz_data
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
  use _ <- result.try(case version6 < 6 {
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
  })
  use version7 <- result.try(get_schema_version(conn))
  use _ <- result.try(case version7 < 7 {
    True -> {
      use _ <- result.try(seed_default_quizzes(conn))
      set_schema_version(conn, 7)
    }
    False -> Ok(Nil)
  })
  use version8 <- result.try(get_schema_version(conn))
  case version8 < 8 {
    True -> {
      use _ <- result.try(seed_sample_commands(conn))
      set_schema_version(conn, 8)
    }
    False -> Ok(Nil)
  }
}

fn seed_default_quizzes(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  quiz_data.all()
  |> list.try_each(fn(q) {
    let answer = string.join(q.answers, ",")
    sqlight.query(
      "INSERT OR IGNORE INTO quizzes (question, answer, reward) VALUES (?, ?, ?)",
      on: conn,
      with: [
        sqlight.text(q.question),
        sqlight.text(answer),
        sqlight.int(q.reward),
      ],
      expecting: decode.success(Nil),
    )
    |> result.map_error(fn(e) { QueryError(e.message) })
    |> result.replace(Nil)
  })
}

fn seed_sample_commands(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  let text_sql =
    "INSERT OR IGNORE INTO custom_commands (name, response, command_type) VALUES (?, ?, 'text')"
  let gleam_sql =
    "INSERT OR IGNORE INTO custom_commands (name, response, command_type, source_code) VALUES (?, ?, 'gleam', ?)"
  // 1. 단순 텍스트 (변수 없음)
  use _ <- result.try(
    sqlight.query(
      text_sql,
      on: conn,
      with: [
        sqlight.text("인사"),
        sqlight.text("반갑습니다~ 채팅 매너를 지키면서 즐거운 방송 시간 보내봐용!"),
      ],
      expecting: decode.success(Nil),
    )
    |> result.map_error(fn(e) { QueryError(e.message) })
    |> result.replace(Nil),
  )
  // 2. 템플릿 (변수 + 조건문)
  use _ <- result.try(
    sqlight.query(
      text_sql,
      on: conn,
      with: [
        sqlight.text("내정보"),
        sqlight.text(
          "{{user}}님 | 포인트: {{points}} | 출석: {{attendance}}회{{if points}} \u{2728}{{else}} (첫 출석을 해보세용!){{end}}",
        ),
      ],
      expecting: decode.success(Nil),
    )
    |> result.map_error(fn(e) { QueryError(e.message) })
    |> result.replace(Nil),
  )
  // 3. 고급 Gleam (주사위)
  sqlight.query(
    gleam_sql,
    on: conn,
    with: [
      sqlight.text("dice"),
      sqlight.text("주사위 명령어이에용~ (컴파일이 필요해용)"),
      sqlight.text(dice_sample_source()),
    ],
    expecting: decode.success(Nil),
  )
  |> result.map_error(fn(e) { QueryError(e.message) })
  |> result.replace(Nil)
}

fn dice_sample_source() -> String {
  "import gleam/int
import gleam/list
import gleam/string

pub fn handle(user: String, args: List(String)) -> String {
  let sides =
    args
    |> list.first
    |> fn(r) {
      case r {
        Ok(n) ->
          n
          |> int.parse
          |> fn(p) {
            case p {
              Ok(v) if v > 1 -> v
              _ -> 6
            }
          }
        _ -> 6
      }
    }

  let roll = int.random(sides) + 1

  let grade = case roll == sides, roll == 1 {
    True, _ -> \" *** CRITICAL! ***\"
    _, True -> \" ... fumble\"
    _, _ -> \"\"
  }

  [user, \" rolled d\", sides |> int.to_string, \" -> \"]
  |> string.concat
  |> string.append(roll |> int.to_string)
  |> string.append(grade)
}"
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
