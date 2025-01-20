
-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM
    city
ORDER BY 2 DESC;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    ci.city_name, SUM(s.total) AS total_revenue
FROM
    sales AS s
        JOIN
    customers AS c ON s.customer_id = c.customer_id
        JOIN
    city AS ci ON ci.city_id = c.city_id
WHERE
    YEAR(s.sale_date) = 2023
        AND QUARTER(s.sale_date) = 4
GROUP BY ci.city_name
order by total_revenue desc;


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name, COUNT(s.sale_id) AS total_orders
FROM
    products AS p
        LEFT JOIN
    sales AS s ON p.product_id = s.product_id
GROUP BY p.product_name
order by total_orders desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customer,
    ROUND((SUM(s.total)) / COUNT(DISTINCT s.customer_id),
            2) AS avg_sale_per_customer
FROM
    sales AS s
        JOIN
    customers AS c ON s.customer_id = c.customer_id
        JOIN
    city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;



-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS (
    SELECT
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions
    FROM city
),
customers_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT 
    ct.city_name,
    ct.coffee_consumers_in_millions,
    cit.unique_customers
FROM city_table AS ct
JOIN customers_table AS cit
    ON cit.city_name = ct.city_name;


-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select *
from 
(
	SELECT
		ci.city_name,
		p.product_id,
		COUNT(s.sale_id) AS total_orders,
	DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS Ra
	FROM sales AS s
	JOIN products AS p ON s.product_id = p.product_id
	JOIN customers AS c ON c.customer_id = s.customer_id
	JOIN city AS ci ON ci.city_id = c.city_id
	GROUP BY ci.city_name, p.product_id
    ) as T1
where Ra <= 3;
 -- order by ci.city_name, total_orders desc
 
 
 -- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customer,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_customer,
    ct.avg_sale_per_customer,
round(cr.estimated_rent/ ct.total_customer , 2) as Avg_rent_per_customer
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
order by Avg_sale_per_customer desc;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sale AS (
    SELECT
        ci.city_name,
        MONTH(s.sale_date) AS Month,
        YEAR(s.sale_date) AS Year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, Month, Year
    ORDER BY ci.city_name, Year, Month
),
growth_sale AS (
    SELECT 
        city_name,
        Month,
        Year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY Year, Month) AS last_month_sale
    FROM monthly_sale 
)
SELECT 
    city_name,
    Month,
    Year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100,
        2
    ) AS growth_ratio
FROM growth_sale
WHERE last_month_sale is not NULL;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customer,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (  
    SELECT 
        city_name,
        estimated_rent,
round((population * 0.25)/1000000,2)  as estimated_coffee_consumer
    FROM city
)
SELECT 
    cr.city_name,
    total_revenue,
    cr.estimated_rent as total_rent,
    ct.total_customer,
    estimated_coffee_consumer,
    ct.avg_sale_per_customer,
round(cr.estimated_rent/ ct.total_customer , 2) as Avg_rent_per_customer
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
order by total_revenue desc;

/* 
-- Recomedation
city 1 : Pune
	Avg rent per customer is very less, 
	2.highest revenue, 2
	3. Avg_sale per customer is also high

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k







