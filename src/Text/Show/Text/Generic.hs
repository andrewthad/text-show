{-# LANGUAGE CPP                 #-}
{-# LANGUAGE DeriveDataTypeable  #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}

#if __GLASGOW_HASKELL__ >= 706
{-# LANGUAGE PolyKinds           #-}
#endif

#if __GLASGOW_HASKELL__ >= 708
{-# LANGUAGE StandaloneDeriving  #-}
#endif
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

import           Data.Monoid.Compat ((<>))
import qualified Data.Text    as TS (Text)
import qualified Data.Text.IO as TS (putStrLn, hPutStrLn)
import           Data.Text.Lazy (toStrict)
import           Data.Text.Lazy.Builder (Builder, fromString, toLazyText)
import qualified Data.Text.Lazy    as TL (Text)
import qualified Data.Text.Lazy.IO as TL (putStrLn, hPutStrLn)
import           Data.Typeable (Typeable)

import           GHC.Generics
import           GHC.Show (appPrec, appPrec1)

import           Prelude ()
import           Prelude.Compat hiding (Show)

import           System.IO (Handle)

import qualified Text.Show as S (Show)
import qualified Text.Show.Text.Classes as T
import           Text.Show.Text.Classes (Show(showbPrec), showbListWith,
                                         showbParen, showbSpace)
import           Text.Show.Text.Instances ()
import           Text.Show.Text.Utils (isInfixTypeCon, isTupleString, s, toString)

#include "inline.h"

{- $generics

'T.Show' instances can be easily defined for data types that are 'Generic' instances.
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

@D@ now has a 'T.Show' instance analogous to what would be generated by a
@deriving Show@ clause.

-}

{- $generic_err

Suppose you intend to tuse 'genericShowbPrec' to define a 'T.Show' instance.

@
data Oops = Oops
    -- forgot to add \"deriving Generic\" here!

instance Show Oops where
    showbPrec = 'genericShowbPrec'
@

If you forget to add a @deriving 'Generic'@ clause to your data type, at
compile-time, you will get an error message that begins roughly as follows:

@
No instance for ('GShow' (Rep Oops))
@

This error can be confusing, but don't let it intimidate you. The correct fix is
simply to add the missing \"@deriving 'Generic'@\" clause.
-}

-- | A 'Generic' implementation of 'T.show'.
-- 
-- /Since: 0.6/
genericShow :: (Generic a, GShow (Rep a)) => a -> TS.Text
genericShow = toStrict . genericShowLazy

-- | A 'Generic' implementation of 'T.showLazy'.
-- 
-- /Since: 0.6/
genericShowLazy :: (Generic a, GShow (Rep a)) => a -> TL.Text
genericShowLazy = toLazyText . genericShowb

-- | A 'Generic' implementation of 'T.showPrec'.
-- 
-- /Since: 0.6/
genericShowPrec :: (Generic a, GShow (Rep a)) => Int -> a -> TS.Text
genericShowPrec p = toStrict . genericShowPrecLazy p

-- | A 'Generic' implementation of 'T.showPrecLazy'.
-- 
-- /Since: 0.6/
genericShowPrecLazy :: (Generic a, GShow (Rep a)) => Int -> a -> TL.Text
genericShowPrecLazy p = toLazyText . genericShowbPrec p

-- | A 'Generic' implementation of 'T.showList'.
-- 
-- /Since: 0.6/
genericShowList :: (Generic a, GShow (Rep a)) => [a] -> TS.Text
genericShowList = toStrict . genericShowListLazy

-- | A 'Generic' implementation of 'T.showListLazy'.
-- 
-- /Since: 0.6/
genericShowListLazy :: (Generic a, GShow (Rep a)) => [a] -> TL.Text
genericShowListLazy = toLazyText . genericShowbList

-- | A 'Generic' implementation of 'T.showb'.
-- 
-- /Since: 0.6/
genericShowb :: (Generic a, GShow (Rep a)) => a -> Builder
genericShowb = genericShowbPrec 0

-- | A 'Generic' implementation of 'T.showbPrec'.
-- 
-- /Since: 0.6/
genericShowbPrec :: (Generic a, GShow (Rep a)) => Int -> a -> Builder
genericShowbPrec p = gShowbPrec Pref p . from

-- | A 'Generic' implementation of 'T.showbList'.
-- 
-- /Since: 0.6/
genericShowbList :: (Generic a, GShow (Rep a)) => [a] -> Builder
genericShowbList = showbListWith genericShowb

-- | A 'Generic' implementation of 'T.print'.
-- 
-- /Since: 0.6/
genericPrint :: (Generic a, GShow (Rep a)) => a -> IO ()
genericPrint = TS.putStrLn . genericShow

-- | A 'Generic' implementation of 'T.printLazy'.
-- 
-- /Since: 0.6/
genericPrintLazy :: (Generic a, GShow (Rep a)) => a -> IO ()
genericPrintLazy = TL.putStrLn . genericShowLazy

-- | A 'Generic' implementation of 'T.hPrint'.
-- 
-- /Since: 0.6/
genericHPrint :: (Generic a, GShow (Rep a)) => Handle -> a -> IO ()
genericHPrint h = TS.hPutStrLn h . genericShow

-- | A 'Generic' implementation of 'T.hPrintLazy'.
-- 
-- /Since: 0.6/
genericHPrintLazy :: (Generic a, GShow (Rep a)) => Handle -> a -> IO ()
genericHPrintLazy h = TL.hPutStrLn h . genericShowLazy

-- | Whether a constructor is a record ('Rec'), a tuple ('Tup'), is prefix ('Pref'),
-- or infix ('Inf').
-- 
-- /Since: 0.6/
data ConType = Rec | Tup | Pref | Inf Builder
  deriving ( Generic
           , S.Show
           , Typeable
#if MIN_VERSION_text(0,11,1)
           , Eq
           , Ord
#endif
           )

instance T.Show ConType where
    showbPrec = genericShowbPrec
    INLINE_INST_FUN(showbPrec)

-- | Class of generic representation types ('Rep') that can be converted to
-- a 'Builder'.
-- 
-- /Since: 0.6/
class GShow f where
    -- | This is used as the default generic implementation of 'showbPrec'.
    gShowbPrec :: ConType -> Int -> f a -> Builder
    -- | Whether a representation type has any constructors.
    isNullary  :: f a -> Bool
    isNullary = error "generic show (isNullary): unnecessary case"
#if __GLASGOW_HASKELL__ >= 708
    {-# MINIMAL gShowbPrec #-}

deriving instance Typeable GShow
#endif

instance GShow U1 where
    gShowbPrec _ _ U1 = mempty
    isNullary _ = True

instance T.Show c => GShow (K1 i c) where
    gShowbPrec _ n (K1 a) = showbPrec n a
    isNullary _ = False

instance (Constructor c, GShow a) => GShow (M1 C c a) where
    gShowbPrec _ n c@(M1 x) = case fixity of
        Prefix -> showbParen ( n > appPrec
                               && not ( isNullary x
                                        || conIsTuple c
#if __GLASGOW_HASKELL__ >= 711
                                        || conIsRecord c
#endif
                                      )
                             ) $
               (if conIsTuple c
                   then mempty
                   else let cn = conName c
                        in showbParen (isInfixTypeCon cn) $ fromString cn
               )
            <> (if isNullary x || conIsTuple c
                   then mempty
                   else s ' '
               )
            <> showbBraces t (gShowbPrec t appPrec1 x)
        Infix _ m -> showbParen (n > m) . showbBraces t $ gShowbPrec t (m+1) x
      where
        fixity :: Fixity
        fixity = conFixity c
        
        t :: ConType
        t = if conIsRecord c
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
        <> infixOp
        <> showbSpace
        <> gShowbPrec t n b
      where
        infixOp :: Builder
        infixOp = if isInfixTypeCon (toString o)
                     then o
                     else s '`' <> o <> s '`'
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
