// MIT: https://github.com/lustre-labs/lustre/blob/main/src/lustre/element/html.gleam

import strike/attribute.{type Attribute}
import strike/element.{type Element, element, text}

pub fn div(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element("div", attrs, children)
}

pub fn script(attrs: List(Attribute(msg)), js: String) -> Element(msg) {
  element("script", attrs, [text(js)])
}

pub fn script_raw(attrs: List(Attribute(msg))) -> Element(msg) {
  element("script", attrs, [])
}

pub fn html(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element("html", attrs, children)
}

pub fn meta(attrs: List(Attribute(msg))) -> Element(msg) {
  element("meta", attrs, [])
}

pub fn head(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element("head", attrs, children)
}

pub fn body(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element("body", attrs, children)
}

pub fn title(attrs: List(Attribute(msg)), title: String) -> Element(msg) {
  element("title", attrs, [text(title)])
}

pub fn a(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("a", attrs, children)
}

pub fn nav(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("nav", attrs, children)
}

pub fn footer(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("footer", attrs, children)
}

pub fn button(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("button", attrs, children)
}

pub fn table(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("table", attrs, children)
}

pub fn tbody(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("tbody", attrs, children)
}

pub fn tr(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("tr", attrs, children)
}

pub fn td(attrs: List(Attribute(msg)), children: List(Element(msg))) {
  element("td", attrs, children)
}
