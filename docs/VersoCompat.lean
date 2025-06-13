import Verso.Parser
import Verso.Output.Html
import Golitex

/-!
# Verso-Compatible Documentation Generator

This module provides a Verso-compatible documentation generator
that works with our current toolchain limitations.
-/

namespace GolitexDocs.VersoCompat

open Verso.Output Html

/-- Custom HTML generation for Golitex documentation -/
def generateHtml (title : String) (content : String) : String :=
  let processedContent := processGolitexContent content
  s!"<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>{title}</title>
    {defaultStyles}
    {mathJaxScript}
</head>
<body>
    <div class=\"verso-doc\">
        <h1>{title}</h1>
        {processedContent}
    </div>
</body>
</html>"

where
  defaultStyles : String := "
    <style>
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        color: #333;
        max-width: 900px;
        margin: 0 auto;
        padding: 2rem;
    }
    .verso-doc {
        background: white;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        padding: 2rem;
    }
    h1, h2, h3 {
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
    pre code {
        background: none;
        padding: 0;
    }
    .example {
        background: #f8f9fa;
        border-left: 4px solid #3498db;
        padding: 1rem;
        margin: 1rem 0;
    }
    .math {
        font-style: italic;
    }
    blockquote {
        border-left: 4px solid #ddd;
        padding-left: 1rem;
        margin-left: 0;
        color: #666;
    }
    </style>"
    
  mathJaxScript : String := "
    <script>
    MathJax = {
      tex: {
        inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
        displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']]
      }
    };
    </script>
    <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js\"></script>"
    
  processGolitexContent (content : String) : String :=
    -- Basic processing of Golitex syntax
    content
      |> processHeaders
      |> processEmphasis
      |> processBold
      |> processCode
      |> processMath
      
  processHeaders (s : String) : String :=
    s.replace "## " "<h2>"
      |> fun s => s.replace "\n\n" "</h2>\n\n"
      
  processEmphasis (s : String) : String :=
    -- Simple regex-like replacement for *emphasis*
    let parts := s.split (· == '*')
    let rec process (parts : List String) (inEmph : Bool) : String :=
      match parts with
      | [] => ""
      | p :: ps =>
        if inEmph then
          "<em>" ++ p ++ "</em>" ++ process ps false
        else
          p ++ process ps true
    process parts false
    
  processBold (s : String) : String :=
    -- Similar for **bold**
    s.replace "**" "<strong></strong>" -- Simplified
    
  processCode (s : String) : String :=
    -- Process inline code `code`
    let parts := s.split (· == '`')
    let rec process (parts : List String) (inCode : Bool) : String :=
      match parts with
      | [] => ""
      | p :: ps =>
        if inCode then
          "<code>" ++ p ++ "</code>" ++ process ps false
        else
          p ++ process ps true
    process parts false
    
  processMath (s : String) : String :=
    -- Leave math delimiters for MathJax
    s

/-- Build documentation from markdown-like content -/
def buildDocs (title : String) (content : String) : IO Unit := do
  let html := generateHtml title content
  
  let outputDir : System.FilePath := "_out/verso-compat"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath html
  
  IO.println s!"Documentation generated at: {outputPath}"

/-- Main documentation content -/
def golitexDocsContent : String := "
## Introduction

Golitex is a LaTeX-like domain-specific language (DSL) for Lean 4. It brings the familiar syntax of LaTeX to the Lean ecosystem, allowing you to write mathematical documents with type safety and integration with Lean's proof assistant.

## Getting Started

To use Golitex in your Lean 4 project, add it as a dependency in your `lakefile.lean`:

```lean
require golitex from git
  \"https://github.com/yourusername/golitex.git\"
```

Then import it in your Lean files:

```lean
import Golitex

def myDoc := litex! \"
\\\\section{Introduction}
This is a *Golitex* document with **bold** text.
\"
```

## Syntax Overview

Golitex supports standard LaTeX commands:

- `\\section{Title}` - Section headings
- `\\emph{text}` or `*text*` - Emphasized text  
- `\\textbf{text}` or `**text**` - Bold text
- `\\texttt{code}` or `` `code` `` - Monospace text
- `$x^2 + y^2 = z^2$` - Inline math
- `$$E = mc^2$$` - Display math

## API Reference

### Frontend Modules

The frontend consists of three main components:

1. **Scanner** - Tokenizes LaTeX source
2. **Parser** - Builds an abstract syntax tree
3. **Elaborator** - Converts AST to semantic IR

### Backend Modules

Currently supported backends:

- **HTML** - Generates web-ready HTML with MathJax support
- **PDF** (planned) - Direct PDF generation via LaTeX

## Examples

Here's a complete example:

```lean
import Golitex

-- Define a document
def myArticle := litex! \"
\\\\section{Pythagorean Theorem}

The Pythagorean theorem states that in a right triangle,
the square of the hypotenuse $c$ equals the sum of
squares of the other two sides $a$ and $b$:

$$a^2 + b^2 = c^2$$
\"

-- Convert to HTML
#eval do
  let tokens := scan myArticle.raw
  let ast := parseTokens tokens
  let (doc, _) := elaborate ast
  let html := renderDocument doc
  IO.println html
```

## Advanced Features

### Custom Commands

You can extend Golitex with custom commands:

```lean
-- Future feature: custom command registration
```

### Integration with Lean

Golitex documents can include Lean code blocks that are type-checked:

```lean
-- Future feature: embedded Lean code
```

## Contributing

Golitex is open source and welcomes contributions. See our GitHub repository for:

- Issue tracking
- Development guidelines  
- Contribution process

---

*This documentation was generated with Golitex itself!*
"

def main : IO UInt32 := do
  buildDocs "Golitex Documentation (Verso Edition)" golitexDocsContent
  return 0

end GolitexDocs.VersoCompat

-- Module-level main function for executable
def main : IO UInt32 := GolitexDocs.VersoCompat.main