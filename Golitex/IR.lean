namespace Golitex.IR

/-!
# Golitex Intermediate Representation

This module defines the semantic intermediate representation (IR) for Golitex documents.
The IR is a structured representation that captures the meaning of Litex/LaTeX constructs
independent of their concrete syntax. This representation is used by backends to generate
output formats like PDF and HTML.
-/

/-- Text formatting options -/
inductive TextStyle where
  | plain
  | emph
  | bold
  | typewriter
  | italic
  deriving Repr, Inhabited, BEq

/-- Inline content that can appear within paragraphs -/
inductive Inline where
  | text (content : String) (style : TextStyle := .plain)
  | command (name : String) (args : List Inline)
  | math (content : String) (display : Bool := false)
  | space
  | lineBreak
  deriving Repr, Inhabited

/-- Block-level elements -/
inductive Block where
  | paragraph (content : List Inline)
  | section (level : Nat) (title : List Inline) (label : Option String := none)
  | environment (name : String) (args : List String) (content : List Block)
  | list (ordered : Bool) (items : List (List Block))
  | quote (content : List Block)
  | verbatim (content : String)
  | raw (format : String) (content : String)
  deriving Repr, Inhabited

/-- Document metadata -/
structure Metadata where
  title : Option String := none
  author : Option String := none
  date : Option String := none
  keywords : List String := []
  abstract : Option (List Block) := none
  deriving Repr, Inhabited

/-- Complete document representation -/
structure Document where
  metadata : Metadata := {}
  content : List Block := []
  raw : String := ""
  deriving Repr, Inhabited

/-- Helper to create a text inline element -/
def text (s : String) (style : TextStyle := .plain) : Inline :=
  Inline.text s style

/-- Helper to create a paragraph -/
def paragraph (inlines : List Inline) : Block :=
  Block.paragraph inlines

/-- Helper to create a section -/
def mkSection (level : Nat) (title : String) : Block :=
  Block.section level [text title]

/-- Convert inline content to plain text (for debugging/testing) -/
def Inline.toPlainText : Inline → String
  | .text content _ => content
  | .command name args => "\\" ++ name ++ "{" ++ String.join (args.map toPlainText) ++ "}"
  | .math content display => if display then "$$" ++ content ++ "$$" else "$" ++ content ++ "$"
  | .space => " "
  | .lineBreak => "\n"

/-- Convert block content to plain text (for debugging/testing) -/
partial def Block.toPlainText : Block → String
  | .paragraph inlines => String.join (inlines.map Inline.toPlainText) ++ "\n\n"
  | .section level title _ => 
      String.mk (List.replicate level '#') ++ " " ++ 
      String.join (title.map Inline.toPlainText) ++ "\n\n"
  | .environment name _ content =>
      "\\begin{" ++ name ++ "}\n" ++
      String.join (content.map toPlainText) ++
      "\\end{" ++ name ++ "}\n\n"
  | .list ordered items =>
      let marker := if ordered then "1. " else "* "
      String.join (items.map fun item => 
        marker ++ String.join (item.map toPlainText)) ++ "\n"
  | .quote content =>
      "> " ++ String.join (content.map toPlainText)
  | .verbatim content =>
      "```\n" ++ content ++ "\n```\n"
  | .raw _ content => content

end Golitex.IR