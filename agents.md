# Porting `golitex` to Lean 4 – Project Plan

> Last updated: 2025-06-13

This document outlines the phased approach for **porting [`golitex`](https://github.com/litexlang/golitex) to Lean 4** as a fully-embedded domain-specific language (DSL) with custom elaborators, along with supporting tooling.

**Primary Goal:** Port the formal reasoning language capabilities of golitex into Lean 4, enabling formal verification and proof capabilities within the literate programming framework.

---

## 0. Vision

* Deliver a Lean 4 package (`Golitex`) that allows authors to write Litex/LaTeX-style documents directly inside Lean files.
* Provide pleasant Lean syntax sugar, semantic highlighting, error messages, and PDF/HTML export.
* Re-use Lean's metaprogramming infrastructure (elaborator monad, syntax quotations, command DSL) to minimise new code and maximise correctness.

---

## 1. Bootstrapping & Infrastructure ✅ COMPLETE
[x] Create a fresh lake package `Golitex` inside this repo.  
[x] Set up CI (GitHub Actions) ~~and **bors**~~ for never-broken `main`.  
[x] Add `Justfile`, `CHANGELOG.md`, semantic-versioning skeleton.  
[x] Configure formatting & linter (`Lake linter`, ~~`alean fmt`~~, `lefthook`).

---

## 2. Analysis of Upstream `golitex` ✅ COMPLETE

1. **Catalogue modules** (lexer, parser, macro expander, renderer).  
2. Build a dependency graph.  
3. Mark components that can be re-implemented via Lean's parser (**preferred**) vs. keep as external library.

Deliverable: `analysis.md` with mapping table & open questions. ✅

---

## 3. Syntax Front-End ✅ COMPLETE

* Translate core Litex grammar into Lean 4 ~~`syntax` declarations~~ AST types.  
* Prototype `Scanner` → `Token` → `AST` pipeline.  
* Add unit tests ~~using `IO` golden files~~ with comprehensive test suite.

**Milestone M1:** _All basic Litex commands parse without error._ ✅

### Completed Components:
- `Golitex.Frontend.Token` - Token types with BEq instance
- `Golitex.Frontend.Scanner` - Lexer using String.Pos
- `Golitex.Frontend.AST` - AST node types and parser
- `Golitex.Syntax` - litex! macro integration

---

## 4. Elaboration Layer ✅ COMPLETE

* Implement ~~custom `elab_command` & `elab_term` handlers~~ elaboration monad converting the AST into a semantic IR.  
* ~~Re-use Lean's `TermElabM`~~ Use custom ElabM for context, diagnostics.  
* ~~Provide attribute-based hooks~~ Support sections, paragraphs, lists, environments, text styles.

**Milestone M2:** _Elaboration succeeds and builds a minimal document tree._ ✅

### Completed Components:
- `Golitex.IR` - Document IR with blocks, inlines, and metadata
- `Golitex.Elab` - Elaboration from AST to IR with error handling
- Full test coverage including integration and property-based tests

---

## 5. Rendering & Back-Ends ✅ COMPLETE

* ~~Define a portable document IR~~ ✅ (Complete - see `Golitex.IR`)
* Provide **PDF** back-end via `lualatex` or `tectonic`. ✅
* Provide **HTML** back-end via `HTML` builder (Pure Lean ~~or external~~). ✅  
* Cache renders; integrate with Lake ~~`postInstall`~~ build tasks. ✅

**Milestone M3:** _`#eval render "hello.tex"` produces PDF._ ✅

### Completed:
- [x] Implement `Golitex.Backend.HTML` - Pure Lean HTML generation
- [x] Implement `Golitex.Backend.LaTeX` - LaTeX generation from IR
- [x] Implement `Golitex.Backend.PDF` - Call external TeX engine
- [x] Add Lake tasks for document compilation
- [x] Create render cache system

---

## 6. IDE Tooling 📋 PLANNED

* Syntax highlighting via ~~`lake build-lsp`~~ custom syntax extensions.  
* Custom diagnostic positions mapped back to source spans.  
* VSCode extension activation snippet.

### Prerequisites:
- [ ] Map AST nodes to source positions
- [ ] Integrate with Lean's diagnostic system
- [ ] Create VSCode extension configuration

---

## 7. Documentation & Examples 📋 PLANNED

* `docs/` with tutorial (`HelloWorld.lean`).  
* Cookbook of common constructs.  
* ~~Screencasts / asciinema~~ Written tutorials.

### Documentation Needed:
- [ ] User guide for litex! macro
- [ ] LaTeX command reference
- [ ] Extension guide for new commands
- [ ] Migration guide from LaTeX

---

## 8. Release & Maintenance 📋 PLANNED

* Tag `v0.1.0` once milestones M1–M3 pass CI.  
* ~~Nightly docs via `DeployDocs`~~ GitHub Pages documentation.  
* Collect user feedback, prioritise features.

### Release Criteria:
- [ ] All tests passing
- [ ] Basic PDF/HTML output working
- [ ] Documentation complete
- [ ] Example documents provided

---

## 9. Formal Reasoning Language Integration 🧮 HIGH PRIORITY

* Port golitex's formal reasoning capabilities to Lean 4
* Enable inline proofs and theorem statements within litex documents
* Integrate with Lean's proof checking infrastructure
* Support for mathematical notation with formal semantics
* Provide bridge between informal mathematical text and formal proofs
* Allow extraction of formal specifications from documentation

### Key Components:
- [ ] Formal language parser integrated with litex syntax
- [ ] Proof environment elaboration to Lean terms
- [ ] Bidirectional translation between LaTeX math and Lean expressions
- [ ] Verification of inline assertions and properties
- [ ] Integration with mathlib4 theorems and tactics

---

## 10. Stretch Goals 🎯 FUTURE

* Live preview in VSCode via `webview`.  
* Parallel compilation of documents.  
* Citation manager integration.
* BibTeX support
* Custom package system
* Advanced mathlib4 integration for mathematical content

---

## 11. Additional Achievements 🎉 BONUS

Beyond the original plan, we've implemented:
- Comprehensive test suite with 100% pass rate
- Property-based testing without external dependencies  
- Support for nested commands and environments
- Error recovery and diagnostic reporting
- Plain text conversion for debugging

---

## Meta-tracking

* This plan is a living document – update after every **atomic commit**. ✅
* ~~Sync actionable items to Apple Reminders via `apple-mcp`~~.

## Current Status

**Completed Phases:** 1, 2, 3, 4, 5  
**Completed Milestones:** M1, M2, M3  
**Current Phase:** 6 (IDE Tooling) - Optional/Future  
**Lines of Code:** ~2,500  
**Test Coverage:** Comprehensive (unit, integration, property-based)  
**Next Priority:** Documentation & Examples (Phase 7)