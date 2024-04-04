import gleam/io
import strike/attribute.{type Attribute, FancyAttribute, SimpleAttribute}
import strike/element.{type Element, Element, Text}
import gleam/json.{type Json}
import gleam/list
import gleam/dynamic.{type DecodeError}
import gleam/result

pub fn to_json(element: Element(a)) -> Json {
  case element {
    Text(text) -> {
      json.object([#("text", json.string(text))])
      json.preprocessed_array([json.string("$strike:text"), json.string(text)])
    }
    Element(tag, attrs, children, _self_closing, _void) -> {
      let props = list.filter_map(attrs, attr_to_json)
      let children = case children {
        [child] -> to_json(child)
        _ -> json.preprocessed_array(list.map(children, to_json))
      }
      let props = list.key_set(props, "children", children)

      json.preprocessed_array([
        json.string("$strike:element"),
        json.string(tag),
        json.object(props),
      ])
      // json.preprocessed_array(list.map(attrs, fn(x) { json.string("attr") })),
    }
    x -> {
      io.debug(x)
      json.string("x")
    }
  }
}

pub fn attr_to_json(
  attr: Attribute(msg),
) -> Result(#(String, Json), List(DecodeError)) {
  case attr {
    SimpleAttribute(key, value) -> {
      Ok(#(key, json.string(value)))
    }
    FancyAttribute(key, _attr_name, value, _) -> {
      dynamic.any(of: [
        fn(x) {
          result.map(dynamic.string(x), fn(x) { #(key, json.string(x)) })
        },
        fn(x) { result.map(dynamic.bool(x), fn(x) { #(key, json.bool(x)) }) },
      ])(value)
    }
  }
}
