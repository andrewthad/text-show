{-|
Module:      TextShow.TH
Copyright:   (C) 2014-2015 Ryan Scott
License:     BSD-style (see the file LICENSE)
Maintainer:  Ryan Scott
Stability:   Provisional
Portability: GHC

Functions to mechanically derive 'TextShow', 'TextShow1', or 'TextShow2' instances,
or to splice @show@-related expressions into Haskell source code. You need to enable
the @TemplateHaskell@ language extension in order to use this module.

/Since: 2/
-}
module TextShow.TH (module TextShow.TH.Internal) where

import TextShow.Instances ()
import TextShow.TH.Internal