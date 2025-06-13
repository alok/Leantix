import Golitex.Syntax
import Golitex.Frontend.AST

/-!
# Tests for Golitex.Syntax

Unit tests for the Syntax module, verifying the litex! macro and parsing integration.
-/

namespace Golitex.SyntaxTest

open Golitex
open Golitex.Frontend.AST

/-- Test basic litex! macro usage -/
def testLitexMacro : IO Unit := do
  let doc := litex! "\\section{Test} Hello world"
  -- Verify the raw content is preserved
  if doc.toDocument.raw != "\\section{Test} Hello world" then
    panic! "Raw content not preserved"
  
  -- Verify AST was created
  match doc.ast with
  | Node.document children _ =>
      if children.length != 2 then
        panic! s!"Expected 2 nodes, got {children.length}"
      IO.println "✓ litex! macro test passed"
  | _ => panic! "Expected document node"

/-- Test parseLitex function -/
def testParseLitex : IO Unit := do
  let doc := parseLitex "\\emph{important} text"
  
  -- Check raw content
  if doc.toDocument.raw != "\\emph{important} text" then
    panic! "Raw content mismatch"
  
  -- Check AST structure
  match doc.ast with
  | Node.document nodes _ =>
      if nodes.length != 2 then
        panic! s!"Expected 2 nodes, got {nodes.length}"
      match nodes with
      | [cmd, text] =>
          if !cmd.isCommand "emph" then
            panic! "Expected emph command"
          match text with
          | Node.text " text" _ => IO.println "✓ parseLitex test passed"
          | _ => panic! "Expected text node"
      | _ => panic! "Unexpected node structure"
  | _ => panic! "Unexpected AST structure"

/-- Test complex document parsing -/
def testComplexDocument : IO Unit := do
  let source := "\\section{Intro} Some text \\emph{with emphasis} and more."
  let doc := parseLitex source
  
  match doc.ast with
  | Node.document nodes _ =>
      if nodes.length != 4 then
        panic! s!"Expected 4 nodes, got {nodes.length}"
      
      -- Verify first node is section command
      match nodes[0]? with
      | some (Node.command "section" _ _) => pure ()
      | _ => panic! "Expected section command"
      
      IO.println "✓ Complex document test passed"
  | _ => panic! "Expected document node"

/-- Test that empty string works -/
def testEmptyDocument : IO Unit := do
  let doc := parseLitex ""
  match doc.ast with
  | Node.document nodes _ => 
      if nodes.isEmpty then
        IO.println "✓ Empty document test passed"
      else
        panic! "Expected empty document"
  | _ => panic! "Expected document node"

/-- Run all syntax tests -/
def main : IO Unit := do
  IO.println "Running Syntax tests..."
  testLitexMacro
  testParseLitex
  testComplexDocument
  testEmptyDocument
  IO.println "All Syntax tests completed successfully!"

-- #eval main