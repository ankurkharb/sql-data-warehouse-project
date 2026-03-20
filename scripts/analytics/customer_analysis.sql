/*
===============================================================================
Customer Analysis
===============================================================================
Script Purpose:
    This script provides analytical queries to deliver detailed insights into 
    customer behavior and demographics. These insights empower stakeholders 
    with key business metrics for strategic decision-making.

    Analyses Included:
    1. Customer Demographics Breakdown
    2. Customer Acquisition Trends
    3. Top 10 Customers by Revenue
    4. Customer Lifetime Value (CLV)
    5. Customer Segmentation by Age Group
===============================================================================
*/

-- ====================================================================
-- 1. Customer Demographics: Gender & Marital Status Distribution
-- Purpose: Understand the composition of the customer base
-- ====================================================================
SELECT
    gender,
    marital_status,
    COUNT(customer_key)    AS total_customers,
    CAST(ROUND(
        COUNT(customer_key) * 100.0 / SUM(COUNT(customer_key)) OVER (), 2
    ) AS DECIMAL(5,2))     AS percentage
FROM gold.dim_customers
GROUP BY gender, marital_status
ORDER BY total_customers DESC;

-- ====================================================================
-- 2. Customer Distribution by Country
-- Purpose: Identify geographic concentration of customers
-- ====================================================================
SELECT
    country,
    COUNT(customer_key)    AS total_customers,
    CAST(ROUND(
        COUNT(customer_key) * 100.0 / SUM(COUNT(customer_key)) OVER (), 2
    ) AS DECIMAL(5,2))     AS percentage
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- ====================================================================
-- 3. Customer Acquisition Trends (Monthly)
-- Purpose: Track how many new customers are acquired over time
-- ====================================================================
SELECT
    YEAR(create_date)      AS acquisition_year,
    MONTH(create_date)     AS acquisition_month,
    COUNT(customer_key)    AS new_customers,
    SUM(COUNT(customer_key)) OVER (
        ORDER BY YEAR(create_date), MONTH(create_date)
    )                      AS cumulative_customers
FROM gold.dim_customers
WHERE create_date IS NOT NULL
GROUP BY YEAR(create_date), MONTH(create_date)
ORDER BY acquisition_year, acquisition_month;

-- ====================================================================
-- 4. Top 10 Customers by Total Revenue
-- Purpose: Identify the highest-value customers
-- ====================================================================
SELECT TOP 10
    c.customer_key,
    c.customer_number,
    c.first_name,
    c.last_name,
    c.country,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.sales_amount)            AS total_revenue,
    SUM(f.quantity)                 AS total_quantity,
    AVG(f.sales_amount)            AS avg_order_value,
    MIN(f.order_date)              AS first_order_date,
    MAX(f.order_date)              AS last_order_date
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY 
    c.customer_key, c.customer_number,
    c.first_name, c.last_name, c.country
ORDER BY total_revenue DESC;

-- ====================================================================
-- 5. Customer Lifetime Value (CLV) Summary
-- Purpose: Measure overall value each customer brings
-- ====================================================================
WITH customer_clv AS (
    SELECT
        c.customer_key,
        c.customer_number,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT f.order_number) AS total_orders,
        SUM(f.sales_amount)            AS total_revenue,
        AVG(f.sales_amount)            AS avg_order_value,
        MIN(f.order_date)              AS first_order,
        MAX(f.order_date)              AS last_order,
        DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY 
        c.customer_key, c.customer_number,
        c.first_name, c.last_name
)
SELECT
    customer_key,
    customer_number,
    first_name,
    last_name,
    total_orders,
    total_revenue,
    avg_order_value,
    lifespan_months,
    -- Segment customers based on revenue
    CASE
        WHEN total_revenue >= 50000 THEN 'High Value'
        WHEN total_revenue >= 10000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_clv
ORDER BY total_revenue DESC;

-- ====================================================================
-- 6. Customer Age Group Segmentation
-- Purpose: Analyze purchasing behavior by age group
-- ====================================================================
WITH customer_age AS (
    SELECT
        c.customer_key,
        c.birthdate,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age,
        CASE
            WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) < 25 THEN '18-24'
            WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) BETWEEN 25 AND 34 THEN '25-34'
            WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) BETWEEN 35 AND 44 THEN '35-44'
            WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) BETWEEN 45 AND 54 THEN '45-54'
            WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) >= 55 THEN '55+'
            ELSE 'Unknown'
        END AS age_group
    FROM gold.dim_customers c
    WHERE c.birthdate IS NOT NULL
)
SELECT
    ca.age_group,
    COUNT(DISTINCT ca.customer_key)    AS total_customers,
    SUM(f.sales_amount)                AS total_revenue,
    AVG(f.sales_amount)                AS avg_order_value,
    COUNT(DISTINCT f.order_number)     AS total_orders
FROM customer_age ca
LEFT JOIN gold.fact_sales f
    ON ca.customer_key = f.customer_key
GROUP BY ca.age_group
ORDER BY total_revenue DESC;
