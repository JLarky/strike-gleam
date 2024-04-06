import gleam/dict
import gleam/dynamic.{type Dynamic}

pub type Attribute(msg) {
  SimpleAttribute(key: String, value: String)
  FancyAttribute(
    key: String,
    attribute_name: String,
    value: Dynamic,
    as_property: Bool,
  )
}

pub fn attribute(name: String, value: String) -> Attribute(msg) {
  SimpleAttribute(name, value)
}

pub fn attribute_advanced(
  name: String,
  value: Dynamic,
  attribute_name attr_name: String,
  as_property as_property: Bool,
) -> Attribute(msg) {
  FancyAttribute(name, attr_name, value, as_property: as_property)
}

pub fn async(value: Bool) -> Attribute(msg) {
  attribute_advanced("async", dynamic.from(value), "async", False)
}

pub fn type_(name: String) -> Attribute(msg) {
  attribute("type", name)
}

pub fn charset(value: String) -> Attribute(msg) {
  attribute_advanced("charSet", dynamic.from(value), "charset", False)
}

pub fn src(value: String) -> Attribute(msg) {
  attribute("src", value)
}

pub fn suppress_hydration_warning(value: Bool) -> Attribute(msg) {
  attribute_advanced("suppressHydrationWarning", dynamic.from(value), "", True)
}

pub fn dangerously_set_inner_html(value: String) -> Attribute(msg) {
  attribute_advanced(
    "dangerouslySetInnerHTML",
    dynamic.from(dict.from_list([#("__html", value)])),
    "",
    True,
  )
}

pub fn href(value: String) {
  attribute("href", value)
}

pub fn lang(value: String) {
  attribute("lang", value)
}
