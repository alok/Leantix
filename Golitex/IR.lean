namespace Golitex.IR

/--
Document-level intermediate representation (very first stub).
Currently only stores the raw Litex source.  Will be replaced with a
proper tree once the elaboration layer lands.
-/

structure Document where
  raw : String
  deriving Repr, Inhabited

end Golitex.IR
