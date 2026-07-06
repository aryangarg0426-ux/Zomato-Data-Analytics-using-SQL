-- EXPLORATORY DATA ANALYSIS

SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;


--Importing the data
--Importing data complete

--Checking for & handling null values in all tables.

SELECT COUNT(*) FROM customers
WHERE customer_name IS NULL OR reg_date IS NULL;
--No null values in customers table.

SELECT COUNT(*) FROM restaurants
WHERE restaurant_name IS NULL OR city IS NULL OR opening_hours IS NULL;
--No NULL values in restaurants table.

SELECT COUNT(*) FROM orders
WHERE customer_id IS NULL OR restaurant_id IS NULL OR order_item IS NULL OR order_date IS NULL OR order_time IS NULL OR order_status IS NULL or total_amount IS NULL;
--No NULL values in orders table.

SELECT COUNT(*) FROM riders
WHERE rider_id IS NULL OR rider_name IS NULL OR sign_up IS NULL;
--No NULL values in riders table.

SELECT 'Total Rows' AS type, COUNT(*) AS count FROM deliveries
UNION ALL
SELECT 'Null Delivery Time', COUNT(*) FROM deliveries WHERE delivery_time IS NULL
UNION ALL
SELECT 'Not Null Delivery Time', COUNT(*) FROM deliveries WHERE delivery_time IS NOT NULL;
-- 797/9750 rows contain null values.

SELECT * FROM deliveries WHERE delivery_time IS NULL AND delivery_status='Delivered';

SELECT delivery_status, COUNT(*) AS null_count
FROM deliveries
WHERE delivery_time IS NULL
GROUP BY delivery_status
ORDER BY null_count DESC;
--All those null values arise from orders which have not been delivered or from a weird delivery_status:Order. 
--So, I will keep these null values for now.










-------------------------------------------------------------------
--Business Analysis : Problems and Insights
-------------------------------------------------------------------









-- (A) Customer Behavior and Retention
-- 1. How many customers are new, regular and loyal?
SELECT customer_type, COUNT(*) AS num_customers
FROM (
  SELECT 
  c.customer_id,
  COUNT(o.order_id) AS total_orders,
  CASE 
    WHEN COUNT(o.order_id) = 0 THEN 'Inactive'
    WHEN COUNT(o.order_id) = 1 THEN 'New'
    WHEN COUNT(o.order_id) > 1 AND COUNT(o.order_id) < 5 THEN 'Regular'
    ELSE 'Loyal'
  END AS customer_type
  FROM customers c
  LEFT JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id
) AS customer_segments
GROUP BY customer_type;
-- 91.6% of active customers (22 out of 24) are loyal, having placed 5 or more orders. This indicates strong customer satisfaction.
-- Only 2 users are in the New and Regular segments combined suggesting that new users are not transitioning into loyal repeat users, a sign of poor early-stage retention.
-- 27% of all registered users (9 out of 33) have never placed an order pointing to a major onboarding and conversion gap.


-- 2. How many customers have not ordered since the past thirty days?
SELECT 
  c.customer_id,
  MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING 
  MAX(o.order_date) IS NULL
  OR MAX(o.order_date) < (SELECT MAX(order_date) FROM orders) - INTERVAL '30 days';
-- Only 2 out of 24 active customers (≈8.3%) haven’t placed an order in the last 30 days.
--This suggests that 91.7% of active users are still regularly engaged, indicating strong short-term retention.


-- 3. Which customers order most frequently (Top 10) and the top food items ordered by the top three customers?
SELECT 
  c.customer_id,
  c.customer_name,
  COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC
LIMIT 10;
-- The top 3 customers — Snehal Desai, Rahul Verma, and Aman Gupta — have each placed 700–800+ orders, indicating very high loyalty and engagement.
--These high-frequency users likely contribute significantly to total revenue and should be considered for exclusive offers or loyalty perks.
--The most popular food items ordered by the top three customers:
WITH top_3cte AS (
  SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id, c.customer_name
  HAVING COUNT(o.order_id) >= 772
)
SELECT 
  c.customer_id, 
  c.customer_name,
  o.order_item,
  COUNT(o.order_item) AS count_of_orders
FROM top_3cte c  
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, o.order_item
ORDER BY count_of_orders DESC;
-- Among the top 3 most frequent customers (each with 772+ orders), the most ordered food items were: Mutton Biryani, Masala Dosa and Mutton Rogan Josh.
--These results highlight a strong preference for non-vegetarian dishes, especially rich Indian meals.
--Recommendation: Leverage this strength by:
--Promoting best-selling non-veg items in loyalty and upsell campaigns
--Personalizing offers for loyal users who favor these categories


--4. The top 5 food items ordered by the top customer: Sneha Desai
SELECT 
  c.customer_id,
  c.customer_name,
  o.order_item as dishes,
  COUNT(o.order_item) AS count_of_orders
FROM customers c
JOIN orders o
  ON c.customer_id = o.customer_id
WHERE c.customer_name = 'Sneha Desai'
GROUP BY c.customer_id, c.customer_name, o.order_item
ORDER BY count_of_orders DESC
LIMIT 5;
-- Analysis of the order data indicates that the top ordered food items are largely non-vegetarian, reflecting a preference for non-vegetarian dishes.


























-- (B). Identify the most popular time slots where most orders are placed. (2 hour intervals) 
SELECT 
  CASE 
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '12am to 2am'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '2am to 4am'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '4am to 6am'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '6am to 8am'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '8am to 10am'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10am to 12pm'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12pm to 2pm'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '2pm to 4pm'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '4pm to 6pm'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '6pm to 8pm'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '8pm to 10pm'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '10pm to 12am'
    ELSE 'Unknown'
  END AS time_slot,
  COUNT(*) AS count_of_orders
FROM orders
GROUP BY time_slot
ORDER BY count_of_orders DESC;
--Zomato can consider offering targeted discounts or delivery incentives during low-traffic hours (12am to 2am) to boost off-peak engagement. 
--Meanwhile, it can ensure maximum delivery partner availability during peak windows(2pm to 8pm) to maintain service speed and quality.





















-- (C) ORDER VALUE ANALYSIS 
-- 1.Find average order value per customer > 750 orders.
WITH count_more_than_750 as
(
SELECT 
  c.customer_id,
  c.customer_name,
  count(o.order_item) as count_of_orders
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING count(o.order_item) > 750
ORDER BY count(o.order_item) DESC
)
SELECT 
  c.customer_id,
  c.customer_name,
  ROUND(AVG(o.total_amount)::numeric, 2) as average_order_value
FROM count_more_than_750 c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY average_order_value DESC;
--8 customers have placed over 500 orders each with average order value between 310 rupees and 340 rupees. 
--The small variation in average order value implies that current pricing strategies are well-accepted by loyal users. There is low price sensitivity in this segment.

-- 2. List the customer who spend > 100K in total on food order
SELECT 
  o.customer_id,
  c.customer_name,
  sum(o.total_amount) as total_amount_spent
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
HAVING sum(o.total_amount) > 100000
ORDER BY sum(o.total_amount) DESC;
-- A total of 14 customers have spent over ₹100,000 each on the platform, making them part of a high-value user segment. These users represent a significant share of total revenue.
-- The top three are likely to have high lifetime value (LTV) and should be considered for premium-tier loyalty programs, personalized offers, or early access to new features and campaigns.















-- (D). ORDERS WIHTOUT DELIVERY
-- 1. Orders that were placed but no delivered..
SELECT 
  COUNT(order_id)
FROM deliveries
WHERE delivery_status <> 'Delivered'
-- 1 in every 12 orders has failed — this is not negligible.

-- 2. Number of riders who failed to deliver.
SELECT 
  r.rider_id,
  r.rider_name,
  COUNT(*) FILTER (WHERE d.delivery_status <> 'Delivered') AS not_delivered
FROM riders r
LEFT JOIN deliveries d ON r.rider_id = d.rider_id
GROUP BY r.rider_id, r.rider_name
ORDER BY not_delivered DESC;
-- Manoj Tiwari, Sunil Yadav and Sandeep Rao have the most undelivered order.


-- 3.Which restaurants, most orders undelivered?

SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM deliveries;
-- YES! There are unique delivery IDs and unique order IDs in deliveries table.

WITH delivery_restaurant_combined AS
(
SELECT d.delivery_id, o.restaurant_id, d.delivery_status
FROM deliveries d
LEFT JOIN orders o
ON d.order_id = o.order_id
)
SELECT 
  c.restaurant_id, 
  r.restaurant_name, 
  r.city, 
  COUNT(c.delivery_status) FILTER (WHERE c.delivery_status <> 'Delivered') AS not_delivered
FROM delivery_restaurant_combined c
LEFT JOIN restaurants r
ON c.restaurant_id = r.restaurant_id
GROUP BY c.restaurant_id, r.restaurant_name, r.city
HAVING COUNT(c.delivery_status) FILTER (WHERE c.delivery_status <> 'Delivered') > 20
ORDER BY COUNT(c.delivery_status) FILTER (WHERE c.delivery_status <> 'Delivered') DESC;
-- The highest number of undelivered orders are concentrated in Mumbai, particularly from restaurants like Mahesh Lunch Home (45), Gajalee (44), and Bademiya (41).





















-- (E)REVENUE ANALYSIS
-- 1.Rank restaurants by total revenue
SELECT 
  r.restaurant_id,
  r.restaurant_name,
  r.city,
  COALESCE(SUM(o.total_amount), 0) AS total_revenue,
  DENSE_RANK() OVER (ORDER BY COALESCE(SUM(o.total_amount), 0) DESC) AS rank_of_revenue
FROM restaurants r
LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY total_revenue DESC;
-- Top three highest revenue generating restaurants are located in Mumbai, suggesting that this city is a high-value market for the platform.

-- 2. City wise ranking of restaurants by total revenue.
SELECT 
  r.restaurant_id,
  r.restaurant_name,
  r.city,
  COALESCE(SUM(o.total_amount), 0) AS total_revenue,
  DENSE_RANK() OVER (
    PARTITION BY r.city
    ORDER BY COALESCE(SUM(o.total_amount), 0) DESC
  ) AS rank_in_city
FROM restaurants r
LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY total_revenue DESC;

-- 3. Total Revenue by City.
SELECT 
  r.city, 
  ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue
FROM 
  orders o
JOIN 
  restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY 
  r.city
ORDER BY 
  total_revenue DESC;
-- Mumbai generates the highest total revenue among all cities, indicating a strong customer base and high order volume or value.
-- Bengaluru ranks second, suggesting another market with significant food delivery activity.
-- Delhi follows in third place.

















--  (F)FOOD ITEM POPULAIRTY
-- 1.Identify the most popular dish by city (based on total number of order
SELECT 
  r.city,
  o.order_item,
  COUNT(o.order_item) AS count_of_order_items,
  DENSE_RANK() OVER (
    PARTITION BY r.city 
    ORDER BY COUNT(o.order_item) DESC
  ) AS rank_of_order_items
FROM orders o
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city, o.order_item
----
WITH dish_ranked AS (
  SELECT 
    r.city,
    o.order_item,
    COUNT(o.order_item) AS count_of_order_items,
    DENSE_RANK() OVER (
      PARTITION BY r.city 
      ORDER BY COUNT(o.order_item) DESC
    ) AS rank_of_order_items
  FROM orders o
  LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
  GROUP BY r.city, o.order_item
)
SELECT 
  city,
  order_item,
  count_of_order_items
FROM dish_ranked
WHERE rank_of_order_items = 1
ORDER BY count_of_order_items DESC;
--Across all cities, protein-rich dishes dominate the top spot in order counts.
--In South Indian cities (e.g., Chennai, Bangalore, Hyderabad), the most popular dishes are predominantly non-vegetarian.
--In contrast, Delhi & Mumbai show a strong preference for the vegetarian protein dish: Paneer Butter Masala.





















--(G) Customer Churn 
-- It refers to the percentage of customers who stop using a product or service during a specific period.
-- 1.Find customers who placed orders in 2023 but not in 2024.
WITH customers_2023 AS (
  SELECT DISTINCT o.customer_id, c.customer_name
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE EXTRACT(YEAR FROM o.order_date) = 2023
),
customers_2024 AS (
  SELECT DISTINCT customer_id
  FROM orders
  WHERE EXTRACT(YEAR FROM order_date) = 2024
)
SELECT c23.customer_id, c23.customer_name
FROM customers_2023 c23
LEFT JOIN customers_2024 c24
  ON c23.customer_id = c24.customer_id
WHERE c24.customer_id IS NULL;

-- 9/33 customers
-- This level of churn is notable and indicates that nearly 1 in 3 users are not finding enough value to continue ordering.
-- Given the high loyalty and order frequency of retained users, each churned user represents a direct loss of repeat revenue potential.




















-- (H) Cancellation Rate Comparison 
--1.  Calculate and compare the order cancellation rate for each restaurant between 2024 and 2023.
SELECT MAX(order_date)
FROM orders
-- Data til 25/01/2024 is present in this database.

SELECT 
  restaurant_id, COUNT(order_id) as count_of_total_order
FROM orders
WHERE EXTRACT(YEAR FROM order_date)=2024
GROUP BY restaurant_id
ORDER BY restaurant_id;

SELECT 
  o.restaurant_id, COUNT(o.order_id) as count_of_delivered_total_orders
FROM orders o
LEFT JOIN deliveries d
ON o.order_id = d.order_id
WHERE d.delivery_status='Delivered' AND EXTRACT(YEAR FROM order_date)=2023
GROUP BY  o.restaurant_id
ORDER BY o.restaurant_id;

-- Cancellation Rate 2023
WITH all_data_23 AS (
  SELECT 
    restaurant_id, 
    COUNT(order_id) AS count_of_total_orders
  FROM orders
  WHERE EXTRACT(YEAR FROM order_date) = 2023
  GROUP BY restaurant_id
),
delivered_data_23 AS (
  SELECT 
    o.restaurant_id, 
    COUNT(o.order_id) AS count_of_delivered_total_orders
  FROM orders o
  LEFT JOIN deliveries d ON o.order_id = d.order_id
  WHERE d.delivery_status = 'Delivered' 
    AND EXTRACT(YEAR FROM o.order_date) = 2023
  GROUP BY o.restaurant_id
)

SELECT 
  a.restaurant_id,
  ROUND(100 - (d.count_of_delivered_total_orders * 1.0 / a.count_of_total_orders * 100), 2) AS cancellation_rate
FROM all_data_23 a
JOIN delivered_data_23 d ON a.restaurant_id = d.restaurant_id
ORDER BY cancellation_rate DESC ;

--Cancellation Rate 2024
WITH all_data_24 AS (
  SELECT 
    restaurant_id, 
    COUNT(order_id) AS count_of_total_orders
  FROM orders
  WHERE EXTRACT(YEAR FROM order_date) = 2024
  GROUP BY restaurant_id
),
delivered_data_24 AS (
  SELECT 
    o.restaurant_id, 
    COUNT(o.order_id) AS count_of_delivered_total_orders
  FROM orders o
  LEFT JOIN deliveries d ON o.order_id = d.order_id
  WHERE d.delivery_status = 'Delivered' 
    AND EXTRACT(YEAR FROM o.order_date) = 2024
  GROUP BY o.restaurant_id
)

SELECT 
  a.restaurant_id,
  ROUND(100 - (d.count_of_delivered_total_orders * 1.0 / a.count_of_total_orders * 100), 2) AS avg_cancellation_rate
FROM all_data_24 a
JOIN delivered_data_24 d ON a.restaurant_id = d.restaurant_id
ORDER BY a.restaurant_id;

-- The top 5 restaurants by total orders in 2023 showed an average cancellation rate of ~15%, well above the platform-wide average of ~7–11%.
--So far in 2024, the platform shows a 100% delivery success rate — i.e., no cancellations recorded. 















-- (I)Average delivery time per rider
SELECT 
  d.rider_id, 
  ROUND(AVG(
    EXTRACT(EPOCH FROM (
      d.delivery_time - o.order_time 
      + CASE 
          WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' 
          ELSE INTERVAL '0 day' 
        END
    ))/60),
    2
  ) AS avg_time_difference_in_minutes
FROM orders o
JOIN deliveries d ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY d.rider_id
ORDER BY d.rider_id;

-- Among the 15 riders analyzed, the top 4 have an average delivery time of ~50 minutes, which is ~50% higher than the rest (33–34 minutes).















--(J)Monthly Restaurant Growth Ratio
-- 1. Calculate each restaurant's growth ratio based on the total number of delivered orders since joining.
WITH monthly_deliveries AS (
  SELECT 
    o.restaurant_id,
    DATE_TRUNC('month', o.order_date) AS month_date,
    COUNT(o.order_id) AS count_of_delivered_orders
  FROM orders o
  JOIN deliveries d ON o.order_id = d.order_id
  WHERE d.delivery_status = 'Delivered'
  GROUP BY o.restaurant_id, DATE_TRUNC('month', o.order_date)
)

SELECT 
  restaurant_id,
  TO_CHAR(month_date, 'MM-YYYY') AS month_name,
  count_of_delivered_orders,
  LAG(count_of_delivered_orders) OVER (
    PARTITION BY restaurant_id 
    ORDER BY month_date
  ) AS previous_month_orders,
  
  ROUND(
    (count_of_delivered_orders * 1.0 / NULLIF(LAG(count_of_delivered_orders) OVER (
      PARTITION BY restaurant_id 
      ORDER BY month_date
    ), 0)) - 1,
    2
  ) AS growth_ratio

FROM monthly_deliveries
ORDER BY restaurant_id, month_date;


-- 2.Average growth ratio
WITH monthly_deliveries AS (
  SELECT 
    o.restaurant_id,
    DATE_TRUNC('month', o.order_date) AS month_date,
    COUNT(o.order_id) AS count_of_delivered_orders
  FROM orders o
  JOIN deliveries d ON o.order_id = d.order_id
  WHERE d.delivery_status = 'Delivered'
  GROUP BY o.restaurant_id, DATE_TRUNC('month', o.order_date)
),

growth_data AS (
  SELECT 
    restaurant_id,
    TO_CHAR(month_date, 'MM-YYYY') AS month_name,
    count_of_delivered_orders,
    LAG(count_of_delivered_orders) OVER (
      PARTITION BY restaurant_id 
      ORDER BY month_date
    ) AS previous_month_orders,
    
    ROUND(
      (count_of_delivered_orders * 1.0 / NULLIF(LAG(count_of_delivered_orders) OVER (
        PARTITION BY restaurant_id 
        ORDER BY month_date
      ), 0)) - 1,
      2
    ) AS growth_ratio
  FROM monthly_deliveries
)

SELECT 
  restaurant_id,
  ROUND(AVG(growth_ratio), 2) AS avg_growth_ratio
FROM growth_data
WHERE growth_ratio IS NOT NULL  -- skip first month where no previous data
GROUP BY restaurant_id
ORDER BY avg_growth_ratio DESC;

-- Restaurant IDs 24, 12, 17, 34 have average monthly growth ratios exceeding +50%
-- Their operational systems (kitchen → packaging → dispatch) are likely adapting well to rising demand.

--10 restaurants have negative average growth, meaning their number of delivered orders is declining over time.












-- (K) Customer Segmentation 
-- if a customer's total spendings > AOV : Gold
-- otherwise : Silver
--SQL query to each segement's total orders and total revenue.
-- AOV = 322.82

-- Customer Segmentation Summary: Total Orders and Revenue per Segment

WITH segmentation AS (
  SELECT 
    customer_id,
    SUM(total_amount) AS total_spent,
    CASE
      WHEN SUM(total_amount) > 322 THEN 'Gold'
      ELSE 'Silver'
    END AS customer_segmentation
  FROM orders
  GROUP BY customer_id
)

SELECT 
  s.customer_segmentation,
  COUNT(o.order_id) AS total_orders,
  SUM(o.total_amount) AS total_revenue
FROM segmentation s
JOIN orders o ON o.customer_id = s.customer_id
GROUP BY s.customer_segmentation;


















-- (L)Calculate each rider's monthly earnings (8% commission)
SELECT 
  d.rider_id, 
  TO_CHAR(o.order_date, 'MM-YYYY') AS month_name ,
  SUM(ROUND((o.total_amount * 0.08)::numeric, 2)) AS total_monthly_earnings
FROM deliveries d
LEFT JOIN orders o 
  ON d.order_id = o.order_id
GROUP BY d.rider_id, month_name
ORDER BY d.rider_id, month_name;




















-- (M) Rider Ratings Analysis


WITH delivery_analysis AS (
  SELECT 
    d.rider_id, 
    o.order_id,
    o.order_time,
    d.delivery_time,
    ROUND(
      (
        CASE 
          WHEN d.delivery_time < o.order_time 
          THEN EXTRACT(EPOCH FROM d.delivery_time) + 86400
          ELSE EXTRACT(EPOCH FROM d.delivery_time)
        END
        - EXTRACT(EPOCH FROM o.order_time)
      ) / 60,
      2
    ) AS time_difference_in_minutes
  FROM orders o
  JOIN deliveries d ON o.order_id = d.order_id
  WHERE d.delivery_status = 'Delivered'
),

ratings_analysis as 
(
SELECT *,
  CASE 
    WHEN time_difference_in_minutes <= 15.00 THEN '5 stars'  
    WHEN time_difference_in_minutes <= 20.00 THEN '4 stars' 
    WHEN time_difference_in_minutes <= 30.00 THEN '3 stars'
    WHEN time_difference_in_minutes <= 45.00 THEN '2 stars'
    ELSE '1 star' 
  END AS ratings_of_rider
FROM delivery_analysis
)

SELECT 
   rider_id,
   ratings_of_rider,
   count(ratings_of_rider) as count_of_ratings
FROM ratings_analysis
GROUP BY rider_id, ratings_of_rider
ORDER BY ratings_of_rider DESC;

--7 riders have consistently high ratings, each averaging around 45 five-star ratings per rider.
--These riders are delivering within 15 minutes on most orders.
--11 riders have a disproportionately high number of 1-star ratings, often taking longer than 45 minutes per delivery.
-- These riders may also overlap in these two extreme categories.
























-- (N) Order Frequency by Day
-- Analyse order frequency per day of the week and identify the peak of each restaurant.

WITH weekday_rankings AS (
  SELECT 
    r.restaurant_id,
    r.restaurant_name,
    EXTRACT(DOW FROM o.order_date) AS weekday_num,
    COUNT(o.order_id) AS count_of_orders,
    RANK() OVER (
      PARTITION BY r.restaurant_id
      ORDER BY COUNT(o.order_id) DESC
    ) AS rank
  FROM orders o
  LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
  GROUP BY r.restaurant_id, r.restaurant_name, EXTRACT(DOW FROM o.order_date)
)

SELECT *
FROM weekday_rankings
WHERE rank = 1
ORDER BY count_of_orders DESC;

-- Friday to Sunday are the busiest days for the majority of restaurants.
-- This aligns with consumer behavior — people order out more during the weekend (parties, less cooking, family time).





















-- (O) Monthly Sales Trends
SELECT 
  EXTRACT(MONTH FROM order_date) as month_number,
  SUM(total_amount) as total_sales
FROM orders
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY SUM(total_amount) DESC;

-- Top 3 months were March, October and July.






















--(P) Seasonal Order Item Popularity
-- Track the popularity of specific order items and identify the seasonal demand spikes.
SELECT 
  CASE 
    WHEN EXTRACT(MONTH FROM order_date) IN (12, 1, 2) THEN 'Winter'
    WHEN EXTRACT(MONTH FROM order_date) IN (3, 4, 5) THEN 'Summer'
    WHEN EXTRACT(MONTH FROM order_date) IN (6, 7, 8, 9) THEN 'Monsoon'
    ELSE 'Autumn' 
  END AS season,
  order_item,
  COUNT(order_id) AS number_of_orders
FROM orders
GROUP BY season, order_item
ORDER BY season, number_of_orders DESC;
-- Monsoon: Chicken Biryani and Masala Dosa are the most popular, showing a strong preference for warm and spicy dishes.
-- Winter: Masala Dosa and Pasta Alfredo trend high, suggesting demand for hearty and comforting meals.
-- Summer: Paneer Butter Masala and Chicken Biryani are favorites, reflecting love for rich, flavorful gravies.
-- Autumn: Paneer Butter Masala and Pasta Alfredo dominate, likely due to festive gatherings and family dining.

































