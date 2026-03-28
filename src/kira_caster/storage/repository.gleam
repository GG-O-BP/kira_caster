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
