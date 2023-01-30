--Putting it all together and some more specific features

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-missing-export-lists #-}


import Apecs
import Apecs.Gloss
import Control.Monad
import Linear (V2(..))
import qualified Linear as L
import Graphics.Gloss.Game hiding (play)
import Graphics.Gloss.Export.Image
import Codec.Picture

import Drawing.Sprites
import Drawing.Camera
import Misc
import Player
import Worlds
import Apecs.Extension
import Grid.Implementation
import Grid.Tile
import qualified Data.Map as M
import Debug.Trace (trace)

data Target = Target deriving (Show)
instance Component Target where type Storage Target = Map Target


makeWorld "World" [''Position, ''Velocity, ''MovementPattern, ''Sprite, ''AnimatedSprite, ''Player, ''Target, ''Particle, ''Score, ''Time, ''Inputs, ''Camera]


type SystemW a = System World a

xmin, xmax :: Float
xmin = -110
xmax = 110


playerPos :: V2 Float
playerPos = V2 0 0

initialize :: SystemW ()
initialize = do
    _playerEty <- newEntity (Player, Position playerPos, Velocity 0, Sprite playerSprite)
    modify global $ \(Camera pos _) -> Camera pos 1.6
    return ()

initialiseGrid :: (HasMany w [Position, Velocity, EntityCounter, Sprite]) => Grid -> [(Int,Int)] -> System w ()
initialiseGrid grid coords  = do
    let 
        sprite = getGridSprite grid coords
        -- sprite =
    void $ newEntity (Position (V2 0 0), Sprite sprite)
    -- mapM_ void [newEntity (Position (V2 (64*fromIntegral x) (64*fromIntegral y)), Sprite $ pic (M.findWithDefault erTile (x,y) grid))| (x,y) <-coords]

clampPlayer :: SystemW ()
clampPlayer = cmap $ \(Player, Position (V2 x y)) ->
    Position (V2 (min xmax . max xmin $ x) y)

clearTargets :: SystemW ()
clearTargets = cmap $ \entity@(Target, Position (V2 x _), MovementPattern _) ->
    if x < xmin || x > xmax
        then Nothing
        else Just entity

step :: Float -> SystemW ()
step dT = do
    incrTime dT
    stepPosition dT
    animatedSprites dT
    stepParticles dT
    camOnPlayer

draw :: Picture -> SystemW Picture
draw bg = do
    sprites <- foldDraw $ \(Position pos, Sprite p) -> translateV2 pos p
    particles <- foldDraw $
        \(Particle _, Velocity (V2 vx vy), Position pos) ->
            translateV2 pos . color orange $ Line [(0, 0), (vx / 10, vy / 10)]
    return $ bg <> sprites <> particles

main :: IO ()
main = do
    content <- readFile "./src/meta.txt"
    let size = 25
        tileOptions = readTilesMeta content
        coords = createGrid size size
    grid <- trace "Doing wave collapse" $ (`doWaveCollapse` coords) $ collapseBaseGrid $ createPreTileGrid tileOptions coords
    background <- optimisePicture (64*size,64*size) . translate 32 32 $ getGridSprite grid coords
    
    
    w <- initWorld
    runWith w $ do
        initialize
        trace "Finished wave collapse" $ play (InWindow "Haskill Issue" (1280, 720) (10, 10)) black 60 (draw (translate (fromIntegral $ -32*size) (fromIntegral $ -32*size) background)) preHandleEvent step
