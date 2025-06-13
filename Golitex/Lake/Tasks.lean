import Lake
import Golitex

/-!
# Lake Tasks for Golitex

This module provides Lake build tasks for compiling Golitex documents
to various output formats (HTML, PDF, LaTeX).
-/

namespace Golitex.Lake

open Lake DSL

/-- Configuration for a Golitex document -/
structure DocConfig where
  /-- Source file path (relative to package root) -/
  src : FilePath
  /-- Output directory (relative to build directory) -/
  outDir : FilePath := "docs"
  /-- Document name (without extension) -/
  name : String
  /-- Output formats to generate -/
  formats : Array String := #["html", "pdf"]
  /-- PDF rendering options -/
  pdfOptions : Option Golitex.Backend.PDF.PDFOptions := none
  /-- HTML rendering options -/
  htmlOptions : Option Golitex.Backend.HTML.RenderOptions := none
  deriving Repr

/-- Build a Golitex document to HTML -/
def buildHtml (pkg : Package) (doc : DocConfig) : IndexBuildM (BuildJob FilePath) := do
  let srcPath := pkg.dir / doc.src
  let htmlPath := pkg.buildDir / doc.outDir / s!"{doc.name}.html"
  
  buildFileAfterDep htmlPath (← inputFile srcPath) fun srcFile => do
    logInfo s!"Building HTML: {doc.name}"
    
    -- Read and parse the source file
    let content ← IO.FS.readFile srcFile.path
    let parsed := Golitex.parseLitex content
    let (irDoc, elabCtx) := Golitex.Elab.elaborate parsed.ast
    
    -- Check for errors
    if !elabCtx.errors.isEmpty then
      logWarning s!"Elaboration warnings for {doc.name}:"
      for err in elabCtx.errors do
        logWarning s!"  {err}"
    
    -- Render to HTML
    let options := doc.htmlOptions.getD {
      title := doc.name
      includeDefaultStyles := true
    }
    Golitex.Backend.HTML.renderToFile irDoc htmlPath options
    
    return (htmlPath, Task.pure BuildTrace.nil)

/-- Build a Golitex document to PDF -/
def buildPdf (pkg : Package) (doc : DocConfig) : IndexBuildM (BuildJob FilePath) := do
  let srcPath := pkg.dir / doc.src
  let pdfPath := pkg.buildDir / doc.outDir / s!"{doc.name}.pdf"
  
  buildFileAfterDep pdfPath (← inputFile srcPath) fun srcFile => do
    logInfo s!"Building PDF: {doc.name}"
    
    -- Read and parse the source file
    let content ← IO.FS.readFile srcFile.path
    let parsed := Golitex.parseLitex content
    let (irDoc, elabCtx) := Golitex.Elab.elaborate parsed.ast
    
    -- Check for errors
    if !elabCtx.errors.isEmpty then
      logWarning s!"Elaboration warnings for {doc.name}:"
      for err in elabCtx.errors do
        logWarning s!"  {err}"
    
    -- Render to PDF
    let options := doc.pdfOptions.getD {}
    Golitex.Backend.PDF.renderToFile irDoc pdfPath options
    
    return (pdfPath, Task.pure BuildTrace.nil)

/-- Build a Golitex document to LaTeX -/
def buildLaTeX (pkg : Package) (doc : DocConfig) : IndexBuildM (BuildJob FilePath) := do
  let srcPath := pkg.dir / doc.src
  let texPath := pkg.buildDir / doc.outDir / s!"{doc.name}.tex"
  
  buildFileAfterDep texPath (← inputFile srcPath) fun srcFile => do
    logInfo s!"Building LaTeX: {doc.name}"
    
    -- Read and parse the source file
    let content ← IO.FS.readFile srcFile.path
    let parsed := Golitex.parseLitex content
    let (irDoc, elabCtx) := Golitex.Elab.elaborate parsed.ast
    
    -- Check for errors
    if !elabCtx.errors.isEmpty then
      logWarning s!"Elaboration warnings for {doc.name}:"
      for err in elabCtx.errors do
        logWarning s!"  {err}"
    
    -- Render to LaTeX
    Golitex.Backend.LaTeX.renderToFile irDoc texPath
    
    return (texPath, Task.pure BuildTrace.nil)

/-- Build all formats for a document -/
def buildDoc (pkg : Package) (doc : DocConfig) : IndexBuildM (BuildJob (Array FilePath)) := do
  let jobs ← doc.formats.mapM fun format => do
    match format with
    | "html" => buildHtml pkg doc
    | "pdf" => buildPdf pkg doc
    | "latex" | "tex" => buildLaTeX pkg doc
    | _ => error s!"Unknown format: {format}"
  
  buildJobsArray jobs

/-- Define a Golitex document target -/
def golitexDoc (pkg : Package) (doc : DocConfig) : IndexBuildM Unit := do
  let target ← buildDoc pkg doc
  pkg.addTarget (pkg.target doc.name target)

/-- Helper to define multiple document targets -/
def golitexDocs (pkg : Package) (docs : Array DocConfig) : IndexBuildM Unit := do
  for doc in docs do
    golitexDoc pkg doc

end Golitex.Lake