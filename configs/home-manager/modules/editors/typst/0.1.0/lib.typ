/// Function to apply the assignment template to a document.
/// -> content
#let assignment(
  /// The assignment's title. This argument is required.
  /// -> str
  title: "",

  /// The student authoring the assignment.
  /// Only `name` is used.
  /// -> dictionary
  student: (name: ""),

  /// The subject the assignment is for.
  /// Only `code` is used.
  /// -> dictionary
  subject: (code: ""),

  /// The assignment's creation date.
  /// -> none | auto | datetime
  date: datetime.today(),

  /// The assignment's content.
  /// -> content
  body,
) = {
  set document(
    title: title,
    author: student.name,
    // removed subject.name from description
    description: subject.code,
    date: date,
  )

  set text(size: 10pt)

  set page(
    paper: "a4",
    margin: (
      top: 118pt,
      bottom: 96pt,
      x: 128pt,
    ),
    header-ascent: 14pt,
    header: {
      set text(size: 8pt)
      grid(
        columns: (auto, 1fr, auto),
        rows: (auto, auto),
        align: (left, center, right),
        gutter: 6pt,

        // row 1 (removed student.id)
        student.name, subject.code, date.display(),

        // row 2 (removed subject.name)
        "", title, "",
      )
    },
    footer-descent: 12pt,
    footer: context {
      set align(center)
      set text(size: 8pt)
      counter(page).display("1")
    },
  )

  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    set text(size: 10pt, weight: "bold")
    it.body + [.]
  }
  show heading.where(level: 2): it => {
    set text(size: 10pt, weight: "bold")
    it.body + [.]
  }

  set enum(indent: 5pt, numbering: "(aiA)")
  set list(indent: 5pt)

  show quote: set align(center)

  show math.equation: set block(breakable: true)

  set par(leading: 5pt, justify: true)

  body
}

/// Lab template: same as `assignment`, but **does not force a new page** at each level-1 heading.
#let lab(
  /// The lab's title. This argument is required.
  /// -> str
  title: "",

  /// The student authoring the lab.
  /// Only `name` is used.
  /// -> dictionary
  student: (name: ""),

  /// The subject the lab is for.
  /// Only `code` is used.
  /// -> dictionary
  subject: (code: ""),

  /// The lab's creation date.
  /// -> none | auto | datetime
  date: datetime.today(),

  /// The lab's content.
  /// -> content
  body,
) = {
  set document(
    title: title,
    author: student.name,
    description: subject.code,
    date: date,
  )

  set text(size: 10pt)

  set page(
    paper: "a4",
    margin: (
      top: 118pt,
      bottom: 96pt,
      x: 128pt,
    ),
    header-ascent: 14pt,
    header: {
      set text(size: 8pt)
      grid(
        columns: (auto, 1fr, auto),
        rows: (auto, auto),
        align: (left, center, right),
        gutter: 6pt,

        // row 1
        student.name, subject.code, date.display(),

        // row 2
        "", title, "",
      )
    },
    footer-descent: 12pt,
    footer: context {
      set align(center)
      set text(size: 8pt)
      counter(page).display("1")
    },
  )

  // Key difference vs `assignment`: remove the pagebreak on level-1 headings.
  show heading.where(level: 1): it => {
    set text(size: 10pt, weight: "bold")
    it.body + [.]
  }
  show heading.where(level: 2): it => {
    set text(size: 10pt, weight: "bold")
    it.body + [.]
  }

  set enum(indent: 5pt, numbering: "(aiA)")
  set list(indent: 5pt)

  show quote: set align(center)

  show math.equation: set block(breakable: true)

  set par(leading: 5pt, justify: true)

  body
}
