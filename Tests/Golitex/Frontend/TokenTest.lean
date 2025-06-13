import Golitex.Frontend.Token

/-!
# Tests for Golitex.Frontend.Token

Unit tests for the Token module, verifying token creation and string conversion.
-/

namespace Golitex.Frontend.TokenTest

open Golitex.Frontend

/-- Test token creation and string representation -/
def testTokenCreation : IO Unit := do
  -- Test command token
  let cmdToken := Token.cmd "section"
  IO.println s!"Command token: {cmdToken}"
  if cmdToken.toString != "\\section" then
    panic! s!"Expected \\section, got {cmdToken.toString}"
  
  -- Test brace tokens
  let lbrace := Token.lbrace
  let rbrace := Token.rbrace
  if lbrace.toString != "{" then
    panic! "Expected {, got something else"
  if rbrace.toString != "}" then
    panic! "Expected }, got something else"
  
  -- Test text token
  let textToken := Token.text "Hello, world!"
  if textToken.toString != "Hello, world!" then
    panic! "Expected Hello, world!, got something else"
  
  IO.println "✓ All token creation tests passed"

/-- Test token equality -/
def testTokenEquality : IO Unit := do
  let t1 := Token.cmd "foo"
  let t2 := Token.cmd "foo"
  let t3 := Token.cmd "bar"
  
  -- Tokens with same content should be equal
  if t1 != t2 then
    panic! "Expected equal tokens"
  if t1 == t3 then
    panic! "Expected different tokens"
  
  -- Different token types should not be equal
  let textFoo := Token.text "foo"
  if Token.cmd "foo" == textFoo then
    panic! "Expected different token types"
  
  IO.println "✓ All token equality tests passed"

/-- Test custom brace characters -/
def testCustomBraces : IO Unit := do
  let customLbrace := Token.lbrace '['
  let customRbrace := Token.rbrace ']'
  
  if customLbrace.toString != "[" then
    panic! "Expected [, got something else"
  if customRbrace.toString != "]" then
    panic! "Expected ], got something else"
  
  IO.println "✓ Custom brace tests passed"

/-- Run all token tests -/
def main : IO Unit := do
  IO.println "Running Token tests..."
  testTokenCreation
  testTokenEquality
  testCustomBraces
  IO.println "All Token tests completed successfully!"