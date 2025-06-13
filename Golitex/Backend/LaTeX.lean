import Golitex.IR

/-!
# Golitex LaTeX Backend

This module provides LaTeX generation from the Golitex IR.
It converts the semantic document representation into LaTeX source code.
-/

namespace Golitex.Backend.LaTeX

open Golitex.IR

/-- LaTeX rendering options -/
structure LaTeXOptions where
  /-- Document class -/
  documentClass : String := "article"
  /-- Document class options -/
  classOptions : List String := []
  /-- Additional packages to include -/
  packages : List String := []
  /-- Custom preamble content -/
  preamble : String := ""
  /-- Indent size for generated LaTeX -/
  indentSize : Nat := 2
  deriving Repr

/-- Escape special LaTeX characters -/
def escapeLaTeX (s : String) : String :=
  s.toList.map (fun c =>
    match c with
    | '\\' => "\\textbackslash{}"
    | '{' => "\\{"
    | '}' => "\\}"
    | '$' => "\\$"
    | '&' => "\\&"
    | '#' => "\\#"
    | '^' => "\\^{}"
    | '_' => "\\_"
    | '~' => "\\~{}"
    | '%' => "\\%"
    | c => c.toString
  ) |> String.join

/-- Convert text style to LaTeX command -/
def textStyleToLaTeX : TextStyle → String → String
  | .plain => id
  | .emph => fun s => s!"\\emph\{{s}}"
  | .bold => fun s => s!"\\textbf\{{s}}"
  | .italic => fun s => s!"\\textit\{{s}}"
  | .typewriter => fun s => s!"\\texttt\{{s}}"

/-- Render inline content to LaTeX -/
def renderInline : Inline → String
  | .text content style =>
    let escaped := escapeLaTeX content
    textStyleToLaTeX style escaped
  | .command name args =>
    let argStr := args.map renderInline |> String.join
    s!"\\{name}{argStr}"
  | .math content false =>
    s!"${content}$"
  | .math content true =>
    s!"$${content}$$"
  | .space => " "
  | .lineBreak => "\\\\\n"

/-- Render a list of inlines -/
def renderInlines (inlines : List Inline) : String :=
  inlines.map renderInline |> String.join

/-- Get section command for level -/
def sectionCommand (level : Nat) : String :=
  match level with
  | 1 => "section"
  | 2 => "subsection"
  | 3 => "subsubsection"
  | 4 => "paragraph"
  | 5 => "subparagraph"
  | _ => "subparagraph"

/-- Render block content to LaTeX with indentation -/
partial def renderBlock (indent : Nat) : Block → String
  | .paragraph inlines =>
    let content := renderInlines inlines
    if content.isEmpty then "" else content ++ "\n"
  
  | .section level title label =>
    let cmd := sectionCommand level
    let titleStr := renderInlines title
    let labelStr := match label with
      | some l => s!"\\label\{{l}}"
      | none => ""
    s!"\\{cmd}\{{titleStr}}{labelStr}\n"
  
  | .list false items =>
    let itemsStr := items.map (renderListItem indent) |> String.join
    s!"\\begin\{itemize}\n{itemsStr}\\end\{itemize}\n"
  
  | .list true items =>
    let itemsStr := items.map (renderListItem indent) |> String.join
    s!"\\begin\{enumerate}\n{itemsStr}\\end\{enumerate}\n"
  
  | .quote blocks =>
    let content := blocks.map (renderBlock (indent + 2)) |> String.join
    s!"\\begin\{quote}\n{content}\\end\{quote}\n"
  
  | .verbatim text =>
    s!"\\begin\{verbatim}\n{text}\n\\end\{verbatim}\n"
  
  | .environment name args blocks =>
    let argStr := if args.isEmpty then "" else 
      args.map (fun a => s!"\{{a}}") |> String.join
    let content := blocks.map (renderBlock (indent + 2)) |> String.join
    s!"\\begin\{{name}}{argStr}\n{content}\\end\{{name}}\n"
  
  | .raw "latex" content =>
    content ++ "\n"
  
  | .raw _ _ =>
    -- Ignore non-LaTeX raw content
    ""

where
  renderListItem (indent : Nat) (blocks : List Block) : String :=
    let spaces := String.mk (List.replicate indent ' ')
    let content := blocks.map (renderBlock (indent + 2)) |> String.join
    s!"{spaces}\\item {content}"

/-- Render document metadata as LaTeX comments -/
def renderMetadata (metadata : Metadata) : String :=
  -- For now, just return empty since Metadata is opaque
  ""

/-- Check if block contains math -/
private partial def hasBlockMath : Block → Bool
  | .paragraph inlines => inlines.any hasInlineMath
  | .environment _ _ blocks => blocks.any hasBlockMath
  | .list _ items => items.any (·.any hasBlockMath)
  | .quote blocks => blocks.any hasBlockMath
  | _ => false
where
  hasInlineMath : Inline → Bool
    | .math _ _ => true
    | _ => false

/-- Collect environment names -/
private def collectEnvironments : List Block → List String
  | [] => []
  | .environment name _ _ :: rest => name :: collectEnvironments rest
  | _ :: rest => collectEnvironments rest

/-- Generate default preamble based on document content -/
def generateDefaultPreamble (doc : Document) : List String :=
  let basePackages := ["inputenc", "fontenc", "lmodern"]
  
  -- Check if we need math packages
  let mathPackages := if doc.content.any hasBlockMath then
    ["amsmath", "amssymb", "amsthm"]
  else []
  
  -- Check for special environments
  let environments := collectEnvironments doc.content
  let envPackages := if environments.contains "theorem" || environments.contains "lemma" || 
     environments.contains "proof" || environments.contains "definition" then
    ["amsthm"]
  else []
  
  (basePackages ++ mathPackages ++ envPackages).eraseDups

/-- Render complete LaTeX document -/
def renderDocument (doc : Document) (options : LaTeXOptions := {}) : String :=
  -- Document class
  let classOptsStr := if options.classOptions.isEmpty then ""
    else "[" ++ String.intercalate "," options.classOptions ++ "]"
  let documentClassLine := s!"\\documentclass{classOptsStr}\{{options.documentClass}}\n"
  
  -- Packages
  let defaultPackages := generateDefaultPreamble doc
  let allPackages := (defaultPackages ++ options.packages).eraseDups
  let packageLines := allPackages.map (fun pkg =>
    match pkg with
    | "inputenc" => "\\usepackage[utf8]{inputenc}"
    | "fontenc" => "\\usepackage[T1]{fontenc}"
    | pkg => s!"\\usepackage\{{pkg}}"
  ) |> String.intercalate "\n"
  
  -- Metadata
  let metadataStr := renderMetadata doc.metadata
  
  -- Content
  let contentStr := doc.content.map (renderBlock 0) |> String.join
  
  -- Combine everything
  s!"{metadataStr}{documentClassLine}\n{packageLines}\n\n{options.preamble}\n\\begin\{document}\n\n{contentStr}\n\\end\{document}"

/-- Render document to LaTeX file -/
def renderToFile (doc : Document) (path : System.FilePath) 
    (options : LaTeXOptions := {}) : IO Unit := do
  let latex := renderDocument doc options
  IO.FS.writeFile path latex

end Golitex.Backend.LaTeX