import Verso
import Verso.Genre.Manual
import Golitex

open Verso.Genre.Manual
open Verso.Doc

def apiReference : Part := {
  title := "API Reference"
  intro := some #[
    para "This section provides detailed API documentation for all Golitex modules."
  ]
  chapters := #[
    frontendAPIChapter,
    irAPIChapter,
    elabAPIChapter,
    backendAPIChapter
  ]
}

def frontendAPIChapter : Chapter where
  title := "Frontend API"
  content := #[
    para "The frontend modules handle lexical analysis and parsing of LaTeX-like syntax.",
    
    section "Golitex.Frontend.Token" #[
      para "Token types for the lexical analyzer.",
      
      subsection "Token Type" #[
        code "lean"
"inductive Token where
  | cmd (name : String) (pos : String.Pos := ⟨0⟩)
  | text (content : String) (pos : String.Pos := ⟨0⟩)
  | lbrace (pos : String.Pos := ⟨0⟩)
  | rbrace (pos : String.Pos := ⟨0⟩)
  | eof (pos : String.Pos := ⟨0⟩)
  deriving Repr, Inhabited, BEq",
        para "Represents the different token types produced by the scanner."
      ]
    ],
    
    section "Golitex.Frontend.Scanner" #[
      para "Lexical analysis functions.",
      
      subsection "scan" #[
        code "lean" "def scan (input : String) : Array Token",
        para "Tokenizes the input string into an array of tokens.",
        para bold!"Parameters:",
        bullets #[
          code "input" ++ " - The LaTeX source string to tokenize"
        ],
        para bold!"Returns:",
        para "An array of tokens representing the lexical structure of the input."
      ],
      
      subsection "debugTokens" #[
        code "lean" "def debugTokens (input : String) : String",
        para "Produces a human-readable representation of the token stream for debugging."
      ]
    ],
    
    section "Golitex.Frontend.AST" #[
      para "Abstract syntax tree definitions and parsing.",
      
      subsection "Node Type" #[
        code "lean"
"inductive Node where
  | command (name : String) (args : List Node) (pos : String.Pos := ⟨0⟩)
  | group (children : List Node) (pos : String.Pos := ⟨0⟩)
  | text (content : String) (pos : String.Pos := ⟨0⟩)
  | environment (name : String) (args : List Node) (body : List Node) (pos : String.Pos := ⟨0⟩)
  | document (children : List Node) (pos : String.Pos := ⟨0⟩)
  deriving Repr, Inhabited",
        para "Represents nodes in the abstract syntax tree."
      ],
      
      subsection "parseTokens" #[
        code "lean" "def parseTokens (tokens : Array Token) : Node",
        para "Parses a token array into an abstract syntax tree.",
        para bold!"Parameters:",
        bullets #[
          code "tokens" ++ " - Array of tokens from the scanner"
        ],
        para bold!"Returns:",
        para "A document node containing the parsed AST."
      ]
    ]
  ]

def irAPIChapter : Chapter where
  title := "Intermediate Representation"
  content := #[
    para "The IR module defines the semantic document structure.",
    
    section "Document Structure" #[
      code "lean"
"structure Document where
  metadata : Metadata := {}
  content : List Block := []
  raw : String := \"\"",
      para "The top-level document structure containing metadata and content blocks."
    ],
    
    section "Block Elements" #[
      code "lean"
"inductive Block where
  | paragraph (content : List Inline)
  | section (level : Nat) (title : List Inline) (label : Option String := none)
  | environment (name : String) (args : List String) (content : List Block)
  | list (ordered : Bool) (items : List (List Block))
  | quote (content : List Block)
  | verbatim (content : String)
  | raw (format : String) (content : String)",
      para "Block-level elements that make up the document structure."
    ],
    
    section "Inline Elements" #[
      code "lean"
"inductive Inline where
  | text (content : String) (style : TextStyle := .plain)
  | command (name : String) (args : List Inline)
  | math (content : String) (display : Bool := false)
  | space
  | lineBreak",
      para "Inline elements that can appear within blocks."
    ],
    
    section "Text Styles" #[
      code "lean"
"inductive TextStyle where
  | plain | emph | bold | typewriter | italic",
      para "Text formatting styles for inline content."
    ]
  ]

def elabAPIChapter : Chapter where
  title := "Elaboration API"
  content := #[
    para "The elaboration module converts AST to IR.",
    
    section "elaborate" #[
      code "lean" "def elaborate (ast : Node) : (Document × List String)",
      para "Elaborates an AST node into a semantic document.",
      para bold!"Parameters:",
      bullets #[
        code "ast" ++ " - The root AST node (should be a document node)"
      ],
      para bold!"Returns:",
      para "A tuple containing the elaborated document and any error messages."
    ],
    
    section "ElabM Monad" #[
      code "lean" "abbrev ElabM := StateT ElabContext Id",
      para "The elaboration monad for tracking context and errors during elaboration."
    ]
  ]

def backendAPIChapter : Chapter where
  title := "Backend API"
  content := #[
    para "Backend modules for generating output formats.",
    
    section "HTML Backend" #[
      subsection "renderDocument" #[
        code "lean" 
"def renderDocument (doc : Document) (options : RenderOptions := {}) : String",
        para "Renders a document to HTML.",
        para bold!"Parameters:",
        bullets #[
          code "doc" ++ " - The document to render",
          code "options" ++ " - Rendering configuration options"
        ],
        para bold!"Returns:",
        para "A complete HTML document as a string."
      ],
      
      subsection "RenderOptions" #[
        code "lean"
"structure RenderOptions where
  includeDefaultStyles : Bool := true
  title : String := \"Golitex Document\"
  customCss : String := \"\"
  additionalHead : List Html := []",
        para "Configuration options for HTML rendering."
      ],
      
      subsection "renderToFile" #[
        code "lean"
"def renderToFile (doc : Document) (path : System.FilePath) 
    (options : RenderOptions := {}) : IO Unit",
        para "Renders a document directly to an HTML file."
      ]
    ]
  ]
}