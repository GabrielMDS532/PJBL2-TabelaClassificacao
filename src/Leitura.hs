-- Camada 3: leitura, validação e saída.
module Leitura
  ( Erro (..)
  , descreveErro
  , separar
  , aparar
  , linhasUteis
  , lerPartida
  , duplicadosNaRodada
  , verificarRodadas
  , lerCampeonato
  , todosOsErros
  , tabelaFormatada
  , umaCasa
  ) where

import Data.Char (isSpace)
import Data.Either (lefts, rights)
import Data.List (dropWhileEnd, group, sort)
import Data.Maybe (listToMaybe, mapMaybe)
import Text.Read (readMaybe)

import Classificacao (aproveitamento, pontosLinha, saldo)
import Tipos

data Erro
  = CamposInvalidos Int String
  | NumeroInvalido Int String
  | PlacarNegativo Int Int Int
  | MesmoTime Int Time
  | TimeRepetidoNaRodada Int Time
  deriving (Show, Eq)

descreveErro :: Erro -> String
descreveErro e = case e of
  CamposInvalidos n txt ->
    "Linha " ++ show n ++ ": esperava 5 campos separados por ';' em \"" ++ txt ++ "\""
  NumeroInvalido n campo ->
    "Linha " ++ show n ++ ": \"" ++ campo ++ "\" nao e um numero inteiro"
  PlacarNegativo n gm gv ->
    "Linha " ++ show n ++ ": placar negativo (" ++ show gm ++ " x " ++ show gv ++ ")"
  MesmoTime n t ->
    "Linha " ++ show n ++ ": " ++ t ++ " jogando contra si mesmo"
  TimeRepetidoNaRodada r t ->
    "Rodada " ++ show r ++ ": " ++ t ++ " aparece em mais de uma partida"

separar :: Char -> String -> [String]
separar sep = foldr passo [""]
  where
    passo c (atual : resto)
      | c == sep = "" : atual : resto
      | otherwise = (c : atual) : resto
    passo _ [] = [""]

aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace

linhasUteis :: String -> [(Int, String)]
linhasUteis = filter (relevante . snd) . zip [1 ..] . lines
  where
    relevante l = case aparar l of
      "" -> False
      ('#' : _) -> False
      _ -> True

lerInt :: Int -> String -> Either Erro Int
lerInt n campo = maybe (Left (NumeroInvalido n campo)) Right (readMaybe campo)

exigir :: Bool -> Erro -> Either Erro ()
exigir True _ = Right ()
exigir False e = Left e

lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha =
  case map aparar (separar ';' linha) of
    [cr, cm, cgm, cgv, cv] -> do
      r <- lerInt n cr
      gm <- lerInt n cgm
      gv <- lerInt n cgv
      exigir (r > 0) (NumeroInvalido n cr)
      exigir (gm >= 0 && gv >= 0) (PlacarNegativo n gm gv)
      exigir (not (null cm) && not (null cv)) (CamposInvalidos n linha)
      exigir (cm /= cv) (MesmoTime n cm)
      Right (Partida r cm gm gv cv)
    _ -> Left (CamposInvalidos n linha)

duplicadosNaRodada :: [Partida] -> [(Int, Time)]
duplicadosNaRodada =
  mapMaybe listToMaybe
    . filter ((> 1) . length)
    . group
    . sort
    . concatMap participacoes
  where
    participacoes p = [(rodada p, mandante p), (rodada p, visitante p)]

verificarRodadas :: [Partida] -> Either Erro ()
verificarRodadas ps =
  case duplicadosNaRodada ps of
    [] -> Right ()
    ((r, t) : _) -> Left (TimeRepetidoNaRodada r t)

lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto = do
  ps <- traverse (uncurry lerPartida) (linhasUteis texto)
  verificarRodadas ps
  Right ps

todosOsErros :: String -> [Erro]
todosOsErros texto = lefts lidas ++ map (uncurry TimeRepetidoNaRodada) duplicados
  where
    lidas = map (uncurry lerPartida) (linhasUteis texto)
    duplicados = duplicadosNaRodada (rights lidas)

alinhaDir :: Int -> String -> String
alinhaDir n s = replicate (n - length s) ' ' ++ s

alinhaEsq :: Int -> String -> String
alinhaEsq n s = s ++ replicate (n - length s) ' '

umaCasa :: Double -> String
umaCasa x = show inteiro ++ "." ++ show decimo
  where
    (inteiro, decimo) = round (x * 10) `divMod` (10 :: Int)

formataLinha :: Int -> Linha -> String
formataLinha pos l =
  concat
    [ alinhaDir 3 (show pos)
    , "  "
    , alinhaEsq 14 (time l)
    , alinhaDir 4 (show (pontosLinha l))
    , alinhaDir 4 (show (jogos l))
    , alinhaDir 4 (show (vitorias l))
    , alinhaDir 4 (show (empates l))
    , alinhaDir 4 (show (derrotas l))
    , alinhaDir 5 (show (golsPro l))
    , alinhaDir 5 (show (golsContra l))
    , alinhaDir 5 (show (saldo l))
    , alinhaDir 9 (umaCasa (aproveitamento l) ++ "%")
    ]

cabecalho :: String
cabecalho =
  concat
    [ alinhaDir 3 "#"
    , "  "
    , alinhaEsq 14 "TIME"
    , alinhaDir 4 "P"
    , alinhaDir 4 "J"
    , alinhaDir 4 "V"
    , alinhaDir 4 "E"
    , alinhaDir 4 "D"
    , alinhaDir 5 "GP"
    , alinhaDir 5 "GC"
    , alinhaDir 5 "SG"
    , alinhaDir 9 "APROV"
    ]

tabelaFormatada :: [Linha] -> String
tabelaFormatada ls =
  unlines (cabecalho : replicate (length cabecalho) '-' : zipWith formataLinha [1 ..] ls)
