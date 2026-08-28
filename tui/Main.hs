module Main
    ( main
    ) where

import Control.Concurrent (forkIO, threadDelay)
import Control.Monad (forever)
import Brick.BChan (newBChan, writeBChan)
import Brick.Main (customMain)
import qualified Graphics.Vty as V
import qualified Graphics.Vty.CrossPlatform as VCP
import qualified Graphics.Vty.Config as VConfig

import UI.App (app)
import UI.Types (CustomEvent(TickEvent), initialAppState)

main :: IO ()
main = do
    -- Create custom event channel for background simulation ticks
    eventChan <- newBChan 10

    -- Background thread emitting tick events (10 Hz = 100ms interval)
    _ <- forkIO $ forever $ do
        threadDelay 100000 -- 100,000 microseconds = 100ms
        writeBChan eventChan TickEvent

    -- Initialize Vty terminal display (cross-platform vty-crossplatform / vty 6.x)
    let vtyConfig = VConfig.defaultConfig
    initialVty <- VCP.mkVty vtyConfig

    -- Run Brick TUI main loop
    _finalState <- customMain initialVty (VCP.mkVty vtyConfig) (Just eventChan) app initialAppState
    putStrLn "NMN Cell Simulation terminated. Goodbye!"

