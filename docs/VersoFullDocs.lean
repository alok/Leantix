import Verso.Parser
import Verso.Output.Html
import MD4Lean
import Golitex

/-!
# Full Verso Documentation Generation

This module provides a comprehensive Verso-based documentation system
that integrates Golitex, MD4Lean, and native Verso features.
-/

namespace GolitexDocs.VersoFull

open Verso.Output
open MD4Lean

/-- Documentation configuration -/
structure DocConfig where
  title : String := "Golitex Documentation"
  author : String := "Golitex Team"
  version : String := "0.1.0"
  enableMathJax : Bool := true
  enableSyntaxHighlight : Bool := true
  theme : String := "default"

/-- Navigation item -/
structure NavItem where
  title : String
  href : String
  children : Array NavItem := #[]

/-- Create navigation HTML -/
partial def createNavigation (items : Array NavItem) : Html :=
  Html.tag "nav" #[("class", "main-nav")] <|
    Html.tag "ul" #[] (Html.seq (items.map renderNavItem))
where
  renderNavItem (item : NavItem) : Html :=
    Html.tag "li" #[] <|
      Html.seq #[
        Html.tag "a" #[("href", item.href)] (Html.text true item.title),
        if item.children.isEmpty then Html.empty
        else Html.tag "ul" #[] (Html.seq (item.children.map renderNavItem))
      ]

/-- Create a documentation page with navigation -/
def createDocPage (config : DocConfig) (nav : Array NavItem) (content : Html) : Html :=
  Html.tag "html" #[("lang", "en")] <|
    Html.seq #[
      Html.tag "head" #[] (createHead config),
      Html.tag "body" #[] <|
        Html.seq #[
          createHeader config,
          Html.tag "div" #[("class", "container")] <|
            Html.seq #[
              Html.tag "aside" #[("class", "sidebar")] (createNavigation nav),
              Html.tag "main" #[("class", "content")] content
            ],
          createFooter config
        ]
    ]

where
  createHead (config : DocConfig) : Html :=
    Html.seq #[
      Html.tag "meta" #[("charset", "UTF-8")] Html.empty,
      Html.tag "meta" #[("name", "viewport"), ("content", "width=device-width, initial-scale=1.0")] Html.empty,
      Html.tag "title" #[] (Html.text true config.title),
      Html.tag "style" #[] (Html.text false (getThemeStyles config.theme)),
      if config.enableMathJax then Html.text false mathJaxScript else Html.empty,
      if config.enableSyntaxHighlight then Html.text false syntaxHighlightScript else Html.empty
    ]

  createHeader (config : DocConfig) : Html :=
    Html.tag "header" #[("class", "main-header")] <|
      Html.seq #[
        Html.tag "h1" #[] (Html.text true config.title),
        Html.tag "p" #[("class", "version")] (Html.text true s!"Version {config.version}")
      ]

  createFooter (config : DocConfig) : Html :=
    Html.tag "footer" #[("class", "main-footer")] <|
      Html.seq #[
        Html.tag "p" #[] <|
          Html.seq #[
            Html.text true s!"© 2025 {config.author}. Generated with ",
            Html.tag "a" #[("href", "https://github.com/leanprover/verso")] (Html.text true "Verso"),
            Html.text true " and ",
            Html.tag "a" #[("href", "https://leanprover.github.io")] (Html.text true "Lean 4")
          ]
      ]

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

  syntaxHighlightScript := "
    <link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css\">
    <script src=\"https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js\"></script>
    <script src=\"https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-lean.min.js\"></script>
    <script src=\"https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-latex.min.js\"></script>"

  getThemeStyles : String → String
    | "default" => defaultTheme
    | "dark" => darkTheme
    | _ => defaultTheme

  defaultTheme := "
    * {
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      margin: 0;
      padding: 0;
      background: #f5f6fa;
    }
    
    .main-header {
      background: #2c3e50;
      color: white;
      padding: 2rem;
      text-align: center;
    }
    
    .main-header h1 {
      margin: 0;
      font-size: 2.5rem;
    }
    
    .version {
      opacity: 0.8;
      margin: 0.5rem 0 0;
    }
    
    .container {
      display: flex;
      max-width: 1400px;
      margin: 0 auto;
      min-height: calc(100vh - 200px);
    }
    
    .sidebar {
      width: 250px;
      background: white;
      padding: 2rem;
      border-right: 1px solid #e1e4e8;
    }
    
    .main-nav ul {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    
    .main-nav li {
      margin: 0.5rem 0;
    }
    
    .main-nav a {
      color: #2c3e50;
      text-decoration: none;
      display: block;
      padding: 0.5rem;
      border-radius: 4px;
      transition: background 0.2s;
    }
    
    .main-nav a:hover {
      background: #f0f0f0;
    }
    
    .main-nav ul ul {
      margin-left: 1rem;
      margin-top: 0.5rem;
    }
    
    .content {
      flex: 1;
      padding: 2rem 3rem;
      background: white;
      overflow-y: auto;
    }
    
    .main-footer {
      background: #2c3e50;
      color: white;
      text-align: center;
      padding: 2rem;
    }
    
    .main-footer a {
      color: #3498db;
    }
    
    h1, h2, h3, h4, h5, h6 {
      color: #2c3e50;
      margin-top: 2rem;
      margin-bottom: 1rem;
    }
    
    h1 {
      border-bottom: 3px solid #3498db;
      padding-bottom: 0.5rem;
    }
    
    code {
      background: #f8f9fa;
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
      background: transparent;
      padding: 0;
    }
    
    blockquote {
      border-left: 4px solid #3498db;
      padding-left: 1rem;
      margin-left: 0;
      color: #666;
    }
    
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1rem 0;
    }
    
    th, td {
      border: 1px solid #dee2e6;
      padding: 0.75rem;
      text-align: left;
    }
    
    th {
      background: #f8f9fa;
      font-weight: bold;
    }
    
    .example-box {
      border: 1px solid #dee2e6;
      border-radius: 4px;
      margin: 1rem 0;
      overflow: hidden;
    }
    
    .example-header {
      background: #f8f9fa;
      padding: 0.75rem 1rem;
      border-bottom: 1px solid #dee2e6;
      font-weight: bold;
    }
    
    .example-content {
      padding: 1rem;
    }
    
    @media (max-width: 768px) {
      .container {
        flex-direction: column;
      }
      
      .sidebar {
        width: 100%;
        border-right: none;
        border-bottom: 1px solid #e1e4e8;
      }
    }
  "

  darkTheme := defaultTheme ++ "
    /* Dark theme overrides */
    body {
      background: #1a1a1a;
      color: #e0e0e0;
    }
    
    .main-header {
      background: #0d0d0d;
    }
    
    .sidebar {
      background: #2d2d2d;
      border-color: #444;
    }
    
    .content {
      background: #2d2d2d;
    }
    
    .main-footer {
      background: #0d0d0d;
    }
    
    h1, h2, h3, h4, h5, h6 {
      color: #e0e0e0;
    }
    
    code {
      background: #3d3d3d;
      color: #f8f8f2;
    }
    
    pre {
      background: #3d3d3d;
      border-color: #555;
    }
    
    th {
      background: #3d3d3d;
    }
    
    th, td {
      border-color: #555;
    }
  "

/-- Create an example box -/
def createExample (title : String) (content : Html) : Html :=
  Html.tag "div" #[("class", "example-box")] <|
    Html.seq #[
      Html.tag "div" #[("class", "example-header")] (Html.text true title),
      Html.tag "div" #[("class", "example-content")] content
    ]

/-- Render Golitex source with output -/
def renderGolitexExample (source : String) : Html :=
  createExample "Golitex Example" <|
    Html.seq #[
      Html.tag "pre" #[] <| Html.tag "code" #[("class", "language-latex")] 
        (Html.text true source),
      Html.tag "div" #[("class", "output")] <|
        Html.seq #[
          Html.tag "h4" #[] (Html.text true "Output:"),
          renderGolitexOutput source
        ]
    ]
where
  renderGolitexOutput (source : String) : Html :=
    let tokens := Golitex.Frontend.Scanner.scan source
    let ast := Golitex.Frontend.AST.parseTokens tokens
    let (doc, _) := Golitex.Elab.elaborate ast
    let html := Golitex.Backend.HTML.renderDocument doc
    Html.text false html

/-- Convert MD4Lean AttrText to string -/
def attrTextToString : AttrText → String
  | .normal s => s
  | .entity s => s
  | .nullchar => ""

/-- Convert MD4Lean Text to Html -/
partial def mdTextToHtml : MD4Lean.Text → Html
  | .normal s => Html.text true s
  | .em contents => Html.tag "em" #[] (Html.seq (contents.map mdTextToHtml))
  | .strong contents => Html.tag "strong" #[] (Html.seq (contents.map mdTextToHtml))
  | .code contents => Html.tag "code" #[] (Html.text true (String.join contents.toList))
  | .a href _ _ contents =>
    let hrefStr := String.join (href.map attrTextToString).toList
    Html.tag "a" #[("href", hrefStr)] (Html.seq (contents.map mdTextToHtml))
  | _ => Html.empty

/-- Convert MD4Lean Block to Html -/
partial def mdBlockToHtml : MD4Lean.Block → Html
  | .p contents => Html.tag "p" #[] (Html.seq (contents.map mdTextToHtml))
  | .header level contents => 
    Html.tag s!"h{level}" #[] (Html.seq (contents.map mdTextToHtml))
  | .code _ lang _ contents =>
    let langStr := String.join (lang.map attrTextToString).toList
    let attrs := if langStr.isEmpty then #[] else #[("class", s!"language-{langStr}")]
    Html.tag "pre" #[] <| Html.tag "code" attrs 
      (Html.text true (String.join contents.toList))
  | .ul _ _ items =>
    Html.tag "ul" #[] (Html.seq (items.map fun li =>
      Html.tag "li" #[] (Html.seq (li.contents.map mdBlockToHtml))))
  | .ol _ start _ items =>
    Html.tag "ol" #[("start", toString start)] (Html.seq (items.map fun li =>
      Html.tag "li" #[] (Html.seq (li.contents.map mdBlockToHtml))))
  | _ => Html.empty

/-- Convert MD4Lean Document to Html -/
def mdDocToHtml (doc : MD4Lean.Document) : Html :=
  Html.seq (doc.blocks.map mdBlockToHtml)

/-- Parse markdown to Html -/
def parseMarkdown (md : String) : Html :=
  match MD4Lean.parse md MD_DIALECT_GITHUB with
  | some doc => mdDocToHtml doc
  | none => Html.text true "Failed to parse markdown"

/-- Build the complete documentation -/
def buildDocumentation : Html :=
  let config : DocConfig := {
    title := "Golitex: LaTeX-like DSL for Lean 4"
    author := "Golitex Contributors"
    version := "0.1.0"
  }
  
  let navigation : Array NavItem := #[
    { title := "Getting Started", href := "#getting-started" },
    { title := "Features", href := "#features", children := #[
      { title := "Basic Syntax", href := "#basic-syntax" },
      { title := "Mathematics", href := "#mathematics" },
      { title := "Environments", href := "#environments" }
    ]},
    { title := "API Reference", href := "#api-reference" },
    { title := "Examples", href := "#examples" },
    { title := "Integration", href := "#integration" }
  ]
  
  let mainContent := Html.seq #[
    Html.tag "section" #[("id", "getting-started")] <|
      Html.seq #[
        Html.tag "h1" #[] (Html.text true "Getting Started"),
        parseMarkdown "
Welcome to **Golitex**, a type-safe LaTeX-like document authoring system built on Lean 4.

## Installation

Add Golitex to your `lakefile.lean`:

```lean
require golitex from git
  \"https://github.com/yourusername/golitex.git\" @ \"main\"
```

## Quick Start

```lean
import Golitex

def myDoc := litex! \"
\\\\section{Hello, World!}
This is my first Golitex document.
\"
```
"
      ],
    
    Html.tag "section" #[("id", "features")] <|
      Html.seq #[
        Html.tag "h1" #[] (Html.text true "Features"),
        
        Html.tag "div" #[("id", "basic-syntax")] <|
          Html.seq #[
            Html.tag "h2" #[] (Html.text true "Basic Syntax"),
            renderGolitexExample "\\section{Document Structure}

Paragraphs are separated by blank lines.

You can use \\emph{emphasis} and \\textbf{bold} formatting.

\\subsection{Lists}

Lists are created with environments (coming soon)."
          ],
        
        Html.tag "div" #[("id", "mathematics")] <|
          Html.seq #[
            Html.tag "h2" #[] (Html.text true "Mathematics"),
            renderGolitexExample "\\section{Mathematical Expressions}

Inline mathematics: $E = mc^2$

Display mathematics:
$$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$"
          ],
        
        Html.tag "div" #[("id", "environments")] <|
          Html.seq #[
            Html.tag "h2" #[] (Html.text true "Environments"),
            parseMarkdown "
Golitex supports various LaTeX-like environments:

- `itemize` for unordered lists
- `enumerate` for ordered lists
- `theorem`, `lemma`, `proof` for mathematical content
- Custom environments can be defined
"
          ]
      ],
    
    Html.tag "section" #[("id", "api-reference")] <|
      Html.seq #[
        Html.tag "h1" #[] (Html.text true "API Reference"),
        createExample "Core Functions" <|
          Html.tag "table" #[] <|
            Html.seq #[
              Html.tag "thead" #[] <| Html.tag "tr" #[] <| Html.seq #[
                Html.tag "th" #[] (Html.text true "Function"),
                Html.tag "th" #[] (Html.text true "Type"),
                Html.tag "th" #[] (Html.text true "Description")
              ],
              Html.tag "tbody" #[] <| Html.seq #[
                Html.tag "tr" #[] <| Html.seq #[
                  Html.tag "td" #[] (Html.tag "code" #[] (Html.text true "scan")),
                  Html.tag "td" #[] (Html.tag "code" #[] (Html.text true "String → Array Token")),
                  Html.tag "td" #[] (Html.text true "Tokenize LaTeX source")
                ],
                Html.tag "tr" #[] <| Html.seq #[
                  Html.tag "td" #[] (Html.tag "code" #[] (Html.text true "parseTokens")),
                  Html.tag "td" #[] (Html.tag "code" #[] (Html.text true "Array Token → Node")),
                  Html.tag "td" #[] (Html.text true "Parse tokens to AST")
                ],
                Html.tag "tr" #[] <| Html.seq #[
                  Html.tag "td" #[] (Html.tag "code" #[] (Html.text true "elaborate")),
                  Html.tag "td" #[] (Html.tag "code" #[] (Html.text true "Node → ElabM Document")),
                  Html.tag "td" #[] (Html.text true "Elaborate AST to IR")
                ]
              ]
            ]
      ],
    
    Html.tag "section" #[("id", "examples")] <|
      Html.seq #[
        Html.tag "h1" #[] (Html.text true "Examples"),
        renderGolitexExample "\\section{Complete Example}

\\subsection{Introduction}
This example demonstrates various Golitex features.

\\subsection{Text Formatting}
We support \\emph{italic}, \\textbf{bold}, and
\\textbf{\\emph{bold italic}} text.

\\subsection{Mathematics}
The quadratic formula: $x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$"
      ],
    
    Html.tag "section" #[("id", "integration")] <|
      Html.seq #[
        Html.tag "h1" #[] (Html.text true "Integration"),
        parseMarkdown "
## Verso Integration

Golitex integrates seamlessly with Verso for documentation generation:

```lean
import Verso.Parser
import Golitex

def generateDocs : Html := ...
```

## MD4Lean Support

You can also use MD4Lean for parsing Markdown alongside Golitex:

```lean
import MD4Lean
import Golitex

-- Parse both Markdown and LaTeX
```
"
      ]
  ]
  
  createDocPage config navigation mainContent

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
  IO.println "Generating full Verso documentation..."
  
  let doc := buildDocumentation
  let html := htmlToString doc
  
  let outputDir : System.FilePath := "_out/verso-full-docs"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath ("<!DOCTYPE html>\n" ++ html)
  
  IO.println s!"Full documentation generated at: {outputPath}"
  return 0

end GolitexDocs.VersoFull

-- Module entry point
def main : IO UInt32 := GolitexDocs.VersoFull.main