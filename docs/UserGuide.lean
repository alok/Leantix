import Verso
import Verso.Genre.Manual
import Golitex

open Verso.Genre.Manual
open Verso.Doc

def userGuide : Part := {
  title := "Golitex User Guide"
  intro := some #[
    para "Welcome to Golitex, a LaTeX-like domain-specific language (DSL) for Lean 4. This guide will help you get started with writing documents using Golitex."
  ]
  chapters := #[
    introductionChapter,
    gettingStartedChapter,
    syntaxChapter,
    htmlBackendChapter
  ]
}

def introductionChapter : Chapter where
  title := "Introduction"
  content := #[
    para "Golitex brings the power of LaTeX document authoring to Lean 4, allowing you to write mathematical documents, papers, and books directly within the Lean ecosystem.",
    
    section "What is Golitex?" #[
      para "Golitex is a port of the Go-based golitex system to Lean 4. It provides:",
      bullets #[
        "A familiar LaTeX-like syntax for document authoring",
        "Deep integration with Lean's type system and proof assistant",
        "Multiple output backends (HTML, PDF)",
        "Extensibility through Lean's metaprogramming capabilities"
      ]
    ],
    
    section "Why Golitex?" #[
      para "Traditional LaTeX has served the mathematical community well for decades, but Golitex offers several advantages:",
      bullets #[
        "Type-safe document construction",
        "Direct integration with Lean proofs and computations",
        "Modern tooling and error messages",
        "Extensible through Lean's macro system"
      ]
    ]
  ]

def gettingStartedChapter : Chapter where
  title := "Getting Started"
  content := #[
    para "This chapter will guide you through installing and using Golitex.",
    
    section "Installation" #[
      para "Add Golitex to your Lean 4 project by updating your lakefile.lean:",
      code "lean" "require golitex from git\n  \"https://github.com/yourusername/golitex.git\"",
      para "Then run:",
      code "bash" "lake update\nlake build"
    ],
    
    section "Your First Document" #[
      para "Here's a simple example using the litex! macro:",
      code "lean" 
"import Golitex

def myDocument := litex! \"
\\\\section{Hello, World!}

This is my first Golitex document. It supports \\\\emph{emphasis} and \\\\textbf{bold} text.

\\\\subsection{Mathematics}

We can write inline math like $x^2 + y^2 = z^2$ or display math:

$$\\\\int_0^\\\\infty e^{-x^2} dx = \\\\frac{\\\\sqrt{\\\\pi}}{2}$$
\"",
      
      para "To convert this to HTML:",
      code "lean"
"-- Parse and elaborate the document
let tokens := scan myDocument.raw
let ast := parseTokens tokens
let (doc, errors) := elaborate ast

-- Render to HTML
let html := renderDocument doc
IO.FS.writeFile \"output.html\" html"
    ]
  ]

def syntaxChapter : Chapter where
  title := "Golitex Syntax"
  content := #[
    para "This chapter covers the LaTeX-like syntax supported by Golitex.",
    
    section "Commands" #[
      para "Golitex supports standard LaTeX commands:",
      code "latex" 
"\\\\section{Section Title}
\\\\subsection{Subsection Title}
\\\\emph{emphasized text}
\\\\textbf{bold text}
\\\\textit{italic text}
\\\\texttt{monospace text}",
      
      para "Commands can take multiple arguments:",
      code "latex" "\\\\command{arg1}{arg2}{arg3}"
    ],
    
    section "Environments" #[
      para "Environments provide structured content:",
      code "latex"
"\\\\begin{itemize}
\\\\item First item
\\\\item Second item
\\\\end{itemize}

\\\\begin{enumerate}
\\\\item First numbered item
\\\\item Second numbered item
\\\\end{enumerate}

\\\\begin{verbatim}
Verbatim text preserves    spacing
and line breaks
\\\\end{verbatim}"
    ],
    
    section "Mathematics" #[
      para "Both inline and display math are supported:",
      code "latex"
"Inline math: $a^2 + b^2 = c^2$

Display math:
$$\\\\sum_{i=1}^n i = \\\\frac{n(n+1)}{2}$$"
    ]
  ]

def htmlBackendChapter : Chapter where
  title := "HTML Backend"
  content := #[
    para "The HTML backend converts Golitex documents to web-ready HTML.",
    
    section "Basic Usage" #[
      para "Convert a document to HTML with default settings:",
      code "lean"
"let html := renderDocument doc
IO.FS.writeFile \"output.html\" html"
    ],
    
    section "Customization" #[
      para "You can customize the HTML output with render options:",
      code "lean"
"let options : RenderOptions := {
  title := \"My Document\"
  includeDefaultStyles := true
  customCss := \"
    body { font-family: serif; }
    h1 { color: navy; }
  \"
}

let html := renderDocument doc options"
    ],
    
    section "Styling" #[
      para "The HTML backend includes default CSS styles that provide:",
      bullets #[
        "Responsive layout with maximum width",
        "Typography optimized for readability",
        "Proper spacing for headings and paragraphs",
        "Styled code blocks and mathematics",
        "Support for print media"
      ]
    ]
  ]
}