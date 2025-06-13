import Golitex

/-!
# HTML Demo

This example demonstrates the full pipeline from LaTeX source to HTML output.
-/

namespace HTMLDemo

open Golitex

def demoSource : String := "
\\section{Introduction}

This is a demonstration of the \\emph{Golitex} LaTeX-like DSL for Lean 4.

\\subsection{Features}

We support:
\\begin{itemize}
\\item Text with \\textbf{bold} and \\emph{italic} styles
\\item Nested \\textbf{\\emph{formatting}}
\\item Mathematical expressions like $x^2 + y^2 = z^2$
\\end{itemize}

\\subsection{Code Examples}

Here's some inline code: \\texttt{lake build} runs the build.

\\begin{verbatim}
def hello : String := \"Hello, world!\"
#eval hello
\\end{verbatim}

That's all for now!
"

def main : IO Unit := do
  -- Parse the source
  let tokens := scan demoSource
  let ast := parseTokens tokens
  
  -- Elaborate to IR
  let (doc, errors) := elaborate ast
  
  if !errors.isEmpty then
    IO.println s!"Errors during elaboration: {errors}"
  
  -- Render to HTML
  let options : Backend.HTML.RenderOptions := {
    title := "Golitex Demo"
    includeDefaultStyles := true
  }
  
  let html := Backend.HTML.renderDocument doc options
  
  -- Write to file
  let outputPath : System.FilePath := "demo.html"
  IO.FS.writeFile outputPath html
  
  IO.println s!"Generated HTML written to {outputPath}"
  IO.println ""
  IO.println "Preview of the HTML (first 500 chars):"
  IO.println (html.take 500 ++ "...")

-- #eval main