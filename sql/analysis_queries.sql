
-- Query 1: Average review score by delivery status
SELECT
    CASE
        WHEN julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date) > 0 THEN 'Late'
        WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        ELSE 'On-time/Early'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(*) AS num_orders
FROM orders o
LEFT JOIN reviews r ON o.order_id = r.order_id
GROUP BY delivery_status
ORDER BY avg_review_score DESC;

-- Query 2: Total revenue by state (top 10)
SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS num_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 3: Top-selling product category per state (using RANK window function)
WITH category_revenue AS (
    SELECT
        c.customer_state,
        t.product_category_name_english,
        SUM(oi.price) AS revenue,
        RANK() OVER (PARTITION BY c.customer_state ORDER BY SUM(oi.price) DESC) AS rank_in_state
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN translation t ON p.product_category_name = t.product_category_name
    GROUP BY c.customer_state, t.product_category_name_english
)
SELECT * FROM category_revenue WHERE rank_in_state = 1 ORDER BY revenue DESC LIMIT 10;
