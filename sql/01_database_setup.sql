-- =========================================
-- 1. BUAT DATABASE
-- =========================================
CREATE DATABASE IF NOT EXISTS chocolate_profitability;
USE chocolate_profitability;

-- =========================================
-- 2. DIMENSION TABLE: PRODUCTS
-- =========================================
CREATE TABLE products (
    product_id      VARCHAR(10)   PRIMARY KEY,
    product_name    VARCHAR(100)  NOT NULL,
    brand           VARCHAR(50),
    category        VARCHAR(20)   NOT NULL,
    cocoa_percent   DECIMAL(5,2)  NOT NULL,
    weight_g        INT
);

-- =========================================
-- 3. DIMENSION TABLE: STORES
-- =========================================
CREATE TABLE stores (
    store_id        VARCHAR(10)   PRIMARY KEY,
    store_name      VARCHAR(100)  NOT NULL,
    city            VARCHAR(50),
    country         VARCHAR(50),
    store_type      VARCHAR(20)
);

-- =========================================
-- 4. FACT TABLE: SALES
-- =========================================
CREATE TABLE sales (
    order_id        VARCHAR(15)   PRIMARY KEY,
    order_date      DATE          NOT NULL,
    product_id      VARCHAR(10),
    store_id        VARCHAR(10),
    customer_id     VARCHAR(15),
    quantity        INT           NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    discount        DECIMAL(5,2)  NOT NULL,
    revenue         DECIMAL(12,2) NOT NULL,
    cost            DECIMAL(12,2) NOT NULL,
    profit          DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_sales_store   FOREIGN KEY (store_id)   REFERENCES stores(store_id)
);

-- =========================================
-- 5. IMPORT CSV
-- Urutan WAJIB: products & stores dulu, baru sales
-- (karena sales punya FK ke keduanya)
-- =========================================
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/stores.csv'
INTO TABLE stores
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- =========================================
-- 6. VALIDASI IMPORT
-- =========================================
SELECT 'products' AS table_name, COUNT(*) AS total_rows FROM products
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'sales', COUNT(*) FROM sales;

-- Hapus tabel sales yang FK-nya menolak baris kotor
DROP TABLE sales;

-- Buat ulang TANPA foreign key dulu — 
-- FK akan kita pasang lagi setelah data dibersihkan di PHASE 3
CREATE TABLE sales (
    order_id        VARCHAR(15)   PRIMARY KEY,
    order_date      DATE          NOT NULL,
    product_id      VARCHAR(10),
    store_id        VARCHAR(10),
    customer_id     VARCHAR(15),
    quantity        INT           NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    discount        DECIMAL(5,2)  NOT NULL,
    revenue         DECIMAL(12,2) NOT NULL,
    cost            DECIMAL(12,2) NOT NULL,
    profit          DECIMAL(12,2) NOT NULL
);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Validasi ulang — sekarang harus 1.000.000
SELECT COUNT(*) AS total_rows FROM sales;