import Verso
import Verso.Genre.Manual
import Golitex

open Verso.Genre.Manual

def golitexManual : Manual where
  title := "Golitex Documentation"
  authors := #[{name := "Golitex Contributors"}]
  date := some "2025"
  
#doc (Manual) "Golitex Documentation" =>

# Introduction

Golitex brings the power of LaTeX document authoring to {lean}[Lean 4], allowing you to write mathematical documents, papers, and books directly within the Lean ecosystem.

## What is Golitex?

Golitex is a port of the Go-based golitex system to Lean 4. It provides:

* A familiar LaTeX-like syntax for document authoring
* Deep integration with Lean's type system and proof assistant
* Multiple output backends (HTML, PDF)
* Extensibility through Lean's metaprogramming capabilities

## Why Golitex?

Traditional LaTeX has served the mathematical community well for decades, but Golitex offers several advantages:

* Type-safe document construction
* Direct integration with Lean proofs and computations
* Modern tooling and error messages
* Extensible through Lean's macro system

# Getting Started

This chapter will guide you through installing and using Golitex.

## Installation

Add Golitex to your Lean 4 project by updating your `lakefile.lean`:

```lean
require golitex from git
  "https://github.com/yourusername/golitex.git"
```

Then run:

```bash
lake update
lake build
```

## Your First Document

Here's a simple example using the `litex!` macro:

```lean
import Golitex

def myDocument := litex! "
\\section{Hello, World!}

This is my first Golitex document. It supports \\emph{emphasis} and \\textbf{bold} text.

\\subsection{Mathematics}

We can write inline math like $x^2 + y^2 = z^2$ or display math:

$$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$
"
```

To convert this to HTML:

```lean
-- Parse and elaborate the document
let tokens := scan myDocument.raw
let ast := parseTokens tokens
let (doc, errors) := elaborate ast

-- Render to HTML
let html := renderDocument doc
IO.FS.writeFile "output.html" html
```

# Golitex Syntax

This chapter covers the LaTeX-like syntax supported by Golitex.

## Commands

Golitex supports standard LaTeX commands:

```latex
\section{Section Title}
\subsection{Subsection Title}
\emph{emphasized text}
\textbf{bold text}
\textit{italic text}
\texttt{monospace text}
```

Commands can take multiple arguments:

```latex
\command{arg1}{arg2}{arg3}
```

## Environments

Environments provide structured content:

```latex
\begin{itemize}
\item First item
\item Second item
\end{itemize}

\begin{enumerate}
\item First numbered item
\item Second numbered item
\end{enumerate}

\begin{verbatim}
Verbatim text preserves    spacing
and line breaks
\end{verbatim}
```

## Mathematics

Both inline and display math are supported:

```latex
Inline math: $a^2 + b^2 = c^2$

Display math:
$$\sum_{i=1}^n i = \frac{n(n+1)}{2}$$
```

# API Reference

This section provides detailed API documentation.

## Frontend API

The frontend modules handle lexical analysis and parsing.

### Token Module

```lean
inductive Token where
  | cmd (name : String) (pos : String.Pos := ⟨0⟩)
  | text (content : String) (pos : String.Pos := ⟨0⟩)
  | lbrace (pos : String.Pos := ⟨0⟩)
  | rbrace (pos : String.Pos := ⟨0⟩)
  | eof (pos : String.Pos := ⟨0⟩)
```

### Scanner Module

```lean
def scan (input : String) : Array Token
```

Tokenizes the input string into an array of tokens.

### AST Module

```lean
inductive Node where
  | command (name : String) (args : List Node) (pos : String.Pos := ⟨0⟩)
  | group (children : List Node) (pos : String.Pos := ⟨0⟩)
  | text (content : String) (pos : String.Pos := ⟨0⟩)
  | environment (name : String) (args : List Node) (body : List Node) (pos : String.Pos := ⟨0⟩)
  | document (children : List Node) (pos : String.Pos := ⟨0⟩)
```

```lean
def parseTokens (tokens : Array Token) : Node
```

## Backend API

### HTML Backend

```lean
def renderDocument (doc : Document) (options : RenderOptions := {}) : String
```

Renders a document to HTML with given options.

```lean
structure RenderOptions where
  includeDefaultStyles : Bool := true
  title : String := "Golitex Document"
  customCss : String := ""
  additionalHead : List Html := []
```