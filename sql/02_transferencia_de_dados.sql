-- PROJECTO:   Global E-Commerce Sales & Customer Data
-- FICHEIRO:   02_transferencia_de_dados
-- OBJECTIVO:  Transferir os dados da tabela original
--             global_central para as 4 tabelas normalizadas
-- AUTOR:      Etelvino Ngola Joaquim
-- DATA:       2026-05-16
-- ________________________________________________________________________________________________________________
--
-- PRÉ-REQUISITOS:
--   - 01_criacao_das_tabelas.sql já executado com sucesso
--   - Tabela global_central existente com os dados originais
--   - Todas as tabelas no schema global_sales_customer
--
-- CONCEITO — ENTIDADE vs EVENTO:
--   TABELAS ENTIDADE → registos únicos, usamos DISTINCT
--   → location, products, customers
--   TABELAS EVENTO   → um registo por transacção, sem DISTINCT
--   → orders
--

--
-- ORDEM DE EXECUÇÃO (obrigatória por causa das FKs):
--   1. location     → sem dependências
--   2. products     → sem dependências
--   3. customers    → depende de location
--   4. orders       → depende de customers e products
--
-- EM CASO DE ERRO DE DUPLICADO:
--   Limpar todas as tabelas e recomeçar do passo 1:
--   TRUNCATE TABLE location, products CASCADE;
-- ________________________________________________________________________________________________


-- ------------------------------------------------------------
-- PASSO 1 DE 4 — Popular location  [TABELA ENTIDADE]
--
-- Extrai os países e regiões únicos da tabela original.
-- DISTINCT garante que cada país aparece apenas uma vez —
-- validado na análise prévia, cada país pertence a uma
-- única região sem inconsistências.
-- ON CONFLICT DO NOTHING evita erro se executado novamente.
-- ------------------------------------------------------------
INSERT INTO location (country, region)
SELECT DISTINCT
    country,
    region
FROM global_central
ON CONFLICT (country) DO NOTHING;


-- ------------------------------------------------------------
-- PASSO 2 DE 4 — Popular products  [TABELA ENTIDADE]
--
-- Extrai os produtos únicos da tabela original.
-- DISTINCT garante que cada produto aparece apenas uma vez —
-- validado na análise prévia, cada product_name pertence
-- a uma única product_category sem inconsistências.
-- ON CONFLICT DO NOTHING evita erro se executado novamente.
-- ------------------------------------------------------------
INSERT INTO products (product_name, product_category)
SELECT DISTINCT
    product_name,
    product_category
FROM global_central
ON CONFLICT (product_name) DO NOTHING;


-- ------------------------------------------------------------
-- PASSO 3 DE 4 — Popular customers  [TABELA ENTIDADE]
--
-- Extrai os clientes únicos identificados pela combinação
-- customer_name + country + customer_segment.
-- DENSE_RANK() gera um ID único por combinação — garante que
-- o mesmo cliente que faz dois pedidos recebe sempre o mesmo ID.
-- Clientes com o mesmo nome em países ou segmentos diferentes
-- são tratados como pessoas distintas.
-- ON CONFLICT DO NOTHING evita erro se executado novamente.
-- ------------------------------------------------------------
INSERT INTO customers (customer_id, customer_name, customer_segment, country)
SELECT DISTINCT
    DENSE_RANK() OVER (
        ORDER BY customer_name, country, customer_segment
    )                   AS customer_id,
    customer_name       AS customer_name,
    customer_segment    AS customer_segment,
    country             AS country
FROM global_central
ON CONFLICT (customer_id) DO NOTHING;

-- ------------------------------------------------------------
-- PASSO 4 DE 4 — Popular orders  [TABELA EVENTO]
--
-- Cada linha representa uma transacção única — um evento
-- que aconteceu num momento específico.
-- Não usamos DISTINCT — cada pedido é um acontecimento
-- diferente que precisa de ser registado individualmente.
-- product_cost é uma coluna calculada (GENERATED ALWAYS AS)
-- e não precisa de ser inserida — o PostgreSQL calcula
-- automaticamente a partir de total_sales, shipping_cost e profit.
-- O customer_id é recuperado com um subquery que usa a mesma
-- lógica do DENSE_RANK() aplicada no passo 3.
-- ------------------------------------------------------------
INSERT INTO orders (
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    discount_percent,
    total_sales,
    shipping_cost,
    profit,
    payment_method
)
SELECT
    g.order_id,
    c.customer_id,
    p.product_id,
    g.order_date::DATE,
    g.quantity,
    g.unit_price,
    g.discount_percent,
    g.total_sales,
    g.shipping_cost,
    g.profit,
    g.payment_method
FROM global_central g
-- Recuperar o customer_id gerado no passo 3
JOIN customers c ON c.customer_name    = g.customer_name
                AND c.country          = g.country
                AND c.customer_segment = g.customer_segment
-- Recuperar o product_id gerado no passo 2
JOIN products  p ON p.product_name     = g.product_name;
