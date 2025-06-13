import Golitex.Verso.Genre

open Golitex.Verso

/-!
# Golitex DSL Demo in Verso

This demonstrates using Golitex as a proper embedded DSL within Verso documents.
-/

#doc (GolitexGenre) "Mathematical Document with Golitex DSL" =>

This document showcases the power of embedding Golitex's LaTeX DSL within Verso.

# Using the litex! Macro

We can embed Golitex documents directly using the `litex!` macro:

{golitexDoc (litex! "
\\section{Introduction to Groups}

A \\emph{group} is one of the fundamental structures in abstract algebra.
Groups arise naturally in many areas of mathematics and physics.

\\subsection{Definition}

A group $(G, \\cdot)$ consists of a set $G$ together with a binary operation 
$\\cdot : G \\times G \\to G$ satisfying:

\\begin{enumerate}
\\item \\textbf{Closure}: For all $a, b \\in G$, we have $a \\cdot b \\in G$.
\\item \\textbf{Associativity}: For all $a, b, c \\in G$, $(a \\cdot b) \\cdot c = a \\cdot (b \\cdot c)$.
\\item \\textbf{Identity}: There exists $e \\in G$ such that $a \\cdot e = e \\cdot a = a$ for all $a \\in G$.
\\item \\textbf{Inverse}: For each $a \\in G$, there exists $b \\in G$ such that $a \\cdot b = b \\cdot a = e$.
\\end{enumerate}
")}

# Inline Golitex Fragments

We can also use inline Golitex: {golitexInline (litex! "$e^{i\\pi} + 1 = 0$")} is Euler's identity.

Another example: The solution to {golitexInline (litex! "$ax^2 + bx + c = 0$")} is given by 
the quadratic formula.

# Complex Mathematical Content

{golitexDoc (litex! "
\\section{Differential Equations}

Consider the heat equation:
$$\\frac{\\partial u}{\\partial t} = \\alpha \\nabla^2 u$$

where $u(\\mathbf{x}, t)$ represents temperature and $\\alpha$ is the thermal diffusivity.

\\subsection{Separation of Variables}

Assuming $u(\\mathbf{x}, t) = X(\\mathbf{x})T(t)$, we get:
$$\\frac{1}{\\alpha T}\\frac{dT}{dt} = \\frac{\\nabla^2 X}{X} = -\\lambda$$

This gives us two ordinary differential equations:
\\begin{align}
\\frac{dT}{dt} + \\alpha\\lambda T &= 0 \\\\
\\nabla^2 X + \\lambda X &= 0
\\end{align}
")}

# Raw TeX Support

Sometimes you need raw TeX for special constructs:

{rawTex "
\\begin{tikzpicture}
  \\draw (0,0) circle (1cm);
  \\draw (-1,0) -- (1,0);
  \\draw (0,-1) -- (0,1);
\\end{tikzpicture}
"}

# Theorems and Proofs

{golitexDoc (litex! "
\\section{Number Theory}

\\begin{theorem}[Fermat's Little Theorem]
If $p$ is prime and $a$ is not divisible by $p$, then
$$a^{p-1} \\equiv 1 \\pmod{p}$$
\\end{theorem}

\\begin{proof}
Consider the set $\\{a, 2a, 3a, \\ldots, (p-1)a\\}$ modulo $p$.
Since $\\gcd(a, p) = 1$, these are all distinct and non-zero modulo $p$.
Therefore, this set is a permutation of $\\{1, 2, 3, \\ldots, p-1\\}$.

Thus:
$$a \\cdot 2a \\cdot 3a \\cdots (p-1)a \\equiv 1 \\cdot 2 \\cdot 3 \\cdots (p-1) \\pmod{p}$$

This gives us:
$$a^{p-1}(p-1)! \\equiv (p-1)! \\pmod{p}$$

Since $(p-1)!$ is coprime to $p$, we can divide both sides by $(p-1)!$ to get:
$$a^{p-1} \\equiv 1 \\pmod{p}$$
\\end{proof}
")}

# Conclusion

This demonstrates how Golitex functions as a full embedded DSL within Verso, allowing
mathematical documents to be written using familiar LaTeX syntax while benefiting from
Lean's type system and Verso's document processing capabilities.

References can be made using {golitexRef "intro"} to link to labeled sections.