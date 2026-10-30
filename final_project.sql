CREATE DATABASE Customers_transactions;

UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
ALTER TABLE customers MODIFY Age INT NULL;

SELECT * FROM transactions;

CREATE TABLE transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10, 3),
Sum_payment DECIMAL (10, 2));

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions_info.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Задание 1
SELECT 
	ID_client,
    COUNT(DISTINCT date_format(date_new, '%Y-%m')) AS active_months,
    round(SUM(Sum_payment) / COUNT(DISTINCT Id_check), 2) AS avg_check,
    round(SUM(Sum_payment) / 13, 2) AS avg_month_pur,
    COUNT(DISTINCT Id_check) AS total_operations
FROM transactions
WHERE date_new >= '2015-06-01'
AND date_new <= '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT date_format(date_new, '%Y-%m')) = 13
ORDER BY ID_client;

-- Задание 2a
SELECT
	date_format(date_new, '%Y-%m') AS `month`,
    round(SUM(Sum_payment) / COUNT(DISTINCT Id_check), 2) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01'
AND	date_new <= '2016-06-01'    
GROUP BY date_format(date_new, '%Y-%m')
ORDER BY `month`;

-- Задание 2b
SELECT
	round(AVG(total_ops), 2) AS avg_month_ops
FROM(
SELECT
	date_format(date_new, '%Y-%m') AS `month`,
	COUNT(DISTINCT Id_check) AS total_ops
FROM transactions
WHERE date_new >= '2015-06-01'
AND date_new <= '2016-06-01'
GROUP BY date_format(date_new, '%Y-%m')
) AS month_data;


-- Задание 2c
SELECT
    ROUND(AVG(active_customers), 2) AS avg_monthly_customers
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS `month`,
        COUNT(DISTINCT ID_client) AS active_customers
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <= '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
) AS month_data;

-- Задание 2d
SELECT
date_format(date_new, '%Y-%m') AS `month`,
COUNT(DISTINCT Id_check) AS total_ops,
round(
   COUNT(DISTINCT Id_check) * 100 /
(
	SELECT COUNT(DISTINCT Id_check)
	FROM transactions
	WHERE date_new >= '2015-06-01'
	AND date_new <= '2016-06-01'
  ), 2
) AS ops_percent,
round(SUM(Sum_payment), 2) AS total_amount,
round(
	SUM(Sum_payment) * 100 /
    (
		SELECT SUM(Sum_payment)
        FROM transactions
        WHERE date_new >= '2015-06-01'
        AND date_new <= '2016-06-01'
        ), 2
	) AS amount_percent
FROM transactions
WHERE date_new >= '2015-06-01'
AND date_new <= '2016-06-01'
GROUP BY date_format(date_new, '%Y-%m')
ORDER BY `month`;

-- Задание 3
SELECT
    CASE WHEN c.Age IS NULL THEN 'NA'
         ELSE CONCAT(LPAD(FLOOR(c.Age / 10) * 10, 2, '0'), '-',
                     LPAD(FLOOR(c.Age / 10) * 10 + 9, 2, '0'))
    END AS age_group,
    COUNT(DISTINCT t.ID_client) AS clients,
    COUNT(DISTINCT t.Id_check) AS total_operations,
    ROUND(SUM(t.Sum_payment), 2) AS total_amount,
    ROUND(SUM(t.Sum_payment) / COUNT(DISTINCT t.Id_check), 2) AS avg_check,
    ROUND(100 * COUNT(DISTINCT t.Id_check) / SUM(COUNT(DISTINCT t.Id_check)) OVER (), 2) AS ops_percent,
    ROUND(100 * SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER (), 2) AS amount_percent
FROM transactions AS t
LEFT JOIN customers AS c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <= '2016-06-01'
GROUP BY age_group
ORDER BY age_group = 'NA', age_group;

WITH q AS (
    SELECT
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter_label,
        CASE WHEN c.Age IS NULL THEN 'NA'
             ELSE CONCAT(LPAD(FLOOR(c.Age / 10) * 10, 2, '0'), '-',
                         LPAD(FLOOR(c.Age / 10) * 10 + 9, 2, '0'))
        END AS age_group,
        COUNT(DISTINCT t.ID_client) AS clients,
        COUNT(DISTINCT t.Id_check) AS ops,
        SUM(t.Sum_payment) AS total
    FROM transactions AS t
    LEFT JOIN customers AS c ON t.ID_client = c.Id_client
    WHERE t.date_new >= '2015-06-01' AND t.date_new <= '2016-06-01'
    GROUP BY quarter_label, age_group
),
mq AS (
    SELECT CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS quarter_label,
           COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS months_in_q
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new <= '2016-06-01'
    GROUP BY quarter_label
)
SELECT
    q.quarter_label,
    mq.months_in_q,
    q.age_group,
    q.clients,
    q.ops AS total_operations,
    ROUND(q.total, 2) AS total_amount,
    ROUND(q.total / q.ops, 2) AS avg_check,
    ROUND(q.ops   / mq.months_in_q, 1) AS avg_ops_per_month,
    ROUND(q.total / mq.months_in_q, 2) AS avg_amount_per_month,
    ROUND(100 * q.ops / SUM(q.ops) OVER (PARTITION BY q.quarter_label), 2) AS ops_percent_in_quarter,
    ROUND(100 * q.total / SUM(q.total) OVER (PARTITION BY q.quarter_label), 2) AS amount_percent_in_quarter
FROM q
JOIN mq USING (quarter_label)
ORDER BY q.quarter_label, q.age_group = 'NA', q.age_group;


	