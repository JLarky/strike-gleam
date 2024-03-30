// MIT: https://github.com/lustre-labs/lustre/blob/main/src/lustre/element.gleam

import gleam/dynamic.{type Decoder, type Dynamic}

pub fn text(content: String) -> Element(msg) {
  Text(content)
}

pub fn element(
  tag: String,
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  case tag {
    "area"
    | "base"
    | "br"
    | "col"
    | "embed"
    | "hr"
    | "img"
    | "input"
    | "link"
    | "meta"
    | "param"
    | "source"
    | "track"
    | "wbr" -> Element("", tag, attrs, [], False, True)
    _ ->
      Element(
        namespace: "",
        tag: tag,
        attrs: attrs,
        children: children,
        self_closing: False,
        void: False,
      )
  }
}

pub fn advanced(
  namespace: String,
  tag: String,
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
  self_closing: Bool,
  void: Bool,
) -> Element(msg) {
  Element(
    namespace: namespace,
    tag: tag,
    attrs: attrs,
    children: children,
    self_closing: self_closing,
    void: void,
  )
}

pub type Element(msg) {
  Text(content: String)
  Element(
    namespace: String,
    tag: String,
    attrs: List(Attribute(msg)),
    children: List(Element(msg)),
    self_closing: Bool,
    void: Bool,
  )
  // The lambda here defers the creation of the mapped subtree until it is necessary.
  // This means we pay the cost of mapping multiple times only *once* during rendering.
  Map(subtree: fn() -> Element(msg))
}

pub type Attribute(msg) {
  Attribute(String, Dynamic, as_property: Bool)
  Event(String, Decoder(msg))
}
