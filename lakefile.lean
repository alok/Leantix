import Lake
open Lake DSL

package leantix where
  version := v!"0.1.0"

-- Verso dependency temporarily disabled due to toolchain conflicts
-- require verso from git
--   "https://github.com/leanprover/verso.git"

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

-- Documentation executable
lean_exe «golitex-docs» where
  root := `Docs.Simple