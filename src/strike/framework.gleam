import gleam/bytes_builder
import gleam/json
import gleam/list
import strike/attribute.{async, dangerously_set_inner_html, src, type_}
import strike/element
import strike/element/html
import strike/element/json as element_json
import strike/element/render

pub fn render_rsc_stream(rsc) {
  json.to_string_builder(element_json.to_json(rsc))
  |> bytes_builder.from_string_builder()
}

pub fn render_html_document(rsc) {
  let rsc_string =
    json.to_string(json.string(json.to_string(element_json.to_json(rsc))))

  let new_rsc =
    element.update_children(rsc, fn(children) {
      case children {
        [] -> []
        [body] -> [rewrite_body(body, rsc_string)]
        [head, body, ..rest] -> [
          rewrite_head(head),
          rewrite_body(body, rsc_string),
          ..rest
        ]
      }
    })

  let rsc_html = render.element_to_bytes_builder(new_rsc)

  "<!DOCTYPE html>"
  |> bytes_builder.from_string()
  |> bytes_builder.append_builder(rsc_html)
}

fn rewrite_head(head) {
  let import_maps =
    "{
      \"imports\": {
        \"strike_islands\": \"/_strike/app.js\",
        \"react\": \"https://esm.sh/react@0.0.0-experimental-9ba1bbd65-20230922?dev\",
        \"react-dom/client\": \"https://esm.sh/react-dom@0.0.0-experimental-9ba1bbd65-20230922/client?dev\",
        \"react-dom\": \"https://esm.sh/react-dom@0.0.0-experimental-9ba1bbd65-20230922?dev\",
        \"react/jsx-runtime\": \"https://esm.sh/react@0.0.0-experimental-9ba1bbd65-20230922/jsx-runtime?dev\",
        \"react-error-boundary\": \"https://esm.sh/react-error-boundary@4.0.11\"
      }
    }"

  element.update_children(head, fn(existing) {
    existing
    |> list.append([
      html.script_raw([
        type_("importmap"),
        dangerously_set_inner_html(import_maps),
      ]),
      html.script(
        [async(True), type_("module"), src("/_strike/bootstrap.js")],
        "",
      ),
    ])
  })
}

fn rewrite_body(body, rsc_string) {
  element.update_children(body, fn(existing) {
    existing
    |> list.append([
      html.script_raw([
        dangerously_set_inner_html(
          "self.__rsc=self.__rsc||[];__rsc.push(" <> rsc_string <> ");",
        ),
      ]),
    ])
  })
}
