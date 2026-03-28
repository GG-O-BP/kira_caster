import gleam/result

pub type CommandError {
  CompileFailed(reason: String)
  RuntimeError(reason: String)
}

@external(erlang, "kira_caster_ffi", "ensure_custom_project")
fn ensure_custom_project_ffi() -> Result(Nil, String)

@external(erlang, "kira_caster_ffi", "compile_gleam")
fn compile_gleam_ffi(name: String, source: String) -> Result(Nil, String)

@external(erlang, "kira_caster_ffi", "call_command")
fn call_command_ffi(
  name: String,
  user: String,
  args: List(String),
) -> Result(String, String)

@external(erlang, "kira_caster_ffi", "unload_command")
fn unload_command_ffi(name: String) -> Nil

pub fn ensure_project() -> Result(Nil, CommandError) {
  ensure_custom_project_ffi()
  |> result.map_error(CompileFailed)
}

pub fn compile_and_load(
  name: String,
  source: String,
) -> Result(Nil, CommandError) {
  compile_gleam_ffi(name, source)
  |> result.map_error(CompileFailed)
}

pub fn execute(
  name: String,
  user: String,
  args: List(String),
) -> Result(String, CommandError) {
  call_command_ffi(name, user, args)
  |> result.map_error(RuntimeError)
}

pub fn unload(name: String) -> Nil {
  unload_command_ffi(name)
}

pub fn error_to_string(err: CommandError) -> String {
  case err {
    CompileFailed(reason) -> "컴파일 실패: " <> reason
    RuntimeError(reason) -> "실행 오류: " <> reason
  }
}
