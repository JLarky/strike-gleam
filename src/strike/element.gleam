// MIT: https://github.com/lustre-labs/lustre/blob/main/src/lustre/element.gleam

import strike/attribute.{type Attribute}

pub fn text(content: String) -> Element(msg) {
  Text(content)
}

pub fn island(name, attrs, children, ssr_fallback) -> Element(msg) {
  Island(name, attrs, children, ssr_fallback)
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
    | "wbr" -> Element(tag, attrs, [], False, True)
    _ ->
      Element(
        tag: tag,
        attrs: attrs,
        children: children,
        self_closing: False,
        void: False,
      )
  }
}

pub fn advanced(
  tag: String,
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
  self_closing: Bool,
  void: Bool,
) -> Element(msg) {
  Element(
    tag: tag,
    attrs: attrs,
    children: children,
    self_closing: self_closing,
    void: void,
  )
}

pub type Element(msg) {
  Text(content: String)
  Island(
    name: String,
    attrs: List(Attribute(msg)),
    children: List(Element(msg)),
    ssr_fallback: List(Element(msg)),
  )
  Element(
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

pub fn update_children(
  parent: Element(msg),
  children_update: fn(List(Element(msg))) -> List(Element(msg)),
) -> Element(msg) {
  case parent {
    Element(tag, attrs, existing_children, self_closing, void) ->
      Element(
        tag: tag,
        attrs: attrs,
        children: children_update(existing_children),
        self_closing: self_closing,
        void: void,
      )
    _ -> parent
  }
}
