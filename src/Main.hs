-- Demonstração das três camadas, na ordem.
module Main (main) where

import Data.List (intercalate, nub)
import System.IO (hSetEncoding, stdout, utf8)

import Classificacao
import Dados
import Leitura
import Tipos

main :: IO ()
main = do
  hSetEncoding stdout utf8

  case lerCampeonato dadosCampeonato of
    Left e -> putStrLn ("Nao foi possivel ler o campeonato. " ++ descreveErro e)
    Right ps -> do
      camada1 ps
      camada2 ps
  camada3

-- Camada 1

camada1 :: [Partida] -> IO ()
camada1 ps = do
  secao "CAMADA 1 - tipos e consultas basicas"
  putStrLn ("Partidas: " ++ show (length ps))
  putStrLn ("Rodadas:  " ++ show (length (nub (map rodada ps))))
  putStrLn ("Times:    " ++ intercalate ", " (times ps))
  putStrLn ""
  case ps of
    [] -> putStrLn "Campeonato sem partidas."
    (p : _) -> do
      putStrLn ("Partida de exemplo: " ++ placar p)
      mapM_
        putStrLn
        [ consulta (mandante p) p ""
        , consulta (visitante p) p ""
        , consulta "Flamengo" p "   (nao jogou esta partida)"
        ]

consulta :: Time -> Partida -> String -> String
consulta t p nota =
  "  resultadoPara " ++ rotulo ++ " = " ++ show (resultadoPara t p) ++ nota
  where
    bruto = show t
    rotulo = bruto ++ replicate (max 0 (12 - length bruto)) ' '

placar :: Partida -> String
placar p =
  "rodada "
    ++ show (rodada p)
    ++ " - "
    ++ mandante p
    ++ " "
    ++ show (golsMandante p)
    ++ " x "
    ++ show (golsVisitante p)
    ++ " "
    ++ visitante p

-- Camada 2

camada2 :: [Partida] -> IO ()
camada2 ps = do
  secao "CAMADA 2 - classificacao final"
  putStr (tabelaFormatada (classificacao ps))

  secao "CAMADA 2 - classificacao apos a rodada 3"
  putStr (tabelaFormatada (classificacao (ateRodada 3 ps)))

  secao "CAMADA 2 - desempates na tabela final"
  mapM_ putStrLn (explicaEmpates (classificacao ps))

  secao "CAMADA 2 - estatisticas"
  putStrLn ("Maior goleada:   " ++ maybe "nenhuma partida" placar (maiorGoleada ps))
  putStrLn ("Media de gols:   " ++ maybe "nenhuma partida" umaCasa (mediaGols ps) ++ " por partida")
  putStrLn ("Total de gols:   " ++ show (sum (map totalDeGols ps)))

  secao "CAMADA 2 - campeonato vazio (funcoes totais)"
  putStrLn ("classificacao [] = " ++ show (classificacao []))
  putStrLn ("maiorGoleada  [] = " ++ show (maiorGoleada []))
  putStrLn ("mediaGols     [] = " ++ show (mediaGols []))

explicaEmpates :: [Linha] -> [String]
explicaEmpates tabela =
  case empatesEmPontos tabela of
    [] -> ["Nenhum empate em pontos na tabela final."]
    grupos -> concatMap explicaGrupo grupos
  where
    explicaGrupo g =
      ("Empatados em " ++ show (pontosLinha (head' g)) ++ " pontos: " ++ intercalate ", " (map time g))
        : zipWith comparaPar g (drop 1 g)

    comparaPar a b =
      "  "
        ++ time a
        ++ " na frente de "
        ++ time b
        ++ " por "
        ++ criterioDecisivo a b
        ++ " ("
        ++ detalhe a
        ++ " contra "
        ++ detalhe b
        ++ ")"

    detalhe l =
      show (vitorias l) ++ "V, saldo " ++ show (saldo l) ++ ", " ++ show (golsPro l) ++ " gols pro"

    head' (x : _) = x
    head' [] = linhaVazia "?"

-- Camada 3

camada3 :: IO ()
camada3 = do
  secao "CAMADA 3 - entrada invalida"
  putStrLn "A entrada de teste tem um erro de cada tipo."
  putStrLn ""
  putStrLn "lerCampeonato para no primeiro erro:"
  case lerCampeonato dadosComErros of
    Left e -> putStrLn ("  " ++ descreveErro e)
    Right _ -> putStrLn "  nenhum erro encontrado (inesperado)"
  putStrLn ""
  putStrLn "todosOsErros lista o relatorio completo:"
  mapM_ (putStrLn . ("  " ++) . descreveErro) (todosOsErros dadosComErros)
  putStrLn ""
  putStrLn "Em nenhum dos casos o programa lanca excecao."

secao :: String -> IO ()
secao titulo = do
  putStrLn ""
  putStrLn (replicate 66 '=')
  putStrLn titulo
  putStrLn (replicate 66 '=')
