# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- AST module for parsing Litex/LaTeX-style commands
- Scanner module using String.Pos for proper position tracking
- Token module with BEq instance for comparisons
- ParsedDocument structure combining raw source and AST
- Integration of AST parser with litex! macro
- Comprehensive unit tests for all frontend modules

## [0.1.0] - 2025-06-11
### Added
- Initial project scaffold for `Golitex` Lean 4 library.
- `agents.md` plan, `.cursorrules` reference.
- Lake configuration updated with new library. 