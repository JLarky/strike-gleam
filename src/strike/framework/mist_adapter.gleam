import gleam/http/request
import gleam/http/response
import mist
import strike/framework.{render_html_document, render_rsc_stream}

pub fn rsc_framework_response(req, rsc) {
  let is_rsc = request.get_header(req, "RSC")
  case is_rsc {
    Ok("1") -> {
      response.new(200)
      |> response.set_body(mist.Bytes(render_rsc_stream(rsc)))
      |> response.set_header("content-type", "text/x-component; charset=utf-8")
    }
    _ -> {
      response.new(200)
      |> response.set_body(mist.Bytes(render_html_document(rsc)))
      |> response.set_header("content-type", "text/html")
    }
  }
}
