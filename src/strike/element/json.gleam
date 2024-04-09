import gleam/io
import strike/attribute.{type Attribute, FancyAttribute, SimpleAttribute}
import strike/element.{type Element, Element, Island, Map, Text}
import gleam/json.{type Json}
import gleam/list
import gleam/dynamic.{type DecodeError}
import gleam/result

pub fn to_json(element: Element(a)) -> Json {
  case element {
    Text(text) -> {
      json.preprocessed_array([json.string("$strike:text"), json.string(text)])
    }
    Element(tag, attrs, children, _self_closing, _void) -> {
      let props = to_props(attrs, children)

      json.preprocessed_array([
        json.string("$strike:element"),
        json.string(tag),
        json.object(props),
      ])
    }
    Map(generator) -> {
      to_json(generator())
    }
    Island(name, attrs, children, ssr_fallback) -> {
      let props = to_props(attrs, children)
      json.preprocessed_array([
        json.string("$strike:island"),
        json.string(name),
        json.object(props),
        json.preprocessed_array(list.map(ssr_fallback, to_json)),
      ])
    }
  }
}

fn to_props(attrs, children) {
  let props = list.filter_map(attrs, attr_to_json)
  let children = case children {
    [child] -> to_json(child)
    _ -> json.preprocessed_array(list.map(children, to_json))
  }
  let props = list.key_set(props, "children", children)
  props
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
        fn(x) { result.map(dynamic.int(x), fn(x) { #(key, json.int(x)) }) },
      ])(value)
    }
  }
}
