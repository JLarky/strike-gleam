import gleam/dynamic
import strike/element.{type Attribute, Attribute}

pub fn attribute(name: String, value: String) -> Attribute(msg) {
  Attribute(name, dynamic.from(value), as_property: False)
}

pub fn type_(name: String) -> Attribute(msg) {
  attribute("type", name)
}

pub fn suppress_hydration_warning(value: Bool) -> Attribute(msg) {
  Attribute("suppressHydrationWarning", dynamic.from(value), as_property: False)
}
