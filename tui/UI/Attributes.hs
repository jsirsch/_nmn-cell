module UI.Attributes
    ( -- * Attribute names
      titleAttr
    , subtitleAttr
    , headerAttr
    , nmnTargetAttr
    , nadAttr
    , atpAttr
    , substrateAttr
    , borderHighlightAttr
    , fluxActiveAttr
    , fluxMutedAttr
    , statusOkAttr
    , statusWarnAttr
    , alertLogAttr
    , keyBindingAttr
    , selectedTabAttr
    , unselectedTabAttr
    , theMap
    ) where

import Brick.AttrMap (AttrMap, attrMap, AttrName, attrName)
import Brick.Util (fg, on)
import qualified Graphics.Vty as V

titleAttr :: AttrName
titleAttr = attrName "title"

subtitleAttr :: AttrName
subtitleAttr = attrName "subtitle"

headerAttr :: AttrName
headerAttr = attrName "header"

nmnTargetAttr :: AttrName
nmnTargetAttr = attrName "nmnTarget"

nadAttr :: AttrName
nadAttr = attrName "nad"

atpAttr :: AttrName
atpAttr = attrName "atp"

substrateAttr :: AttrName
substrateAttr = attrName "substrate"

borderHighlightAttr :: AttrName
borderHighlightAttr = attrName "borderHighlight"

fluxActiveAttr :: AttrName
fluxActiveAttr = attrName "fluxActive"

fluxMutedAttr :: AttrName
fluxMutedAttr = attrName "fluxMuted"

statusOkAttr :: AttrName
statusOkAttr = attrName "statusOk"

statusWarnAttr :: AttrName
statusWarnAttr = attrName "statusWarn"

alertLogAttr :: AttrName
alertLogAttr = attrName "alertLog"

keyBindingAttr :: AttrName
keyBindingAttr = attrName "keyBinding"

selectedTabAttr :: AttrName
selectedTabAttr = attrName "selectedTab"

unselectedTabAttr :: AttrName
unselectedTabAttr = attrName "unselectedTab"

theMap :: AttrMap
theMap = attrMap V.defAttr
    [ (titleAttr,           fg V.brightCyan `V.withStyle` V.bold)
    , (subtitleAttr,        fg V.cyan)
    , (headerAttr,          fg V.yellow `V.withStyle` V.bold)
    , (nmnTargetAttr,       fg V.brightYellow `V.withStyle` V.bold)
    , (nadAttr,             fg V.brightBlue `V.withStyle` V.bold)
    , (atpAttr,             fg V.brightMagenta `V.withStyle` V.bold)
    , (substrateAttr,       fg V.green)
    , (borderHighlightAttr, fg V.brightCyan)
    , (fluxActiveAttr,      fg V.brightGreen `V.withStyle` V.bold)
    , (fluxMutedAttr,       fg V.white)
    , (statusOkAttr,        fg V.green `V.withStyle` V.bold)
    , (statusWarnAttr,      fg V.brightRed `V.withStyle` V.bold)
    , (alertLogAttr,        fg V.yellow)
    , (keyBindingAttr,      fg V.brightWhite `V.withStyle` V.bold)
    , (selectedTabAttr,     (V.black `on` V.brightCyan) `V.withStyle` V.bold)
    , (unselectedTabAttr,   fg V.white)
    ]

