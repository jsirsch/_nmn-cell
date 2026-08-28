module UI.App
    ( app
    ) where

import Brick.Main (App(..), neverShowCursor)

import UI.Types
import UI.Attributes (theMap)
import UI.Draw (drawApp)
import UI.Events (handleEvent)

-- | Brick Application Definition
app :: App AppState CustomEvent Name
app = App
    { appDraw         = drawApp
    , appChooseCursor = neverShowCursor
    , appHandleEvent  = handleEvent
    , appStartEvent   = return ()
    , appAttrMap      = const theMap
    }

