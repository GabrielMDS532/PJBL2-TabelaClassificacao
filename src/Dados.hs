-- Campeonato de teste, no mesmo formato de texto que a Camada 3 lê.
module Dados
  ( dadosCampeonato
  , dadosComErros
  , campeonato
  ) where

import Leitura (lerCampeonato)
import Tipos (Partida)

dadosCampeonato :: String
dadosCampeonato =
  unlines
    [ "# Campeonato Paranaense 2026 - turno unico, 6 times, 5 rodadas"
    , "# rodada;mandante;gols mandante;gols visitante;visitante"
    , ""
    , "# --- rodada 1 ---"
    , "1;Athletico;2;1;Coritiba"
    , "1;Londrina;0;0;Paraná"
    , "1;Maringá;1;3;Operário"
    , "# --- rodada 2 ---"
    , "2;Athletico;4;0;Londrina"
    , "2;Maringá;2;2;Coritiba"
    , "2;Operário;1;0;Paraná"
    , "# --- rodada 3 ---"
    , "3;Athletico;1;1;Maringá"
    , "3;Operário;2;1;Londrina"
    , "3;Paraná;3;1;Coritiba"
    , "# --- rodada 4 ---"
    , "4;Athletico;0;2;Operário"
    , "4;Paraná;1;1;Maringá"
    , "4;Coritiba;2;0;Londrina"
    , "# --- rodada 5 ---"
    , "5;Athletico;2;0;Paraná"
    , "5;Coritiba;1;1;Operário"
    , "5;Londrina;2;3;Maringá"
    ]

dadosComErros :: String
dadosComErros =
  unlines
    [ "# entrada propositalmente invalida, para o relatorio de erros"
    , ""
    , "1;Coritiba;2;1"
    , "1;Athletico;dois;1;Londrina"
    , "2;Maringá;-1;2;Operário"
    , "2;Paraná;1;1;Paraná"
    , "3;Coritiba;1;0;Londrina"
    , "3;Coritiba;2;2;Maringá"
    ]

campeonato :: [Partida]
campeonato = either (const []) id (lerCampeonato dadosCampeonato)
