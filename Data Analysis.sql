--Exploratory Data Analysis
SELECT * FROM customers;
SELECT * FROM deliveries;
SELECT * FROM orders;
SELECT * FROM restaurants;
SELECT * FROM riders;

--Handling Nulls
SELECT COUNT(*) FROM customers
WHERE 
	customer_name IS NULL
    OR 
	reg_date IS NULL;

SELECT COUNT(*) FROM orders
WHERE
    order_item IS NULL
    OR 
	order_date IS NULL
    OR 
	order_time IS NULL
    OR 
	order_status IS NULL
    OR 
	total_amount IS NULL;

-----------------------------------------------------------------------
--Data Analysis
-----------------------------------------------------------------------

--Q.1 — Write a query to find the most frequently ordered dishes by customer called "Rahul Gupta" in the last 3 year.
SELECT 	c.customer_name,
		o.order_item as dishes,
		COUNT(o.order_item) as no_of_orders_made
FROM orders o
JOIN customers c
ON o.customer_id=c.customer_id
WHERE c.customer_name = 'Rahul Gupta'
AND
o.order_date >= CURRENT_DATE - INTERVAl '3 year'
GROUP BY 1,2
ORDER BY 3 DESC;

--Q.2 Popular Time Slots 
--Identify the time slots during which the most orders are placed, based on 2-hour intervals.

WITH time_slots
AS
	(SELECT *,
		CASE
				WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1  THEN '00:00-02:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3  THEN '02:00-04:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5  THEN '04:00-06:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7  THEN '06:00-08:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9  THEN '08:00-10:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00-12:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00-14:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00-16:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00-18:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00-20:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00-22:00'
	            WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00-24:00'
		END as time_slot
	FROM orders)	
SELECT time_slot,
		COUNT(*) as no_of_orders_made
FROM time_slots
GROUP BY 1
ORDER BY 2 DESC;

--Q.3 Order Value Analysis
--Find the average order value per customer who has placed more than 8 orders. Return customer_name and aov (average order value).

SELECT
    c.customer_name,
    ROUND(AVG(o.total_amount),2) AS aov
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY 1
HAVING COUNT(order_id) >= 8
ORDER BY 2 DESC;

--Q.4 High-Value Customers
--List the customers who have spent more than 15K in total on food orders.
--Return customer_name

SELECT c.customer_name,
		SUM(o.total_amount)
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 15000
ORDER BY 2 DESC;

--Q.5 Orders Without Delivery
--Write a query to find orders that were placed but not delivered.
--Return each restaurant_name, city and number of not delivered orders

SELECT r.restaurant_name,
		r.city,
		COUNT(o.order_id) as orders_not_delivered
FROM orders o
LEFT JOIN
    restaurants r
    ON r.restaurant_id = o.restaurant_id
LEFT JOIN
    deliveries d
    ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1,2
ORDER BY 3 DESC;

--Q.6 Restaurant Revenue Ranking
--Rank restaurants by their total revenue from the year 2024, including their name, total revenue, and rank within their city.

SELECT 
    r.restaurant_name,
    r.city,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank_in_city
FROM restaurants r
JOIN orders o
    ON r.restaurant_id = o.restaurant_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2024
GROUP BY 1, 2
ORDER BY 2,4;

--Q.7 Most Popular Dish by City
--Identify the most popular dish in each city based on the number of orders.

WITH dishes_ranks
AS
	(SELECT r.city,
			o.order_item,
			COUNT(order_item) AS no_of_orders,
			RANK() OVER(PARTITION BY r.city ORDER BY COUNT(order_item) DESC) AS rank_in_city
	FROM restaurants r
	JOIN orders o
		ON r.restaurant_id = o.restaurant_id
	GROUP BY 1,2
	ORDER BY 1)
SELECT *
FROM dishes_ranks
WHERE rank_in_city = 1;


--Q.8 Customer Churn
--Find customers who haven't placed an order in 2024 but did in 2023.

SELECT DISTINCT c.*
FROM customers c
JOIN orders o 
	ON c.customer_id = o.customer_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
  AND c.customer_id NOT IN (
      SELECT customer_id
      FROM orders
      WHERE EXTRACT(YEAR FROM order_date) = 2024
	  );


--Q.9 Cancellation Rate Comparison
--Calculate and compare the order cancellation rate for each restaurant between the 2023 and 2024.

WITH canc_orders AS (
    SELECT 
        r.restaurant_id,
        COUNT(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2023 
                   THEN 1 END) AS total_orders_2023,
        COUNT(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2023 
                   AND o.order_status = 'Cancelled' THEN 1 END) AS cancelled_2023,
        COUNT(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2024 
                   THEN 1 END) AS total_orders_2024,
        COUNT(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2024 
                   AND o.order_status = 'Cancelled' THEN 1 END) AS cancelled_2024
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE EXTRACT(YEAR FROM o.order_date) BETWEEN 2023 AND 2024
    GROUP BY 1
)
SELECT 
    restaurant_id,
    CASE 
        WHEN total_orders_2023 = 0 THEN 0.00
        ELSE ROUND(100.0 * cancelled_2023 / total_orders_2023, 2)
    END AS canc_rate_2023,
    CASE 
        WHEN total_orders_2024 = 0 THEN 0.00
        ELSE ROUND(100.0 * cancelled_2024 / total_orders_2024, 2)
    END AS canc_rate_2024
FROM canc_orders
ORDER BY 1;


--Q.10 Rider Average Delivery Time
--Determine each rider's average delivery time.

SELECT
    o.order_id,
    o.order_time,
    d.delivery_time,
    d.rider_id,
    --d.delivery_time - o.order_time AS time_difference,
    ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
        CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
        INTERVAL '0 day' END))/60,3) as time_difference_insec
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';

--Q.11 Customer Segmentation
--Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average order value (AOV). 
--If a customer's total spending exceeds the AOV, label them as 'Gold'; otherwise, label them as 'Silver'. 
--Write an SQL query to determine each segment's total number of orders and total revenue.

SELECT
    cx_category,
    SUM(total_orders) AS total_orders,
    SUM(total_spent) AS total_revenue
FROM
    (SELECT
        customer_id,
        SUM(total_amount) AS total_spent,
        COUNT(order_id) AS total_orders,
        CASE
            WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
            ELSE 'Silver'
        END AS cx_category
    FROM orders
    GROUP BY 1
    ) AS t1
GROUP BY 1;

--Q.12 Rider Monthly Earnings
--Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

SELECT
    d.rider_id,
    TO_CHAR(o.order_date, 'mm-yy') AS month,
    SUM(total_amount) AS revenue,
    SUM(total_amount) * 0.08 AS riders_earning
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
GROUP BY 1, 2
ORDER BY 1, 2;

--Q.13 Rider Ratings Analysis
--Find the number of 5-star, 4-star, and 3-star ratings each rider has. Riders receive this rating based on delivery time:
--If orders are delivered in less than 15 minutes → 5 star
--If they deliver between 15 and 20 minutes → 4 star
--If they deliver after 20 minutes → 3 star

WITH delivery_time_cte AS (
    SELECT
        o.order_id,
        o.order_time,
        d.delivery_time,
        EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
            CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
            ELSE INTERVAL '0 day' END
        ))/60 AS delivery_took_time,
        d.rider_id
    FROM orders AS o
    JOIN deliveries AS d
    ON o.order_id = d.order_id
    WHERE delivery_status = 'Delivered'
),
star_ratings AS (
    SELECT
        rider_id,
        delivery_took_time,
        CASE
            WHEN delivery_took_time < 15 THEN '5 star'
            WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4 star'
            ELSE '3 star'
        END AS stars
    FROM delivery_time_cte
)
SELECT
    rider_id,
    stars,
    COUNT(*) AS total_ratings
FROM star_ratings
GROUP BY 1, 2
ORDER BY 1, 2;

-- Q.14 Order Frequency by Day
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

SELECT * FROM
(
    SELECT
        r.restaurant_name,
        TO_CHAR(o.order_date, 'Day') AS day,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM orders AS o
    JOIN restaurants AS r
    ON o.restaurant_id = r.restaurant_id
    GROUP BY 1, 2
    ORDER BY 1, 3 DESC
) AS t1
WHERE rank = 1;


-- Q.15 Customer Lifetime Value (CLV)
-- Calculate the total revenue generated by each customer over all their orders.

SELECT
    o.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS CLV
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY 1, 2;


-- Q.16 Monthly Sales Trends
-- Identify sales trends by comparing each month's total sales to the previous month.

SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(total_amount) AS total_sale,
    LAG(SUM(total_amount), 1) OVER(
        ORDER BY EXTRACT(YEAR FROM order_date), 
        EXTRACT(MONTH FROM order_date)
    ) AS prev_month_sale
FROM orders
GROUP BY 1, 2;