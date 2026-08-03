# Technical Documentation
## Commercial Profitability & Product Strategy

*Full methodology, SQL logic, data modeling, and statistical analysis behind this project. For a quick overview, see the [main README](../README.md).*

---

## 1. Business Background

The company is a chocolate manufacturer and retailer processing over one million transactions across 200 SKUs spanning five product lines: Praline, White, Dark, Truffle, and Milk. It operates 100 stores across six countries, through four store formats: Retail, Mall, Airport, and Online.

Cocoa is the primary raw material and is exposed to global commodity price volatility. Because cocoa content varies by product (roughly 50%–90%), price swings do not affect every SKU equally — higher-cocoa products carry more raw-material cost exposure. If pricing has not been adjusted accordingly, certain product lines could be quietly eroding profitability. Profitability gaps can also arise at the store level (location, footfall, discounting) that are invisible in company-wide averages — which is why this project evaluates both product and store profitability together.

## 2. Business Problem

1. Products with higher cocoa content may carry production costs that are not proportionally reflected in their selling price.
2. Certain stores or store types may be consistently underperforming, without this being visible in aggregate company reporting.

## 3. Business Objectives

- Evaluate profitability (revenue, cost, profit, margin) across product categories.
- Test the relationship between cocoa percentage and profit margin.
- Identify high- and low-performing stores/store types and their contribution to profitability.
- Assess discount effectiveness on sales volume in underperforming stores.
- Produce recommendations grounded strictly in data, not pre-analysis assumptions.

## 4. Business Questions

| # | Question |
|---|---|
| 1 | How do revenue, cost, and profit compare across product categories? |
| 2 | Does a higher cocoa percentage result in a better or worse profit margin? |
| 3 | Which regions contribute the most to the bottom line? |
| 4 | Is there a correlation between discount rate and sales volume in underperforming stores? |

## 5. Stakeholders

| Stakeholder | Use Case |
|---|---|
| COO | Company-wide profitability visibility for operational decisions |
| VP of Sales | Store/geographic performance for sales and discount strategy |
| Product Manager | Category and cocoa-content profitability for pricing and SKU decisions |

## 6. KPI Definitions

| KPI | Definition |
|---|---|
| Total Revenue | Net sales value after discount |
| Total Cost | Total cost of goods sold |
| Total Profit | Revenue − Cost |
| Gross Profit Margin % | Profit ÷ Revenue |
| Average Order Value (AOV) | Average revenue per transaction |

## 7. Metric Tree

```
Revenue  =  Quantity × Unit Price × (1 − Discount)
Profit   =  Revenue − Cost
Margin % =  Profit ÷ Revenue
```

Margin % is the primary comparison metric in this project because it normalizes profitability across groups of very different size — a large category can generate more total profit than a small one purely from scale, but margin reveals whether that profit is generated *efficiently*.

## 8. Project Scope

**Included:** product profitability, geographic performance, store performance, discount effectiveness.

**Excluded:** inventory optimization, marketing campaign effectiveness, customer-level behavior (`customer_id` exists in raw data but was excluded from the model per scope), supply chain cost.

## 9. Data Source

Exported from the company's ERP/POS system as three relational CSV files:
- `sales.csv` — transaction fact data
- `products.csv` — product reference data
- `stores.csv` — store reference data

## 10. Dataset Overview

| Attribute | Value |
|---|---|
| Raw transactions | 1,000,000 |
| Valid transactions after cleaning | 990,236 (99.02%) |
| Period | Jan 1, 2023 – Dec 31, 2024 (731 days) |
| SKUs | 200 across 5 categories |
| Stores | 100 across 6 countries, 4 store types |
| Average discount rate | 5.62% |

All 200 SKUs and 100 stores had transaction activity within the period — no rationalization decision is based on missing/zero-activity data.

## 11. Data Dictionary

**Sales (Fact):** `order_id`, `product_id`, `quantity`, `revenue`, `cost`, `profit`
**Products (Dimension):** `category`, `cocoa_percent`, `weight_g`
**Stores (Dimension):** `city`, `country`, `store_type`

---

## 12. Data Quality Assessment

| Check | Result |
|---|---|
| Missing values (all key columns) | 0 |
| Duplicate records | 0 |
| Revenue formula validation | 0 mismatches |
| Profit formula validation | 0 mismatches |
| Out-of-range values (discount/quantity/cocoa%) | 0 |
| **Invalid `product_id` references** | **9,764 rows (0.98%)** |

Two `product_id` values (`P0000`, `P0201`) referenced in `sales.csv` did not exist in `products.csv`. These rows were excluded, since they could not be assigned a category or cocoa content — both central to the business questions. This is treated as a data quality finding and drives the long-term recommendation for stronger input validation at the source system.

## 13. Data Modeling — Star Schema

```
                    Dim_Product
                         │ 1:*
Dim_Store  ── 1:* ──  Sales_Fact  ── 1:* ──  Dim_Calendar
              (990,236 rows)
```

- **Fact:** `Sales_Fact` — one row per transaction.
- **Dimensions:** `Dim_Product` (200 SKUs, includes engineered `cocoa_level`), `Dim_Store` (100 stores), `Dim_Calendar` (731 continuous dates, built specifically to support Power BI time-intelligence).

Star Schema was chosen over a flat table to avoid duplicating product/store attributes across ~1M rows, to let Power BI's VertiPaq engine compress and query efficiently, and to match how business users naturally filter data — by product, store, or time.

---

## 14. Methodology

| Step | Description |
|---|---|
| 1. Database Setup | Normalized MySQL schema with explicit PK/FK; bulk-loaded 1M+ rows via `LOAD DATA INFILE`. |
| 2. Data Validation | Checked missing values, duplicates, referential integrity, and formula consistency. |
| 3. Data Cleaning | Removed 9,764 invalid-reference rows; re-applied FK constraints. |
| 4. Exploratory Analysis | Established company-wide baseline KPIs as benchmark for all breakdowns. |
| 5. Business Analysis | Answered all 4 Business Questions via SQL aggregation, classification, ranking, correlation. |
| 6. Feature Engineering | Added persisted columns (`profit_margin_pct`, `cocoa_level`) and `Dim_Calendar`. |
| 7. Data Modeling | Built Star Schema relationships and DAX measures in Power BI. |
| 8. Dashboard Development | 3-page dashboard: Executive, Operational, Store Deep-Dive. |
| 9. Business Insight | Interpreted results, distinguishing real patterns from ones disproven under further testing. |
| 10. Recommendation | Converted validated findings into short/medium/long-term actions. |

## 15. SQL Techniques

| Technique | Purpose |
|---|---|
| `JOIN` | Attach category/cocoa/geographic attributes to each transaction |
| `GROUP BY` + Aggregates | Summarize by category, cocoa tier, country, store type |
| `CASE WHEN` | Classify `cocoa_percent` into Low/Medium/High tiers |
| `RANK() OVER (PARTITION BY ...)` | Rank stores by profit within each country |
| `CTE (WITH)` | Define intermediate sets (e.g. bottom 15 stores) for readability |
| Manual Pearson Correlation | Compute discount-vs-volume correlation (`CORR()` not available in MySQL) |
| Generated Columns (`STORED`) | Auto-maintain `profit_margin_pct` and `cocoa_level` |

## 16. Exploratory Data Analysis

- **Overall margin:** 40.00%, computed as `SUM(Profit)/SUM(Revenue)` (revenue-weighted, not a simple average of transaction margins).
- **Baseline:** Revenue $25,238,648.22 / Cost $15,142,996.36 / Profit $10,095,641.91.
- **Transaction-level margin range:** ~29.9%–50.2%, no negative or extreme-outlier transactions.
- **Discount:** company-wide average 5.62%, consistent with prior reporting — confirms cleaning did not distort the distribution.
- **Coverage:** all 200 SKUs and 100 stores active in the period.

## 17. Business Analysis by Question

**BQ1 — Category profitability**

| Category | Revenue | Profit | Margin % | % of Revenue |
|---|---|---|---|---|
| Praline | $6,665,641.32 | $2,665,242.79 | 39.98% | 26.41% |
| White | $6,070,172.20 | $2,428,117.37 | 40.00% | 24.05% |
| Dark | $5,298,123.27 | $2,120,672.08 | 40.03% | 20.99% |
| Truffle | $3,924,343.24 | $1,569,202.54 | 39.99% | 15.55% |
| Milk | $3,280,368.19 | $1,312,407.13 | 40.01% | 13.00% |

**BQ2 — Cocoa tier profitability**

| Cocoa Level | SKUs | Avg Cocoa % | Margin % |
|---|---|---|---|
| Low (<60%) | 51 | 50.00% | 40.00% |
| Medium (60–75%) | 73 | 65.89% | 40.00% |
| High (>75%) | 76 | 85.14% | 40.01% |

**BQ3 — Geographic profitability**

| Country | Stores | Revenue | Profit | Margin % | % of Revenue |
|---|---|---|---|---|---|
| Canada | 20 | $5,036,623.01 | $2,013,945.16 | 39.99% | 19.96% |
| UK | 19 | $4,777,585.16 | $1,911,788.83 | 40.02% | 18.93% |
| USA | 17 | $4,298,447.49 | $1,719,614.31 | 40.01% | 17.03% |
| France | 17 | $4,296,611.25 | $1,718,567.53 | 40.00% | 17.02% |
| Australia | 15 | $3,798,165.48 | $1,519,688.46 | 40.01% | 15.05% |
| Germany | 12 | $3,031,215.83 | $1,212,037.62 | 39.99% | 12.01% |

Top-ranked stores within each country (via `RANK() OVER (PARTITION BY country)`) showed margins of 39.9%–40.4% — in line with the company average, indicating their lead comes from volume rather than margin efficiency.

**BQ4 — Discount effectiveness**

The 15 lowest-profit stores averaged 5.48%–5.81% discount (vs. 5.62% company-wide) — not meaningfully different. Pearson correlation between discount and quantity across 146,914 transactions in these stores: **r = 0.0047**.

## 18. Statistical Analysis — Pearson Correlation

**Method:** Standard Pearson correlation formula, computed manually in SQL using `SUM`, `POW`, and `SQRT`, since MySQL has no built-in `CORR()` function (unlike PostgreSQL).

**Result:** r = 0.0047 (n = 146,914 transactions, restricted to the 15 lowest-profit stores).

**Interpretation:** A coefficient this close to zero indicates no meaningful linear relationship — deeper discounting does not correspond to higher sales volume in these stores. The current discount policy is not functioning as an effective volume lever where it is most needed.

## 19. Store Type Analysis (Supplementary)

Following BQ4, 10 of the 15 lowest-profit stores (67%) were Airport-format — prompting a full population-level test:

| Store Type | Stores | Avg Profit/Store | Coefficient of Variation |
|---|---|---|---|
| Airport | 30 | $100,553.75 | 1.27% |
| Online | 25 | $101,189.11 | 0.99% |
| Retail | 19 | $101,278.48 | 0.96% |
| Mall | 26 | $100,961.95 | 0.83% |

The difference in variability is directionally consistent with the initial pattern but too small (≈0.3–0.4 percentage points) to be considered practically significant — no store type is structurally underperforming.

---

## 20. Key Findings

1. **Margin is highly consistent** across category (39.98–40.03%), cocoa tier (40.00–40.01%), and country (39.99–40.02%) — the Dark Chocolate mispricing hypothesis is not supported.
2. **Discounting is not an effective volume driver** in underperforming stores (r = 0.0047).
3. **Top-performing stores win on volume**, not margin efficiency — their margins are in line with the company average.
4. **No store type is structurally underperforming** — the Airport pattern seen in the bottom-15 sample did not hold at the full-population level.

## 21. Business Recommendations

**Short-term**
- Do not raise Dark Chocolate prices — not supported by data.
- A/B test the discount policy across a sample of stores; current flat rate shows no volume impact.

**Medium-term**
- Shift growth strategy toward volume/traffic, since margin is already near-optimal.
- Conduct a non-data operational audit of bottom-performing stores (lease, staffing, local competition).

**Long-term**
- Strengthen `product_id` validation at the point of transaction entry in the source ERP/POS system.

## 22. Dashboard Detail

**Executive Dashboard** — 5 KPI cards, geographic profitability map, Top 10/Bottom 10 store ranking, with Year/Month/Country slicers.

**Operational Dashboard** — clustered bar chart (revenue vs. cost by category), scatter plot (cocoa % vs. per-product margin, visually confirming BQ2), treemap (revenue by store type).

**Store Deep-Dive (Drill-through)** — transaction-level detail (product, quantity, revenue, profit) accessible by right-clicking any store or country on the other pages.

## 23. Tools & Technologies

| Tool | Role |
|---|---|
| MySQL | Schema design, cleaning, validation, business analysis |
| Power BI | Star Schema modeling, dashboard |
| DAX | Business measures responsive to filters/slicers |
| GitHub | Portfolio hosting and documentation |

## 24. Key Skills Demonstrated

SQL query design · data cleaning & validation · referential integrity auditing · relational schema design · Star Schema modeling · feature engineering · window functions · manual statistical correlation · business analytics · Power BI dashboard design · DAX · data storytelling

## 25. Project Workflow

```
Business Understanding → Data Collection → Data Cleaning → SQL Analysis
→ Feature Engineering → Power BI Modeling → Dashboard
→ Business Insights → Recommendations
```
