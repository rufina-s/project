/*
    Темнолесье — версия запросов для Microsoft SQL Server (2012+).

    Предположения:
    1. Таблицы находятся в схеме fantasy.
    2. Поле events.[date] хранится в формате YYYY-MM-DD.
       TRY_CONVERT(..., 23) преобразует его в date; некорректные строки дадут NULL.
    3. Имена столбцов [date] и [time] заключены в квадратные скобки.

    Основные изменения относительно PostgreSQL:
    - LIMIT заменён на TOP;
    - USING заменён на JOIN ... ON;
    - DATE_TRUNC заменён на DATEFROMPARTS + YEAR + MONTH;
    - приведение ::numeric удалено, AVG приведён к decimal;
    - STDDEV заменён на STDEV;
    - PERCENTILE_CONT / PERCENTILE_DISC используют OVER().
*/

SELECT schema_name   -- выгружаем все названия схем
FROM information_schema.schemata

SELECT table_name  -- выгружаем все названия таблиц схемы fantasy
FROM information_schema.tables
WHERE table_schema = 'fantasy'

SELECT c.table_schema, c.table_name, c.column_name, c.data_type, k.constraint_name -- смотрим на данные в таблице users
FROM information_schema.columns AS c 
LEFT JOIN information_schema.key_column_usage AS k ON c.table_schema = k.table_schema
AND c.table_name = k.table_name
AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'users' 
ORDER BY c.table_name

SELECT COUNT (*) AS row_counts -- общ кол-во строк -- проверка пропусков 
FROM fantasy.users
WHERE class_id IS NULL
    OR ch_id IS NULL
    OR pers_gender IS NULL
    OR server IS NULL
    OR race_id IS NULL
    OR payer IS NULL
    OR loc_id IS NULL

    SELECT   -- знакомство с категориальными данными таблицы users
    server, 
    COUNT(*)
FROM fantasy.users
GROUP BY SERVER

-- Выводим названия полей, их тип данных и метку о ключевом поле таблицы events

SELECT c.table_schema,
       c.table_name,
       c.column_name,
       c.data_type,
       k.constraint_name
FROM information_schema.columns AS c 
LEFT JOIN information_schema.key_column_usage AS k 
    ON c.table_schema = k.table_schema
   AND c.table_name = k.table_name
   AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'events'
ORDER BY c.table_name

--  таблице date и tame хранятся данные character varying, что не корректно 
SELECT TOP (5) *,
       (SELECT COUNT(*) FROM fantasy.events) AS row_count
FROM fantasy.events

--  игроки совершили более миллиноа внутриигровых покупок - 1 307 678. Также можно заметить, что id продавца и покупателся отличается 

-- видимо для продажи эпических предметов игрок должен зарегисроироваться как продавец 

--проверка пропусков в таблице events

SELECT COUNT(*)
FROM fantasy.events
WHERE [date] IS NULL
  OR [time] IS NULL
  OR amount IS NULL
  OR seller_id IS NULL 

-- в 508 186 строках из 1307678 содержатся пропуски хотя бы в одной из полей 

  -- детально изучим строки с пропусками в каждом из полей 

  -- это поможет узнать количество пропущенных значений в каждом столбце

  SELECT 
COUNT ([date]) AS data_count,
COUNT([time]) AS time_count,
COUNT(amount) AS amount_count,
COUNT(seller_id) AS seller_id_count
FROM fantasy.events
WHERE [date] IS NULL
  OR [time] IS NULL
  OR amount IS NULL
  OR seller_id IS NULL

  -- все 508186 пропусков содержатся в поле seller_id, то есть в данных нети инф о продавце

  -- видимл в таком случае покупки совершались в игровом магазине, а не у другого продавца

  -- таблица classes

  SELECT c.table_schema,
       c.table_name,
       c.column_name,
       c.data_type,
       k.constraint_name
FROM information_schema.columns AS c 
LEFT JOIN information_schema.key_column_usage AS k 
    ON c.table_schema = k.table_schema
   AND c.table_name = k.table_name
   AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'classes'
ORDER BY c.table_name

--   в таблице classes есть поля class_id и class, тип данных character varying, первычным ключом является class_id

-- общ кол-во пропусков

SELECT COUNT(*)
FROM fantasy.classes
WHERE class_id IS NULL 
OR CLASS IS NULL

-- нет пропусков

SELECT CLASS,
COUNT (*)
FROM fantasy.classes
GROUP BY class

-- в игре существует 13 уникальных классов персонажей 

-- Это Archer, Barbarian, Bard, Druid, Engineer, Healer, Knight, Mage, Monk, Necromancer, Paladin, Rogue, Shaman

-- таблица country

SELECT table_schema, table_name, column_name, data_type, constraint_name  
FROM information_schema.columns AS c
LEFT JOIN information_schema.key_column_usage AS k ON c.table_schema = k.table_schema
   AND c.table_name = k.table_name
   AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'country' 
ORDER BY c.table_name

--  в данной таблице 2 поля - loc_id (первичный ключ) и location, тип данных character varying 

SELECT location,
COUNT(*)
FROM fantasy.country
GROUP BY LOCATION

-- в игре зарегистрованны игроки из стран: United States, China, Japan, South Korea, Russia

-- пропуски

SELECT COUNT(*)
FROM fantasy.country
WHERE LOCATION IS NULL OR loc_id IS NULL 

-- пропусков не обнаружено

--таблица items

SELECT table_schema, table_name, column_name, data_type, constraint_name  
FROM information_schema.columns AS c
LEFT JOIN information_schema.key_column_usage AS k ON c.table_schema = k.table_schema
   AND c.table_name = k.table_name
   AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'items' 
ORDER BY c.table_name

--в таблице есть item_code (первичный ключ) - integer, и game_items -  character varying

SELECT game_items
FROM fantasy.items

--всего 184 эпических придметов, которым может пользоваться игрок 

SELECT COUNT(*)
FROM fantasy.items
WHERE game_items IS NULL OR item_code IS NULL

-- пропусков не обнаружено 

--таблица skills

SELECT table_schema, table_name, column_name, data_type, constraint_name  
FROM information_schema.columns AS c
LEFT JOIN information_schema.key_column_usage AS k ON c.table_schema = k.table_schema
   AND c.table_name = k.table_name
   AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'skills' 
ORDER BY c.table_name

--  таблице имеется ch_id (первичный ключ),  legendary_skill - тип данных: character varying

SELECT ch_id, COUNT (*)
FROM fantasy.skills
GROUP BY ch_id

--всего 181 уникальных умений на выбор. 

--Считаем по идентификатору легендарного умения - ch_id, т.к. может быть одинаковое название у разных умений

SELECT COUNT(*)
FROM fantasy.skills
WHERE ch_id IS NULL OR legendary_skill IS NULL

-- пропуской не обнаружено 

-- таблица race

SELECT table_schema, table_name, column_name, data_type, constraint_name  
FROM information_schema.columns AS c
LEFT JOIN information_schema.key_column_usage AS k ON c.table_schema = k.table_schema
   AND c.table_name = k.table_name
   AND c.column_name = k.column_name
WHERE c.table_schema = 'fantasy' AND c.table_name = 'race' 
ORDER BY c.table_name

--  таблице имеется race_id (первичный ключ),  race - тип данных: character varying

SELECT race, COUNT (*)
FROM fantasy.race
GROUP BY race

-- всего семь рас: Angel, Demon, Elf, Hobbit, Human, Northman и Orc 

SELECT COUNT(*)
FROM fantasy.race
WHERE race_id IS NULL OR race IS NULL

-- пропуской не обнаружено 

-- В таблицах нет пропусков и нет дубликатов, т.к в таблицах содержатся первичные ключи, поэтому каждый код будет уникал.

--  Исследование доли платящих игроков

-- 1. Изучим, какую долю составляют игроки, которые купили внутриигровую валюту «райские лепестки» за реальные деньги, 

-- от общего количества зарегистрированных игроков. После этого проанализируем, существует ли взаимосвязь доли 

-- платящих игроков от выбранной расы персонажа

--доля платящих игроков по всем данным

SELECT COUNT (id) AS total_reg_users,
SUM (payer) AS pay_users
ROUND(SUM (payer) * 1.0 / COUNT (id) * 100,2) AS pers_pay_users
FROM fantasy.users

-- доля платящих игроков от выбранной расы персонажа

SELECT r.race,
SUM (u.payer) AS pay_users,
COUNT (*) AS count_reg,
ROUND(SUM (u.payer) * 1.0 / COUNT (*)*100,2) AS pers_pay_users
FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id 
GROUP BY r.race

-- Исследование внутриигровых покупок 

-- основные статистические показатели по полю покупки amount

;WITH median_value AS (
    SELECT TOP (1)
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) OVER () AS median
    FROM fantasy.events
),
purchase_stats AS (
    SELECT
        COUNT(amount) AS count_amount,
        SUM(amount) AS total_amount,
        MAX(amount) AS max_amount,
        MIN(amount) AS min_amount,
        AVG(CAST(amount AS decimal(18, 2))) AS avg_amount,
        STDEV(amount) AS stand_amount
    FROM fantasy.events
)
SELECT
    p.count_amount,
    p.total_amount,
    p.max_amount,
    p.min_amount,
    p.avg_amount,
    p.stand_amount,
    m.median
FROM purchase_stats AS p
CROSS JOIN median_value AS m

--встречаются ли покупки с нулевой стоимостью 

;WITH zero_amount AS (
           SELECT COUNT (amount) AS count_amount_zero
           FROM fantasy.events
           WHERE amount = 0

)

SELECT a.count_amount_zero,
COUNT (*) AS count_amount,
a.count_amount_zero * 1.0 / COUNT (amount)* 100 AS share
FROM zero_amount AS a 
CROSS JOIN fantasy.events AS e
GROUP BY a.count_amount_zero

;WITH percentile AS (  -- опред порог аномальности
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER () AS f_quartile,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) OVER () AS s_quartile,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) OVER () AS t_quartile
    FROM fantasy.events
    WHERE amount > 0
)
SELECT 
    f_quartile,
    t_quartile,
    t_quartile - f_quartile AS IQR,  -- квартильный размах
    t_quartile + 1.5 * (t_quartile - f_quartile) AS upper -- верхн порог
FROM percentile;

-- поиск покупок, которые превыш верх границу

;WITH percentile AS (
    SELECT TOP (1) 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER () AS f_quartile,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) OVER () AS s_quartile,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) OVER () AS t_quartile
    FROM fantasy.events
    WHERE amount > 0),
upper AS (
SELECT 
    f_quartile,
    t_quartile,
    t_quartile - f_quartile AS IQR,
    t_quartile + 1.5 * (t_quartile - f_quartile) AS upper
FROM percentile
)
SELECT e.*
FROM upper AS u
CROSS JOIN fantasy.events AS e
WHERE e.amount > u.upper
ORDER BY amount DESC 

;WITH percentile AS (
    SELECT TOP (1)
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER () AS f_quartile,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) OVER () AS t_quartile
    FROM fantasy.events
    WHERE amount > 0
),
threshold AS (
    SELECT
        t_quartile + 1.5 * (t_quartile - f_quartile) AS upper
    FROM percentile
),
player_amounts AS (
    SELECT
        e.id,
        COUNT(*) AS count_amount,
        SUM(e.amount) AS sum_amount
    FROM threshold AS t
    CROSS JOIN fantasy.events AS e
    WHERE e.amount > t.upper
    GROUP BY e.id
),

player_shares AS (

    SELECT

        id,

        count_amount,

        sum_amount,

        COUNT(*) OVER () AS count_users,

        SUM(count_amount) OVER () AS total_anomaly_orders,

        SUM(sum_amount) OVER () AS total_anomaly_amount,

        ROUND((sum_amount * 100.0 / SUM(sum_amount) OVER ()),2) AS share_percent

    FROM player_amounts

)

SELECT TOP (10) *
FROM player_shares
ORDER BY sum_amount DESC;

-- популярные эпические предметы 

;WITH item_stats AS (

    SELECT

        i.game_items,

        COUNT(*) AS total_orders,    -- количество покупок предмета

        COUNT(DISTINCT e.id) AS unique_buyers  -- количество уникальных игроков, которые приобрели этот предмет

    FROM fantasy.events AS e

    JOIN fantasy.items AS i

        ON e.item_code = i.item_code

    WHERE e.amount > 0

    GROUP BY i.game_items

)

SELECT

    game_items,

    total_orders,

    ROUND(total_orders * 100.0 / SUM(total_orders) OVER (), 2) AS order_share,  --доля покупок каждого предмета

    unique_buyers,

    ROUND(unique_buyers * 100.0 /(SELECT COUNT(DISTINCT id)  -- долю покупателей

         FROM fantasy.events

         WHERE amount > 0),2) AS player_share

FROM item_stats

ORDER BY unique_buyers DESC;

--- динамика покупок

SELECT MIN(TRY_CONVERT(date, [date], 23)) AS min_date, -- рання дата покупки

MAX(TRY_CONVERT(date, [date], 23)) AS max_date, -- поздняя дата покупки 

COUNT([date]) AS count_date

FROM fantasy.events

-- анализ динамики покупок по месяцам 

SELECT

    DATEFROMPARTS(
        YEAR(TRY_CONVERT(date, [date], 23)),
        MONTH(TRY_CONVERT(date, [date], 23)),
        1
    ) AS month,

    COUNT(*) AS count_purchases,

    SUM(amount) AS total_amount,

    ROUND(AVG(CAST(amount AS decimal(18, 2))), 2) AS avg_purchase

FROM fantasy.events

GROUP BY DATEFROMPARTS(
        YEAR(TRY_CONVERT(date, [date], 23)),
        MONTH(TRY_CONVERT(date, [date], 23)),
        1
    )

ORDER BY month;

-- Анализ покупок по игровым предметам

-- Определяем количество покупок, число уникальных покупателей,

-- общую сумму и среднюю стоимость покупки каждого предмета.

SELECT

    i.game_items,

    COUNT(e.transaction_id) AS total_purchases,

    COUNT(DISTINCT e.id) AS unique_buyers,

    SUM(e.amount) AS total_revenue,

    ROUND(AVG(e.amount), 2) AS avg_purchase_amount

FROM fantasy.events AS e

JOIN fantasy.items AS i

    ON e.item_code = i.item_code

GROUP BY i.game_items

ORDER BY total_revenue DESC

-- Анализ покупательской активности по странам

-- Сравниваем количество зарегистрированных игроков и покупателей,

-- количество транзакций, общую сумму и среднюю стоимость покупки

-- в каждой стране.

SELECT

    c.location,

    COUNT(DISTINCT u.id) AS total_users,

    COUNT(DISTINCT e.id) AS buyers, -- кто соверш покупку

    COUNT(e.transaction_id) AS total_purchases, 

    SUM(e.amount) AS total_revenue,

    ROUND(AVG(e.amount), 2) AS avg_purchase_amount -- средняя стоимость одной транзакции

FROM fantasy.users AS u

JOIN fantasy.country AS c

    ON u.loc_id = c.loc_id

LEFT JOIN fantasy.events AS e

    ON u.id = e.id

GROUP BY c.location

ORDER BY total_revenue DESC

-- Анализ покупательской активности по игровым классам

-- Сравниваем количество зарегистрированных игроков и покупателей,

-- количество транзакций, общую сумму и среднюю стоимость покупки

-- для каждого игрового класса.

SELECT

    cl.class,

    COUNT(DISTINCT u.id) AS total_users,

    COUNT(DISTINCT e.id) AS buyers,

    COUNT(e.transaction_id) AS total_purchases,

    SUM(e.amount) AS total_revenue,

    ROUND(AVG(e.amount), 2) AS avg_purchase_amount

FROM fantasy.users AS u

JOIN fantasy.classes AS cl

    ON u.class_id = cl.class_id

LEFT JOIN fantasy.events AS e

    ON u.id = e.id

GROUP BY cl.class

ORDER BY total_revenue DESC

-- Зависимость активности игроков от расы персонажа

SELECT

    race,

    COUNT(DISTINCT e.id) AS unique_buyers, -- игроки соверш покупки

    COUNT(DISTINCT u.id) AS reg_users, -- кол-во зарег игроков

    COUNT(DISTINCT e.id) * 100.0/ COUNT(DISTINCT u.id) AS share_buyers, -- доля покупателей среди зарег игроков

    COUNT(DISTINCT CASE -- доля игроков с payer = 1 среди покупателей расы

                   WHEN u.payer = 1 THEN u.id

                   ELSE NULL

                   END) * 100.0 / COUNT(DISTINCT e.id) AS share_payers,

COUNT(e.transaction_id)*1.0 / COUNT(DISTINCT e.id) AS avg_purchases, -- средн кол-во покупок на одного покупателя

SUM(e.amount) * 1.0 / COUNT(e.transaction_id) AS avg_purchase_amount, -- сред стоимость 1 покупки

SUM(e.amount) * 1.0 / COUNT(DISTINCT e.id) AS avg_total_spent --сред общая сумма покупок на одного покупателя

FROM fantasy.race AS r

LEFT JOIN fantasy.users AS u

    ON r.race_id = u.race_id

LEFT JOIN fantasy.events AS e

    ON u.id = e.id

    AND e.amount > 0

GROUP BY race

-----------------------------------------------------------------------------------------------------------------
