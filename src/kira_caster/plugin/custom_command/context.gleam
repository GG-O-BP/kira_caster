import gleam/dict
import gleam/int
import gleam/string
import kira_caster/storage/repository.{type Repository}

pub fn build_context(
  repo: Repository,
  user: String,
  command: String,
  args: List(String),
) -> dict.Dict(String, String) {
  let ctx =
    dict.new()
    |> dict.insert("user", user)
    |> dict.insert("command", command)
    |> dict.insert("args", string.join(args, " "))
  let ctx = insert_args_indexed(ctx, args, 0)
  case repo.get_user(user) {
    Ok(user_data) ->
      ctx
      |> dict.insert("points", int.to_string(user_data.points))
      |> dict.insert("attendance", int.to_string(user_data.attendance_count))
    Error(_) -> ctx
  }
}

fn insert_args_indexed(
  ctx: dict.Dict(String, String),
  args: List(String),
  index: Int,
) -> dict.Dict(String, String) {
  case args {
    [] -> ctx
    [first, ..rest] ->
      insert_args_indexed(
        dict.insert(ctx, "args." <> int.to_string(index), first),
        rest,
        index + 1,
      )
  }
}
