PjBL2 — Tabela de Classificação de Campeonato (Haskell)

Trabalho de Programação Lógica e Funcional da PUCPR. O programa calcula a
tabela de classificação de um campeonato de futebol a partir dos resultados
das partidas, que são lidos de um texto.

Integrantes do grupo: Gabriel Mendes da Silva Cardin, 
Daniel Jose Pereira, 
Vitor Henrique Juliatto

Ambiente:
GHC local, instalado via GHCup. O projeto foi testado com o GHC 9.4.7 e usa
apenas a biblioteca base (Data.Char, Data.Either, Data.List, Data.Maybe,
Data.Ord, Text.Read e System.IO, este último só para fixar a codificação da
saída).

Como compilar e executar:
Na raiz do projeto, a demonstração das três camadas é compilada com o comando
abaixo e executada com ./build/campeonato.

ghc -Wall -Wincomplete-patterns -isrc -outputdir build -o build/campeonato src/Main.hs

A bateria de testes é compilada com o comando abaixo e executada com
./build/testes.

ghc -Wall -Wincomplete-patterns -isrc -outputdir build/t -o build/testes tests/Testes.hs

No Windows o executável sai com a extensão .exe, então basta rodar
.\build\campeonato.exe e .\build\testes.exe. Como os nomes dos times têm
acento, o programa escreve a saída em UTF-8. No PowerShell, no Windows
Terminal e no terminal do VS Code isso funciona direto; no cmd, se os acentos
saírem trocados, rode chcp 65001 antes.

Os dados ficam no código. O campeonato está dentro do programa como String, e
não em um arquivo separado. Assim o programa também roda no play.haskell.org,
que não tem entrada pelo teclado nem sistema de arquivos.

Organização do código:
O código está dividido em três camadas, cada uma em um módulo dentro de src.
A Camada 1, em Tipos.hs, define os tipos algébricos e as consultas sobre uma
partida. A Camada 2, em Classificacao.hs, monta a tabela e as estatísticas
usando apenas funções de ordem superior. A Camada 3, em Leitura.hs, cuida da
leitura do texto, da validação com Either e da formatação da tabela.

Além das camadas, Dados.hs guarda o campeonato de teste e uma entrada
propositalmente inválida, e Main.hs faz a demonstração das três camadas, sendo
a única parte do projeto que faz IO. Os testes ficam em tests/Testes.hs, e as
decisões de modelagem e as limitações conhecidas estão em docs/decisoes.md.

Os módulos dependem uns dos outros em linha reta, sem ciclos: Tipos é usado
por Classificacao, que é usado por Leitura, que é usado por Dados, e tanto
Main quanto os testes usam todos eles.

O campeonato de teste:
Um Paranaense fictício com 6 times e 5 rodadas em turno único, ou seja, 15
partidas em que todo mundo joga contra todo mundo uma vez. Cada linha do texto
tem o formato rodada;mandante;gols mandante;gols visitante;visitante, como em
1;Athletico;2;1;Coritiba, e linhas começando com # são comentários.

Casos de borda plantados de propósito. Há um empate em 0 x 0 (Londrina e
Paraná, na rodada 1), uma goleada de quatro gols de diferença (Athletico 4 x 0
Londrina, na rodada 2), dois times empatados em pontos (Coritiba e Paraná, com
5 pontos cada), uma tabela parcial diferente da final (o Paraná é 3º depois da
rodada 3 e termina em 5º) e comentários e linhas em branco espalhados pelo
texto.

Tabela final. O Operário termina em primeiro com 13 pontos, seguido por
Athletico (10), Maringá (6), Coritiba (5), Paraná (5) e Londrina (1). Coritiba
e Paraná têm os mesmos pontos, o mesmo número de vitórias e o mesmo saldo de
−1, então a ordem entre os dois só é decidida no quarto critério, gols pró, em
que o Coritiba vence por 7 a 4. O próprio programa imprime essa explicação, e
há um teste que a verifica.

Critérios de ordenação:
Seguem os do Campeonato Brasileiro: primeiro mais pontos, depois mais
vitórias, maior saldo de gols e mais gols pró. Se ainda houver empate, vale a
ordem alfabética, para que a tabela saia sempre igual. Os cinco critérios
formam uma única função de comparação, Classificacao.criterios, montada com
comparing, Down e o operador <>, e aplicada com um único sortBy.

Entrada inválida:
Nenhuma entrada derruba o programa. Todo problema vira um Left com um valor do
tipo Erro que diz onde ele está. CamposInvalidos indica uma linha sem os cinco
campos, como 1;Coritiba;2;1. NumeroInvalido indica um campo que não é número
inteiro, como o placar "dois" em 1;Athletico;dois;1;Londrina. PlacarNegativo
indica gols negativos, MesmoTime indica um time jogando contra si mesmo, e
TimeRepetidoNaRodada indica um time escalado em mais de uma partida da mesma
rodada. Os quatro primeiros apontam o número da linha e o último aponta a
rodada.

Duas formas de ler, de propósito. lerCampeonato para no primeiro erro, usando
traverse na mônada Either, enquanto todosOsErros percorre o texto inteiro e
lista todos os problemas, servindo de relatório.

Testes:
A bateria tem 58 testes e todos passam. Eles cobrem os três blocos pedidos no
enunciado: resultadoPara no mandante, no visitante e em quem não jogou (que dá
Nothing), a lista de times sem repetição, a classificação completa conferida à
mão, o desempate e o critério que o decidiu, a tabela de ateRodada 3 diferente
da final, maiorGoleada e mediaGols devolvendo Nothing para lista vazia, um
teste para cada construtor de Erro e todosOsErros sobre um texto com cinco
problemas. Se algum teste quebrar, ele aparece na saída como uma linha
começando com FALHOU.
