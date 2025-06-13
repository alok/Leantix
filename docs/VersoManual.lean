import Verso
import Verso.Parser
import Docs.GolitexGenre
import Golitex

open Verso.Parser
open Verso Doc Genre
open GolitexDocs

-- Create a simple documentation structure
def golitexIntro : Part GolitexGenre :=
  let title := [Doc.Inline.text "Getting Started with Golitex"]
  { title
    titleString := Doc.Inline.toString title
    metadata := some {}
    content := #[
      Doc.Block.para #[
        .text "Welcome to Golitex, a LaTeX-like DSL for Lean 4. ",
        .text "This guide will help you create your first document."
      ],
      
      Doc.Block.para #[.text "Here's a simple example:"],
      
      example "\\section{Hello}\nThis is a paragraph with \\emph{emphasis}.",
      
      Doc.Block.para #[
        .text "You can also include math: ",
        math "x^2 + y^2 = z^2",
        .text " or display it:"
      ],
      
      displayMath "\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}"
    ]
    subParts := #[]
  }

def syntaxReference : Part GolitexGenre :=
  let title := [Doc.Inline.text "Syntax Reference"] 
  { title
    titleString := Doc.Inline.toString title
    metadata := some { tag := some "syntax" }
    content := #[
      Doc.Block.para #[.text "Golitex supports various LaTeX commands:"],
      
      Doc.Block.ul #[
        .mk #[Doc.Block.para #[latexCmd "section" #[.text "Section Title"]]],
        .mk #[Doc.Block.para #[latexCmd "emph" #[.text "emphasized"]]],
        .mk #[Doc.Block.para #[latexCmd "textbf" #[.text "bold"]]]
      ],
      
      latexEnv "example" #[
        Doc.Block.para #[.text "This is inside a custom environment."]
      ]
    ]
    subParts := #[]
  }

def golitexManual : Part GolitexGenre :=
  let title := [Doc.Inline.text "Golitex Documentation"]
  { title
    titleString := Doc.Inline.toString title  
    metadata := some {}
    content := #[
      Doc.Block.para #[
        .text "Golitex brings LaTeX-style document authoring to Lean 4."
      ]
    ]
    subParts := #[golitexIntro, syntaxReference]
  }

-- Rendering function
def renderManual : IO UInt32 := do
  -- Traverse the document
  let context : TraverseContext := {}
  let state : TraverseState := {}
  let (doc, finalState) := GolitexGenre.traverse golitexManual |>.run context |>.run state
  
  -- Set up HTML rendering
  let hadError ← IO.mkRef false
  let logError msg := do
    hadError.set true
    IO.eprintln msg
    
  -- Render to HTML
  let (content, _) ← GolitexGenre.toHtml {logError} context finalState {} {} {} doc .empty
  
  let styles := "
    body {
      font-family: -apple-system, system-ui, sans-serif;
      line-height: 1.6;
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
    }
    .golitex-example {
      border: 1px solid #ddd;
      border-radius: 4px;
      margin: 1rem 0;
    }
    .example-source {
      background: #f5f5f5;
      padding: 1rem;
      border-bottom: 1px solid #ddd;
    }
    .example-output {
      padding: 1rem;
    }
    .latex-cmd {
      font-family: monospace;
      color: #0066cc;
    }
    .math {
      font-style: italic;
    }
    pre {
      background: #f5f5f5;
      padding: 0.5rem;
      overflow-x: auto;
    }
  "
  
  let html := {{
    <html>
      <head>
        <title>Golitex Documentation</title>
        <meta charset="utf-8"/>
        <style>{{styles}}</style>
        <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
        <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
      </head>
      <body>{{content}}</body>
    </html>
  }}
  
  -- Write output
  let outputDir : System.FilePath := "_out/verso-manual"
  IO.FS.createDirAll outputDir
  let outputPath := outputDir / "index.html"
  
  IO.FS.withFile outputPath .write fun h => do
    h.putStrLn html.asString
    
  IO.println s!"Manual written to {outputPath}"
  
  if ← hadError.get then
    IO.eprintln "Errors occurred during rendering"
    pure 1
  else
    pure 0