import Golitex.Lint.Rules
import Leantix
import Golitex

/-! Golitex custom linter executable.

Runs the lint rules defined in `Golitex.Lint.Rules` and exits with code
`1` on any violation, otherwise `0`. -/

open IO

def main : IO UInt32 := do
  let ok ← (Golitex.Lint.runAll).run' {}
  if ok then
    pure 0
  else
    pure 1
