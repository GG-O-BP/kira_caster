import kira_caster/plugin/advanced_command

@external(erlang, "kira_caster_test_ffi", "clean_custom_commands")
fn clean_custom_commands() -> Nil

// All tests in a single function to avoid concurrent gleam build conflicts
// (gleeunit runs tests concurrently, but gleam build on the same project is not thread-safe)
pub fn advanced_command_lifecycle_test() {
  clean_custom_commands()
  let assert Ok(Nil) = advanced_command.ensure_project()

  // 1. Compile and execute valid Gleam code
  let source =
    "pub fn handle(user: String, _args: List(String)) -> String {
  user <> \"님 안녕!\"
}
"
  let assert Ok(Nil) = advanced_command.compile_and_load("lifecycle", source)
  let assert Ok(result) = advanced_command.execute("lifecycle", "alice", [])
  assert result == "alice님 안녕!"
  advanced_command.unload("lifecycle")

  // 2. Compile invalid code returns error
  let bad_source = "this is not valid gleam code !!!"
  let bad_result =
    advanced_command.compile_and_load("lifecycle_bad", bad_source)
  case bad_result {
    Error(advanced_command.CompileFailed(_)) -> Nil
    _ -> panic as "Expected CompileFailed error"
  }

  // 3. Execute nonexistent module returns error
  let no_result =
    advanced_command.execute("nonexistent_module_xyz", "alice", [])
  case no_result {
    Error(advanced_command.RuntimeError(_)) -> Nil
    _ -> panic as "Expected RuntimeError"
  }
}

pub fn error_to_string_test() {
  let err = advanced_command.CompileFailed(reason: "syntax error")
  assert advanced_command.error_to_string(err) == "컴파일 실패: syntax error"
  let err2 = advanced_command.RuntimeError(reason: "undef")
  assert advanced_command.error_to_string(err2) == "실행 오류: undef"
}
