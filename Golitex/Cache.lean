import Golitex.IR
import Golitex.Frontend.AST
import Std.Data.HashMap
import Lean.Data.Json

/-!
# Golitex Render Cache

This module provides caching functionality for Golitex document rendering.
It caches parsed ASTs, elaborated IR, and rendered outputs to improve
compilation performance.
-/

namespace Golitex.Cache

open System
open Lean (Json)
open Std (HashMap)

/-- Cache entry for a Golitex document -/
structure CacheEntry where
  /-- Source file path -/
  sourcePath : FilePath
  /-- Last modification time of source -/
  sourceModTime : IO.FS.SystemTime
  /-- Hash of source content -/
  sourceHash : UInt64
  /-- Parsed AST -/
  ast : Option Golitex.Frontend.AST.Node := none
  /-- Elaborated IR -/
  ir : Option Golitex.IR.Document := none
  /-- Rendered HTML -/
  html : Option String := none
  /-- Rendered LaTeX -/
  latex : Option String := none
  /-- PDF file path (if generated) -/
  pdfPath : Option FilePath := none
  deriving Inhabited

/-- Document cache -/
structure Cache where
  /-- Cache directory -/
  cacheDir : FilePath
  /-- Cached entries by source path -/
  entries : HashMap FilePath CacheEntry := {}
  /-- Maximum cache size in bytes -/
  maxSize : Nat := 100 * 1024 * 1024  -- 100MB
  deriving Inhabited

/-- Initialize cache in given directory -/
def Cache.init (cacheDir : FilePath) : IO Cache := do
  -- Create cache directory if it doesn't exist
  if !(← cacheDir.pathExists) then
    IO.FS.createDirAll cacheDir
  return { cacheDir }

/-- Compute hash of string content -/
def hashContent (content : String) : UInt64 :=
  content.foldl (fun acc c => acc * 31 + c.val.toUInt64) 0

/-- Check if cache entry is valid -/
def isValidEntry (entry : CacheEntry) : IO Bool := do
  -- Check if source file still exists
  if !(← entry.sourcePath.pathExists) then
    return false
  
  -- Check if modification time matches
  let currentModTime ← entry.sourcePath.metadata
  if currentModTime.modified != entry.sourceModTime then
    return false
  
  -- Could also re-hash content for extra safety
  return true

/-- Get cached entry for source file -/
def Cache.get (cache : Cache) (sourcePath : FilePath) : IO (Option CacheEntry) := do
  match cache.entries[sourcePath]? with
  | none => return none
  | some entry =>
    if ← isValidEntry entry then
      return some entry
    else
      return none

/-- Update cache entry -/
def Cache.update (cache : Cache) (entry : CacheEntry) : Cache :=
  { cache with entries := cache.entries.insert entry.sourcePath entry }

/-- Save entry to disk cache -/
def saveEntryToDisk (cache : Cache) (entry : CacheEntry) : IO Unit := do
  let entryFile := cache.cacheDir / (toString entry.sourceHash ++ ".cache")
  
  -- Create a serializable representation
  let data : Json := Json.mkObj [
    ("sourcePath", Json.str entry.sourcePath.toString),
    ("sourceModTime", Json.num (entry.sourceModTime.sec.toNat : Nat)),
    ("sourceHash", Json.num (entry.sourceHash.toNat : Nat)),
    ("html", entry.html.map Json.str |>.getD Json.null),
    ("latex", entry.latex.map Json.str |>.getD Json.null),
    ("pdfPath", entry.pdfPath.map (Json.str ∘ toString) |>.getD Json.null)
  ]
  
  IO.FS.writeFile entryFile data.compress

/-- Load entry from disk cache -/
def loadEntryFromDisk (cache : Cache) (sourcePath : FilePath) : IO (Option CacheEntry) := do
  -- First check if source exists and get its info
  if !(← sourcePath.pathExists) then
    return none
  
  let content ← IO.FS.readFile sourcePath
  let hash := hashContent content
  let entryFile := cache.cacheDir / (toString hash ++ ".cache")
  
  if !(← entryFile.pathExists) then
    return none
  
  try
    let data ← IO.FS.readFile entryFile
    -- Parse JSON and reconstruct entry
    -- (simplified - would need proper JSON parsing)
    return none
  catch _ =>
    return none

/-- Clear expired entries from cache -/
def Cache.cleanup (cache : Cache) (maxAge : Nat := 7 * 24 * 3600) : IO Cache := do
  let now ← IO.monoMsNow
  let cutoff := now - maxAge * 1000
  
  -- Remove old entries from memory
  let validEntries ← cache.entries.toList.filterM fun (_, entry) => do
    if ← isValidEntry entry then
      return true
    else
      -- Remove from memory cache
      return false
  
  let newCache := { cache with entries := HashMap.ofList validEntries }
  
  -- Clean up disk cache
  let files ← cache.cacheDir.readDir
  for file in files do
    if file.path.extension == some "cache" then
      let metadata ← file.path.metadata
      if metadata.modified.sec.toNat * 1000 < cutoff then
        IO.FS.removeFile file.path
  
  return newCache

/-- Cache-aware document processing -/
def processWithCache (cache : Cache) (sourcePath : FilePath) 
    (process : String → IO (Golitex.Frontend.AST.Node × Golitex.IR.Document)) : 
    IO (Cache × Golitex.Frontend.AST.Node × Golitex.IR.Document) := do
  -- Check cache first
  if let some entry ← cache.get sourcePath then
    if let (some ast, some ir) := (entry.ast, entry.ir) then
      return (cache, ast, ir)
  
  -- Not in cache, process document
  let content ← IO.FS.readFile sourcePath
  let metadata ← sourcePath.metadata
  let hash := hashContent content
  let (ast, ir) ← process content
  
  -- Update cache
  let entry : CacheEntry := {
    sourcePath
    sourceModTime := metadata.modified
    sourceHash := hash
    ast := some ast
    ir := some ir
  }
  
  let newCache := cache.update entry
  saveEntryToDisk cache entry
  
  return (newCache, ast, ir)

/-- Initialize global cache reference -/
initialize globalCacheRef : IO.Ref (Option Cache) ← IO.mkRef none

/-- Get or create global cache -/
def getGlobalCache : IO Cache := do
  match ← globalCacheRef.get with
  | some cache => return cache
  | none =>
    let cache ← Cache.init ".golitex-cache"
    globalCacheRef.set (some cache)
    return cache

end Golitex.Cache