module NMN.Enzymes
    ( -- * Kinetic rate calculations
      michaelisMenten1
    , michaelisMenten2
    , computeNAMPTFlux
    , computeNRK1Flux
    , computeNMNATFlux
    , computeCD38Flux
    , computeSIRTFlux
    ) where

import NMN.Types

-- | Single substrate Michaelis-Menten rate calculation
michaelisMenten1 :: Enzyme -> Double -> Double
michaelisMenten1 Enzyme{..} s1
    | not isEnabled = 0.0
    | s1 <= 0.0     = 0.0
    | otherwise     =
        let effectiveVmax = vmax * expressionLevel * (1.0 - max 0.0 (min 1.0 inhibitionFactor))
            rate = (effectiveVmax * s1) / (km1 + s1)
        in max 0.0 rate

-- | Bi-substrate Michaelis-Menten rate calculation
michaelisMenten2 :: Enzyme -> Double -> Double -> Double
michaelisMenten2 Enzyme{..} s1 s2
    | not isEnabled      = 0.0
    | s1 <= 0.0 || s2 <= 0.0 = 0.0
    | otherwise          =
        let effectiveVmax = vmax * expressionLevel * (1.0 - max 0.0 (min 1.0 inhibitionFactor))
            saturation1   = s1 / (km1 + s1)
            saturation2   = s2 / (km2 + s2)
            rate          = effectiveVmax * saturation1 * saturation2
        in max 0.0 rate

-- | Calculate NAMPT flux: Nicotinamide + PRPP -> NMN + PPi
-- Includes physiological feedback inhibition by downstream NAD+ (Ki ~ 500 μM)
computeNAMPTFlux :: Enzyme -> Double -> Double -> Double -> Double
computeNAMPTFlux enzyme namConc prppConc nadPlusConc =
    let baseRate = michaelisMenten2 enzyme namConc prppConc
        -- Weak product/feedback inhibition by NAD+
        nadInhibition = 1.0 / (1.0 + (nadPlusConc / 600.0))
    in baseRate * nadInhibition

-- | Calculate NRK1 flux: Nicotinamide Riboside + ATP -> NMN + ADP
computeNRK1Flux :: Enzyme -> Double -> Double -> Double
computeNRK1Flux enzyme nrConc atpConc =
    michaelisMenten2 enzyme nrConc atpConc

-- | Calculate NMNAT flux: NMN + ATP -> NAD+ + PPi
computeNMNATFlux :: Enzyme -> Double -> Double -> Double
computeNMNATFlux enzyme nmnConc atpConc =
    michaelisMenten2 enzyme nmnConc atpConc

-- | Calculate CD38 flux: NAD+ -> Nicotinamide + ADPR
computeCD38Flux :: Enzyme -> Double -> Double
computeCD38Flux enzyme nadPlusConc =
    michaelisMenten1 enzyme nadPlusConc

-- | Calculate SIRT / PARP flux: NAD+ -> Nicotinamide + deacylated target
computeSIRTFlux :: Enzyme -> Double -> Double
computeSIRTFlux enzyme nadPlusConc =
    michaelisMenten1 enzyme nadPlusConc

