-- Camada 2: classificação com funções de ordem superior.
module Classificacao
  ( pontos
  , linhaDoTime
  , pontosLinha
  , saldo
  , aproveitamento
  , criterios
  , criterioDecisivo
  , empatesEmPontos
  , classificacao
  , ateRodada
  , diferencaDeGols
  , totalDeGols
  , maiorGoleada
  , mediaGols
  ) where

import Data.List (groupBy, sortBy, sortOn)
import Data.Maybe (listToMaybe)
import Data.Ord (Down (..), comparing)

import Tipos

pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime ps t = foldl acumula (linhaVazia t) (filter (participou t) ps)
  where
    acumula :: Linha -> Partida -> Linha
    acumula l p = maybe l (somar l) (golsDe t p)

    somar :: Linha -> (Int, Int) -> Linha
    somar l (meus, deles) =
      l { jogos      = jogos l + 1
        , vitorias   = vitorias l + conta Vitoria
        , empates    = empates l + conta Empate
        , derrotas   = derrotas l + conta Derrota
        , golsPro    = golsPro l + meus
        , golsContra = golsContra l + deles
        }
      where
        r = resultadoDe meus deles
        conta x = if r == x then 1 else 0

pontosLinha :: Linha -> Int
pontosLinha l =
  vitorias l * pontos Vitoria
    + empates l * pontos Empate
    + derrotas l * pontos Derrota

saldo :: Linha -> Int
saldo l = golsPro l - golsContra l

aproveitamento :: Linha -> Double
aproveitamento l
  | jogos l == 0 = 0
  | otherwise =
      100 * fromIntegral (pontosLinha l) / fromIntegral (3 * jogos l)

criterios :: Linha -> Linha -> Ordering
criterios =
  comparing (Down . pontosLinha)
    <> comparing (Down . vitorias)
    <> comparing (Down . saldo)
    <> comparing (Down . golsPro)
    <> comparing time

criterioDecisivo :: Linha -> Linha -> String
criterioDecisivo a b
  | pontosLinha a /= pontosLinha b = "pontos"
  | vitorias a /= vitorias b = "vitorias"
  | saldo a /= saldo b = "saldo de gols"
  | golsPro a /= golsPro b = "gols pro"
  | otherwise = "ordem alfabetica"

empatesEmPontos :: [Linha] -> [[Linha]]
empatesEmPontos =
  filter ((> 1) . length)
    . groupBy (\a b -> pontosLinha a == pontosLinha b)

classificacao :: [Partida] -> [Linha]
classificacao ps = sortBy criterios (map (linhaDoTime ps) (times ps))

ateRodada :: Int -> [Partida] -> [Partida]
ateRodada r = filter ((<= r) . rodada)

diferencaDeGols :: Partida -> Int
diferencaDeGols p = abs (golsMandante p - golsVisitante p)

totalDeGols :: Partida -> Int
totalDeGols p = golsMandante p + golsVisitante p

maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada = listToMaybe . sortOn (Down . diferencaDeGols)

mediaGols :: [Partida] -> Maybe Double
mediaGols [] = Nothing
mediaGols ps =
  Just (fromIntegral (sum (map totalDeGols ps)) / fromIntegral (length ps))
