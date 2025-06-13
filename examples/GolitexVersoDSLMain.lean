import Examples.GolitexVersoDSL
import Golitex.Verso.Genre

open Golitex.Verso

/-- Render a Golitex Verso document to HTML -/
def renderGolitexDoc (doc : Part GolitexGenre) : IO UInt32 := do
  -- Initialize state and context
  let mut state : GolitexState := {}
  let context : GolitexContext := {}
  
  -- Simple traversal (no fixpoint needed for this example)
  let (doc', state') := GolitexGenre.traverse doc |>.run context |>.run state
  
  -- Error handling
  let hadError ← IO.mkRef false
  let logError str := do
    hadError.set true
    IO.eprintln s!"Error: {str}"
  
  -- Render to HTML
  let (content, _) ← GolitexGenre.toHtml {logError} context state' {} {} {} doc' .empty
  
  -- Create full HTML document
  let html := Html.element "html" #[("lang", "en")] [
    Html.element "head" #[] [
      Html.element "meta" #[("charset", "UTF-8")] [],
      Html.element "meta" #[("name", "viewport"), ("content", "width=device-width, initial-scale=1.0")] [],
      Html.element "title" #[] [Html.text true doc'.titleString],
      Html.element "style" #[] [Html.text false styles],
      Html.text false mathJaxScript
    ],
    Html.element "body" #[] [
      Html.element "div" #[("class", "container")] [content]
    ]
  ]
  
  -- Write output
  let outputDir : System.FilePath := "_out/golitex-dsl"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath html.asString
  
  IO.println s!"Golitex DSL document rendered to: {outputPath}"
  
  if ← hadError.get then
    return 1
  else
    return 0

where
  styles := "
    body {
      font-family: 'Computer Modern', 'Times New Roman', serif;
      line-height: 1.6;
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      color: #333;
    }
    
    h1, h2, h3, h4 {
      margin-top: 2rem;
      margin-bottom: 1rem;
    }
    
    h1 { font-size: 2.5em; }
    h2 { font-size: 2em; }
    h3 { font-size: 1.5em; }
    
    p {
      margin: 1em 0;
      text-align: justify;
    }
    
    .container {
      background: white;
      box-shadow: 0 0 20px rgba(0,0,0,0.1);
      padding: 3rem;
    }
    
    /* Golitex-specific styles */
    .theorem {
      margin: 1.5em 0;
      padding: 1em;
      background: #f9f9f9;
      border-left: 3px solid #333;
    }
    
    .proof {
      margin: 1em 0;
      font-style: italic;
    }
    
    .proof::after {
      content: ' □';
      float: right;
      font-style: normal;
    }
    
    code {
      background: #f4f4f4;
      padding: 0.2em 0.4em;
      border-radius: 3px;
    }
    
    /* LaTeX-style math */
    .math {
      font-family: 'Computer Modern Math', 'Times New Roman', serif;
    }
    
    .display-math {
      display: block;
      text-align: center;
      margin: 1.5em 0;
    }
  "
  
  mathJaxScript := "
    <script>
    window.MathJax = {
      tex: {
        inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
        displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']],
        processEscapes: true
      },
      svg: {
        fontCache: 'global'
      }
    };
    </script>
    <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js\"></script>
  "

/-- Main entry point -/
def main : IO UInt32 := do
  -- The document is already defined in GolitexVersoDSL.lean
  -- In a real application, we would import and reference it here
  IO.println "Note: This would render the document defined in GolitexVersoDSL.lean"
  IO.println "To actually render, we need to reference the #doc defined there."
  return 0