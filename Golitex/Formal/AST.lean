/-
Copyright (c) 2024 The Golitex Contributors.
Released under the MIT license.
-/

import Golitex.Frontend.AST
import Golitex.Formal.Types

/-!
# Formal Reasoning AST Extensions

This module extends the base AST with nodes specific to formal mathematical
reasoning, including theorems, proofs, and semantic mathematical expressions.
-/

namespace Golitex.Formal.AST

open Golitex.Frontend.AST

/-- Extended AST nodes for formal reasoning -/
inductive FormalNode
  /-- Theorem-like statement with label, name, statement, and optional proof -/
  | theorem (kind : StatementKind) (label : Option String) (name : Option String) 
            (statement : List Node) (proof : Option ProofNode) (pos : Option SourcePos := none)
  /-- Proof environment with structured content -/
  | proof (content : ProofNode) (pos : Option SourcePos := none)
  /-- Mathematical formula with semantic annotations -/
  | math (inline : Bool) (source : String) (semantics : Option MathNode) (pos : Option SourcePos := none)
  /-- Cross-reference to formal statement -/
  | ref (label : String) (kind : Option String) (pos : Option SourcePos := none)
  /-- Assumption declaration -/
  | assume (label : Option String) (content : List Node) (pos : Option SourcePos := none)
  /-- Notation declaration -/
  | notation (symbol : String) (meaning : List Node) (pos : Option SourcePos := none)
  deriving Repr, Inhabited

/-- AST nodes for proof content -/
inductive ProofNode
  /-- Prose proof (unstructured text and commands) -/
  | prose : List Node → ProofNode
  /-- Structured proof with steps -/
  | structured : List ProofStepNode → ProofNode
  /-- Proof by reference (e.g., "by Theorem 3.1") -/
  | byReference : String → ProofNode
  /-- Omitted proof (e.g., "obvious", "by induction") -/
  | omitted : String → ProofNode
  /-- Qed marker -/
  | qed : ProofNode
  deriving Repr, Inhabited

/-- AST node for a proof step -/
structure ProofStepNode where
  label : Option String
  content : List Node
  justification : Option String
  substeps : List ProofStepNode
  deriving Repr, Inhabited

/-- AST nodes for mathematical expressions with semantics -/
inductive MathNode
  /-- Variable or identifier -/
  | var : String → MathNode
  /-- Constant or literal -/
  | const : String → MathNode
  /-- Function application -/
  | app : MathNode → List MathNode → MathNode
  /-- Lambda abstraction -/
  | lam : String → MathNode → MathNode
  /-- Binary relation (=, <, ≤, etc.) -/
  | rel : String → MathNode → MathNode → MathNode
  /-- Operator application (+, -, *, etc.) -/
  | op : String → List MathNode → MathNode
  /-- Subscript -/
  | sub : MathNode → MathNode → MathNode
  /-- Superscript -/
  | sup : MathNode → MathNode → MathNode
  /-- Fraction -/
  | frac : MathNode → MathNode → MathNode
  /-- Square root -/
  | sqrt : MathNode → MathNode
  /-- Summation -/
  | sum : MathNode → MathNode → MathNode → MathNode  -- lower, upper, body
  /-- Product -/
  | prod : MathNode → MathNode → MathNode → MathNode  -- lower, upper, body
  /-- Integral -/
  | int : Option MathNode → Option MathNode → MathNode → MathNode  -- lower, upper, body
  deriving Repr, Inhabited

/-- Check if an environment name corresponds to a formal statement -/
def isFormalEnvironment (name : String) : Bool :=
  name ∈ ["theorem", "lemma", "proposition", "corollary", "definition", "axiom", "example", "proof"]

/-- Convert environment name to statement kind -/
def envNameToStatementKind (name : String) : Option StatementKind :=
  match name with
  | "theorem" => some .theorem
  | "lemma" => some .lemma
  | "proposition" => some .proposition
  | "corollary" => some .corollary
  | "definition" => some .definition
  | "axiom" => some .axiom
  | "example" => some .example
  | _ => none

/-- Extended node type that combines regular and formal nodes -/
inductive ExtendedNode
  | regular : Node → ExtendedNode
  | formal : FormalNode → ExtendedNode
  deriving Repr, Inhabited

end Golitex.Formal.AST