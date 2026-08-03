-- a. Business Analysis: BQ #1 (Revenue/Cost/Profit per Kategori)
SELECT
    p.category,
    COUNT(*) AS jumlah_transaksi,
    ROUND(SUM(s.revenue), 2) AS total_revenue,
    ROUND(SUM(s.cost), 2) AS total_cost,
    ROUND(SUM(s.profit), 2) AS total_profit,
    ROUND(SUM(s.profit) / SUM(s.revenue) * 100, 2) AS margin_pct,
    ROUND(SUM(s.revenue) / (SELECT SUM(revenue) FROM sales) * 100, 2) AS pct_of_total_revenue,
    ROUND(AVG(s.revenue), 2) AS avg_order_value
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY total_profit DESC;

-- b. Business Analysis: BQ #2 (Cocoa % vs Profit Margin)
SELECT
    CASE
        WHEN p.cocoa_percent < 60 THEN 'Low (<60%)'
        WHEN p.cocoa_percent BETWEEN 60 AND 75 THEN 'Medium (60-75%)'
        ELSE 'High (>75%)'
    END AS cocoa_level,
    COUNT(DISTINCT p.product_id) AS jumlah_sku,
    COUNT(*) AS jumlah_transaksi,
    ROUND(AVG(p.cocoa_percent), 2) AS avg_cocoa_pct,
    ROUND(SUM(s.revenue), 2) AS total_revenue,
    ROUND(SUM(s.cost), 2) AS total_cost,
    ROUND(SUM(s.profit), 2) AS total_profit,
    ROUND(SUM(s.profit) / SUM(s.revenue) * 100, 2) AS margin_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY cocoa_level
ORDER BY avg_cocoa_pct;

-- c. Business Analysis: BQ #3 (Profitabilitas Geografis & Ranking Toko)
-- c.1 Profit per Negara
SELECT
    st.country,
    COUNT(DISTINCT st.store_id) AS jumlah_toko,
    ROUND(SUM(s.revenue), 2) AS total_revenue,
    ROUND(SUM(s.profit), 2) AS total_profit,
    ROUND(SUM(s.profit) / SUM(s.revenue) * 100, 2) AS margin_pct,
    ROUND(SUM(s.revenue) / (SELECT SUM(revenue) FROM sales) * 100, 2) AS pct_of_total_revenue
FROM sales s
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.country
ORDER BY total_profit DESC;

-- c.2 Ranking Toko Terbaik per Negara (Window Function)
SELECT *
FROM (
    SELECT
        st.country,
        st.store_id,
        st.store_name,
        st.store_type,
        ROUND(SUM(s.profit), 2) AS store_profit,
        ROUND(SUM(s.profit) / SUM(s.revenue) * 100, 2) AS store_margin_pct,
        RANK() OVER (PARTITION BY st.country ORDER BY SUM(s.profit) DESC) AS rank_in_country
    FROM sales s
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.country, st.store_id, st.store_name, st.store_type
) ranked
WHERE rank_in_country <= 3
ORDER BY country, rank_in_country;

-- d. Business Analysis: BQ #4 (Korelasi Diskon vs Volume di Toko Underperforming)
-- d.1 Identifikasi & profil 15 toko performa terendah
WITH bottom_stores AS (
    SELECT store_id
    FROM sales
    GROUP BY store_id
    ORDER BY SUM(profit) ASC
    LIMIT 15
)
SELECT
    st.store_id,
    st.store_name,
    st.country,
    st.store_type,
    ROUND(SUM(s.profit), 2) AS store_profit,
    ROUND(SUM(s.profit) / SUM(s.revenue) * 100, 2) AS store_margin_pct,
    ROUND(AVG(s.discount) * 100, 2) AS avg_discount_pct,
    ROUND(AVG(s.quantity), 2) AS avg_quantity
FROM sales s
JOIN stores st ON s.store_id = st.store_id
WHERE s.store_id IN (SELECT store_id FROM bottom_stores)
GROUP BY st.store_id, st.store_name, st.country, st.store_type
ORDER BY store_profit ASC;

-- d.2 Pearson Correlation: discount vs quantity (khusus 15 toko ini)
WITH bottom_stores AS (
    SELECT store_id
    FROM sales
    GROUP BY store_id
    ORDER BY SUM(profit) ASC
    LIMIT 15
)
SELECT
    COUNT(*) AS jumlah_transaksi,
    ROUND(
      (COUNT(*) * SUM(s.discount * s.quantity) - SUM(s.discount) * SUM(s.quantity))
      /
      (
        SQRT(COUNT(*) * SUM(POW(s.discount,2)) - POW(SUM(s.discount),2))
        *
        SQRT(COUNT(*) * SUM(POW(s.quantity,2)) - POW(SUM(s.quantity),2))
      )
    , 4) AS pearson_correlation_discount_vs_quantity
FROM sales s
WHERE s.store_id IN (SELECT store_id FROM bottom_stores);

-- e. Store Type Performance (Airport vs Lainnya)
SELECT
    st.store_type,
    COUNT(DISTINCT st.store_id) AS jumlah_toko,
    COUNT(*) AS jumlah_transaksi,
    ROUND(SUM(s.revenue), 2) AS total_revenue,
    ROUND(SUM(s.profit), 2) AS total_profit,
    ROUND(SUM(s.profit) / SUM(s.revenue) * 100, 2) AS margin_pct,
    ROUND(SUM(s.profit) / COUNT(DISTINCT st.store_id), 2) AS avg_profit_per_store,
    ROUND(AVG(s.revenue), 2) AS avg_order_value,
    ROUND(AVG(s.discount) * 100, 2) AS avg_discount_pct
FROM sales s
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_type
ORDER BY avg_profit_per_store ASC;

-- f. Uji Hipotesis: Variabilitas Performa per Store Type
WITH store_profit AS (
    SELECT
        st.store_type,
        st.store_id,
        SUM(s.profit) AS profit_per_store
    FROM sales s
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.store_type, st.store_id
)
SELECT
    store_type,
    COUNT(*) AS jumlah_toko,
    ROUND(AVG(profit_per_store), 2) AS avg_profit,
    ROUND(STDDEV(profit_per_store), 2) AS stddev_profit,
    ROUND(STDDEV(profit_per_store) / AVG(profit_per_store) * 100, 2) AS coefficient_of_variation_pct,
    ROUND(MIN(profit_per_store), 2) AS min_profit,
    ROUND(MAX(profit_per_store), 2) AS max_profit,
    ROUND(MAX(profit_per_store) - MIN(profit_per_store), 2) AS range_profit
FROM store_profit
GROUP BY store_type
ORDER BY coefficient_of_variation_pct DESC;
