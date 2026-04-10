import lustre/element.{type Element}
import wisp.{type Response}

pub fn page(
  title title: String,
  head head: String,
  body body: Element(msg),
  tail tail: String,
) -> Response {
  let body_html = element.to_string(body)
  wisp.html_response(
    "<!DOCTYPE html><html lang=\"ko\"><head>"
      <> "<meta charset=\"UTF-8\">"
      <> "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
      <> "<title>"
      <> title
      <> "</title>"
      <> head
      <> "</head><body>"
      <> body_html
      <> tail
      <> "</body></html>",
    200,
  )
}
