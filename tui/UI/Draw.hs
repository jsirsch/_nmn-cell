module UI.Draw
    ( drawApp
    ) where

import Brick.Types (Widget)
import Brick.Widgets.Core
import Brick.Widgets.Border (borderWithLabel, hBorder)
import Brick.Widgets.Border.Style (unicode)
import qualified Data.Text as T
import Numeric (showFFloat)
import Lens.Micro ((^.))

import NMN.Types
import UI.Types
import UI.Attributes

-- | Top-level render function
drawApp :: AppState -> [Widget Name]
drawApp st =
    [ withBorderStyle unicode $
        vBox
            [ drawHeader st
            , drawTabBar st
            , drawMainContent st
            , drawFooter st
            ]
    ]

-- | Top header with title, running state, simulation clock, and energy charge
drawHeader :: AppState -> Widget Name
drawHeader st =
    let cs = st ^. simState
        p  = pool cs
        ec = computeEnergyCharge p
        isPaused' = st ^. isPaused
        statusWidget = if isPaused'
                       then withAttr statusWarnAttr (str "[ PAUSED ]")
                       else withAttr statusOkAttr   (str "[ RUNNING ]")
        timeStr = formatFloat 2 (simTime cs) <> "s"
        nmnTotalStr = formatFloat 2 (totalNMNSynthesized cs) <> " μM"
        ecStr = formatFloat 3 ec
        ecAttr = if ec >= 0.85 then statusOkAttr else statusWarnAttr
    in borderWithLabel (withAttr titleAttr (str " 🔬 NMN CELL SIMULATION ENGINE ")) $
        padLeftRight 1 $
            vBox
                [ hBox
                    [ withAttr subtitleAttr (str "Nicotinamide Mononucleotide & NAD+ Biosynthesis")
                    , fill ' '
                    , statusWidget
                    , str "  |  Sim Time: "
                    , withAttr headerAttr (str timeStr)
                    , str " (Tick #"
                    , str (show (tickCount cs))
                    , str ")"
                    ]
                , hBox
                    [ str "Total NMN Synthesized: "
                    , withAttr nmnTargetAttr (str nmnTotalStr)
                    , fill ' '
                    , str "Adenylate Energy Charge: "
                    , withAttr ecAttr (str ecStr)
                    , str (if ec >= 0.85 then " (Optimal)" else " (Low Energy)")
                    ]
                ]

-- | Tab bar navigation
drawTabBar :: AppState -> Widget Name
drawTabBar st =
    let curTab = st ^. activeTab
        renderTab tab label keyStr =
            let isCurrent = tab == curTab
                attr = if isCurrent then selectedTabAttr else unselectedTabAttr
                prefix = if isCurrent then " ► " else "   "
            in withAttr attr (str (prefix <> "[" <> keyStr <> "] " <> label <> " "))
    in padLeftRight 1 $
        hBox
            [ renderTab TabOverview "1. Overview & Metabolic Flux" "Tab/1"
            , str "  "
            , renderTab TabEnzymes  "2. Enzyme Kinetics & Regulation" "2"
            , str "  "
            , renderTab TabHelp     "3. Pathways & Biochemical Guide" "3/h"
            , fill ' '
            ]

-- | Render content depending on active tab
drawMainContent :: AppState -> Widget Name
drawMainContent st = case st ^. activeTab of
    TabOverview -> drawOverviewTab st
    TabEnzymes  -> drawEnzymesTab st
    TabHelp     -> drawHelpTab st

-- | Overview Tab: Metabolic pathway ASCII map, metabolite concentrations, and real-time flux
drawOverviewTab :: AppState -> Widget Name
drawOverviewTab st =
    let cs = st ^. simState
    in vBox
        [ hBox
            [ drawPathwaySchematic cs
            , drawFluxPanel cs
            ]
        , hBox
            [ drawMetabolitePoolPanel (pool cs)
            , drawLogPanel (recentLogs cs)
            ]
        ]

-- | Visual ASCII Diagram of the NMN synthesis and salvage cycle
drawPathwaySchematic :: CellState -> Widget Name
drawPathwaySchematic cs =
    let p = pool cs
        f = fluxes cs
        vNAMPTStr = formatFloat 2 (fluxNAMPT f) <> " μM/s"
        vNRK1Str  = formatFloat 2 (fluxNRK1 f) <> " μM/s"
        vNMNATStr = formatFloat 2 (fluxNMNAT f) <> " μM/s"
        vConsStr  = formatFloat 2 (fluxCD38 f + fluxSIRT f) <> " μM/s"
    in borderWithLabel (withAttr headerAttr (str " Metabolic Pathway Schematic ")) $
        padLeftRight 1 $
            vBox
                [ hBox [ str "Salvage:  "
                       , withAttr substrateAttr (str ("[NAM] (" <> formatFloat 1 (nam p) <> " μM)"))
                       , str " + "
                       , withAttr substrateAttr (str ("[PRPP] (" <> formatFloat 1 (prpp p) <> " μM)"))
                       , str " ──[ "
                       , withAttr fluxActiveAttr (str ("NAMPT: " <> vNAMPTStr))
                       , str " ]──► "
                       , withAttr nmnTargetAttr (str "[ NMN ]")
                       ]
                , hBox [ str "NR Kinase:"
                       , withAttr substrateAttr (str ("[NR]  (" <> formatFloat 1 (nr p) <> " μM)"))
                       , str " + "
                       , withAttr atpAttr (str ("[ATP]  (" <> formatFloat 0 (atp p) <> " μM)"))
                       , str " ──[ "
                       , withAttr fluxActiveAttr (str ("NRK1:  " <> vNRK1Str))
                       , str " ]──► "
                       , withAttr nmnTargetAttr (str ("(" <> formatFloat 1 (nmn p) <> " μM)"))
                       ]
                , str "                                                               │"
                , hBox [ str "                                                       + [ATP] │ [ "
                       , withAttr fluxActiveAttr (str ("NMNAT: " <> vNMNATStr))
                       , str " ]"
                       ]
                , str "                                                               ▼"
                , hBox [ str "                                                       "
                       , withAttr nadAttr (str ("[ NAD+ ] (" <> formatFloat 1 (nadPlus p) <> " μM)"))
                       ]
                , str "                                                               │"
                , hBox [ str "    ◄──────────── CD38 / SIRTs / PARPs ("
                       , withAttr fluxActiveAttr (str vConsStr)
                       , str ") ─────────────┘"
                       ]
                , str "    ▼ (Recycles to NAM Salvage)"
                ]

-- | Real-time Metabolic Flux Monitor
drawFluxPanel :: CellState -> Widget Name
drawFluxPanel cs =
    let f = fluxes cs
        totalNMNFlux = fluxNAMPT f + fluxNRK1 f
    in borderWithLabel (withAttr headerAttr (str " Reaction Flux (μM / s) ")) $
        padLeftRight 1 $
            vBox
                [ hBox [ str "NAMPT Flux (Salvage)   : ", fill ' ', withAttr fluxActiveAttr (str (formatFloat 3 (fluxNAMPT f))) ]
                , hBox [ str "NRK1 Flux (NR Kinase)  : ", fill ' ', withAttr fluxActiveAttr (str (formatFloat 3 (fluxNRK1 f))) ]
                , hBorder
                , hBox [ withAttr nmnTargetAttr (str "► Net NMN Synthesis    : "), fill ' ', withAttr nmnTargetAttr (str (formatFloat 3 totalNMNFlux)) ]
                , hBorder
                , hBox [ str "NMNAT Flux (NAD+ Synth): ", fill ' ', withAttr nadAttr (str (formatFloat 3 (fluxNMNAT f))) ]
                , hBox [ str "CD38 Flux (Consumption): ", fill ' ', str (formatFloat 3 (fluxCD38 f)) ]
                , hBox [ str "SIRT/PARP Flux         : ", fill ' ', str (formatFloat 3 (fluxSIRT f)) ]
                , hBox [ str "PRPP Biosynthesis Rate : ", fill ' ', str (formatFloat 3 (fluxPRPPSynth f)) ]
                ]

-- | Intracellular metabolite pool concentrations and visual gauges
drawMetabolitePoolPanel :: MetabolitePool -> Widget Name
drawMetabolitePoolPanel p =
    let renderBar label val maxVal unit attr' =
            let ratio = max 0.0 (min 1.0 (val / maxVal))
                barWidth = 14
                filled = round (ratio * fromIntegral barWidth) :: Int
                empty' = barWidth - filled
                barStr = "[" <> replicate filled '█' <> replicate empty' '░' <> "]"
                valStr = formatFloat 1 val <> " " <> unit
            in hBox
                [ withAttr attr' (padRight (Pad 12) (str label))
                , withAttr attr' (str barStr)
                , str " "
                , fill ' '
                , withAttr attr' (str valStr)
                ]
    in borderWithLabel (withAttr headerAttr (str " Intracellular Metabolites (Concentrations) ")) $
        padLeftRight 1 $
            vBox
                [ renderBar "NMN (Target)" (nmn p) 50.0 "μM" nmnTargetAttr
                , renderBar "NAD+        " (nadPlus p) 800.0 "μM" nadAttr
                , renderBar "NAM (Salvage)" (nam p) 100.0 "μM" substrateAttr
                , renderBar "NR (Riboside)" (nr p) 50.0 "μM" substrateAttr
                , renderBar "PRPP        " (prpp p) 40.0 "μM" substrateAttr
                , renderBar "ATP (Energy)" (atp p) 4000.0 "μM" atpAttr
                , renderBar "ADP         " (adp p) 1000.0 "μM" substrateAttr
                ]

-- | Biochemical event and perturbation log
drawLogPanel :: [T.Text] -> Widget Name
drawLogPanel logs =
    let renderLogLine msg =
            let attr = if "⚠️" `T.isInfixOf` msg then statusWarnAttr
                       else if "🎉" `T.isInfixOf` msg then nmnTargetAttr
                       else alertLogAttr
            in withAttr attr (str (T.unpack msg))
        entries = if null logs
                  then [str "No recent events."]
                  else map renderLogLine (take 6 logs)
    in borderWithLabel (withAttr headerAttr (str " Live Biochemical Event Log ")) $
        padLeftRight 1 $
            vBox entries

-- | Tab 2: Enzyme Kinetics, Michaelis Constants, and Regulation
drawEnzymesTab :: AppState -> Widget Name
drawEnzymesTab st =
    let cs = st ^. simState
        reg = enzymes cs
        renderEnzymeRow (Enzyme name _ vm k1 k2 expr inhib enabled) =
            let statusStr' = if not enabled then "[DISABLED]"
                             else if inhib > 0.0 then "[INHIBITED " <> show (round (inhib * 100) :: Int) <> "%]"
                             else "[ACTIVE]"
                statusAttr' = if not enabled || inhib >= 0.5 then statusWarnAttr else statusOkAttr
            in vBox
                [ hBox
                    [ withAttr headerAttr (padRight (Pad 28) (str (T.unpack name)))
                    , str "Status: "
                    , withAttr statusAttr' (str statusStr')
                    , fill ' '
                    , str "Expr: "
                    , str (formatFloat 1 expr <> "x")
                    ]
                , hBox
                    [ str "  ├─ Vmax: "
                    , str (formatFloat 1 vm <> " μM/s")
                    , str "  |  Km1: "
                    , str (formatFloat 1 k1 <> " μM")
                    , if k2 > 0.0 then str ("  |  Km2: " <> formatFloat 1 k2 <> " μM") else str ""
                    , fill ' '
                    , str "Inhibition: "
                    , str (show (round (inhib * 100) :: Int) <> "%")
                    ]
                , hBorder
                ]
    in borderWithLabel (withAttr headerAttr (str " Enzyme Kinetics & Cellular Regulation ")) $
        padLeftRight 2 $
            vBox
                [ str "Enzyme Registry & Regulation Parameters:"
                , str "-----------------------------------------"
                , renderEnzymeRow (nampt reg)
                , renderEnzymeRow (nrk1 reg)
                , renderEnzymeRow (nmnat reg)
                , renderEnzymeRow (cd38 reg)
                , renderEnzymeRow (sirt reg)
                , padTop (Pad 1) $
                    str "Press 'u' to upregulate NAMPT, 'i' to toggle NAMPT inhibitor (FK866), 'c' to toggle CD38 inhibitor."
                ]

-- | Tab 3: Biochemical documentation and Keyboard Shortcut guide
drawHelpTab :: AppState -> Widget Name
drawHelpTab _st =
    borderWithLabel (withAttr headerAttr (str " Biochemical Guide & Controls ")) $
        padLeftRight 2 $
            vBox
                [ withAttr titleAttr (str "NMN (Nicotinamide Mononucleotide) Synthesis Overview:")
                , str "• Salvage Pathway (NAMPT): Primary endogenous route converting Nicotinamide (NAM)"
                , str "  and PRPP into NMN. NAMPT is the rate-limiting enzyme in mammalian cells."
                , str "• NR Kinase Pathway (NRK1): Phosphorylates Nicotinamide Riboside (NR) with ATP"
                , str "  to directly yield NMN, bypassing NAMPT."
                , str "• Downstream Consumption (NMNAT): Converts NMN and ATP into NAD+."
                , str "• NAD+ Turnover (CD38/SIRTs): Cleaves NAD+ back into NAM, closing the salvage cycle."
                , hBorder
                , withAttr headerAttr (str "Interactive Controls & Interventions:")
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "Space")), str "Toggle simulation running / paused" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "t")), str "Single-step simulation tick (when paused)" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "1")), str "Inject 25.0 μM Nicotinamide (NAM) precursor" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "2")), str "Inject 20.0 μM Nicotinamide Riboside (NR)" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "3")), str "Inject 15.0 μM PRPP substrate" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "4")), str "Inject 500.0 μM ATP energy" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "u")), str "Up-regulate NAMPT expression (+25%)" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "i")), str "Toggle NAMPT inhibitor (FK866 simulation)" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "c")), str "Toggle CD38 inhibitor (78c NAD+ sparing simulation)" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "+ / -")), str "Increase / decrease simulation speed (dt)" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "r")), str "Reset cell state to initial baseline" ]
                , hBox [ withAttr keyBindingAttr (padRight (Pad 16) (str "q / Esc")), str "Quit application" ]
                ]

-- | Bottom status line and quick key bindings
drawFooter :: AppState -> Widget Name
drawFooter st =
    let msg = st ^. statusMessage
        speedStr = formatFloat 2 (st ^. simDt) <> "s/tick"
    in vBox
        [ hBox
            [ withAttr keyBindingAttr (str " [Space]")
            , str " Pause/Play  "
            , withAttr keyBindingAttr (str "[1-4]")
            , str " Inject  "
            , withAttr keyBindingAttr (str "[u/i/c]")
            , str " Regulate  "
            , withAttr keyBindingAttr (str "[+/-]")
            , str (" Speed (" <> speedStr <> ")  ")
            , withAttr keyBindingAttr (str "[r]")
            , str " Reset  "
            , withAttr keyBindingAttr (str "[q]")
            , str " Quit"
            ]
        , padTop (Pad 1) $
            withAttr subtitleAttr (str ("Status: " <> T.unpack msg))
        ]

-- | Format floating point number to N decimal places
formatFloat :: Int -> Double -> String
formatFloat decimals val = showFFloat (Just decimals) val ""

