module Spec.Data.VersionSpec (main, spec) where

import Data.Version (Version, showVersion)

import Instances.Data.Version ()

import Spec.Utils (prop_matchesTextShow)

import Test.Hspec (Spec, describe, hspec, parallel)
import Test.Hspec.QuickCheck (prop)

import TextShow (fromString)
import TextShow.Data.Version (showbVersionConcrete)

main :: IO ()
main = hspec spec

spec :: Spec
spec = parallel $ do
    describe "Version" $
        prop "TextShow instance"                      (prop_matchesTextShow :: Int -> Version -> Bool)
    describe "showbVersionConcrete" $
        prop "has the same output as showVersion"     prop_showVersion

-- | Verifies 'showVersion' and 'showbVersion' generate the same output.
prop_showVersion :: Version -> Bool
prop_showVersion v = fromString (showVersion v) == showbVersionConcrete v
