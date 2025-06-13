import Golitex.Frontend.AST
import Golitex.Frontend.Scanner
import Golitex.Frontend.Token

/-!
# Tests for Golitex.Frontend.AST

Unit tests for the AST module, verifying AST construction and parsing.
-/

namespace Golitex.Frontend.ASTTest

open Golitex.Frontend
open Golitex.Frontend.AST
open Golitex.Frontend.Scanner

/-- Test basic AST node creation -/
def testNodeCreation : IO Unit := do
  -- Test command node
  let cmdNode := Node.command "section" [Node.text "Introduction"]
  if !cmdNode.isCommand "section" then
    panic! "Expected command node to be 'section'"
  if cmdNode.toString != "\\section Introduction" then
    panic! s!"Expected '\\section Introduction', got '{cmdNode.toString}'"
  
  -- Test group node
  let groupNode := Node.group [Node.text "grouped text"]
  if groupNode.toString != "{grouped text}" then
    panic! s!"Expected '\{grouped text}', got '{groupNode.toString}'"
  
  -- Test text node
  let textNode := Node.text "Hello, world!"
  if textNode.toString != "Hello, world!" then
    panic! s!"Expected 'Hello, world!', got '{textNode.toString}'"
  if textNode.extractText != "Hello, world!" then
    panic! s!"Expected 'Hello, world!' from extractText"
  
  IO.println "✓ Node creation tests passed"

/-- Test parsing simple commands -/
def testParseSimpleCommand : IO Unit := do
  let src := "\\section{Introduction}"
  let tokens := scan src
  let ast := parseTokens tokens
  
  match ast with
  | Node.document [cmd] _ =>
      match cmd with
      | Node.command "section" [arg] _ =>
          match arg with
          | Node.group [Node.text "Introduction" _] _ =>
              IO.println "✓ Simple command parsing test passed"
          | _ => panic! s!"Unexpected argument structure: {arg}"
      | _ => panic! s!"Unexpected command structure: {cmd}"
  | _ => 
      panic! s!"Unexpected AST structure: {ast}"

/-- Test parsing multiple commands -/
def testParseMultipleCommands : IO Unit := do
  let src := "\\section{A} text \\emph{B}"
  let tokens := scan src
  let ast := parseTokens tokens
  
  match ast with
  | Node.document nodes _ =>
      if nodes.length != 3 then
        panic! s!"Expected 3 nodes, got {nodes.length}"
      -- Verify structure
      match nodes with
      | [cmd1, text, cmd2] =>
          if !cmd1.isCommand "section" then
            panic! "First node should be section command"
          if text.toString != " text " then
            panic! "Middle node should be ' text '"
          if !cmd2.isCommand "emph" then
            panic! "Last node should be emph command"
      | _ => panic! "Unexpected node structure"
      IO.println "✓ Multiple commands parsing test passed"
  | _ => panic! "Expected document node"

/-- Test parsing nested groups -/
def testParseNestedGroups : IO Unit := do
  let src := "{outer {inner} text}"
  let tokens := scan src
  let ast := parseTokens tokens
  
  match ast with
  | Node.document [g] _ =>
      match g with
      | Node.group children _ =>
          if children.length != 3 then
            panic! s!"Expected 3 children, got {children.length}"
          IO.println "✓ Nested groups parsing test passed"
      | _ => panic! "Expected group node"
  | _ => panic! "Unexpected AST structure"

/-- Test extractText functionality -/
def testExtractText : IO Unit := do
  -- Test text extraction from various node types
  let cmdNode := Node.command "emph" [Node.group [Node.text "important"]]
  if cmdNode.extractText != "important" then
    panic! "Expected 'important' from command node"
  
  let envNode := Node.environment "quote" [] [Node.text "A quote"]
  if envNode.extractText != "A quote" then
    panic! "Expected 'A quote' from environment node"
  
  let docNode := Node.document [
    Node.text "Start ",
    Node.command "emph" [Node.group [Node.text "middle"]],
    Node.text " end"
  ]
  if docNode.extractText != "Start middle end" then
    panic! "Expected 'Start middle end' from document node"
  
  IO.println "✓ Text extraction tests passed"

/-- Test toString for complex structures -/
def testComplexToString : IO Unit := do
  let env := Node.environment "itemize" [] [
    Node.command "item" [Node.text "First"],
    Node.command "item" [Node.text "Second"]
  ]
  let expected := "\\begin{itemize}\n\\item First\n\\item Second\n\\end{itemize}"
  if env.toString != expected then
    panic! s!"Expected environment string format, got {env.toString}"
  
  IO.println "✓ Complex toString test passed"

/-- Test source position handling -/
def testSourcePositions : IO Unit := do
  let pos := SourcePos.mk 10 5
  let node := Node.text "test" pos
  
  match node.getPos with
  | some p => 
      if p.line != 10 then
        panic! s!"Expected line 10, got {p.line}"
      if p.column != 5 then
        panic! s!"Expected column 5, got {p.column}"
  | none => panic! "Expected source position"
  
  -- Test node without position
  let node2 := Node.text "test2"
  if node2.getPos.isSome then
    panic! "Expected no source position"
  
  IO.println "✓ Source position tests passed"

/-- Test parsing edge cases -/
def testParseEdgeCases : IO Unit := do
  -- Empty token array
  let ast1 := parseTokens #[]
  match ast1 with
  | Node.document [] _ => IO.println "✓ Empty parse test passed"
  | _ => panic! "Expected empty document"
  
  -- Just text
  let ast2 := parseTokens #[Token.text "plain text"]
  match ast2 with
  | Node.document [t] _ => 
      match t with
      | Node.text "plain text" _ => 
          IO.println "✓ Plain text parse test passed"
      | _ => panic! "Expected text node"
  | _ => panic! "Unexpected AST"

/-- Run all AST tests -/
def main : IO Unit := do
  IO.println "Running AST tests..."
  testNodeCreation
  testParseSimpleCommand
  testParseMultipleCommands
  testParseNestedGroups
  testExtractText
  testComplexToString
  testSourcePositions
  testParseEdgeCases
  IO.println "All AST tests completed successfully!"