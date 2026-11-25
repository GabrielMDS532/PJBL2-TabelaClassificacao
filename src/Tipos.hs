-- Camada 1: tipos e dados do campeonato.
module Tipos
  ( Time
  , Resultado (..)
  , Partida (..)
  , Linha (..)
  , linhaVazia
  , participou
  , golsDe
  , resultadoDe
  , resultadoPara
  , times
  ) where

import Data.List (nub, sort)

type Time = String

data Resultado
  = Vitoria
  | Empate
  | Derrota
  deriving (Show, Eq)

data Partida = Partida
  { rodada        :: Int
  , mandante      :: Time
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time
  }
  deriving (Show, Eq)

data Linha = Linha
  { time       :: Time
  , jogos      :: Int
  , vitorias   :: Int
  , empates    :: Int
  , derrotas   :: Int
  , golsPro    :: Int
  , golsContra :: Int
  }
  deriving (Show, Eq)

linhaVazia :: Time -> Linha
linhaVazia t = Linha t 0 0 0 0 0 0

participou :: Time -> Partida -> Bool
participou t p = mandante p == t || visitante p == t

golsDe :: Time -> Partida -> Maybe (Int, Int)
golsDe t p
  | t == mandante p  = Just (golsMandante p, golsVisitante p)
  | t == visitante p = Just (golsVisitante p, golsMandante p)
  | otherwise        = Nothing

resultadoDe :: Int -> Int -> Resultado
resultadoDe meus deles
  | meus > deles  = Vitoria
  | meus == deles = Empate
  | otherwise     = Derrota

resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t = fmap (uncurry resultadoDe) . golsDe t

times :: [Partida] -> [Time]
times = sort . nub . concatMap ambos
  where
    ambos p = [mandante p, visitante p]
