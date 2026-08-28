module UI.Events
    ( handleEvent
    ) where

import Brick.Types (BrickEvent(..), EventM)
import Brick.Main (halt)
import qualified Graphics.Vty as V
import Control.Monad.State (get, gets, modify)
import Lens.Micro ((^.), (%~), (.~))
import qualified Data.Text as T

import UI.Types
import NMN.Types
import NMN.Simulation

-- | Top-level Brick event handler
handleEvent :: BrickEvent Name CustomEvent -> EventM Name AppState ()
handleEvent event = case event of
    -- Timer tick event from background ticker thread
    AppEvent TickEvent -> do
        paused <- gets (^. isPaused)
        if not paused
            then do
                dt <- gets (^. simDt)
                modify $ simState %~ stepSimulation dt
            else return ()

    -- Log message or other custom event
    AppEvent (LogMessageEvent msg) ->
        modify $ statusMessage .~ msg

    -- Key presses
    VtyEvent (V.EvKey key mods) -> handleKey key mods

    _ -> return ()

-- | Handle keyboard inputs
handleKey :: V.Key -> [V.Modifier] -> EventM Name AppState ()
handleKey key _mods = case key of
    -- Exit application
    V.KChar 'q' -> halt
    V.KChar 'Q' -> halt
    V.KEsc      -> halt

    -- Pause / Resume
    V.KChar ' ' -> do
        paused <- gets (^. isPaused)
        let newPaused = not paused
            msg = if newPaused then "Simulation PAUSED. Press Space to resume or 't' to single-step."
                               else "Simulation RESUMED."
        modify $ (isPaused .~ newPaused) . (statusMessage .~ msg)

    -- Single step tick
    V.KChar 't' -> do
        dt <- gets (^. simDt)
        modify $ (simState %~ stepSimulation dt)
               . (statusMessage .~ "Stepped 1 tick (" <> T.pack (show dt) <> "s).")

    -- Tab switching
    V.KChar '\t' -> do
        curTab <- gets (^. activeTab)
        let nextTab = case curTab of
                TabOverview -> TabEnzymes
                TabEnzymes  -> TabHelp
                TabHelp     -> TabOverview
        modify $ activeTab .~ nextTab

    V.KChar 'h' -> modify $ activeTab .~ TabHelp
    V.KChar 'H' -> modify $ activeTab .~ TabHelp

    -- Substrate injections
    V.KChar '1' -> do
        modify $ (simState %~ injectSubstrate NAM 25.0)
               . (statusMessage .~ "Injected 25.0 μM Nicotinamide (NAM) into cellular pool.")

    V.KChar '2' -> do
        modify $ (simState %~ injectSubstrate NR 20.0)
               . (statusMessage .~ "Injected 20.0 μM Nicotinamide Riboside (NR) into cellular pool.")

    V.KChar '3' -> do
        modify $ (simState %~ injectSubstrate PRPP 15.0)
               . (statusMessage .~ "Injected 15.0 μM PRPP substrate.")

    V.KChar '4' -> do
        modify $ (simState %~ injectSubstrate ATP 500.0)
               . (statusMessage .~ "Injected 500.0 μM ATP energy currency.")

    -- Enzyme regulation
    V.KChar 'u' -> do
        modify $ (simState %~ adjustEnzymeExpression NAMPT_Enzyme 1.25)
               . (statusMessage .~ "Upregulated NAMPT expression by +25%.")

    V.KChar 'i' -> do
        st <- get
        let currentInhib = inhibitionFactor (nampt (enzymes (st ^. simState)))
            newInhib = if currentInhib > 0.0 then 0.0 else 0.85
            msg = if newInhib > 0.0
                  then "Applied FK866: NAMPT inhibited 85%."
                  else "Cleared FK866: NAMPT uninhibited."
        modify $ (simState %~ setInhibitor NAMPT_Enzyme newInhib)
               . (statusMessage .~ msg)

    V.KChar 'c' -> do
        st <- get
        let currentInhib = inhibitionFactor (cd38 (enzymes (st ^. simState)))
            newInhib = if currentInhib > 0.0 then 0.0 else 0.90
            msg = if newInhib > 0.0
                  then "Applied 78c inhibitor: CD38 inhibited 90% (NAD+ sparing)."
                  else "Cleared CD38 inhibitor."
        modify $ (simState %~ setInhibitor CD38_Enzyme newInhib)
               . (statusMessage .~ msg)

    -- Simulation speed controls
    V.KChar '+' -> do
        modify $ \s ->
            let newDt = min 2.0 (s ^. simDt + 0.05)
            in (simDt .~ newDt) . (statusMessage .~ "Simulation speed set to dt = " <> T.pack (show (round (newDt * 100) :: Int)) <> "cs.") $ s

    V.KChar '=' -> handleKey (V.KChar '+') []

    V.KChar '-' -> do
        modify $ \s ->
            let newDt = max 0.02 (s ^. simDt - 0.05)
            in (simDt .~ newDt) . (statusMessage .~ "Simulation speed set to dt = " <> T.pack (show (round (newDt * 100) :: Int)) <> "cs.") $ s

    V.KChar '_' -> handleKey (V.KChar '-') []

    -- Reset simulation
    V.KChar 'r' -> do
        modify $ (simState .~ defaultCellState)
               . (statusMessage .~ "Reset cell simulation to baseline parameters.")

    _ -> return ()

