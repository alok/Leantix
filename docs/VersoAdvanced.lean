import Verso.Parser
import Verso.Output.Html
import Golitex

/-!
# Advanced Verso Integration

This module demonstrates advanced Verso features including custom syntax highlighting
and interactive documentation elements.
-/

namespace GolitexDocs.VersoAdvanced

open Verso.Output
open Verso.Parser

/-- Custom highlighter for Golitex syntax -/
structure GolitexHighlighter where
  name : String := "golitex"

/-- Highlight Golitex code -/
def highlightGolitex (code : String) : Html :=
  let lines := code.split (· == '\n')
  let highlightedLines := lines.map highlightLine
  Html.tag "pre" #[("class", "golitex-highlighted")] <|
    Html.tag "code" #[] <|
      Html.seq (highlightedLines.toArray)

where
  highlightLine (line : String) : Html :=
    if line.startsWith "\\section" || line.startsWith "\\subsection" then
      Html.seq #[
        Html.tag "span" #[("class", "golitex-command")] (Html.text true (line.takeWhile (· != '{'))),
        Html.text true (line.dropWhile (· != '{')),
        Html.text true "\n"
      ]
    else if (line.splitOn "\\emph").length > 1 || (line.splitOn "\\textbf").length > 1 then
      -- Simple highlighting for inline commands
      let parts := line.split (· == '\\')
      let highlighted := parts.mapIdx fun i part =>
        if i > 0 && (part.startsWith "emph" || part.startsWith "textbf") then
          Html.seq #[
            Html.text true "\\",
            Html.tag "span" #[("class", "golitex-command")] 
              (Html.text true (part.takeWhile (fun c => c.isAlpha))),
            Html.text true (part.dropWhile (fun c => c.isAlpha))
          ]
        else
          Html.text true (if i > 0 then "\\" ++ part else part)
      Html.seq #[Html.seq highlighted.toArray, Html.text true "\n"]
    else
      Html.seq #[Html.text true line, Html.text true "\n"]

/-- Interactive Golitex playground -/
def createPlayground (id : String) (initialCode : String) : Html :=
  Html.tag "div" #[("class", "golitex-playground"), ("id", id)] <|
    Html.seq #[
      Html.tag "div" #[("class", "playground-editor")] <|
        Html.tag "textarea" #[
          ("class", "golitex-input"),
          ("rows", "10"),
          ("style", "width: 100%; font-family: monospace;")
        ] (Html.text true initialCode),
      
      Html.tag "button" #[
        ("class", "render-button"),
        ("onclick", s!"renderGolitex('{id}')")
      ] (Html.text true "Render"),
      
      Html.tag "div" #[("class", "playground-output")] Html.empty
    ]

/-- Create documentation section with collapsible content -/
def createSection (title : String) (content : Array Html) (collapsed : Bool := false) : Html :=
  let sectionId := title.replace " " "-" |>.toLower
  Html.tag "div" #[("class", "doc-section")] <|
    Html.seq #[
      Html.tag "h2" #[
        ("class", "section-header"),
        ("onclick", s!"toggleSection('{sectionId}')")
      ] <| Html.seq #[
        Html.tag "span" #[("class", "toggle-icon")] 
          (Html.text true (if collapsed then "▶" else "▼")),
        Html.text true s!" {title}"
      ],
      Html.tag "div" #[
        ("id", sectionId),
        ("class", "section-content"),
        ("style", if collapsed then "display: none;" else "")
      ] (Html.seq content)
    ]

/-- Generate the advanced documentation -/
def generateAdvancedDocs : Html :=
  createPage "Golitex Advanced Documentation" <|
    Html.seq #[
      Html.tag "h1" #[] (Html.text true "Golitex Advanced Documentation"),
      
      Html.tag "p" #[] (Html.text true "This advanced documentation showcases Verso's capabilities for creating interactive documentation."),
      
      createSection "Interactive Examples" #[
        Html.tag "p" #[] (Html.text true "Try editing the Golitex code below and click 'Render' to see the output:"),
        
        createPlayground "playground1" "\\section{Interactive Demo}

Edit this text and add \\emph{emphasis} or \\textbf{bold} formatting.

Try adding:
- Lists
- Mathematics like $a^2 + b^2 = c^2$
- New sections"
      ],
      
      createSection "Syntax Highlighting" #[
        Html.tag "p" #[] (Html.text true "Golitex code with custom syntax highlighting:"),
        
        highlightGolitex "\\section{Highlighted Code}

This demonstrates \\emph{custom} syntax highlighting for Golitex.

\\subsection{Features}
- Commands like \\textbf{bold} are highlighted
- Section headers stand out
- Nested \\textit{\\textbf{formatting}} is supported"
      ],
      
      createSection "API Documentation" #[
        Html.tag "h3" #[] (Html.text true "Core Functions"),
        
        Html.tag "div" #[("class", "api-item")] <|
          Html.seq #[
            Html.tag "h4" #[] (Html.tag "code" #[] (Html.text true "scan : String → Array Token")),
            Html.tag "p" #[] (Html.text true "Tokenizes a LaTeX source string into an array of tokens."),
            Html.tag "details" #[] <| Html.seq #[
              Html.tag "summary" #[] (Html.text true "Example"),
              highlightGolitex "#eval scan \"\\\\section{Test}\""
            ]
          ],
        
        Html.tag "div" #[("class", "api-item")] <|
          Html.seq #[
            Html.tag "h4" #[] (Html.tag "code" #[] (Html.text true "parseTokens : Array Token → Node")),
            Html.tag "p" #[] (Html.text true "Parses tokens into an abstract syntax tree."),
            Html.tag "details" #[] <| Html.seq #[
              Html.tag "summary" #[] (Html.text true "Example"),
              highlightGolitex "let tokens := scan source\nlet ast := parseTokens tokens"
            ]
          ]
      ] true,
      
      createSection "Advanced Features" #[
        Html.tag "h3" #[] (Html.text true "Custom Commands"),
        Html.tag "p" #[] (Html.text true "Extend Golitex with custom LaTeX commands:"),
        
        highlightGolitex "-- Define a custom command handler
def myCommand (args : List Node) : ElabM (List Block) := do
  -- Custom elaboration logic here
  return []",
        
        Html.tag "h3" #[] (Html.text true "Integration with Lean"),
        Html.tag "p" #[] (Html.text true "Golitex documents can include evaluated Lean code:"),
        
        highlightGolitex "\\begin{lean}
#eval 2 + 2
\\end{lean}"
      ] true
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
            Html.tag "style" #[] (Html.text false advancedStyles),
            Html.tag "script" #[] (Html.text false interactiveScript)
          ],
        Html.tag "body" #[] body
      ]

  advancedStyles := "
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1000px;
      margin: 0 auto;
      padding: 2rem;
      background: #f8f9fa;
    }
    h1, h2, h3, h4 { color: #2c3e50; margin-top: 2rem; }
    h1 { border-bottom: 3px solid #3498db; padding-bottom: 0.5rem; }
    
    .doc-section {
      background: white;
      border-radius: 8px;
      margin: 1rem 0;
      padding: 1.5rem;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .section-header {
      cursor: pointer;
      user-select: none;
    }
    
    .section-header:hover {
      color: #3498db;
    }
    
    .toggle-icon {
      display: inline-block;
      width: 20px;
    }
    
    .golitex-playground {
      border: 1px solid #dee2e6;
      border-radius: 4px;
      overflow: hidden;
      margin: 1rem 0;
    }
    
    .playground-editor {
      background: #f5f5f5;
      padding: 1rem;
    }
    
    .render-button {
      background: #3498db;
      color: white;
      border: none;
      padding: 0.5rem 1rem;
      margin: 0.5rem 0;
      border-radius: 4px;
      cursor: pointer;
    }
    
    .render-button:hover {
      background: #2980b9;
    }
    
    .playground-output {
      padding: 1rem;
      background: white;
      min-height: 100px;
    }
    
    .golitex-highlighted {
      background: #f8f9fa;
      border: 1px solid #dee2e6;
      border-radius: 4px;
      padding: 1rem;
      overflow-x: auto;
    }
    
    .golitex-command {
      color: #0066cc;
      font-weight: bold;
    }
    
    .api-item {
      margin: 1rem 0;
      padding: 1rem;
      background: #f8f9fa;
      border-radius: 4px;
    }
    
    details {
      margin: 0.5rem 0;
    }
    
    summary {
      cursor: pointer;
      color: #3498db;
    }
    
    code {
      background: #e9ecef;
      padding: 0.2rem 0.4rem;
      border-radius: 3px;
      font-family: 'Menlo', 'Monaco', monospace;
    }
  "
  
  interactiveScript := "
    function toggleSection(id) {
      const section = document.getElementById(id);
      const header = section.previousElementSibling;
      const icon = header.querySelector('.toggle-icon');
      
      if (section.style.display === 'none') {
        section.style.display = 'block';
        icon.textContent = '▼';
      } else {
        section.style.display = 'none';
        icon.textContent = '▶';
      }
    }
    
    function renderGolitex(playgroundId) {
      const playground = document.getElementById(playgroundId);
      const input = playground.querySelector('.golitex-input').value;
      const output = playground.querySelector('.playground-output');
      
      // This would normally call the Golitex renderer
      // For now, we'll just show a placeholder
      output.innerHTML = '<p><em>Rendering would happen here in a real implementation.</em></p>' +
                        '<p>Input: <code>' + input.replace(/</g, '&lt;').replace(/>/g, '&gt;') + '</code></p>';
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
  IO.println "Building advanced Verso documentation..."
  
  let doc := generateAdvancedDocs
  let html := htmlToString doc
  
  let outputDir : System.FilePath := "_out/verso-advanced"
  IO.FS.createDirAll outputDir
  
  let outputPath := outputDir / "index.html"
  IO.FS.writeFile outputPath ("<!DOCTYPE html>\n" ++ html)
  
  IO.println s!"Advanced documentation generated at: {outputPath}"
  return 0

end GolitexDocs.VersoAdvanced

-- Module entry point
def main : IO UInt32 := GolitexDocs.VersoAdvanced.main