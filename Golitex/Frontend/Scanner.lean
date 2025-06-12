/-!
# Golitex.Frontend.Scanner

Prototype lexer that converts a UTF-8 `String` containing Litex source
into a list of `Token`s defined in `Golitex.Frontend.Token`.

The implementation is *deliberately simplistic* – it is sufficient for
Milestone M1 (basic structural commands) and ignores hard features such
as cat-codes, comments, control symbols, verbatim blocks, etc.  Those
will be added as the grammatical front-end matures.

Algorithm outline:

* Traverse the input character by character.
* Whenever a back-slash `\` is encountered:
  * Consume subsequent ASCII letters (`isAlpha`).
  * Emit `Token.cmd` for the accumulated name (empty name becomes
    *error* – but here we fall back to single `text` to stay total).
* Braces `{` / `}` become individual tokens.
* All other characters are accumulated into a `Token.text` chunk until
  we reach one of the above *sentinel* characters.

Edge cases such as an EOF immediately after `\` are treated as plain
text for now.  This keeps the function total without throwing e.g.
`Except`.  Proper error handling will be introduced in the elaboration
layer, where tokens are mapped to source positions.
-/

import Golitex.Frontend.Token

open Golitex.Frontend

namespace Golitex.Frontend.Scanner

/-
Auxiliary predicate: Lean’s `Char.isAlpha` covers *Unicode* alphabetic
code-points which is more than we need, but that is acceptable for the
prototype.
-/

def isCommandChar (c : Char) : Bool := c.isAlpha

/-- Consumes a maximal letter sequence starting at index `i` (inclusive)
and returns the *exclusive* end index together with the extracted
substring.  Pre-condition: `s[i]` is alphabetic. -/
private def takeWhileAlpha (s : String) (i : Nat) : Nat × String :=
  let rec loop (j : Nat) : Nat :=
    if h : j < s.length then
      let c := s.get j
      if isCommandChar c then
        loop (j + 1)
      else j
    else j
  let j := loop i
  (j, s.extract i j)

/--
`scan src` tokenises `src` and returns an array of tokens.  The order of
the array is the order of appearance in the source.
-/
def scan (src : String) : Array Token :=
  let rec go (i : Nat) (acc : Array Token) : Array Token :=
    if hEnd : i < src.length then
      let c := src.get i
      match c with
      | '\\' =>
          let nextIdx := i + 1
          if nextIdx < src.length then
            let c2 := src.get nextIdx
            if isCommandChar c2 then
              let (j, name) := takeWhileAlpha src nextIdx
              go j (acc.push (.cmd name))
            else
              -- Control symbol (e.g. \%) – treat as text for now.
              let acc := acc.push (.text "\\")
              go nextIdx acc
          else
            -- Lone backslash at EOF.
            acc.push (.text "\\")
      | '{' => go (i + 1) (acc.push (.lbrace '{'))
      | '}' => go (i + 1) (acc.push (.rbrace '}'))
      | _   =>
          -- Accumulate text until we hit sentinel char.
          let rec collect (j : Nat) : Nat :=
            if h : j < src.length then
              let cj := src.get j
              if cj == '\\' || cj == '{' || cj == '}' then j else collect (j + 1)
            else j
          let j := collect i
          let chunk := src.extract i j
          go j (acc.push (.text chunk))
    else acc
  go 0 #[]

/-- Pretty debug printer – joins tokens with `·` so visual boundaries are
clearer. -/
def debugTokens (src : String) : String :=
  String.intercalate " · " <| (scan src).toList.map toString

-- Quick unit tests (very ad-hoc until we bring in `std` test framework).
#eval debugTokens "\\section{Hello} world"

end Golitex.Frontend.Scanner
