-- USE DATABASE pizza_sales;
CREATE TABLE order_details(
	order_details_id INT PRIMARY KEY,
	order_id INT,
	pizza_id TEXT,
	quantity INT
);
SELECT * FROM order_details;

CREATE TABLE orders(
	order_id INT,
	order_date DATE NOT NULL,
	order_time TIME NOT NULL,
	PRIMARY KEY(order_id)
);
SELECT * FROM orders;

CREATE TABLE pizza_types(
	pizza_type_id TEXT PRIMARY KEY,
	name TEXT,
	category TEXT,
	ingredients TEXT
);
SELECT * FROM pizza_types;

CREATE TABLE pizzas(
	pizza_id TEXT PRIMARY KEY,
	pizza_type_id TEXT,
	size CHAR(5),
	price NUMERIC(5,2)
);
SELECT * FROM pizzas;

-- 1. Retrieve the total number of orders placed.
SELECT
	COUNT(*) AS total_orders
FROM orders;

-- 2. Calculate the total revenue generated from pizza sales.
SELECT
	SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
INNER JOIN pizzas p
ON od.pizza_id = p.pizza_id;

-- 3. Identify the highest-priced pizza.
SELECT
	pt.name,
	p.price
FROM pizza_types pt
JOIN pizzas p
ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- 4. Identify the most common pizza size ordered.
SELECT
	p.size AS size_of_pizza,
	COUNT(od.order_details_id) AS order_count
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY COUNT(od.order_details_id) DESC
LIMIT 1;


-- 5. List the top 5 most ordered pizza types along with their quantities.
SELECT
	pt.name,
	COUNT(od.order_details_id) AS orders,
	SUM(od.quantity) as quantity
FROM pizzas p
JOIN order_details od
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY quantity DESC
LIMIT 5;

-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT
	DISTINCT pt.category,
	SUM(od.quantity) AS total_quantity
FROM pizzas p
join order_details od
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP by pt.category
ORDER BY total_quantity DESC;

-- 7. Determine the distribution of orders by hour of the day.

SELECT
	DATE_PART('HOUR', order_time) AS hours,
	COUNT(order_id) AS orders
FROM orders
GROUP BY hours
ORDER BY orders DESC;

-- 8. Join relevant tables to find the category-wise distribution of pizzas.

SELECT
	category,
	COUNT(name) pizza_count
FROM pizza_types
GROUP BY category;

-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT * FROM orders;

SELECT TRUNC(AVG(total_order_qty), 0) AS avg_pizza_ordered_per_day
FROM
	(SELECT
		o.order_date AS "Date",
		SUM(od.quantity) AS total_order_qty
	FROM orders o
	JOIN order_details od
	ON o.order_id = od.order_id
	GROUP BY "Date") AS t;
	

-- 10. Determine the top 3 most ordered pizza types based on revenue.

SELECT pt.name AS pizza_type, SUM(od.quantity * p.price) AS revenue 
FROM pizzas p
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od
ON p.pizza_id = od.pizza_id -- revenue of per order.
GROUP BY pizza_type
ORDER BY revenue DESC
LIMIT 3;

-- 11. Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
	pt.category AS pizza_category,
	TRUNC((SUM(od.quantity * p.price) / 
		(SELECT
			SUM(od.quantity * p.price) AS total_revenue
		FROM order_details od
		INNER JOIN pizzas p
		ON od.pizza_id = p.pizza_id)) * 100, 2) || ' %' AS revenue_pct
FROM pizzas p
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY pizza_category
ORDER BY revenue_pct DESC;

-- 12. Analyze the cumulative revenue generated over time.

SELECT order_date,
SUM(revenue) OVER(ORDER BY order_date) AS cum_revenue
FROM
	(SELECT
		o.order_date AS order_date,
		SUM(od.quantity * p.price) AS revenue
	FROM pizzas p
	JOIN order_details od
	ON p.pizza_id = od.pizza_id
	JOIN orders o
	ON od.order_id = o.order_id
	GROUP BY o.order_date) AS sales;

-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT category, name, revenue
FROM
	(SELECT
		category, name, revenue,
		RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
	FROM
		(SELECT
			pt.category,
			pt.name,
			SUM(od.quantity * p.price) AS revenue
		FROM pizzas p
		JOIN order_details od
		ON p.pizza_id = od.pizza_id
		JOIN pizza_types pt
		ON p.pizza_type_id = pt.pizza_type_id
		GROUP BY pt.category, pt.name
		) AS t1
	) AS t2
WHERE rn <= 3;
