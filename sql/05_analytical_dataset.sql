-- =========================================
-- 1. TAMBAH KOLOM cocoa_level DI products (persisted, reusable)
-- =========================================
ALTER TABLE products
    ADD COLUMN cocoa_level VARCHAR(20)
    GENERATED ALWAYS AS (
        CASE
            WHEN cocoa_percent < 60 THEN 'Low (<60%)'
            WHEN cocoa_percent BETWEEN 60 AND 75 THEN 'Medium (60-75%)'
            ELSE 'High (>75%)'
        END
    ) STORED;

-- =========================================
-- 2. BUAT dim_calendar
-- =========================================
CREATE TABLE dim_calendar (
    `date_key`      DATE PRIMARY KEY,
    `year`          INT,
    `quarter`       INT,
    `month_num`     INT,
    `month_name`    VARCHAR(15),
    `year_month`    VARCHAR(7),
    `day_of_week`   VARCHAR(10),
    `is_weekend`    TINYINT
);

-- Generate baris tanggal dari 2023-01-01 s/d 2024-12-31
-- pakai recursive CTE (MySQL 8.0+)
INSERT INTO dim_calendar (`date_key`, `year`, `quarter`, `month_num`, `month_name`, `year_month`, `day_of_week`, `is_weekend`)
WITH RECURSIVE date_series AS (
    SELECT DATE('2023-01-01') AS dt
    UNION ALL
    SELECT dt + INTERVAL 1 DAY
    FROM date_series
    WHERE dt < '2024-12-31'
)
SELECT
    dt,
    YEAR(dt),
    QUARTER(dt),
    MONTH(dt),
    MONTHNAME(dt),
    DATE_FORMAT(dt, '%Y-%m'),
    DAYNAME(dt),
    IF(DAYOFWEEK(dt) IN (1,7), 1, 0)
FROM date_series;

-- =========================================
-- 3. VALIDASI FINAL
-- =========================================
SELECT COUNT(*) AS total_hari FROM dim_calendar;

SELECT p.cocoa_level, COUNT(*) AS jumlah_sku
FROM products p
GROUP BY p.cocoa_level;

SELECT MIN(s.order_date), MAX(s.order_date), MIN(dc.date_key), MAX(dc.date_key)
FROM sales s, dim_calendar dc;