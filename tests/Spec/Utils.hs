{-# LANGUAGE CPP              #-}
{-# LANGUAGE FlexibleContexts #-}
{-|
Module:      Spec.Utils
Copyright:   (C) 2014-2015 Ryan Scott
License:     BSD-style (see the file LICENSE)
Maintainer:  Ryan Scott
Stability:   Experimental
Portability: GHC

Testing-related utility functions.
-}
module Spec.Utils (
      ioProperty
    , prop_matchesShow
#if __GLASGOW_HASKELL__ >= 702
    , prop_genericShow
#endif
    , prop_readShow
    , prop_showEq
    ) where

#if __GLASGOW_HASKELL__ >= 702
import           GHC.Generics (Generic, Rep)
#endif

import           Prelude hiding (Show)

#if MIN_VERSION_QuickCheck(2,7,0)
import qualified Test.QuickCheck as QC (ioProperty)
#else
import           Test.QuickCheck (morallyDubiousIOProperty)
#endif
import           Test.QuickCheck (Property, Testable)

import qualified Text.Show as S (Show)
import qualified Text.Show.Text as T (Show)
import           Text.Show.Text hiding (Show)
import           Text.Show.Text.Generic

ioProperty :: Testable prop => IO prop -> Property
#if MIN_VERSION_QuickCheck(2,7,0)
ioProperty = QC.ioProperty
#else
ioProperty = morallyDubiousIOProperty
#endif

-- | Verifies that a type's @Show@ instances coincide for both 'String's and 'Text',
-- irrespective of precedence.
prop_matchesShow :: (S.Show a, T.Show a) => Int -> a -> Bool
prop_matchesShow p x = showbPrec p (FromStringShow x) == showbPrec p x

#if __GLASGOW_HASKELL__ >= 702
-- | Verifies that a type's @Show@ instance coincides with the output produced
-- by the equivalent 'Generic' functions.
prop_genericShow :: (T.Show a, Generic a, GShow (Rep a))
                 => Int -> a -> Bool
prop_genericShow p x = showbPrec p x == genericShowbPrec p x
#endif

-- | Verifies that @read . show = id@.
prop_readShow :: (Eq a, Read a, S.Show a) => Int -> a -> Bool
prop_readShow p x = read (showsPrec p x "") == x

-- | Verifies that two type's @Show@ instances produce identical output, where the first
-- type is a wrapper around the second type.
prop_showEq :: (T.Show a, T.Show b) => (a -> b) -> Int -> a -> Bool
prop_showEq f p x = showbPrec p (f x) == showbPrec p x
