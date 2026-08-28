module NMN.Pathways
    ( -- * Metabolic step calculation
      evaluatePathways
    , PathwayDelta(..)
    ) where

import NMN.Types
import NMN.Enzymes

-- | Instantaneous rate of change for all metabolites (μM / s) and reaction fluxes
data PathwayDelta = PathwayDelta
    { dNAM     :: !Double
    , dPRPP    :: !Double
    , dNR      :: !Double
    , dNMN     :: !Double
    , dNADPlus :: !Double
    , dATP     :: !Double
    , dADP     :: !Double
    , dAMP     :: !Double
    , dPPi     :: !Double
    , dNMNSynthesized :: !Double
    , currentFluxes   :: !ReactionFlux
    } deriving stock (Eq, Show)

-- | Evaluate metabolic fluxes and derivative delta across all pathways for a given state
evaluatePathways :: MetabolitePool -> EnzymeRegistry -> PathwayDelta
evaluatePathways pool enzymes =
    let -- 1. Primary Salvage Pathway: NAM + PRPP -> NMN + PPi (NAMPT)
        vNAMPT = computeNAMPTFlux (nampt enzymes) (nam pool) (prpp pool) (nadPlus pool)

        -- 2. Riboside Kinase Pathway: NR + ATP -> NMN + ADP (NRK1)
        vNRK1  = computeNRK1Flux (nrk1 enzymes) (nr pool) (atp pool)

        -- 3. Adenylylation: NMN + ATP -> NAD+ + PPi (NMNAT)
        vNMNAT = computeNMNATFlux (nmnat enzymes) (nmn pool) (atp pool)

        -- 4. NAD+ Consumers: NAD+ -> NAM + products (CD38 & SIRTs)
        vCD38  = computeCD38Flux (cd38 enzymes) (nadPlus pool)
        vSIRT  = computeSIRTFlux (sirt enzymes) (nadPlus pool)

        -- 5. Basal cellular homeostasis: PRPP synthesis from Pentose Phosphate Pathway
        -- Target baseline ~ 15 μM; synthesizes faster when PRPP is depleted
        prppTarget = 15.0
        vPRPPSynth = max 0.0 ((prppTarget - prpp pool) * 0.25 + 1.2)

        -- 6. Basal ATP regeneration (Mitochondrial respiration & Glycolysis)
        -- Targets ~ 3000 μM; dynamically regenerates ADP -> ATP
        atpTarget  = 3000.0
        vATPSynth  = max 0.0 ((atpTarget - atp pool) * 0.5 + (vNRK1 + vNMNAT))

        -- 7. Inorganic pyrophosphatase (PPase) degradation of PPi -> 2 Pi
        vPPiase    = max 0.0 (ppi pool * 0.8)

        -- Coupled differential changes (μM / s)
        dNAM'      = (- vNAMPT) + vCD38 + vSIRT
        dPRPP'     = (- vNAMPT) + vPRPPSynth
        dNR'       = (- vNRK1)
        dNMN'      = vNAMPT + vNRK1 - vNMNAT
        dNADPlus'  = vNMNAT - (vCD38 + vSIRT)
        dATP'      = (- vNRK1) - vNMNAT + vATPSynth
        dADP'      = vNRK1 - vATPSynth
        dAMP'      = 0.0
        dPPi'      = vNAMPT + vNMNAT - vPPiase

        fluxes'    = ReactionFlux
            { fluxNAMPT     = vNAMPT
            , fluxNRK1      = vNRK1
            , fluxNMNAT     = vNMNAT
            , fluxCD38      = vCD38
            , fluxSIRT      = vSIRT
            , fluxPRPPSynth = vPRPPSynth
            , fluxATPSynth  = vATPSynth
            }

    in PathwayDelta
        { dNAM            = dNAM'
        , dPRPP           = dPRPP'
        , dNR             = dNR'
        , dNMN            = dNMN'
        , dNADPlus        = dNADPlus'
        , dATP            = dATP'
        , dADP            = dADP'
        , dAMP            = dAMP'
        , dPPi            = dPPi'
        , dNMNSynthesized = vNAMPT + vNRK1
        , currentFluxes   = fluxes'
        }

