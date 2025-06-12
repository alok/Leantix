import Lean
import Golitex.IR

/--
`litex!` string interpolator.

Usage:

```
#eval litex! "\\section{Hello} world"
```

For now it just stores the *raw* string inside `Golitex.IR.Document`.
Later phases will parse and elaborate this properly.
-/

open Lean

namespace Golitex

syntax "litex!" strLit : term

macro_rules
  | `(litex! $str) => `(Golitex.IR.Document.mk (raw := $str))

end Golitex
