/*
===============================================================================
Product Analysis
===============================================================================
Script Purpose:
    This script provides analytical queries to deliver detailed insights into 
    product performance. These insights empower stakeholders with key business 
    metrics for inventory, pricing, and strategy decisions.

    Analyses Included:
    1. Top 10 Products by Revenue
    2. Bottom 10 Products by Revenue
    3. Category & Subcategory Performance
    4. Product Line Comparison
    5. Product Cost vs Revenue Margin Analysis
    6. Category Contribution to Total Sales
===============================================================================
*/

-- ====================================================================
-- 1. Top 10 Products by Revenue
-- Purpose: Identify the best performing products
-- ====================================================================
SELECT TOP 10
    p.product_name,
    p.category,
    p.subcategory,
    p.product_line,
    SUM(f.sales_amount)                AS total_revenue,
    SUM(f.quantity)                     AS total_quantity_sold,
    COUNT(DISTINCT f.order_number)     AS total_orders,
    AVG(f.price)                       AS avg_selling_price
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY 
    p.product_name, p.category,
    p.subcategory, p.product_line
ORDER BY total_revenue DESC;

-- ====================================================================
-- 2. Bottom 10 Products by Revenue (with at least 1 sale)
-- Purpose: Find underperforming products for review
-- ====================================================================
SELECT TOP 10
    p.product_name,
    p.category,
    p.subcategory,
    p.product_line,
    SUM(f.sales_amount)                AS total_revenue,
    SUM(f.quantity)                     AS total_quantity_sold,
    COUNT(DISTINCT f.order_number)     AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY 
    p.product_name, p.category,
    p.subcategory, p.product_line
HAVING SUM(f.sales_amount) > 0
ORDER BY total_revenue ASC;

-- ====================================================================
-- 3. Category & Subcategory Performance
-- Purpose: Break down sales by product hierarchy
-- ====================================================================
SELECT
    p.category,
    p.subcategory,
    COUNT(DISTINCT p.product_key)      AS total_products,
    SUM(f.sales_amount)                AS total_revenue,
    SUM(f.quantity)                     AS total_quantity_sold,
    COUNT(DISTINCT f.order_number)     AS total_orders,
    AVG(f.price)                       AS avg_price,
    AVG(f.sales_amount)                AS avg_order_value
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory
ORDER BY total_revenue DESC;

-- ====================================================================
-- 4. Product Line Performance Comparison
-- Purpose: Compare Mountain, Road, Touring, and Other Sales lines
-- ====================================================================
SELECT
    p.product_line,
    COUNT(DISTINCT p.product_key)      AS total_products,
    SUM(f.sales_amount)                AS total_revenue,
    SUM(f.quantity)                     AS total_quantity_sold,
    COUNT(DISTINCT f.order_number)     AS total_orders,
    AVG(f.price)                       AS avg_selling_price,
    CAST(ROUND(
        SUM(f.sales_amount) * 100.0 / SUM(SUM(f.sales_amount)) OVER (), 2
    ) AS DECIMAL(5,2))                 AS revenue_percentage
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.product_line
ORDER BY total_revenue DESC;

-- ====================================================================
-- 5. Product Cost vs Revenue Margin Analysis
-- Purpose: Evaluate profitability by comparing cost to selling price
-- ====================================================================
SELECT
    p.product_name,
    p.category,
    p.product_line,
    p.cost,
    AVG(f.price)                                    AS avg_selling_price,
    AVG(f.price) - p.cost                           AS avg_profit_per_unit,
    CASE
        WHEN p.cost = 0 THEN NULL
        ELSE CAST(ROUND(
            (AVG(f.price) - p.cost) * 100.0 / NULLIF(p.cost, 0), 2
        ) AS DECIMAL(7,2))
    END                                             AS margin_percentage,
    SUM(f.quantity)                                  AS total_quantity_sold,
    SUM(f.sales_amount) - (p.cost * SUM(f.quantity)) AS total_profit
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.cost > 0
GROUP BY 
    p.product_name, p.category,
    p.product_line, p.cost
ORDER BY total_profit DESC;

-- ====================================================================
-- 6. Category Contribution to Total Sales
-- Purpose: Understand which categories drive the most revenue
-- ====================================================================
SELECT
    p.category,
    SUM(f.sales_amount)                AS total_revenue,
    SUM(f.quantity)                     AS total_quantity,
    COUNT(DISTINCT f.order_number)     AS total_orders,
    COUNT(DISTINCT p.product_key)      AS total_products,
    CAST(ROUND(
        SUM(f.sales_amount) * 100.0 / SUM(SUM(f.sales_amount)) OVER (), 2
    ) AS DECIMAL(5,2))                 AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS revenue_rank
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
