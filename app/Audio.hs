
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Audio where

import System.Environment
import System.FilePath
import qualified Data.ByteString as SB
import Control.Concurrent
import Control.Monad

import Sound.ProteaAudio
import Apecs
import Apecs.Gloss (Camera(Camera))
import Linear (V2 (..),norm)
import Worlds

musicDir :: String
musicDir = "./assets/Audio/Music/"
menuLoop, menuLoopIntro, gameLoop, gameLoopIntro :: IO Sample
menuLoopIntro = sampleFromFile (musicDir ++ "Sunny_day_intro.ogg") 0.3
menuLoop = sampleFromFile (musicDir ++ "Sunny_day_loop.ogg") 0.3
gameLoopIntro = sampleFromFile (musicDir ++ "Uncharted_Encounter_intro.ogg") 0.3
gameLoop = sampleFromFile (musicDir ++ "Uncharted_Encounter_loop.ogg") 0.3

effectsDir :: String
effectsDir = "./assets/Audio/Effects/"
pew, fastAttack, kukasAttack, eatSound, explosion, invokeSeed, kukasDeath, pickUpSeed, laserGun, plantPlant :: IO Sample
pew = sampleFromFile (effectsDir ++ "PEW.wav") 1.0
fastAttack = sampleFromFile (effectsDir ++ "basic attack.ogg") 1.0
kukasAttack = sampleFromFile (effectsDir ++ "kukas attack.ogg") 1.0
eatSound = sampleFromFile (effectsDir ++ "eating sound question mark.ogg") 1.0
explosion = sampleFromFile (effectsDir ++ "generic explosion.ogg") 1.0
invokeSeed = sampleFromFile (effectsDir ++ "invoke seed.ogg") 1.0
kukasDeath = sampleFromFile (effectsDir ++ "kukas death.ogg") 1.0
pickUpSeed = sampleFromFile (effectsDir ++ "pick up seed.ogg") 1.0
laserGun = sampleFromFile (effectsDir ++ "laser gun 1.ogg") 1.0
plantPlant = sampleFromFile (effectsDir ++ "plant plant.ogg") 1.0

playSoundEffect :: Sample -> System w Sound
playSoundEffect = liftIO . (\s -> soundPlay s 1 1 0 1)
playIOSoundEffect :: IO Sample -> System w Sound
playIOSoundEffect iosample = do
    sample <- liftIO iosample
    liftIO $ soundPlay sample 1 1 0 1

playIOSoundEffectAt :: Has w IO Camera => V2 Float -> IO Sample -> System w Sound
playIOSoundEffectAt location iosample = do
    sample <- liftIO iosample
    (Camera playerPos _) <- get global
    let leftEar = playerPos - V2 600 0
        rightEar = playerPos + V2 600 0
        leftVol = 1/(1+2**(0.01*norm (location - leftEar) - 12))
        rightVol = 1/(1+2**(0.01*norm (location - rightEar) - 12))
    liftIO $ soundPlay sample leftVol rightVol 0 1

waitSound :: Sound -> IO ()
waitSound s = do
    playing <- soundActive s
    when playing $ do
        threadDelay (div oneSec 100)
        waitSound s

oneSec :: Int
oneSec = 1000000 -- micro seconds

initializeAudio :: IO ()
initializeAudio = do
    result <- initAudio 128 44100 1024 -- max channels, mixing frequency, mixing buffer size
    unless result $ fail "failed to initialize the audio system"

    void $ forkIO $ do 
        gameLoop <- gameLoop
        gameLoopIntro <- gameLoopIntro
        intro <- soundPlay gameLoopIntro 1 1 0 1
        waitSound intro
        _musicTrack <- soundLoop gameLoop 1 1 0 1
        return ()
    