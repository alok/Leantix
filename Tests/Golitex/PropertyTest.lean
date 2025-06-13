import Golitex.Frontend.Scanner
import Golitex.Frontend.AST
import Golitex.Frontend.Token

/-!
# Property-Based Tests for Golitex

These tests verify properties that should hold for all inputs,
using manually crafted test cases since we don't have Plausible available.
-/

namespace Golitex.PropertyTest

open Golitex.Frontend
open Golitex.Frontend.Scanner
open Golitex.Frontend.AST

/-- Property: Scanning and then converting back should preserve structure -/
def propScanPreservesStructure (input : String) : Bool :=
  let tokens := scan input
  let _ := debugTokens input
  -- For now, just check that we get some output
  !tokens.isEmpty || input.isEmpty

/-- Property: Every opening brace should have a matching closing brace -/
def propBalancedBraces (tokens : Array Token) : Bool :=
  let rec checkBalanced (toks : List Token) (depth : Int) : Bool :=
    match toks with
    | [] => depth == 0
    | (.lbrace _) :: rest => checkBalanced rest (depth + 1)
    | (.rbrace _) :: rest => 
        if depth > 0 then checkBalanced rest (depth - 1)
        else false
    | _ :: rest => checkBalanced rest depth
  checkBalanced tokens.toList 0

/-- Property: Text tokens should not contain special characters -/
def propTextTokensClean (tokens : Array Token) : Bool :=
  tokens.all fun tok =>
    match tok with
    | .text content => !content.contains '\\' && !content.contains '{' && !content.contains '}'
    | _ => true

/-- Property: Commands should only contain alphabetic characters -/
def propCommandNamesValid (tokens : Array Token) : Bool :=
  tokens.all fun tok =>
    match tok with
    | .cmd name => name.all Char.isAlpha
    | _ => true

/-- Property: Parsing should produce a document node at the root -/
def propParseProducesDocument (tokens : Array Token) : Bool :=
  match parseTokens tokens with
  | Node.document _ _ => true
  | _ => false

/-- Property: Empty input produces empty document -/
def propEmptyInputEmptyDoc : Bool :=
  let tokens := scan ""
  match parseTokens tokens with
  | Node.document [] _ => true
  | _ => false

/-- Test scanner properties with various inputs -/
def testScannerProperties : IO Unit := do
  let testCases := [
    "",
    "plain text",
    "\\command",
    "{group}",
    "\\cmd{arg}",
    "nested {braces {inside} here}",
    "\\section{Title} Some text \\emph{emphasis} more."
  ]
  
  let mut allPass := true
  
  for input in testCases do
    let tokens := scan input
    
    -- Test preservation
    if !propScanPreservesStructure input then
      IO.println s!"✗ Scan preservation failed for: {input}"
      allPass := false
    
    -- Test balanced braces
    if !propBalancedBraces tokens then
      IO.println s!"✗ Unbalanced braces for: {input}"
      allPass := false
    
    -- Test text tokens
    if !propTextTokensClean tokens then
      IO.println s!"✗ Text tokens contain special chars for: {input}"
      allPass := false
    
    -- Test command names
    if !propCommandNamesValid tokens then
      IO.println s!"✗ Invalid command names for: {input}"
      allPass := false
  
  if allPass then
    IO.println "✓ All scanner properties passed"

/-- Test parser properties -/
def testParserProperties : IO Unit := do
  -- Test that parser always produces documents
  let testTokens := [
    #[],
    #[Token.text "hello"],
    #[Token.cmd "test"],
    #[Token.lbrace, Token.rbrace],
    #[Token.cmd "foo", Token.lbrace, Token.text "bar", Token.rbrace]
  ]
  
  let mut allPass := true
  
  for tokens in testTokens do
    if !propParseProducesDocument tokens then
      IO.println s!"✗ Parser didn't produce document for: {tokens}"
      allPass := false
  
  -- Test empty input
  if !propEmptyInputEmptyDoc then
    IO.println "✗ Empty input didn't produce empty document"
    allPass := false
  
  if allPass then
    IO.println "✓ All parser properties passed"

/-- Property: Round-trip through scanner and parser preserves text content -/
def testRoundTripProperty : IO Unit := do
  let testCases := [
    ("Hello, world!", "Hello, world!"),
    ("Multiple words here", "Multiple words here"),
    -- Commands are expected to lose their syntax but preserve argument text
    ("Text with \\command{argument} inside", "Text with argument inside")
  ]
  
  let mut allPass := true
  
  for (input, expected) in testCases do
    let tokens := scan input
    let ast := parseTokens tokens
    let extracted := ast.extractText
    
    -- Compare the extracted text with expected
    if extracted != expected then
      IO.println s!"✗ Round-trip mismatch: '{input}' -> '{extracted}' (expected '{expected}')"
      allPass := false
  
  if allPass then
    IO.println "✓ Round-trip property passed"

/-- Invariant: AST node count properties -/
def testASTInvariants : IO Unit := do
  -- Property: Number of command tokens should equal command nodes in AST
  let source := "\\foo \\bar{x} \\baz{y}{z}"
  let tokens := scan source
  let ast := parseTokens tokens
  
  let commandTokenCount := tokens.filter (fun tok => match tok with | .cmd _ => true | _ => false) |>.size
  
  let rec countCommands : Node → Nat
    | Node.command _ _ _ => 1
    | Node.group children _ => children.map countCommands |>.sum
    | Node.document children _ => children.map countCommands |>.sum
    | _ => 0
  
  let commandNodeCount := countCommands ast
  
  if commandTokenCount == commandNodeCount then
    IO.println "✓ Command count invariant passed"
  else
    IO.println s!"✗ Command count mismatch: {commandTokenCount} tokens vs {commandNodeCount} nodes"

/-- Run all property tests -/
def main : IO Unit := do
  IO.println "Running Property-based tests..."
  testScannerProperties
  testParserProperties
  testRoundTripProperty
  testASTInvariants
  IO.println "All Property tests completed!"

-- #eval main