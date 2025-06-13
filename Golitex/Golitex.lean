/-!
# Golitex - A LaTeX-like DSL for Lean 4

This is the main entry point for the Golitex library.
-/

import Golitex.Frontend.Token
import Golitex.Frontend.Scanner  
import Golitex.Frontend.AST
import Golitex.IR
import Golitex.Syntax
import Golitex.Elab
import Golitex.Backend.HTML

namespace Golitex

abbrev Version : String := "0.0.1-dev"

-- Re-export key types and functions
export Frontend.Token (Token)
export Frontend.Scanner (scan)
export Frontend.AST (Node parseTokens)
export IR (Document Block Inline)
export Syntax (litex)
export Elab (elaborate)
export Backend.HTML (renderDocument renderToFile)

end Golitex