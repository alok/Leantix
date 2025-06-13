/-!
# Golitex.Frontend.Token

Very small self-contained *token* definition that will be produced by the
`Scanner` module.  For Milestone M1 we only care about the absolute
minimum set of tokens required to recognise a handful of **basic Litex
commands** that appear in tutorial files:

* `\command` – back-slash followed by a sequence of letters (e.g.
  `\section`).
* `{` and `}` braces.
* Plain UTF-8 text (until we hit either `\` or a brace).

More exotic TeX cat-codes (e.g. math mode `$`, `%` comments) are *out of
scope* for the initial prototype and will be added incrementally.
-/

namespace Golitex.Frontend

/--
Enumeration of lexical tokens recognised by the Litex scanner.  Each
token stores the *lexeme* (i.e. the concrete bytes / slice of the
source string) primarily for error reporting.  For braces we keep the
exact glyph as a `Char` solely for future extensibility (e.g. `[` /
`]`).

We *do not* track source locations yet – that will be added once we
wire diagnostics into the elaborator.
-/
inductive Token where
  | cmd     (name : String)   -- ^ a control sequence: `\foo`
  | lbrace  (raw : Char := '{') -- ^ opening brace
  | rbrace  (raw : Char := '}') -- ^ closing brace
  | text    (val : String)    -- ^ a run of plain text
  deriving Repr, Inhabited, BEq

/-- Pretty-prints a token back to something close to its original
lexeme.  Useful while debugging the scanner. -/
def Token.toString : Token → String
  | .cmd n     => s!"\\{n}"
  | .lbrace c  => c.toString
  | .rbrace c  => c.toString
  | .text s    => s

instance : ToString Token where
  toString := Token.toString

end Golitex.Frontend
