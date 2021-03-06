{-# LANGUAGE CPP #-}

{-|
Module:      Spec.Text.ReadSpec
Copyright:   (C) 2014-2016 Ryan Scott
License:     BSD-style (see the file LICENSE)
Maintainer:  Ryan Scott
Stability:   Provisional
Portability: GHC

@hspec@ tests for data types in the "Text.Read" module.
-}
module Spec.Text.ReadSpec (main, spec) where

import Instances.Text.Read ()

import Spec.Utils (prop_matchesTextShow)

import Test.Hspec (Spec, describe, hspec, parallel)
import Test.Hspec.QuickCheck (prop)

import Text.Read (Lexeme)
#if MIN_VERSION_base(4,7,0)
import Text.Read.Lex (Number)
#endif

main :: IO ()
main = hspec spec

spec :: Spec
spec = parallel $ do
    describe "Lexeme" $
        prop "TextShow instance" (prop_matchesTextShow :: Int -> Lexeme -> Bool)
#if MIN_VERSION_base(4,7,0)
    describe "Number" $
        prop "TextShow instance" (prop_matchesTextShow :: Int -> Number -> Bool)
#endif
