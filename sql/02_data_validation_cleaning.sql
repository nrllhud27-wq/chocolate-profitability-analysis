-- =========================================
-- A. MISSING VALUES (cek semua kolom penting)
-- =========================================
SELECT
    SUM(order_date IS NULL)   AS null_order_date,
    SUM(product_id IS NULL OR product_id = '')  AS null_product_id,
    SUM(store_id IS NULL OR store_id = '')      AS null_store_id,
    SUM(quantity IS NULL)     AS null_quantity,
    SUM(unit_price IS NULL)   AS null_unit_price,
    SUM(discount IS NULL)     AS null_discount,
    SUM(revenue IS NULL)      AS null_revenue,
    SUM(cost IS NULL)         AS null_cost,
    SUM(profit IS NULL)       AS null_profit
FROM sales;

-- =========================================
-- B. DUPLICATE CHECK
-- =========================================
-- order_id sudah PRIMARY KEY (otomatis unik), 
-- tapi kita cek juga products & stores
SELECT product_id, COUNT(*) AS jumlah
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT store_id, COUNT(*) AS jumlah
FROM stores
GROUP BY store_id
HAVING COUNT(*) > 1;

-- =========================================
-- C. REFERENTIAL INTEGRITY (isolasi baris bermasalah)
-- =========================================
SELECT s.order_id, s.product_id, s.store_id, s.revenue, s.profit
FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id
WHERE p.product_id IS NULL
LIMIT 20;

SELECT COUNT(*) AS total_orphan_rows
FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

-- =========================================
-- D. VALIDASI RUMUS: Revenue = Quantity x Unit Price x (1 - Discount)
-- =========================================
SELECT COUNT(*) AS revenue_formula_mismatch
FROM sales
WHERE ABS(revenue - (quantity * unit_price * (1 - discount))) > 0.05;

-- =========================================
-- E. VALIDASI RUMUS: Profit = Revenue - Cost
-- =========================================
SELECT COUNT(*) AS profit_formula_mismatch
FROM sales
WHERE ABS(profit - (revenue - cost)) > 0.05;

-- =========================================
-- F. SANITY CHECK RANGE (nilai di luar batas wajar)
-- =========================================
SELECT
    SUM(discount < 0 OR discount > 1)          AS discount_out_of_range,
    SUM(quantity <= 0)                         AS quantity_invalid,
    SUM(revenue < 0 OR cost < 0)                AS negative_money,
    SUM(cocoa_percent NOT BETWEEN 0 AND 100)   AS cocoa_pct_invalid
FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id;



-- =========================================
-- 1. EXCLUDE baris dengan product_id invalid
-- =========================================
SET FOREIGN_KEY_CHECKS = 0;
DELETE s FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

-- =========================================
-- 2. Pasang kembali FK constraint (jaminan integritas ke depan)
-- =========================================
ALTER TABLE sales
    ADD CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    ADD CONSTRAINT fk_sales_store   FOREIGN KEY (store_id)   REFERENCES stores(store_id);
SET FOREIGN_KEY_CHECKS = 1;

-- =========================================
-- 3. FEATURE ENGINEERING: Profit Margin %
-- =========================================
ALTER TABLE sales
    ADD COLUMN profit_margin_pct DECIMAL(6,2)
    GENERATED ALWAYS AS (ROUND((profit / revenue) * 100, 2)) STORED;

-- =========================================
-- 4. VALIDASI FINAL
-- =========================================
SELECT
    COUNT(*) AS total_rows,
    ROUND(AVG(profit_margin_pct), 2) AS avg_margin_pct,
    MIN(profit_margin_pct) AS min_margin_pct,
    MAX(profit_margin_pct) AS max_margin_pct
FROM sales;