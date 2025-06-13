/-
Copyright (c) 2025 Golitex Contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Verso
import Golitex

/-!
# Golitex as a Verso Genre

This module integrates Golitex's embedded LaTeX DSL into Verso, allowing
Golitex documents to be written using Verso's document system while leveraging
the full power of the `litex!` macro and Golitex elaboration.
-/

open Verso Doc
open Golitex

namespace Golitex.Verso

/-! ## Genre Definition

The Golitex genre extends Verso with:
- Inline Golitex fragments using `litex!` 
- Block-level Golitex documents
- Metadata for LaTeX document configuration
-/

/-- Inline Golitex content -/
inductive GolitexInline where
  | fragment (doc : ParsedDocument)
  | ref (label : String)
deriving Inhabited, Repr

/-- Block Golitex content -/  
inductive GolitexBlock where
  | document (doc : ParsedDocument)
  | rawTex (content : String)
deriving Inhabited, Repr

/-- Golitex-specific metadata -/
structure GolitexMeta where
  documentClass : String := "article"
  packages : Array String := #[]
  preamble : String := ""
deriving Inhabited, Repr

/-- Traversal context -/
structure GolitexContext where
  /-- Current elaboration context from Golitex -/
  elabContext : Elab.ElabContext := {}
deriving Inhabited, Repr

/-- Traversal state -/
structure GolitexState where  
  /-- All parsed documents -/
  documents : Array ParsedDocument := #[]
  /-- Label mappings -/
  labels : Std.HashMap String String := {}
deriving Inhabited

instance : BEq GolitexState where
  beq s1 s2 := 
    s1.documents.size == s2.documents.size &&
    s1.labels.size == s2.labels.size

/-- The Golitex Verso genre -/
def GolitexGenre : Genre where
  PartMetadata := GolitexMeta
  Block := GolitexBlock  
  Inline := GolitexInline
  TraverseContext := GolitexContext
  TraverseState := GolitexState

/-! ## Traversal -/

abbrev TraverseM := ReaderT GolitexContext (StateT GolitexState Id)

instance : TraversePart GolitexGenre where

instance : Traverse GolitexGenre TraverseM where
  part _ := pure none
  block _ := pure ()
  inline _ := pure ()
  
  genrePart _ _ := pure none
  
  genreBlock
    | .document doc, _ => do
      -- Register the document
      modify fun st => {st with documents := st.documents.push doc}
      pure none
    | .rawTex _, _ => pure none
  
  genreInline  
    | .fragment doc, _ => do
      -- Register inline fragment
      modify fun st => {st with documents := st.documents.push doc}
      pure none
    | .ref label, _ => do
      -- Track reference
      pure none

/-! ## HTML Rendering -/

open Verso.Output Html in
instance : GenreHtml GolitexGenre IO where
  part _ metadata _ := pure ""
  
  block _ 
    | .document doc => do
      -- Elaborate the Golitex document
      let (irDoc, _) := Golitex.Elab.elaborate doc.ast
      -- Render to HTML
      let html := Golitex.Backend.HTML.renderDocument irDoc
      pure <| Html.text false html
    | .rawTex content => do
      -- Parse and render raw TeX
      let parsedDoc := parseLitex content
      let (irDoc, _) := Golitex.Elab.elaborate parsedDoc.ast
      let html := Golitex.Backend.HTML.renderDocument irDoc
      pure <| Html.text false html
  
  inline _
    | .fragment doc, _ => do
      -- Elaborate and render inline Golitex
      let (irDoc, _) := Golitex.Elab.elaborate doc.ast
      let html := Golitex.Backend.HTML.renderDocument irDoc
      pure <| Html.text false html
    | .ref label, _ =>
      pure <| Html.tag "a" #[("href", s!"#{label}")] 
        (Html.text true s!"[{label}]")

/-! ## User API -/

/-- Create a Golitex document block from a litex! expression -/
def golitexDoc (doc : ParsedDocument) : Block GolitexGenre :=
  .other (.document doc)

/-- Create a raw TeX block -/
def rawTex (content : String) : Block GolitexGenre :=
  .other (.rawTex content)

/-- Create an inline Golitex fragment -/
def golitexInline (doc : ParsedDocument) : Inline GolitexGenre :=
  .other (.fragment doc) #[]

/-- Create a reference -/
def golitexRef (label : String) : Inline GolitexGenre :=
  .other (.ref label) #[]

/-- Helper to create a Golitex block from a string -/
def golitex (content : String) : Block GolitexGenre :=
  golitexDoc (parseLitex content)

end Golitex.Verso