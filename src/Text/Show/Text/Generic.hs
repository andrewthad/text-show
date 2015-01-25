{-# LANGUAGE CPP, FlexibleContexts, FlexibleInstances, InstanceSigs,
             OverloadedStrings, ScopedTypeVariables, TypeOperators #-}
{-|
Module:      Text.Show.Text.Generic
Copyright:   (C) 2014-2015 Ryan Scott
License:     BSD-style (see the file LICENSE)
Maintainer:  Ryan Scott
Stability:   Experimental
Portability: GHC

Generic versions of 'Show' class functions, as an alternative to "Text.Show.Text.TH",
which uses Template Haskell. This module is only available if the compiler supports
generics (on GHC, 7.2 or above).

This implementation is based off of the @Generics.Deriving.Show@ module from the
@generic-deriving@ library.

/Since: 0.6/
-}
module Text.Show.Text.Generic (
      -- * Generic @show@ functions
      -- $generics
      
      -- ** Understanding a compiler error
      -- $generic_err
      genericShow
    , genericShowLazy
    , genericShowPrec
    , genericShowPrecLazy
    , genericShowList
    , genericShowListLazy
    , genericShowb
    , genericShowbPrec
    , genericShowbList
    , genericPrint
    , genericPrintLazy
    , genericHPrint
    , genericHPrintLazy
      -- * The 'GShow' class
    , GShow(..)
    , ConType(..)
    ) where

#if !(MIN_VERSION_base(4,8,0))
import           Data.Monoid (mempty)
#endif
import qualified Data.Text    as TS (Text)
import qualified Data.Text.IO as TS (putStrLn, hPutStrLn)
import           Data.Text.Lazy (toStrict)
import           Data.Text.Lazy.Builder (Builder, fromString, toLazyText)
import qualified Data.Text.Lazy    as TL (Text)
import qualified Data.Text.Lazy.IO as TL (putStrLn, hPutStrLn)

import           GHC.Generics
import           GHC.Show (appPrec, appPrec1)

import           Prelude hiding (Show)

import           System.IO (Handle)

import           Text.Show.Text.Classes (Show(showbPrec), showbListDefault,
                                         showbParen, showbSpace)
import           Text.Show.Text.Instances ()
import           Text.Show.Text.Utils ((<>), isInfixTypeCon, isTupleString,
                                       s, toString)

{- $generics

'Show' instances can be easily defined for data types that are 'Generic' instances.
The easiest way to do this is to use the @DeriveGeneric@ extension.

@
&#123;-&#35; LANGUAGE DeriveGeneric &#35;-&#125;
import Text.Show.Text
import Text.Show.Generic (genericShowbPrec)

data D a = Nullary
         | Unary Int
         | Product String Char a
         | Record { testOne   :: Double
                  , testTwo   :: Bool
                  , testThree :: D a
                  }

instance Show a => Show (D a) where
    showbPrec = 'genericShowbPrec'
@

@D@ now has a 'Show' instance analogous to what would be generated by a
@deriving Show@ clause.

-}

{- $generic_err

Suppose you intend to tuse 'genericShowbPrec' to define a 'Show' instance.

@
data Oops = Oops
    -- forgot to add \"deriving Generic\" here!

instance Show Oops where
    showbPrec = 'genericShowbPrec'
@

If you forget to add a \"@deriving 'Generic'@\" clause to your data type, at
compile-time, you will get an error message that begins roughly as follows:

@
No instance for ('GShow' (Rep Oops))
@

This error can be confusing, but don't let it intimidate you. The correct fix is
simply to add the missing \"@deriving 'Generic'@\" clause.
-}

-- | Converts a 'Generic' instance to a strict 'TS.Text'.
-- 
-- /Since: 0.6/
genericShow :: (Generic a, GShow (Rep a)) => a -> TS.Text
genericShow = toStrict . genericShowLazy

-- | Converts a 'Generic' instance to a lazy 'TL.Text'.
-- 
-- /Since: 0.6/
genericShowLazy :: (Generic a, GShow (Rep a)) => a -> TL.Text
genericShowLazy = toLazyText . genericShowb

-- | Converts a 'Generic' instance to a strict 'TS.Text' with the given precedence.
-- 
-- /Since: 0.6/
genericShowPrec :: (Generic a, GShow (Rep a)) => Int -> a -> TS.Text
genericShowPrec p = toStrict . genericShowPrecLazy p

-- | Converts a 'Generic' instance to a lazy 'TL.Text' with the given precedence.
-- 
-- /Since: 0.6/
genericShowPrecLazy :: (Generic a, GShow (Rep a)) => Int -> a -> TL.Text
genericShowPrecLazy p = toLazyText . genericShowbPrec p

-- | Converts a list of 'Generic' instances to a strict 'TS.Text'.
-- 
-- /Since: 0.6/
genericShowList :: (Generic a, GShow (Rep a)) => [a] -> TS.Text
genericShowList = toStrict . genericShowListLazy

-- | Converts a list of 'Generic' instances to a lazy 'TL.Text'.
-- 
-- /Since: 0.6/
genericShowListLazy :: (Generic a, GShow (Rep a)) => [a] -> TL.Text
genericShowListLazy = toLazyText . genericShowbList

-- | Converts a 'Generic' instance to a 'Builder' with the given precedence.
-- 
-- /Since: 0.6/
genericShowb :: (Generic a, GShow (Rep a)) => a -> Builder
genericShowb = genericShowbPrec 0

-- | Converts a 'Generic' instance to a 'Builder' with the given precedence.
-- 
-- /Since: 0.6/
genericShowbPrec :: (Generic a, GShow (Rep a)) => Int -> a -> Builder
genericShowbPrec p = gShowbPrec Pref p . from

-- | Converts a list of 'Generic' instances to a 'Builder'.
-- 
-- /Since: 0.6/
genericShowbList :: (Generic a, GShow (Rep a)) => [a] -> Builder
genericShowbList = showbListDefault genericShowb

-- | Writes a 'Generic' instance's strict 'TS.Text' representation to the standard
-- output, followed by a newline.
-- 
-- /Since: 0.6/
genericPrint :: (Generic a, GShow (Rep a)) => a -> IO ()
genericPrint = TS.putStrLn . genericShow

-- | Writes a 'Generic' instance's lazy 'TL.Text' representation to the standard
-- output, followed by a newline.
-- 
-- /Since: 0.6/
genericPrintLazy :: (Generic a, GShow (Rep a)) => a -> IO ()
genericPrintLazy = TL.putStrLn . genericShowLazy

-- | Writes a 'Generic' instance's strict 'TS.Text' representation to the given file
-- handle, followed by a newline.
-- 
-- /Since: 0.6/
genericHPrint :: (Generic a, GShow (Rep a)) => Handle -> a -> IO ()
genericHPrint h = TS.hPutStrLn h . genericShow

-- | Writes a 'Generic' instance's lazy 'TL.Text' representation to the given file
-- handle, followed by a newline.
-- 
-- /Since: 0.6/
genericHPrintLazy :: (Generic a, GShow (Rep a)) => Handle -> a -> IO ()
genericHPrintLazy h = TL.hPutStrLn h . genericShowLazy

-- | Whether a constructor is a record ('Rec'), a tuple ('Tup'), is prefix ('Pref'),
-- or infix ('Inf').
data ConType = Rec | Tup | Pref | Inf Builder

-- | Class of generic representation types ('Rep') that can be converted to
-- a 'Builder'.
class GShow f where
    -- This function is used as the default generic implementation of 'showbPrec'.
    gShowbPrec :: ConType -> Int -> f a -> Builder
    -- Whether a representation type has any constructors.
    isNullary  :: f a -> Bool
    isNullary = error "generic show (isNullary): unnecessary case"

instance GShow U1 where
    gShowbPrec _ _ U1 = mempty
    isNullary _ = True

instance Show c => GShow (K1 i c) where
    gShowbPrec _ n (K1 a) = showbPrec n a
    isNullary _ = False

instance (Constructor c, GShow a) => GShow (M1 C c a) where
    gShowbPrec :: ConType -> Int -> M1 C c a b -> Builder
    gShowbPrec _ n c@(M1 x) = case fixity of
        Prefix    -> showbParen (n > appPrec && not (isNullary x || conIsTuple c)) $
               (if (conIsTuple c) then mempty else fromString (conName c))
            <> (if (isNullary x || conIsTuple c) then mempty else s ' ')
            <> (showbBraces t (gShowbPrec t appPrec1 x))
        Infix _ m -> showbParen (n > m) . showbBraces t $ gShowbPrec t (m+1) x
      where
        fixity :: Fixity
        fixity = conFixity c
        
        t :: ConType
        t = if (conIsRecord c)
            then Rec
            else case conIsTuple c of
                True  -> Tup
                False -> case fixity of
                    Prefix    -> Pref
                    Infix _ _ -> Inf . fromString $ conName c
        
        showbBraces :: ConType -> Builder -> Builder
        showbBraces Rec     b = s '{' <> b <> s '}'
        showbBraces Tup     b = s '(' <> b <> s ')'
        showbBraces Pref    b = b
        showbBraces (Inf _) b = b
        
        conIsTuple :: M1 C c a b -> Bool
        conIsTuple = isTupleString . conName

instance (Selector s, GShow a) => GShow (M1 S s a) where
    gShowbPrec t n sel@(M1 x)
        | selName sel == "" = gShowbPrec t n x
        | otherwise         = fromString (selName sel) <> " = " <> gShowbPrec t 0 x
    isNullary (M1 x) = isNullary x

instance GShow a => GShow (M1 D d a) where
    gShowbPrec t n (M1 x) = gShowbPrec t n x

instance (GShow a, GShow b) => GShow (a :+: b) where
    gShowbPrec t n (L1 x) = gShowbPrec t n x
    gShowbPrec t n (R1 x) = gShowbPrec t n x

instance (GShow a, GShow b) => GShow (a :*: b) where
    gShowbPrec t@Rec _ (a :*: b) =
           gShowbPrec t 0 a
        <> ", "
        <> gShowbPrec t 0 b
    gShowbPrec t@(Inf o) n (a :*: b) =
           gShowbPrec t n a
        <> showbSpace
        <> mBacktick
        <> o
        <> mBacktick
        <> showbSpace
        <> gShowbPrec t n b
      where
        mBacktick :: Builder
        mBacktick = if isInfixTypeCon (toString o)
            then mempty
            else s '`'
    gShowbPrec t@Tup _ (a :*: b) =
           gShowbPrec t 0 a
        <> s ','
        <> gShowbPrec t 0 b
    gShowbPrec t@Pref n (a :*: b) =
           gShowbPrec t n a
        <> showbSpace
        <> gShowbPrec t n b
    
    -- If we have a product then it is not a nullary constructor
    isNullary _ = False
