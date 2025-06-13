/-
Copyright (c) 2024 The Golitex Contributors.
Released under the MIT license.
-/

import Golitex.IR

/-!
# Formal Reasoning Types

This module defines types for representing formal mathematical content
including theorems, lemmas, proofs, and definitions.
-/

namespace Golitex.Formal

/-- Type of formal statement -/
inductive StatementKind
  | theorem
  | lemma
  | proposition
  | corollary
  | definition
  | axiom
  | example
  deriving BEq, Repr

/-- A formal mathematical statement -/
structure FormalStatement where
  kind : StatementKind
  label : Option String
  name : Option String
  statement : List IR.Inline
  proof : Option ProofContent
  deriving BEq, Repr

/-- Content of a proof -/
inductive ProofContent
  | prose : List IR.Block → ProofContent
  | structured : List ProofStep → ProofContent
  | omitted : String → ProofContent  -- e.g., "by induction", "obvious"
  | reference : String → ProofContent  -- reference to another proof
  deriving BEq, Repr

/-- A single step in a structured proof -/
structure ProofStep where
  label : Option String
  justification : Option String
  content : List IR.Inline
  substeps : List ProofStep
  deriving BEq, Repr

/-- Mathematical formula with semantic information -/
structure MathFormula where
  source : String  -- Original LaTeX source
  display : Bool   -- Display mode vs inline mode
  semantics : Option MathSemantics
  deriving BEq, Repr

/-- Semantic representation of mathematical content -/
inductive MathSemantics
  | variable : String → MathSemantics
  | constant : String → MathSemantics
  | application : MathSemantics → List MathSemantics → MathSemantics
  | abstraction : String → MathSemantics → MathSemantics
  | relation : String → MathSemantics → MathSemantics → MathSemantics
  | operator : String → List MathSemantics → MathSemantics
  deriving BEq, Repr

/-- Cross-reference to a formal statement -/
structure FormalReference where
  label : String
  kind : Option String  -- "Theorem", "Lemma", etc.
  deriving BEq, Repr

/-- Extended IR blocks for formal content -/
inductive FormalBlock
  | statement : FormalStatement → FormalBlock
  | assumption : String → List IR.Inline → FormalBlock
  | notation : String → String → FormalBlock  -- symbol, meaning
  deriving BEq, Repr

/-- Extended IR inlines for formal content -/
inductive FormalInline
  | formula : MathFormula → FormalInline
  | reference : FormalReference → FormalInline
  | term : String → FormalInline  -- Formal term reference
  deriving BEq, Repr

end Golitex.Formal