-- Golitex - A LaTeX-like DSL for Lean 4
-- This is the main entry point for the Golitex library.

import Golitex.Frontend.Token
import Golitex.Frontend.Scanner
import Golitex.Frontend.AST
import Golitex.IR
import Golitex.Syntax
import Golitex.Elab
import Golitex.Backend.HTML
import Golitex.Backend.LaTeX
import Golitex.Backend.PDF

namespace Golitex

abbrev Version : String := "0.0.1-dev"

end Golitex