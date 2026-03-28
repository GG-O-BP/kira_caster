import kira_caster/storage/repository.{UserData}
import kira_caster/storage/sqlight_repo

pub fn new_opens_database_test() {
  let assert Ok(_repo) = sqlight_repo.new(":memory:")
}

pub fn save_and_get_user_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let user =
    UserData(
      user_id: "alice",
      points: 100,
      attendance_count: 5,
      last_attendance: 0,
    )
  let assert Ok(Nil) = repo.save_user(user)
  let assert Ok(found) = repo.get_user("alice")
  assert found.user_id == "alice"
  assert found.points == 100
  assert found.attendance_count == 5
}

pub fn get_user_not_found_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Error(repository.NotFound) = repo.get_user("nobody")
}

pub fn save_user_upsert_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let user1 =
    UserData(
      user_id: "bob",
      points: 50,
      attendance_count: 1,
      last_attendance: 0,
    )
  let assert Ok(Nil) = repo.save_user(user1)
  let user2 =
    UserData(
      user_id: "bob",
      points: 200,
      attendance_count: 3,
      last_attendance: 0,
    )
  let assert Ok(Nil) = repo.save_user(user2)
  let assert Ok(found) = repo.get_user("bob")
  assert found.points == 200
  assert found.attendance_count == 3
}

pub fn get_all_users_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) =
    repo.save_user(UserData(
      user_id: "alice",
      points: 100,
      attendance_count: 1,
      last_attendance: 0,
    ))
  let assert Ok(Nil) =
    repo.save_user(UserData(
      user_id: "bob",
      points: 50,
      attendance_count: 2,
      last_attendance: 0,
    ))
  let assert Ok(users) = repo.get_all_users()
  assert {
    case users {
      [_, _] -> True
      _ -> False
    }
  }
}

pub fn get_all_users_empty_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(users) = repo.get_all_users()
  assert users == []
}

pub fn add_and_get_banned_words_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.add_banned_word("spam")
  let assert Ok(Nil) = repo.add_banned_word("광고")
  let assert Ok(words) = repo.get_banned_words()
  assert {
    case words {
      [_, _] -> True
      _ -> False
    }
  }
}

pub fn remove_banned_word_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.add_banned_word("spam")
  let assert Ok(Nil) = repo.add_banned_word("광고")
  let assert Ok(Nil) = repo.remove_banned_word("spam")
  let assert Ok(words) = repo.get_banned_words()
  assert words == ["광고"]
}

pub fn add_duplicate_banned_word_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.add_banned_word("spam")
  let assert Ok(Nil) = repo.add_banned_word("spam")
  let assert Ok(words) = repo.get_banned_words()
  assert words == ["spam"]
}

pub fn get_banned_words_empty_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(words) = repo.get_banned_words()
  assert words == []
}

pub fn set_and_get_command_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.set_command("인사", "안녕하세요!")
  let assert Ok(response) = repo.get_command("인사")
  assert response == "안녕하세요!"
}

pub fn get_command_not_found_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Error(repository.NotFound) = repo.get_command("없음")
}

pub fn delete_command_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.set_command("인사", "안녕!")
  let assert Ok(Nil) = repo.delete_command("인사")
  let assert Error(repository.NotFound) = repo.get_command("인사")
}

pub fn get_all_commands_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.set_command("인사", "안녕!")
  let assert Ok(Nil) = repo.set_command("규칙", "규칙을 지켜주세요")
  let assert Ok(commands) = repo.get_all_commands()
  assert {
    case commands {
      [_, _] -> True
      _ -> False
    }
  }
}

pub fn set_command_upsert_test() {
  let assert Ok(repo) = sqlight_repo.new(":memory:")
  let assert Ok(Nil) = repo.set_command("인사", "안녕!")
  let assert Ok(Nil) = repo.set_command("인사", "반가워요!")
  let assert Ok(response) = repo.get_command("인사")
  assert response == "반가워요!"
}
