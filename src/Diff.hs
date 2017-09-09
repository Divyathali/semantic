{-# LANGUAGE DataKinds, TypeFamilies, TypeOperators #-}
module Diff where

import Data.Bifunctor
import Data.Functor.Both as Both
import Data.Functor.Classes.Pretty.Generic
import Data.Functor.Foldable
import Data.Mergeable
import Data.Record
import Data.Union
import Patch
import Syntax
import Term

-- | An annotated series of patches of terms.
newtype Diff syntax ann = Diff { unDiff :: DiffF syntax ann (Diff syntax ann) }

data DiffF syntax ann recur
  = In (Both ann) (syntax recur)
  | Patch (Patch (Term syntax ann))
  deriving (Functor)

type SyntaxDiff fields = Diff Syntax (Record fields)

diffSum :: (Foldable syntax, Functor syntax) => (Patch (Term syntax annotation) -> Int) -> Diff syntax annotation -> Int
diffSum patchCost = go
  where go (Diff (In _ syntax)) = sum (fmap go syntax)
        go (Diff (Patch patch)) = patchCost patch

-- | The sum of the node count of the diff’s patches.
diffCost :: (Foldable syntax, Functor syntax) => Diff syntax annotation -> Int
diffCost = diffSum (patchSum termSize)

-- | Merge a diff using a function to provide the Term (in Maybe, to simplify recovery of the before/after state) for every Patch.
mergeMaybe :: Mergeable syntax => (Patch (Term syntax annotation) -> Maybe (Term syntax annotation)) -> (Both annotation -> annotation) -> Diff syntax annotation -> Maybe (Term syntax annotation)
mergeMaybe transform extractAnnotation = cata algebra
  where algebra (In annotations syntax) = (extractAnnotation annotations :<) <$> sequenceAlt syntax
        algebra (Patch term) = transform term

-- | Recover the before state of a diff.
beforeTerm :: Mergeable f => Diff f annotation -> Maybe (Term f annotation)
beforeTerm = mergeMaybe before Both.fst

-- | Recover the after state of a diff.
afterTerm :: Mergeable f => Diff f annotation -> Maybe (Term f annotation)
afterTerm = mergeMaybe after Both.snd


-- | Strips the head annotation off a diff annotated with non-empty records.
stripDiff :: Functor f
          => Diff f (Record (h ': t))
          -> Diff f (Record t)
stripDiff = fmap rtail


-- | Constructs the replacement of one value by another in an Applicative context.
replacing :: Term syntax ann -> Term syntax ann -> Diff syntax ann
replacing = (Diff .) . (Patch .) . Replace

-- | Constructs the insertion of a value in an Applicative context.
inserting :: Term syntax ann -> Diff syntax ann
inserting = Diff . Patch . Insert

-- | Constructs the deletion of a value in an Applicative context.
deleting :: Term syntax ann -> Diff syntax ann
deleting = Diff . Patch . Delete


wrapTermF :: TermF syntax (Both ann) (Diff syntax ann) -> Diff syntax ann
wrapTermF (a :<< r) = Diff (In a r)


instance Apply1 Pretty1 fs => Pretty1 (Diff (Union fs)) where
  liftPretty p pl = go
    where go (Diff (In _ syntax)) = liftPrettyUnion go (list . map (liftPretty p pl)) syntax
          go (Diff (Patch patch)) = liftPretty (liftPretty p pl) (list . map (liftPretty p pl)) patch

instance (Apply1 Pretty1 fs, Pretty ann) => Pretty (Diff (Union fs) ann) where
  pretty = liftPretty pretty prettyList

instance Apply1 Pretty1 fs => Pretty2 (DiffF (Union fs)) where
  liftPretty2 pA plA pB plB (In (Join ann) f) = liftPretty2 pA plA pA plA ann <+> liftPrettyUnion pB plB f
  liftPretty2 pA plA _ _ (Patch p) = liftPretty (liftPretty pA plA) (list . map (liftPretty pA plA)) p

type instance Base (Diff syntax ann) = DiffF syntax ann

instance Functor syntax => Recursive (Diff syntax ann) where project = unDiff
instance Functor syntax => Corecursive (Diff syntax ann) where embed = Diff

instance Functor syntax => Functor (Diff syntax) where
  fmap f = Diff . bimap f (fmap f) . unDiff

instance Functor syntax => Bifunctor (DiffF syntax) where
  bimap f g (In anns r) = In (fmap f anns) (fmap g r)
  bimap f _ (Patch term) = Patch (fmap (fmap f) term)
