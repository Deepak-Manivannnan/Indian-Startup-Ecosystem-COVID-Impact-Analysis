-- Project: Indian Startup Ecosystem - COVID Impact Analysis
-- Dataset: 4135 rows | 2015 - 2025
-- Tools: MySQL
-- Description: SQL analysis of startup funding trends across Pre-COVID, COVID, and Post-COVID periods
-- Create Table
USE indian_startup_funding;

CREATE TABLE startup_funding (
    date DATE,
    startup_name VARCHAR(100),
    industry VARCHAR(50),
    city VARCHAR(50),
    investment_type VARCHAR(50),
    amount_usd VARCHAR(30),
    period VARCHAR(20)
);


-- Fix NULL Values and Correct Data Types
SET SQL_SAFE_UPDATES = 0;

UPDATE startup_funding SET amount_usd = NULL WHERE amount_usd = '';
ALTER TABLE startup_funding MODIFY amount_usd DECIMAL(20,2);

SET SQL_SAFE_UPDATES = 1;

-- Data Validation check 
SELECT COUNT(*) FROM startup_funding;

SELECT 
    COUNT(*) - COUNT(date) AS date_nulls,
    COUNT(*) - COUNT(startup_name) AS startup_name_nulls,
    COUNT(*) - COUNT(industry) AS industry_nulls,
    COUNT(*) - COUNT(city) AS city_nulls,
    COUNT(*) - COUNT(investment_type) AS investment_type_nulls,
    COUNT(*) - COUNT(amount_usd) AS amount_usd_nulls,
    COUNT(*) - COUNT(period) AS period_nulls
FROM
    startup_funding;

SET SQL_SAFE_UPDATES = 0;

UPDATE startup_funding SET industry = NULL WHERE industry = '';
UPDATE startup_funding SET city = NULL WHERE city = '';

SET SQL_SAFE_UPDATES = 1;

SELECT 
    COUNT(*) - COUNT(date) AS date_nulls,
    COUNT(*) - COUNT(startup_name) AS startup_name_nulls,
    COUNT(*) - COUNT(industry) AS industry_nulls,
    COUNT(*) - COUNT(city) AS city_nulls,
    COUNT(*) - COUNT(investment_type) AS investment_type_nulls,
    COUNT(*) - COUNT(amount_usd) AS amount_usd_nulls,
    COUNT(*) - COUNT(period) AS period_nulls
FROM
    startup_funding;

-- ================================================
-- FUNDING TREND ANALYSIS
-- ================================================

-- Year over year total funding and deal count from 2015 to 2025
SELECT 
    YEAR(date) AS year,
    SUM(amount_usd) AS total_funding,
    COUNT(*) AS deal_count
FROM
    startup_funding
GROUP BY YEAR(date)
ORDER BY year;

-- Total funding and deal count across Pre-COVID, COVID, and Post-COVID periods
SELECT 
    period,
    COUNT(*) AS deal_count,
    SUM(amount_usd) AS total_funding
FROM
    startup_funding
GROUP BY period
ORDER BY CASE
    WHEN period = 'Pre-COVID' THEN 1
    WHEN Period = 'COVID' THEN 2
    WHEN Period = 'Post-COVID' THEN 3
END;

-- Percentage change in funding between periods
WITH period_totals AS (
    SELECT 
        period,
        COUNT(*) AS deal_count,
        SUM(amount_usd) AS total_funding
    FROM startup_funding
    GROUP BY period
    ORDER BY CASE 
        WHEN period = 'Pre-COVID' THEN 1
        WHEN period = 'COVID' THEN 2
        WHEN period = 'Post-COVID' THEN 3
    END
)
SELECT 
    period,
    deal_count,
    total_funding,
    ROUND((total_funding - LAG(total_funding) OVER(ORDER BY CASE 
        WHEN period = 'Pre-COVID' THEN 1
        WHEN period = 'COVID' THEN 2
        WHEN period = 'Post-COVID' THEN 3
    END)) / LAG(total_funding) OVER(ORDER BY CASE 
        WHEN period = 'Pre-COVID' THEN 1
        WHEN period = 'COVID' THEN 2
        WHEN period = 'Post-COVID' THEN 3
    END) * 100, 2) AS pct_change
FROM period_totals;

-- Cumulative running total of funding year over year
WITH yearly_funding AS (
    SELECT
        YEAR(date) AS year,
        SUM(amount_usd) AS total_funding
    FROM startup_funding
    WHERE amount_usd IS NOT NULL
    GROUP BY YEAR(date)
)
SELECT
    year,
    total_funding,
    SUM(total_funding) OVER (
        ORDER BY year
    ) AS running_total
FROM yearly_funding;

-- ================================================
-- SECTOR ANALYSIS
-- ================================================

-- Total funding and deal count per sector
SELECT 
    industry,
    SUM(amount_usd) AS total_funding,
    COUNT(*) AS deal_count
FROM
    startup_funding
WHERE
    industry IS NOT NULL
GROUP BY industry;

-- Sector wise funding and deal count across three periods
SELECT 
    industry,
    SUM(amount_usd) AS total_funding,
    COUNT(*) AS deal_count,
    period
FROM
    startup_funding
WHERE
    industry IS NOT NULL
GROUP BY industry , period
ORDER BY CASE
    WHEN period = 'Pre-COVID' THEN 1
    WHEN period = 'COVID' THEN 2
    WHEN period = 'Post-COVID' THEN 3
END , total_funding DESC;

-- Sector with the highest average deal size
SELECT 
    industry, AVG(amount_usd) AS avg_deal_size
FROM
    startup_funding
WHERE
    industry IS NOT NULL
GROUP BY industry
ORDER BY avg_deal_size DESC
LIMIT 1;

-- Sectors completely absent during COVID
SELECT 
    industry,
    SUM(CASE
        WHEN period = 'Pre-COVID' THEN 1
        ELSE 0
    END) AS pre_covid_deals,
    SUM(CASE
        WHEN period = 'COVID' THEN 1
        ELSE 0
    END) AS covid_deals,
    SUM(CASE
        WHEN period = 'Post-COVID' THEN 1
        ELSE 0
    END) AS post_covid_deals
FROM
    startup_funding
WHERE
    industry IS NOT NULL
GROUP BY industry
HAVING covid_deals = 0;

-- Most active sectors with lowest average funding per deal 
SELECT 
    industry,
    COUNT(*) AS deal_count,
    SUM(amount_usd) AS total_funding,
    ROUND(SUM(amount_usd) / COUNT(*), 2) AS avg_funding_per_deal
FROM
    startup_funding
WHERE
    industry IS NOT NULL
GROUP BY industry
ORDER BY deal_count DESC , total_funding ASC;

-- ================================================
-- CITY ANALYSIS
-- ================================================

-- Total funding and deal count per city
SELECT 
    city,
    COUNT(*) AS deal_count,
    SUM(amount_usd) AS total_funding
FROM
    startup_funding
WHERE
    city IS NOT NULL
        AND amount_usd IS NOT NULL
GROUP BY city
ORDER BY total_funding DESC;

-- City wise funding across three periods
SELECT 
    city,
    SUM(CASE
        WHEN period = 'Pre-COVID' THEN amount_usd
        ELSE 0
    END) AS pre_covid_funding,
    SUM(CASE
        WHEN period = 'COVID' THEN amount_usd
        ELSE 0
    END) AS covid_funding,
    SUM(CASE
        WHEN period = 'Post-COVID' THEN amount_usd
        ELSE 0
    END) AS post_covid_funding
FROM
    startup_funding
WHERE
    city IS NOT NULL
        AND amount_usd IS NOT NULL
GROUP BY city
ORDER BY pre_covid_funding DESC , covid_funding DESC , post_covid_funding DESC;

-- Cities with most deals during COVID
SELECT 
    city, COUNT(*) AS deal_count
FROM
    startup_funding
WHERE
    city IS NOT NULL AND period = 'COVID'
GROUP BY city
ORDER BY deal_count DESC;

-- Percentage of total funding held by top 5 cities 
SELECT 
    city,
    ROUND(SUM(amount_usd) / (SELECT 
                    SUM(amount_usd)
                FROM
                    startup_funding) * 100,
            2) AS pct_of_total_funding
FROM
    startup_funding
WHERE
    city IS NOT NULL
GROUP BY city
ORDER BY pct_of_total_funding DESC
LIMIT 5;

-- ================================================
-- INVESTMENT TYPE ANALYSIS
-- ================================================

-- Total funding and deal count per investment type
SELECT 
    investment_type,
    SUM(amount_usd) AS total_funding,
    COUNT(*) AS deal_count
FROM
    startup_funding
GROUP BY investment_type
ORDER BY total_funding DESC;

-- Investment type distribution across three periods
SELECT 
    investment_type,
    SUM(CASE
        WHEN period = 'Pre-COVID' THEN 1
        ELSE 0
    END) AS pre_covid_deal_count,
    SUM(CASE
        WHEN period = 'Pre-COVID' THEN amount_usd
        ELSE 0
    END) AS pre_covid_funding,
    SUM(CASE
        WHEN period = 'COVID' THEN 1
        ELSE 0
    END) AS covid_deal_count,
    SUM(CASE
        WHEN period = 'COVID' THEN amount_usd
        ELSE 0
    END) AS covid_funding,
    SUM(CASE
        WHEN period = 'Post-COVID' THEN 1
        ELSE 0
    END) AS post_covid_deal_count,
    SUM(CASE
        WHEN period = 'Post-COVID' THEN amount_usd
        ELSE 0
    END) AS post_covid_funding
FROM
    startup_funding
GROUP BY investment_type;

-- Investment type with highest average deal size
SELECT 
    investment_type, AVG(amount_usd) AS avg_deal_size
FROM
    startup_funding
GROUP BY investment_type
ORDER BY avg_deal_size DESC
LIMIT 1;

-- Most active investment types during COVID
SELECT 
    investment_type, COUNT(*) AS deal_count
FROM
    startup_funding
WHERE
    period = 'COVID'
GROUP BY investment_type
ORDER BY deal_count DESC;

-- ================================================
-- CROSS DIMENSIONAL ANALYSIS
-- ================================================

-- Top 10 sector and city combinations by total funding
SELECT 
    industry, city, SUM(amount_usd) AS total_funding
FROM
    startup_funding
WHERE
    industry IS NOT NULL
        AND city IS NOT NULL
        AND amount_usd IS NOT NULL
GROUP BY industry , city
ORDER BY total_funding DESC
LIMIT 10;

-- Dominant sector per city by deal count
SELECT 
    t1.city, t1.industry, t1.deal_count
FROM
    (SELECT 
        industry, city, COUNT(*) AS deal_count
    FROM
        startup_funding
    WHERE
        industry IS NOT NULL
            AND city IS NOT NULL
    GROUP BY industry , city) t1
        INNER JOIN
    (SELECT 
        city, MAX(deal_count) AS max_deals
    FROM
        (SELECT 
        industry, city, COUNT(*) AS deal_count
    FROM
        startup_funding
    WHERE
        industry IS NOT NULL
            AND city IS NOT NULL
    GROUP BY industry , city) t2
    GROUP BY city) t3 ON t1.city = t3.city
        AND t1.deal_count = t3.max_deals
ORDER BY t1.deal_count DESC;

-- Most common investment type per sector
SELECT 
    t1.industry, t1.investment_type, t1.deal_count
FROM
    (SELECT 
        industry, investment_type, COUNT(*) AS deal_count
    FROM
        startup_funding
    WHERE
        industry IS NOT NULL
    GROUP BY industry , investment_type) t1
        INNER JOIN
    (SELECT 
        industry, MAX(deal_count) AS max_deals
    FROM
        (SELECT 
        industry, investment_type, COUNT(*) AS deal_count
    FROM
        startup_funding
    WHERE
        industry IS NOT NULL
    GROUP BY industry , investment_type) t2
    GROUP BY industry) t3 ON t1.industry = t3.industry
        AND t1.deal_count = t3.max_deals
ORDER BY t1.deal_count DESC;

-- Most active city and sector combinations during COVID
SELECT 
    city, industry, COUNT(*) AS deal_count
FROM
    startup_funding
WHERE
    city IS NOT NULL AND period = 'COVID'
GROUP BY city , industry
ORDER BY deal_count DESC;