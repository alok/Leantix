import Verso
import Verso.Genre.Manual
import Docs.UserGuide
import Docs.APIReference

/-!
# Golitex Documentation Manual

This module defines the complete Golitex documentation manual using Verso.
-/

open Verso.Genre.Manual

def golitexManual : Manual where
  title := "Golitex Documentation"
  authors := #[{name := "Golitex Contributors"}]
  date := some "2025"
  commitment := "This documentation is a work in progress and may be incomplete or contain errors."
  mainMatter := #[userGuide, apiReference]
  backMatter := #[]