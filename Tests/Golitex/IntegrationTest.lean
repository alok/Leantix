import Golitex.Frontend.Scanner
import Golitex.Frontend.AST
import Golitex.Elab
import Golitex.IR

/-!
# Integration Tests for Golitex

These tests verify the complete pipeline from source text to IR.
-/

namespace Golitex.IntegrationTest

open Golitex.Frontend.Scanner
open Golitex.Frontend.AST
open Golitex.Elab
open Golitex.IR

/-- Helper to run the full pipeline -/
def processDocument (source : String) : Document × List String :=
  let tokens := scan source
  let ast := parseTokens tokens
  elaborate ast

/-- Test simple paragraph -/
def testSimpleParagraph : IO Unit := do
  let (doc, errors) := processDocument "Hello, world!"
  
  if !errors.isEmpty then
    panic! s!"Unexpected errors: {errors}"
  
  match doc.content with
  | [Block.paragraph inlines] =>
      match inlines with
      | [Inline.text "Hello, world!" _] =>
          IO.println "✓ Simple paragraph test passed"
      | _ => panic! "Unexpected inline structure"
  | _ => panic! "Expected single paragraph"

/-- Test emphasis command -/
def testEmphasis : IO Unit := do
  let (doc, errors) := processDocument "This is \\emph{important} text."
  
  if !errors.isEmpty then
    panic! s!"Unexpected errors: {errors}"
  
  match doc.content with
  | [Block.paragraph inlines] =>
      if inlines.length != 3 then
        panic! s!"Expected 3 inlines, got {inlines.length}"
      match inlines with
      | [Inline.text "This is " _, 
         Inline.text "important" TextStyle.emph,
         Inline.text " text." _] =>
          IO.println "✓ Emphasis test passed"
      | _ => panic! "Unexpected inline structure"
  | _ => panic! "Expected single paragraph"

/-- Test section structure -/
def testSectionStructure : IO Unit := do
  let source := "\\section{Introduction} This is the intro. \\subsection{Details} More text."
  let (doc, errors) := processDocument source
  
  if !errors.isEmpty then
    panic! s!"Unexpected errors: {errors}"
  
  match doc.content with
  | [Block.section 1 title1 _,
     Block.paragraph intro,
     Block.section 2 title2 _,
     Block.paragraph details] =>
      -- Verify section titles
      match title1 with
      | [Inline.text "Introduction" _] => pure ()
      | _ => panic! "Unexpected section 1 title"
      
      match title2 with
      | [Inline.text "Details" _] => pure ()
      | _ => panic! "Unexpected section 2 title"
      
      IO.println "✓ Section structure test passed"
  | _ => panic! "Unexpected document structure"

/-- Test nested groups and commands -/
def testNestedCommands : IO Unit := do
  let source := "\\textbf{\\emph{Bold and italic} text}"
  let (doc, errors) := processDocument source
  
  if !errors.isEmpty then
    panic! s!"Unexpected errors: {errors}"
  
  match doc.content with
  | [Block.paragraph inlines] =>
      -- We expect bold applied to both parts
      match inlines with
      | [Inline.text _ TextStyle.bold,
         Inline.text _ TextStyle.bold] =>
          IO.println "✓ Nested commands test passed"
      | _ => panic! "Unexpected inline structure"
  | _ => panic! "Expected single paragraph"

/-- Test list environment -/
def testListEnvironment : IO Unit := do
  let source := "\\begin{itemize} \\item First \\item Second \\end{itemize}"
  let tokens := scan source
  let _ := parseTokens tokens
  
  -- For this test, we need to manually construct the environment node
  -- since our parser doesn't handle \begin/\end yet
  let listEnv := Node.environment "itemize" [] [
    Node.command "item" [],
    Node.text " First",
    Node.command "item" [],
    Node.text " Second"
  ]
  let doc := Node.document [listEnv]
  let (result, errors) := elaborate doc
  
  if !errors.isEmpty then
    panic! s!"Unexpected errors: {errors}"
  
  match result.content with
  | [Block.list false items] =>
      if items.length != 2 then
        panic! s!"Expected 2 items, got {items.length}"
      IO.println "✓ List environment test passed"
  | _ => panic! "Expected list block"

/-- Test error handling -/
def testErrorHandling : IO Unit := do
  -- Create an AST with invalid structure
  let badAst := Node.document [
    Node.command "section" [], -- Section with no title
    Node.document [] -- Nested document (invalid)
  ]
  
  let (_, errors) := elaborate badAst
  
  if errors.isEmpty then
    panic! "Expected errors but got none"
  
  IO.println s!"✓ Error handling test passed with {errors.length} errors"

/-- Test document to plain text conversion -/
def testPlainTextConversion : IO Unit := do
  let doc : Document := {
    content := [
      Block.section 1 [text "Title"],
      Block.paragraph [text "Hello ", text "world" .emph, text "!"],
      Block.list false [[Block.paragraph [text "Item 1"]], 
                       [Block.paragraph [text "Item 2"]]]
    ]
  }
  
  let plainTexts := doc.content.map Block.toPlainText
  let fullText := String.join plainTexts
  
  -- Just check for some expected content
  if fullText.contains '#' && fullText.contains '!' then
    IO.println "✓ Plain text conversion test passed"
  else
    panic! s!"Unexpected plain text output: {fullText}"

/-- Test inline command preservation -/
def testUnknownCommand : IO Unit := do
  let (doc, errors) := processDocument "Use \\foo{bar} command"
  
  if !errors.isEmpty then
    panic! s!"Unexpected errors: {errors}"
  
  match doc.content with
  | [Block.paragraph inlines] =>
      -- Should preserve unknown command
      let hasCommand := inlines.any fun i =>
        match i with
        | Inline.command "foo" _ => true
        | _ => false
      if hasCommand then
        IO.println "✓ Unknown command preservation test passed"
      else
        panic! "Unknown command was not preserved"
  | _ => panic! "Expected single paragraph"

/-- Run all integration tests -/
def main : IO Unit := do
  IO.println "Running Integration tests..."
  testSimpleParagraph
  testEmphasis
  testSectionStructure
  testNestedCommands
  testListEnvironment
  testErrorHandling
  testPlainTextConversion
  testUnknownCommand
  IO.println "All Integration tests completed successfully!"

-- #eval main