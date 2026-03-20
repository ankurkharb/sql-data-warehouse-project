/*
===============================================================================
Sales Analysis
===============================================================================
Script Purpose:
    This script provides analytical queries to deliver detailed insights into 
    sales trends and patterns. These insights empower stakeholders with key 
    business metrics for revenue forecasting and strategic decision-making.

    Analyses Included:
    1. Overall Sales Summary
    2. Monthly Sales Trends
    3. Yearly Sales Performance
    4. Year-over-Year Growth Analysis
    5. Average Order Value Trends
    6. Order Volume & Shipping Analysis
    7. Revenue by Product Line Over Time
    8. Weekday vs Weekend Sales Analysis
===============================================================================
*/

-- ====================================================================
-- 1. Overall Sales Summary (KPIs)
-- Purpose: High-level snapshot of total business performance
-- ====================================================================
SELECT
    COUNT(DISTINCT order_number)     AS total_orders,
    COUNT(DISTINCT customer_key)     AS total_customers,
    COUNT(DISTINCT product_key)      AS total_products_sold,
    SUM(sales_amount)                AS total_revenue,
    SUM(quantity)                     AS total_quantity_sold,
    AVG(sales_amount)                AS avg_order_value,
    AVG(price)                       AS avg_unit_price,
    MIN(order_date)                  AS first_order_date,
    MAX(order_date)                  AS last_order_date
FROM gold.fact_sales;

-- ====================================================================
-- 2. Monthly Sales Trends
-- Purpose: Track revenue and order volume month by month
-- ====================================================================
SELECT
    YEAR(order_date)                 AS sales_year,
    MONTH(order_date)                AS sales_month,
    FORMAT(order_date, 'yyyy-MM')    AS year_month,
    SUM(sales_amount)                AS total_revenue,
    COUNT(DISTINCT order_number)     AS total_orders,
    SUM(quantity)                     AS total_quantity,
    AVG(sales_amount)                AS avg_order_value,
    COUNT(DISTINCT customer_key)     AS unique_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date), FORMAT(order_date, 'yyyy-MM')
ORDER BY sales_year, sales_month;

-- ====================================================================
-- 3. Yearly Sales Performance
-- Purpose: Summarize annual sales metrics for high-level comparison
-- ====================================================================
SELECT
    YEAR(order_date)                 AS sales_year,
    SUM(sales_amount)                AS total_revenue,
    COUNT(DISTINCT order_number)     AS total_orders,
    COUNT(DISTINCT customer_key)     AS total_customers,
    SUM(quantity)                     AS total_quantity,
    AVG(sales_amount)                AS avg_order_value
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY sales_year;

-- ====================================================================
-- 4. Year-over-Year (YoY) Growth Analysis
-- Purpose: Calculate YoY revenue and order growth rates
-- ====================================================================
WITH yearly_sales AS (
    SELECT
        YEAR(order_date)             AS sales_year,
        SUM(sales_amount)            AS total_revenue,
        COUNT(DISTINCT order_number) AS total_orders
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date)
)
SELECT
    sales_year,
    total_revenue,
    total_orders,
    LAG(total_revenue) OVER (ORDER BY sales_year) AS prev_year_revenue,
    LAG(total_orders)  OVER (ORDER BY sales_year) AS prev_year_orders,
    CASE
        WHEN LAG(total_revenue) OVER (ORDER BY sales_year) IS NULL THEN NULL
        ELSE CAST(ROUND(
            (total_revenue - LAG(total_revenue) OVER (ORDER BY sales_year)) * 100.0 
            / NULLIF(LAG(total_revenue) OVER (ORDER BY sales_year), 0), 2
        ) AS DECIMAL(7,2))
    END AS revenue_growth_pct,
    CASE
        WHEN LAG(total_orders) OVER (ORDER BY sales_year) IS NULL THEN NULL
        ELSE CAST(ROUND(
            (total_orders - LAG(total_orders) OVER (ORDER BY sales_year)) * 100.0 
            / NULLIF(LAG(total_orders) OVER (ORDER BY sales_year), 0), 2
        ) AS DECIMAL(7,2))
    END AS orders_growth_pct
FROM yearly_sales
ORDER BY sales_year;

-- ====================================================================
-- 5. Average Order Value (AOV) Trends Over Time
-- Purpose: Monitor how average spend per order changes monthly
-- ====================================================================
SELECT
    FORMAT(order_date, 'yyyy-MM')    AS year_month,
    COUNT(DISTINCT order_number)     AS total_orders,
    SUM(sales_amount)                AS total_revenue,
    AVG(sales_amount)                AS avg_order_value,
    SUM(quantity)                     AS total_quantity,
    CAST(ROUND(
        SUM(sales_amount) * 1.0 / NULLIF(SUM(quantity), 0), 2
    ) AS DECIMAL(10,2))              AS revenue_per_unit
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY year_month;

-- ====================================================================
-- 6. Order Volume & Shipping Analysis
-- Purpose: Analyze shipping performance and order fulfillment
-- ====================================================================
SELECT
    YEAR(order_date)                 AS sales_year,
    MONTH(order_date)                AS sales_month,
    COUNT(DISTINCT order_number)     AS total_orders,
    AVG(DATEDIFF(DAY, order_date, shipping_date))  AS avg_shipping_days,
    AVG(DATEDIFF(DAY, order_date, due_date))       AS avg_due_days,
    MIN(DATEDIFF(DAY, order_date, shipping_date))  AS min_shipping_days,
    MAX(DATEDIFF(DAY, order_date, shipping_date))  AS max_shipping_days
FROM gold.fact_sales
WHERE order_date IS NOT NULL AND shipping_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY sales_year, sales_month;

-- ====================================================================
-- 7. Revenue by Product Line Over Time
-- Purpose: Compare how different product lines perform across periods
-- ====================================================================
SELECT
    FORMAT(f.order_date, 'yyyy-MM')  AS year_month,
    p.product_line,
    SUM(f.sales_amount)              AS total_revenue,
    SUM(f.quantity)                   AS total_quantity,
    COUNT(DISTINCT f.order_number)   AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY FORMAT(f.order_date, 'yyyy-MM'), p.product_line
ORDER BY year_month, total_revenue DESC;

-- ====================================================================
-- 8. Weekday vs Weekend Sales Analysis
-- Purpose: Compare sales patterns between business days and weekends
-- ====================================================================
SELECT
    CASE 
        WHEN DATEPART(WEEKDAY, order_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END                              AS day_type,
    DATENAME(WEEKDAY, order_date)    AS day_name,
    COUNT(DISTINCT order_number)     AS total_orders,
    SUM(sales_amount)                AS total_revenue,
    AVG(sales_amount)                AS avg_order_value,
    SUM(quantity)                     AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
    CASE 
        WHEN DATEPART(WEEKDAY, order_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END,
    DATENAME(WEEKDAY, order_date)
ORDER BY total_revenue DESC;
