{-# LANGUAGE TemplateHaskell #-}
module UI.Types
    ( -- * Brick Resource Names & Events
      Name(..)
    , CustomEvent(..)
    , Tab(..)
      -- * UI State
    , AppState(..)
    , initialAppState
      -- * Lenses
    , simState
    , isPaused
    , simDt
    , activeTab
    , selectedEnzyme
    , statusMessage
    ) where

import Lens.Micro.TH (makeLenses)
import Data.Text (Text)
import NMN.Types
import NMN.Simulation (defaultCellState)

-- | Resource names for Brick widgets
data Name
    = MainViewport
    | PathwayPanel
    | MetabolitePanel
    | FluxPanel
    | EnzymePanel
    | LogPanel
    deriving stock (Eq, Ord, Show)

-- | Custom asynchronous events sent to Brick event loop
data CustomEvent
    = TickEvent
    | LogMessageEvent !Text
    deriving stock (Eq, Show)

-- | Available navigation tabs
data Tab
    = TabOverview
    | TabEnzymes
    | TabHelp
    deriving stock (Eq, Ord, Show, Enum, Bounded)

-- | Main UI State record
data AppState = AppState
    { _simState       :: !CellState   -- ^ Biochemical simulation state
    , _isPaused       :: !Bool        -- ^ Whether simulation timer is running
    , _simDt          :: !Double      -- ^ Time delta (seconds) integrated per tick
    , _activeTab      :: !Tab         -- ^ Active view tab
    , _selectedEnzyme :: !EnzymeType  -- ^ Selected enzyme for detail inspection
    , _statusMessage  :: !Text        -- ^ Transient status line
    } deriving stock (Eq, Show)

makeLenses ''AppState

-- | Initial App State
initialAppState :: AppState
initialAppState = AppState
    { _simState       = defaultCellState
    , _isPaused       = False
    , _simDt          = 0.2           -- 0.2s simulation time per tick
    , _activeTab      = TabOverview
    , _selectedEnzyme = NAMPT_Enzyme
    , _statusMessage  = "Simulation running. Press Space to pause, 1-4 to inject substrates, 'h' for help."
    }

