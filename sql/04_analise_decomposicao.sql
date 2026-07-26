-- PROJECTO:   Global E-Commerce Sales & Customer Data
-- FICHEIRO:   04_decomposição da analise de rentabilidade global
-- OBJECTIVO: Investigar os factores que explicam a evolução e a queda da rentabilidade através de análises de lucro, receita, volume, preço, desconto,
--             segmentos de clientes, categorias de produtos e regiões geográficas.
--
-- AUTOR:      Etelvino Ngola Joaquim
-- DATA:       2026-05-16
--
--
-- ORDEM DAS ANÁLISES/DECOMPOSIÇÕES:
--   1. Decomposição da queda de -33% do lucro no Q1 de 2024
--   2. Decomposição do aumento de 34% do custo de envio na categoria Office Supplies.
--   3. Decomposição dos segmentos
--   4. Decomposição Geográfica/Regional


-- 1ª Decomposição da queda de -33% no Q1 2024
-- Objetivo: identificar quais categorias, paises e segmentos mais contribuiram para a queda
-- metodo: self-join comparando Q1 2024 vs Q1 2023

-- Pergunta 1.1- Qual categoria mais contribuiu para a queda de -33% no Q1 2024?
-- Identifica as categorias que mais contribuíram para a variação total
-- contribuicao_pct: participação de cada categoria na variação total do lucro
--
-- agrega o lucro por categoria, ano e trimestre
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join products p
        on p.product_id = o.product_id
    where extract(year from o.order_date) in (2023, 2024) -- fitra apenas os anos de 2023 e 2024.
        and extract(quarter from o.order_date) = 1 -- filtra apenas o primeiro trimesttre de cada ano
    group by 1, 2, 3),
--
-- compara q1 2024 com q1 2023 utilizando self join    
comparacao as (
    select
        q1_2024.categoria,
        q1_2023.lucro as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro, 0) as variacao_pct
    from base q1_2024
    inner join base q1_2023
        on q1_2024.categoria = q1_2023.categoria
        and q1_2023.ano = 2023
        and q1_2024.ano = 2024),
--
-- calcula a variação líquida total da queda/negativo do lucro        
total as (
    select
        sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta < 0) -- apenas as categorias que contribuíram de forma negativa.
--
-- resultado final
select
    c.categoria,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct
from comparacao c
cross join total t
where c.variacao_absoluta < 0
order by variacao_absoluta asc;
-- ----------------------------------------------------------------------------------


-- Pergunta 1.2- Qual pais mais contribuiu para a queda do lucro de -33% no Q1 de 2024?
-- objetivo: identificar quais paises mais contribuiram para a queda
--
-- agrega o lucro por pais, ano e trimestre
with base as (
    select
        c.country as pais,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2023, 2024) -- fitra apenas os anos de 2023 e 2024.
        and extract(quarter from o.order_date) = 1 -- filtra apenas o primeiro trimesttre de cada ano
    group by 1, 2, 3),
--
 -- compara o lucro do Q1 2024 com o Q1 2023 por pais, self-join une o mesmo pais em dois anos diferentes
comparacao as (
    select
        q1_2024.pais,
        q1_2023.lucro as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro, 0) as variacao_pct -- variacao percentual para contextualizar a magnitude da queda por pais
    from base q1_2024
    inner join base q1_2023
        on q1_2023.pais = q1_2024.pais
        and q1_2023.ano = 2023
        and q1_2024.ano = 2024),
--
-- -- calcula a perda total observada entre q1 2024 e q1 2023 usada como denominador para medir a contribuição de cada pais
total as (
    select
        sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta < 0)
--
-- resultado final  → quanto cada pais representa da variacao total
select
    c.pais,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct
from comparacao c
cross join total t
where c.variacao_absoluta < 0  -- apenas paises que contribuiram para a queda
order by variacao_absoluta asc;
-- -----------------------------------------------------------------------------------


-- Pergunta 1.2.1- Decomposicao da queda de -33% no Q1 2024 por continente
-- visao agregada da analise por pais acima agrupa os paises por regiao/continente para identificar padroes geograficos macro
--
-- agrega o lucro por continente, ano e trimestre
with base as (
    select
        l.region as continente,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
	inner join location l on l.country = c.country
	 where extract(year from o.order_date) in (2023, 2024) -- fitra apenas os anos de 2023 e 2024.
        and extract(quarter from o.order_date) = 1 -- filtra apenas o primeiro trimesttre de cada ano
    group by 1, 2, 3),
--
-- compara o lucro do Q1 2024 com o Q1 2023 por continente, self-join une o mesmo continente em dois anos diferentes
comparacao as (
    select
        q1_2024.continente,
        q1_2023.lucro as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro,0) as variacao_pct -- variacao percentual para contextualizar a magnitude da queda por continente
    from base q1_2024
    inner join base q1_2023
        on q1_2023.continente = q1_2024.continente
        and q1_2023.ano = 2023
        and  q1_2024.ano = 2024),
--
-- calcula a variacao absoluta da queda total do Q1 2024 usado como denominador para calcular a contribuicao de cada continente
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
   where variacao_absoluta < 0)
--
-- resultado final com contribuicao percentual de cada continente contribuicao_pct → quanto cada continente representa da variacao total
select
    c.continente,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct
from comparacao c
cross join total t
where variacao_absoluta < 0
order by variacao_absoluta asc;
-- ----------------------------------------------------------------------------------


-- Pergunta 1.3- Qual segmento de clientes mais contribuiu para a queda do lucro de -33% no Q1 de 2024?
-- Identifica os segmentos que mais contribuíram para a variação total
-- contribuicao_pct: participação de cada segmento na variação total do lucro
-- 
-- agrega o lucro por segmento, ano e trimestre
with base as (
    select
        c.customer_segment as segmento,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2023, 2024) -- fitra apenas os anos de 2023 e 2024.
        and extract(quarter from o.order_date) = 1 -- filtra apenas o primeiro trimesttre de cada ano
    group by 1, 2, 3),
--
-- Compara o lucro do Q1 2024 vs Q1 2023 por segmento usando self-join
comparacao as (
    select
        q1_2024.segmento,
        q1_2023.lucro as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro,0) as variacao_pct
    from base q1_2024
    inner join base q1_2023
        on q1_2023.segmento = q1_2024.segmento
        and q1_2023.ano = 2023
        and q1_2024.ano = 2024),
--
-- Calcula a variação absoluta da queda total do lucro
-- usada como base (denominador) para medir a contribuição de cada segmento na variação total
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta < 0)
--
-- Resultado final com a participação percentual de cada segmento na variação total do lucro
select
    c.segmento,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct
from comparacao c
cross join total t
where variacao_absoluta < 0
order by variacao_absoluta asc;
-- ----------------------------------------------------------------------------------


-- Combinação - Top 10 combinações de país, categoria e segmento que mais contribuíram para a queda de lucro em Q1 2024
-- objetivo: identificar os principais focos de destruição de lucro através da combinação
-- país + categoria + segmento, permitindo localizar o epicentro da queda de rentabilidade.
--
with base as (
    select
        c.country as pais,
        p.product_category as categoria,
        c.customer_segment as segmento,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    inner join products p
        on p.product_id = o.product_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
    group by 1,2,3,4,5),
--
-- compara q1 2024 vs q1 2023
comparacao as (
    select
        q24.pais,
        q24.categoria,
        q24.segmento,
        q23.lucro as lucro_q1_2023,
        q24.lucro as lucro_q1_2024,
        q24.lucro - q23.lucro as variacao_absoluta,
        (q24.lucro - q23.lucro) / nullif(q23.lucro,0) as variacao_pct
    from base q24
    inner join base q23
        on q23.pais = q24.pais
        and q23.categoria = q24.categoria
        and q23.segmento = q24.segmento
        and q23.ano = 2023
        and q24.ano = 2024),
--
-- calcula apenas a perda total
total as (
    select
        sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta < 0),
--
-- cria o ranking das combinações com maior destruição de lucro    
ranking as (
    select
        c.pais,
        c.categoria,
        c.segmento,
        round(c.lucro_q1_2023,2) as lucro_q1_2023,
        round(c.lucro_q1_2024,2) as lucro_q1_2024,
        round(c.variacao_absoluta,2) as variacao_absoluta,
        round(c.variacao_pct,4) as variacao_pct,
        round(c.variacao_absoluta / nullif(t.variacao_total,0),4) as contribuicao_pct,
        row_number() over (order by c.variacao_absoluta asc ) as ranking
    from comparacao c
    cross join total t
    where c.variacao_absoluta < 0)
--
-- resultado final: top 10 combinações que mais contribuíram para a queda de lucro
select
    ranking,
    pais,
    categoria,
    segmento,
    lucro_q1_2023,
    lucro_q1_2024,
    variacao_absoluta,
    variacao_pct,
    contribuicao_pct
from ranking
where ranking <= 10
order by ranking;
-- ----------------------------------------------------------------------------------


-- Pergunta 1.5 - Foi volume, preco ou desconto o principal driver da queda de -33% no Q1 2024?
-- objetivo: identificar qual componente mais contribuiu para a queda
-- metodo: compara volume, preco medio e desconto entre Q1 2024 e Q1 2023
--
-- agrega os componentes de crescimento por ano e trimestre
with base as (
    select
        extract(year from o.order_date)    as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity)                    as volume,
        sum(o.quantity * o.unit_price)     as faturamento,
        sum(o.total_sales)                 as receita
    from orders o
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
    group by 1, 2),
--
-- compara q1 2024 vs q1 2023
comparacao as (
    select
        q23.volume        as volume_2023,
        q24.volume        as volume_2024,
        q23.faturamento   as faturamento_2023,
        q24.faturamento   as faturamento_2024,
        q23.receita as receita_2023,
        q24.receita as receita_2024
    from base q24
    inner join base q23
        on q23.ano = 2023 
        and q24.ano = 2024),
--
-- calcula preco medio e desconto efetivo
drivers as (
    select
        volume_2023,
        volume_2024,
        receita_2023,
        receita_2024,
        faturamento_2023 / nullif(volume_2023, 0) as preco_2023,
        faturamento_2024 / nullif(volume_2024, 0)  as preco_2024,
        1 - (receita_2023 / nullif(faturamento_2023, 0)) as desconto_2023,
        1 - (receita_2024 / nullif(faturamento_2024, 0)) as desconto_2024
    from comparacao),
--
-- calcula o impacto isolado de cada driver
impactos as (
    select
        round((volume_2024 - volume_2023) * preco_2023 * (1 - desconto_2023), 2) as impacto_volume,
        round(volume_2024 * (preco_2024 - preco_2023) * (1 - desconto_2023), 2) as impacto_preco,
        round(volume_2024 * preco_2024 * (desconto_2023 - desconto_2024), 2)  as impacto_desconto,
        round(receita_2024 - receita_2023, 2) as variacao_total
    from drivers)
--
-- formata o resultado em linhas por driver
select
    driver,
    impacto,
    round(abs(impacto) / nullif(abs(variacao_total), 0), 4) as peso_na_queda
from impactos,
lateral (values
    ('Volume', impacto_volume),
    ('Preco', impacto_preco),
    ('Desconto', impacto_desconto)
) as t(driver, impacto)
order by
    case driver
        when 'Volume'         then 1
        when 'Preco'          then 2
        when 'Desconto'       then 3
    end;
-- ----------------------------------------------------------------------------------


-- Pergunta 1.5.1 - Como evoluíram volume, preço médio e desconto médio no periodo de 2024 Q1?
-- objetivo: comparar os indicadores operacionais entre Q1 2023 e Q1 2024
-- metodo: calcular volume total, preço médio e desconto médio para cada período
--
-- agrega as métricas por ano e trimestre
with base as (
    select
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity) as volume,
        sum(o.quantity * o.unit_price) as faturamento,
        sum(o.total_sales) as receita
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
    group by 1,2),
--
-- organiza os dois períodos para comparação
comparacao as (
    select
        q23.volume as volume_2023,
        q24.volume as volume_2024,
        q23.faturamento / nullif(q23.volume,0) as preco_medio_2023,
        q24.faturamento / nullif(q24.volume,0) as preco_medio_2024,
        1 - (q23.receita / nullif(q23.faturamento,0)) as desconto_medio_2023,
        1 - (q24.receita / nullif(q24.faturamento,0)) as desconto_medio_2024
    from base q23
    inner join base q24
        on q23.ano = 2023
        and q24.ano = 2024)
--
-- resultado final
-- utiliza union all para consolidar as três métricas numa única tabela, facilitando a comparação entre volume, preço médio e desconto médio
select
    'Volume' as metrica,
    volume_2023 as q1_2023,
    volume_2024 as q1_2024,
    volume_2024 - volume_2023 as variacao_absoluta,
	round((volume_2024 - volume_2023)::numeric / nullif(volume_2023, 0)::numeric, 4) as variacao_pct
from comparacao
union all
--
select
    'Preço Médio Unitário',
    round(preco_medio_2023,2),
    round(preco_medio_2024,2),
    round(preco_medio_2024 - preco_medio_2023,2),
    round((preco_medio_2024 - preco_medio_2023) / nullif(preco_medio_2023,0),4)
from comparacao
union all
--
select
    'Desconto Médio Efetivo',
    round(desconto_medio_2023 * 100,2),
    round(desconto_medio_2024 * 100,2),
    round((desconto_medio_2024 - desconto_medio_2023) * 100,2),
    round((desconto_medio_2024 - desconto_medio_2023) / nullif(desconto_medio_2023,0),4)
from comparacao;
-- -----------------------------------------------------------------------------------

-- 1.5.2 - A queda do volume em Q1 2024 foi provocada pela perda de clientes?
-- objetivo: comparar a evolução da base de clientes activos e do volume vendido para verificar se existe associação entre ambos.
--
-- agrega clientes activos, volume e lucro por período
with base as (
    select
        extract(year from o.order_date) as ano,
        count(distinct o.customer_id) as clientes_activos,
        sum(o.quantity) as volume_total,
        round(sum(o.profit)::numeric, 2) as lucro_total
    from orders o
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
    group by 1),
--
-- organiza os indicadores numa estrutura comparativa entre Q1 2023 e Q1 2024
comparacao as (
    select
        'Clientes activos'  as indicadores,
        max(case when ano = 2023 then clientes_activos::text end) as q1_2023,
        max(case when ano = 2024 then clientes_activos::text end) as q1_2024,
        max(case when ano = 2024 then clientes_activos end) - max(case when ano = 2023 then clientes_activos end)   as variacao_absoluta,
        round((max(case when ano = 2024 then clientes_activos end) - max(case when ano = 2023 then clientes_activos end))::numeric /
            nullif(max(case when ano = 2023 then clientes_activos end), 0), 4) as variacao_pct
    from base
    union all
--
-- compara a evolução do volume vendido
    select
        'Volume total',
        max(case when ano = 2023 then volume_total::text end),
        max(case when ano = 2024 then volume_total::text end),
        max(case when ano = 2024 then volume_total end) - max(case when ano = 2023 then volume_total end),
        round((max(case when ano = 2024 then volume_total end) - max(case when ano = 2023 then volume_total end))::numeric /
            nullif(max(case when ano = 2023 then volume_total end), 0), 4)
    from base
    union all
--
-- compara a evolução do lucro total
    select
        'Lucro total',
        max(case when ano = 2023 then lucro_total::text end),
        max(case when ano = 2024 then lucro_total::text end),
        max(case when ano = 2024 then lucro_total end) -
        max(case when ano = 2023 then lucro_total end),
        round( (max(case when ano = 2024 then lucro_total end) - max(case when ano = 2023 then lucro_total end))::numeric /
            nullif(max(case when ano = 2023 then lucro_total end), 0), 4)
    from base)
--
-- resultado final
-- consolida os indicadores numa única visão para avaliar se a redução do volume acompanha a redução da base de clientes
select
    indicadores,
    q1_2023,
    q1_2024,
    variacao_absoluta,
    variacao_pct
from comparacao;
-- interpretação:
-- se a queda percentual dos clientes activos for próxima da queda do volume,
-- então a redução das vendas está fortemente associada à perda de clientes.
--
-- se o volume cair mais do que a base de clientes,
-- isso indica que os clientes remanescentes também passaram a comprar menos.
-- -----------------------------------------------------------------------------------


-- 1.5.3 - A redução do preço médio em Q1 2024 foi provocada por queda de preços ou alteração do mix de produtos?
-- objetivo: analisar a evolução do preço médio por categoria para distinguir o efeito preço do efeito mix.
--
-- visão analítica:
-- se a maioria das categorias apresentar redução de preço, existe evidência de queda real dos preços.
-- se os preços permanecerem estáveis, a variação tende a ser explicada por alterações no mix de produtos vendidos.
--
-- calcula o preço médio unitário por categoria e período
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        round(sum(o.quantity * o.unit_price)::numeric / nullif(sum(o.quantity), 0), 2) as preco_medio
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
    group by 1, 2)
--
-- compara o preço médio de cada categoria entre Q1 2023 e Q1 2024
select
    b.categoria,
    max(case when ano = 2023 then preco_medio end) as preco_2023,
    max(case when ano = 2024 then preco_medio end) as preco_2024,
    round(max(case when ano = 2024 then preco_medio end) - max(case when ano = 2023 then preco_medio end), 2) as variacao_absoluta,
    round((max(case when ano = 2024 then preco_medio end) - max(case when ano = 2023 then preco_medio end)) /
        nullif(max(case when ano = 2023 then preco_medio end), 0), 4)  as variacao_pct
from base b
group by b.categoria
order by b.categoria;
--_______________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________


-- 2ª Decomposição do Custo de Envio
-- objetivo: identificar os factores que explicam o aumento de 34% do custo de envio na categoria Office Supplies.

-- 2.1 - O que explica o peso de 34% do custo de envio em Office Supplies?
-- objetivo: comparar métricas operacionais entre categorias para identificar os factores
-- que tornam o custo de envio proporcionalmente mais elevado em Office Supplies.
select
    p.product_category as categoria,
    count(o.order_id) as num_pedidos,
    sum(o.quantity) as unidades_vendidas,
    round(sum(o.total_sales) / count(o.order_id), 2) as ticket_medio_pedido,
    round(sum(o.total_sales) / sum(o.quantity), 2) as preco_medio_unidade,   
    round(sum(o.shipping_cost) / count(o.order_id), 2) as envio_medio_pedido,  -- custo de envio medio por pedido
    round(sum(o.shipping_cost) / sum(o.quantity), 2) as envio_medio_unidade, -- custo de envio medio por unidade
    round(sum(o.shipping_cost) / sum(o.total_sales), 4) as peso_envio_pct -- peso do envio sobre faturamento
from orders o
inner join products p on p.product_id = o.product_id
group by 1
order by peso_envio_pct desc;
-- ----------------------------------------------------------------------------------


-- 2.2.1 - Em quais categorias o custo de envio supera o lucro gerado?
-- objetivo: identificar categorias com maior concentração de transações deficitárias.
--
-- visão analítica:
-- quanto maior a percentagem de transações em que o envio excede o lucro, maior o risco de erosão da rentabilidade da categoria.
--
select
    p.product_category as categoria,
    count(o.order_id) as total_transacoes,
    sum(case when o.shipping_cost > o.profit then 1 else 0 end) as transacoes_deficitarias,
    round(sum(case when o.shipping_cost > o.profit then 1 else 0 end)::numeric  / count(o.order_id), 4) as pct_deficitarias
from orders o
inner join products p on p.product_id = o.product_id
group by 1
order by pct_deficitarias desc;
--_______________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________


-- 3ª Decomposição dos Segmentos
-- objetivo: identificar os factores que explicam os maiores movimentos de crescimento e retracção entre os segmentos.

-- Pergunta 3.1- O que causou a queda do Consumer em Q1 2024?
-- Analisar os fatores que contribuíram para a queda do segmento Consumer no Q1 2024 em comparação ao Q1 2023.

-- 3.1.1 — Perspectiva por Categoria
-- Objetivo: Identificar quais categorias de produtos mais contribuíram para a queda do lucro do segmento Consumer no Q1 2024 versus Q1 2023.
--
-- Visão analítica: A análise por categoria permite compreender se a deterioração do resultado foi impulsionada por linhas específicas de produtos, 
-- evidenciando quais categorias exerceram maior pressão sobre a rentabilidade do segmento.
--
-- agrega o lucro por categoria e trimestre filtrado apenas para o segmento Consumer
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'  -- filtro do segmento
    group by 1, 2, 3),
--
-- compara Q1 2024 vs Q1 2023 por categoria
comparacao as (
    select
        q1_2024.categoria,
        q1_2023.lucro  as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro, 0) as variacao_pct
    from base q1_2024
    inner join base q1_2023
        on q1_2023.categoria = q1_2024.categoria
        and q1_2023.ano = 2023
        and q1_2024.ano = 2024),
--
-- variacao da queda total do Consumer no Q1 2024
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta < 0)
--
select
    c.categoria,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct -- contribuicao de cada categoria para a queda total do Consumer
from comparacao c
cross join total t
where c.variacao_absoluta < 0
order by variacao_absoluta asc;
-------------------------------------------------------------------------------------


-- 3.1.2 — Perspectiva por País
-- Objetivo: Identificar quais países mais contribuíram para a queda do lucro do segmento Consumer no Q1 2024 versus Q1 2023.
-- Visão analítica: A análise por país permite localizar geograficamente os principais focos de deterioração do resultado, 
-- evidenciando quais mercados apresentaram maior impacto negativo sobre o desempenho do segmento Consumer.
--
-- agrega o lucro por pais e trimestre filtrado apenas para o segmento Consumer
with base as (
    select
        c.country as pais,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q1 2024 vs Q1 2023 por pais
comparacao as (
    select
        q1_2024.pais,
        q1_2023.lucro  as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro, 0) as variacao_pct
    from base q1_2024
    inner join base q1_2023
        on q1_2023.pais = q1_2024.pais
        and q1_2023.ano = 2023
        and q1_2024.ano = 2024),
--
-- variacao total do Consumer no Q1 2024
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta < 0)
--
select
    c.pais,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct -- contribuicao de cada pais para a queda total do Consumer
from comparacao c
cross join total t
where c.variacao_absoluta < 0
order by variacao_absoluta asc;
-------------------------------------------------------------------------------------

-- 3.1.3 — Perspectiva por Continente
-- Objetivo: Identificar quais continentes mais contribuíram para a queda do lucro do segmento Consumer no Q1 2024 versus Q1 2023.
-- Visão analítica: A análise por continente permite avaliar o comportamento regional agregado do segmento Consumer, 
-- identificando se a queda foi concentrada em mercados específicos ou disseminada entre diferentes regiões.
--
-- agrega o lucro por continente e trimestre filtrado apenas para o segmento Consumer
with base as (
    select
        l.region as continente,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
	inner join location l on l.country = c.country
	 where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q1 2024 vs Q1 2023 por continente
comparacao as (
    select
        q1_2024.continente,
        q1_2023.lucro  as lucro_q1_2023,
        q1_2024.lucro as lucro_q1_2024,
        q1_2024.lucro - q1_2023.lucro as variacao_absoluta,
        (q1_2024.lucro - q1_2023.lucro) / nullif(q1_2023.lucro, 0) as variacao_pct
    from base q1_2024
    inner join base q1_2023
        on q1_2023.continente = q1_2024.continente
        and q1_2023.ano = 2023
        and q1_2024.ano = 2024),
--
-- variacao total do Consumer no Q1 2024
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta < 0)
--
select
    c.continente,
    round(c.lucro_q1_2023, 2) as lucro_q1_2023,
    round(c.lucro_q1_2024, 2) as lucro_q1_2024,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct -- contribuicao de cada continente para a queda total do Consumer
from comparacao c
cross join total t
where c.variacao_absoluta < 0
order by variacao_absoluta asc;
-- ----------------------------------------------------------------------------------

-- 3.1.4 - Perspectiva: Combinação de País e categoria
-- OBJETIVO: identificar o epicentro exacto da queda
with base as (
    select
        c.country as pais,
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    inner join products p on p.product_id = o.product_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'  -- filtro do segmento
    group by 1,2,3,4),
--
-- compara q1 2024 vs q1 2023
comparacao as (
    select
        q24.pais,
        q24.categoria,
        q23.lucro as lucro_q1_2023,
        q24.lucro as lucro_q1_2024,
        q24.lucro - q23.lucro as variacao_absoluta,
        (q24.lucro - q23.lucro) / nullif(q23.lucro,0) as variacao_pct
    from base q24
    inner join base q23
        on q23.pais = q24.pais
        and q23.categoria = q24.categoria
        and q23.ano = 2023
        and q24.ano = 2024),
--
-- calcula apenas a perda total
total as (
    select
        sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta < 0),
--
-- cria o ranking das combinações com maior destruição de lucro    
ranking as (
    select
        c.pais,
        c.categoria,
        round(c.lucro_q1_2023,2) as lucro_q1_2023,
        round(c.lucro_q1_2024,2) as lucro_q1_2024,
        round(c.variacao_absoluta,2) as variacao_absoluta,
        round(c.variacao_pct,4) as variacao_pct,
        round(c.variacao_absoluta / nullif(t.variacao_total,0),4) as contribuicao_pct,
        row_number() over (order by c.variacao_absoluta asc ) as ranking
    from comparacao c
    cross join total t
    where c.variacao_absoluta < 0)
--
-- resultado final: top 10 combinações que mais contribuíram para a queda de lucro
select
    ranking,
    pais,
    categoria,
    lucro_q1_2023,
    lucro_q1_2024,
    variacao_absoluta,
    variacao_pct,
    contribuicao_pct
from ranking
where ranking <= 10
order by ranking;
-- -----------------------------------------------------------------------------------


-- Pergunta 3.1.5 - Foi volume, preco ou desconto o principal driver da queda de consumer no Q1 2024?
-- objetivo: identificar qual componente mais contribuiu para a queda
-- metodo: compara volume, preco medio e desconto entre Q1 2024 e Q1 2023
--
-- agrega os componentes de crescimento por ano e trimestre
with base as (
    select
        extract(year from o.order_date)    as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity)                    as volume,
        sum(o.quantity * o.unit_price)     as faturamento,
        sum(o.total_sales)                 as receita
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'  -- filtro do segmento
    group by 1, 2),
--
-- compara q1 2024 vs q1 2023
comparacao as (
    select
        q23.volume        as volume_2023,
        q24.volume        as volume_2024,
        q23.faturamento   as faturamento_2023,
        q24.faturamento   as faturamento_2024,
        q23.receita as receita_2023,
        q24.receita as receita_2024
    from base q24
    inner join base q23
        on q23.ano = 2023 
        and q24.ano = 2024),
--
-- calcula preco medio e desconto efetivo
drivers as (
    select
        volume_2023,
        volume_2024,
        receita_2023,
        receita_2024,
        faturamento_2023 / nullif(volume_2023, 0) as preco_2023,
        faturamento_2024 / nullif(volume_2024, 0)  as preco_2024,
        1 - (receita_2023 / nullif(faturamento_2023, 0)) as desconto_2023,
        1 - (receita_2024 / nullif(faturamento_2024, 0)) as desconto_2024
    from comparacao),
--
-- calcula o impacto isolado de cada driver
impactos as (
    select
        round((volume_2024 - volume_2023) * preco_2023 * (1 - desconto_2023), 2) as impacto_volume,
        round(volume_2024 * (preco_2024 - preco_2023) * (1 - desconto_2023), 2) as impacto_preco,
        round(volume_2024 * preco_2024 * (desconto_2023 - desconto_2024), 2)  as impacto_desconto,
        round(receita_2024 - receita_2023, 2) as variacao_total
    from drivers)
--
-- formata o resultado em linhas por driver
select
    driver,
    impacto,
    round(impacto / nullif(variacao_total, 0), 4) as peso_na_queda
from impactos,
lateral (values
    ('Volume', impacto_volume),
    ('Preco', impacto_preco),
    ('Desconto', impacto_desconto)
) as t(driver, impacto)
order by
    case driver
        when 'Volume'         then 1
        when 'Preco'          then 2
        when 'Desconto'       then 3
    end;
-- ------------------------------------------------------------------------------------


-- Pergunta 3.1.5.1 - Como evoluíram volume, preço médio e desconto médio do segmento Consumer?
-- objetivo: comparar os indicadores operacionais entre Q1 2023 e Q1 2024
-- metodo: calcular volume total, preço médio e desconto médio para cada período
--
-- agrega as métricas por ano e trimestre
with base as (
    select
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity) as volume,
        sum(o.quantity * o.unit_price) as faturamento,
        sum(o.total_sales) as receita
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'
    group by 1,2),
--
-- organiza os indicadores numa estrutura comparativa entre Q1 2023 e Q1 2024 para o segmento consumer
comparacao as (
    select
        q23.volume as volume_2023,
        q24.volume as volume_2024,
        q23.faturamento / nullif(q23.volume,0) as preco_medio_2023,
        q24.faturamento / nullif(q24.volume,0) as preco_medio_2024,
        1 - (q23.receita / nullif(q23.faturamento,0)) as desconto_medio_2023,
        1 - (q24.receita / nullif(q24.faturamento,0)) as desconto_medio_2024
    from base q23
    inner join base q24
        on q23.ano = 2023
        and q24.ano = 2024)
--
-- resultado final
-- consolida os indicadores numa única visão para avaliar
--
-- compara a evolução do volume vendido
select
    'Volume' as metrica,
    volume_2023 as q1_2023,
    volume_2024 as q1_2024,
    volume_2024 - volume_2023 as variacao_absoluta,
	round((volume_2024 - volume_2023)::numeric / nullif(volume_2023, 0)::numeric, 4) as variacao_pct
from comparacao
union all
--
-- compara a evolução do preço médio unitário
select
    'Preço Médio Unitário',
    round(preco_medio_2023,2),
    round(preco_medio_2024,2),
    round(preco_medio_2024 - preco_medio_2023,2),
    round((preco_medio_2024 - preco_medio_2023) / nullif(preco_medio_2023,0),4)
from comparacao
union all
--
-- compara a evolução do desconto médio
select
    'Desconto Médio Efetivo',
    round(desconto_medio_2023 * 100,2),
    round(desconto_medio_2024 * 100,2),
    round((desconto_medio_2024 - desconto_medio_2023) * 100,2),
    round((desconto_medio_2024 - desconto_medio_2023) / nullif(desconto_medio_2023,0),4)
from comparacao;
-- -------------------------------------------------------------------------------------


-- 3.1.5.2 - Evolução da base de clientes activos do Consumer: Q1 2023 vs Q1 2024
-- objetivo: determinar se a queda de volume está associada à perda de clientes activos
-- metodologia:
-- 1. contabilizar clientes activos (clientes com pelo menos uma compra no período)
-- 2. calcular volume total vendido e lucro total
-- 3. comparar Q1 2024 com Q1 2023
-- 4. medir a variação absoluta e percentual dos indicadores
--
-- agrega clientes activos, volume e lucro por ano
with base as (
    select
        extract(year from o.order_date) as ano,
        count(distinct o.customer_id) as clientes_activos,
        sum(o.quantity) as volume_total,
        round(sum(o.profit)::numeric, 2) as lucro_total
    from orders o
    inner join customers c on c.customer_id = o.customer_id 
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'
    group by 1),
--
-- organiza os indicadores para comparação entre os períodos
comparacao as (
    select
        'Clientes activos'  as indicadores,
        max(case when ano = 2023 then clientes_activos::text end) as q1_2023,
        max(case when ano = 2024 then clientes_activos::text end) as q1_2024,
        max(case when ano = 2024 then clientes_activos end) - max(case when ano = 2023 then clientes_activos end)   as variacao_absoluta,
        round((max(case when ano = 2024 then clientes_activos end) - max(case when ano = 2023 then clientes_activos end))::numeric /
            nullif(max(case when ano = 2023 then clientes_activos end), 0), 4) as variacao_pct
    from base
    union all
--
-- compara a evolução do volume vendido
    select
        'Volume total',
        max(case when ano = 2023 then volume_total::text end),
        max(case when ano = 2024 then volume_total::text end),
        max(case when ano = 2024 then volume_total end) - max(case when ano = 2023 then volume_total end),
        round((max(case when ano = 2024 then volume_total end) - max(case when ano = 2023 then volume_total end))::numeric /
            nullif(max(case when ano = 2023 then volume_total end), 0), 4)
    from base
    union all
--
-- compara a evolução do lucro total
    select
        'Lucro total',
        max(case when ano = 2023 then lucro_total::text end),
        max(case when ano = 2024 then lucro_total::text end),
        max(case when ano = 2024 then lucro_total end) -
        max(case when ano = 2023 then lucro_total end),
        round( (max(case when ano = 2024 then lucro_total end) - max(case when ano = 2023 then lucro_total end))::numeric /
            nullif(max(case when ano = 2023 then lucro_total end), 0), 4)
    from base)
--
-- resultado final
select
    indicadores,
    q1_2023,
    q1_2024,
    variacao_absoluta,
    variacao_pct
from comparacao;
--
-- interpretação: se a queda percentual dos clientes activos for próxima da queda do volume, então a redução das vendas está fortemente associada à perda de clientes.
-- se o volume cair mais do que a base de clientes, isso indica que os clientes remanescentes também passaram a comprar menos.
-- -----------------------------------------------------------------------------------


-- 3.1.6.3- Como evoluiu o preço médio por categoria entre Q1 2023 e Q1 2024 no segmento do consumer?
-- objetivo: identificar se a redução do preço médio observada no segmento Consumer foi provocada por quedas de preço dentro das categorias ou por alterações
-- no mix de produtos vendidos.
-- visão analítica: esta análise isola o comportamento do preço dentro de cada categoria, permitindo separar o efeito preço do efeito mix.
--
-- calcula o preço médio unitário por categoria e período
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        round(sum(o.quantity * o.unit_price)::numeric / nullif(sum(o.quantity), 0), 2) as preco_medio
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2023, 2024)
        and extract(quarter from o.order_date) = 1
        and c.customer_segment = 'Consumer'
    group by 1, 2)
--
-- compara o preço médio de cada categoria entre Q1 2023 e Q1 2024 para identificar quais categorias contribuíram para a queda
-- ou aumento do preço médio do segmento Consumer
select
    b.categoria,
    max(case when ano = 2023 then preco_medio end) as preco_2023,
    max(case when ano = 2024 then preco_medio end) as preco_2024,
    round(max(case when ano = 2024 then preco_medio end) - max(case when ano = 2023 then preco_medio end), 2) as variacao_absoluta,
    round((max(case when ano = 2024 then preco_medio end) - max(case when ano = 2023 then preco_medio end)) /
        nullif(max(case when ano = 2023 then preco_medio end), 0), 4)  as variacao_pct
from base b
group by b.categoria
order by b.categoria;
--______________________________________________________________________________________________________________________________________________________

-- Pergunta 3.2- O que causou o pico do Corporate em Q3 2025?
-- Analisar os fatores que impulsionaram o crescimento do segmento Corporate no Q3 2025 em comparação ao Q3 2024.
-- Para compreender a origem do aumento do lucro, a análise será realizada sob três perspectivas complementares:
--

-- 3.2.1 — Perspectiva por Categoria
-- Objetivo: Identificar quais categorias de produtos mais contribuíram para o pico/crescimento do lucro do segmento Corporate no Q3 2025 versus Q3 2024.
-- Visão analítica: A análise por categoria permite compreender quais linhas de produtos impulsionaram o desempenho do segmento Corporate, 
-- evidenciando as categorias com maior impacto positivo sobre a rentabilidade.
--
-- agrega o lucro por categoria e trimestre filtrado apenas para o segmento Corporate
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q3 2025 vs Q3 2024 por categoria
comparacao as (
    select
        q3_2025.categoria,
        q3_2024.lucro  as lucro_q3_2024,
        q3_2025.lucro as lucro_q3_2025,
        q3_2025.lucro - q3_2024.lucro as variacao_absoluta,
        (q3_2025.lucro - q3_2024.lucro) / nullif(q3_2024.lucro, 0) as variacao_pct
    from base q3_2025
    inner join base q3_2024
        on q3_2024.categoria = q3_2025.categoria
        and q3_2024.ano = 2024
        and q3_2025.ano = 2025),
--
-- variacao do crescimento total do Corporate no Q3 2025
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta > 0)
--
select
    c.categoria,
    round(c.lucro_q3_2024, 2) as lucro_q3_2024,
    round(c.lucro_q3_2025, 2) as lucro_q3_2025,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct  -- contribuição de cada categoria para o pico do lucro do segmento Corporate
from comparacao c
cross join total t
where c.variacao_absoluta > 0
order by variacao_absoluta desc;
-------------------------------------------------------------------------------------


-- 3.2.2 — Perspectiva por País
-- Objetivo: Identificar quais países mais contribuíram para o crescimento do lucro do segmento Corporate no Q3 2025 versus Q3 2024.
-- Visão analítica: A análise por país permite localizar geograficamente os principais mercados responsáveis pela expansão do resultado, 
-- evidenciando os países com maior impacto positivo sobre o desempenho do segmento Corporate.
--
-- agrega o lucro por pais e trimestre filtrado apenas para o segmento Corporate
with base as (
    select
        c.country as pais,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q3 2025 vs Q3 2024 por pais
comparacao as (
    select
        q3_2025.pais,
        q3_2024.lucro  as lucro_q3_2024,
        q3_2025.lucro as lucro_q3_2025,
        q3_2025.lucro - q3_2024.lucro as variacao_absoluta,
        (q3_2025.lucro - q3_2024.lucro) / nullif(q3_2024.lucro, 0) as variacao_pct
    from base q3_2025
    inner join base q3_2024
        on q3_2024.pais = q3_2025.pais
        and q3_2024.ano = 2024
        and q3_2025.ano = 2025),
--
-- variacao do crescimento totaldo Corporate no Q3 2025
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta > 0)
--
select
    c.pais,
    round(c.lucro_q3_2024, 2) as lucro_q3_2024,
    round(c.lucro_q3_2025, 2) as lucro_q3_2025,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct  -- contribuicao de cada pais para o crescimento do lucro do segmento Corporate
from comparacao c
cross join total t
where c.variacao_absoluta > 0
order by variacao_absoluta desc;
-------------------------------------------------------------------------------------


-- 3.2.3 — Perspectiva por Continente
-- Objetivo: Identificar quais continentes mais contribuíram para o crescimento do lucro do segmento Corporate no Q3 2025 versus Q3 2024.
-- Visão analítica: A análise por continente permite avaliar o comportamento regional agregado do segmento Corporate, 
-- identificando as regiões que mais impulsionaram o crescimento do lucro no período analisado.
--
-- agrega o lucro por continente e trimestre filtrado apenas para o segmento Corporate
with base as (
    select
        l.region as continente,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
	inner join location l on l.country = c.country
	 where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q3 2025 vs Q3 2024 por continente
comparacao as (
    select
        q3_2025.continente,
        q3_2024.lucro  as lucro_q3_2024,
        q3_2025.lucro as lucro_q3_2025,
        q3_2025.lucro - q3_2024.lucro as variacao_absoluta,
        (q3_2025.lucro - q3_2024.lucro) / nullif(q3_2024.lucro, 0) as variacao_pct
    from base q3_2025
    inner join base q3_2024
        on q3_2024.continente = q3_2025.continente
        and q3_2024.ano = 2024
        and q3_2025.ano = 2025),
--
-- variacao do crescimento total do Corporate no Q3 2025
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta > 0)
--
select
    c.continente,
    round(c.lucro_q3_2024, 2) as lucro_q3_2024,
    round(c.lucro_q3_2025, 2) as lucro_q3_2025,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct  -- contribuição de cada categoria para o pico do lucro do segmento Corporate
from comparacao c
cross join total t
where c.variacao_absoluta > 0
order by variacao_absoluta desc;
-- ----------------------------------------------------------------------------------


-- 3.2.4 - Perspectiva: Combinação de País e categoria
-- OBJETIVO: identificar o epicentro exacto da pico/crescimento
--
with base as (
    select
        c.country as pais,
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    inner join products p on p.product_id = o.product_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'  -- filtro do segmento
    group by 1,2,3,4),
--
-- compara q3 2025 vs q3 2024
comparacao as (
    select
        q25.pais,
        q25.categoria,
        q24.lucro as lucro_q3_2024,
        q25.lucro as lucro_q3_2025,
        q25.lucro - q24.lucro as variacao_absoluta,
        (q25.lucro - q24.lucro) / nullif(q24.lucro,0) as variacao_pct
    from base q25
    inner join base q24
        on q24.pais = q25.pais
        and q24.categoria = q25.categoria
        and q24.ano = 2024
        and q25.ano = 2025),
--
-- variacao do crescimento total do Corporate no Q3 2025
total as (
    select
        sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta > 0),
--
-- cria o ranking das combinações com maior destruição de lucro    
ranking as (
    select
        c.pais,
        c.categoria,
        round(c.lucro_q3_2024,2) as lucro_q3_2024,
        round(c.lucro_q3_2025,2) as lucro_q3_2025,
        round(c.variacao_absoluta,2) as variacao_absoluta,
        round(c.variacao_pct,4) as variacao_pct,
        round(c.variacao_absoluta / nullif(t.variacao_total,0),4) as contribuicao_pct,
        row_number() over (order by c.variacao_absoluta desc ) as ranking
    from comparacao c
    cross join total t
    where c.variacao_absoluta > 0)
--
-- resultado final: top 10 combinações que mais contribuíram para a queda de lucro
select
    ranking,
    pais,
    categoria,
    lucro_q3_2024,
    lucro_q3_2025,
    variacao_absoluta,
    variacao_pct,
    contribuicao_pct
from ranking
where ranking <= 10
order by ranking;
-- -----------------------------------------------------------------------------------


-- Pergunta 3.2.5 - Foi volume, preco ou desconto o principal driver do pico de corporate no Q3 2025?
-- objetivo: identificar qual componente mais contribuiu para o pico
-- metodo: compara volume, preco medio e desconto entre Q3 2025 e Q3 2024
--
-- agrega os componentes de crescimento por ano e trimestre
with base as (
    select
        extract(year from o.order_date)    as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity)                    as volume,
        sum(o.quantity * o.unit_price)     as faturamento,
        sum(o.total_sales)                 as receita
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'  -- filtro do segmento
    group by 1, 2),
--
-- compara q3 2025 vs q3 2024
comparacao as (
    select
        q24.volume        as volume_2024,
        q25.volume        as volume_2025,
        q24.faturamento   as faturamento_2024,
        q25.faturamento   as faturamento_2025,
        q24.receita as receita_2024,
        q25.receita as receita_2025
    from base q25
    inner join base q24
        on q24.ano = 2024 
        and q25.ano = 2025),
--
-- calcula preco medio e desconto efetivo
drivers as (
    select
        volume_2024,
        volume_2025,
        receita_2024,
        receita_2025,
        faturamento_2024 / nullif(volume_2024, 0) as preco_2024,
        faturamento_2025 / nullif(volume_2025, 0)  as preco_2025,
        1 - (receita_2024 / nullif(faturamento_2024, 0)) as desconto_2024,
        1 - (receita_2025 / nullif(faturamento_2025, 0)) as desconto_2025
    from comparacao),
--
-- calcula o impacto isolado de cada driver
impactos as (
    select
        round((volume_2025 - volume_2024) * preco_2024 * (1 - desconto_2024), 2) as impacto_volume,
        round(volume_2025 * (preco_2025 - preco_2024) * (1 - desconto_2024), 2) as impacto_preco,
        round(volume_2025 * preco_2025 * (desconto_2024 - desconto_2025), 2)  as impacto_desconto,
        round(receita_2025 - receita_2024, 2) as variacao_total
    from drivers)
--
-- formata o resultado em linhas por driver
select
    driver,
    impacto,
    round(impacto / nullif(variacao_total, 0), 4) as peso_no_crescimento
from impactos,
lateral (values
    ('Volume', impacto_volume),
    ('Preco', impacto_preco),
    ('Desconto', impacto_desconto)
) as t(driver, impacto)
order by
    case driver
        when 'Volume'         then 1
        when 'Preco'          then 2
        when 'Desconto'       then 3
    end;
-- ------------------------------------------------------------------------------------


-- Pergunta 3.2.5.1 - Como evoluíram volume, preço médio e desconto médio do segmento Corporate?
-- objetivo: comparar os indicadores operacionais entre Q3 2024 e Q3 2025
-- metodo: calcular volume total, preço médio e desconto médio para cada período
--
-- agrega as métricas por ano e trimestre
with base as (
    select
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity) as volume,
        sum(o.quantity * o.unit_price) as faturamento,
        sum(o.total_sales) as receita
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'
    group by 1,2),
--
-- organiza os dois períodos para comparação
comparacao as (
    select
        q24.volume as volume_2024,
        q25.volume as volume_2025,
        q24.faturamento / nullif(q24.volume,0) as preco_medio_2024,
        q25.faturamento / nullif(q25.volume,0) as preco_medio_2025,
        1 - (q24.receita / nullif(q24.faturamento,0)) as desconto_medio_2024,
        1 - (q25.receita / nullif(q25.faturamento,0)) as desconto_medio_2025
    from base q24
    inner join base q25
        on q24.ano = 2024
        and q25.ano = 2025)
--
-- resultado final
-- utiliza union all para consolidar as três métricas numa única tabela, facilitando a comparação entre volume, preço médio e desconto médio
select
    'Volume' as metrica,
    volume_2024 as q3_2024,
    volume_2025 as q3_2025,
    volume_2025 - volume_2024 as variacao_absoluta,
	round((volume_2025 - volume_2024)::numeric / nullif(volume_2024, 0)::numeric, 4) as variacao_pct
from comparacao
union all
--
select
    'Preço Médio Unitário',
    round(preco_medio_2024,2),
    round(preco_medio_2025,2),
    round(preco_medio_2025 - preco_medio_2024,2),
    round((preco_medio_2025 - preco_medio_2024) / nullif(preco_medio_2024,0),4)
from comparacao
union all
--
select
    'Desconto Médio Efetivo',
    round(desconto_medio_2024 * 100,2),
    round(desconto_medio_2025 * 100,2),
    round((desconto_medio_2025 - desconto_medio_2024) * 100,2),
    round((desconto_medio_2025 - desconto_medio_2024) / nullif(desconto_medio_2024,0),4)
from comparacao;
-- ------------------------------------------------------------------------------------


-- 3.2.5.2 - Evolução da base de clientes activos do Corporate: Q3 2025 vs Q3 2024
-- objetivo: determinar se o pico/crescimento de volume está associada ao aumento de clientes activos
-- metodologia:
-- 1. contabilizar clientes activos (clientes com pelo menos uma compra no período)
-- 2. calcular volume total vendido e lucro total
-- 3. comparar Q3 2024 com Q3 2025
-- 4. medir a variação absoluta e percentual dos indicadores
--
-- agrega clientes activos, volume e lucro por ano
with base as (
    select
        extract(year from o.order_date) as ano,
        count(distinct o.customer_id) as clientes_activos,
        sum(o.quantity) as volume_total,
        round(sum(o.profit)::numeric, 2) as lucro_total
    from orders o
    inner join customers c on c.customer_id = o.customer_id 
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'
    group by 1),
--
-- organiza os indicadores para comparação entre os períodos
comparacao as (
    select
        'Clientes activos'  as indicadores,
        max(case when ano = 2024 then clientes_activos::text end) as q3_2024,
        max(case when ano = 2025 then clientes_activos::text end) as q3_2025,
        max(case when ano = 2025 then clientes_activos end) - max(case when ano = 2024 then clientes_activos end)   as variacao_absoluta,
        round((max(case when ano = 2025 then clientes_activos end) - max(case when ano = 2024 then clientes_activos end))::numeric /
            nullif(max(case when ano = 2024 then clientes_activos end), 0), 4) as variacao_pct
    from base
    union all
--
-- compara a evolução do volume vendido
    select
        'Volume total',
        max(case when ano = 2024 then volume_total::text end),
        max(case when ano = 2025 then volume_total::text end),
        max(case when ano = 2025 then volume_total end) - max(case when ano = 2024 then volume_total end),
        round((max(case when ano = 2025 then volume_total end) - max(case when ano = 2024 then volume_total end))::numeric /
            nullif(max(case when ano = 2024 then volume_total end), 0), 4)
    from base
    union all
--
-- compara a evolução do lucro total
    select
        'Lucro total',
        max(case when ano = 2024 then lucro_total::text end),
        max(case when ano = 2025 then lucro_total::text end),
        max(case when ano = 2025 then lucro_total end) - max(case when ano = 2024 then lucro_total end),
        round( (max(case when ano = 2025 then lucro_total end) - max(case when ano = 2024 then lucro_total end))::numeric /
            nullif(max(case when ano = 2024 then lucro_total end), 0), 4)
    from base)
--
-- resultado final
select
    indicadores,
    q3_2024,
    q3_2025,
    variacao_absoluta,
    variacao_pct
from comparacao;
--
-- interpretação:
-- se o crescimento percentual dos clientes activos for semelhante ao crescimento do volume, então a expansão das vendas está fortemente associada ao aumento da base de clientes.
--
-- se o volume crescer significativamente acima da base de clientes, isso indica que os clientes activos passaram a comprar mais unidades,
-- aumentando o volume médio por cliente.
--
-- neste cenário, a diferença entre o crescimento dos clientes e do volume ajuda a distinguir se o crescimento foi impulsionado por aquisição de clientes
-- ou por maior intensidade de compra dos clientes existentes.
-- -----------------------------------------------------------------------------------


-- 3.2.5.3- Como evoluiu o preço médio por categoria entre Q3 2024 e Q3 2025 no segmento do Corporate?
-- objetivo: identificar se a aumento do preço médio observada no segmento Corporate foi provocada por aumento de preço dentro das categorias ou por alterações
-- no mix de produtos vendidos.
-- visão analítica: esta análise isola o comportamento do preço dentro de cada categoria, permitindo separar o efeito preço do efeito mix.
--
-- calcula o preço médio unitário por categoria e período
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        round(sum(o.quantity * o.unit_price)::numeric / nullif(sum(o.quantity), 0), 2) as preco_medio
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 3
        and c.customer_segment = 'Corporate'
    group by 1, 2)
--
-- compara o preço médio de cada categoria entre Q3 2024 e Q3 2025 para identificar quais categorias contribuíram para o crescimento preço médio do segmento Corporate
select
    b.categoria,
    max(case when ano = 2024 then preco_medio end) as preco_2024,
    max(case when ano = 2025 then preco_medio end) as preco_2025,
    round(max(case when ano = 2025 then preco_medio end) - max(case when ano = 2024 then preco_medio end), 2) as variacao_absoluta,
    round((max(case when ano = 2025 then preco_medio end) - max(case when ano = 2024 then preco_medio end)) /
        nullif(max(case when ano = 2024 then preco_medio end), 0), 4)  as variacao_pct
from base b
group by b.categoria
order by b.categoria;
--________________________________________________________________________________________________________________________________________


-- Pergunta 3.3- O que causou o pico do Home Office em Q4 2025?
-- Analisar os fatores que impulsionaram o crescimento do segmento Home Office no Q4 2025 em comparação ao Q4 2024.
-- Para compreender a origem do aumento do lucro, a análise será realizada sob três perspectivas complementares


-- 3.3.1 — Perspectiva por Categoria
-- Objetivo: Identificar quais categorias de produtos mais contribuíram para o pico/crescimento do lucro do segmento Home Office no Q4 2025 versus Q4 2024.
-- Visão analítica: A análise por categoria permite compreender quais linhas de produtos impulsionaram o desempenho do segmento Home Office, 
-- evidenciando as categorias com maior impacto positivo sobre a rentabilidade.
--
-- agrega o lucro por categoria e trimestre filtrado apenas para o segmento Home Office
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q4 2025 vs Q4 2024 por categoria
comparacao as (
    select
        q4_2025.categoria,
        q4_2024.lucro  as lucro_q4_2024,
        q4_2025.lucro as lucro_q4_2025,
        q4_2025.lucro - q4_2024.lucro as variacao_absoluta,
        (q4_2025.lucro - q4_2024.lucro) / nullif(q4_2024.lucro, 0) as variacao_pct
    from base q4_2025
    inner join base q4_2024
        on q4_2024.categoria = q4_2025.categoria
        and q4_2024.ano = 2024
        and q4_2025.ano = 2025),
--
-- variacao do crescimento total do Home Office no Q4 2025
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta > 0)
--
select
    c.categoria,
    round(c.lucro_q4_2024, 2) as lucro_q4_2024,
    round(c.lucro_q4_2025, 2) as lucro_q4_2025,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct  -- contribuição de cada categoria para o pico do lucro do segmento Home Office
from comparacao c
cross join total t
where c.variacao_absoluta > 0
order by variacao_absoluta desc;
-------------------------------------------------------------------------------------


-- 3.3.2 — Perspectiva por País
-- Objetivo: Identificar quais países mais contribuíram para o crescimento do lucro do segmento Home Office no Q4 2025 versus Q4 2024.
-- Visão analítica: A análise por país permite localizar geograficamente os principais mercados responsáveis pela expansão do resultado, 
-- evidenciando os países com maior impacto positivo sobre o desempenho do segmento Home Office.
--
-- agrega o lucro por pais e trimestre filtrado apenas para o segmento Home Office
with base as (
    select
        c.country as pais,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
     where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q4 2025 vs Q4 2024 por pais
comparacao as (
    select
        q4_2025.pais,
        q4_2024.lucro  as lucro_q4_2024,
        q4_2025.lucro as lucro_q4_2025,
        q4_2025.lucro - q4_2024.lucro as variacao_absoluta,
        (q4_2025.lucro - q4_2024.lucro) / nullif(q4_2024.lucro, 0) as variacao_pct
    from base q4_2025
    inner join base q4_2024
        on q4_2024.pais = q4_2025.pais
        and q4_2024.ano = 2024
        and q4_2025.ano = 2025),
--
-- variacao do crescimento total do Home Office no Q4 2025
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta > 0)
--
select
    c.pais,
    round(c.lucro_q4_2024, 2) as lucro_q4_2024,
    round(c.lucro_q4_2025, 2) as lucro_q4_2025,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct  -- contribuicao de cada pais para o crescimento do lucro do segmento Home Office
from comparacao c
cross join total t
where c.variacao_absoluta > 0
order by variacao_absoluta desc;
-------------------------------------------------------------------------------------


-- 3.3.3 — Perspectiva por Continente
-- Objetivo: Identificar quais continentes mais contribuíram para o crescimento do lucro do segmento Home Office no Q4 2025 versus Q4 2024.
-- Visão analítica: A análise por continente permite avaliar o comportamento regional agregado do segmento Home Office, 
-- identificando as regiões que mais impulsionaram o crescimento do lucro no período analisado.
--
-- agrega o lucro por continente e trimestre filtrado apenas para o segmento Home Office
with base as (
    select
        l.region as continente,
        extract(year from o.order_date)  as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit)  as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
	inner join location l on l.country = c.country
	 where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'  -- filtro do segmento
    group by 1, 2, 3),
--
-- self-join compara Q4 2025 vs Q4 2024 por continente
comparacao as (
    select
        q4_2025.continente,
        q4_2024.lucro  as lucro_q4_2024,
        q4_2025.lucro as lucro_q4_2025,
        q4_2025.lucro - q4_2024.lucro as variacao_absoluta,
        (q4_2025.lucro - q4_2024.lucro) / nullif(q4_2024.lucro, 0) as variacao_pct
    from base q4_2025
    inner join base q4_2024
        on q4_2024.continente = q4_2025.continente
        and q4_2024.ano = 2024
        and q4_2025.ano = 2025),
--
-- variacao do crescimento total do Home Office no Q4 2025
total as (
    select sum(variacao_absoluta) as variacao_total
    from comparacao
	where variacao_absoluta > 0)
--
select
    c.continente,
    round(c.lucro_q4_2024, 2) as lucro_q4_2024,
    round(c.lucro_q4_2025, 2) as lucro_q4_2025,
    round(c.variacao_absoluta, 2) as variacao_absoluta,
    round(c.variacao_pct, 4) as variacao_pct,
    round(c.variacao_absoluta / nullif(t.variacao_total, 0),4) as contribuicao_pct  -- contribuição de cada continente para o crescimento do lucro do segmento Home Office
from comparacao c
cross join total t
where c.variacao_absoluta > 0
order by variacao_absoluta desc;
-- ----------------------------------------------------------------------------------


-- 3.3.4 - Perspectiva: Combinação de País e categoria
-- OBJETIVO: identificar o epicentro exacto do crescimento
with base as (
    select
        c.country as pais,
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.profit) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    inner join products p on p.product_id = o.product_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'  -- filtro do segmento
    group by 1,2,3,4),
--
-- compara q4 2025 vs q4 2024
comparacao as (
    select
        q25.pais,
        q25.categoria,
        q24.lucro as lucro_q4_2024,
        q25.lucro as lucro_q4_2025,
        q25.lucro - q24.lucro as variacao_absoluta,
        (q25.lucro - q24.lucro) / nullif(q24.lucro,0) as variacao_pct
    from base q25
    inner join base q24
        on q24.pais = q25.pais
        and q24.categoria = q25.categoria
        and q24.ano = 2024
        and q25.ano = 2025),
--
-- variacao total/positiva do crescimento do Home Office no Q4 de 2025
total as (
    select
        sum(variacao_absoluta) as variacao_total
    from comparacao
    where variacao_absoluta > 0),
--
-- cria o ranking das combinações com maior destruição de lucro    
ranking as (
    select
        c.pais,
        c.categoria,
        round(c.lucro_q4_2024,2) as lucro_q4_2024,
        round(c.lucro_q4_2025,2) as lucro_q4_2025,
        round(c.variacao_absoluta,2) as variacao_absoluta,
        round(c.variacao_pct,4) as variacao_pct,
        round(c.variacao_absoluta / nullif(t.variacao_total,0),4) as contribuicao_pct,
        row_number() over (order by c.variacao_absoluta desc ) as ranking
    from comparacao c
    cross join total t
    where c.variacao_absoluta > 0)
--
-- resultado final: top 10 combinações que mais contribuíram para a queda de lucro
select
    ranking,
    pais,
    categoria,
    lucro_q4_2024,
    lucro_q4_2025,
    variacao_absoluta,
    variacao_pct,
    contribuicao_pct
from ranking
where ranking <= 10
order by ranking;
-- -----------------------------------------------------------------------------------


-- Pergunta 3.3.5 - Foi volume, preco ou desconto o principal driver do pico de Home Office no Q4 2025?
-- objetivo: identificar qual componente mais contribuiu para o pico
-- metodo: compara volume, preco medio e desconto entre Q4 2025 e Q4 2024
--
-- agrega os componentes de crescimento por ano e trimestre
with base as (
    select
        extract(year from o.order_date)    as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity)                    as volume,
        sum(o.quantity * o.unit_price)     as faturamento,
        sum(o.total_sales)                 as receita
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'  -- filtro do segmento
    group by 1, 2),
--
-- compara q4 2025 vs q4 2024
comparacao as (
    select
        q24.volume        as volume_2024,
        q25.volume        as volume_2025,
        q24.faturamento   as faturamento_2024,
        q25.faturamento   as faturamento_2025,
        q24.receita as receita_2024,
        q25.receita as receita_2025
    from base q25
    inner join base q24
        on q24.ano = 2024 
        and q25.ano = 2025),
--
-- calcula preco medio e desconto efetivo
drivers as (
    select
        volume_2024,
        volume_2025,
        receita_2024,
        receita_2025,
        faturamento_2024 / nullif(volume_2024, 0) as preco_2024,
        faturamento_2025 / nullif(volume_2025, 0)  as preco_2025,
        1 - (receita_2024 / nullif(faturamento_2024, 0)) as desconto_2024,
        1 - (receita_2025 / nullif(faturamento_2025, 0)) as desconto_2025
    from comparacao),
--
-- calcula o impacto isolado de cada driver
impactos as (
    select
        round((volume_2025 - volume_2024) * preco_2024 * (1 - desconto_2024), 2) as impacto_volume,
        round(volume_2025 * (preco_2025 - preco_2024) * (1 - desconto_2024), 2) as impacto_preco,
        round(volume_2025 * preco_2025 * (desconto_2024 - desconto_2025), 2)  as impacto_desconto,
        round(receita_2025 - receita_2024, 2) as variacao_total
    from drivers)
--
-- formata o resultado em linhas por driver
select
    driver,
    impacto,
    round(impacto / nullif(variacao_total, 0), 4) as peso_no_crescimento
from impactos,
lateral (values
    ('Volume', impacto_volume),
    ('Preco', impacto_preco),
    ('Desconto', impacto_desconto)
) as t(driver, impacto)
order by
    case driver
        when 'Volume'         then 1
        when 'Preco'          then 2
        when 'Desconto'       then 3
    end;
-- -------------------------------------------------------------------------------------

-- Pergunta 3.3.5.2 - Como evoluíram volume, preço médio e desconto médio do segmento Home Office?
-- objetivo: comparar os indicadores operacionais entre Q4 2024 e Q4 2025
-- metodo: calcular volume total, preço médio e desconto médio para cada período
--
-- agrega as métricas por ano e trimestre
with base as (
    select
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        sum(o.quantity) as volume,
        sum(o.quantity * o.unit_price) as faturamento,
        sum(o.total_sales) as receita
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'
    group by 1,2),
--
-- organiza os dois períodos para comparação
comparacao as (
    select
        q24.volume as volume_2024,
        q25.volume as volume_2025,
        q24.faturamento / nullif(q24.volume,0) as preco_medio_2024,
        q25.faturamento / nullif(q25.volume,0) as preco_medio_2025,
        1 - (q24.receita / nullif(q24.faturamento,0)) as desconto_medio_2024,
        1 - (q25.receita / nullif(q25.faturamento,0)) as desconto_medio_2025
    from base q24
    inner join base q25
        on q24.ano = 2024
        and q25.ano = 2025)
--
-- resultado final
select
    'Volume' as metrica,
    volume_2024 as q4_2024,
    volume_2025 as q4_2025,
    volume_2025 - volume_2024 as variacao_absoluta,
	round((volume_2025 - volume_2024)::numeric / nullif(volume_2024, 0)::numeric, 4) as variacao_pct
from comparacao
union all
select
    'Preço Médio Unitário',
    round(preco_medio_2024,2),
    round(preco_medio_2025,2),
    round(preco_medio_2025 - preco_medio_2024,2),
    round((preco_medio_2025 - preco_medio_2024) / nullif(preco_medio_2024,0),4)
from comparacao
union all
select
    'Desconto Médio Efetivo',
    round(desconto_medio_2024 * 100,2),
    round(desconto_medio_2025 * 100,2),
    round((desconto_medio_2025 - desconto_medio_2024) * 100,2),
    round((desconto_medio_2025 - desconto_medio_2024) / nullif(desconto_medio_2024,0),4)
from comparacao;
-- --------------------------------------------------------------------------------------

-- 3.3.5.3 - Evolução da base de clientes activos do Home Office: Q4 2024 vs Q4 2025
-- objetivo: determinar se o pico/crescimento de volume está associada ao aumento de clientes activos
-- metodologia:
-- 1. contabilizar clientes activos (clientes com pelo menos uma compra no período)
-- 2. calcular volume total vendido e lucro total
-- 3. comparar Q4 2024 com Q4 2025
-- 4. medir a variação absoluta e percentual dos indicadores
--
-- agrega clientes activos, volume e lucro por ano
with base as (
    select
        extract(year from o.order_date) as ano,
        count(distinct o.customer_id) as clientes_activos,
        sum(o.quantity) as volume_total,
        round(sum(o.profit)::numeric, 2) as lucro_total
    from orders o
    inner join customers c on c.customer_id = o.customer_id 
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'
    group by 1),
--
-- organiza os indicadores para comparação entre os períodos
comparacao as (
    select
        'Clientes activos'  as indicadores,
        max(case when ano = 2024 then clientes_activos::text end) as q4_2024,
        max(case when ano = 2025 then clientes_activos::text end) as q4_2025,
        max(case when ano = 2025 then clientes_activos end) - max(case when ano = 2024 then clientes_activos end)   as variacao_absoluta,
        round((max(case when ano = 2025 then clientes_activos end) - max(case when ano = 2024 then clientes_activos end))::numeric /
            nullif(max(case when ano = 2024 then clientes_activos end), 0), 4) as variacao_pct
    from base
    union all
--
-- compara a evolução do volume vendido
    select
        'Volume total',
        max(case when ano = 2024 then volume_total::text end),
        max(case when ano = 2025 then volume_total::text end),
        max(case when ano = 2025 then volume_total end) - max(case when ano = 2024 then volume_total end),
        round((max(case when ano = 2025 then volume_total end) - max(case when ano = 2024 then volume_total end))::numeric /
            nullif(max(case when ano = 2024 then volume_total end), 0), 4)
    from base
    union all
--
-- compara a evolução do lucro total
    select
        'Lucro total',
        max(case when ano = 2024 then lucro_total::text end),
        max(case when ano = 2025 then lucro_total::text end),
        max(case when ano = 2025 then lucro_total end) - max(case when ano = 2024 then lucro_total end),
        round( (max(case when ano = 2025 then lucro_total end) - max(case when ano = 2024 then lucro_total end))::numeric /
            nullif(max(case when ano = 2024 then lucro_total end), 0), 4)
    from base)
--
-- resultado final
select
    indicadores,
    q4_2024,
    q4_2025,
    variacao_absoluta,
    variacao_pct
from comparacao;
--
-- interpretação:
-- se o crescimento percentual dos clientes activos for semelhante ao crescimento do volume, então a expansão das vendas está fortemente associada ao aumento da base de clientes.
--
-- se o volume crescer significativamente acima da base de clientes, isso indica que os clientes activos passaram a comprar mais unidades,
-- aumentando o volume médio por cliente.
--
-- neste cenário, a diferença entre o crescimento dos clientes e do volume ajuda a distinguir se o crescimento foi impulsionado por aquisição de clientes
-- ou por maior intensidade de compra dos clientes existentes.
-- -----------------------------------------------------------------------------------

-- 3.3.5.4- Como evoluiu o preço médio por categoria entre Q4 2024 e Q4 2025 no segmento do Home Office?
-- objetivo: identificar se a aumento do preço médio observada no segmento Home Office foi provocada por aumento de preço dentro das categorias ou por alterações
-- no mix de produtos vendidos.
-- visão analítica: esta análise isola o comportamento do preço dentro de cada categoria, permitindo separar o efeito preço do efeito mix.
--
-- calcula o preço médio unitário por categoria e período
with base as (
    select
        p.product_category as categoria,
        extract(year from o.order_date) as ano,
        round(sum(o.quantity * o.unit_price)::numeric / nullif(sum(o.quantity), 0), 2) as preco_medio
    from orders o
    inner join products p on p.product_id = o.product_id
    inner join customers c on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and extract(quarter from o.order_date) = 4
        and c.customer_segment = 'Home Office'
    group by 1, 2)
--
-- compara o preço médio de cada categoria entre Q4 2024 e Q4 2025 para identificar quais categorias contribuíram para o crescimento preço médio do segmento Home Office
select
    b.categoria,
    max(case when ano = 2024 then preco_medio end) as preco_2024,
    max(case when ano = 2025 then preco_medio end) as preco_2025,
    round(max(case when ano = 2025 then preco_medio end) - max(case when ano = 2024 then preco_medio end), 2) as variacao_absoluta,
    round((max(case when ano = 2025 then preco_medio end) - max(case when ano = 2024 then preco_medio end)) /
        nullif(max(case when ano = 2024 then preco_medio end), 0), 4)  as variacao_pct
from base b
group by b.categoria
order by b.categoria;
--________________________________________________________________________________________________________________________________________
--________________________________________________________________________________________________________________________________________


-- 4ª Decomposição Regional

-- Pergunta 4.1 - Quais paises crescem e quais retraem?
-- objetivo: calcular o yoy do lucro por regiao e classificar a trajetoria
-- metodo: yoy trimestral por país + classificacao
--
with base as (
    select
        c.country as pais,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        round(sum(o.profit), 2) as lucro
    from orders o
    inner join customers c on c.customer_id = o.customer_id
    group by 1, 2, 3),
--
-- calcula a comparação YoY do lucro por país partition by pais e trimestre garante comparação entre o mesmo trimestre de anos diferentes
yoy as (
    select
        pais,
        ano,
        trimestre,
        lucro,
        lag(lucro) over ( partition by pais, trimestre order by ano )  as lucro_anterior
    from base),
--
yoy_calculado as (
    select
        pais,
        ano,
        trimestre,
        lucro,
        lucro_anterior,
        round((lucro - lucro_anterior)::numeric / nullif(lucro_anterior::numeric,0), 4) as yoy_pct
    from yoy
    where lucro_anterior is not null),
--
-- consolida os indicadores que serão utilizados para classificar a trajetória de cada país
resumo as (
    select
        pais,
        round(avg(lucro - lucro_anterior), 2)   as media_variacao_absoluta,
        round(stddev(lucro - lucro_anterior), 2) as desvio_padrao,
        count(case when lucro > lucro_anterior then 1 end) as trimestres_positivos,
        count(case when lucro < lucro_anterior then 1 end) as trimestres_negativos,
        count(*) as total_trimestres
    from yoy
    where lucro_anterior is not null
    group by 1)
--
select
    pais,
    media_variacao_absoluta,
    desvio_padrao,
    trimestres_positivos,
    trimestres_negativos,
    total_trimestres,
--
-- classifica a trajetória histórica de cada país com base no balanço entre trimestres positivos e negativos
case
    when trimestres_positivos > trimestres_negativos and media_variacao_absoluta > 0 then 'crescimento'
    when trimestres_positivos = trimestres_negativos and media_variacao_absoluta >= 0 then 'neutro positivo'
    when trimestres_positivos = trimestres_negativos and media_variacao_absoluta < 0 then 'neutro negativo'
    else 'retracao'
end as trajetoria
from resumo
order by media_variacao_absoluta desc;
-- -------------------------------------------------------------------------------------


-- 4.2 - Qual foi o principal driver do crescimento dos países em expansão?
-- objetivo: identificar se o crescimento foi impulsionado principalmente por volume, preço ou desconto
-- metodologia:
-- 1. identificar os países classificados como crescimento
-- 2. calcular volume, preço médio e desconto médio por ano
-- 3. decompor a variação da receita em efeitos volume, preço e desconto
-- 4. identificar o driver dominante e a sua participação relativa no total dos impactos
--
with base_trajetoria as (
    select
        c.country as pais,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        round(sum(o.profit), 2) as lucro
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    group by 1, 2, 3),
--
yoy as (
    select
        pais,
        ano,
        trimestre,
        lucro,
        lag(lucro) over (partition by pais, trimestre order by ano) as lucro_anterior
    from base_trajetoria),
--
resumo as (
    select
        pais,
        round(avg(lucro - lucro_anterior), 2) as media_variacao_absoluta,
        count(case when lucro > lucro_anterior then 1 end) as trimestres_positivos,
        count(case when lucro < lucro_anterior then 1 end) as trimestres_negativos
    from yoy
    where lucro_anterior is not null
    group by 1),
--
-- selecciona apenas os países com trajetória de crescimento identificados na análise anterior
paises_crescimento as (
    select pais
    from resumo
    where trimestres_positivos > trimestres_negativos
        and media_variacao_absoluta > 0),
--
-- agrega as métricas necessárias para a decomposição da receita por país e ano
base_drivers as (
    select
        c.country as pais,
        extract(year from o.order_date) as ano,
        sum(o.quantity) as volume,
        sum(o.quantity * o.unit_price) as faturamento,
        sum(o.total_sales) as receita
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
        and c.country in (
            select pais
            from paises_crescimento)
    group by 1, 2),
--
-- organiza os indicadores de 2024 e 2025 para comparação directa entre os períodos
comparacao as (
    select
        q24.pais,
        q24.volume as volume_2024,
        q25.volume as volume_2025,
        q24.receita as receita_2024,
        q25.receita as receita_2025,
        q24.faturamento / nullif(q24.volume, 0) as preco_2024,
        q25.faturamento / nullif(q25.volume, 0) as preco_2025,
        1 - q24.receita / nullif(q24.faturamento, 0) as desconto_2024,
        1 - q25.receita / nullif(q25.faturamento, 0) as desconto_2025
    from base_drivers q24
    inner join base_drivers q25
        on q24.pais = q25.pais
        and q24.ano = 2024
        and q25.ano = 2025),
--
-- decompõe a variação da receita nos efeitos: volume, preço médio e desconto
impactos as (
    select
        pais,
        round((volume_2025 - volume_2024) * preco_2024 * (1 - desconto_2024),2) as impacto_volume,
        round(volume_2025 * (preco_2025 - preco_2024) * (1 - desconto_2024),2) as impacto_preco,
        round(volume_2025 * preco_2025 * (desconto_2024 - desconto_2025),2) as impacto_desconto,
        round(receita_2025 - receita_2024, 2) as variacao_total
    from comparacao),
--
-- identifica o principal driver da variação da receita e calcula a sua contribuição relativa
drivers as (
    select
        pais,
        impacto_volume,
        impacto_preco,
        impacto_desconto,
        variacao_total,
        --
        greatest(
            abs(impacto_volume),
            abs(impacto_preco),
            abs(impacto_desconto)
        ) as maior_impacto,
--
        abs(impacto_volume)
        + abs(impacto_preco)
        + abs(impacto_desconto) as impacto_total
    from impactos)
--
-- resultado final
select
    pais,
    case
        when maior_impacto = abs(impacto_volume) then 'Volume'
        when maior_impacto = abs(impacto_preco) then 'Preço'
        else 'Desconto'
    end as driver_principal,
    round(maior_impacto / nullif(impacto_total, 0), 4) as contribuicao_pct
from drivers
order by contribuicao_pct desc;
-- -----------------------------------------------------------------------------------------------------


-- 4.3 - Qual foi o principal driver de deterioração dos países em retração?
-- objetivo: identificar qual factor mais contribuiu para a deterioração do desempenho dos países em retração
-- metodologia:
-- 1. identificar os países classificados como retração
-- 2. calcular volume, preço médio e desconto médio por ano
-- 3. decompor a variação da receita em efeitos volume, preço e desconto
-- 4. identificar o driver dominante e a sua participação relativa no total dos impactos
--
with base_trajetoria as (
    select
        c.country as pais,
        extract(year from o.order_date) as ano,
        extract(quarter from o.order_date) as trimestre,
        round(sum(o.profit), 2) as lucro
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    group by 1, 2, 3),
--
yoy as (
    select
        pais,
        ano,
        trimestre,
        lucro,
        lag(lucro) over (partition by pais, trimestre order by ano) as lucro_anterior
    from base_trajetoria),
--
resumo as (
    select
        pais,
        round(avg(lucro - lucro_anterior), 2) as media_variacao_absoluta,
        count(case when lucro > lucro_anterior then 1 end) as trimestres_positivos,
        count(case when lucro < lucro_anterior then 1 end) as trimestres_negativos
    from yoy
    where lucro_anterior is not null
    group by 1),
--
-- selecciona apenas os países com trajetória de retração identificados na análise anterior (5.1)
paises_retracao as (
    select pais
    from resumo
    where trimestres_positivos < trimestres_negativos),
--
-- agrega as métricas necessárias para a decomposição da receita por país e ano
base_drivers as (
    select
        c.country as pais,
        extract(year from o.order_date) as ano,
        sum(o.quantity) as volume,
        sum(o.quantity * o.unit_price) as faturamento,
        sum(o.total_sales) as receita
    from orders o
    inner join customers c
        on c.customer_id = o.customer_id
    where extract(year from o.order_date) in (2024, 2025)
    and c.country in (
        select pais
        from paises_retracao)
    group by 1, 2),
--
-- organiza os indicadores de 2024 e 2025 para comparação directa entre os períodos
comparacao as (
    select
        q24.pais,
        q24.volume as volume_2024,
        q25.volume as volume_2025,
        q24.receita as receita_2024,
        q25.receita as receita_2025,
        q24.faturamento / nullif(q24.volume, 0) as preco_2024,
        q25.faturamento / nullif(q25.volume, 0) as preco_2025,
        1 - q24.receita / nullif(q24.faturamento, 0) as desconto_2024,
        1 - q25.receita / nullif(q25.faturamento, 0) as desconto_2025
    from base_drivers q24
    inner join base_drivers q25
        on q24.pais = q25.pais
        and q24.ano = 2024
        and q25.ano = 2025),
--
-- decompõe a variação da receita nos efeitos: volume, preço médio e desconto
impactos as (
    select
        pais,
        round((volume_2025 - volume_2024) * preco_2024 * (1 - desconto_2024),2) as impacto_volume,
        round(volume_2025 * (preco_2025 - preco_2024) * (1 - desconto_2024),2) as impacto_preco,
        round(volume_2025 * preco_2025 * (desconto_2024 - desconto_2025),2) as impacto_desconto,
        round(receita_2025 - receita_2024, 2) as variacao_total
    from comparacao),
--
-- identifica o principal driver da variação da receita e calcula a sua contribuição relativa
drivers as (
    select
        pais,
        impacto_volume,
        impacto_preco,
        impacto_desconto,
        variacao_total,
        --
        greatest(
            abs(impacto_volume),
            abs(impacto_preco),
            abs(impacto_desconto)
        ) as maior_impacto,
--
        abs(impacto_volume)
        + abs(impacto_preco)
        + abs(impacto_desconto) as impacto_total
    from impactos)
--
-- resultado final
select
    pais,
    case
        when maior_impacto = abs(impacto_volume) then 'Volume'
        when maior_impacto = abs(impacto_preco) then 'Preço'
        else 'Desconto'
    end as driver_principal,
    round(maior_impacto / nullif(impacto_total, 0), 4) as contribuicao_pct
from drivers
order by contribuicao_pct desc;
