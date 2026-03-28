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
