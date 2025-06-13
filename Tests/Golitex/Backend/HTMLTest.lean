import Golitex.Backend.HTML
import Golitex.IR

/-!
# HTML Backend Tests

Tests for the HTML generation from Golitex IR.
-/

namespace Golitex.Backend.HTMLTest

open Golitex.IR
open Golitex.Backend.HTML

/-- Helper to check if a string contains a substring -/
def contains (haystack : String) (needle : String) : Bool :=
  (haystack.splitOn needle).length > 1

/-- Test basic HTML element rendering -/
def testBasicElements : IO Unit := do
  -- Test text escaping
  let text := Html.text "<script>alert('xss')</script>"
  let textStr := text.toString
  if contains textStr "<script>" then
    panic! "HTML escaping failed"
  
  -- Test element with attributes
  let div := Html.div [("class", "test"), ("id", "main")] [Html.text "content"]
  let divStr := div.toString
  if !contains divStr "class=\"test\"" || !contains divStr "id=\"main\"" then
    panic! "Attribute rendering failed"
  
  IO.println "✓ Basic HTML elements test passed"

/-- Test inline rendering -/
def testInlineRendering : IO Unit := do
  -- Plain text
  let plain := renderInline (Inline.text "Hello")
  if plain.toString != "Hello" then
    panic! "Plain text rendering failed"
  
  -- Emphasized text
  let emph := renderInline (Inline.text "important" .emph)
  let emphStr := emph.toString
  if !contains emphStr "<em>" || !contains emphStr "</em>" then
    panic! "Emphasis rendering failed"
  
  -- Bold text
  let bold := renderInline (Inline.text "bold" .bold)
  let boldStr := bold.toString
  if !contains boldStr "<strong>" then
    panic! "Bold rendering failed"
  
  -- Command rendering
  let cmd := renderInline (Inline.command "foo" [Inline.text "bar"])
  let cmdStr := cmd.toString
  if !contains cmdStr "data-latex-command=\"foo\"" then
    panic! "Command rendering failed"
  
  IO.println "✓ Inline rendering test passed"

/-- Test block rendering -/
def testBlockRendering : IO Unit := do
  -- Paragraph
  let para := renderBlock (Block.paragraph [
    Inline.text "Hello ",
    Inline.text "world" .emph,
    Inline.text "!"
  ])
  let paraStr := para.toString
  if !contains paraStr "<p>" || !contains paraStr "<em>world</em>" then
    panic! "Paragraph rendering failed"
  
  -- Section headers
  let h1 := renderBlock (Block.section 1 [Inline.text "Title"])
  if !contains h1.toString "<h1>Title</h1>" then
    panic! "H1 rendering failed"
  
  let h2 := renderBlock (Block.section 2 [Inline.text "Subtitle"])
  if !contains h2.toString "<h2>Subtitle</h2>" then
    panic! "H2 rendering failed"
  
  -- Lists
  let ulist := renderBlock (Block.list false [
    [Block.paragraph [Inline.text "Item 1"]],
    [Block.paragraph [Inline.text "Item 2"]]
  ])
  let ulistStr := ulist.toString
  if !contains ulistStr "<ul>" || !contains ulistStr "<li>" then
    panic! "Unordered list rendering failed"
  
  let olist := renderBlock (Block.list true [
    [Block.paragraph [Inline.text "First"]],
    [Block.paragraph [Inline.text "Second"]]
  ])
  if !contains olist.toString "<ol>" then
    panic! "Ordered list rendering failed"
  
  -- Quote
  let quote := renderBlock (Block.quote [
    Block.paragraph [Inline.text "A wise quote"]
  ])
  if !contains quote.toString "<blockquote>" then
    panic! "Quote rendering failed"
  
  -- Verbatim
  let verb := renderBlock (Block.verbatim "let x = 42")
  let verbStr := verb.toString
  if !contains verbStr "<pre>" || !contains verbStr "<code>" then
    panic! "Verbatim rendering failed"
  
  IO.println "✓ Block rendering test passed"

/-- Test complete document rendering -/
def testDocumentRendering : IO Unit := do
  let doc : Document := {
    metadata := {}
    content := [
      Block.section 1 [Inline.text "Introduction"],
      Block.paragraph [
        Inline.text "This is ",
        Inline.text "important" .emph,
        Inline.text " text."
      ],
      Block.section 2 [Inline.text "Details"],
      Block.list false [
        [Block.paragraph [Inline.text "Point one"]],
        [Block.paragraph [Inline.text "Point two"]]
      ]
    ]
    raw := ""
  }
  
  let html := renderDocument doc
  
  -- Check DOCTYPE
  if !html.startsWith "<!DOCTYPE html>" then
    panic! "Missing DOCTYPE"
  
  -- Check basic structure
  if !contains html "<html" || !contains html "<head>" || !contains html "<body>" then
    panic! "Missing basic HTML structure"
  
  -- Check metadata
  if !contains html "charset=\"UTF-8\"" then
    panic! "Missing charset"
  
  -- Check content
  if !contains html "<h1>Introduction</h1>" then
    panic! "Missing h1"
  
  if !contains html "<em>important</em>" then
    panic! "Missing emphasis"
  
  -- Check default styles included
  if !contains html "<style>" then
    panic! "Missing default styles"
  
  IO.println "✓ Document rendering test passed"

/-- Test rendering options -/
def testRenderingOptions : IO Unit := do
  let doc : Document := {
    metadata := {}
    content := [Block.paragraph [Inline.text "Test"]]
    raw := ""
  }
  
  -- Test custom title
  let options : RenderOptions := {
    title := "My Custom Title"
    includeDefaultStyles := false
    customCss := "body { color: red; }"
  }
  
  let html := renderDocument doc options
  
  if !contains html "<title>My Custom Title</title>" then
    panic! "Custom title not applied"
  
  if contains html "font-family: 'Times New Roman'" then
    panic! "Default styles included when disabled"
  
  if !contains html "body { color: red; }" then
    panic! "Custom CSS not included"
  
  IO.println "✓ Rendering options test passed"

/-- Test special characters and edge cases -/
def testSpecialCases : IO Unit := do
  -- Test various special characters
  let specialText := Inline.text "< > & \" ' © € 🎉"
  let rendered := renderInline specialText
  let html := rendered.toString
  
  -- Check that special characters are escaped
  if html.toList.any (· == '<') && !contains html "&lt;" then
    panic! "Less-than not escaped"
  
  if html.toList.any (· == '>') && !contains html "&gt;" then
    panic! "Greater-than not escaped"
  
  -- Only check for unescaped & if it's not part of an entity
  let hasUnescapedAmp := html.splitOn "&" |>.any fun part =>
    !part.isEmpty && !part.startsWith "lt;" && !part.startsWith "gt;" && 
    !part.startsWith "amp;" && !part.startsWith "quot;" && !part.startsWith "#"
  if hasUnescapedAmp then
    panic! "Ampersand not escaped"
  
  -- Test nested structures
  let nested := Block.list false [
    [Block.paragraph [Inline.text "Item with ", Inline.text "nested" .bold, Inline.text " style"]],
    [Block.list true [
      [Block.paragraph [Inline.text "Nested item"]]
    ]]
  ]
  
  let nestedHtml := renderBlock nested
  let nestedStr := nestedHtml.toString
  
  if !contains nestedStr "<ul>" || !contains nestedStr "<ol>" then
    panic! "Nested lists not rendered correctly"
  
  IO.println "✓ Special cases test passed"

/-- Test environment rendering -/
def testEnvironmentRendering : IO Unit := do
  let env := renderBlock (Block.environment "theorem" [] [
    Block.paragraph [Inline.text "If ", Inline.text "x = y" .typewriter, Inline.text ", then ", Inline.text "y = x" .typewriter]
  ])
  
  let envStr := env.toString
  
  if !contains envStr "class=\"environment environment-theorem\"" then
    panic! "Environment class not set correctly"
  
  if !contains envStr "<code>x = y</code>" then
    panic! "Typewriter style not rendered as code"
  
  IO.println "✓ Environment rendering test passed"

/-- Run all HTML backend tests -/
def main : IO Unit := do
  IO.println "Running HTML Backend tests..."
  testBasicElements
  testInlineRendering
  testBlockRendering
  testDocumentRendering
  testRenderingOptions
  testSpecialCases
  testEnvironmentRendering
  IO.println "All HTML Backend tests completed successfully!"

-- #eval main