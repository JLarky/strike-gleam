import gleam/bit_array
import gleam/bytes_builder
import gleam/crypto.{Sha256}
import gleam/erlang
import gleam/erlang/os
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/iterator
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}
import strike/attribute.{
  attribute, charset, dyn_attribute, href, lang, suppress_hydration_warning,
}
import strike/element.{island, text}
import strike/element/html
import strike/framework/mist_adapter.{rsc_framework_response}
import strike/internals/counter_server
import strike/internals/test_data_server

pub fn main() {
  let assert Ok(counter_server) = counter_server.new()
  let assert Ok(test_data_server) = test_data_server.new()

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        [] -> handle_rsc_request(counter_server, req)
        ["ssr-benchmark"] -> handle_table_request(test_data_server, req)
        ["about"] -> handle_rsc_request(counter_server, req)
        ["chunk"] -> serve_chunk(req)
        ["_strike", ..rest] -> serve_file(req, list.concat([["assets"], rest]))

        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port({
      let port =
        os.get_env("PORT")
        |> result.try(int.parse)
        |> result.unwrap(3000)
      port
    })
    |> mist.start_http

  process.sleep_forever()
}

fn handle_table_request(test_data_server, req) {
  let page =
    html.html([lang("en")], [
      html.head([], [
        //
        html.meta([charset("utf-8")]),
        html.meta([
          attribute("name", "viewport"),
          attribute("content", "width=device-width, initial-scale=1"),
        ]),
      ]),
      // html.body([], [table(test_data_server.test_data())]),
      html.body([], [table(test_data_server.get(test_data_server))]),
    ])

  rsc_framework_response(req, page)
}

fn table(data) {
  html.table([], [
    html.tbody(
      [],
      list.map(data, fn(row) {
        let #(id, name) = row
        entry(id, name)
      }),
    ),
  ])
}

fn entry(id, name) {
  html.tr([], [html.td([], [text(id)]), html.td([], [text(name)])])
}

fn handle_rsc_request(counter_server, req) {
  let sha256 =
    crypto.strong_random_bytes(32)
    |> crypto.hash(Sha256, _)
    |> bit_array.base64_encode(True)
  let nav =
    html.nav([], [
      html.a([href("/")], [text("Home")]),
      text(" "),
      html.a([href("/about")], [text("About")]),
    ])
  let footer =
    html.footer([], [
      html.a([href("https://github.com/JLarky/strike-gleam")], [
        text("see source"),
      ]),
    ])

  let island_el = case request.to_uri(req).path {
    "/" -> {
      let counter = counter_server.get(counter_server)
      island("Counter", [dyn_attribute("serverCounter", counter)], [], [
        html.div([], [text("Loading...")]),
      ])
    }
    _ -> {
      let counter = counter_server.inc(counter_server)
      island("Counter", [dyn_attribute("serverCounter", counter)], [], [
        html.button([], [text("Count: 0 (" <> int.to_string(counter) <> ")")]),
      ])
    }
  }
  let body =
    html.div([], [
      nav,
      html.div([], [
        html.div([], [text("My page is " <> request.to_uri(req).path)]),
        html.div([], [
          text("and I generated this sha256 on the server: " <> sha256),
        ]),
        island_el,
      ]),
      footer,
    ])
  let page =
    html.html([lang("en"), suppress_hydration_warning(True)], [
      html.head([], [html.title([], "Title " <> request.to_uri(req).path)]),
      html.body([], [body]),
    ])

  rsc_framework_response(req, page)
}

pub type MyMessage {
  Broadcast(String)
}

fn serve_chunk(_request: Request(Connection)) -> Response(ResponseData) {
  let iter2 = {
    process.sleep(1000)
    use <- iterator.yield("1")
    process.sleep(1000)
    use <- iterator.yield("two")
    process.sleep(1000)
    use <- iterator.yield("drei")
    process.sleep(1000)
    iterator.empty()
  }
  let iter =
    iter2
    |> iterator.map(bytes_builder.from_string)

  response.new(200)
  |> response.set_body(mist.Chunked(iter))
  |> response.set_header("content-type", "text/plain")
}

fn serve_file(
  _req: Request(Connection),
  path: List(String),
) -> Response(ResponseData) {
  let file_path = string.join(path, "/")
  let assert Ok(priv_dir) = erlang.priv_directory("strike_gleam")
  let file_path = priv_dir <> "/" <> file_path

  // Omitting validation for brevity
  mist.send_file(file_path, offset: 0, limit: None)
  |> result.map(fn(file) {
    let content_type = guess_content_type(file_path)
    response.new(200)
    |> response.prepend_header("content-type", content_type)
    |> response.set_body(file)
  })
  |> result.lazy_unwrap(fn() {
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn guess_content_type(path: String) -> String {
  case string.split(path, ".") {
    [_, "html"] -> "text/html"
    [_, "js"] -> "application/javascript"
    [_, "css"] -> "text/css"
    _ -> "application/octet-stream"
  }
}
