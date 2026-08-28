module NMN.Simulation
    ( -- * Core simulation steps
      stepSimulation
    , defaultCellState
      -- * Perturbations & Interventions
    , injectSubstrate
    , adjustEnzymeExpression
    , toggleEnzyme
    , setInhibitor
    , resetSimulation
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import NMN.Types
import NMN.Pathways

-- | Default initial cell state
defaultCellState :: CellState
defaultCellState = initialCellState

-- | Advance the simulation by delta-t seconds (Euler numerical integration with bounds checking)
stepSimulation :: Double -> CellState -> CellState
stepSimulation dt state@CellState{..} =
    let delta = evaluatePathways pool enzymes

        -- Integrate pool with floor at 0.0 to prevent negative concentrations
        clamp0 x = max 0.0 x
        newPool = MetabolitePool
            { nam     = clamp0 (nam pool     + dNAM delta     * dt)
            , prpp    = clamp0 (prpp pool    + dPRPP delta    * dt)
            , nr      = clamp0 (nr pool      + dNR delta      * dt)
            , nmn     = clamp0 (nmn pool     + dNMN delta     * dt)
            , nadPlus = clamp0 (nadPlus pool + dNADPlus delta * dt)
            , nadh    = nadh pool -- basal steady
            , atp     = clamp0 (atp pool     + dATP delta     * dt)
            , adp     = clamp0 (adp pool     + dADP delta     * dt)
            , amp     = clamp0 (amp pool     + dAMP delta     * dt)
            , ppi     = clamp0 (ppi pool     + dPPi delta     * dt)
            }

        newTime = simTime + dt
        newTicks = tickCount + 1
        newTotalNMN = totalNMNSynthesized + (dNMNSynthesized delta * dt)

        -- Automated warnings / metabolic event alerts
        alerts = generateAlerts pool newPool delta

        newLogs = take 12 (alerts ++ recentLogs)

    in state
        { pool                = newPool
        , fluxes              = currentFluxes delta
        , simTime             = newTime
        , tickCount           = newTicks
        , recentLogs          = newLogs
        , totalNMNSynthesized = newTotalNMN
        }

-- | Generate log alerts on significant biochemical shifts
generateAlerts :: MetabolitePool -> MetabolitePool -> PathwayDelta -> [Text]
generateAlerts oldPool newPool _ =
    let alerts0 = []
        alerts1 = if nam oldPool > 5.0 && nam newPool <= 5.0
                  then "⚠️ Low Nicotinamide (NAM): Salvage pathway substrate depleting." : alerts0
                  else alerts0
        alerts2 = if prpp oldPool > 3.0 && prpp newPool <= 3.0
                  then "⚠️ PRPP Depletion: Phosphoribosyltransferase rate limited." : alerts1
                  else alerts1
        alerts3 = if nmn newPool > 30.0 && nmn oldPool <= 30.0
                  then "🎉 High NMN accumulation: NMN > 30 μM reached!" : alerts2
                  else alerts2
        alerts4 = if nadPlus newPool < 150.0 && nadPlus oldPool >= 150.0
                  then "⚠️ NAD+ Deficiency: Cellular NAD+ pool fallen below critical threshold." : alerts3
                  else alerts3
    in alerts4

-- | Inject a bolus of substrate (μM) into the intracellular pool
injectSubstrate :: Metabolite -> Double -> CellState -> CellState
injectSubstrate met amount state@CellState{..} =
    let p = pool
        (p', logMsg) = case met of
            NAM -> (p { nam = nam p + amount }, "💉 Injected " <> T.pack (show amount) <> " μM Nicotinamide (NAM).")
            NR  -> (p { nr = nr p + amount }, "💉 Injected " <> T.pack (show amount) <> " μM Nicotinamide Riboside (NR).")
            PRPP -> (p { prpp = prpp p + amount }, "💉 Injected " <> T.pack (show amount) <> " μM PRPP.")
            ATP -> (p { atp = atp p + amount }, "💉 Injected " <> T.pack (show amount) <> " μM ATP.")
            NMN -> (p { nmn = nmn p + amount }, "💉 Injected " <> T.pack (show amount) <> " μM NMN directly.")
            NADPlus -> (p { nadPlus = nadPlus p + amount }, "💉 Injected " <> T.pack (show amount) <> " μM NAD+.")
            _   -> (p, "Injected substrate.")
    in state { pool = p', recentLogs = take 12 (logMsg : recentLogs) }

-- | Adjust enzyme expression multiplier
adjustEnzymeExpression :: EnzymeType -> Double -> CellState -> CellState
adjustEnzymeExpression etype multiplier state@CellState{..} =
    let modifyE e = e { expressionLevel = max 0.0 (min 5.0 (expressionLevel e * multiplier)) }
        e' = updateEnzymeRegistry etype modifyE enzymes
        msg = "⚙️ Adjusted expression for " <> T.pack (show etype) <> " (x" <> T.pack (show multiplier) <> ")."
    in state { enzymes = e', recentLogs = take 12 (msg : recentLogs) }

-- | Toggle active/inactive status of an enzyme
toggleEnzyme :: EnzymeType -> CellState -> CellState
toggleEnzyme etype state@CellState{..} =
    let modifyE e = e { isEnabled = not (isEnabled e) }
        e' = updateEnzymeRegistry etype modifyE enzymes
        statusStr reg = if isEnabled (getEnzyme etype reg) then "ENABLED" else "DISABLED"
        msg = "🔌 Enzyme " <> T.pack (show etype) <> " " <> statusStr e' <> "."
    in state { enzymes = e', recentLogs = take 12 (msg : recentLogs) }

-- | Set inhibitor factor [0.0 - 1.0] (e.g. FK866 for NAMPT, 78c for CD38)
setInhibitor :: EnzymeType -> Double -> CellState -> CellState
setInhibitor etype factor state@CellState{..} =
    let modifyE e = e { inhibitionFactor = max 0.0 (min 1.0 factor) }
        e' = updateEnzymeRegistry etype modifyE enzymes
        msg = "🛑 Set inhibitor for " <> T.pack (show etype) <> " to " <> T.pack (show (round (factor * 100) :: Int)) <> "%."
    in state { enzymes = e', recentLogs = take 12 (msg : recentLogs) }

-- | Helper to update specific enzyme in registry
updateEnzymeRegistry :: EnzymeType -> (Enzyme -> Enzyme) -> EnzymeRegistry -> EnzymeRegistry
updateEnzymeRegistry etype fn reg = case etype of
    NAMPT_Enzyme -> reg { nampt = fn (nampt reg) }
    NRK1_Enzyme  -> reg { nrk1  = fn (nrk1 reg) }
    NMNAT_Enzyme -> reg { nmnat = fn (nmnat reg) }
    CD38_Enzyme  -> reg { cd38  = fn (cd38 reg) }
    SIRT_Enzyme  -> reg { sirt  = fn (sirt reg) }

getEnzyme :: EnzymeType -> EnzymeRegistry -> Enzyme
getEnzyme etype reg = case etype of
    NAMPT_Enzyme -> nampt reg
    NRK1_Enzyme  -> nrk1 reg
    NMNAT_Enzyme -> nmnat reg
    CD38_Enzyme  -> cd38 reg
    SIRT_Enzyme  -> sirt reg

-- | Reset simulation to baseline initial state
resetSimulation :: CellState
resetSimulation = initialCellState

