SELECT
    MIN(order_date) AS periode_awal,
    MAX(order_date) AS periode_akhir,
    COUNT(*) AS total_transaksi,
    COUNT(DISTINCT product_id) AS jumlah_produk_terjual,
    COUNT(DISTINCT store_id) AS jumlah_toko_aktif,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(cost), 2) AS total_cost,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(revenue) * 100, 2) AS overall_margin_pct,
    ROUND(AVG(revenue), 2) AS avg_order_value,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct
FROM sales;