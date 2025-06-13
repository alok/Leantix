import Golitex.IR

/-!
# Golitex HTML Backend

This module provides pure Lean HTML generation from the Golitex IR.
It converts the semantic document representation into valid HTML5.
-/

namespace Golitex.Backend.HTML

open Golitex.IR

/-- HTML element representation -/
inductive Html where
  | text : String → Html
  | element : String → List (String × String) → List Html → Html
  | raw : String → Html
  deriving Repr, Inhabited

/-- Convert HTML to string -/
partial def Html.toString : Html → String
  | .text s => escapeHtml s
  | .element tag attrs children =>
    let attrStr := attrs.map (fun (k, v) => s!"{k}=\"{escapeAttr v}\"") |> String.intercalate " "
    let openTag := if attrStr.isEmpty then s!"<{tag}>" else s!"<{tag} {attrStr}>"
    if children.isEmpty && isVoidElement tag then
      s!"<{tag}{if attrStr.isEmpty then "" else " " ++ attrStr} />"
    else
      let childrenStr := children.map toString |> String.intercalate ""
      s!"{openTag}{childrenStr}</{tag}>"
  | .raw s => s
where
  /-- Escape HTML special characters -/
  escapeHtml (s : String) : String :=
    s.toList.map (fun c =>
      match c with
      | '<' => "&lt;"
      | '>' => "&gt;"
      | '&' => "&amp;"
      | '"' => "&quot;"
      | '\'' => "&#39;"
      | c => c.toString
    ) |> String.join

  /-- Escape attribute values -/
  escapeAttr (s : String) : String :=
    s.toList.map (fun c =>
      match c with
      | '"' => "&quot;"
      | '&' => "&amp;"
      | '<' => "&lt;"
      | '>' => "&gt;"
      | c => c.toString
    ) |> String.join

  /-- Check if element is void (self-closing) -/
  isVoidElement : String → Bool
    | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" 
    | "input" | "link" | "meta" | "param" | "source" | "track" | "wbr" => true
    | _ => false

/-- Smart constructors for common HTML elements -/
def Html.h1 (content : List Html) : Html := Html.element "h1" [] content
def Html.h2 (content : List Html) : Html := Html.element "h2" [] content
def Html.h3 (content : List Html) : Html := Html.element "h3" [] content
def Html.h4 (content : List Html) : Html := Html.element "h4" [] content
def Html.h5 (content : List Html) : Html := Html.element "h5" [] content
def Html.h6 (content : List Html) : Html := Html.element "h6" [] content

def Html.p (content : List Html) : Html := Html.element "p" [] content
def Html.div (attrs : List (String × String) := []) (content : List Html) : Html := 
  Html.element "div" attrs content
def Html.span (attrs : List (String × String) := []) (content : List Html) : Html := 
  Html.element "span" attrs content

def Html.em (content : List Html) : Html := Html.element "em" [] content
def Html.strong (content : List Html) : Html := Html.element "strong" [] content
def Html.code (content : List Html) : Html := Html.element "code" [] content
def Html.i (content : List Html) : Html := Html.element "i" [] content
def Html.b (content : List Html) : Html := Html.element "b" [] content

def Html.ul (items : List Html) : Html := Html.element "ul" [] items
def Html.ol (items : List Html) : Html := Html.element "ol" [] items
def Html.li (content : List Html) : Html := Html.element "li" [] content

def Html.blockquote (content : List Html) : Html := Html.element "blockquote" [] content
def Html.pre (content : List Html) : Html := Html.element "pre" [] content

def Html.article (content : List Html) : Html := Html.element "article" [] content
def Html.section (content : List Html) : Html := Html.element "section" [] content

/-- Convert text style to HTML -/
def renderTextStyle (style : TextStyle) (content : List Html) : Html :=
  match style with
  | .plain => Html.span [] content
  | .emph => Html.em content
  | .bold => Html.strong content
  | .italic => Html.i content
  | .typewriter => Html.code content

/-- Render inline content to HTML -/
def renderInline : Inline → Html
  | .text content style =>
    let textHtml := Html.text content
    if style == .plain then textHtml
    else renderTextStyle style [textHtml]
  | .command name args =>
    -- Render unknown commands as span with data attribute
    Html.span [("data-latex-command", name), ("class", "latex-command")] 
      (Html.text s!"\\{name}" :: args.map renderInline)
  | .math content display =>
    -- Render math using appropriate class
    if display then
      Html.div [("class", "math display-math")] [Html.text s!"$${content}$$"]
    else
      Html.span [("class", "math inline-math")] [Html.text s!"${content}$"]
  | .space => Html.text " "
  | .lineBreak => Html.element "br" [] []

/-- Render a list of inlines -/
def renderInlines (inlines : List Inline) : List Html :=
  inlines.map renderInline

/-- Render block content to HTML -/
partial def renderBlock : Block → Html
  | .paragraph inlines =>
    Html.p (renderInlines inlines)
  
  | .section level title _ =>
    let headerTag := match level with
      | 1 => Html.h1
      | 2 => Html.h2
      | 3 => Html.h3
      | 4 => Html.h4
      | 5 => Html.h5
      | _ => Html.h6
    headerTag (renderInlines title)
  
  | .list ordered items =>
    let renderItem (blocks : List Block) : Html :=
      Html.li (blocks.map renderBlock)
    let listItems := items.map renderItem
    if ordered then Html.ol listItems else Html.ul listItems
  
  | .quote blocks =>
    Html.blockquote (blocks.map renderBlock)
  
  | .verbatim text =>
    Html.pre [Html.code [Html.text text]]
  
  | .environment name _ blocks =>
    -- Render generic environment as div with class
    Html.div [("class", s!"environment environment-{name}")] 
      (blocks.map renderBlock)
  
  | .raw format content =>
    -- Only include raw HTML content, ignore other formats
    if format == "html" then Html.raw content
    else Html.div [("class", s!"raw-{format}")] [Html.text content]

/-- Configuration options for HTML rendering -/
structure RenderOptions where
  /-- Include default CSS styles -/
  includeDefaultStyles : Bool := true
  /-- Document title -/
  title : String := "Golitex Document"
  /-- Additional CSS to include -/
  customCss : String := ""
  /-- Additional head elements -/
  additionalHead : List Html := []
  deriving Repr

/-- Default CSS styles for Golitex documents -/
def defaultStyles : String := "
body {
  font-family: 'Times New Roman', Times, serif;
  line-height: 1.6;
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
  color: #333;
}

h1, h2, h3, h4, h5, h6 {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}

h1 { font-size: 2.5em; }
h2 { font-size: 2em; }
h3 { font-size: 1.5em; }
h4 { font-size: 1.2em; }
h5 { font-size: 1.1em; }
h6 { font-size: 1em; }

p {
  margin: 1em 0;
  text-align: justify;
}

code {
  background-color: #f4f4f4;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-family: 'Courier New', Courier, monospace;
}

pre {
  background-color: #f4f4f4;
  padding: 1em;
  border-radius: 5px;
  overflow-x: auto;
}

pre code {
  background-color: transparent;
  padding: 0;
}

blockquote {
  border-left: 4px solid #ddd;
  padding-left: 1em;
  margin-left: 0;
  color: #666;
}

ul, ol {
  margin: 1em 0;
  padding-left: 2em;
}

.environment {
  margin: 1em 0;
  padding: 1em;
  border: 1px solid #ddd;
  border-radius: 5px;
}

.latex-command {
  color: #800;
  font-family: 'Courier New', Courier, monospace;
}

.math {
  font-style: italic;
}

.display-math {
  display: block;
  text-align: center;
  margin: 1em 0;
}
"

/-- Render a complete HTML document -/
def renderDocument (doc : Document) (options : RenderOptions := {}) : String :=
  let head := Html.element "head" [] ([
    Html.element "meta" [("charset", "UTF-8")] [],
    Html.element "meta" [
      ("name", "viewport"),
      ("content", "width=device-width, initial-scale=1.0")
    ] [],
    Html.element "title" [] [Html.text options.title]
  ] ++ 
  (if options.includeDefaultStyles then
    [Html.element "style" [] [Html.raw defaultStyles]]
  else []) ++
  (if options.customCss.isEmpty then []
   else [Html.element "style" [] [Html.raw options.customCss]]) ++
  options.additionalHead)
  
  let body := Html.element "body" [] [
    Html.article (doc.content.map renderBlock)
  ]
  
  let html := Html.element "html" [("lang", "en")] [head, body]
  "<!DOCTYPE html>\n" ++ html.toString

/-- Render document to HTML file -/
def renderToFile (doc : Document) (path : System.FilePath) 
    (options : RenderOptions := {}) : IO Unit := do
  let html := renderDocument doc options
  IO.FS.writeFile path html

end Golitex.Backend.HTML