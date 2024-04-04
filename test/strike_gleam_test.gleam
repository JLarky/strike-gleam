import gleeunit
import gleeunit/should
import strike/attribute
import strike/element.{text}
import strike/element/html
import strike/element/render

pub fn main() {
  gleeunit.main()
}

pub fn text_test() {
  let el = element.text("<strike/>")
  el
  |> render.element_to_string
  |> should.equal("&lt;strike/&gt;")
}

pub fn title_test() {
  let el = html.title([], "Strike!!!")
  el
  |> render.element_to_string
  |> should.equal("<title>Strike!!!</title>")
}

pub fn title_with_attribute_test() {
  let el = html.title([attribute.type_("test")], "Strike!!!")
  el
  |> render.element_to_string
  |> should.equal("<title type=\"test\">Strike!!!</title>")
}

pub fn html_with_charset_test() {
  let el = html.html([attribute.charset("utf-8")], [])
  el
  |> render.element_to_string
  |> should.equal("<html charset=\"utf-8\"></html>")
}

pub fn nested_divs_test() {
  let el = html.div([], [html.div([], [text("1")]), html.div([], [text("2")])])
  el
  |> render.element_to_string
  |> should.equal("<div><div>1</div><div>2</div></div>")
}

pub fn script_raw_test() {
  let el =
    html.script_raw([
      attribute.dangerously_set_inner_html("console.log('hello')"),
    ])
  el
  |> render.element_to_string
  |> should.equal("<script>console.log('hello')</script>")
}

pub fn script_async_test() {
  let el = html.script([attribute.async(True)], "")
  el
  |> render.element_to_string
  |> should.equal("<script async=\"true\"></script>")
}
