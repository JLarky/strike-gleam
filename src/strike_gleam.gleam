import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/erlang/os
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}
import strike/element/html
import strike/element.{text}
import strike/attribute.{suppress_hydration_warning}
import strike/framework.{render_html_document}

pub fn main() {
  // These values are for the Websocket process initialized below
  let selector = process.new_selector()
  let state = Nil

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        [] -> {
          let head = html.head([], [html.title([], "Strike!")])
          let body = html.body([], [html.div([], [text("Hello, world!")])])
          let rsc = html.html([suppress_hydration_warning(True)], [head, body])

          response.new(200)
          |> response.set_body(mist.Bytes(render_html_document(rsc)))
          |> response.set_header("content-type", "text/html")
        }
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: fn(_conn) { #(state, Some(selector)) },
            on_close: fn(_state) { io.println("goodbye!") },
            handler: handle_ws_message,
          )
        ["echo"] -> echo_body(req)
        ["chunk"] -> serve_chunk(req)
        ["_strike", ..rest] -> serve_file(req, list.concat([["assets"], rest]))
        ["form"] -> handle_form(req)

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

pub type MyMessage {
  Broadcast(String)
}

fn handle_ws_message(state, conn, message) {
  case message {
    mist.Text("ping") -> {
      let assert Ok(_) = mist.send_text_frame(conn, "pong")
      actor.continue(state)
    }
    mist.Text(_) | mist.Binary(_) -> {
      actor.continue(state)
    }
    mist.Custom(Broadcast(text)) -> {
      let assert Ok(_) = mist.send_text_frame(conn, text)
      actor.continue(state)
    }
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}

fn echo_body(request: Request(Connection)) -> Response(ResponseData) {
  let content_type =
    request
    |> request.get_header("content-type")
    |> result.unwrap("text/plain")

  mist.read_body(request, 1024 * 1024 * 10)
  |> result.map(fn(req) {
    response.new(200)
    |> response.set_body(mist.Bytes(bytes_builder.from_bit_array(req.body)))
    |> response.set_header("content-type", content_type)
  })
  |> result.lazy_unwrap(fn() {
    response.new(400)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn serve_chunk(_request: Request(Connection)) -> Response(ResponseData) {
  let iter =
    ["one", "two", "three"]
    |> iterator.from_list
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

fn handle_form(req: Request(Connection)) -> Response(ResponseData) {
  let _req = mist.read_body(req, 1024 * 1024 * 30)
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.new()))
}

fn guess_content_type(path: String) -> String {
  case string.split(path, ".") {
    [_, "html"] -> "text/html"
    [_, "js"] -> "application/javascript"
    [_, "css"] -> "text/css"
    _ -> "application/octet-stream"
  }
}
