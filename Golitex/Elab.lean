import Golitex.Frontend.AST
import Golitex.IR

/-!
# Golitex Elaboration

This module converts the AST produced by the parser into the semantic IR.
The elaboration process interprets LaTeX commands and environments, resolving
their meaning into structured document elements.
-/

namespace Golitex.Elab

open Golitex.Frontend.AST
open Golitex.IR

/-- Elaboration context for tracking state during conversion -/
structure ElabContext where
  /-- Current section level (for nested sections) -/
  sectionLevel : Nat := 0
  /-- Collected metadata during elaboration -/
  metadata : Metadata := {}
  /-- Error messages collected during elaboration -/
  errors : List String := []

/-- Elaboration monad -/
abbrev ElabM := StateT ElabContext Id

/-- Report an error during elaboration -/
def reportError (msg : String) : ElabM Unit := do
  modify fun ctx => { ctx with errors := msg :: ctx.errors }

/-- Get the current section level -/
def getSectionLevel : ElabM Nat := do
  return (← get).sectionLevel

/-- Modify the section level for nested content -/
def withSectionLevel (level : Nat) (m : ElabM α) : ElabM α := do
  let oldLevel := (← get).sectionLevel
  modify fun ctx => { ctx with sectionLevel := level }
  let result ← m
  modify fun ctx => { ctx with sectionLevel := oldLevel }
  return result

/-- Map a command name to a text style -/
def commandToStyle : String → Option TextStyle
  | "emph" => some .emph
  | "textbf" => some .bold
  | "textit" => some .italic
  | "texttt" => some .typewriter
  | _ => none

/-- Elaborate inline content from AST nodes -/
partial def elabInline (node : Node) : ElabM (List Inline) := do
  match node with
  | .text content _ => 
      return [Inline.text content]
  
  | .command name args _ =>
      -- Check if it's a style command
      if let some style := commandToStyle name then
        -- Apply style to argument content
        let argInlines ← args.mapM elabInline
        let allInlines := argInlines.flatten
        return allInlines.map fun inline =>
          match inline with
          | Inline.text content _ => Inline.text content style
          | other => other
      else
        -- Unknown command - preserve as-is
        let argInlines ← args.mapM elabInline
        return [Inline.command name argInlines.flatten]
  
  | .group children _ =>
      -- Groups just contain their children
      let childInlines ← children.mapM elabInline
      return childInlines.flatten
  
  | _ =>
      reportError s!"Unexpected node in inline context: {node}"
      return []

/-- Determine section level from command name -/
def sectionLevelFromCommand : String → Option Nat
  | "section" => some 1
  | "subsection" => some 2
  | "subsubsection" => some 3
  | "paragraph" => some 4
  | "subparagraph" => some 5
  | _ => none

-- Forward declaration
mutual

/-- Elaborate block content from AST nodes -/
partial def elabBlock (nodes : List Node) : ElabM (List Block) := do
  let mut blocks : List Block := []
  let mut currentPara : List Inline := []
  
  -- Helper to flush current paragraph
  let flushPara := fun (blocks : List Block) (para : List Inline) =>
    if para.isEmpty then blocks
    else blocks ++ [Block.paragraph para]
  
  for node in nodes do
    match node with
    | .text content _ =>
        -- Add text to current paragraph
        currentPara := currentPara ++ [Inline.text content]
    
    | .command name args _ =>
        -- Check for block-level commands
        if let some level := sectionLevelFromCommand name then
          -- Section command - flush paragraph first
          blocks := flushPara blocks currentPara
          currentPara := []
          
          -- Extract section title
          let titleInlines ← args.mapM elabInline
          let title := titleInlines.flatten
          
          blocks := blocks ++ [Block.section level title]
        
        else if name == "begin" then
          -- Environment - this would be handled by parseEnvironment
          reportError "\\begin without matching environment parser"
        
        else
          -- Inline command - add to current paragraph
          let inlines ← elabInline node
          currentPara := currentPara ++ inlines
    
    | .group children _ =>
        -- Group - elaborate its contents as inline
        let inlines ← elabInline node
        currentPara := currentPara ++ inlines
    
    | .environment name _ body _ =>
        -- Flush current paragraph
        blocks := flushPara blocks currentPara
        currentPara := []
        
        -- Elaborate environment
        match name with
        | "itemize" =>
            let items ← elabListItems body
            blocks := blocks ++ [Block.list false items]
        | "enumerate" =>
            let items ← elabListItems body
            blocks := blocks ++ [Block.list true items]
        | "quote" =>
            let content ← elabBlock body
            blocks := blocks ++ [Block.quote content]
        | "verbatim" =>
            let text := body.map (·.extractText) |> String.join
            blocks := blocks ++ [Block.verbatim text]
        | _ =>
            -- Generic environment
            let content ← elabBlock body
            blocks := blocks ++ [Block.environment name [] content]
    
    | _ =>
        reportError s!"Unexpected node in block context: {node}"
  
  -- Flush any remaining paragraph
  return flushPara blocks currentPara

/-- Elaborate list items from a list environment body -/
partial def elabListItems (nodes : List Node) : ElabM (List (List Block)) := do
  let mut items : List (List Block) := []
  let mut currentItem : List Node := []
  
  for node in nodes do
    match node with
    | .command "item" _ _ =>
        -- Start new item - elaborate previous one if any
        if !currentItem.isEmpty then
          let itemBlocks ← elabBlock currentItem
          items := items ++ [itemBlocks]
          currentItem := []
    | _ =>
        currentItem := currentItem ++ [node]
  
  -- Flush last item
  if !currentItem.isEmpty then
    let itemBlocks ← elabBlock currentItem
    items := items ++ [itemBlocks]
  
  return items

end

/-- Main elaboration function -/
def elaborate (ast : Node) : (Document × List String) :=
  match ast with
  | .document nodes _ =>
      let (blocks, ctx) := elabBlock nodes |>.run {}
      let doc : Document := {
        metadata := ctx.metadata
        content := blocks
        raw := ""
      }
      (doc, ctx.errors.reverse)
  | _ =>
      (default, ["Expected document node at top level"])

/-- Elaborate and get just the document (for simple cases) -/
def elaborateSimple (ast : Node) : Document :=
  elaborate ast |>.fst

end Golitex.Elab