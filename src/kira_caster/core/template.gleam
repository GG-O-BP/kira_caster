import gleam/dict.{type Dict}
import gleam/string

pub type TemplateError {
  UnmatchedTag(tag: String)
  SyntaxError(detail: String)
}

// AST nodes
type Node {
  Literal(text: String)
  Variable(name: String)
  IfBlock(variable: String, true_branch: List(Node), false_branch: List(Node))
}

// Raw tokens from scanning
type RawToken {
  TextChunk(text: String)
  Tag(content: String)
}

pub fn render(
  template: String,
  context: Dict(String, String),
) -> Result(String, TemplateError) {
  let raw_tokens = scan(template)
  case parse(raw_tokens) {
    Ok(nodes) -> Ok(evaluate(nodes, context))
    Error(e) -> Error(e)
  }
}

// --- Phase 1: Scan template into raw tokens ---

fn scan(input: String) -> List(RawToken) {
  scan_loop(input, [])
  |> reverse_raw
}

fn scan_loop(input: String, acc: List(RawToken)) -> List(RawToken) {
  case string.split_once(input, "{{") {
    Error(Nil) ->
      case input {
        "" -> acc
        _ -> [TextChunk(text: input), ..acc]
      }
    Ok(#(before, rest)) -> {
      let acc2 = case before {
        "" -> acc
        _ -> [TextChunk(text: before), ..acc]
      }
      case string.split_once(rest, "}}") {
        Error(Nil) ->
          // No closing }} — treat the {{ as literal text
          [TextChunk(text: before <> "{{" <> rest), ..acc]
        Ok(#(tag_content, after)) ->
          scan_loop(after, [Tag(content: string.trim(tag_content)), ..acc2])
      }
    }
  }
}

// --- Phase 2: Parse raw tokens into AST ---

fn parse(tokens: List(RawToken)) -> Result(List(Node), TemplateError) {
  case parse_nodes(tokens, False) {
    Ok(#(nodes, [])) -> Ok(nodes)
    Ok(#(_, _remaining)) ->
      Error(SyntaxError(detail: "unexpected tokens after end"))
    Error(e) -> Error(e)
  }
}

fn parse_nodes(
  tokens: List(RawToken),
  in_block: Bool,
) -> Result(#(List(Node), List(RawToken)), TemplateError) {
  parse_nodes_loop(tokens, [], in_block)
}

fn parse_nodes_loop(
  tokens: List(RawToken),
  acc: List(Node),
  in_block: Bool,
) -> Result(#(List(Node), List(RawToken)), TemplateError) {
  case tokens {
    [] ->
      case in_block {
        True -> Error(SyntaxError(detail: "{{if}} without matching {{end}}"))
        False -> Ok(#(reverse_nodes(acc), []))
      }
    [TextChunk(text:), ..rest] ->
      parse_nodes_loop(rest, [Literal(text:), ..acc], in_block)
    [Tag(content: "end"), ..rest] ->
      case in_block {
        True -> Ok(#(reverse_nodes(acc), rest))
        False -> Error(UnmatchedTag(tag: "end"))
      }
    [Tag(content: "else"), ..rest] ->
      case in_block {
        True -> Ok(#(reverse_nodes(acc), [Tag(content: "else"), ..rest]))
        False -> Error(UnmatchedTag(tag: "else"))
      }
    [Tag(content:), ..rest] ->
      case string.starts_with(content, "if ") {
        True -> {
          let var_name = string.drop_start(content, 3) |> string.trim
          case parse_if(var_name, rest) {
            Ok(#(node, remaining)) ->
              parse_nodes_loop(remaining, [node, ..acc], in_block)
            Error(e) -> Error(e)
          }
        }
        False -> {
          // Variable
          parse_nodes_loop(rest, [Variable(name: content), ..acc], in_block)
        }
      }
  }
}

fn parse_if(
  var_name: String,
  tokens: List(RawToken),
) -> Result(#(Node, List(RawToken)), TemplateError) {
  // Parse true branch (stops at {{else}} or {{end}})
  case parse_nodes(tokens, True) {
    Ok(#(true_branch, remaining)) ->
      case remaining {
        [Tag(content: "else"), ..after_else] ->
          // Parse false branch (stops at {{end}})
          case parse_nodes(after_else, True) {
            Ok(#(false_branch, after_end)) ->
              Ok(#(
                IfBlock(variable: var_name, true_branch:, false_branch:),
                after_end,
              ))
            Error(e) -> Error(e)
          }
        _ ->
          Ok(#(
            IfBlock(variable: var_name, true_branch:, false_branch: []),
            remaining,
          ))
      }
    Error(e) -> Error(e)
  }
}

// --- Phase 3: Evaluate AST ---

fn evaluate(nodes: List(Node), context: Dict(String, String)) -> String {
  evaluate_loop(nodes, context, "")
}

fn evaluate_loop(
  nodes: List(Node),
  context: Dict(String, String),
  acc: String,
) -> String {
  case nodes {
    [] -> acc
    [Literal(text:), ..rest] -> evaluate_loop(rest, context, acc <> text)
    [Variable(name:), ..rest] -> {
      let value = case dict.get(context, name) {
        Ok(v) -> v
        Error(Nil) -> ""
      }
      evaluate_loop(rest, context, acc <> value)
    }
    [IfBlock(variable:, true_branch:, false_branch:), ..rest] -> {
      let branch = case dict.get(context, variable) {
        Ok(v) if v != "" -> true_branch
        _ -> false_branch
      }
      let result = evaluate(branch, context)
      evaluate_loop(rest, context, acc <> result)
    }
  }
}

// --- Helpers ---

fn reverse_raw(tokens: List(RawToken)) -> List(RawToken) {
  reverse_raw_loop(tokens, [])
}

fn reverse_raw_loop(
  tokens: List(RawToken),
  acc: List(RawToken),
) -> List(RawToken) {
  case tokens {
    [] -> acc
    [first, ..rest] -> reverse_raw_loop(rest, [first, ..acc])
  }
}

fn reverse_nodes(nodes: List(Node)) -> List(Node) {
  reverse_nodes_loop(nodes, [])
}

fn reverse_nodes_loop(nodes: List(Node), acc: List(Node)) -> List(Node) {
  case nodes {
    [] -> acc
    [first, ..rest] -> reverse_nodes_loop(rest, [first, ..acc])
  }
}
