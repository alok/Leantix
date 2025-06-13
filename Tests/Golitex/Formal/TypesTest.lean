/-
Copyright (c) 2024 The Golitex Contributors.
Released under the MIT license.
-/

import Golitex.Formal.Types
import Golitex.IR

/-!
# Tests for Formal Reasoning Types

This module tests the types used for representing formal mathematical content.
-/

namespace Golitex.Formal.TypesTest

open Golitex.Formal
open Golitex.IR

-- Test statement kinds
def testStatementKind : IO Unit := do
  let kinds : List StatementKind := [
    .theorem, .lemma, .proposition, .corollary, 
    .definition, .axiom, .example
  ]
  
  for k in kinds do
    IO.println s!"Statement kind: {repr k}"
  
  -- Test equality
  assert! (StatementKind.theorem == StatementKind.theorem)
  assert! (StatementKind.theorem != StatementKind.lemma)
  
  IO.println "✓ Statement kinds test passed"

-- Test formal statement construction
def testFormalStatement : IO Unit := do
  let stmt : FormalStatement := {
    kind := .theorem
    label := some "thm:example"
    name := some "Example Theorem"
    statement := [Inline.text "For all x, P(x)"]
    proof := some (ProofContent.omitted "obvious")
  }
  
  assert! (stmt.kind == .theorem)
  assert! (stmt.label == some "thm:example")
  
  IO.println "✓ Formal statement test passed"

-- Test proof content types
def testProofContent : IO Unit := do
  -- Prose proof
  let prose := ProofContent.prose [
    Block.paragraph [Inline.text "This follows by induction."]
  ]
  
  -- Structured proof
  let step1 : ProofStep := {
    label := some "base"
    justification := some "definition"
    content := [Inline.text "Base case holds"]
    substeps := []
  }
  let structured := ProofContent.structured [step1]
  
  -- Omitted proof
  let omitted := ProofContent.omitted "left as exercise"
  
  -- Reference proof
  let reference := ProofContent.reference "Theorem 3.1"
  
  IO.println "✓ Proof content types test passed"

-- Test mathematical formulas
def testMathFormula : IO Unit := do
  let formula : MathFormula := {
    source := "x^2 + y^2 = z^2"
    display := true
    semantics := some (MathSemantics.relation "=" 
      (MathSemantics.operator "+" [
        MathSemantics.operator "^" [
          MathSemantics.variable "x",
          MathSemantics.constant "2"
        ],
        MathSemantics.operator "^" [
          MathSemantics.variable "y", 
          MathSemantics.constant "2"
        ]
      ])
      (MathSemantics.operator "^" [
        MathSemantics.variable "z",
        MathSemantics.constant "2"
      ])
    )
  }
  
  assert! formula.display
  assert! (formula.source == "x^2 + y^2 = z^2")
  
  IO.println "✓ Math formula test passed"

-- Test formal blocks
def testFormalBlocks : IO Unit := do
  -- Statement block
  let stmt : FormalStatement := {
    kind := .lemma
    label := some "lem:helper"
    name := none
    statement := [Inline.text "Helper lemma"]
    proof := none
  }
  let stmtBlock := FormalBlock.statement stmt
  
  -- Assumption block
  let assumption := FormalBlock.assumption "A1" 
    [Inline.text "x > 0"]
  
  -- Notation block
  let notation := FormalBlock.notation "⊕" "direct sum"
  
  IO.println "✓ Formal blocks test passed"

-- Test formal references
def testFormalReference : IO Unit := do
  let ref1 : FormalReference := {
    label := "thm:main"
    kind := some "Theorem"
  }
  
  let ref2 : FormalReference := {
    label := "eq:pythagorean"
    kind := none
  }
  
  assert! (ref1.label == "thm:main")
  assert! (ref2.kind == none)
  
  IO.println "✓ Formal reference test passed"

-- Run all tests
def main : IO Unit := do
  IO.println "=== Formal Types Tests ==="
  testStatementKind
  testFormalStatement
  testProofContent
  testMathFormula
  testFormalBlocks
  testFormalReference
  IO.println "All tests passed! ✨"

#eval main

end Golitex.Formal.TypesTest