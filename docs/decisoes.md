Decisões de modelagem e limitações conhecidas

Camada 1 — tipos:
Partida é um record, não uma tupla. Uma tupla (Int, String, Int, Int, String)
tem dois Int de gols lado a lado: trocar o do mandante pelo do visitante
compila sem reclamação e só aparece como tabela errada. Com os campos nomeados,
golsMandante p não tem como virar golsVisitante p por descuido.

Resultado é tipo soma, não String nem Int. Com String, "v",
"V" e "vitoria" compilam igual e só um deles funciona. Com três
construtores, o conjunto de valores fica fechado, e -Wincomplete-patterns
avisa se alguma função esquecer um caso.

Linha guarda só o que é contado, nunca o que é derivado. Os campos são
jogos, vitórias, empates, derrotas, gols pró e gols contra. Pontos, saldo e
aproveitamento são funções da Camada 2 (pontosLinha, saldo,
aproveitamento). Se pontos fosse um campo, seria possível construir uma
Linha com 3 vitórias e 2 pontos um estado inválido que o tipo permitiria.

golsDe é a única função que sabe de que lado do placar cada time está.
Todo o resto é construído sobre ela, inclusive resultadoPara, que é só
fmap (uncurry resultadoDe) . golsDe t. Assim a regra "se sou mandante olho
golsMandante, se sou visitante olho golsVisitante" existe em um lugar só, e
o Nothing de quem não jogou atravessa sem nenhum if.

times ordena alfabeticamente (sort . nub . concatMap) porque a lista é
usada para montar a tabela: começar de uma ordem fixa deixa o resultado do
sortBy determinístico mesmo quando todos os critérios empatam.

Camada 2 — classificação:
linhaDoTime usa foldl, não foldr. O acumulador é a linha sendo
preenchida e a operação é comutativa (somar gols, contar vitórias), então as
duas direções dariam o mesmo total. foldl foi escolhido porque descreve
melhor o que acontece: percorrer as partidas em ordem carregando o parcial, que
é como alguém preencheria a tabela no papel. Onde a direção importa o
saldo de uma conta bancária, em que um saque pode ser recusado a escolha
deixaria de ser estilística; aqui não é, e isso está anotado no código.

Os critérios de desempate são uma comparação só. Encadear sortBy por
pontos, depois por saldo, depois por gols pró dependeria de cada ordenação
preservar a anterior, o que é frágil de ler mesmo quando funciona (sortBy é
estável). criterios é uma única função montada com <>, aproveitando que
Ordering é um Monoid: o critério seguinte só é consultado quando o anterior
empatou. Down inverte onde a ordem é decrescente.

Ordem adotada: pontos, vitórias, saldo, gols pró e, por fim, ordem
alfabética. Os quatro primeiros são os do Campeonato Brasileiro. O regulamento
real segue depois para confronto direto, cartões vermelhos, cartões amarelos e
sorteio nenhum desses é calculável com os dados que temos (ver limitações).
O quinto critério é alfabético para que a tabela seja idêntica em toda
execução, em vez de depender da ordem de leitura.

Nenhuma função parcial. maiorGoleada é listToMaybe . sortOn (Down . diferencaDeGols)
em vez de maximumBy, que quebra em lista vazia; mediaGols casa []
explicitamente. Em Leitura, duplicadosNaRodada usa mapMaybe listToMaybe
no lugar de map head. Campeonato vazio é um caso de uso real (antes da
primeira rodada), não uma exceção.

aproveitamento devolve Double de 0 a 100 e usa fromIntegral. Com
div o resultado truncaria (86% em vez de 86,7%), e / não aceita dois Int:
fromIntegral é a ponte. A escala 0–100 foi escolhida por ser como a imprensa
esportiva publica; quem preferir 0–1 muda uma constante.

pontosLinha deriva de pontos, em vez de escrever 3 * v + e. A regra
3/1/0 fica num lugar só, e mudar a pontuação do campeonato é mexer em uma
função de três linhas.

Camada 3 — leitura e validação:
Erro carrega a localização. Cada construtor leva o número da linha (ou a
rodada, no caso do time repetido). Um Left CamposInvalidos sem a linha obriga
quem digitou a procurar o erro em um arquivo inteiro.

A numeração vem antes da filtragem. linhasUteis faz
filter … . zip [1..] . lines: numera o arquivo inteiro e só depois descarta
comentários e linhas em branco. Filtrar antes faria a mensagem apontar a terceira
linha útil em vez da linha 7 do arquivo, que é o que o aluno vê no editor.

separar é uma dobra. Poderia ser recursão explícita, mas o padrão é o de
uma dobra: o acumulador é a lista de pedaços e cada caractere ou abre um pedaço
novo ou entra no atual. A equação passo _ [] = [""] nunca é alcançada (o
acumulador começa com um pedaço e nunca esvazia) e existe só para o padrão ser
completo com -Wall.

readMaybe, nunca read. Diante de "dois" ou "2a", read lança
Prelude.read: no parse e derruba o programa; readMaybe devolve Nothing, e
o maybe em lerInt converte isso no Erro certo.

lerPartida usa do na mônada Either. Cada validação é uma linha, e a
primeira que falha encerra a conversão sem case aninhado. As validações que
não produzem valor (placar não negativo, times diferentes) passam por exigir,
que devolve Right () ou Left erro.

Duas formas de ler, de propósito. lerCampeonato usa traverse e para no
primeiro erro, que é o comportamento certo para processar um campeonato.
todosOsErros não usa a mônada — justamente porque ela pararia cedo demais
e percorre as linhas com map, separando com lefts e rights. São usos
diferentes do mesmo Either, e por isso os dois estão no trabalho.

A validação de rodada é separada da de linha. "Não repetir time na mesma
rodada" não se verifica olhando uma linha: precisa do campeonato inteiro. Por
isso verificarRodadas roda depois do traverse, sobre a lista já convertida.

campeonato vem de lerCampeonato dadosCampeonato, e não de uma lista de
Partida escrita à mão. Os testes das camadas 1 e 2 rodam, assim, exatamente
sobre o que a Camada 3 produziu as três camadas ficam amarradas, e um erro de
digitação nos dados aparece de uma vez em vez de passar despercebido.

hSetEncoding stdout utf8 no main. Os nomes dos times têm acento, e no
Windows o putStrLn com a codificação padrão do console pode falhar com
commitBuffer: invalid argument. É a única chamada do projeto fora dos módulos
listados no enunciado, e está no main justamente por ser configuração de IO.

O núcleo é puro. main é a única função com IO (). Todas as outras são
funções de valor para valor é isso que permite que Testes.hs exercite o
programa inteiro sem console, e que o mesmo código rode no playground.

Limitações conhecidas:
Desempate incompleto perto do fim. Depois de gols pró, o regulamento do
Brasileirão usa confronto direto e depois cartões. Confronto direto seria
implementável com os dados que temos, mas não é uma comparação entre duas
linhas isoladas (depende das partidas entre os dois times), então não cabe na
função criterios do jeito que ela está modelada. Cartões não existem no
tipo Partida. No lugar dos dois, o critério final é alfabético.

Nome de time é String livre. "Coritiba", "coritiba" e
"Coritiba " (com espaço interno) seriam times diferentes. aparar resolve
espaços nas pontas, mas não há normalização de maiúsculas nem de acentos, nem
uma lista fechada de times válidos. Um newtype com construtor controlado, ou
um tipo soma com os times do campeonato, fecharia esse buraco.

A estrutura do campeonato não é validada. O programa aceita um
campeonato com rodada 1 e rodada 7 sem as do meio, com número diferente de
partidas por rodada, ou com dois times que nunca se enfrentam. Só a regra
explicitamente pedida nenhum time duas vezes na mesma rodada — é conferida.

todosOsErros não vê tudo em uma passada. TimeRepetidoNaRodada só é
detectado entre as linhas que já são válidas: se a linha que repetiria o time
tiver também um placar inválido, ela aparece no relatório como
NumeroInvalido e a repetição não é reportada. Corrigir a primeira falha e
rodar de novo revela a segunda.

CamposInvalidos acumula dois casos. Serve tanto para "número de campos
diferente de 5" quanto para "nome de time em branco". Separar em dois
construtores daria mensagens mais precisas.

Empate de goleadas é resolvido pela ordem de leitura. maiorGoleada usa
sortOn, que é estável, então entre duas vitórias com a mesma diferença
devolve a que foi jogada primeiro. É determinístico, mas é uma escolha
arbitrária, não uma regra de campeonato.

Saída em UTF-8. Resolve o travamento no Windows, mas em um cmd antigo
sem chcp 65001 os acentos saem trocados. A tabela continua legível e o
programa não quebra.

Sem returno e sem mando de campo nos critérios. O campeonato de teste é
de turno único; o código funciona com returno (basta mais linhas no texto),
mas nada no modelo distingue uma partida de ida de uma de volta.
