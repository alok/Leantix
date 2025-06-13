import Golitex.Frontend.Token

/-!
# Golitex.Frontend.AST

Abstract Syntax Tree definitions for the Golitex language. This module
defines the node types that will be produced by parsing Litex/LaTeX-style
commands.

For Milestone M1, we focus on basic structural commands:
- Control sequences (commands)
- Braced groups
- Text content
- Basic document structure (sections, paragraphs)

This corresponds to the Go `ast` package in the original golitex implementation,
translated to Lean's inductive types.
-/

namespace Golitex.Frontend.AST

/-- Source position information for AST nodes -/
structure SourcePos where
  line   : Nat
  column : Nat
  deriving Repr, Inhabited, BEq

/-- 
Base AST node interface. In the Go implementation this was an interface,
here we use an inductive type with different constructors.
-/
inductive Node where
  /-- A control sequence like `\section` with optional arguments -/
  | command (name : String) (args : List Node) (pos : Option SourcePos := none)
  /-- A braced group `{...}` containing child nodes -/
  | group (children : List Node) (pos : Option SourcePos := none)
  /-- Plain text content -/
  | text (content : String) (pos : Option SourcePos := none)
  /-- A comment (for future use when we parse % comments) -/
  | comment (content : String) (pos : Option SourcePos := none)
  /-- Environment begin/end pair -/
  | environment (name : String) (args : List Node) (body : List Node) (pos : Option SourcePos := none)
  /-- Document root node -/
  | document (children : List Node) (pos : Option SourcePos := none)
  deriving Repr, Inhabited

/-- Get the source position of a node if available -/
def Node.getPos : Node → Option SourcePos
  | .command _ _ pos => pos
  | .group _ pos => pos
  | .text _ pos => pos
  | .comment _ pos => pos
  | .environment _ _ _ pos => pos
  | .document _ pos => pos

/-- Pretty printer for AST nodes (for debugging) -/
partial def Node.toString : Node → String
  | .command name args _ => 
      let argStr := if args.isEmpty then "" else " " ++ (args.map toString |> String.intercalate " ")
      "\\" ++ name ++ argStr
  | .group children _ => 
      let childStr := children.map toString |> String.intercalate " "
      "{" ++ childStr ++ "}"
  | .text content _ => content
  | .comment content _ => "%" ++ content
  | .environment name args body _ =>
      let argStr := if args.isEmpty then "" else args.map toString |> String.intercalate " "
      let bodyStr := body.map toString |> String.intercalate "\n"
      "\\begin{" ++ name ++ "}" ++ argStr ++ "\n" ++ bodyStr ++ "\n\\end{" ++ name ++ "}"
  | .document children _ =>
      children.map toString |> String.intercalate "\n"

instance : ToString Node where
  toString := Node.toString

/-- 
Build an AST from a token stream. This is a simplified parser for M1.
In the full implementation, this would be replaced by Lean's syntax/macro system.
-/
partial def parseTokens (tokens : Array Token) : Node :=
  -- Simple single-pass parser implementation
  let rec parse (i : Nat) (acc : List Node) (inGroup : Bool) : Nat × List Node :=
    if h : i < tokens.size then
      match tokens[i] with
      | .cmd name =>
          -- Collect following braced groups as arguments
          let rec collectArgs (j : Nat) (args : List Node) : Nat × List Node :=
            if h2 : j < tokens.size then
              match tokens[j] with
              | .lbrace _ =>
                  let (k, group) := parse (j + 1) [] true
                  collectArgs k (args ++ [Node.group group])
              | _ => (j, args)
            else (j, args)
          let (j, args) := collectArgs (i + 1) []
          parse j (acc ++ [Node.command name args]) inGroup
      | .lbrace _ =>
          let (j, children) := parse (i + 1) [] true
          parse j (acc ++ [Node.group children]) inGroup
      | .rbrace _ =>
          if inGroup then
            (i + 1, acc)
          else
            parse (i + 1) (acc ++ [Node.text "}"]) inGroup
      | .text content =>
          parse (i + 1) (acc ++ [Node.text content]) inGroup
    else
      (i, acc)
  
  let (_, children) := parse 0 [] false
  Node.document children

/-- Check if a node represents a specific command -/
def Node.isCommand (node : Node) (name : String) : Bool :=
  match node with
  | .command n _ _ => n == name
  | _ => false

/-- Extract text content from a node recursively -/
def Node.extractText : Node → String
  | .text content _ => content
  | .group children _ => children.map extractText |> String.intercalate ""
  | .command _ args _ => args.map extractText |> String.intercalate ""
  | .environment _ _ body _ => body.map extractText |> String.intercalate ""
  | .document children _ => children.map extractText |> String.intercalate ""
  | .comment _ _ => ""

end Golitex.Frontend.AST