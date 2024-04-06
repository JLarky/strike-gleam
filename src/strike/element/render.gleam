import gleam/bytes_builder.{type BytesBuilder}
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/result
import strike/attribute.{type Attribute, FancyAttribute, SimpleAttribute}
import strike/element.{type Element, Element, Text}
import glentities/html_encoder
import gleam/string_builder.{type StringBuilder}

pub fn element_to_string(element: Element(a)) -> String {
  element
  |> element_to_string_builder
  |> string_builder.to_string
}

pub fn element_to_bytes_builder(element: Element(a)) -> BytesBuilder {
  element
  |> element_to_string_builder
  |> bytes_builder.from_string_builder
}

pub fn element_to_string_builder(element: Element(a)) -> StringBuilder {
  case element {
    Text(text) -> {
      text
      |> html_encoder.encode
      |> string_builder.from_string
    }
    Element(tag, attrs, children, _self_closing, _void) -> {
      let #(attr_str, raw) = attributes_to_string_builder(attrs)
      let output = string_builder.from_string("<" <> tag)
      let output =
        output
        |> string_builder.append_builder(attr_str)
        |> string_builder.append(">")
        |> string_builder.append_builder(
          children
          |> list.map(element_to_string_builder)
          |> string_builder.concat,
        )
      output
      |> string_builder.append_builder(raw)
      |> string_builder.append("</" <> tag <> ">")
    }
    x -> {
      io.debug(x)
      string_builder.new()
    }
  }
}

fn attributes_to_string_builder(
  attributes: List(Attribute(msg)),
) -> #(StringBuilder, StringBuilder) {
  let #(raw, y) =
    list.map_fold(
      over: attributes,
      from: string_builder.new(),
      with: attribute_to_string_builder,
    )
  #(string_builder.concat(y), raw)
}

// #("", "")
fn attribute_to_string_builder(
  raw: StringBuilder,
  attribute: Attribute(msg),
) -> #(StringBuilder, StringBuilder) {
  case attribute {
    SimpleAttribute(key, value) -> {
      #(raw, do_attribute_to_string_builder(key, value))
    }
    FancyAttribute("dangerouslySetInnerHTML", "", value, as_property: True) -> {
      let new_raw =
        value
        |> dynamic.field(named: "__html", of: dynamic.string)
        |> result.unwrap("")
        |> string_builder.from_string()
      #(new_raw, string_builder.new())
    }
    FancyAttribute(_key, _attribute_name, _value, as_property: True) -> {
      #(raw, string_builder.new())
    }
    FancyAttribute(_key, attribute_name, value, as_property: False) -> {
      let value =
        dynamic.any(of: [
          dynamic.string,
          fn(x) {
            result.map(dynamic.bool(x), fn(x) {
              case x {
                True -> "true"
                False -> "false"
              }
            })
          },
          fn(x) {
            result.map(dynamic.bool(x), fn(x) {
              case x {
                True -> "true"
                False -> "false"
              }
            })
          },
        ])(value)
      #(
        raw,
        do_attribute_to_string_builder(attribute_name, result.unwrap(value, "")),
      )
    }
  }
}

fn do_attribute_to_string_builder(key: String, value: String) -> StringBuilder {
  string_builder.from_string(" ")
  // FIXME: is it safe not to escape the key?
  |> string_builder.append(key)
  |> string_builder.append("=\"")
  // FIXME: is this safe to encode the value this way?
  |> string_builder.append(html_encoder.encode(value))
  |> string_builder.append("\"")
}
