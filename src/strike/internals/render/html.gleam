import gleam/string_builder.{type StringBuilder}

@external(erlang, "Elixir.Phoenix.HTML", "html_escape")
fn elixir_function(i: String) -> #(String, StringBuilder)

pub fn html_escape(text: String) {
  let #(_safe, new_text) = elixir_function(text)
  new_text
}
