import gleam/list
import lustre/attribute.{attribute as attr}
import lustre/element.{type Element, text}
import lustre/element/html

pub fn tab(name: String, label: String, active: Bool) -> Element(msg) {
  html.div(
    [
      attribute.class(case active {
        True -> "tab active"
        False -> "tab"
      }),
      attr("onclick", "showTab('" <> name <> "',this)"),
    ],
    [text(label)],
  )
}

pub fn panel(
  name: String,
  active: Bool,
  children: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.id(name),
      attribute.class(case active {
        True -> "panel active"
        False -> "panel"
      }),
    ],
    children,
  )
}

pub fn form_row(children: List(Element(msg))) -> Element(msg) {
  html.div([attribute.class("form-row")], children)
}

pub fn styled_form_row(
  style: String,
  children: List(Element(msg)),
) -> Element(msg) {
  html.div([attribute.class("form-row"), attr("style", style)], children)
}

pub fn data_table(table_id: String, headers: List(String)) -> Element(msg) {
  html.table([attribute.id(table_id)], [
    html.thead([], [
      html.tr([], list.map(headers, fn(h) { html.th([], [text(h)]) })),
    ]),
    html.tbody([], []),
  ])
}

pub fn btn(label: String, handler: String) -> Element(msg) {
  html.button([attr("onclick", handler)], [text(label)])
}

pub fn danger_btn(label: String, handler: String) -> Element(msg) {
  html.button([attribute.class("danger"), attr("onclick", handler)], [
    text(label),
  ])
}

pub fn success_btn(label: String, handler: String) -> Element(msg) {
  html.button([attribute.class("success"), attr("onclick", handler)], [
    text(label),
  ])
}

pub fn text_input(input_id: String, ph: String) -> Element(msg) {
  html.input([attribute.id(input_id), attribute.placeholder(ph)])
}

pub fn styled_input(input_id: String, ph: String, style: String) -> Element(msg) {
  html.input([
    attribute.id(input_id),
    attribute.placeholder(ph),
    attr("style", style),
  ])
}

pub fn number_input(
  input_id: String,
  ph: String,
  default_value: String,
  style: String,
) -> Element(msg) {
  html.input([
    attribute.id(input_id),
    attribute.type_("number"),
    attribute.placeholder(ph),
    attribute.value(default_value),
    attr("style", style),
  ])
}

pub fn section_heading(label: String) -> Element(msg) {
  html.h3([attr("style", "margin-bottom:12px")], [text(label)])
}

pub fn section_heading_top(label: String) -> Element(msg) {
  html.h3([attr("style", "margin-top:16px;margin-bottom:12px")], [text(label)])
}

pub fn info_card(
  card_id: String,
  extra_style: String,
  content: String,
) -> Element(msg) {
  let base = "padding:12px;background:rgba(253,113,155,.08);border-radius:8px"
  let style = case extra_style {
    "" -> base
    s -> base <> ";" <> s
  }
  html.div([attribute.id(card_id), attr("style", style)], [text(content)])
}
