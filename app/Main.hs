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
import Debug.Time
import Enemy.Pathfinding


makeWorld "World" [''Position, ''Velocity, ''MovementPattern, ''Paths, ''PathFinder, ''Sprite, ''AnimatedSprite, ''Player, ''Bullet, ''Particle, ''Score, ''Time, ''Inputs, ''Camera]


type SystemW a = System World a

xmin, xmax :: Float
xmin = -110
xmax = 110

hitBonus, missPenalty :: Int
hitBonus = 100
missPenalty = 40

playerPos, scorePos :: V2 Float
playerPos = V2 0 0
scorePos = V2 xmin (-170)

initialize :: PathfindGraph -> SystemW ()
initialize pathGraph= do
    _playerEty <- newEntity (Player, Position playerPos, Velocity 0, Sprite playerSprite)
    modify global $ \(Camera pos _) -> Camera pos 1.6
    modify global $ \(Paths _) -> Paths pathGraph
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

clearBullets :: SystemW ()
clearBullets = cmap $ \(Bullet, Position (V2 _ y), Score s) ->
    if y > 170
        then Right (Not @(Bullet, Kinetic), Score (s - missPenalty))
        else Left ()

-- handleCollisions :: SystemW ()
-- handleCollisions =
--     cmapM_ $ \(Target, Position posT, etyT) ->
--         cmapM_ $ \(Bullet, Position posB, etyB) ->
--             when (L.norm (posT - posB) < 10) $ do
--                 destroy etyT (Proxy @(Target, Kinetic))
--                 destroy etyB (Proxy @(Bullet, Kinetic))
--                 spawnParticles 15 (Position posB) (-500, 500) (200, -50)
--                 modify global $ \(Score x) -> Score (x + hitBonus)
--                 modify global $ \(Camera pos cScale) -> Camera pos (0.85*cScale)

step :: Float -> SystemW ()
step dT = do
    incrTime dT
    stepPosition dT
    animatedSprites dT
    stepParticles dT
    camOnPlayer
    doPathFinding
    triggerEvery dT 5 3 $  newEntity (Position (V2 600 600), Sprite targetSprite2, Velocity (V2 0 0), PathFinder (Just [(0,0)]) [])

draw :: Picture -> SystemW Picture
draw bg = do
    sprites <- foldDraw $ \(Position pos, Sprite p) -> translateV2 pos p
    particles <- foldDraw $
        \(Particle _, Velocity (V2 vx vy), Position pos) ->
            translateV2 pos . color orange $ Line [(0, 0), (vx / 10, vy / 10)]

    cam <- get global
    Score s <- get global
    let score = color white . pictureOnHud cam . translateV2 scorePos . scale 0.1 0.1 . Text $ "Score: " ++ show s

    return $ bg <> sprites <> score <> particles

main :: IO ()
main = do
    content <- readFile "./src/meta.txt"
    let size = traceTimer "WFCollapse" 20
        tileOptions = readTilesMeta content
        graphicTileCoords = traceTimer "WFCollapse" createGrid size size
        pathFindCoords = map (toRealCoord size) graphicTileCoords
        
        
    grid <- startTimer "WFCollapse" $ (`doWaveCollapse` graphicTileCoords) $ traceTimer "WFCollapse" $ collapseBaseGrid $ traceTimer "WFCollapse" $ createPreTileGrid tileOptions graphicTileCoords
    background <- startTimer "GridImage" optimisePicture (64*size,64*size) . translate 32 32 $ getGridSprite (traceTimer "GridImage" $ traceTimer "WFCollapse" grid) graphicTileCoords
    
    let getTile = tileOfCoord grid size
    
    w <- initWorld
    runWith w $ do
        
        startTimer "GraphCreation" $ initialize (traceTimer "GraphCreation" $ generateGraph (traceTimer "GraphCreation" getTile) pathFindCoords)
        play (InWindow "Haskill Issue" (1280, 720) (10, 10)) black 60 (draw (traceTimer "GridImage"  $ translate (fromIntegral $ -32*size) (fromIntegral $ -32*size) background)) preHandleEvent step
