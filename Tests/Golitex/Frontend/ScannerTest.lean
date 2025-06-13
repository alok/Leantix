import Golitex.Frontend.Scanner
import Golitex.Frontend.Token

/-!
# Tests for Golitex.Frontend.Scanner

Unit tests for the Scanner module, verifying tokenization of Litex source code.
-/

namespace Golitex.Frontend.ScannerTest

open Golitex.Frontend
open Golitex.Frontend.Scanner

/-- Helper to compare token arrays -/
def tokensEqual (actual : Array Token) (expected : Array Token) : Bool :=
  actual.size == expected.size && 
  (actual.zip expected).all fun (a, e) => a == e

/-- Test basic command scanning -/
def testBasicCommands : IO Unit := do
  let src := "\\section{Hello}"
  let tokens := scan src
  let expected := #[
    Token.cmd "section",
    Token.lbrace,
    Token.text "Hello",
    Token.rbrace
  ]
  
  if !tokensEqual tokens expected then
    panic! s!"Token mismatch in basic command test"
  IO.println s!"✓ Basic command test passed: {debugTokens src}"

/-- Test multiple commands -/
def testMultipleCommands : IO Unit := do
  let src := "\\section{Intro} Some text \\emph{important} stuff"
  let tokens := scan src
  let expected := #[
    Token.cmd "section",
    Token.lbrace,
    Token.text "Intro",
    Token.rbrace,
    Token.text " Some text ",
    Token.cmd "emph",
    Token.lbrace,
    Token.text "important",
    Token.rbrace,
    Token.text " stuff"
  ]
  
  if !tokensEqual tokens expected then
    panic! "Token mismatch in multiple commands test"
  IO.println s!"✓ Multiple commands test passed"

/-- Test nested braces -/
def testNestedBraces : IO Unit := do
  let src := "{outer {inner} text}"
  let tokens := scan src
  let expected := #[
    Token.lbrace,
    Token.text "outer ",
    Token.lbrace,
    Token.text "inner",
    Token.rbrace,
    Token.text " text",
    Token.rbrace
  ]
  
  if !tokensEqual tokens expected then
    panic! "Token mismatch in nested braces test"
  IO.println s!"✓ Nested braces test passed"

/-- Test edge cases -/
def testEdgeCases : IO Unit := do
  -- Empty string
  let tokens1 := scan ""
  if !tokens1.isEmpty then
    panic! "Expected empty tokens for empty string"
  
  -- Lone backslash at EOF
  let tokens2 := scan "\\"
  if !tokensEqual tokens2 #[Token.text "\\"] then
    panic! "Lone backslash test failed"
  
  -- Backslash followed by non-letter
  let tokens3 := scan "\\%"
  if !tokensEqual tokens3 #[Token.text "\\", Token.text "%"] then
    panic! "Backslash non-letter test failed"
  
  -- Just braces
  let tokens4 := scan "{}"
  if !tokensEqual tokens4 #[Token.lbrace, Token.rbrace] then
    panic! "Just braces test failed"
  
  IO.println "✓ Edge cases test passed"

/-- Test command with no arguments -/
def testCommandNoArgs : IO Unit := do
  let src := "\\newline text"
  let tokens := scan src
  let expected := #[
    Token.cmd "newline",
    Token.text " text"
  ]
  
  if !tokensEqual tokens expected then
    panic! "Command with no args test failed"
  IO.println "✓ Command with no args test passed"

/-- Test multiple braced arguments -/
def testMultipleArgs : IO Unit := do
  let src := "\\textcolor{red}{text}"
  let tokens := scan src
  let expected := #[
    Token.cmd "textcolor",
    Token.lbrace,
    Token.text "red",
    Token.rbrace,
    Token.lbrace,
    Token.text "text",
    Token.rbrace
  ]
  
  if !tokensEqual tokens expected then
    panic! "Multiple arguments test failed"
  IO.println "✓ Multiple arguments test passed"

/-- Test text with special characters -/
def testSpecialChars : IO Unit := do
  let src := "Math: x + y = z"
  let tokens := scan src
  if tokens.size != 1 then
    panic! "Expected single token"
  match tokens[0]? with
  | some (Token.text t) => 
      if t != src then
        panic! s!"Expected '{src}', got '{t}'"
  | _ => panic! "Expected text token"
  
  IO.println "✓ Special characters test passed"

/-- Test Unicode text -/
def testUnicode : IO Unit := do
  let src := "Unicode: α β γ δ"
  let tokens := scan src
  if tokens.size != 1 then
    panic! "Expected single token for unicode"
  match tokens[0]? with
  | some (Token.text t) => 
      if t != src then
        panic! s!"Expected '{src}', got '{t}'"
  | _ => panic! "Expected text token"
  
  IO.println "✓ Unicode test passed"

/-- Run all scanner tests -/
def main : IO Unit := do
  IO.println "Running Scanner tests..."
  testBasicCommands
  testMultipleCommands
  testNestedBraces
  testEdgeCases
  testCommandNoArgs
  testMultipleArgs
  testSpecialChars
  testUnicode
  IO.println "All Scanner tests completed successfully!"