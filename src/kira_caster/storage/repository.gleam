import gleam/list

pub type StorageError {
  NotFound
  ConnectionError(reason: String)
  QueryError(reason: String)
}

pub type UserData {
  UserData(
    user_id: String,
    points: Int,
    attendance_count: Int,
    last_attendance: Int,
  )
}

pub type Repository {
  Repository(
    get_user: fn(String) -> Result(UserData, StorageError),
    save_user: fn(UserData) -> Result(Nil, StorageError),
    get_all_users: fn() -> Result(List(UserData), StorageError),
    get_banned_words: fn() -> Result(List(String), StorageError),
    add_banned_word: fn(String) -> Result(Nil, StorageError),
    remove_banned_word: fn(String) -> Result(Nil, StorageError),
    get_command: fn(String) -> Result(String, StorageError),
    set_command: fn(String, String) -> Result(Nil, StorageError),
    delete_command: fn(String) -> Result(Nil, StorageError),
    get_all_commands: fn() -> Result(List(#(String, String)), StorageError),
    start_vote: fn(String, List(String)) -> Result(Nil, StorageError),
    cast_vote: fn(String, String) -> Result(Nil, StorageError),
    get_vote_results: fn() -> Result(List(#(String, Int)), StorageError),
    get_active_vote: fn() -> Result(#(String, List(String)), StorageError),
    end_vote: fn() -> Result(Nil, StorageError),
    add_quiz: fn(String, String, Int) -> Result(Nil, StorageError),
    delete_quiz: fn(String) -> Result(Nil, StorageError),
    get_all_quizzes: fn() -> Result(List(#(String, String, Int)), StorageError),
    get_quiz_count: fn() -> Result(Int, StorageError),
  )
}

pub fn mock_repo(users: List(UserData)) -> Repository {
  Repository(
    get_user: fn(user_id) {
      case list.find(users, fn(u) { u.user_id == user_id }) {
        Ok(user) -> Ok(user)
        Error(_) -> Error(NotFound)
      }
    },
    save_user: fn(_user_data) { Ok(Nil) },
    get_all_users: fn() { Ok(users) },
    get_banned_words: fn() { Ok([]) },
    add_banned_word: fn(_word) { Ok(Nil) },
    remove_banned_word: fn(_word) { Ok(Nil) },
    get_command: fn(_name) { Error(NotFound) },
    set_command: fn(_name, _response) { Ok(Nil) },
    delete_command: fn(_name) { Ok(Nil) },
    get_all_commands: fn() { Ok([]) },
    start_vote: fn(_topic, _options) { Ok(Nil) },
    cast_vote: fn(_user, _choice) { Ok(Nil) },
    get_vote_results: fn() { Ok([]) },
    get_active_vote: fn() { Error(NotFound) },
    end_vote: fn() { Ok(Nil) },
    add_quiz: fn(_q, _a, _r) { Ok(Nil) },
    delete_quiz: fn(_q) { Ok(Nil) },
    get_all_quizzes: fn() { Ok([]) },
    get_quiz_count: fn() { Ok(0) },
  )
}

pub fn mock_repo_with_words(
  users: List(UserData),
  words: List(String),
) -> Repository {
  let base = mock_repo(users)
  Repository(..base, get_banned_words: fn() { Ok(words) })
}

pub fn mock_repo_with_commands(
  users: List(UserData),
  commands: List(#(String, String)),
) -> Repository {
  let base = mock_repo(users)
  Repository(
    ..base,
    get_command: fn(name) {
      case list.find(commands, fn(c) { c.0 == name }) {
        Ok(#(_, response)) -> Ok(response)
        Error(_) -> Error(NotFound)
      }
    },
    get_all_commands: fn() { Ok(commands) },
  )
}

pub fn mock_repo_with_vote(
  users: List(UserData),
  topic: String,
  options: List(String),
  results: List(#(String, Int)),
) -> Repository {
  let base = mock_repo(users)
  Repository(
    ..base,
    get_active_vote: fn() { Ok(#(topic, options)) },
    get_vote_results: fn() { Ok(results) },
  )
}
