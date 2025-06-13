import Lean
import Golitex.Frontend.Scanner
import Golitex.Frontend.AST
import Golitex.IR

namespace Golitex

open Lean
open Golitex.Frontend.Scanner
open Golitex.Frontend.AST

/-- Enhanced Document IR that includes parsed AST -/
structure ParsedDocument extends IR.Document where
  ast : Node
  deriving Repr, Inhabited

/--
`litex!` string interpolator.

Usage:

```
#eval litex! "\\section{Hello} world"
```

This macro now parses the Litex source into an AST and stores both
the raw source and the parsed structure in the IR.Document.
-/
syntax "litex!" str : term

macro_rules
  | `(litex! $str:str) => do
    -- At macro expansion time, we can't easily call our parser
    -- So we'll create a helper function that does the parsing
    `(
      let raw := $str
      let tokens := Golitex.Frontend.Scanner.scan raw
      let ast := Golitex.Frontend.AST.parseTokens tokens
      ParsedDocument.mk ⟨{}, [], raw⟩ ast
    )

/-- Helper function to create a parsed document from a string -/
def parseLitex (source : String) : ParsedDocument :=
  let tokens := scan source
  let ast := parseTokens tokens
  ParsedDocument.mk ⟨{}, [], source⟩ ast

-- Example usage:
-- #eval parseLitex "\\section{Introduction} This is some text."

end Golitex