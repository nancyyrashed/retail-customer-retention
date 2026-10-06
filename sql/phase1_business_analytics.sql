-- Retail Customer Retention Intelligence
-- Phase 1: SQL Business Analytics


-- =========================================================
-- 1. Monthly Revenue and Customer Activity
-- =========================================================

SELECT
    DATE_TRUNC('month', invoice_date) AS month,
    ROUND(SUM(line_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice) AS invoices,
    COUNT(DISTINCT customer_id) AS active_customers
FROM retail_transactions
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;


-- =========================================================
-- 2. Month-over-Month Revenue Growth
-- =========================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(line_revenue) AS revenue
    FROM retail_transactions
    GROUP BY DATE_TRUNC('month', invoice_date)
),

revenue_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM revenue_growth
ORDER BY month;


-- =========================================================
-- 3. Monthly Average Order Value
-- =========================================================

SELECT
    DATE_TRUNC('month', invoice_date) AS month,
    ROUND(SUM(line_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice) AS invoices,
    ROUND(
        SUM(line_revenue)
        / NULLIF(COUNT(DISTINCT invoice), 0),
        2
    ) AS average_order_value
FROM retail_transactions
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;


-- =========================================================
-- 4. Customer Purchase Frequency
-- =========================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS order_count
    FROM retail_transactions
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE order_count = 1
    ) AS one_time_customers,
    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_count > 1
        ) / COUNT(*),
        2
    ) AS repeat_customer_pct,
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    MAX(order_count) AS max_orders
FROM customer_orders;


-- =========================================================
-- 5. First vs Repeat Purchase Share
-- =========================================================

WITH invoice_level AS (
    SELECT
        customer_id,
        invoice,
        MIN(invoice_date) AS invoice_date
    FROM retail_transactions
    GROUP BY customer_id, invoice
),

ranked_orders AS (
    SELECT
        customer_id,
        invoice,
        invoice_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY invoice_date, invoice
        ) AS order_number
    FROM invoice_level
)

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_number = 1
    ) AS first_orders,
    COUNT(*) FILTER (
        WHERE order_number > 1
    ) AS repeat_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_number > 1
        ) / COUNT(*),
        2
    ) AS repeat_order_pct
FROM ranked_orders;


-- =========================================================
-- 6. Customer Revenue Ranking
-- =========================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(line_revenue) AS revenue
    FROM retail_transactions
    GROUP BY customer_id
),

ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS customer_rank,
        SUM(revenue) OVER (
            ORDER BY revenue DESC
        ) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
)

SELECT
    customer_id,
    customer_rank,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100.0 * customer_rank / total_customers,
        2
    ) AS cumulative_customer_pct,
    ROUND(
        100.0 * cumulative_revenue / total_revenue,
        2
    ) AS cumulative_revenue_pct
FROM ranked_customers
ORDER BY customer_rank
LIMIT 20;


-- =========================================================
-- 7. Revenue Concentration
-- =========================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(line_revenue) AS revenue
    FROM retail_transactions
    GROUP BY customer_id
),

ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS customer_rank,
        COUNT(*) OVER () AS total_customers,
        SUM(revenue) OVER () AS total_revenue
    FROM customer_revenue
)

SELECT
    ROUND(
        100.0 * SUM(revenue) FILTER (
            WHERE customer_rank <= CEIL(total_customers * 0.01)
        ) / MAX(total_revenue),
        2
    ) AS top_1_pct_revenue,

    ROUND(
        100.0 * SUM(revenue) FILTER (
            WHERE customer_rank <= CEIL(total_customers * 0.05)
        ) / MAX(total_revenue),
        2
    ) AS top_5_pct_revenue,

    ROUND(
        100.0 * SUM(revenue) FILTER (
            WHERE customer_rank <= CEIL(total_customers * 0.10)
        ) / MAX(total_revenue),
        2
    ) AS top_10_pct_revenue,

    ROUND(
        100.0 * SUM(revenue) FILTER (
            WHERE customer_rank <= CEIL(total_customers * 0.20)
        ) / MAX(total_revenue),
        2
    ) AS top_20_pct_revenue

FROM ranked_customers;


-- =========================================================
-- 8. Customer Recency Distribution
-- =========================================================

WITH dataset_end AS (
    SELECT
        MAX(invoice_date)::date AS reference_date
    FROM retail_transactions
),

customer_last_purchase AS (
    SELECT
        customer_id,
        MAX(invoice_date)::date AS last_purchase_date
    FROM retail_transactions
    GROUP BY customer_id
),

customer_recency AS (
    SELECT
        c.customer_id,
        c.last_purchase_date,
        d.reference_date,
        d.reference_date - c.last_purchase_date AS recency_days
    FROM customer_last_purchase c
    CROSS JOIN dataset_end d
)

SELECT
    CASE
        WHEN recency_days <= 30 THEN '0-30 days'
        WHEN recency_days <= 60 THEN '31-60 days'
        WHEN recency_days <= 90 THEN '61-90 days'
        WHEN recency_days <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END AS recency_group,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct
FROM customer_recency
GROUP BY
    CASE
        WHEN recency_days <= 30 THEN '0-30 days'
        WHEN recency_days <= 60 THEN '31-60 days'
        WHEN recency_days <= 90 THEN '61-90 days'
        WHEN recency_days <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END
ORDER BY MIN(recency_days);