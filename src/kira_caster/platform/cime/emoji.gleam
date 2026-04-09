import gleam/dict.{type Dict}
import gleam/string

/// Strip emoji tokens from content, replacing with empty string
pub fn strip_tokens(content: String) -> String {
  replace_tokens(content, fn(_) { "" })
}

/// Replace emoji tokens with a placeholder
pub fn replace_with_placeholder(content: String) -> String {
  replace_tokens(content, fn(_) { "[이모티콘]" })
}

/// Replace emoji tokens with img tags using the emoji URL mapping
pub fn to_html(content: String, emojis: Dict(String, String)) -> String {
  dict.fold(emojis, content, fn(acc, token, url) {
    string.replace(
      acc,
      token,
      "<img src=\"" <> url <> "\" class=\"emoji\" alt=\"emoji\">",
    )
  })
}

fn replace_tokens(content: String, replacer: fn(String) -> String) -> String {
  do_replace_tokens(content, "", False, "", replacer)
}

fn do_replace_tokens(
  remaining: String,
  result: String,
  in_token: Bool,
  token_acc: String,
  replacer: fn(String) -> String,
) -> String {
  case string.pop_grapheme(remaining) {
    Error(_) -> {
      case in_token {
        True -> result <> ":" <> token_acc
        False -> result
      }
    }
    Ok(#(":", rest)) -> {
      case in_token {
        True -> {
          // End of token
          let full_token = ":" <> token_acc <> ":"
          let replacement = replacer(full_token)
          do_replace_tokens(rest, result <> replacement, False, "", replacer)
        }
        False -> {
          // Start of potential token
          do_replace_tokens(rest, result, True, "", replacer)
        }
      }
    }
    Ok(#(char, rest)) -> {
      case in_token {
        True ->
          do_replace_tokens(rest, result, True, token_acc <> char, replacer)
        False ->
          do_replace_tokens(rest, result <> char, False, token_acc, replacer)
      }
    }
  }
}
