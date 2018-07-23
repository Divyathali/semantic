{-# LANGUAGE DeriveAnyClass #-}
{-# OPTIONS_GHC -Wno-missing-export-lists #-}
module Language.Java.Syntax where

import Data.Abstract.Evaluatable
import Diffing.Algorithm
import Prologue hiding (Constructor)
import Data.JSON.Fields

newtype Import a = Import [a]
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)


instance Eq1 Import where liftEq = genericLiftEq
instance Ord1 Import where liftCompare = genericLiftCompare
instance Show1 Import where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for ArrayType
instance Evaluatable Import

data Module a = Module { moduleIdentifier :: !a, moduleStatements :: ![a] }
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)


instance Eq1 Module where liftEq = genericLiftEq
instance Ord1 Module where liftCompare = genericLiftCompare
instance Show1 Module where liftShowsPrec = genericLiftShowsPrec

instance Evaluatable Module

newtype Package a = Package [a]
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)


instance Eq1 Package where liftEq = genericLiftEq
instance Ord1 Package where liftCompare = genericLiftCompare
instance Show1 Package where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for ArrayType
instance Evaluatable Package

data EnumDeclaration a = EnumDeclaration { enumDeclarationModifier :: ![a], enumDeclarationIdentifier :: !a, enumDeclarationSuperInterfaces :: ![a], enumDeclarationConstant :: ![a], enumDeclarationBody :: ![a] }
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 EnumDeclaration where liftEq = genericLiftEq
instance Ord1 EnumDeclaration where liftCompare = genericLiftCompare
instance Show1 EnumDeclaration where liftShowsPrec = genericLiftShowsPrec
instance Evaluatable EnumDeclaration


data Variable a = Variable { variableModifiers :: ![a], variableType :: !a, variableName :: !a}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 Variable where liftEq = genericLiftEq
instance Ord1 Variable where liftCompare = genericLiftCompare
instance Show1 Variable where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for Variable
instance Evaluatable Variable

data Synchronized a = Synchronized { synchronizedSubject :: !a, synchronizedBody :: !a}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 Synchronized where liftEq = genericLiftEq
instance Ord1 Synchronized where liftCompare = genericLiftCompare
instance Show1 Synchronized where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for Synchronized
instance Evaluatable Synchronized

data New a = New { newType :: !a, newArgs :: ![a] }
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 New where liftEq = genericLiftEq
instance Ord1 New where liftCompare = genericLiftCompare
instance Show1 New where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for New
instance Evaluatable New

data Asterisk a = Asterisk
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 Asterisk where liftEq = genericLiftEq
instance Ord1 Asterisk where liftCompare = genericLiftCompare
instance Show1 Asterisk where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for New
instance Evaluatable Asterisk


data Constructor a = Constructor { constructorModifiers :: ![a], constructorTypeParams :: ![a], constructorIdentifier :: !a, constructorParams :: ![a], constructorThrows :: ![a], constructorBody :: a}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 Constructor where liftEq = genericLiftEq
instance Ord1 Constructor where liftCompare = genericLiftCompare
instance Show1 Constructor where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for Constructor
instance Evaluatable Constructor

data TypeParameter a = TypeParameter { typeParamAnnotation :: ![a], typeParamIdentifier :: !a, typeParamTypeBound :: ![a]}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 TypeParameter where liftEq = genericLiftEq
instance Ord1 TypeParameter where liftCompare = genericLiftCompare
instance Show1 TypeParameter where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for TypeParameter
instance Evaluatable TypeParameter

data Annotation a = Annotation { annotationName :: !a, annotationField :: [a]}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 Annotation where liftEq = genericLiftEq
instance Ord1 Annotation where liftCompare = genericLiftCompare
instance Show1 Annotation where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for Annotation
instance Evaluatable Annotation

data AnnotationField a = AnnotationField { annotationFieldName :: a, annotationFieldValue :: a }
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 AnnotationField where liftEq = genericLiftEq
instance Ord1 AnnotationField where liftCompare = genericLiftCompare
instance Show1 AnnotationField where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for AnnotationField
instance Evaluatable AnnotationField

data GenericType a = GenericType { genericTypeIdentifier :: a, genericTypeArguments :: [a] }
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 GenericType where liftEq = genericLiftEq
instance Ord1 GenericType where liftCompare = genericLiftCompare
instance Show1 GenericType where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for GenericType
instance Evaluatable GenericType

data TypeWithModifiers a = TypeWithModifiers [a] a
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 TypeWithModifiers where liftEq = genericLiftEq
instance Ord1 TypeWithModifiers where liftCompare = genericLiftCompare
instance Show1 TypeWithModifiers where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for TypeWithModifiers
instance Evaluatable TypeWithModifiers

data Wildcard a = Wildcard { wildcardAnnotation :: [a], wildcardBounds :: Maybe a }
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 Wildcard where liftEq = genericLiftEq
instance Ord1 Wildcard where liftCompare = genericLiftCompare
instance Show1 Wildcard where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for TypeWithModifiers
instance Evaluatable Wildcard

data WildcardBounds a = WildcardBoundExtends { wildcardBoundType :: a} | WildcardBoundSuper { wildcardBoundType :: a}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 WildcardBounds where liftEq = genericLiftEq
instance Ord1 WildcardBounds where liftCompare = genericLiftCompare
instance Show1 WildcardBounds where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for TypeWithModifiers
instance Evaluatable WildcardBounds

newtype SpreadParameter a = SpreadParameter { spreadParameterVariableDeclarator :: a}
  deriving (Declarations1, Diffable, Eq, Foldable, FreeVariables1, Functor, Generic1, Hashable1, Ord, Show, ToJSONFields1, Traversable)

instance Eq1 SpreadParameter where liftEq = genericLiftEq
instance Ord1 SpreadParameter where liftCompare = genericLiftCompare
instance Show1 SpreadParameter where liftShowsPrec = genericLiftShowsPrec

-- TODO: Implement Eval instance for SpreadParameter
instance Evaluatable SpreadParameter
