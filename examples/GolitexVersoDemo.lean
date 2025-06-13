import Golitex.Genre

open GolitexGenre

/-!
# Golitex Verso Demo

This file demonstrates using Golitex as a DSL within Verso documents.
-/

#doc (Golitex) "Mathematical Analysis with Golitex" =>
%%%
label := "main"
preamble := #["\\usepackage{amsmath}", "\\usepackage{amsthm}"]
%%%

Welcome to this demonstration of {cmd "textbf" #["Golitex"]}[], a LaTeX-like DSL integrated with Verso.

# Introduction
%%%
label := "intro" 
%%%

Golitex allows you to write mathematical documents using familiar LaTeX syntax within the Verso framework. 
For example, we can write inline math like {math "E = mc^2"}[] or references to equations like {ref "euler"}[].

# Mathematical Content

Let's explore some mathematical expressions. The famous Euler's identity can be written as:

{displayMath "e^{i\\pi} + 1 = 0"}

We can also use environments:

{env "theorem" #[] #[
  .para #[.text "For any real number ", {math "x"}[], .text ", we have ", {math "\\sin^2 x + \\cos^2 x = 1"}[], .text "."]
]}

## Inline Mathematics

Inline mathematics is seamlessly integrated: The quadratic formula is {math "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"}[].

## Display Mathematics

For more complex expressions, we use display mode:

{displayMath "\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}"}

# Working with Environments

{env "definition" #[] #[
  .para #[.text "A ", {cmd "emph" #["group"]}[], .text " is a set ", {math "G"}[], .text " together with a binary operation ", {math "\\cdot"}[], .text " that satisfies:"],
  .ul false #[
    .mk #[.para #[.text "Closure: ", {math "\\forall a, b \\in G, a \\cdot b \\in G"}[]]],
    .mk #[.para #[.text "Associativity: ", {math "\\forall a, b, c \\in G, (a \\cdot b) \\cdot c = a \\cdot (b \\cdot c)"}[]]],
    .mk #[.para #[.text "Identity: ", {math "\\exists e \\in G, \\forall a \\in G, a \\cdot e = e \\cdot a = a"}[]]],
    .mk #[.para #[.text "Inverse: ", {math "\\forall a \\in G, \\exists b \\in G, a \\cdot b = b \\cdot a = e"}[]]]
  ]
]}

# Citations and References

As shown in {cite #["knuth1984", "lamport1994"]}[], TeX and LaTeX have revolutionized mathematical typesetting.

See {ref "intro"}[] for more details about this document.

# Raw LaTeX Support

Sometimes you need to include raw LaTeX:

{rawLatex "\\begin{align}
  \\nabla \\times \\vec{E} &= -\\frac{\\partial \\vec{B}}{\\partial t} \\\\
  \\nabla \\times \\vec{B} &= \\mu_0 \\vec{J} + \\mu_0 \\epsilon_0 \\frac{\\partial \\vec{E}}{\\partial t}
\\end{align}"}

# Conclusion

This demonstrates how Golitex can be used as a proper DSL within Verso, combining the power of LaTeX mathematical typesetting with Verso's document processing capabilities.