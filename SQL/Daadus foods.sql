CREATE DATABASE daadus_foods;
USE daadus_foods;
show tables;
SELECT * FROM fact_orders LIMIT 10;

-- joining ordres table and products table
SELECT
    o.order_id,
    o.order_date,
    p.product_name,
    o.gross_amount
FROM fact_orders o
JOIN dim_products p
ON o.product_id = p.product_id
LIMIT 20;

-- Total orders, Total customers, Revenue generated
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(gross_amount) AS revenue
FROM fact_orders;

-- Top selling products
SELECT
    p.product_name,
    SUM(o.quantity) AS units_sold
FROM fact_orders o
JOIN dim_products p
ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC;  
-- Baked Mathri products contributed the majority of unit sales, suggesting stronger consumer demand for
-- snack products compared to specialty products such as Mango Chutney.

-- Revenue by product
SELECT
    p.product_name,
    SUM(o.gross_amount) AS revenue
FROM fact_orders o
JOIN dim_products p
ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;

-- Which platform generated most revenue
SELECT
    platform,
    SUM(gross_amount) AS revenue
FROM fact_orders
GROUP BY platform
ORDER BY revenue DESC;
-- Amazon contributed the highest share of revenue, indicating strong marketplace visibility.

-- Customer geography
SELECT
    city,
    COUNT(*) AS orders
FROM fact_orders
GROUP BY city
ORDER BY orders DESC;
-- Delhi NCR cities accounted for the majority of online orders

-- Profitability analysis
SELECT
    platform,
    SUM(gross_amount)
    - SUM(discount_amount)
    - SUM(shipping_cost)
    - SUM(platform_commission)
    - SUM(product_cost)
    AS estimated_profit
FROM fact_orders
GROUP BY platform;
-- Amazon generated the highest revenue among online channels due to greater marketplace reach
-- However, marketplace commissions must be considered before evaluating platform performance.
-- Despite generating revenue, profitability was negatively impacted by shipping costs, marketplace commissions 
-- discounts, and product costs

-- AOV (Average order value)  
SELECT
    ROUND(AVG(gross_amount),2) AS avg_order_value
FROM fact_orders; 
--  The average order value remained below ₹500. Since orders below ₹400 incurred shipping charges

-- COD analysis 
SELECT
    payment_method,
    COUNT(*) AS orders
FROM fact_orders
GROUP BY payment_method;
SELECT
    return_reason,
    COUNT(*) AS total_returns
FROM fact_returns
GROUP BY return_reason
ORDER BY total_returns DESC; 

-- Repeat customer analysis
SELECT
    customer_id,
    COUNT(*) AS orders
FROM fact_orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY orders DESC;

-- Online vs Offline
SELECT
    SUM(gross_amount) AS online_revenue
FROM fact_orders;
SELECT
    SUM(revenue) AS offline_revenue
FROM fact_offline_sales;

-- Which products generated the highest profit contribution 
SELECT
    p.product_name,
    SUM(
        o.gross_amount
        - o.discount_amount
        - o.shipping_cost
        - o.platform_commission
        - o.product_cost
    ) AS estimated_profit
FROM fact_orders o
JOIN dim_products p
ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY estimated_profit DESC;

-- Which online channel generated the highest profit
SELECT
    platform,
    SUM(
        gross_amount
        - discount_amount
        - shipping_cost
        - platform_commission
        - product_cost
    ) AS estimated_profit
FROM fact_orders
GROUP BY platform
ORDER BY estimated_profit DESC;
-- Website orders may contribute better profitability due to zero marketplace commissions, 
-- while Amazon and Flipkart revenue is reduced by commission and fulfillment costs.

-- Repeat customer percentage
SELECT
ROUND(
(
COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END)
*100.0
/
COUNT(DISTINCT customer_id)
),2) AS repeat_customer_pct
FROM
(
SELECT
customer_id,
COUNT(*) AS order_count
FROM fact_orders
GROUP BY customer_id
) t;
-- Product acceptance existed; unit economics were the bigger issue.

-- Monthly Revenue Trend
SELECT
DATE_FORMAT(order_date,'%Y-%m') AS month,
SUM(gross_amount) AS revenue
FROM fact_orders
GROUP BY month
ORDER BY month; 

-- Customer acquisition cost (CAC)
SELECT
DATE_FORMAT(campaign_date,'%Y-%m') AS month,
SUM(ad_spend) AS spend,
SUM(conversions) AS conversions,
ROUND(
SUM(ad_spend)/NULLIF(SUM(conversions),0),
2
) AS CAC
FROM fact_marketing
GROUP BY month
ORDER BY month; 

-- Which Meta campaign generated the best conversion rate
SELECT
campaign_name,
SUM(ad_spend) AS total_spend,
SUM(conversions) AS conversions,
ROUND(
SUM(conversions)*100.0/
SUM(clicks),
2
) AS conversion_rate
FROM fact_marketing
GROUP BY campaign_name
ORDER BY conversion_rate DESC; 

-- Return Analysis
SELECT
return_reason,
COUNT(*) AS returns_count
FROM fact_returns
GROUP BY return_reason
ORDER BY returns_count DESC; 
-- COD rejection emerged as the largest source of returns, highlighting one of the operational challenges 
-- of e-commerce.

-- Revenue by city
SELECT
city,
SUM(gross_amount) AS revenue
FROM fact_orders
GROUP BY city
ORDER BY revenue DESC; 
-- Delhi NCR contributed the largest share of revenue

--  Offline vs online profitability 
SELECT
'Online' AS channel,
SUM(
gross_amount
-discount_amount
-shipping_cost
-platform_commission
-product_cost
) AS estimated_profit
FROM fact_orders

UNION ALL

SELECT
'Offline',
SUM(
revenue*(profit_margin_pct/100)
)
FROM fact_offline_sales; 
-- While online channels generated higher visibility and broader customer reach, offline retail produced
-- healthier profit margins due to lower logistics costs, zero marketplace commissions, and no customer 
-- acquisition expenses.

-- Daadus Foods achieved customer acceptance and revenue growth, but e-commerce profitability remained constrained
-- by high acquisition costs, shipping expenses, platform commissions, and low average order values. 
-- Offline retail proved to be a more sustainable and profitable channel.

-- Customer segmentation
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    SUM(o.gross_amount) AS total_spent,
    COUNT(o.order_id) AS total_orders,
    CASE
        WHEN SUM(o.gross_amount) >= 1000 THEN 'High Value'
        WHEN SUM(o.gross_amount) >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM fact_orders o
JOIN dim_customers c
ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city
ORDER BY total_spent DESC;
-- A relatively small segment of customers contributes a disproportionately large share of revenue, 
-- indicating an opportunity to focus retention efforts on high value customers.

-- Customer Lifetime Value (CLV) 
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_amount) AS lifetime_revenue,
    ROUND(
        SUM(o.gross_amount) / COUNT(o.order_id),
        2
    ) AS avg_order_value
FROM fact_orders o
JOIN dim_customers c
ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY lifetime_revenue DESC; 
-- The highest-value customers generated multiple purchases over time, proving that repeat customers 
-- were critical to overall revenue generation.

-- Ranking customers based on total spending 
SELECT
    customer_id,
    total_spent,
    RANK() OVER(
        ORDER BY total_spent DESC
    ) AS spending_rank
FROM
(
    SELECT
        customer_id,
        SUM(gross_amount) AS total_spent
    FROM fact_orders
    GROUP BY customer_id
) t;

-- Top 10 Customers
SELECT *
FROM
(
    SELECT
        c.customer_name,
        SUM(o.gross_amount) AS revenue,
        DENSE_RANK() OVER(
            ORDER BY SUM(o.gross_amount) DESC
        ) AS customer_rank
    FROM fact_orders o
    JOIN dim_customers c
    ON o.customer_id = c.customer_id
    GROUP BY c.customer_name
) t
WHERE customer_rank <= 10;
-- The top 10 customers generated significantly higher revenue than the average customer, 
-- indicating a strong concentration of purchasing activity.

-- RFM ANALYSIS  Recency, Frequency, Monetary
SELECT
    customer_id,
    MAX(order_date) AS last_purchase,
    COUNT(order_id) AS frequency,
    SUM(gross_amount) AS monetary_value
FROM fact_orders
GROUP BY customer_id;
-- Customers with recent purchases, high frequency, and high spending represent the brand's most valuable 
-- customer segment  

-- Advanced RFM segmentation 
WITH customer_rfm AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_purchase,
        COUNT(order_id) AS frequency,
        SUM(gross_amount) AS monetary
    FROM fact_orders
    GROUP BY customer_id
)

SELECT
    customer_id,
    frequency,
    monetary,
    CASE
        WHEN frequency >= 3 AND monetary >= 1000
        THEN 'Ultra Loyal Customers'

        WHEN frequency >= 2
        THEN 'Loyal Customers'

        ELSE 'Occasional Customers'
    END AS customer_group
FROM customer_rfm;
-- The customer base consisted primarily of occasional buyers, while a smaller group of loyal customers and 
-- ultra loyal customers contributed a substantial share of revenue.

-- Monthly customer growth
SELECT
    DATE_FORMAT(order_date,'%Y-%m') AS month,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM fact_orders
GROUP BY month
ORDER BY month;


-- How much revenue is being consumed by shipping
SELECT
    ROUND(
        SUM(shipping_cost) * 100.0 /
        SUM(gross_amount),
        2
    ) AS shipping_cost_pct
FROM fact_orders;
