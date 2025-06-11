# Porting `golitex` to Lean 4 – Project Plan

> Last updated: 2025-06-11

This document outlines the phased approach for **porting [`golitex`](https://github.com/litexlang/golitex) to Lean 4** as a fully-embedded domain-specific language (DSL) with custom elaborators, along with supporting tooling.

---

## 0. Vision

* Deliver a Lean 4 package (`Golitex`) that allows authors to write Litex/LaTeX-style documents directly inside Lean files.
* Provide pleasant Lean syntax sugar, semantic highlighting, error messages, and PDF/HTML export.
* Re-use Lean's metaprogramming infrastructure (elaborator monad, syntax quotations, command DSL) to minimise new code and maximise correctness.

---

## 1. Bootstrapping & Infrastructure  
[ ] Create a fresh lake package `Golitex` inside this repo.  
[ ] Set up CI (GitHub Actions) and **bors** for never-broken `main`.  
[ ] Add `Justfile`, `CHANGELOG.md`, semantic-versioning skeleton.  
[ ] Configure formatting & linter (`Lake linter`, `alean fmt`, `lefthook`).

---

## 2. Analysis of Upstream `golitex`

1. **Catalogue modules** (lexer, parser, macro expander, renderer).  
2. Build a dependency graph.  
3. Mark components that can be re-implemented via Lean's parser (**preferred**) vs. keep as external library.

Deliverable: `analysis.md` with mapping table & open questions.

---

## 3. Syntax Front-End

* Translate core Litex grammar into Lean 4 `syntax` declarations.  
* Prototype `command` → `macro` stubs that capture the concrete syntax into AST structures.  
* Add unit tests using `IO` golden files.

**Milestone M1:** _All basic Litex commands parse without error._

---

## 4. Elaboration Layer

* Implement custom `elab_command` & `elab_term` handlers converting the AST into a semantic IR.  
* Re-use Lean's `TermElabM` for context, diagnostics.  
* Provide attribute-based hooks for document pre-amble, packages, etc.

**Milestone M2:** _Elaboration succeeds and builds a minimal document tree._

---

## 5. Rendering & Back-Ends

* Define a portable document IR (sections, environments, inline).  
* Provide **PDF** back-end via `lualatex` or `tectonic`.  
* Provide **HTML** back-end via `HTML` builder (Pure Lean or external).  
* Cache renders; integrate with Lake `postInstall`.

**Milestone M3:** _`#eval render "hello.tex"` produces PDF._

---

## 6. IDE Tooling

* Syntax highlighting via `lake build-lsp`.  
* Custom diagnostic positions mapped back to source spans.  
* VSCode extension activation snippet.

---

## 7. Documentation & Examples

* `docs/` with tutorial (`HelloWorld.lean`).  
* Cookbook of common constructs.  
* Screencasts / asciinema.

---

## 8. Release & Maintenance

* Tag `v0.1.0` once milestones M1–M3 pass CI.  
* Nightly docs via `DeployDocs`.  
* Collect user feedback, prioritise features.

---

## 9. Stretch Goals

* Live preview in VSCode via `webview`.  
* Parallel compilation of documents.  
* Citation manager integration.

---

## Meta-tracking

* This plan is a living document – update after every **atomic commit**.  
* Sync actionable items to Apple Reminders via `apple-mcp`. 