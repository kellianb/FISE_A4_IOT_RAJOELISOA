// Deliverable styling
#let deliverable(body) = {
  // Page style
  set page(numbering: "1", number-align: right)

  // Heading style
  set heading(numbering: "1.")
  show heading: set block(below: 1.5em, above: 1.5em)

  // Text style
  set par(leading: 1.2em, spacing: 1.7em)

  // Link style
  show link: set text(fill: blue, weight: 700)
  show link: underline

  // Title style
  show title: set text(size: 20pt)
  show title: set align(center)

  // Table style
  show figure.where(kind: table): set block(breakable: true)
  show table: set par(leading: 0.8em, spacing: 1em)
  body
}
