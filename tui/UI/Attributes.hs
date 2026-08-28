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
import Brick.Util (fg, on, style)
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
    [ (titleAttr,           fg V.brightCyan `style` V.bold)
    , (subtitleAttr,        fg V.cyan)
    , (headerAttr,          fg V.yellow `style` V.bold)
    , (nmnTargetAttr,       fg V.brightYellow `style` V.bold)
    , (nadAttr,             fg V.brightBlue `style` V.bold)
    , (atpAttr,             fg V.brightMagenta `style` V.bold)
    , (substrateAttr,       fg V.green)
    , (borderHighlightAttr, fg V.brightCyan)
    , (fluxActiveAttr,      fg V.brightGreen `style` V.bold)
    , (fluxMutedAttr,       fg V.white)
    , (statusOkAttr,        fg V.green `style` V.bold)
    , (statusWarnAttr,      fg V.brightRed `style` V.bold)
    , (alertLogAttr,        fg V.yellow)
    , (keyBindingAttr,      fg V.brightWhite `style` V.bold)
    , (selectedTabAttr,     (V.black `on` V.brightCyan) `style` V.bold)
    , (unselectedTabAttr,   fg V.white)
    ]

