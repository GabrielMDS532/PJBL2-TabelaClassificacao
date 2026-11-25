-- Bateria de testes das três camadas.
module Main (main) where

import System.IO (hSetEncoding, stdout, utf8)

import Classificacao
import Dados
import Leitura
import Tipos

testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise = putStrLn ("FALHOU  " ++ nome ++ ": " ++ show obtido)

verificar :: (Eq a, Show a) => String -> a -> a -> IO Bool
verificar nome obtido esperado = do
  testar nome obtido esperado
  return (obtido == esperado)

bloco :: String -> [IO Bool] -> IO [Bool]
bloco titulo testes = do
  putStrLn ""
  putStrLn ("--- " ++ titulo ++ " " ++ replicate (50 - length titulo) '-')
  sequence testes

main :: IO ()
main = do
  hSetEncoding stdout utf8
  r1 <- bloco "Camada 1: tipos e consultas" testesCamada1
  r2 <- bloco "Camada 2: classificacao" testesCamada2
  r3 <- bloco "Camada 3: leitura e validacao" testesCamada3
  resumo (r1 ++ r2 ++ r3)

resumo :: [Bool] -> IO ()
resumo rs = do
  putStrLn ""
  putStrLn (replicate 60 '=')
  putStrLn
    ( show (length (filter id rs))
        ++ " de "
        ++ show (length rs)
        ++ " testes passaram"
    )
  putStrLn
    ( if and rs
        then "Todos os testes passaram."
        else "ATENCAO: ha testes falhando (linhas marcadas com FALHOU)."
    )

-- Camada 1

jogo1 :: Partida
jogo1 = Partida 1 "Athletico" 2 1 "Coritiba"

jogoEmpate :: Partida
jogoEmpate = Partida 1 "Londrina" 0 0 "Paraná"

testesCamada1 :: [IO Bool]
testesCamada1 =
  [ -- o mandante conta como participante
    verificar "participou: mandante" (participou "Athletico" jogo1) True
  , -- o visitante conta como participante
    verificar "participou: visitante" (participou "Coritiba" jogo1) True
  , -- time de fora da partida não participou
    verificar "participou: quem nao jogou" (participou "Flamengo" jogo1) False
  , -- mandante que fez mais gols vence
    verificar "resultadoPara: mandante vencedor" (resultadoPara "Athletico" jogo1) (Just Vitoria)
  , -- visitante que fez menos gols perde
    verificar "resultadoPara: visitante perdedor" (resultadoPara "Coritiba" jogo1) (Just Derrota)
  , -- time que não jogou não tem resultado
    verificar "resultadoPara: quem nao jogou da Nothing" (resultadoPara "Flamengo" jogo1) Nothing
  , -- 0 x 0 é empate para o mandante
    verificar "resultadoPara: empate para o mandante" (resultadoPara "Londrina" jogoEmpate) (Just Empate)
  , -- 0 x 0 é empate para o visitante
    verificar "resultadoPara: empate para o visitante" (resultadoPara "Paraná" jogoEmpate) (Just Empate)
  , -- o placar se inverte para o visitante (gols feitos, gols sofridos)
    verificar "golsDe: ponto de vista do visitante" (golsDe "Coritiba" jogo1) (Just (1, 2))
  , -- lista de times sem repetição e em ordem alfabética
    verificar
      "times: sem repeticao e em ordem alfabetica"
      (times campeonato)
      ["Athletico", "Coritiba", "Londrina", "Maringá", "Operário", "Paraná"]
  , -- o campeonato de teste tem 6 times
    verificar "times: 6 times no campeonato de teste" (length (times campeonato)) 6
  , -- sem partidas não há times
    verificar "times: lista vazia" (times []) []
  ]

-- Camada 2

tabelaFinalEsperada :: [Linha]
tabelaFinalEsperada =
  [ Linha "Operário" 5 4 1 0 9 3
  , Linha "Athletico" 5 3 1 1 9 4
  , Linha "Maringá" 5 1 3 1 8 9
  , Linha "Coritiba" 5 1 2 2 7 8
  , Linha "Paraná" 5 1 2 2 4 5
  , Linha "Londrina" 5 0 1 4 3 11
  ]

testesCamada2 :: [IO Bool]
testesCamada2 =
  [ -- vitória vale 3 pontos
    verificar "pontos: vitoria" (pontos Vitoria) 3
  , -- empate vale 1 ponto
    verificar "pontos: empate" (pontos Empate) 1
  , -- derrota vale 0 pontos
    verificar "pontos: derrota" (pontos Derrota) 0
  , -- linha acumulada do líder bate com a conta feita à mão
    verificar
      "linhaDoTime: lider do campeonato"
      (linhaDoTime campeonato "Operário")
      (Linha "Operário" 5 4 1 0 9 3)
  , -- time ausente do campeonato fica com a linha zerada
    verificar
      "linhaDoTime: time que nao jogou fica zerado"
      (linhaDoTime campeonato "Flamengo")
      (Linha "Flamengo" 0 0 0 0 0 0)
  , -- 4 vitórias e 1 empate somam 13 pontos
    verificar "pontosLinha: 4 vitorias e 1 empate" (pontosLinha (Linha "X" 5 4 1 0 9 3)) 13
  , -- saldo = gols pró - gols contra
    verificar "saldo: gols pro menos gols contra" (saldo (Linha "X" 5 4 1 0 9 3)) 6
  , -- 13 pontos de 15 possíveis
    verificar "aproveitamento: 13 de 15 pontos" (aproveitamento (Linha "X" 5 4 1 0 9 3)) (13 / 15 * 100)
  , -- só vitórias dá 100%
    verificar "aproveitamento: aproveitamento total" (aproveitamento (Linha "X" 3 3 0 0 6 2)) 100
  , -- sem jogos dá 0, sem divisão por zero
    verificar "aproveitamento: quem nao jogou nao divide por zero" (aproveitamento (linhaVazia "X")) 0
  , -- tabela final inteira igual à esperada
    verificar "classificacao: tabela final completa" (classificacao campeonato) tabelaFinalEsperada
  , -- ordem dos times na tabela final
    verificar
      "classificacao: ordem dos times na tabela final"
      (map time (classificacao campeonato))
      ["Operário", "Athletico", "Maringá", "Coritiba", "Paraná", "Londrina"]
  , -- Coritiba e Paraná terminam com os mesmos pontos
    verificar
      "desempate: Coritiba e Parana empatados em pontos"
      (map pontosLinha (filter (\l -> time l `elem` ["Coritiba", "Paraná"]) (classificacao campeonato)))
      [5, 5]
  , -- o empate entre os dois é decidido por gols pró
    verificar
      "desempate: criterio que decidiu foi gols pro"
      (criterioDecisivo (linhaDoTime campeonato "Coritiba") (linhaDoTime campeonato "Paraná"))
      "gols pro"
  , -- Coritiba fica à frente do Paraná na tabela
    verificar
      "desempate: Coritiba fica na frente do Parana"
      (filter (`elem` ["Coritiba", "Paraná"]) (map time (classificacao campeonato)))
      ["Coritiba", "Paraná"]
  , -- até a rodada 3 há 9 partidas
    verificar "ateRodada: 3 rodadas dao 9 partidas" (length (ateRodada 3 campeonato)) 9
  , -- rodada 0 não tem partidas
    verificar "ateRodada: rodada 0 nao tem partidas" (ateRodada 0 campeonato) []
  , -- rodada além da última traz todas as partidas
    verificar "ateRodada: alem da ultima rodada traz tudo" (length (ateRodada 99 campeonato)) 15
  , -- ordem da tabela parcial após a rodada 3
    verificar
      "classificacao: tabela apos a rodada 3"
      (map time (classificacao (ateRodada 3 campeonato)))
      ["Operário", "Athletico", "Paraná", "Maringá", "Coritiba", "Londrina"]
  , -- a tabela parcial é diferente da final
    verificar
      "classificacao: a tabela da rodada 3 difere da final"
      (map time (classificacao (ateRodada 3 campeonato)) /= map time (classificacao campeonato))
      True
  , -- maior goleada do campeonato
    verificar
      "maiorGoleada: Athletico 4 x 0 Londrina"
      (maiorGoleada campeonato)
      (Just (Partida 2 "Athletico" 4 0 "Londrina"))
  , -- sem partidas não há goleada
    verificar "maiorGoleada: lista vazia da Nothing" (maiorGoleada []) Nothing
  , -- média de gols por partida
    verificar "mediaGols: 40 gols em 15 partidas" (mediaGols campeonato) (Just (40 / 15))
  , -- sem partidas não há média
    verificar "mediaGols: lista vazia da Nothing" (mediaGols []) Nothing
  , -- campeonato vazio gera tabela vazia
    verificar "classificacao: campeonato vazio da tabela vazia" (classificacao []) []
  ]

-- Camada 3

linhaCamposInvalidos, linhaNumeroInvalido, linhaPlacarNegativo, linhaMesmoTime :: String
linhaCamposInvalidos = "1;Coritiba;2;1"
linhaNumeroInvalido = "1;Athletico;dois;1;Londrina"
linhaPlacarNegativo = "2;Maringá;-1;2;Operário"
linhaMesmoTime = "2;Paraná;1;1;Paraná"

textoTimeRepetido :: String
textoTimeRepetido = unlines ["3;Coritiba;1;0;Londrina", "3;Coritiba;2;2;Maringá"]

testesCamada3 :: [IO Bool]
testesCamada3 =
  [ -- divide uma linha válida nos cinco campos
    verificar
      "separar: cinco campos"
      (separar ';' "1;Coritiba;2;1;Athletico")
      ["1", "Coritiba", "2", "1", "Athletico"]
  , -- dois separadores seguidos geram um campo vazio
    verificar "separar: campo vazio no meio" (separar ';' "a;;b") ["a", "", "b"]
  , -- texto sem separador vira um único campo
    verificar "separar: string sem separador" (separar ';' "abc") ["abc"]
  , -- remove espaços do início e do fim
    verificar "aparar: espacos nas duas pontas" (aparar "  Coritiba  ") "Coritiba"
  , -- descarta comentários e linhas em branco mantendo a numeração original
    verificar
      "linhasUteis: ignora comentarios e linhas em branco, mas numera o arquivo todo"
      (map fst (linhasUteis dadosCampeonato))
      [5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 18, 19, 21, 22, 23]
  , -- linha válida vira uma Partida
    verificar
      "lerPartida: linha valida"
      (lerPartida 1 "1;Athletico;2;1;Coritiba")
      (Right (Partida 1 "Athletico" 2 1 "Coritiba"))
  , -- espaços em volta dos campos são ignorados
    verificar
      "lerPartida: aceita espacos em volta dos campos"
      (lerPartida 1 " 1 ; Athletico ; 2 ; 1 ; Coritiba ")
      (Right (Partida 1 "Athletico" 2 1 "Coritiba"))
  , -- linha com campos faltando
    verificar
      "Erro CamposInvalidos: faltou um campo"
      (lerPartida 3 linhaCamposInvalidos)
      (Left (CamposInvalidos 3 linhaCamposInvalidos))
  , -- placar que não é número
    verificar
      "Erro NumeroInvalido: placar escrito por extenso"
      (lerPartida 4 linhaNumeroInvalido)
      (Left (NumeroInvalido 4 "dois"))
  , -- placar com gols negativos
    verificar
      "Erro PlacarNegativo: gols negativos"
      (lerPartida 5 linhaPlacarNegativo)
      (Left (PlacarNegativo 5 (-1) 2))
  , -- mandante e visitante iguais
    verificar
      "Erro MesmoTime: time jogando contra si mesmo"
      (lerPartida 6 linhaMesmoTime)
      (Left (MesmoTime 6 "Paraná"))
  , -- mesmo time em duas partidas da mesma rodada
    verificar
      "Erro TimeRepetidoNaRodada: Coritiba duas vezes na rodada 3"
      (lerCampeonato textoTimeRepetido)
      (Left (TimeRepetidoNaRodada 3 "Coritiba"))
  , -- entrada válida lê as 15 partidas
    verificar
      "lerCampeonato: entrada valida devolve Right com 15 partidas"
      (fmap length (lerCampeonato dadosCampeonato))
      (Right 15)
  , -- a primeira partida é lida com os valores certos
    verificar
      "lerCampeonato: primeira partida lida corretamente"
      (fmap (take 1) (lerCampeonato dadosCampeonato))
      (Right [Partida 1 "Athletico" 2 1 "Coritiba"])
  , -- texto vazio não é erro, só não tem partidas
    verificar "lerCampeonato: texto vazio devolve lista vazia" (lerCampeonato "") (Right [])
  , -- texto só com comentários não tem partidas
    verificar
      "lerCampeonato: so comentarios devolve lista vazia"
      (lerCampeonato "# nada aqui\n\n")
      (Right [])
  , -- com vários erros, devolve só o primeiro
    verificar
      "lerCampeonato: para no primeiro erro"
      (lerCampeonato dadosComErros)
      (Left (CamposInvalidos 3 linhaCamposInvalidos))
  , -- relatório lista todos os cinco erros, não só o primeiro
    verificar
      "todosOsErros: lista os cinco erros do texto"
      (todosOsErros dadosComErros)
      [ CamposInvalidos 3 linhaCamposInvalidos
      , NumeroInvalido 4 "dois"
      , PlacarNegativo 5 (-1) 2
      , MesmoTime 6 "Paraná"
      , TimeRepetidoNaRodada 3 "Coritiba"
      ]
  , -- entrada válida não gera erros
    verificar "todosOsErros: entrada valida nao tem erro" (todosOsErros dadosCampeonato) []
  , -- cabeçalho, linha de traços e uma linha por time
    verificar
      "tabelaFormatada: uma linha de cabecalho, uma de traco e uma por time"
      (length (lines (tabelaFormatada (classificacao campeonato))))
      8
  , -- tabela vazia ainda mostra o cabeçalho
    verificar
      "tabelaFormatada: tabela vazia ainda tem cabecalho"
      (length (lines (tabelaFormatada [])))
      2
  ]
