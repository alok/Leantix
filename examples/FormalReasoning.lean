/-
Copyright (c) 2024 The Golitex Contributors.
Released under the MIT license.
-/

import Golitex

/-!
# Formal Reasoning Example

This example demonstrates how to use Golitex's formal reasoning capabilities
to write mathematical documents with embedded proofs and formal verification.
-/

namespace FormalReasoningExample

open Golitex

-- Example of a document with theorems and proofs
def formalDocument : String := r#"
\documentclass{article}
\title{Introduction to Formal Reasoning in Golitex}
\author{Golitex Team}

\begin{document}

\section{Basic Theorems}

We demonstrate how Golitex integrates formal mathematical reasoning with
traditional LaTeX-style document authoring.

\begin{definition}[Natural Numbers]
The natural numbers $\mathbb{N}$ are defined inductively:
\begin{itemize}
\item $0 \in \mathbb{N}$
\item If $n \in \mathbb{N}$, then $n + 1 \in \mathbb{N}$
\end{itemize}
\end{definition}

\begin{theorem}[Addition Commutativity]\label{thm:add-comm}
For all natural numbers $a, b \in \mathbb{N}$:
$$a + b = b + a$$
\end{theorem}

\begin{proof}
We proceed by induction on $b$.

Base case: When $b = 0$, we have $a + 0 = a = 0 + a$ by the definition
of addition.

Inductive step: Assume $a + b = b + a$ for some $b$. We need to show
$a + (b + 1) = (b + 1) + a$.

By the definition of addition:
$$a + (b + 1) = (a + b) + 1 = (b + a) + 1$$

By the inductive hypothesis and the definition of addition again:
$$(b + a) + 1 = b + (a + 1) = b + (1 + a) = (b + 1) + a$$

Therefore, by induction, $a + b = b + a$ for all $a, b \in \mathbb{N}$.
\end{proof}

\begin{lemma}[Zero Identity]\label{lem:zero-id}
For any $n \in \mathbb{N}$: $n + 0 = n$
\end{lemma}

\begin{proof}
By definition of addition.
\end{proof}

\begin{example}
Let's verify that $2 + 3 = 5$:
\begin{align}
2 + 3 &= 2 + (2 + 1) \\
      &= (2 + 2) + 1 \\
      &= 4 + 1 \\
      &= 5
\end{align}
\end{example}

\section{Advanced Features}

Golitex supports various proof styles:

\begin{proposition}[Structured Proof Example]
If $P \implies Q$ and $Q \implies R$, then $P \implies R$.
\end{proposition}

\begin{proof}
Step 1: Assume $P$ holds.
Step 2: Since $P \implies Q$, we have $Q$.
Step 3: Since $Q \implies R$, we have $R$.
Step 4: Therefore $P \implies R$.
\end{proof}

We can also reference previous results: By \ref{thm:add-comm}, addition
is commutative. Combined with \ref{lem:zero-id}, we get nice properties.

\end{document}
"#

-- Parse the document with formal reasoning support
def parseExample : IO Unit := do
  match Golitex.Frontend.AST.parse formalDocument with
  | .ok ast =>
    IO.println "Successfully parsed formal document!"
    IO.println s!"Found {ast.length} top-level nodes"
  | .error e =>
    IO.println s!"Parse error: {e}"

-- Example of inline assertions (future feature)
def inlineAssertions : String := r#"
Consider the function $f(x) = x^2$.

\assert{$f(x) \geq 0$ for all $x \in \mathbb{R}$}

This follows because the square of any real number is non-negative.

\verify{
  For any $x \in \mathbb{R}$:
  - If $x \geq 0$, then $x^2 \geq 0$
  - If $x < 0$, then $x = -|x|$ and $x^2 = |x|^2 \geq 0$
}
"#

-- Example of Lean integration (future feature)
def leanIntegration : String := r#"
\begin{lean}
theorem add_comm (a b : Nat) : a + b = b + a := by
  induction b with
  | zero => rfl
  | succ b ih => simp [add_succ, ih]
\end{lean}

We can now use this theorem in our document:

\begin{theorem}[Verified Addition]
The Lean theorem \lean{add_comm} proves that addition is commutative.
\end{theorem}
"#

-- Demonstrate formal content rendering
def renderExample : IO Unit := do
  let doc := Document.mk [] [
    Block.section 1 [Inline.text "Formal Mathematics"] none,
    Block.paragraph [
      Inline.text "Here's a theorem about natural numbers:"
    ],
    Block.environment "theorem" ["Addition is Associative"] [
      Block.paragraph [
        Inline.text "For all ",
        Inline.math false "a, b, c \\in \\mathbb{N}",
        Inline.text ": ",
        Inline.math true "(a + b) + c = a + (b + c)"
      ]
    ],
    Block.environment "proof" [] [
      Block.paragraph [
        Inline.text "By induction on ",
        Inline.math false "c",
        Inline.text "."
      ]
    ]
  ]
  
  -- Render to LaTeX
  let latex := Golitex.Backend.LaTeX.renderDocument doc
  IO.println "LaTeX output:"
  IO.println latex

-- Main entry point
def main : IO Unit := do
  IO.println "=== Golitex Formal Reasoning Examples ==="
  IO.println ""
  
  IO.println "1. Parsing formal document..."
  parseExample
  IO.println ""
  
  IO.println "2. Rendering formal content..."
  renderExample
  IO.println ""
  
  IO.println "3. Future features preview:"
  IO.println "- Inline assertions for verification"
  IO.println "- Direct Lean theorem integration"
  IO.println "- Automatic proof checking"
  IO.println "- Export to formal proof assistants"

end FormalReasoningExample

-- Run the example
#eval FormalReasoningExample.main