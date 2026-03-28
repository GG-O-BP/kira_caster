import gleam/list

pub type StorageError {
  NotFound
  ConnectionError(reason: String)
  QueryError(reason: String)
}

pub type UserData {
  UserData(user_id: String, points: Int, attendance_count: Int)
}

pub type Repository {
  Repository(
    get_user: fn(String) -> Result(UserData, StorageError),
    save_user: fn(UserData) -> Result(Nil, StorageError),
    get_all_users: fn() -> Result(List(UserData), StorageError),
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
  )
}
