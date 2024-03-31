import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/json
import mist.{type Connection, type ResponseData}
import strike/element/html
import strike/element/json as element_json
import strike/element.{text}
import strike/attribute.{suppress_hydration_warning, type_}

pub fn main() {
  let import_maps =
    "{
      \"imports\": {
        \"strike_islands\": \"/_strike/islands.js\",
        \"react\": \"https://esm.sh/react@0.0.0-experimental-9ba1bbd65-20230922?dev\",
        \"react-dom/client\": \"https://esm.sh/react-dom@0.0.0-experimental-9ba1bbd65-20230922/client?dev\",
        \"react-dom\": \"https://esm.sh/react-dom@0.0.0-experimental-9ba1bbd65-20230922?dev\",
        \"react/jsx-runtime\": \"https://esm.sh/react@0.0.0-experimental-9ba1bbd65-20230922/jsx-runtime?dev\",
        \"react-error-boundary\": \"https://esm.sh/react-error-boundary@4.0.11\"
      }
    }"

  let head =
    html.head([], [
      html.title([], "Strike!!!"),
      html.script([type_("importmap")], import_maps),
    ])
  let rsc =
    html.html([suppress_hydration_warning(True)], [
      head,
      html.body([], [html.div([], [text("Hello, world!!!")])]),
    ])

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
          response.new(200)
          |> response.set_body(
            mist.Bytes(bytes_builder.from_string("<!DOCTYPE html>
              <html><head><title>From html</title><script type=\"importmap\">" <> import_maps <> "</script><script async type='module' src='/_strike/bootstrap.js'></script></head><body><div>Hello, world!!!</div><script>self.__rsc=self.__rsc||[];__rsc.push(" <> json.to_string(
              json.string(json.to_string(element_json.to_json(rsc))),
            ) <> ");</script></body>
            </html>")),
          )
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
    |> mist.port(3000)
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
