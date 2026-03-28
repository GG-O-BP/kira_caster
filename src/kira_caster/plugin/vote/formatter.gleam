import gleam/int
import gleam/string

pub fn format_results(results: List(#(String, Int))) -> String {
  case results {
    [] -> ""
    _ ->
      results
      |> format_results_loop([])
      |> string.join("\n")
  }
}

fn format_results_loop(
  results: List(#(String, Int)),
  acc: List(String),
) -> List(String) {
  case results {
    [] -> list_reverse(acc)
    [#(choice, count), ..rest] ->
      format_results_loop(rest, [
        choice <> ": " <> int.to_string(count) <> "표",
        ..acc
      ])
  }
}

pub fn list_contains(items: List(String), target: String) -> Bool {
  case items {
    [] -> False
    [first, ..rest] ->
      case first == target {
        True -> True
        False -> list_contains(rest, target)
      }
  }
}

fn list_reverse(items: List(a)) -> List(a) {
  list_reverse_loop(items, [])
}

fn list_reverse_loop(items: List(a), acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [first, ..rest] -> list_reverse_loop(rest, [first, ..acc])
  }
}
