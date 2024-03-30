// MIT: https://github.com/lustre-labs/lustre/blob/main/src/lustre/element/html.gleam

import strike/element.{type Attribute, type Element, element}

pub fn div(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element("div", attrs, children)
}
