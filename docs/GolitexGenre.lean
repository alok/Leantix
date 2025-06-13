import Verso
import Golitex

/-!
# Golitex Documentation Genre

A custom Verso genre for Golitex documentation that integrates
LaTeX rendering capabilities with Verso's documentation system.
-/

open Verso Doc

namespace GolitexDocs

-- Extensions for Golitex-specific elements
inductive GolitexInline where
  | latexCommand (name : String) (args : Array (Inline GolitexGenre))
  | latexMath (content : String) (display : Bool)
  | golitexExample (source : String)

inductive GolitexBlock where  
  | latexEnvironment (name : String) (content : Array (Block GolitexGenre))
  | renderedExample (source : String) (output : String)

structure GolitexPartMetadata where
  tag : Option String := none
  latexLabel : Option String := none

structure TraverseContext where
  currentChapter : Option String := none
  
structure TraverseState where
  examples : List (String × String) := []
  labels : Std.HashMap String String := {}
  nextExampleId : Nat := 0

instance : BEq TraverseState where
  beq s1 s2 := 
    s1.examples == s2.examples &&
    s1.labels.toList.toArray == s2.labels.toList.toArray &&
    s1.nextExampleId == s2.nextExampleId

def GolitexGenre : Genre where
  Inline := GolitexInline
  Block := GolitexBlock
  PartMetadata := GolitexPartMetadata
  TraverseContext := TraverseContext
  TraverseState := TraverseState

-- Traversal implementation
abbrev TraverseM := ReaderT TraverseContext (StateT TraverseState Id)

instance : TraversePart GolitexGenre where
  -- Default implementation

instance : Traverse GolitexGenre TraverseM where
  part _ := pure none
  block _ := pure ()
  inline _ := pure ()
  
  genrePart metadata _ := do
    if let some label := metadata.latexLabel then
      modify fun st => { st with labels := st.labels.insert label metadata.tag.getD "" }
    pure none
    
  genreBlock
    | .renderedExample source _, _ => do
      -- Process and store examples
      let id ← modifyGet fun st => (st.nextExampleId, {st with nextExampleId := st.nextExampleId + 1})
      -- In a real implementation, we'd render the example here
      let output := s!"[Rendered output for example {id}]"
      modify fun st => { st with examples := (source, output) :: st.examples }
      pure none
    | _, _ => pure ()
    
  genreInline
    | .golitexExample source, _ => do
      -- Convert inline examples to block examples for processing
      pure (some (.other (.golitexExample source) #[]))
    | _, _ => pure none

-- HTML rendering
open Verso.Output Html in
instance : GenreHtml GolitexGenre IO where
  part recur metadata part := do
    let id := metadata.tag.getD (metadata.latexLabel.getD "")
    let attrs := if id.isEmpty then #[] else #[("id", id)]
    recur part (fun lvl title => .tag s!"h{lvl}" attrs title)
    
  block recur
    | .latexEnvironment name content, _ => do
      let content' ← content.mapM recur
      pure {{ <div class=s!"latex-env latex-env-{name}">{{content'}}</div> }}
    | .renderedExample source output, _ => do
      pure {{
        <div class="golitex-example">
          <div class="example-source">
            <pre><code>{{source}}</code></pre>
          </div>
          <div class="example-output">
            <div class="rendered">{{output}}</div>
          </div>
        </div>
      }}
      
  inline recur  
    | .latexCommand name args, _ => do
      let args' ← args.mapM recur
      pure {{ <span class=s!"latex-cmd latex-cmd-{name}">{{args'}}</span> }}
    | .latexMath content false, _ => 
      pure {{ <span class="math inline">\\({{content}}\\)</span> }}
    | .latexMath content true, _ => 
      pure {{ <div class="math display">\\[{{content}}\\]</div> }}
    | .golitexExample source, _ =>
      pure {{ <code class="golitex-inline">{{source}}</code> }}

-- User API
def latexCmd (name : String) (args : Array (Inline GolitexGenre)) : Inline GolitexGenre :=
  .other (.latexCommand name args) #[]

def math (content : String) : Inline GolitexGenre :=
  .other (.latexMath content false) #[]

def displayMath (content : String) : Inline GolitexGenre :=
  .other (.latexMath content true) #[]

def example (source : String) : Block GolitexGenre :=
  .other (.renderedExample source "[Output will be rendered]")

def latexEnv (name : String) (content : Array (Block GolitexGenre)) : Block GolitexGenre :=
  .other (.latexEnvironment name content)

end GolitexDocs