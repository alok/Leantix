import Verso
import Verso.Genre.Manual
import Verso.Output
import Verso.Output.Html
import Verso.Output.TeX
import Docs.GolitexManual

open Verso.Genre.Manual
open Verso.Output

def buildHtml : IO Unit := do
  let config : Html.Config := {
    depthToSplit := 2
    extraCss := [
      (Slug.ofString "golitex", golitexStyles)
    ]
    extraJs := []
    mathjax := true
    renderMode := .multiPage
  }
  
  let outputDir : System.FilePath := "_out/verso-docs"
  
  -- Clear and create output directory
  if (← outputDir.pathExists) then
    IO.FS.removeDirAll outputDir
  IO.FS.createDirAll outputDir
  
  Html.generate golitexManual outputDir config
  IO.println s!"HTML documentation generated at: {outputDir}"

where
  golitexStyles : String := "
    /* Golitex-specific styles */
    .golitex-example {
      background: #f8f9fa;
      border: 1px solid #dee2e6;
      border-radius: 0.25rem;
      padding: 1rem;
      margin: 1rem 0;
    }
    
    .golitex-command {
      font-family: monospace;
      background: #e9ecef;
      padding: 0.125rem 0.25rem;
      border-radius: 0.125rem;
    }
  "

def buildTeX : IO Unit := do
  let config : TeX.Config := {
    pdflatex := "pdflatex"
  }
  
  let outputDir : System.FilePath := "_out/verso-tex"
  
  -- Clear and create output directory  
  if (← outputDir.pathExists) then
    IO.FS.removeDirAll outputDir
  IO.FS.createDirAll outputDir
  
  TeX.generate golitexManual outputDir config
  IO.println s!"TeX documentation generated at: {outputDir}"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["html"] => buildHtml; return 0
  | ["tex"] => buildTeX; return 0
  | ["all"] => buildHtml; buildTeX; return 0
  | _ =>
    IO.println "Golitex Documentation Builder (Verso)"
    IO.println ""
    IO.println "Usage: lake exe golitex-verso-docs [FORMAT]"
    IO.println ""
    IO.println "Formats:"
    IO.println "  html    Build HTML documentation"
    IO.println "  tex     Build LaTeX/PDF documentation"
    IO.println "  all     Build all formats"
    return 1