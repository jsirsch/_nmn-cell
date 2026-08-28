module NMN.Types
    ( -- * Metabolites
      Metabolite(..)
    , MetabolitePool(..)
    , initialMetabolitePool
      -- * Enzymes
    , Enzyme(..)
    , EnzymeType(..)
    , EnzymeRegistry(..)
    , initialEnzymeRegistry
      -- * Reaction Fluxes
    , ReactionFlux(..)
    , initialReactionFlux
      -- * Cell State
    , CellState(..)
    , initialCellState
    , EnergyCharge
    , computeEnergyCharge
    ) where

import GHC.Generics (Generic)
import Data.Text (Text)

-- | Identified biochemical species in the NMN synthesis pathways
data Metabolite
    = NAM      -- ^ Nicotinamide (μM)
    | PRPP     -- ^ 5-Phosphoribosyl-1-pyrophosphate (μM)
    | NR       -- ^ Nicotinamide Riboside (μM)
    | NMN      -- ^ Nicotinamide Mononucleotide (μM)
    | NADPlus  -- ^ Nicotinamide Adenine Dinucleotide oxidized (μM)
    | NADH     -- ^ Nicotinamide Adenine Dinucleotide reduced (μM)
    | ATP      -- ^ Adenosine Triphosphate (μM)
    | ADP      -- ^ Adenosine Diphosphate (μM)
    | AMP      -- ^ Adenosine Monophosphate (μM)
    | PPi      -- ^ Inorganic Pyrophosphate (μM)
    deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)

-- | Cellular concentrations of key metabolites (in micromolar, μM)
data MetabolitePool = MetabolitePool
    { nam     :: !Double  -- ^ Nicotinamide (Salvage precursor)
    , prpp    :: !Double  -- ^ PRPP (Ribose-phosphate donor for NAMPT)
    , nr      :: !Double  -- ^ Nicotinamide Riboside (Precursor for NRK)
    , nmn     :: !Double  -- ^ Nicotinamide Mononucleotide (Target molecule)
    , nadPlus :: !Double  -- ^ NAD+ (Essential coenzyme & sirtuin substrate)
    , nadh    :: !Double  -- ^ NADH (Electron carrier)
    , atp     :: !Double  -- ^ ATP (Energy currency & phosphate/adenylyl donor)
    , adp     :: !Double  -- ^ ADP
    , amp     :: !Double  -- ^ AMP
    , ppi     :: !Double  -- ^ Inorganic Pyrophosphate
    } deriving stock (Eq, Show, Generic)

-- | Typical mammalian baseline intracellular concentrations (μM)
initialMetabolitePool :: MetabolitePool
initialMetabolitePool = MetabolitePool
    { nam     = 25.0
    , prpp    = 15.0
    , nr      = 5.0
    , nmn     = 8.0
    , nadPlus = 450.0
    , nadh    = 50.0
    , atp     = 3000.0
    , adp     = 350.0
    , amp     = 50.0
    , ppi     = 10.0
    }

-- | Enzyme types active in NMN and NAD+ metabolic pathways
data EnzymeType
    = NAMPT_Enzyme  -- ^ Nicotinamide Phosphoribosyltransferase (Rate-limiting salvage)
    | NRK1_Enzyme   -- ^ Nicotinamide Riboside Kinase 1 (NR phosphorylation)
    | NMNAT_Enzyme  -- ^ NMN Adenylyltransferase (NMN -> NAD+)
    | CD38_Enzyme   -- ^ CD38 NAD+ Glycohydrolase (NAD+ consumer)
    | SIRT_Enzyme   -- ^ Sirtuins / PARPs (Deacylases / ADP-ribosylation)
    deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)

-- | Enzyme properties and kinetic parameters
data Enzyme = Enzyme
    { enzymeName       :: !Text
    , enzymeType       :: !EnzymeType
    , vmax             :: !Double  -- ^ Maximum velocity (μM / s)
    , km1              :: !Double  -- ^ Michaelis constant for primary substrate (μM)
    , km2              :: !Double  -- ^ Michaelis constant for secondary substrate (μM)
    , expressionLevel  :: !Double  -- ^ Relative expression multiplier [0.0 - 5.0]
    , inhibitionFactor :: !Double  -- ^ Inhibition factor [0.0 (no inhibition) - 1.0 (fully inhibited)]
    , isEnabled        :: !Bool    -- ^ Whether the enzyme is active
    } deriving stock (Eq, Show, Generic)

-- | Collection of enzymes involved in cellular NMN synthesis and turnover
data EnzymeRegistry = EnzymeRegistry
    { nampt :: !Enzyme  -- ^ NAM + PRPP -> NMN + PPi
    , nrk1  :: !Enzyme  -- ^ NR + ATP -> NMN + ADP
    , nmnat :: !Enzyme  -- ^ NMN + ATP -> NAD+ + PPi
    , cd38  :: !Enzyme  -- ^ NAD+ -> NAM + ADPR (Ectoenzyme/intracellular consumer)
    , sirt  :: !Enzyme  -- ^ NAD+ -> NAM + O-acetyl-ADPR (Deacetylase activity)
    } deriving stock (Eq, Show, Generic)

initialEnzymeRegistry :: EnzymeRegistry
initialEnzymeRegistry = EnzymeRegistry
    { nampt = Enzyme
        { enzymeName       = "NAMPT (Rate-Limiting Salvage)"
        , enzymeType       = NAMPT_Enzyme
        , vmax             = 12.0
        , km1              = 5.0   -- Km for NAM
        , km2              = 10.0  -- Km for PRPP
        , expressionLevel  = 1.0
        , inhibitionFactor = 0.0
        , isEnabled        = True
        }
    , nrk1 = Enzyme
        { enzymeName       = "NRK1 (Riboside Kinase)"
        , enzymeType       = NRK1_Enzyme
        , vmax             = 8.0
        , km1              = 20.0  -- Km for NR
        , km2              = 50.0  -- Km for ATP
        , expressionLevel  = 1.0
        , inhibitionFactor = 0.0
        , isEnabled        = True
        }
    , nmnat = Enzyme
        { enzymeName       = "NMNAT1/2 (Adenylyltransferase)"
        , enzymeType       = NMNAT_Enzyme
        , vmax             = 15.0
        , km1              = 15.0  -- Km for NMN
        , km2              = 100.0 -- Km for ATP
        , expressionLevel  = 1.0
        , inhibitionFactor = 0.0
        , isEnabled        = True
        }
    , cd38 = Enzyme
        { enzymeName       = "CD38 (NAD+ Glycohydrolase)"
        , enzymeType       = CD38_Enzyme
        , vmax             = 6.0
        , km1              = 25.0  -- Km for NAD+
        , km2              = 0.0
        , expressionLevel  = 1.0
        , inhibitionFactor = 0.0
        , isEnabled        = True
        }
    , sirt = Enzyme
        { enzymeName       = "SIRT1 / PARPs (NAD+ Consumers)"
        , enzymeType       = SIRT_Enzyme
        , vmax             = 5.0
        , km1              = 50.0  -- Km for NAD+
        , km2              = 0.0
        , expressionLevel  = 1.0
        , inhibitionFactor = 0.0
        , isEnabled        = True
        }
    }

-- | Metabolic reaction rates at the current simulation step (μM / s)
data ReactionFlux = ReactionFlux
    { fluxNAMPT :: !Double  -- ^ Rate of NAM + PRPP -> NMN
    , fluxNRK1  :: !Double  -- ^ Rate of NR + ATP -> NMN
    , fluxNMNAT :: !Double  -- ^ Rate of NMN + ATP -> NAD+
    , fluxCD38  :: !Double  -- ^ Rate of NAD+ -> NAM
    , fluxSIRT  :: !Double  -- ^ Rate of NAD+ -> NAM
    , fluxPRPPSynth :: !Double -- ^ Rate of PRPP synthesis from pentose phosphate
    , fluxATPSynth  :: !Double -- ^ Rate of oxidative phosphorylation / glycolysis ATP replenishment
    } deriving stock (Eq, Show, Generic)

initialReactionFlux :: ReactionFlux
initialReactionFlux = ReactionFlux
    { fluxNAMPT = 0.0
    , fluxNRK1  = 0.0
    , fluxNMNAT = 0.0
    , fluxCD38  = 0.0
    , fluxSIRT  = 0.0
    , fluxPRPPSynth = 0.0
    , fluxATPSynth  = 0.0
    }

-- | Cellular Adenylate Energy Charge: ([ATP] + 0.5 [ADP]) / ([ATP] + [ADP] + [AMP])
type EnergyCharge = Double

computeEnergyCharge :: MetabolitePool -> EnergyCharge
computeEnergyCharge MetabolitePool{..} =
    let totalAdenylates = atp + adp + amp
    in if totalAdenylates <= 0
       then 0.0
       else (atp + 0.5 * adp) / totalAdenylates

-- | Overall cell state encapsulating metabolite concentrations, enzymes, and time
data CellState = CellState
    { pool         :: !MetabolitePool
    , enzymes      :: !EnzymeRegistry
    , fluxes       :: !ReactionFlux
    , simTime      :: !Double    -- ^ Elapsed simulation time (seconds)
    , tickCount    :: !Integer   -- ^ Total simulation steps evaluated
    , recentLogs   :: ![Text]    -- ^ Biochemical event / alert notifications
    , totalNMNSynthesized :: !Double -- ^ Cumulative NMN produced (μM)
    } deriving stock (Eq, Show, Generic)

initialCellState :: CellState
initialCellState = CellState
    { pool                = initialMetabolitePool
    , enzymes             = initialEnzymeRegistry
    , fluxes              = initialReactionFlux
    , simTime             = 0.0
    , tickCount           = 0
    , recentLogs          = ["Cell simulation initialized: Salvage and NR pathways active."]
    , totalNMNSynthesized = 0.0
    }

