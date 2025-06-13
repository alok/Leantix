import Verso.Parser
import MD4Lean
import Golitex

/-!
# Full Verso Integration for Golitex

This module provides full Verso integration using MD4Lean for markdown parsing
and custom rendering for Golitex-specific elements.
-/

namespace GolitexDocs.VersoIntegration

open MD4Lean

/-- Parse markdown content with Golitex extensions -/
def parseMarkdown (content : String) : Document := 
  match MD4Lean.parse content with
  | some doc => doc
  | none => { blocks := #[] }

/-- Convert MD4Lean document to HTML with Golitex support -/
def renderToHtml (doc : Document) : String :=
  let bodyHtml := renderBlocks doc.blocks
  wrapInHtml "Golitex Documentation" bodyHtml

where
  renderBlocks (blocks : Array Block) : String :=
    blocks.map renderBlock |> String.join

  renderBlock : Block → String
    | .heading level inlines => 
      s!"<h{level}>{renderInlines inlines}</h{level}>\n"
    | .paragraph inlines => 
      s!"<p>{renderInlines inlines}</p>\n"
    | .blockquote blocks => 
      s!"<blockquote>\n{renderBlocks blocks}</blockquote>\n"
    | .list ordered items =>
      let tag := if ordered then "ol" else "ul"
      let itemsHtml := items.map renderListItem |> String.join
      s!"<{tag}>\n{itemsHtml}</{tag}>\n"
    | .code info text =>
      let lang := info.takeWhile (· != ' ')
      if lang == "golitex" then
        renderGolitexExample text
      else
        s!"<pre><code class=\"language-{lang}\">{escapeHtml text}</code></pre>\n"
    | .html text => text
    | _ => ""

  renderListItem (item : ListItem) : String :=
    s!"<li>{renderBlocks item.blocks}</li>\n"

  renderInlines (inlines : Array Inline) : String :=
    inlines.map renderInline |> String.join

  renderInline : Inline → String
    | .text text => escapeHtml text
    | .code text => s!"<code>{escapeHtml text}</code>"
    | .emph inlines => s!"<em>{renderInlines inlines}</em>"
    | .strong inlines => s!"<strong>{renderInlines inlines}</strong>"
    | .link inlines url _ => s!"<a href=\"{url}\">{renderInlines inlines}</a>"
    | .image _ url title => s!"<img src=\"{url}\" alt=\"{title.getD ""}\"/>"
    | .linebreak => "<br/>\n"
    | _ => ""

  escapeHtml (s : String) : String :=
    s.replace "&" "&amp;"
     |>.replace "<" "&lt;"
     |>.replace ">" "&gt;"
     |>.replace "\"" "&quot;"

  renderGolitexExample (source : String) : String :=
    -- Parse and render Golitex source
    try
      let tokens := Golitex.scan source
      let ast := Golitex.parseTokens tokens
      let (doc, _) := Golitex.elaborate ast
      let rendered := Golitex.renderDocument doc
      s!"<div class=\"golitex-example\">
<div class=\"source\">
<pre><code class=\"language-latex\">{escapeHtml source}</code></pre>
</div>
<div class=\"output\">
<iframe srcdoc=\"{escapeHtml rendered}\" style=\"width: 100%; border: 1px solid #ddd;\"></iframe>
</div>
</div>\n"
    catch _ =>
      s!"<pre><code class=\"language-latex\">{escapeHtml source}</code></pre>\n"

  wrapInHtml (title : String) (body : String) : String :=
    s!"<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>{title}</title>
    <style>
    body \{
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        color: #333;
        max-width: 900px;
        margin: 0 auto;
        padding: 2rem;
    \}
    h1, h2, h3, h4, h5, h6 \{
        color: #2c3e50;
        margin-top: 2rem;
        margin-bottom: 1rem;
    \}
    h1 \{ border-bottom: 2px solid #3498db; padding-bottom: 0.5rem; \}
    code \{
        background: #f4f4f4;
        padding: 0.2em 0.4em;
        border-radius: 3px;
        font-family: 'Menlo', 'Monaco', monospace;
    \}
    pre \{
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 4px;
        padding: 1rem;
        overflow-x: auto;
    \}
    pre code \{
        background: none;
        padding: 0;
    \}
    blockquote \{
        border-left: 4px solid #ddd;
        padding-left: 1rem;
        margin-left: 0;
        color: #666;
    \}
    .golitex-example \{
        border: 1px solid #ddd;
        border-radius: 4px;
        margin: 1rem 0;
    \}
    .golitex-example .source \{
        background: #f5f5f5;
        padding: 1rem;
        border-bottom: 1px solid #ddd;
    \}
    .golitex-example .output \{
        padding: 1rem;
        background: white;
    \}
    </style>
    <script src=\"https://polyfill.io/v3/polyfill.min.js?features=es6\"></script>
    <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js\"></script>
</head>
<body>
    {body}
</body>
</html>"

/-- Documentation content in markdown format -/
def markdownContent : String := "# Golitex Documentation

Welcome to **Golitex**, a LaTeX-like domain-specific language for Lean 4.

## Features

- **Type-safe** document construction
- **Integration** with Lean's proof assistant  
- **Modern** error messages and tooling
- **Extensible** through Lean's macro system

## Quick Start

Add Golitex to your `lakefile.lean`:

```lean
require golitex from git
  \"https://github.com/yourusername/golitex.git\"
```

## Basic Example

Here's a simple Golitex document:

```golitex
\\section{Introduction}

This is a paragraph with \\emph{emphasis} and \\textbf{bold} text.

\\subsection{Mathematics}

Inline math: $x^2 + y^2 = z^2$

Display math:
$$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$
```

## Using the API

```lean
import Golitex

def myDoc := litex! \"
\\\\section{Hello, World!}
This is my first document.
\"

-- Convert to HTML
#eval do
  let tokens := scan myDoc.raw
  let ast := parseTokens tokens
  let (doc, _) := elaborate ast
  IO.println (renderDocument doc)
```

## Supported Commands

| Command | Description | Example |
|---------|-------------|---------|
| `\\section` | Section heading | `\\section{Title}` |
| `\\emph` | Emphasized text | `\\emph{important}` |
| `\\textbf` | Bold text | `\\textbf{bold}` |
| `\\texttt` | Monospace | `\\texttt{code}` |

## Advanced Features

### Custom Environments

```latex
\\begin{theorem}
Let $f$ be a continuous function...
\\end{theorem}
```

### Lists

```latex
\\begin{itemize}
\\item First item
\\item Second item
\\end{itemize}
```

## Contributing

Visit our [GitHub repository](https://github.com/golitex/golitex) to:

- Report issues
- Submit pull requests
- Read development docs

---

*Generated with Golitex and Verso*"

/-- Build the documentation -/
def buildDocs : IO Unit := do
  let doc := parseMarkdown markdownContent
  let html := renderToHtml doc
  
  let outputDir : System.FilePath := "_out/verso-full"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath html
  
  IO.println s!"Full Verso documentation generated at: {outputPath}"

def main : IO UInt32 := do
  buildDocs
  return 0

end GolitexDocs.VersoIntegration

-- Module-level main
def main : IO UInt32 := GolitexDocs.VersoIntegration.main