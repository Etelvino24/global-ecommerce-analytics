-- ============================================================
-- PROJECTO:   Global E-Commerce Sales & Customer Data
-- FICHEIRO:   01 Criação das tabelas
-- OBJECTIVO:  Normalizar a tabela flat global em 4 tabelas
--             relacionais.
-- AUTOR:      Etelvino Ngola Joaquim
-- DATA:       2026-05-16

-- ============================================================
--
-- CONTEXTO:
--   O dataset original é composto por uma única tabela flat
--   com 15 colunas misturando atributos de entidades distintas
--   (clientes, produtos, regiões e pedidos).
--   Essa estrutura causa redundância e dificulta análises
--   segmentadas por entidade.
--
-- VALIDAÇÃO PRÉVIA DO DATASET:
--   Antes de normalizar, foram validados os seguintes pontos:
--   ✅ order_id         → único por pedido (2.000 registos)
--   ✅ product_name     → 40 produtos consistentes por categoria
--   ✅ region/country   → 20 países em 5 regiões sem inconsistências
--   ⚠️ customer_name   → sem ID único no dataset original
--   ⚠️ customer_segment → inconsistente por nome (ignorado como atributo fixo)
--   ⚠️ total_sales     → fórmula documentada não corresponde ao valor real,
--                         usar o valor directamente sem recalcular
--
-- DESCOBERTA — product_cost:
--   A documentação oficial do dataset descreve o campo profit como:
--   "Net profit after product cost and shipping."
--   Isso revela que existe um custo de produto (product_cost) que
--   não está exposto como coluna na tabela original — estava oculto.
--   Para tornar este valor visível e utilizável nas análises,
--   foi necessário isolar o product_cost através da fórmula inversa:
--
--     profit = total_sales - product_cost - shipping_cost
--     logo:
--     product_cost = total_sales - shipping_cost - profit
--
--   A validação confirmou que os valores são positivos e coerentes
--   em todos os 2.000 pedidos — por isso foi adicionado como coluna
--   calculada (GENERATED ALWAYS AS ... STORED) na tabela orders,
--   tornando o custo do produto sempre disponível para análise
--   sem necessidade de repetir o cálculo em cada query.
--
-- DECISÃO DE MODELAÇÃO — customer_id:
--   O dataset original não possui identificador único de cliente.
--   Para distinguir clientes com o mesmo nome em países diferentes,
--   o customer_id é gerado artificialmente no script de transferência de dados
--   com DENSE_RANK() sobre a combinação customer_name + country +
--   customer_segment. Assim, o mesmo cliente que faz dois pedidos
--   recebe sempre o mesmo ID.
--
-- CONCEITO — ENTIDADE vs EVENTO:
--   TABELAS ENTIDADE → "quem" ou "o quê" (registos únicos)
--   → regions, products, customers
--   TABELAS EVENTO   → "o que aconteceu" (um registo por transacção)
--   → orders
--
-- ORDEM DE EXECUÇÃO (obrigatória por causa das FKs):
--   1. location      → sem dependências
--   2. products     → sem dependências
--   3. customers    → depende de regions
--   4. orders       → depende de customers e products
--
-- ============================================================


-- ------------------------------------------------------------
-- PASSO 1 DE 4 — Localização  [TABELA ENTIDADE]
--
-- Armazena a hierarquia geográfica do dataset.
-- Cada país pertence a uma única região — relação consistente
-- e validada na análise prévia de qualidade dos dados.
-- 20 países distribuídos por 5 regiões.
-- ------------------------------------------------------------
CREATE TABLE location (
    country        VARCHAR(100)    PRIMARY KEY,
    region         VARCHAR(100)    NOT null  
);


-- ------------------------------------------------------------
-- PASSO 2 DE 4 — PRODUCTS  [TABELA ENTIDADE]
--
-- Armazena o catálogo de produtos.
-- 40 produtos únicos distribuídos por 4 categorias.
-- Validado na análise prévia — cada product_name pertence
-- a uma única product_category, sem inconsistências.
-- product_id gerado artificialmente pois não existe no dataset.
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id       INT GENERATED ALWAYS AS IDENTITY   PRIMARY KEY,
    product_name     VARCHAR(200)    NOT NULL UNIQUE,
    product_category VARCHAR(100)    NOT NULL
);


-- ------------------------------------------------------------
-- PASSO 3 DE 4 — CUSTOMERS  [TABELA ENTIDADE]
--
-- Armazena os clientes únicos identificados pela combinação
-- customer_name + country + customer_segment.
-- customer_id gerado artificialmente com DENSE_RANK() no
-- script de população — garante que o mesmo cliente que faz
-- dois pedidos recebe sempre o mesmo ID.
-- Nota: customer_segment foi validado como inconsistente por
-- nome isolado, por isso faz parte da chave de identificação.
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id        INT             PRIMARY KEY,
    customer_name      VARCHAR(150)    NOT NULL,
    customer_segment   VARCHAR(50)     NOT null,
    country            VARCHAR(100)    NOT NULL REFERENCES location(country) 
);


-- ------------------------------------------------------------
-- PASSO 4 DE 4 — ORDERS  [TABELA EVENTO]
--
-- Tabela central — regista cada transacção única.
-- Cada linha representa um pedido com o seu valor financeiro,
-- método de pagamento e referências ao cliente e produto.
--
-- COLUNAS FINANCEIRAS:
--   total_sales    → receita do pedido (usado directamente —
--                    a fórmula documentada não corresponde ao valor real)
--   shipping_cost  → custo de envio
--   profit         → lucro líquido após product_cost e shipping_cost
--   product_cost   → custo do produto — estava oculto no dataset.
--                    A documentação oficial indica que profit =
--                    total_sales - product_cost - shipping_cost.
--                    Isolámos e adicionámos como coluna calculada
--                    para tornar este valor disponível nas análises:
--                    product_cost = total_sales - shipping_cost - profit
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id           VARCHAR(20)     PRIMARY KEY,
    customer_id        INT             NOT NULL REFERENCES customers(customer_id),
    product_id         INT             NOT NULL REFERENCES products(product_id),
    order_date         DATE            NOT NULL,
    quantity           INT             NOT NULL CHECK (quantity BETWEEN 1 AND 15),
    unit_price         DECIMAL(10,2)   NOT NULL,
    discount_percent   DECIMAL(5,2)    DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 30),
    total_sales        DECIMAL(10,2)   NOT NULL,
    shipping_cost      DECIMAL(10,2)   NOT NULL,
    profit             DECIMAL(10,2)   NOT NULL,
-- Custo do produto calculado a partir da fórmula inversa do profit.
-- Estava oculto no dataset original — ver explicação no cabeçalho.
    product_cost    DECIMAL(10,2)   GENERATED ALWAYS AS (total_sales - shipping_cost - profit) STORED,                    
    payment_method     VARCHAR(50)     NOT null    
);


-- ============================================================
-- RESUMO FINAL
-- ============================================================
--
--  Tabela      | Tipo     | PK                    | FKs
--  ------------|----------|-----------------------|------------------
--  location    | entidade | country (VARCHAR)     | —
--  products    | entidade | product_id (IDENTITY) | —
--  customers   | entidade | customer_id (INT)     | location
--  orders      | evento   | order_id (VARCHAR)    | customers, products
--

--
--  Próximo passo: 02 transferencia_de_dados