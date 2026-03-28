import gleam/int
import kira_caster/storage/repository.{type Repository}

pub fn get_setting_int(repo: Repository, key: String, default: Int) -> Int {
  case repo.get_setting(key) {
    Ok(val) ->
      case int.parse(val) {
        Ok(n) -> n
        Error(_) -> default
      }
    Error(_) -> default
  }
}

pub fn get_setting_bool(repo: Repository, key: String, default: Bool) -> Bool {
  case repo.get_setting(key) {
    Ok("true") -> True
    Ok("false") -> False
    _ -> default
  }
}

pub fn get_setting_str(repo: Repository, key: String, default: String) -> String {
  case repo.get_setting(key) {
    Ok(val) -> val
    Error(_) -> default
  }
}

pub fn list_at(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [], _ -> Error(Nil)
    [first, ..], 0 -> Ok(first)
    [_, ..rest], n -> list_at(rest, n - 1)
  }
}
