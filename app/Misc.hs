-- Misc general functions

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

module Misc where

import Worlds (Position(..),Time(..))

import Apecs
import Apecs.Gloss
import Control.Monad

import Linear (V2(..))
import System.Random (randomRIO)
import Codec.Picture (DynamicImage(ImageRGBA8), savePngImage)
import Graphics.Gloss.Export (exportPictureToFormat)
import Graphics.Gloss.Game (png)
import qualified Data.Vector as V
import Control.Monad (replicateM)
import Data.Function (on)
import Data.List     (sortBy)
import System.Random (randomRIO)

translatePos :: Position -> Picture -> Picture
translatePos (Position (V2 x y)) = translate x y
translateV2 :: V2 Float -> Picture -> Picture
translateV2 (V2 x y) = translate x y

cursorPosToReal :: Camera -> V2 Float -> V2 Float
cursorPosToReal (Camera cameraOffset cameraScale) (V2 a b) = cameraOffset + V2 (a/cameraScale) (b/cameraScale)


tileRange :: Int -> Float
tileRange x = sqrt $ (64 * fromIntegral x + 32)**2 + (64 * fromIntegral x + 32)**2

triggerEvery :: (Has w IO Time) => Float -> Float -> Float -> System w a -> System w ()
triggerEvery dT period phase sys = do
    Time t <- get global
    let t' = t + phase
        trigger = floor (t' / period) /= floor ((t' + dT) / period)
    when trigger $ void sys

triggerAt :: (Has w IO Time) => Float -> Float -> System w a -> System w ()
triggerAt dT time sys = do
    Time t <- get global
    when (t <= time && t+dT > time) $ void sys

floorMultiple :: RealFrac a => a -> Int -> Int
floorMultiple val mult =  mult * div (floor val) mult

atRandIndex :: V.Vector b -> IO b
atRandIndex l = do
    let n = V.length l

    i <- randomRIO (0, n - 1)
    if n <= 0 then error "Can't pick a random element of an empty list" else return $ l V.! i

shuffleList :: [a] -> IO [a]
shuffleList xs = do
    ys <- replicateM (length xs) $ randomRIO (1 :: Int, 100000)
    pure $ map fst $ sortBy (compare `on` snd) (zip xs ys)

concatRep :: Int -> [a] -> [a]
concatRep n = concat . replicate n

optimisePicturewithRes :: (Int,Int) -> (Int,Int) -> Picture -> IO Picture
optimisePicturewithRes (screenX,screenY) (picX,picY) picture =
    let corneredPic = translate (-fromIntegral screenX/2) (-fromIntegral screenY/2) picture
        export snapSize = exportPictureToFormat (\fp img->savePngImage fp (ImageRGBA8 img)) snapSize red
        intervals n d = zip (takeWhile (<n-d) (iterate (+d) 0)) (repeat d) ++ [(d*div n d,mod n d)]
        allSnapsDimensions = [(xOff,yOff,snapLen,snapHei) | (xOff,snapLen) <- intervals picX screenX, (yOff,snapHei) <- intervals picY screenY]
        loadSnap (xOff,yOff,snapLen,snapHei) =
            do
                let fName = "./tmp/"++show xOff++" "++show yOff ++".png"
                    xTrans = fromIntegral (snapLen-screenX)/2 + fromIntegral xOff
                    yTrans = fromIntegral (snapHei-screenY)/2 + fromIntegral yOff
                export (snapLen,snapHei) fName (translate (-xTrans) (-yTrans) corneredPic)
                return $ translate xTrans yTrans $ png fName
    in
        do
            pic <- foldMap loadSnap allSnapsDimensions
            return $ translate (fromIntegral screenX/2) (fromIntegral screenY/2) pic

optimisePicture :: (Int,Int) -> Picture -> IO Picture
optimisePicture = optimisePicturewithRes (1500,1000)

