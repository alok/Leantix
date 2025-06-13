/-
Copyright (c) 2025 Golitex Contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Verso
import Golitex

/-!
# Golitex Verso Genre

This module defines Golitex as a Verso genre, allowing Golitex's LaTeX-like DSL
to be used within Verso documents. This creates a powerful authoring system
where LaTeX mathematical content can be seamlessly integrated with Verso's
documentation capabilities.
-/

open Verso Doc
open Golitex

namespace GolitexGenre

/-! ## Genre Extensions

Golitex extends Verso with:
- Inline elements: LaTeX commands, math expressions
- Block elements: sections, environments, display math
- Part metadata: LaTeX preamble settings
-/

/-- Inline Golitex elements that can appear within text -/
inductive GolitexInline where
  | command (name : String) (args : Array String)
  | math (content : String)
  | ref (label : String)
  | cite (keys : Array String)
deriving Inhabited, Repr, BEq

/-- Block-level Golitex elements -/
inductive GolitexBlock where
  | environment (name : String) (args : Array String) (content : Array (Block Golitex))
  | displayMath (content : String)
  | include (file : String)
  | rawLatex (content : String)
deriving Inhabited, Repr, BEq

/-- Metadata for Golitex document parts -/
structure GolitexMetadata where
  label : Option String := none
  preamble : Array String := #[]
  bibliography : Option String := none
deriving Inhabited, Repr, BEq

/-- Context for traversing Golitex documents -/
structure GolitexContext where
  /-- Current section depth -/
  depth : Nat := 0
  /-- Document class and options -/
  documentClass : String := "article"
  /-- Active packages -/
  packages : Array String := #[]
  /-- Custom macro definitions -/
  macros : Std.HashMap String String := {}
deriving Inhabited, Repr, BEq

/-- State maintained during traversal -/
structure GolitexState where
  /-- Labels defined in the document -/
  labels : Std.HashSet String := {}
  /-- Citations used in the document -/
  citations : Std.HashSet String := {}
  /-- Cross-references -/
  refs : Std.HashMap String (Array String) := {}
  /-- Equation counter -/
  equationNumber : Nat := 0
  /-- Figure counter -/
  figureNumber : Nat := 0
  /-- Table counter -/
  tableNumber : Nat := 0
deriving Inhabited, BEq

/-- The Golitex genre for Verso -/
def Golitex : Genre where
  PartMetadata := GolitexMetadata
  Block := GolitexBlock
  Inline := GolitexInline
  TraverseContext := GolitexContext
  TraverseState := GolitexState

/-! ## Traversal Implementation -/

abbrev TraverseM := ReaderT GolitexContext (StateT GolitexState Id)

instance : TraversePart Golitex where
  -- Default implementation
  
instance : Traverse Golitex TraverseM where
  part _ := pure none
  block _ := pure ()
  inline _ := pure ()
  
  genrePart metadata part := do
    -- Register label if present
    if let some label := metadata.label then
      modify fun st => {st with labels := st.labels.insert label}
    pure none
  
  genreBlock
    | .environment "equation" _ content, _ => do
      -- Increment equation counter
      modify fun st => {st with equationNumber := st.equationNumber + 1}
      pure none
    | .environment "figure" _ _, _ => do
      modify fun st => {st with figureNumber := st.figureNumber + 1}
      pure none
    | .environment "table" _ _, _ => do
      modify fun st => {st with tableNumber := st.tableNumber + 1}
      pure none
    | _, _ => pure none
  
  genreInline
    | .ref label, _ => do
      -- Track reference usage
      modify fun st => {st with 
        refs := st.refs.insert label (st.refs.findD label #[] |>.push "ref")}
      pure none
    | .cite keys, _ => do
      -- Track citations
      modify fun st => {st with 
        citations := keys.foldl (·.insert ·) st.citations}
      pure none
    | _, _ => pure none

/-! ## HTML Output -/

open Verso.Output Html in
instance : GenreHtml Golitex IO where
  part := fun _ _ _ => pure ""  -- Use default rendering
  
  block recur 
    | .environment name args content => do
      let className := s!"golitex-env-{name}"
      let contentHtml ← content.mapM recur
      pure <| Html.tag "div" #[("class", className)] <|
        Html.seq <| #[
          Html.tag "div" #[("class", "env-header")] 
            (Html.text true s!"{name}" ),
          Html.tag "div" #[("class", "env-content")] 
            (Html.seq contentHtml)
        ]
    | .displayMath content => do
      -- Parse and render the math using Golitex
      let tokens := Golitex.Frontend.Scanner.scan s!"$${content}$$"
      let ast := Golitex.Frontend.AST.parseTokens tokens
      let (doc, _) := Golitex.Elab.elaborate ast
      let html := Golitex.Backend.HTML.renderDocument doc
      pure <| Html.text false html
    | .include file =>
      pure <| Html.tag "div" #[("class", "golitex-include")] 
        (Html.text true s!"[Include: {file}]")
    | .rawLatex content =>
      -- For raw LaTeX, we parse and render through Golitex
      let tokens := Golitex.Frontend.Scanner.scan content
      let ast := Golitex.Frontend.AST.parseTokens tokens
      let (doc, _) := Golitex.Elab.elaborate ast
      let html := Golitex.Backend.HTML.renderDocument doc
      pure <| Html.text false html
  
  inline recur
    | .command name args, content => do
      let contentHtml ← content.mapM recur
      -- Handle common LaTeX commands
      match name with
      | "emph" => 
        pure <| Html.tag "em" #[] (Html.seq contentHtml)
      | "textbf" => 
        pure <| Html.tag "strong" #[] (Html.seq contentHtml)
      | "textit" =>
        pure <| Html.tag "i" #[] (Html.seq contentHtml)
      | "texttt" =>
        pure <| Html.tag "code" #[] (Html.seq contentHtml)
      | "footnote" =>
        pure <| Html.tag "sup" #[("class", "footnote")] (Html.seq contentHtml)
      | _ =>
        -- For other commands, use Golitex to render
        let latexStr := s!"\\{name}" ++ args.foldl (· ++ s!"{{{·}}}") ""
        let tokens := Golitex.Frontend.Scanner.scan latexStr
        let ast := Golitex.Frontend.AST.parseTokens tokens  
        let (doc, _) := Golitex.Elab.elaborate ast
        let html := Golitex.Backend.HTML.renderDocument doc
        pure <| Html.text false html
    | .math content, _ => do
      -- Inline math
      let tokens := Golitex.Frontend.Scanner.scan s!"${content}$"
      let ast := Golitex.Frontend.AST.parseTokens tokens
      let (doc, _) := Golitex.Elab.elaborate ast
      let html := Golitex.Backend.HTML.renderDocument doc
      pure <| Html.text false html
    | .ref label, _ =>
      pure <| Html.tag "a" #[("href", s!"#{label}"), ("class", "golitex-ref")] 
        (Html.text true s!"[{label}]")
    | .cite keys, _ =>
      let keysStr := keys.toList.intersperse ", " |> String.join
      pure <| Html.tag "span" #[("class", "golitex-cite")] 
        (Html.text true s!"[{keysStr}]")

/-! ## User API -/

/-- Create a LaTeX command inline element -/
def cmd (name : String) (args : Array String := #[]) (content : Array (Inline Golitex) := #[]) : Inline Golitex :=
  .other (.command name args) content

/-- Create inline math -/
def math (content : String) : Inline Golitex :=
  .other (.math content) #[]

/-- Create a reference -/
def ref (label : String) : Inline Golitex :=
  .other (.ref label) #[]

/-- Create a citation -/
def cite (keys : Array String) : Inline Golitex :=
  .other (.cite keys) #[]

/-- Create an environment block -/
def env (name : String) (args : Array String := #[]) (content : Array (Block Golitex)) : Block Golitex :=
  .other (.environment name args content)

/-- Create display math -/
def displayMath (content : String) : Block Golitex :=
  .other (.displayMath content)

/-- Include a file -/
def include (file : String) : Block Golitex :=
  .other (.include file)

/-- Raw LaTeX block -/
def rawLatex (content : String) : Block Golitex :=
  .other (.rawLatex content)

/-- Add metadata to a part -/
def withMetadata (label : Option String := none) (preamble : Array String := #[]) 
    (bibliography : Option String := none) : GolitexMetadata :=
  { label, preamble, bibliography }

end GolitexGenre