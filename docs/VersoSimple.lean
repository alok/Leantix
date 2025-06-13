import Verso.Parser
import Verso.Output.Html
import MD4Lean
import Golitex

/-!
# Simple Verso Integration

A working Verso integration using only the modules that compile successfully.
-/

namespace GolitexDocs.VersoSimple

open Verso.Output
open MD4Lean

/-- Convert Golitex document to Verso HTML -/
def golitexToHtml (source : String) : IO Html := do
  try
    let tokens := Golitex.Frontend.Scanner.scan source
    let ast := Golitex.Frontend.AST.parseTokens tokens
    let (doc, errors) := Golitex.Elab.elaborate ast
    
    if !errors.isEmpty then
      for err in errors do
        IO.eprintln s!"Warning: {err}"
    
    let htmlStr := Golitex.Backend.HTML.renderDocument doc
    pure (.text false htmlStr)
  catch e =>
    pure (.text true s!"Error: {e}")

/-- Create a Verso HTML document -/
def createDocument (title : String) (content : Html) : Html :=
  Html.tag "html" #[("lang", "en")] <|
    Html.seq #[
      Html.tag "head" #[] <|
        Html.seq #[
          Html.tag "meta" #[("charset", "UTF-8")] Html.empty,
          Html.tag "meta" #[("name", "viewport"), ("content", "width=device-width, initial-scale=1.0")] Html.empty,
          Html.tag "title" #[] (Html.text true title),
          Html.tag "style" #[] (Html.text false defaultStyles)
        ],
      Html.tag "body" #[] content
    ]

where
  defaultStyles := "
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
    .example {
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
  "

/-- Build HTML content from markdown -/
def buildContent (markdown : String) : IO Html := do
  match MD4Lean.parse markdown with
  | none => pure (Html.text true "Failed to parse markdown")
  | some doc =>
    let blocks ← doc.blocks.mapM renderBlock
    pure (Html.seq blocks)

where
  renderBlock : Block → IO Html
    | .heading level inlines => do
      let content ← renderInlines inlines
      pure (Html.tag s!"h{level}" #[] content)
    | .paragraph inlines => do
      let content ← renderInlines inlines
      pure (Html.tag "p" #[] content)
    | .blockquote blocks => do
      let content ← blocks.mapM renderBlock
      pure (Html.tag "blockquote" #[] (Html.seq content))
    | .list ordered items => do
      let tag := if ordered then "ol" else "ul"
      let itemsHtml ← items.mapM renderListItem
      pure (Html.tag tag #[] (Html.seq itemsHtml))
    | .code info text => do
      let lang := info.takeWhile (· != ' ')
      if lang == "golitex" then
        renderGolitexExample text
      else
        pure (Html.tag "pre" #[] 
          (Html.tag "code" #[("class", s!"language-{lang}")] (Html.text true text)))
    | _ => pure Html.empty

  renderListItem (item : ListItem) : IO Html := do
    let blocks ← item.blocks.mapM renderBlock
    pure (Html.tag "li" #[] (Html.seq blocks))

  renderInlines (inlines : Array Inline) : IO Html := do
    let parts ← inlines.mapM renderInline
    pure (Html.seq parts)

  renderInline : Inline → IO Html
    | .text text => pure (Html.text true text)
    | .code text => pure (Html.tag "code" #[] (Html.text true text))
    | .emph inlines => do
      let content ← renderInlines inlines
      pure (Html.tag "em" #[] content)
    | .strong inlines => do
      let content ← renderInlines inlines
      pure (Html.tag "strong" #[] content)
    | .link inlines url _ => do
      let content ← renderInlines inlines
      pure (Html.tag "a" #[("href", url)] content)
    | _ => pure Html.empty

  renderGolitexExample (source : String) : IO Html := do
    let sourceHtml := Html.tag "div" #[("class", "example-source")] 
      (Html.tag "pre" #[] (Html.tag "code" #[] (Html.text true source)))
    
    let outputHtml ← do
      let rendered ← golitexToHtml source
      pure (Html.tag "div" #[("class", "example-output")] rendered)
    
    pure (Html.tag "div" #[("class", "example")] 
      (Html.seq #[sourceHtml, outputHtml]))

/-- Convert Html to string -/
partial def htmlToString : Html → String
  | .text false s => s
  | .text true s => escapeHtml s
  | .tag name attrs content =>
    let attrStr := attrs.map (fun (k, v) => s!"{k}=\"{escapeAttr v}\"") |> Array.toList |> String.intercalate " "
    let openTag := if attrStr.isEmpty then s!"<{name}>" else s!"<{name} {attrStr}>"
    if isVoidElement name && isEmpty content then
      s!"<{name}{if attrStr.isEmpty then "" else " " ++ attrStr} />"
    else
      s!"{openTag}{htmlToString content}</{name}>"
  | .seq contents =>
    contents.map htmlToString |> Array.toList |> String.join

where
  escapeHtml (s : String) : String :=
    s.replace "&" "&amp;"
     |>.replace "<" "&lt;"
     |>.replace ">" "&gt;"
     |>.replace "\"" "&quot;"
     |>.replace "'" "&#39;"

  escapeAttr (s : String) : String :=
    s.replace "&" "&amp;"
     |>.replace "\"" "&quot;"
     |>.replace "<" "&lt;"
     |>.replace ">" "&gt;"

  isVoidElement : String → Bool
    | "meta" | "link" | "br" | "hr" | "img" | "input" => true
    | _ => false

  isEmpty : Html → Bool
    | .text _ "" => true
    | .seq #[] => true
    | .seq contents => contents.all isEmpty
    | _ => false

/-- Example markdown content -/
def exampleContent := "# Golitex with Verso

This demonstrates **Verso** integration with the Golitex LaTeX DSL.

## Features

- Type-safe document construction
- Lean integration
- Multiple backends

## Example

Here's a Golitex example that will be rendered:

```golitex
\\section{Demo Section}

This is a paragraph with \\emph{emphasis} and \\textbf{bold} text.

Mathematics: $x^2 + y^2 = z^2$
```

## API Usage

```lean
import Golitex

def myDoc := litex! \"\\\\section{Title}\"
```

That's all!"

/-- Main function to generate documentation -/
def main : IO UInt32 := do
  IO.println "Building Verso documentation..."
  
  let content ← buildContent exampleContent
  let doc := createDocument "Golitex Documentation (Verso)" content
  let html := htmlToString doc
  
  let outputDir : System.FilePath := "_out/verso-simple"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath ("<!DOCTYPE html>\n" ++ html)
  
  IO.println s!"Documentation generated at: {outputPath}"
  return 0

end GolitexDocs.VersoSimple

-- Module entry point
def main : IO UInt32 := GolitexDocs.VersoSimple.main