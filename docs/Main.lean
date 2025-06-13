import Verso
import Verso.Genre.Manual
import Verso.Output
import Docs.Manual
import Golitex

/-!
# Golitex Documentation Builder

This module builds the documentation for Golitex using Verso.
-/

open Verso.Genre.Manual in
def main (args : List String) : IO Unit := do
  let opts : Verso.Output.Options := {
    outDir := "_out/docs"
  }
  
  match args with
  | ["--help"] | ["-h"] | [] =>
    IO.println "Golitex Documentation Builder"
    IO.println ""
    IO.println "Usage: lake exe golitex-docs [OPTIONS]"
    IO.println ""
    IO.println "Options:"
    IO.println "  --help, -h     Show this help message"
    IO.println "  --output DIR   Set output directory (default: _out/docs)"
    IO.println "  --serve        Start a local server after building"
  
  | ["--output", dir] =>
    let opts' := { opts with outDir := dir }
    IO.println s!"Building documentation to {opts'.outDir}..."
    buildManualCmd golitexManual opts'
    IO.println "Documentation built successfully!"
  
  | ["--serve"] =>
    IO.println s!"Building documentation to {opts.outDir}..."
    buildManualCmd golitexManual opts
    IO.println "Starting local server..."
    -- TODO: Add server functionality
    IO.println "(Server functionality not yet implemented)"
    
  | _ =>
    IO.println "Building documentation with default settings..."
    buildManualCmd golitexManual opts
    IO.println s!"Documentation built to {opts.outDir}"

where
  buildManualCmd (manual : Manual) (opts : Verso.Output.Options) : IO Unit := do
    -- For now, we'll just create a simple HTML output
    -- In a full implementation, this would use Verso's rendering pipeline
    IO.println "Note: Full Verso integration is pending. Creating simplified output..."
    
    -- Create output directory
    IO.FS.createDirAll opts.outDir
    
    -- Generate a simple index.html
    let indexHtml := generateIndexHtml manual
    IO.FS.writeFile (opts.outDir / "index.html") indexHtml
    
  generateIndexHtml (manual : Manual) : String :=
    s!"<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\">
    <title>{manual.title}</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 900px;
            margin: 0 auto;
            padding: 2rem;
        }}
        h1, h2, h3 {{ margin-top: 2rem; }}
        code {{
            background: #f4f4f4;
            padding: 0.2em 0.4em;
            border-radius: 3px;
        }}
        pre {{
            background: #f4f4f4;
            padding: 1em;
            border-radius: 5px;
            overflow-x: auto;
        }}
    </style>
</head>
<body>
    <h1>{manual.title}</h1>
    <p>By: {manual.authors.map (·.name) |> String.intercalate ", "}</p>
    {manual.date.map (fun d => s!"<p>Date: {d}</p>") |>.getD ""}
    <p><em>{manual.commitment}</em></p>
    
    <h2>Contents</h2>
    <ul>
        <li><a href=\"#user-guide\">User Guide</a></li>
        <li><a href=\"#api-reference\">API Reference</a></li>
    </ul>
    
    <hr>
    
    <p>This is a placeholder for the full Verso-generated documentation.</p>
    <p>To see the complete documentation, please check the generated files in the output directory.</p>
</body>
</html>"