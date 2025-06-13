/-
Copyright (c) 2024 The Golitex Contributors.
Released under the MIT license.
-/

import Golitex.Formal.Parser
import Golitex.Frontend.AST

/-!
# Tests for Formal Reasoning Parser

This module tests the parser extensions for formal mathematical content.
-/

namespace Golitex.Formal.ParserTest

open Golitex.Frontend.AST
open Golitex.Formal.AST
open Golitex.Formal.Parser

-- Test environment name classification
def testFormalEnvironments : IO Unit := do
  -- Formal environments
  assert! (isFormalEnvironment "theorem")
  assert! (isFormalEnvironment "lemma")
  assert! (isFormalEnvironment "proposition")
  assert! (isFormalEnvironment "corollary")
  assert! (isFormalEnvironment "definition")
  assert! (isFormalEnvironment "axiom")
  assert! (isFormalEnvironment "example")
  assert! (isFormalEnvironment "proof")
  
  -- Non-formal environments
  assert! (not (isFormalEnvironment "itemize"))
  assert! (not (isFormalEnvironment "equation"))
  assert! (not (isFormalEnvironment "figure"))
  
  IO.println "✓ Formal environment classification test passed"

-- Test environment name to statement kind conversion
def testEnvToStatementKind : IO Unit := do
  assert! (envNameToStatementKind "theorem" == some StatementKind.theorem)
  assert! (envNameToStatementKind "lemma" == some StatementKind.lemma)
  assert! (envNameToStatementKind "definition" == some StatementKind.definition)
  assert! (envNameToStatementKind "unknown" == none)
  
  IO.println "✓ Environment to statement kind conversion test passed"

-- Test parsing formal environments
def testParseFormalEnvironment : IO Unit := do
  -- Simple theorem
  let thmBody := [Node.text "For all x, P(x)" none]
  let thmNode := parseFormalEnvironment "theorem" 
    [Node.text "thm:example" none] thmBody none
  
  match thmNode with
  | some (FormalNode.theorem kind label _ _ _ _) =>
    assert! (kind == StatementKind.theorem)
    assert! (label == some "thm:example")
  | _ => panic! "Expected theorem node"
  
  -- Theorem with proof
  let proofBody := [Node.text "By induction." none]
  let thmWithProof := [
    Node.text "Statement here" none,
    Node.environment "proof" [] proofBody none
  ]
  let thmNode2 := parseFormalEnvironment "lemma" [] thmWithProof none
  
  match thmNode2 with
  | some (FormalNode.theorem kind _ _ stmt proof _) =>
    assert! (kind == StatementKind.lemma)
    assert! proof.isSome
  | _ => panic! "Expected lemma node"
  
  IO.println "✓ Formal environment parsing test passed"

-- Test proof content detection
def testProofDetection : IO Unit := do
  -- Structured proof indicators
  let structured1 := [Node.text "Step 1: Base case" none]
  assert! (detectStructuredProof structured1)
  
  let structured2 := [Node.text "Case 1: n = 0" none]
  assert! (detectStructuredProof structured2)
  
  let structured3 := [Node.text "Claim: The property holds" none]
  assert! (detectStructuredProof structured3)
  
  -- Regular prose
  let prose := [Node.text "This follows by induction on n." none]
  assert! (not (detectStructuredProof prose))
  
  IO.println "✓ Proof structure detection test passed"

-- Test reference parsing
def testReferenceParser : IO Unit := do
  -- Simple reference
  let ref1 := parseReference [Node.text "thm:main" none]
  match ref1 with
  | some (FormalNode.ref label kind _) =>
    assert! (label == "thm:main")
    assert! (kind == none)
  | _ => panic! "Expected reference node"
  
  -- Reference with kind
  let ref2 := parseReference [
    Node.text "Theorem" none,
    Node.text "thm:convergence" none
  ]
  match ref2 with
  | some (FormalNode.ref label kind _) =>
    assert! (label == "thm:convergence")
    assert! (kind == some "Theorem")
  | _ => panic! "Expected reference node"
  
  IO.println "✓ Reference parsing test passed"

-- Test node extension
def testExtendParser : IO Unit := do
  -- Regular node
  let textNode := Node.text "Hello" none
  match extendParser textNode with
  | ExtendedNode.regular _ => pure ()
  | _ => panic! "Expected regular node"
  
  -- Theorem environment
  let thmEnv := Node.environment "theorem" [] 
    [Node.text "Statement" none] none
  match extendParser thmEnv with
  | ExtendedNode.formal _ => pure ()
  | _ => panic! "Expected formal node"
  
  -- Math command
  let mathCmd := Node.command "$" [Node.text "x^2" none] none
  match extendParser mathCmd with
  | ExtendedNode.formal (FormalNode.math inline source _ _) =>
    assert! inline
    assert! (source == "x^2")
  | _ => panic! "Expected math node"
  
  IO.println "✓ Parser extension test passed"

-- Run all tests
def main : IO Unit := do
  IO.println "=== Formal Parser Tests ==="
  testFormalEnvironments
  testEnvToStatementKind
  testParseFormalEnvironment
  testProofDetection
  testReferenceParser
  testExtendParser
  IO.println "All tests passed! ✨"

#eval main

end Golitex.Formal.ParserTest