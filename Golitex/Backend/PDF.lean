import Golitex.IR
import Golitex.Backend.LaTeX

/-!
# Golitex PDF Backend

This module provides PDF generation from the Golitex IR by converting
to LaTeX and calling an external TeX engine (lualatex, pdflatex, or tectonic).
-/

namespace Golitex.Backend.PDF

open Golitex.IR
open System

/-- Available TeX engines for PDF generation -/
inductive TeXEngine where
  | pdflatex
  | lualatex
  | xelatex
  | tectonic
  deriving Repr, Inhabited, BEq

/-- Convert TeX engine to command name -/
def TeXEngine.toCommand : TeXEngine → String
  | .pdflatex => "pdflatex"
  | .lualatex => "lualatex"
  | .xelatex => "xelatex"
  | .tectonic => "tectonic"

/-- PDF rendering options -/
structure PDFOptions where
  /-- TeX engine to use -/
  engine : TeXEngine := .pdflatex
  /-- Document class -/
  documentClass : String := "article"
  /-- Document class options -/
  classOptions : List String := []
  /-- Additional packages to include -/
  packages : List String := []
  /-- Custom preamble -/
  preamble : String := ""
  /-- Working directory for compilation -/
  workDir : Option FilePath := none
  /-- Keep intermediate files -/
  keepIntermediateFiles : Bool := false
  /-- Number of compilation passes (for references, etc.) -/
  passes : Nat := 2
  /-- Timeout in milliseconds -/
  timeout : UInt32 := 30000
  deriving Repr

/-- Result of PDF compilation -/
inductive PDFResult where
  | success (pdfPath : FilePath) (log : String)
  | error (message : String) (log : String)
  deriving Repr

/-- Check if a TeX engine is available -/
def checkTeXEngine (engine : TeXEngine) : IO Bool := do
  let proc ← IO.Process.spawn {
    cmd := engine.toCommand
    args := #["--version"]
    stdout := .piped
    stderr := .piped
  }
  let exitCode ← proc.wait
  return exitCode == 0

/-- Find an available TeX engine -/
def findAvailableEngine : IO (Option TeXEngine) := do
  for engine in [TeXEngine.tectonic, .lualatex, .pdflatex, .xelatex] do
    if ← checkTeXEngine engine then
      return some engine
  return none

/-- Create a temporary directory for compilation -/
def createTempDir : IO FilePath := do
  let tempBase ← (do
    if let some tmp ← IO.getEnv "TMPDIR" then return tmp
    else if let some tmp ← IO.getEnv "TEMP" then return tmp
    else return "/tmp")
  let timestamp ← IO.monoMsNow
  let dirName := s!"golitex-{timestamp}"
  let tempDir : FilePath := tempBase / dirName
  IO.FS.createDir tempDir
  return tempDir

/-- Compile LaTeX to PDF using external engine -/
def compileLaTeX (texFile : FilePath) (options : PDFOptions) : IO PDFResult := do
  let workDir ← match options.workDir with
    | some dir => pure dir
    | none => pure texFile.parent.get!
  
  -- Accumulate logs across passes
  let rec runPasses (pass : Nat) (accLog : String) : IO PDFResult := do
    if pass > options.passes then
      -- All passes completed, check if PDF was created
      let pdfFile := texFile.withExtension "pdf"
      if ← pdfFile.pathExists then
        return .success pdfFile accLog
      else
        return .error "PDF file was not created" accLog
    else
      let proc ← IO.Process.spawn {
        cmd := options.engine.toCommand
        args := match options.engine with
          | .tectonic => #[texFile.toString]
          | _ => #[
              "-interaction=nonstopmode",
              "-output-directory", workDir.toString,
              texFile.toString
            ]
        cwd := some workDir
        stdout := .piped
        stderr := .piped
      }
      
      let stdout ← proc.stdout.readToEnd
      let stderr ← proc.stderr.readToEnd  
      let exitCode ← proc.wait
      
      let passLog := s!"\n--- Pass {pass} ---\n" ++ stdout ++
        (if stderr.isEmpty then "" else "\nErrors:\n" ++ stderr)
      let newLog := accLog ++ passLog
      
      if exitCode != 0 then
        return .error s!"TeX compilation failed (exit code: {exitCode})" newLog
      else
        runPasses (pass + 1) newLog
  termination_by options.passes + 1 - pass
  
  runPasses 1 ""

/-- Render document to PDF -/
def renderDocument (doc : Document) (options : PDFOptions := {}) : IO PDFResult := do
  -- Check if engine is available
  let engine ← match options.engine with
    | e => 
      if ← checkTeXEngine e then pure e
      else match ← findAvailableEngine with
        | some availableEngine => pure availableEngine
        | none => return .error "No TeX engine found. Please install pdflatex, lualatex, xelatex, or tectonic." ""
  
  -- Create working directory
  let workDir ← match options.workDir with
    | some dir => pure dir
    | none => createTempDir
  
  -- Generate LaTeX content
  let latexContent := LaTeX.renderDocument doc {
    documentClass := options.documentClass
    classOptions := options.classOptions
    packages := options.packages
    preamble := options.preamble
  }
  
  -- Write LaTeX file
  let texFile := workDir / "document.tex"
  IO.FS.writeFile texFile latexContent
  
  -- Compile to PDF
  let result ← compileLaTeX texFile { options with engine := engine, workDir := some workDir }
  
  -- Clean up if requested
  if !options.keepIntermediateFiles && options.workDir.isNone then
    -- Remove temporary directory
    try
      IO.FS.removeDirAll workDir
    catch _ =>
      -- Ignore cleanup errors
      pure ()
  
  return result

/-- Render document to PDF file at specific path -/
def renderToFile (doc : Document) (outputPath : FilePath) 
    (options : PDFOptions := {}) : IO Unit := do
  match ← renderDocument doc options with
  | .success pdfPath log =>
    -- Copy PDF to desired location
    if pdfPath != outputPath then
      IO.FS.writeBinFile outputPath (← IO.FS.readBinFile pdfPath)
    if options.keepIntermediateFiles then
      IO.println s!"PDF generated successfully. Log:\n{log}"
  | .error msg log =>
    throw <| IO.userError s!"PDF generation failed: {msg}\nLog:\n{log}"

end Golitex.Backend.PDF