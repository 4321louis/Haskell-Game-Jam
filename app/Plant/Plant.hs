-- FUCK I LOVE PLANTS :D

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
{-# LANGUAGE BlockArguments #-}

module Plant.Plant where

import Debug.Trace
import Drawing.Sprites
import Apecs
import Apecs.Extension
import Apecs.Gloss
import Control.Monad
import Misc
import System.Random
import qualified Linear as L

import Audio
import Enemy.Enemy
import Enemy.Hive
import Enemy.Pathfinding
import Worlds
import Plant.Seed
import Linear (V2(..))
import Structure.Structure

type AllPlantComps = (Position, Structure, Sprite, Hp, Plant)

data Plant = RockPlant | Cactus | BigMushroom | Enchanter | SeedSeeker | CorpseFlower | VampireFlower | BirdOfParadise | Mycelium | Necromancer deriving (Eq)
instance Show Plant where 
    show SeedSeeker = "Seed Seeker"
    show Enchanter = "Enchanter"
    show CorpseFlower = "Giant Anthurium"
    show RockPlant = "Not a Rock"
    show VampireFlower = "Vampire Flower"
    show BigMushroom = "Puff Mush"
    show Cactus = "Cactus"
    show BirdOfParadise = "Bird of Paradise"
    show Mycelium = "Mycelium"
    show Necromancer = "Necromancer"
    show _ = ""

instance Component Plant where type Storage Plant = Map Plant

-- Dmg, Fuse, speed
data UndeadBomber = UndeadBomber Float Float Float
instance Component UndeadBomber where type Storage UndeadBomber = Map UndeadBomber
-- Spore Residue from Big Mushroom on death
data SporeResidue = SporeResidue Float deriving (Show)
instance Component SporeResidue where type Storage SporeResidue = Map SporeResidue
--Timer
newtype AttackSpeed = AttackSpeed Float deriving (Show)
instance Component AttackSpeed where type Storage AttackSpeed = Map AttackSpeed

-- Target, speed , turn ratio
data Homer = Homer Entity Float Float deriving (Show)
instance Component Homer where type Storage Homer = Map Homer

-- Timer
newtype Poison = Poison Float deriving (Show)
instance Component Poison where type Storage Poison = Map Poison

-- dmg
data Bullet = PoisonBullet | DamageBullet Float deriving (Show)
instance Component Bullet where type Storage Bullet = Map Bullet


bigMushroomDmg, cactusDmg, doTDmg, enchanterShield, lazerDmg, poisonDuration, attackSpeedModifier :: Float
bigMushroomDmg = 12
cactusDmg = 8
lazerDmg = 100
poisonDuration = 5
doTDmg = 15
enchanterShield = 15
attackSpeedModifier = 1.4


getPlant :: [Seed] -> Plant
getPlant [GreenSeed, GreenSeed] = SeedSeeker
getPlant [GreenSeed, BlueSeed] = Enchanter
getPlant [GreenSeed, RedSeed] = CorpseFlower
getPlant [GreenSeed, Spore] = VampireFlower
getPlant [BlueSeed, BlueSeed] = RockPlant
getPlant [BlueSeed, RedSeed] = Cactus
getPlant [BlueSeed, Spore] = BigMushroom
getPlant [RedSeed, RedSeed] = BirdOfParadise
getPlant [RedSeed, Spore] = Mycelium
getPlant [Spore, Spore] = Necromancer
getPlant [x, y] = getPlant [y, x]
getPlant _ = SeedSeeker

getSeed :: Plant -> [Seed]
getSeed SeedSeeker = [GreenSeed, GreenSeed]
getSeed Enchanter = [GreenSeed, BlueSeed]
getSeed CorpseFlower = [GreenSeed, RedSeed]
getSeed VampireFlower = [GreenSeed, Spore]
getSeed RockPlant = [BlueSeed, BlueSeed]
getSeed Cactus = [BlueSeed, RedSeed]
getSeed BigMushroom = [BlueSeed, Spore]
getSeed BirdOfParadise = [RedSeed, RedSeed]
getSeed Mycelium = [RedSeed, Spore]
getSeed Necromancer = [Spore, Spore]
getSeed _ = [GreenSeed, GreenSeed]

getPlantSprite :: Plant -> Picture
getPlantSprite Cactus = cactus
getPlantSprite Enchanter = enchanter
getPlantSprite SeedSeeker = seedSeeker
getPlantSprite RockPlant = rockPlant
getPlantSprite CorpseFlower = attackSpeedFlower
getPlantSprite VampireFlower = vampireFlower
getPlantSprite BigMushroom = aoeMushroom
getPlantSprite BirdOfParadise = birdOfParadise
getPlantSprite Mycelium = mycelium
getPlantSprite Necromancer = necromancer
getPlantSprite _ = seedSeeker

newPlant :: (HasMany w [Plant, Position, Hp, Sprite, Structure, EntityCounter, AttackSpeed]) => Plant -> V2 Float -> System w Entity
newPlant Cactus pos = newEntity (Cactus, Position pos, Hp 20 20 0, Sprite cactus)
newPlant Enchanter pos = newEntity (Enchanter, Position pos, Hp 10 10 0, Sprite enchanter, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant SeedSeeker pos = newEntity (SeedSeeker, Position pos, Hp 20 20 0, Sprite seedSeeker, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant RockPlant pos = newEntity (RockPlant, Position pos, Hp 80 80 0, Sprite rockPlant, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant CorpseFlower pos = newEntity (CorpseFlower, Position pos, Hp 20 20 0, Sprite attackSpeedFlower, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant VampireFlower pos = newEntity (VampireFlower, Position pos, Hp 20 20 0, Sprite vampireFlower, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant BigMushroom pos = newEntity (BigMushroom, Position pos, Hp 20 20 0, Sprite aoeMushroom, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant BirdOfParadise pos = newEntity (BirdOfParadise, Position pos, Hp 20 20 0, Sprite birdOfParadise, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]), AttackSpeed 0)
newPlant Mycelium pos = newEntity (Mycelium, Position pos, Hp 20 20 0, Sprite mycelium, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))
newPlant Necromancer pos = newEntity (Necromancer, Position pos, Hp 20 20 0, Sprite necromancer, Structure ((pos+) <$> [V2 64 0, V2 (-64) 0, V2 0 64,V2 0 (-64)]))

doPlants :: (HasMany w [Enemy, Position, Plant, Time, Hp, EntityCounter, Sprite, AttackSpeed, Seed, Particle, UndeadBomber, SporeResidue, PathFinder, Hive, Velocity, AnimatedSprite, Poison, Bullet, Homer])=> Float -> System w ()
doPlants dT = do
    doAttacks dT
    doOnDeaths

doAttacks :: (HasMany w [Enemy, Position, Plant, Time, Hp, EntityCounter, Sprite, AttackSpeed, Seed, Particle, AnimatedSprite, UndeadBomber, SporeResidue, PathFinder, Hive, Velocity, Poison, Bullet, Homer])=> Float -> System w ()
doAttacks dT = do
    cmapM_ $ \(plant::Plant, Position pos, ety) -> do
        case plant of
            Cactus -> doCactusAttack dT pos ety
            Enchanter -> doEnchanting dT pos
            SeedSeeker -> doSeedSeeking dT pos
            BigMushroom -> doBigMushroomAttack dT pos ety
            BirdOfParadise -> doLazerAttack dT pos ety
            RockPlant -> doRockPlant dT ety
            CorpseFlower -> doAttackSpeedBuff dT pos
            VampireFlower -> doVampireAttack dT pos ety
            Mycelium -> doDoTAttack dT pos ety
            _ -> return ()
    stepAttackSpeedTimer dT
    stepPoisonTimer dT
    doBulletCollision
    doUndeadBombers dT
    doSporeResidue
    stepSporeTimer dT

doOnDeaths :: (HasMany w [Enemy, Position, Velocity, UndeadBomber, PathFinder, Hive, Plant, Time, Hp, EntityCounter, Sprite, Seed, Particle, AnimatedSprite, SporeResidue]) => System w ()
doOnDeaths = do
    cmapM_ $ \(Enemy {}, Position posE, etyE, Hp hp _ _) -> do
        when (hp <= 0) $ do
            (dist, closest) <- cfold (\min@(minDist,_) (p::Plant, Position posP, etyP) ->

                    let nDist = L.norm (posP - posE)
                    in if isOnDeath p && nDist < minDist then (nDist,etyP) else min) (10000,0)
            when (dist<700) $ do
                (plant, Position pos) <- get closest
                case plant of
                    VampireFlower -> vampireOnDeath pos etyE
                    BigMushroom -> doBigMushroomOnDeath pos posE
                    Necromancer -> necromancyOnDeath pos etyE
                    _ -> return ()

isOnDeath VampireFlower = True
isOnDeath BigMushroom = True
isOnDeath Necromancer = True
isOnDeath _ = False

stepPoisonTimer :: (HasMany w [Position, Velocity, Poison, Enemy, Hp, AnimatedSprite, Particle, Sprite, EntityCounter, Time]) => Float -> System w ()
stepPoisonTimer dT = cmapM $ \(Poison t, Position pos, Enemy {}, Hp hp _ _, etyE) ->
    if t < 0
        then do
            return $ Right $ Not @Poison
        else do
            triggerEvery dT 0.5 0 $ do
                newEntity (Position pos, dotEffect, Particle 0.4)
                modifyM etyE (\(Enemy {}, pos, hp) -> dealDamage pos hp doTDmg)
            return $ Left $ Poison (t-dT)

doBulletCollision :: (HasMany w [Position, Bullet, Enemy, Hp, Velocity, EntityCounter, Homer, Particle, Sprite, Poison]) => System w ()
doBulletCollision =
    cmapM $ \(Enemy {}, Position posE, etyE) ->
        cmapM $ \(b::Bullet, Position posB, etyB) ->
            when (L.norm (posE - posB) < 10) $ do
                case b of
                    (DamageBullet dmg) -> do
                        modifyM etyE (\(Enemy {}, pos, hp) -> dealDamage pos hp dmg)
                    PoisonBullet -> modify etyE (\(Enemy {}) -> Poison poisonDuration)
                destroy etyB (Proxy @(Bullet, Position, Velocity, Homer, Sprite))

doSporeResidue :: (HasMany w [Enemy, Position, Velocity, Hp, EntityCounter, Sprite, Particle, AnimatedSprite, SporeResidue]) => System w ()
doSporeResidue =
    cmapM $ \(Position pos, SporeResidue _, etyS) ->
        cmapM $ \(Enemy {},Hp hp _ _, Position posE, etyE) ->
            when (L.norm (posE - pos) < tileRange 0 && hp > 0) $ do
                modifyM etyE (\(Enemy {}, pos, hp) -> dealDamage pos hp bigMushroomDmg)
                destroy etyS (Proxy @(Position, SporeResidue, AnimatedSprite, Sprite))

stepSporeTimer :: (HasMany w [Position, EntityCounter, Sprite, AnimatedSprite, SporeResidue]) => Float -> System w ()
stepSporeTimer dT = cmapM $ \(SporeResidue t, Position pos) ->
    if t < 0
        then do
            return $ Right $ (Not @(SporeResidue, Position, AnimatedSprite, Sprite))
        else do
            return $ Left $ SporeResidue (t-dT)


doUndeadBombers :: (HasMany w [PathFinder, Position, Velocity, UndeadBomber, Sprite, Enemy, Hp, AnimatedSprite, Particle, EntityCounter]) => Float -> System w ()
doUndeadBombers dT = cmapM $
    \(p@(PathFinder _ pathNodes), Position pos, Velocity _, UndeadBomber dmg fuse speed) ->
        if fuse <= 0
        then do
            cmapM $ \(Enemy {}, p@(Position posE), hp) -> if L.norm (posE - pos) < tileRange 1 then dealDamage p hp dmg else return hp
            newEntity (Position pos, aoeEffectNecro, Particle 1)
            return $ Right (Not @(Sprite,PathFinder,Position,Velocity,UndeadBomber,AnimatedSprite))
        else do
            newFuse <- (`cfold` fuse) $ \f (Enemy {},Position posE) -> if L.norm (posE - pos) < tileRange 1 then f - dT else f
            if null pathNodes
            then return $ Left (PathFinder Nothing [],Velocity (V2 0 0),UndeadBomber dmg newFuse speed, AnimatedSprite 10 [necrokukaswf1])
            else do
                let newVelocity@(V2 vx _) = (L.^* speed) . L.normalize $ head pathNodes - pos
                return $ Left (p,Velocity newVelocity,UndeadBomber dmg newFuse  speed, if vx <0 then necroKukasWalkLeft else necroKukasWalkRight )

doRockPlant :: (HasMany w [Time, Hp, Velocity, Position, Particle, Sprite, EntityCounter]) => Float -> Entity -> System w ()
doRockPlant dT ety = triggerEvery dT 1 0.6 $ modifyM ety (\(a,b) -> healHp a b 1)

doAttackSpeedBuff :: (HasMany w [Plant, Position, Time, Hp, Sprite, Particle, EntityCounter, AttackSpeed]) => Float -> V2 Float -> System w ()
doAttackSpeedBuff dT pos = triggerEvery dT 2 0.6 $ do
    cmapM $  \(p::Plant, Position posP) -> if L.norm (pos - posP) < tileRange 1 && elem p [Cactus, BirdOfParadise, BigMushroom, Mycelium, VampireFlower] then do
        xoff <- liftIO $ randomRIO (-16,16)
        yoff <- liftIO $ randomRIO (-16,16)
        newEntity (Sprite attackSpeedEffect, Position (posP+V2 xoff yoff), Particle 1)
        return $ Right $ AttackSpeed 4
        else return $ Left ()

stepAttackSpeedTimer :: (Has w IO AttackSpeed) => Float -> System w ()
stepAttackSpeedTimer dT = cmap $ \(AttackSpeed t) ->
    if t < 0
        then Right $ Not @AttackSpeed
        else Left  $ AttackSpeed (t-dT)

doCactusAttack :: (HasMany w [Enemy, Position, Velocity, Plant, Time, Hp, AttackSpeed, Particle, Sprite, EntityCounter]) => Float -> V2 Float -> Entity -> System w ()
doCactusAttack dT posP ety = do
    hasAttackBuff <- exists ety (Proxy @AttackSpeed)
    let rate = 0.5/if hasAttackBuff then attackSpeedModifier else 1
    triggerEvery dT rate 0.6 $ do
        cmapM_ $ \(Enemy {}, Position posE, etyE) -> when (L.norm (posE - posP) < tileRange 0) $
            modifyM etyE (\(Enemy {}, pos, hp) -> dealDamage pos hp cactusDmg)

doBigMushroomAttack :: (HasMany w [Enemy, Position, Velocity, Plant, Time, Hp, AnimatedSprite, EntityCounter, Particle, Sprite, AttackSpeed]) => Float -> V2 Float -> Entity -> System w ()
doBigMushroomAttack dT posP ety = do
    hasAttackBuff <- exists ety (Proxy @AttackSpeed)
    let rate = 2.5/if hasAttackBuff then attackSpeedModifier else 1
    triggerEvery dT rate 0.6 $ do
        cmapM_ $ \(Enemy {}, Position posE, etyE) -> when (L.norm (posE - posP) < tileRange 2) $ do
            newEntity (Position posP, aoeEffect, Particle 2)
            modifyM etyE (\(Enemy {}, pos, hp) -> dealDamage pos hp bigMushroomDmg)

doBigMushroomOnDeath :: (HasMany w [Enemy, Position, Plant, Time, Hp, AnimatedSprite, EntityCounter, Particle, SporeResidue]) => V2 Float -> V2 Float -> System w ()
doBigMushroomOnDeath posP pos =
    when (L.norm(posP - pos) < tileRange 2) $ do
        void $ newEntity (Position pos, SporeResidue 30, aoeEffectMini)

doEnchanting :: (HasMany w [Plant, Position, Velocity, Time, Hp, Sprite, Particle, EntityCounter]) => Float -> V2 Float -> System w ()
doEnchanting dT posEch = triggerEvery dT 6 0.6 $ do
    cmapM_ $ \(_::Plant, Position posP, etyP) -> when (L.norm (posEch - posP) < tileRange 1) $
        (do
            modifyM etyP $ \(_::Plant, pos, hp) -> shieldHp pos hp enchanterShield
            xoff <- liftIO $ randomRIO (-16,16)
            yoff <- liftIO $ randomRIO (-16,16)
            void $ newEntity (Sprite shieldEffect, Position (posP+V2 xoff yoff), Particle 2))

doSeedSeeking :: (HasMany w [Seed, Sprite, Plant, Position, Time, EntityCounter]) => Float -> V2 Float -> System w ()
doSeedSeeking dT pos = triggerEvery dT 120 0.6 $ do
    seed <- liftIO $ randomRIO (0,3)
    xoff <- liftIO $ randomRIO (-32,32)
    yoff <- liftIO $ randomRIO (-32,-1)
    newEntity ([GreenSeed,RedSeed,BlueSeed,Spore]!! seed, Position (V2 xoff yoff + pos), Sprite $ [greenSeed,redSeed,blueSeed,spore] !! seed )

doDoTAttack :: (HasMany w [Enemy, Position, Time, Homer,  Sprite, EntityCounter, AttackSpeed, Bullet, Poison, Velocity]) => Float -> V2 Float -> Entity -> System w ()
doDoTAttack dT posP ety = do
    hasAttackBuff <- exists ety (Proxy @AttackSpeed)
    let rate = 3/if hasAttackBuff then attackSpeedModifier else 1
    triggerEvery dT rate 0.6 $ do
        (cdist, target, _) <- cfoldM (\min@(minDist,_,minPois) (Enemy {}, Position posE, etyE) -> do
                let nDist = L.norm (posP - posE)
                poisoned <- exists etyE (Proxy @Poison)
                Poison poisonDuration <- if poisoned then get etyE else return (Poison 0)
                return $ if nDist < tileRange 5 && ( poisonDuration < minPois || (poisonDuration == minPois && nDist < minDist)) then (nDist,etyE,poisonDuration) else min) (10000,0,1000)
        when (cdist < tileRange 5) $ do
                void $ newEntity (Sprite dotBullet, PoisonBullet, Position posP, Velocity (V2 0 0), Homer target 100 0.1)


doLazerAttack :: (HasMany w [Enemy, Position, Velocity, Time, Hp, Particle, Sprite, EntityCounter, AttackSpeed]) => Float -> V2 Float -> Entity -> System w ()
doLazerAttack dT posP ety = do
    hasAttackBuff <- exists ety (Proxy @AttackSpeed)
    let rate = 2.5/if hasAttackBuff then attackSpeedModifier else 1
    triggerEvery dT rate 0.6 $ do
        (cdist, closest) <- cfold (\min@(minDist,_) (Enemy {}, Position posE, etyE) ->
                let nDist = L.norm (posP - posE)
                in if nDist < minDist then (nDist,etyE) else min) (10000,0)
        when (cdist < tileRange 2) $ do
            Position posE <- get closest
            let V2 lx ly = posE - posP
                (ox,oy) = if lx < 0 then (-22,28) else (11,19)
                lazerLine = (color orange $ Line [(ox,oy),(lx,ly)]) <> (color red $ Line [(ox,oy+2),(lx,ly)]) <> (color red $ Line [(ox,oy-2),(lx,ly)])
            newEntity (Particle 0.25, Position posP, Sprite lazerLine)
            modifyM closest $ \(Enemy {}, pos, hp) -> dealDamage pos hp lazerDmg


doVampireAttack :: (HasMany w [Enemy, Position, Time, Hp, Bullet, Sprite, Velocity, Homer, EntityCounter, AttackSpeed]) => Float -> V2 Float -> Entity -> SystemT w IO ()
doVampireAttack dT posP ety = do
    hasAttackBuff <- exists ety (Proxy @AttackSpeed)
    let rate = 3/if hasAttackBuff then attackSpeedModifier else 1
    triggerEvery dT rate 0.6 $ do
        (cdist, target) <- cfold (\min@(minDist,_) (Enemy {}, Position posE, etyE) ->
                let nDist = L.norm (posP - posE)
                in if nDist < minDist then (nDist,etyE) else min) (10000,0)
        when (cdist < tileRange 4) $ do
                void $ newEntity (Sprite vampBullet, DamageBullet 40, Position posP, Velocity (V2 0 0), Homer target 100 0.1)


necromancyOnDeath :: (HasMany w [Enemy, Position, Velocity, UndeadBomber, PathFinder, Hive, Time, Hp, Particle, Sprite, EntityCounter]) => V2 Float -> Entity -> System w ()
necromancyOnDeath posP ety = do
    (Position posE, Hp _ maxHp _, Enemy _ speed _) <- get ety
    when (L.norm (posP - posE) < 3.5*64) $ do
        roll <- liftIO $ randomRIO (1::Int,100)
        when (roll <= 70) $ do
            hives <- (`cfold` []) $ \hs (_h::Hive, Position pos) -> pos:hs
            let V2 lx ly = posE - posP
                (ox,oy) = (0,0)
                lazerLine = color (greyN 0.3) (Line [(ox,oy),(lx,ly)]) <> color black (Line [(ox,oy),(lx+2,ly)]) <> color black (Line [(ox,oy),(lx-2,ly)])
            newEntity (Particle 0.25, Position posP, Sprite lazerLine)
            void $ newEntity (Position posE, Velocity (V2 0 0), UndeadBomber (25+maxHp/10) 4 speed, PathFinder (Just hives) [])


vampireOnDeath :: (HasMany w [Position, Velocity, Hp, Particle, Sprite, EntityCounter, Plant]) => V2 Float -> Entity -> System w ()
vampireOnDeath posP ety = do
    (Position posE, Hp _ maxHp _) <- get ety
    when (L.norm (posP - posE) < tileRange 4) $ do
        (tHp, target) <- cfold (\min@(minHp,_) (_::Plant, Position posT, Hp hp max _, ety) ->
            let nDist = L.norm (posP - posT)
            in if nDist < tileRange 2 && hp < minHp && hp < max then (hp,ety) else min) (10000,0)
        when (tHp /= 10000) $ do
            Position posT <- get target
            let V2 lx ly = posT - posE
                (ox,oy) = (0,0)
                lazerLine = color white (Line [(ox,oy),(lx,ly)]) <> color green (Line [(ox,oy),(lx+2,ly)]) <> color green (Line [(ox,oy),(lx-2,ly)])
            newEntity (Particle 0.25, Position posE, Sprite lazerLine)
            modifyM target (\(a,b) -> healHp a b (maxHp/50))

stepHomers :: (HasMany w [Velocity, Position, Homer, Sprite, Bullet]) => System w ()
stepHomers = cmapM $ \(Homer target speed turnRatio, Velocity v, Position pos) -> do
    targetAlive <- exists target (Proxy @Position)
    if targetAlive
    then do
        Position posT <- get target
        return $ Left $ Velocity ((speed L.*^) . L.normalize $ (v L.^* (1-turnRatio) + turnRatio L.*^ (posT-pos)))
    else return $ Right (Not @(Velocity, Position, Homer, Sprite, Bullet))

destroyDeadStructures :: (HasMany w [Sprite, Plant, Position, Paths, PathFinder, Structure, Hp, Camera]) => System w ()
destroyDeadStructures = do
    pathingChanged <- cfoldM (\b (Structure _, Hp hp _ _ , ety, Position pos) -> do
        when (hp <= 0) $ do
            playIOSoundEffectAt pos explosion
            destroy ety (Proxy @AllPlantComps )
        return (b || hp <= 0)) False
    when pathingChanged $ do
        updateGoals
        clearPaths