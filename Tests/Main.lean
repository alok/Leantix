import Tests.Golitex.Frontend.TokenTest
import Tests.Golitex.Frontend.ScannerTest
import Tests.Golitex.Frontend.ASTTest
import Tests.Golitex.SyntaxTest

/-!
# Main test runner for Golitex tests

This module runs all unit tests for the Golitex library.
-/

def main : IO Unit := do
  IO.println "===== Running Golitex Test Suite ====="
  IO.println ""
  
  -- Run Token tests
  Golitex.Frontend.TokenTest.main
  IO.println ""
  
  -- Run Scanner tests
  Golitex.Frontend.ScannerTest.main
  IO.println ""
  
  -- Run AST tests
  Golitex.Frontend.ASTTest.main
  IO.println ""
  
  -- Run Syntax tests
  Golitex.SyntaxTest.main
  IO.println ""
  
  IO.println "===== All tests completed! ====="