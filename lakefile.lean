import Lake
open Lake DSL

package leantix where
  version := v!"0.1.0"

require verso from git
  "https://github.com/leanprover/verso.git" @ "main"

@[default_target]
lean_lib Leantix

lean_exe leantix where
  root := `Main

lean_lib Golitex

lean_lib Tests

lean_exe «golitex-lint» where
  root := `Scripts.GolitexLintMain

lean_exe test where
  root := `Tests.Main

-- Documentation executables
lean_exe «golitex-docs» where
  root := `Docs.Simple

lean_exe «golitex-verso-docs» where
  root := `Docs.VersoCompat
  supportInterpreter := true

lean_exe «golitex-verso-full» where
  root := `Docs.VersoIntegration
  supportInterpreter := true