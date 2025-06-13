import Verso.Parser
import Verso.Output.Html
import Golitex

/-!
# Working Verso Integration

A minimal working Verso integration that properly handles HTML generation.
-/

namespace GolitexDocs.VersoWorking

open Verso.Output

/-- Create a simple HTML page with Verso -/
def createPage (title : String) (body : Array Html) : Html :=
  Html.tag "html" #[("lang", "en")] <|
    Html.seq #[
      Html.tag "head" #[] <|
        Html.seq #[
          Html.tag "meta" #[("charset", "UTF-8")] Html.empty,
          Html.tag "meta" #[("name", "viewport"), ("content", "width=device-width, initial-scale=1.0")] Html.empty,
          Html.tag "title" #[] (Html.text true title),
          Html.tag "style" #[] (Html.text false styles),
          Html.text false mathJaxScript
        ],
      Html.tag "body" #[] (Html.seq body)
    ]

where
  styles := "
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 900px;
      margin: 0 auto;
      padding: 2rem;
    }
    h1, h2, h3, h4, h5, h6 {
      color: #2c3e50;
      margin-top: 2rem;
      margin-bottom: 1rem;
    }
    h1 { 
      border-bottom: 2px solid #3498db; 
      padding-bottom: 0.5rem; 
    }
    code {
      background: #f4f4f4;
      padding: 0.2em 0.4em;
      border-radius: 3px;
      font-family: 'Menlo', 'Monaco', monospace;
    }
    pre {
      background: #f8f9fa;
      border: 1px solid #dee2e6;
      border-radius: 4px;
      padding: 1rem;
      overflow-x: auto;
    }
    blockquote {
      border-left: 4px solid #ddd;
      padding-left: 1rem;
      margin-left: 0;
      color: #666;
    }
    .golitex-example {
      border: 1px solid #ddd;
      border-radius: 4px;
      margin: 1rem 0;
      overflow: hidden;
    }
    .golitex-source {
      background: #f5f5f5;
      padding: 1rem;
      border-bottom: 1px solid #ddd;
    }
    .golitex-output {
      padding: 1rem;
    }
  "
  
  mathJaxScript := "
    <script>
    MathJax = {
      tex: {
        inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
        displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']]
      }
    };
    </script>
    <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js\"></script>"

/-- Convert Html to string -/
partial def htmlToString : Html → String
  | .text false s => s
  | .text true s => s.replace "&" "&amp;" |>.replace "<" "&lt;" |>.replace ">" "&gt;"
  | .tag name attrs content =>
    let attrStr := attrs.map (fun (k, v) => s!"{k}=\"{v.replace "\"" "&quot;"}\"") 
                        |> Array.toList |> String.intercalate " "
    let openTag := if attrStr.isEmpty then s!"<{name}>" else s!"<{name} {attrStr}>"
    s!"{openTag}{htmlToString content}</{name}>"
  | .seq contents =>
    contents.map htmlToString |> Array.toList |> String.join

/-- Render a Golitex example -/
def renderGolitexExample (source : String) : Html :=
  Html.tag "div" #[("class", "golitex-example")] <|
    Html.seq #[
      Html.tag "div" #[("class", "golitex-source")] <|
        Html.tag "pre" #[] <|
          Html.tag "code" #[("class", "language-latex")] <|
            Html.text true source,
      Html.tag "div" #[("class", "golitex-output")] <|
        renderGolitexOutput source
    ]

where
  renderGolitexOutput (source : String) : Html :=
    let tokens := Golitex.Frontend.Scanner.scan source
    let ast := Golitex.Frontend.AST.parseTokens tokens
    let (doc, _) := Golitex.Elab.elaborate ast
    let html := Golitex.Backend.HTML.renderDocument doc
    Html.text false html

/-- Build the documentation content -/
def buildContent : Array Html := #[
  Html.tag "h1" #[] (Html.text true "Golitex Documentation with Verso"),
  
  Html.tag "p" #[] (Html.text true "Welcome to Golitex, a LaTeX-like DSL for Lean 4. This documentation is generated using Verso's HTML generation capabilities."),
  
  Html.tag "h2" #[] (Html.text true "Features"),
  Html.tag "ul" #[] <| Html.seq #[
    Html.tag "li" #[] (Html.text true "Type-safe document construction"),
    Html.tag "li" #[] (Html.text true "Integration with Lean's proof assistant"),
    Html.tag "li" #[] (Html.text true "Multiple output backends (HTML, PDF planned)"),
    Html.tag "li" #[] (Html.text true "Extensible through Lean's macro system")
  ],
  
  Html.tag "h2" #[] (Html.text true "Quick Example"),
  Html.tag "p" #[] (Html.text true "Here's a simple Golitex document:"),
  
  renderGolitexExample "\\section{Introduction}

This is a paragraph with \\emph{emphasis} and \\textbf{bold} text.

\\subsection{Mathematics}

Inline math: $x^2 + y^2 = z^2$

Display math: $$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$",
  
  Html.tag "h2" #[] (Html.text true "Using the litex! Macro"),
  Html.tag "pre" #[] <| Html.tag "code" #[("class", "language-lean")] <|
    Html.text true "import Golitex

def myDoc := litex! \"
\\\\section{Hello, World!}
This is my first Golitex document.
\"

-- Convert to HTML
#eval do
  let tokens := scan myDoc.raw
  let ast := parseTokens tokens
  let (doc, _) := elaborate ast
  IO.println (renderDocument doc)",
  
  Html.tag "h2" #[] (Html.text true "Supported Commands"),
  Html.tag "table" #[("style", "border-collapse: collapse; width: 100%;")] <| Html.seq #[
    Html.tag "tr" #[] <| Html.seq #[
      Html.tag "th" #[("style", "border: 1px solid #ddd; padding: 8px;")] (Html.text true "Command"),
      Html.tag "th" #[("style", "border: 1px solid #ddd; padding: 8px;")] (Html.text true "Description"),
      Html.tag "th" #[("style", "border: 1px solid #ddd; padding: 8px;")] (Html.text true "Example")
    ],
    Html.tag "tr" #[] <| Html.seq #[
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.tag "code" #[] (Html.text true "\\section")),
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.text true "Section heading"),
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.tag "code" #[] (Html.text true "\\section{Title}"))
    ],
    Html.tag "tr" #[] <| Html.seq #[
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.tag "code" #[] (Html.text true "\\emph")),
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.text true "Emphasized text"),
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.tag "code" #[] (Html.text true "\\emph{important}"))
    ],
    Html.tag "tr" #[] <| Html.seq #[
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.tag "code" #[] (Html.text true "\\textbf")),
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.text true "Bold text"),
      Html.tag "td" #[("style", "border: 1px solid #ddd; padding: 8px;")] 
        (Html.tag "code" #[] (Html.text true "\\textbf{bold}"))
    ]
  ],
  
  Html.tag "h2" #[] (Html.text true "More Examples"),
  
  Html.tag "h3" #[] (Html.text true "Lists"),
  renderGolitexExample "\\begin{itemize}
\\item First item
\\item Second item with \\emph{emphasis}
\\item Third item
\\end{itemize}",
  
  Html.tag "h3" #[] (Html.text true "Nested Commands"),
  renderGolitexExample "Text with \\textbf{\\emph{bold and italic}} formatting.",
  
  Html.tag "p" #[] <| Html.seq #[
    Html.tag "em" #[] (Html.text true "Generated with Golitex and Verso")
  ]
]

/-- Main function -/
def main : IO UInt32 := do
  IO.println "Building Verso documentation..."
  
  let page := createPage "Golitex Documentation" buildContent
  let html := htmlToString page
  
  let outputDir : System.FilePath := "_out/verso-working"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath ("<!DOCTYPE html>\n" ++ html)
  
  IO.println s!"Documentation generated at: {outputPath}"
  return 0

end GolitexDocs.VersoWorking

-- Module entry point
def main : IO UInt32 := GolitexDocs.VersoWorking.main