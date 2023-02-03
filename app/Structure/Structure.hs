-- Things that can be attacked by enemies

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Structure.Structure where

import Apecs
import Apecs.Extension
import Enemy.Pathfinding
import Linear (V2(..))

-- HP, attack positions
newtype Structure = Structure [V2 Float] deriving (Show)
instance Component Structure where type Storage Structure = Map Structure

data Base = Base deriving (Show)
instance Component Base where type Storage Base = Unique Base

updateGoals :: (HasMany w [Paths, Structure]) => System w ()
updateGoals = do
    modify global $ \(Paths graph _) -> Paths graph []
    cmapM_ $ \(Structure points) -> do modify global $ \(Paths graph goals) -> Paths graph (points ++ goals)
