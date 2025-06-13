import Verso.Parser
import Verso.Output.Html
import MD4Lean
import Golitex

/-!
# MD4Lean Integration with Golitex

This module demonstrates using MD4Lean to parse markdown content
and integrate it with Golitex documentation.
-/

namespace GolitexDocs.MD4LeanIntegration

open Verso.Output
open MD4Lean

/-- Convert MD4Lean AttrText to HTML string -/
def attrTextToString : AttrText → String
  | .normal s => s
  | .entity s => s
  | .nullchar => ""

/-- Convert MD4Lean Text to Verso Html -/
partial def mdTextToHtml : Text → Html
  | .normal s => Html.text true s
  | .nullchar => Html.empty
  | .br s => Html.seq #[Html.tag "br" #[] Html.empty, Html.text true s]
  | .softbr _ => Html.text true " "
  | .entity s => Html.text false s
  | .em contents => Html.tag "em" #[] (Html.seq (contents.map mdTextToHtml))
  | .strong contents => Html.tag "strong" #[] (Html.seq (contents.map mdTextToHtml))
  | .u contents => Html.tag "u" #[] (Html.seq (contents.map mdTextToHtml))
  | .a href title isAuto contents =>
    let hrefStr := String.join (href.map attrTextToString).toList
    let titleStr := String.join (title.map attrTextToString).toList
    let attrs := if titleStr.isEmpty then #[("href", hrefStr)] else #[("href", hrefStr), ("title", titleStr)]
    Html.tag "a" attrs (Html.seq (contents.map mdTextToHtml))
  | .img src title alt =>
    let srcStr := String.join (src.map attrTextToString).toList
    let titleStr := String.join (title.map attrTextToString).toList
    let altHtml := Html.seq (alt.map mdTextToHtml)
    let attrs := #[("src", srcStr)] ++ 
      (if titleStr.isEmpty then #[] else #[("title", titleStr)]) ++
      #[("alt", htmlToText altHtml)]
    Html.tag "img" attrs Html.empty
  | .code contents => Html.tag "code" #[] (Html.text true (String.join contents.toList))
  | .del contents => Html.tag "del" #[] (Html.seq (contents.map mdTextToHtml))
  | .latexMath contents => Html.text false s!"${String.join contents.toList}$"
  | .latexMathDisplay contents => Html.text false s!"$${String.join contents.toList}$$"
  | .wikiLink target contents =>
    let targetStr := String.join (target.map attrTextToString).toList
    Html.tag "a" #[("href", s!"wiki:{targetStr}"), ("class", "wiki-link")] 
      (Html.seq (contents.map mdTextToHtml))

where
  htmlToText : Html → String
    | .text _ s => s
    | .tag _ _ content => htmlToText content
    | .seq contents => String.join (contents.map htmlToText).toList

/-- Convert MD4Lean Block to Verso Html -/
partial def mdBlockToHtml : Block → Html
  | .p contents => Html.tag "p" #[] (Html.seq (contents.map mdTextToHtml))
  | .ul tight mark items =>
    let itemsHtml := items.map fun li =>
      Html.tag "li" #[] (Html.seq (li.contents.map mdBlockToHtml))
    Html.tag "ul" #[] (Html.seq itemsHtml)
  | .ol tight start mark items =>
    let itemsHtml := items.map fun li =>
      Html.tag "li" #[] (Html.seq (li.contents.map mdBlockToHtml))
    Html.tag "ol" #[("start", toString start)] (Html.seq itemsHtml)
  | .hr => Html.tag "hr" #[] Html.empty
  | .header level contents =>
    let tagName := s!"h{level}"
    Html.tag tagName #[] (Html.seq (contents.map mdTextToHtml))
  | .code info lang fenceChar contents =>
    let langStr := String.join (lang.map attrTextToString).toList
    let codeContent := String.join contents.toList
    let attrs := if langStr.isEmpty then #[] else #[("class", s!"language-{langStr}")]
    Html.tag "pre" #[] (Html.tag "code" attrs (Html.text true codeContent))
  | .html contents => Html.text false (String.join contents.toList)
  | .blockquote contents => 
    Html.tag "blockquote" #[] (Html.seq (contents.map mdBlockToHtml))
  | .table head body =>
    let headerRow := Html.tag "tr" #[] <| Html.seq <| head.map fun cell =>
      Html.tag "th" #[] (Html.seq (cell.map mdTextToHtml))
    let bodyRows := body.map fun row =>
      Html.tag "tr" #[] <| Html.seq <| row.map fun cell =>
        Html.tag "td" #[] (Html.seq (cell.map mdTextToHtml))
    Html.tag "table" #[] <| Html.seq #[
      Html.tag "thead" #[] headerRow,
      Html.tag "tbody" #[] (Html.seq bodyRows)
    ]

/-- Parse markdown and convert to Html -/
def parseMarkdownToHtml (markdown : String) : Option Html := do
  let doc ← MD4Lean.parse markdown MD_DIALECT_GITHUB
  return Html.seq (doc.blocks.map mdBlockToHtml)

/-- Create a markdown content section -/
def createMarkdownSection (title : String) (markdown : String) : Html :=
  Html.tag "div" #[("class", "markdown-section")] <|
    Html.seq #[
      Html.tag "h2" #[] (Html.text true title),
      parseMarkdownToHtml markdown |>.getD (Html.text true "Failed to parse markdown")
    ]

/-- Create a combined Golitex and Markdown example -/
def createCombinedExample (golitexSource : String) (markdownSource : String) : Html :=
  Html.tag "div" #[("class", "combined-example")] <|
    Html.seq #[
      Html.tag "div" #[("class", "example-row")] <|
        Html.seq #[
          Html.tag "div" #[("class", "example-column")] <|
            Html.seq #[
              Html.tag "h3" #[] (Html.text true "Golitex Source"),
              Html.tag "pre" #[] <| Html.tag "code" #[] (Html.text true golitexSource),
              Html.tag "h4" #[] (Html.text true "Golitex Output"),
              renderGolitexOutput golitexSource
            ],
          Html.tag "div" #[("class", "example-column")] <|
            Html.seq #[
              Html.tag "h3" #[] (Html.text true "Markdown Source"),
              Html.tag "pre" #[] <| Html.tag "code" #[] (Html.text true markdownSource),
              Html.tag "h4" #[] (Html.text true "Markdown Output"),
              parseMarkdownToHtml markdownSource |>.getD (Html.text true "Parse error")
            ]
        ]
    ]

where
  renderGolitexOutput (source : String) : Html :=
    let tokens := Golitex.Frontend.Scanner.scan source
    let ast := Golitex.Frontend.AST.parseTokens tokens
    let (doc, _) := Golitex.Elab.elaborate ast
    let html := Golitex.Backend.HTML.renderDocument doc
    Html.text false html

/-- Generate the MD4Lean integration documentation -/
def generateDocs : Html :=
  createPage "Golitex with MD4Lean Integration" <|
    Html.seq #[
      Html.tag "h1" #[] (Html.text true "Golitex with MD4Lean Integration"),
      
      Html.tag "p" #[] (Html.text true "This documentation demonstrates how MD4Lean can be used alongside Golitex to provide rich markdown parsing capabilities."),
      
      createMarkdownSection "Markdown Features" "
# Headers work great

You can have **bold text** and *italic text*.

## Lists are supported

- Unordered lists
- With multiple items
  - Even nested items

1. Ordered lists too
2. With numbers
3. And proper ordering

## Code blocks

```lean
def hello : String := \"world\"
```

## Links and images

[Visit Lean](https://leanprover.github.io) for more information.

> Block quotes provide emphasis
> across multiple lines

## Tables

| Feature | Golitex | Markdown |
|---------|---------|----------|
| Math    | ✓       | ✓        |
| Tables  | ✗       | ✓        |
| LaTeX   | ✓       | Partial  |
",
      
      Html.tag "h2" #[] (Html.text true "Comparison: Golitex vs Markdown"),
      
      createCombinedExample 
        "\\section{Document Structure}

This is a paragraph with \\emph{emphasis}.

\\subsection{Mathematics}

Inline math: $x^2 + y^2 = z^2$"
        "# Document Structure

This is a paragraph with *emphasis*.

## Mathematics  

Inline math: $x^2 + y^2 = z^2$",
      
      Html.tag "h2" #[] (Html.text true "Integration Benefits"),
      
      parseMarkdownToHtml "
### Why use both?

1. **Golitex** provides:
   - Type-safe document construction
   - Deep Lean integration
   - LaTeX compatibility
   
2. **MD4Lean** provides:
   - GitHub-flavored markdown
   - Tables and task lists
   - Wide ecosystem compatibility

### Example: Documentation Pipeline

```
Markdown files → MD4Lean → Verso Html
LaTeX files → Golitex → Verso Html
                          ↓
                  Unified Documentation
```
" |>.getD Html.empty,
      
      Html.tag "p" #[("style", "margin-top: 3rem; text-align: center; color: #666;")] 
        (Html.text true "Generated with Golitex, MD4Lean, and Verso")
    ]

where
  createPage (title : String) (body : Html) : Html :=
    Html.tag "html" #[("lang", "en")] <|
      Html.seq #[
        Html.tag "head" #[] <|
          Html.seq #[
            Html.tag "meta" #[("charset", "UTF-8")] Html.empty,
            Html.tag "meta" #[("name", "viewport"), ("content", "width=device-width, initial-scale=1.0")] Html.empty,
            Html.tag "title" #[] (Html.text true title),
            Html.tag "style" #[] (Html.text false styles)
          ],
        Html.tag "body" #[] body
      ]

  styles := "
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem;
      background: #f5f6fa;
    }
    h1, h2, h3, h4 { 
      color: #2c3e50; 
      margin-top: 2rem;
    }
    h1 { 
      border-bottom: 3px solid #3498db; 
      padding-bottom: 0.5rem; 
    }
    
    .markdown-section {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      margin: 2rem 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .combined-example {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      margin: 2rem 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .example-row {
      display: flex;
      gap: 2rem;
    }
    
    .example-column {
      flex: 1;
    }
    
    pre {
      background: #f8f9fa;
      border: 1px solid #dee2e6;
      border-radius: 4px;
      padding: 1rem;
      overflow-x: auto;
    }
    
    code {
      background: #f8f9fa;
      padding: 0.2em 0.4em;
      border-radius: 3px;
      font-family: 'Menlo', 'Monaco', monospace;
    }
    
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1rem 0;
    }
    
    th, td {
      border: 1px solid #ddd;
      padding: 0.5rem;
      text-align: left;
    }
    
    th {
      background: #f8f9fa;
      font-weight: bold;
    }
    
    blockquote {
      border-left: 4px solid #3498db;
      padding-left: 1rem;
      margin-left: 0;
      color: #666;
    }
    
    @media (max-width: 768px) {
      .example-row {
        flex-direction: column;
      }
    }
  "

/-- Convert Html to string -/
partial def htmlToString : Html → String
  | .text false s => s
  | .text true s => s.replace "&" "&amp;" |>.replace "<" "&lt;" |>.replace ">" "&gt;"
  | .tag name attrs content =>
    let attrStr := attrs.map (fun (k, v) => s!"{k}=\"{v.replace "\"" "&quot;"}\"") 
                        |> Array.toList |> String.intercalate " "
    let openTag := if attrStr.isEmpty then s!"<{name}>" else s!"<{name} {attrStr}>"
    if isVoid name && isEmpty content then
      s!"<{name}{if attrStr.isEmpty then "" else " " ++ attrStr} />"
    else
      s!"{openTag}{htmlToString content}</{name}>"
  | .seq contents =>
    contents.map htmlToString |> Array.toList |> String.join

where
  isVoid : String → Bool
    | "meta" | "link" | "br" | "hr" | "img" | "input" => true
    | _ => false
    
  isEmpty : Html → Bool
    | .text _ "" => true
    | .seq #[] => true
    | _ => false

/-- Main function -/
def main : IO UInt32 := do
  IO.println "Building MD4Lean integration documentation..."
  
  let doc := generateDocs
  let html := htmlToString doc
  
  let outputDir : System.FilePath := "_out/md4lean-integration"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath ("<!DOCTYPE html>\n" ++ html)
  
  IO.println s!"MD4Lean integration documentation generated at: {outputPath}"
  return 0

end GolitexDocs.MD4LeanIntegration

-- Module entry point
def main : IO UInt32 := GolitexDocs.MD4LeanIntegration.main