-- PROJECTO:   Global E-Commerce Sales & Customer Data
-- FICHEIRO:   03_queries_de_analise
-- OBJECTIVO:  Queries de análise sobre as 4 tabelas normalizadas
--             (location, products, customers, orders)
-- AUTOR:      Etelvino Ngola Joaquim
-- DATA:       2026-05-16
--
--
-- ORDEM DAS ANÁLISES:
--   1. Visão geral (KPIs)
--   2. Análise Temporal
--   3. Análise por produto e categoria
--   4. Análise Geográfica/Regional
--   5. Análise por cliente e segmento
--

-- ANÁLISE 1 — Visão geral de vendas
-- KPIs gerais do negócio: Faturamentol, Lucro,
-- Total de Pedidos, margem % e Ticket Médio.


-- KPIs Gerais
select
round(sum(quantity * unit_price),2) as faturamento_bruto,
sum(total_sales) as faturamento_liquido,
sum(profit) as lucro,
count(order_id) as total_pedidos,
sum(quantity) as quantidade,
round(sum(profit) / sum(total_sales),4) as margem_perct,
round(sum(total_sales) / count(order_id),2) as ticket_medio,
round(sum(quantity*unit_price)- sum(total_sales),2) as desconto,
round(sum(shipping_cost),2) as custo_de_envio,
round(sum(product_cost),2) as custo_de_produto
from orders;
--________________________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________________



-- ANÁLISE TEMPORAL

-- Pergunta 1 - Estamos a crescer ao longo do tempo?
-- objetivo: analisar a evolução mensal do lucro e identificar a tendência geral de crescimento ou retração
-- método:
-- 1. agregar o lucro por mês
-- 2. calcular a variação mês contra mês (MoM)
-- 3. aplicar uma média móvel de 3 meses para suavizar oscilações de curto prazo
-- 4. avaliar a direção da tendência ao longo do período
--
-- agrega o lucro por mês
with lucro_mensal as ( 
    select
        date_trunc('month', order_date) as mes,
        to_char(order_date, 'Mon') as nome_mes,
        extract(year from order_date) as ano,
        'Q' || extract(quarter from o.order_date)::text as trimestre,
        sum(profit) as lucro
    from orders o
    group by 1,2,3,4)
--
select
      ano,
      nome_mes,
      trimestre,
      lucro,
      lag(lucro,1,0) over (order by mes) as mes_anterior, -- lucro do mês anterior para cálculo do MoM
      coalesce(round((lucro - lag(lucro) over (order by mes)) / nullif(lag(lucro) over (order by mes), 0),4),0) as crescimento_mom, -- crescimento mês contra mês (Month over Month)
      round(avg(lucro) over (order by mes rows between 2 preceding and current row),2) as linha_de_tendencia  -- média móvel de 3 meses usada como linha de tendência
from lucro_mensal     
order by mes;
-- ----------------------------------------------------------------------------------


-- Pergunta 2 - Como evoluiu o lucro em relação ao mesmo trimestre do ano anterior?
-- objetivo: medir o crescimento ou retração do lucro através da variação YoY (Year over Year)
-- método:
-- 1. agregar o lucro por ano e trimestre
-- 2. comparar cada trimestre com o mesmo trimestre do ano anterior
-- 3. calcular a variação percentual YoY
-- 4. analisar a consistência do crescimento ao longo do tempo
--
-- agrega o lucro por ano e trimestre
with trimestres as ( 
    select
        extract(year from order_date)    as ano,
        'Q' || extract(quarter from o.order_date)::text as trimestre,
        sum(profit) as lucro_total
    from orders o
    group by 1, 2),
--
-- recupera o lucro do mesmo trimestre do ano anterior e partition by trimestre garante comparações sazonalmente equivalentes
    yoy as (
    select 
        ano, 
        trimestre, 
        lucro_total,
        lag(lucro_total) over (partition by trimestre order by ano) as lucro_ano_anterior
    from trimestres)
--
select 
    ano, 
    trimestre, 
    lucro_total, 
    lucro_ano_anterior,
    round((lucro_total - lucro_ano_anterior)::numeric / lucro_ano_anterior::numeric , 4) AS yoy_pct -- crescimento/retração vs mesmo trimestre do ano anterior
from yoy
where lucro_ano_anterior is not null -- exclui 2023 (sem base anterior)
order by ano, trimestre;
-- ----------------------------------------------------------------------------------


-- Pergunta 3 - O crescimento é consistente ou instável ao longo do tempo?
-- objetivo: avaliar a estabilidade do crescimento através da dispersão dos resultados YoY
-- método:
-- 1. calcular o lucro por trimestre
-- 2. calcular o YoY de cada trimestre
-- 3. medir a média e a volatilidade dos YoY
-- 4. calcular o coeficiente de variação (CV) para avaliar a consistência do crescimento
--
-- agrega o lucro por ano e trimestre
with trimestres as ( 
    select
        extract(year from order_date)    as ano,
        extract(quarter from order_date) as trimestre,
        sum(profit) as lucro_total
    from orders
    group by 1, 2),
--
-- recupera o lucro do mesmo trimestre do ano anterior e partition by trimestre garante comparações sazonalmente equivalentes
yoy as (select ano, trimestre, lucro_total,
        lag(lucro_total) over (partition by trimestre order by ano) as lucro_ano_anterior
    from trimestres)
--
-- calcula estatísticas descritivas dos YoY
select
    round(avg(yoy_pct), 2) as media_yoy,
    round(stddev(yoy_pct), 2) as desvio_padrao,
    round(stddev(yoy_pct) / avg(yoy_pct) * 100, 2) as coeficiente_variacao
FROM (
    SELECT (lucro_total - lucro_ano_anterior)/ lucro_ano_anterior * 100 as yoy_pct
    from yoy
    where lucro_ano_anterior is not null
) t;
-- ----------------------------------------------------------------------------------


-- Pergunta 4 - Existem padrões sazonais recorrentes no negócio?
-- objetivo: identificar se determinados trimestres apresentam desempenho consistentemente acima ou abaixo da média histórica
-- método:
-- 1. calcular o lucro total por trimestre
-- 2. calcular a média global de todos os trimestres
-- 3. calcular a média histórica de cada trimestre
-- 4. construir um índice sazonal para medir o desvio em relação à média global
--
-- agrega o lucro por ano e trimestre
with trimestres as (
    select
        extract(year from order_date)    as ano,
        'Q' || extract(quarter from o.order_date)::text as trimestre,
        sum(profit) as lucro_total
    from orders o
    group by 1, 2),
--
-- calcula a média global de lucro considerando todos os trimestres
media_geral as (
    select avg(lucro_total) as media_global
    from trimestres), -- usamos o CTE do trimestre
--
-- calcula a média de cada trimestre ao longo dos anos    
media_trimestre as ( 
    select trimestre,
        avg(lucro_total) as media_trim
    from trimestres
    group by trimestre)
--
select 
    mt.trimestre,
    round(mt.media_trim, 2) as media_trimestre,
    round(mg.media_global, 2) as media_global,
    round(mt.media_trim / mg.media_global, 2) as indice_sazonal
from media_trimestre mt
cross join media_geral mg
order by mt.trimestre;
--________________________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________________



-- ANÁLISE DE PRODUTO

-- Pergunta 1: Quantos produtos concentram a maior parte da rentabilidade do negócio?
-- objetivo: identificar os produtos responsáveis por aproximadamente 80% do lucro total
-- visão analítica: aplica o princípio de Pareto para verificar se a rentabilidade está concentrada num grupo reduzido de produtos ou distribuída de forma equilibrada.
--
-- calcula o lucro acumulado por produto
with lucro_por_produto as ( 
    select p.product_name as produto,
        sum(o.profit) as lucro
    from orders o
    inner join products p on p.product_id = o.product_id
    group by 1),
--
-- lucro total do negócio utilizado como denominador
lucro_total as (
    select sum(lucro) as total
    from lucro_por_produto),
--
-- calcula participação individual e acumulada de cada produto
pareto as (
    select produto,
        round(lucro, 2) as lucro,
        round(lucro / total, 4) as contribuicao_pct,
        round(sum(lucro) over (order by lucro desc), 2) as lucro_acumulado,
        round(sum(lucro / total) over (order by lucro desc), 4) as contribuicao_acumulada_pct
    from lucro_por_produto, lucro_total)
--
-- resultado final: produtos que compõem os primeiros 80% do lucro acumulado
select *
from pareto
where contribuicao_acumulada_pct < 0.80
order by lucro desc;
-- -----------------------------------------------------------------------------------------


-- Pergunta 2: O que mais pressiona a margem de cada categoria?
-- objetivo: decompor a rentabilidade por categoria e identificar os principais consumos da receita
-- visão analítica: compara o peso do custo do produto, descontos e custo de envio para
-- compreender quais factores reduzem a margem líquida de cada categoria
--
-- agrega as principais métricas financeiras por categoria
with base as (
    select
        p.product_category as categoria,
        sum(o.profit) as lucro_total,
        sum(o.total_sales) as faturamento_total,
        sum(o.shipping_cost) as envio_total,
		sum(o.product_cost) as custo_produto_total,
        sum(o.quantity * o.unit_price) as faturamento_bruto,
        sum((o.quantity * o.unit_price) - total_sales) as desconto_total
    from orders o
	inner join products p on p.product_id = o.product_id
    group by 1)
--
-- resultado final: decomposição dos componentes que impactam a margem
select categoria,
round(faturamento_bruto, 2) as faturamento,
round(lucro_total, 2) as lucro,  
round(lucro_total / faturamento_total, 4) as margem_pct, -- quanto do faturamento virou lucro
round(custo_produto_total / faturamento_total, 4) as peso_custo_produto_pct, -- quanto do faturamento foi consumido pelo custo do produto
round(desconto_total / faturamento_bruto, 4) as peso_desconto_pct, -- quanto do faturamento bruto foi perdido em desconto
round(envio_total / faturamento_total, 4) as peso_envio_pct -- quanto do faturamento foi consumido pelo custo de envio
from base
order by margem_pct;
--________________________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________________



-- ANÁLISE Geográfica/Rregional

-- Pergunta 1: Quais regiões dependem mais de desconto para vender?
-- objetivo: identificar regiões onde o desconto tem maior peso na geração de vendas
--
-- agrega métricas comerciais e de rentabilidade por região
with base as (
    select l.region as regiao,
        sum(o.total_sales)  as faturamento_total,
        sum(o.profit) as lucro_total,
        sum(o.quantity * o.unit_price) as faturamento_bruto,
        sum((o.quantity * o.unit_price) - o.total_sales) as desconto_total,
        avg(o.discount_percent) / 100 as desconto_medio_pct
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    inner join location l on l.country = c.country
    group by 1),
--
-- calcula a média global do peso do desconto utilizada como referência para classificar a dependência de cada região
media_desconto as (
    select avg(desconto_total / faturamento_bruto) as media_global_desconto
    from base)
--
select b.regiao,
    round(b.faturamento_total, 2) as faturamento,
    round(b.lucro_total, 2) as lucro,
    round(b.lucro_total / b.faturamento_total, 4) as margem_pct,-- margem liquida por regiao  
    round(b.desconto_medio_pct, 4) as desconto_medio_pct,-- desconto medio em percentagem do preco original
    round(b.desconto_total / b.faturamento_bruto, 4) as peso_desconto_pct,-- peso do desconto: quanto do faturamento bruto foi perdido em desconto
    round(md.media_global_desconto, 4) as media_global_desconto,
--
-- compara o peso do desconto da região com a média global para classificar
    case
        when b.desconto_total / b.faturamento_bruto > md.media_global_desconto then 'alta'
        else 'baixa'
    end as dependencia_desconto
from base b
cross join media_desconto md
order by peso_desconto_pct desc;
-- ---------------------------------------------------------------------------------------------------------


-- Pergunta 2: Quantos países são responsáveis por 80% do lucro?
-- objetivo: identificar os países que concentram a maior parte da rentabilidade do negócio
--
-- agrega o lucro total por país
with lucro_por_pais as (
    select
        l.region as regiao,
        c.country as pais,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    inner join location l on l.country = c.country
    group by 1, 2),
--
-- calcula o lucro total do negócio para servir de base ao Pareto
lucro_total as (
    select sum(lucro) as total
    from lucro_por_pais),
--
-- calcula a contribuição individual e acumulada de cada país
pareto as (
    select
        regiao,
        pais,
        round(lucro, 2) as lucro,
        round(lucro / total, 4) as contribuicao_pct,
        round(sum(lucro) over (order by lucro desc), 2) as lucro_acumulado,
        round(sum(lucro / total) over (order by lucro desc), 4) as contribuicao_acumulada_pct
    from lucro_por_pais, lucro_total)
--
-- resultado final: países que compõem os primeiros 80% do lucro acumulado
select *
from pareto
where contribuicao_acumulada_pct - contribuicao_pct < 0.80
order by lucro desc;
--________________________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________________



-- ANÁLISE DE CLIENTES

-- Pergunta 1: Qual segmento apresenta o melhor desempenho ao longo do tempo?
-- objetivo: analisar a evolução do lucro por segmento através do crescimento YoY trimestral
--
-- agrega o lucro por segmento, ano e trimestre
with base as (
    select
        c.customer_segment as segmento,
        extract(year from o.order_date) as ano,
        'Q' || extract(quarter from o.order_date)::text as trimestre,
        sum(o.profit) as lucro_total
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    group by 1, 2, 3),
--
-- compara cada trimestre com o mesmo trimestre do ano anterior partition by segmento e trimestre preserva o efeito sazonal
yoy as (
    select
        segmento,
        ano,
        trimestre,
        round(lucro_total,2) as lucro_total,
        lag(lucro_total) over (partition by segmento, trimestre order by ano) as lucro_anterior
    from base)
--
-- resultado final: crescimento YoY do lucro por segmento
select
    segmento,
    ano,
    trimestre,
    lucro_total,
    lucro_anterior,
    round((lucro_total - lucro_anterior)::numeric/ lucro_anterior::numeric, 4) as yoy_pct
from yoy
where lucro_anterior is not null -- exclui 2023 que serve como base
order by ano, trimestre, segmento;
-- --------------------------------------------------------------------------------------------------------


-- Pergunta 2: Qual é o posicionamento de valor de cada segmento?
-- objetivo: comparar volume, ticket médio e rentabilidade para identificar segmentos premium e segmentos de escala
-- visão analítica: segmentos premium tendem a combinar ticket médio elevado e boa margem, enquanto segmentos de escala compensam margens menores através de maior volume de vendas
--
-- calcula os principais indicadores de desempenho por segmento
select
    c.customer_segment as segmento,
    round(sum(o.total_sales), 2) as faturamento_total,
    round(sum(o.profit), 2) as lucro_total,
    round(sum(o.profit) / sum(o.total_sales), 4) as margem_pct,
    sum(o.quantity) as volume,
    round(sum(o.total_sales) / sum(o.quantity) , 2) as ticket_medio 
from orders o
inner join customers c on c.customer_id = o.customer_id
group by 1
order by margem_pct desc;