# 🌎 Global E-Commerce Sales & Customer Data

## 📊 Análise de Rentabilidade — E-commerce Global

## 🎯 Problema de negócio

Antes de investigar qualquer causa específica, conduzi uma análise exploratória estruturada em
quatro dimensões de negócio — temporal, produtos, regional e clientes/segmentos — para diagnosticar
a saúde geral do negócio e identificar sinais que merecessem investigação mais profunda. Foi essa
análise que revelou um resultado que levantou dúvidas: uma queda de **-33% no lucro do Q1 2024**
face ao mesmo período do ano anterior, além de outros sinais (pressão de custo de envio numa
categoria específica, e movimentos fortes em determinados segmentos de cliente). Isso motivou uma
segunda fase de decomposição, para explicar exatamente o que causou cada um desses sinais.

## 🔍 Fase 1 — Análise exploratória (diagnóstico multidimensional)

**1. Análise temporal**
- Tendência de crescimento ao longo do tempo (média móvel 3M) — o negócio está a crescer?
- Consistência do crescimento (coeficiente de variação) — o crescimento é estável ou instável?
- Variação do lucro YoY trimestral
- Decomposição do lucro por desconto, preço e unidades vendidas

**2. Análise de produtos**
- O que mais pressiona a margem de cada categoria? (peso do custo do produto, desconto e envio)
- Quantos produtos concentram ~80% do lucro? (análise de Pareto)

**3. Análise regional**
- Que regiões dependem mais de desconto para gerar vendas?
- Quantos países concentram ~80% do lucro? (análise de Pareto)

**4. Análise de clientes/segmento**
- Qual o posicionamento de valor de cada segmento? (volume, ticket médio, rentabilidade — segmentos
  premium vs. segmentos de escala)
- Qual segmento tem melhor desempenho ao longo do tempo? (crescimento YoY trimestral)

## 🔎 Fase 2 — Decomposição (motivada pelos resultados da Fase 1)

1. Decomposição da queda de -33% no lucro do Q1 2024
2. Decomposição do aumento de 34% no custo de envio da categoria Office Supplies
3. Decomposição por segmento:
   - 3.1 O que causou a queda do Consumer em Q1 2024?
   - 3.2 O que causou o pico do Corporate em Q3 2025?
   - 3.3 O que causou o pico do Home Office em Q4 2025?

## 🗂️ Dados
Dataset público (Kaggle), ~2.000 transações de e-commerce global, 2023–2025: vendas, custos, categorias de produto, segmentos de cliente e datas de encomenda.


[![Kaggle Dataset](https://custom-icon-badges.demolab.com/badge/KAGGLE-DATASET-20BEFF?style=for-the-badge&logo=kaggle&logoColor=white&labelColor=0B5A7A)](https://www.kaggle.com/datasets/muhammadaammartufail/global-e-commerce-sales-and-customer-data)   

**`Clica para ver dastaset`**

## 🛠️ Metodologia
Modelação relacional da base de dados em PostgreSQL.
SQL avançado — os scripts seguem uma progressão lógica (por isso a numeração 01 a 04):

01_criacao_tabelas.sql — criação do esquema relacional.

02_transferencia_de_dados.sql — carga dos dados brutos para as tabelas.

03_analise_rentabilidade.sql — cálculo de métricas de rentabilidade por período/categoria/segmento.  

04_analise_decomposicao.sql — decomposição da variação de lucro entre volume, preço e mix, usando CTEs com bases temporais separadas e LAG() OVER (PARTITION BY trimestre) para a comparação homóloga (YoY).

Power BI: dashboards executivos com medidas DAX, construídos em torno das perguntas de negócio acima — não por tipo de gráfico.

obs: as medidas dax foram criadas em subsituição do script 03_analise_rentabilidade com objetivo de haver interação entre os gráficos no power bi diferente do script 04_analise_decomposição que foi exportado no power bi.

Comunicação executiva: relatório de 15 slides em PowerPoint, com a estrutura Pergunta → Descoberta → Conclusão → Recomendação em cada slide, no estilo de uma consultora (McKinsey/BCG).

## 📈 Dashboard
### Fase 1 — Análise exploratória (diagnóstico multidimensional)
![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)
![alt text](image-4.png)
<img width="1357" height="767" alt="image" src="https://github.com/user-attachments/assets/608d2514-63eb-46ea-80ea-10b9aa1e7b65" />


### 💡 Descobertas — Análise exploratória

- **O negócio não está em crescimento sustentado — está estável dentro de um padrão sazonal.**
  A média móvel de 3 meses não mostra uma trajetória ascendente ao longo dos 3 anos: o lucro
  mensal oscila repetidamente na mesma faixa (~$2.400 a ~$5.980), sem ganhar nem perder patamar de
  um ano para o outro. Essa oscilação forte (CV de 1,09) não é instabilidade aleatória — é
  sazonalidade estrutural e consistente: Q1 e Q3 sistematicamente fracos, Q2 e Q4 fortes. A queda
  de -33% no Q1 2024 insere-se nesse padrão, mas com uma magnitude que se destaca do resto da
  série, o que justificou a investigação mais profunda.

- **Office Supplies tem uma estrutura de custo desalinhada.** O custo de envio consome 34% do
  valor de venda da categoria — 4 a 11x mais do que nas restantes (3-8%) — resultando na menor
  margem do portfólio (17%, vs. 32-38% nas outras categorias).

- **A rentabilidade está concentrada em produtos, não em geografias.** 40% dos produtos (16 de 40)
  geram 80% do lucro; já a nível de país, é preciso somar 13 dos 20 mercados para atingir a mesma
  fatia — a dependência geográfica é baixa, a dependência de produto é alta.

- **As regiões menos rentáveis são as mais dependentes de desconto.** América do Sul e Médio
  Oriente/África têm a maior dependência de desconto (9,3%) e também o menor lucro absoluto —
  o oposto da América do Norte, a região mais eficiente e a que menos desconta.

- **O segmento Consumer concentra tanto o lucro quanto o risco.** Gera 55% do lucro total e tem o
  perfil "Premium" (preço e margem altos) — mas foi também o único segmento a cair no Q1 2024
  (-43%), enquanto Corporate e Home Office se mantiveram estáveis. Isso explica por que a queda
  agregada (-33%) ficou abaixo da queda do próprio Consumer.

- **Corporate e Home Office têm picos de crescimento pontuais e fortes:** +160% no Q3 2025 e +83%
  no Q4 2025, respetivamente — os dois sinais que motivaram as perguntas 3.2 e 3.3 da decomposição.

## 🔎 Fase 2 — Decomposição (motivada pelos resultados da Fase 1)
![alt text](image-5.png)
![alt text](image-6.png)
![alt text](image-8.png)
![alt text](image-9.png)
![alt text](image-10.png)
![alt text](image-11.png)
![alt text](image-12.png)
![alt text](image-13.png)
![alt text](image-14.png)
![alt text](image-15.png)

### 💡 Descobertas — Decomposição

- **A queda de -33% no lucro do Q1 2024 foi um problema de volume, não de preço ou desconto.**
  A redução de 19% nas unidades vendidas respondeu por 62% da queda; a diminuição de 13% no preço
  médio explicou outros 35%; o aumento de 17% no desconto médio teve impacto residual (3%). A
  contração concentrou-se fortemente na categoria Furniture (75% da queda), com destaque para
  Canadá, Argentina e México.

- **Office Supplies tem um problema estrutural de precificação de envio, não operacional.** O
  preço médio do produto ($11,14) é inferior ao custo médio de envio por pedido ($12,67) — o envio
  chega a representar 114% do valor do produto. Resultado: 79% das transações da categoria (406 de
  513 pedidos) são deficitárias, a única entre as quatro categorias nessa situação.

- **A queda do Q1 2024 foi quase inteiramente um problema do segmento Consumer.** O Consumer caiu
  -43% no período — impulsionado 86% por perda de volume, ligada a uma queda de 27,9% em clientes
  ativos — enquanto Corporate e Home Office se mantiveram estáveis. A contração concentrou-se em
  Furniture (63%), nos mesmos países do driver geral: Canadá, Argentina, México, Itália e Reino
  Unido.

- **O crescimento de +160% do Corporate no Q3 2025 veio de monetização, não de mais clientes — e
  parte dele é expansão geográfica, não melhoria orgânica.** O preço médio (+60%) explicou 64% do
  crescimento, contra apenas +10% em clientes ativos — sinal de venda mais cara à base existente,
  mais do que conquista de mercado. Concentrado em Furniture (60%), com França, México e Alemanha à
  frente; vários destes países entraram como mercado novo em 2025, o que infla a leitura percentual
  isolada de cada país.

- **O crescimento de +83% do Home Office no Q4 2025 é o mais saudável dos três sinais.** Foi
  puxado por preço (+53%, 70% do crescimento) e reforçado por volume (+40%) e mais clientes ativos
  (+26%) — com o desconto médio a *cair* 8% no mesmo período. Ou seja, cresceu sem depender de mais
  desconto, ao contrário do padrão mais comum. Concentrado em Furniture (77%), liderado por Reino
  Unido, França e Itália.

  ## 📂 Estrutura deste projeto
  ├── sql/                  → scripts de criação, ETL e análise (numerados por ordem de execução)
├── power-bi/             → ficheiros .pbix dos dashboards
├── relatorio/             → relatório executivo (pptx + pdf)
├── documentacao/          → documento de contextualização do projeto
└── imagens/               → capturas de ecrã usadas neste README
