{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
module Main (main) where

import           Analysis.Name (Name)
import qualified Analysis.Name as Name
import qualified AST.Unmarshal as TS
import           Control.Algebra
import           Control.Carrier.Lift
import           Control.Carrier.Sketch.ScopeGraph
import qualified Control.Effect.ScopeGraph.Properties.Declaration as Props
import qualified Control.Effect.ScopeGraph.Properties.Function as Props
import qualified Control.Effect.ScopeGraph.Properties.Reference as Props
import           Control.Monad
import qualified Data.ByteString as ByteString
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.ScopeGraph as ScopeGraph
import qualified Language.Python ()
import qualified Language.Python as Py (Term)
import qualified Language.Python.Grammar as TSP
import           Scope.Graph.Convert
import           Source.Loc
import qualified Source.Source as Source
import           Source.Span
import           System.Exit (die)
import           System.Path ((</>))
import qualified System.Path as Path
import qualified System.Path.Directory as Path
import qualified Test.Tasty as Tasty
import qualified Test.Tasty.HUnit as HUnit

{-

The Python code here is

hello = ()
goodbye = ()

The graph should be

  🏁
  |
  1️⃣----"hello"
  |
  |
  |
  |
  2️⃣----"goodbye"

-}


runScopeGraph :: ToScopeGraph t => Path.AbsRelFile -> Source.Source -> t Loc -> (ScopeGraph.ScopeGraph Name, Result)
runScopeGraph p _src item = run . runSketch (Just p) $ scopeGraph item

sampleGraphThing :: ScopeGraphEff sig m => m Result
sampleGraphThing = do
  declare "hello" (Props.Declaration ScopeGraph.Assignment ScopeGraph.Default Nothing (Span (Pos 2 0) (Pos 2 10)))
  declare "goodbye" (Props.Declaration ScopeGraph.Assignment ScopeGraph.Default Nothing (Span (Pos 3 0) (Pos 3 12)))
  pure Complete

graphFile :: FilePath -> IO (ScopeGraph.ScopeGraph Name, Result)
graphFile fp = do
  file <- ByteString.readFile fp
  tree <- TS.parseByteString @Py.Term @Loc TSP.tree_sitter_python file
  pyModule <- either die pure tree
  pure $ runScopeGraph (Path.absRel fp) (Source.fromUTF8 file) pyModule


assertSimpleAssignment :: HUnit.Assertion
assertSimpleAssignment = do
  let path = "semantic-python/test/fixtures/1-04-toplevel-assignment.py"
  (result, Complete) <- graphFile path
  (expecto, Complete) <- runM $ runSketch Nothing sampleGraphThing
  HUnit.assertEqual "Should work for simple case" expecto result

assertSimpleReference :: HUnit.Assertion
assertSimpleReference = do
  let path = "semantic-python/test/fixtures/5-01-simple-reference.py"
  (result, Complete) <- graphFile path
  (expecto, Complete) <- runM $ runSketch Nothing expectedReference

  HUnit.assertEqual "Should work for simple case" expecto result

expectedReference :: ScopeGraphEff sig m => m Result
expectedReference = do
  declare "x" (Props.Declaration ScopeGraph.Assignment ScopeGraph.Default Nothing (Span (Pos 0 0) (Pos 0 5)))
  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 1 0) (Pos 1 1))
  newReference "x" refProperties
  pure Complete

expectedQualifiedImport :: ScopeGraphEff sig m => m Result
expectedQualifiedImport = do
  newEdge ScopeGraph.Import (NonEmpty.fromList ["cheese", "ints"])

  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 7) (Pos 0 13))
  newReference (Name.name "cheese") refProperties

  withScope "cheese" $ do
    let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 14) (Pos 0 18))
    newReference (Name.name "ints") refProperties
  pure Complete

expectedWildcardImport :: ScopeGraphEff sig m => m Result
expectedWildcardImport = do
  newEdge ScopeGraph.Import (NonEmpty.fromList ["cheese", "ints"])
  pure Complete

assertLexicalScope :: HUnit.Assertion
assertLexicalScope = do
  let path = "semantic-python/test/fixtures/5-02-simple-function.py"
  (graph, _) <- graphFile path
  case run (runSketch Nothing expectedLexicalScope) of
    (expecto, Complete) -> HUnit.assertEqual "Should work for simple case" expecto graph
    (_, Todo msg)       -> HUnit.assertFailure ("Failed to complete:" <> show msg)

expectedLexicalScope :: ScopeGraphEff sig m => m Result
expectedLexicalScope = do
  _ <- declareFunction (Just $ Name.name "foo") (Props.Function ScopeGraph.Function (Span (Pos 0 0) (Pos 1 24)))
  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 3 0) (Pos 3 3))
  newReference "foo" refProperties
  pure Complete


assertFunctionArg :: HUnit.Assertion
assertFunctionArg = do
  let path = "semantic-python/test/fixtures/5-03-function-argument.py"
  (graph, _) <- graphFile path
  case run (runSketch Nothing expectedFunctionArg) of
    (expecto, Complete) -> HUnit.assertEqual "Should work for simple case" expecto graph
    (_, Todo msg)       -> HUnit.assertFailure ("Failed to complete:" <>  show msg)

expectedFunctionArg :: ScopeGraphEff sig m => m Result
expectedFunctionArg = do
  (_, associatedScope) <- declareFunction (Just $ Name.name "foo") (Props.Function ScopeGraph.Function (Span (Pos 0 0) (Pos 1 12)))
  withScope associatedScope $ do
    declare "x" (Props.Declaration ScopeGraph.Parameter ScopeGraph.Default Nothing (Span (Pos 0 8) (Pos 0 9)))
    let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 1 11) (Pos 1 12))
    newReference "x" refProperties
    pure ()
  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 3 0) (Pos 3 3))
  newReference "foo" refProperties
  pure Complete


assertWildcardImport :: HUnit.Assertion
assertWildcardImport = do
  let path = "semantic-python/test/fixtures/cheese/6-01-imports.py"
  (graph, _) <- graphFile path
  case run (runSketch Nothing expectedWildcardImport) of
    (expecto, Complete) -> HUnit.assertEqual "Should work for simple case" expecto graph
    (_, Todo msg)       -> HUnit.assertFailure ("Failed to complete:" <>  show msg)

assertQualifiedImport :: HUnit.Assertion
assertQualifiedImport = do
  let path = "semantic-python/test/fixtures/cheese/6-02-qualified-imports.py"
  (graph, _) <- graphFile path
  case run (runSketch Nothing expectedQualifiedImport) of
    (expecto, Complete) -> HUnit.assertEqual "Should work for simple case" expecto graph
    (_, Todo msg)       -> HUnit.assertFailure ("Failed to complete:" <>  show msg)

assertImportFromSymbols :: HUnit.Assertion
assertImportFromSymbols = do
  let path = "semantic-python/test/fixtures/cheese/6-03-import-from.py"
  (graph, _) <- graphFile path
  case run (runSketch Nothing expectedImportFromSymbols) of
    (expecto, Complete) -> HUnit.assertEqual "Should work for simple case" expecto graph
    (_, Todo msg)       -> HUnit.assertFailure ("Failed to complete:" <>  show msg)

expectedImportFromSymbols :: ScopeGraphEff sig m => m Result
expectedImportFromSymbols = do
  newEdge ScopeGraph.Import (NonEmpty.fromList ["cheese", "ints"])

  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 5) (Pos 0 11))
  newReference (Name.name "cheese") refProperties

  withScope "cheese" $ do
    let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 12) (Pos 0 16))
    newReference (Name.name "ints") refProperties


  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 24) (Pos 0 27))
  newReference (Name.name "two") refProperties

  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 2 0) (Pos 2 3))
  newReference "two" refProperties

  pure Complete

assertImportFromSymbolAliases :: HUnit.Assertion
assertImportFromSymbolAliases = do
  let path = "semantic-python/test/fixtures/cheese/6-04-import-from-alias.py"
  (graph, _) <- graphFile path
  case run (runSketch Nothing expectedImportFromSymbolAliases) of
    (expecto, Complete) -> HUnit.assertEqual "Should work for simple case" expecto graph
    (_, Todo msg)       -> HUnit.assertFailure ("Failed to complete:" <>  show msg)

expectedImportFromSymbolAliases :: ScopeGraphEff sig m => m Result
expectedImportFromSymbolAliases = do
  newEdge ScopeGraph.Import (NonEmpty.fromList ["cheese", "ints"])

  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 5) (Pos 0 11))
  newReference (Name.name "cheese") refProperties

  withScope "cheese" $ do
    let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 12) (Pos 0 16))
    newReference (Name.name "ints") refProperties

  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 0 24) (Pos 0 27))
  newReference (Name.name "two") refProperties

  let declProperties = Props.Declaration ScopeGraph.UnqualifiedImport ScopeGraph.Default Nothing (Span (Pos 0 31) (Pos 0 36))
  declare (Name.name "three") declProperties

  let refProperties = Props.Reference ScopeGraph.Identifier ScopeGraph.Default (Span (Pos 2 0) (Pos 2 5))
  newReference "three" refProperties

  pure Complete

main :: IO ()
main = do
  -- make sure we're in the root directory so the paths resolve properly
  cwd <- Path.getCurrentDirectory
  when (Path.takeDirName cwd == Just (Path.relDir "semantic-python"))
    (Path.setCurrentDirectory (cwd </> Path.relDir ".."))

  Tasty.defaultMain $
    Tasty.testGroup "Tests" [
      Tasty.testGroup "declare" [
        HUnit.testCase "toplevel assignment" assertSimpleAssignment
      ],
      Tasty.testGroup "reference" [
        HUnit.testCase "simple reference" assertSimpleReference
      ],
      Tasty.testGroup "lexical scopes" [
        HUnit.testCase "simple function scope" assertLexicalScope
      , HUnit.testCase "simple function argument" assertFunctionArg
      ],
      Tasty.testGroup "imports" [
        HUnit.testCase "simple function argument" assertWildcardImport
        , HUnit.testCase "qualified imports" assertQualifiedImport
        , HUnit.testCase "qualified imports with symbols" assertImportFromSymbols
        , HUnit.testCase "qualified imports with symbol aliases" assertImportFromSymbolAliases
      ]
    ]
