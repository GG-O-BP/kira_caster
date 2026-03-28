import gleam/dict
import kira_caster/core/template

pub fn plain_text_unchanged_test() {
  let assert Ok(result) = template.render("안녕하세요!", dict.new())
  assert result == "안녕하세요!"
}

pub fn empty_template_test() {
  let assert Ok(result) = template.render("", dict.new())
  assert result == ""
}

pub fn variable_substitution_test() {
  let ctx = dict.from_list([#("user", "alice")])
  let assert Ok(result) = template.render("{{user}}님 안녕!", ctx)
  assert result == "alice님 안녕!"
}

pub fn multiple_variables_test() {
  let ctx = dict.from_list([#("user", "alice"), #("command", "인사")])
  let assert Ok(result) = template.render("{{user}}님이 !{{command}} 실행", ctx)
  assert result == "alice님이 !인사 실행"
}

pub fn args_index_test() {
  let ctx = dict.from_list([#("args.0", "빨강"), #("args.1", "파랑")])
  let assert Ok(result) = template.render("{{args.0}} vs {{args.1}}", ctx)
  assert result == "빨강 vs 파랑"
}

pub fn missing_variable_renders_empty_test() {
  let assert Ok(result) = template.render("X{{없는변수}}Y", dict.new())
  assert result == "XY"
}

pub fn if_with_value_test() {
  let ctx = dict.from_list([#("args", "hello")])
  let assert Ok(result) = template.render("{{if args}}인자: {{args}}{{end}}", ctx)
  assert result == "인자: hello"
}

pub fn if_without_value_test() {
  let assert Ok(result) =
    template.render("{{if args}}인자: {{args}}{{end}}", dict.new())
  assert result == ""
}

pub fn if_else_true_branch_test() {
  let ctx = dict.from_list([#("args", "hi")])
  let assert Ok(result) = template.render("{{if args}}있음{{else}}없음{{end}}", ctx)
  assert result == "있음"
}

pub fn if_else_false_branch_test() {
  let assert Ok(result) =
    template.render("{{if args}}있음{{else}}없음{{end}}", dict.new())
  assert result == "없음"
}

pub fn nested_variable_in_if_test() {
  let ctx = dict.from_list([#("user", "alice"), #("points", "100")])
  let assert Ok(result) =
    template.render("{{if points}}{{user}}님 포인트: {{points}}{{end}}", ctx)
  assert result == "alice님 포인트: 100"
}

pub fn mixed_korean_template_test() {
  let ctx = dict.from_list([#("user", "밥"), #("args", "가위")])
  let assert Ok(result) = template.render("{{user}}님이 {{args}}를 선택했습니다!", ctx)
  assert result == "밥님이 가위를 선택했습니다!"
}

pub fn unmatched_end_returns_error_test() {
  let result = template.render("hello {{end}}", dict.new())
  assert result == Error(template.UnmatchedTag(tag: "end"))
}

pub fn unmatched_else_returns_error_test() {
  let result = template.render("hello {{else}}", dict.new())
  assert result == Error(template.UnmatchedTag(tag: "else"))
}

pub fn if_without_end_returns_error_test() {
  let result = template.render("{{if x}}hello", dict.new())
  assert result
    == Error(template.SyntaxError(detail: "{{if}} without matching {{end}}"))
}

pub fn unclosed_tag_treated_as_literal_test() {
  let assert Ok(result) = template.render("hello {{ no close", dict.new())
  assert result == "hello {{ no close"
}

pub fn empty_variable_in_if_is_false_test() {
  let ctx = dict.from_list([#("args", "")])
  let assert Ok(result) =
    template.render("{{if args}}yes{{else}}no{{end}}", ctx)
  assert result == "no"
}

pub fn text_around_if_block_test() {
  let ctx = dict.from_list([#("vip", "true")])
  let assert Ok(result) = template.render("안녕 {{if vip}}VIP {{end}}유저님", ctx)
  assert result == "안녕 VIP 유저님"
}
