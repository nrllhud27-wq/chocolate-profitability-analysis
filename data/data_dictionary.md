# Data Dictionary

*Raw data (990,236+ transaction rows) is not published in this repository — both for business confidentiality and because GitHub's file size limits reject CSVs of this scale. This document describes the schema and column definitions of the source dataset instead.*

---

## 1. `sales.csv` — Transaction Fact Table

Source: exported from the company's ERP/POS system. One row = one transaction line.

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR | Unique transaction identifier (primary key) |
| `order_date` | DATE | Date the transaction occurred |
| `product_id` | VARCHAR | Foreign key to `products.csv` |
| `store_id` | VARCHAR | Foreign key to `stores.csv` |
| `customer_id` | VARCHAR | Customer identifier (present in raw data; excluded from analysis per project scope — see [Technical Documentation](../docs/TECHNICAL_DOCUMENTATION.md#8-project-scope)) |
| `quantity` | INT | Number of units sold in the transaction |
| `unit_price` | DECIMAL | Price per unit before discount |
| `discount` | DECIMAL | Discount rate applied to the transaction (0–1 scale) |
| `revenue` | DECIMAL | Net revenue after discount: `Quantity × Unit Price × (1 − Discount)` |
| `cost` | DECIMAL | Total cost of goods sold for the transaction |
| `profit` | DECIMAL | `Revenue − Cost` |

## 2. `products.csv` — Product Dimension Table

One row per SKU (200 total).

| Column | Type | Description |
|---|---|---|
| `product_id` | VARCHAR | Unique product identifier (primary key) |
| `product_name` | VARCHAR | Product display name |
| `brand` | VARCHAR | Product brand |
| `category` | VARCHAR | Product category: Praline, White, Dark, Truffle, or Milk |
| `cocoa_percent` | DECIMAL | Cocoa content percentage (approx. 50%–90%) |
| `weight_g` | INT | Product weight in grams |

## 3. `stores.csv` — Store Dimension Table

One row per store (100 total).

| Column | Type | Description |
|---|---|---|
| `store_id` | VARCHAR | Unique store identifier (primary key) |
| `store_name` | VARCHAR | Store display name |
| `city` | VARCHAR | City where the store operates |
| `country` | VARCHAR | Country where the store operates (6 total: Canada, UK, USA, France, Australia, Germany) |
| `store_type` | VARCHAR | Store format: Retail, Mall, Airport, or Online |

---

## 4. Engineered Columns (Feature Engineering)

Added during data processing — not present in the original raw files. See [Technical Documentation §14](../docs/TECHNICAL_DOCUMENTATION.md#14-methodology) for details.

| Column | Table | Description |
|---|---|---|
| `profit_margin_pct` | `sales` | Generated column: `(Profit ÷ Revenue) × 100`, auto-recalculated whenever profit/revenue changes |
| `cocoa_level` | `products` | Generated column classifying `cocoa_percent` into three tiers: Low (<60%), Medium (60–75%), High (>75%) |
| `Dim_Calendar` | *(new table)* | Purpose-built calendar dimension (731 continuous dates, Jan 2023–Dec 2024) with `year`, `quarter`, `month_num`, `month_name`, `year_month`, `day_of_week`, `is_weekend` — built to support Power BI time-intelligence, since `order_date` alone only contains dates with recorded transactions |

---

## 5. Known Data Quality Note

9,764 rows (0.98%) in `sales.csv` reference two `product_id` values (`P0000`, `P0201`) that do not exist in `products.csv`. These rows were excluded from analysis. Full detail in [Technical Documentation §12](../docs/TECHNICAL_DOCUMENTATION.md#12-data-quality-assessment).
