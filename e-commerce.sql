SELECT * FROM order_list WHERE ISNULL(order_id) OR ISNULL(order_date) OR ISNULL(CustomerName);
SELECT * FROM order_details;
SELECT * FROM sales_target;
-- Mengubah nama kolom di tabel order_details
ALTER TABLE order_details RENAME COLUMN `Sub-Category` TO sub_category ;
ALTER TABLE order_details RENAME COLUMN `Order ID` TO order_id;

-- Mengubah nama kolom di tabel order_list
ALTER TABLE order_list RENAME COLUMN `Order Date` TO order_date;
ALTER TABLE order_list RENAME COLUMN `Order ID` TO order_id ;

-- Mengubah nama kolom di tabel sales_target
ALTER TABLE sales_target RENAME COLUMN `Month of Order Date` TO month_of_order;


CREATE VIEW combined_orders AS
SELECT 
    d.order_id, 
    d.amount, 
    d.profit, 
    d.quantity, 
    d.category, 
    d.sub_category, 
    l.order_date, 
    l.CustomerName, 
    l.state, 
    l.city
FROM order_details AS d
INNER JOIN order_list AS l
ON d.order_id = l.order_id;

-- Langkah 2: Membuat View untuk Pengelompokan Pelanggan Menggunakan Model RFM
CREATE VIEW customer_grouping AS
SELECT 
    CustomerName,
    CASE
        WHEN (R >= 4 AND R <= 5) AND (F >= 4 AND F <= 5) AND (M >= 4 AND M <= 5) THEN 'Champions'
        WHEN (R >= 3 AND R <= 5) AND (F >= 3 AND F <= 5) AND (M >= 2 AND M <= 5) THEN 'Loyal Customers'
        WHEN (R >= 3 AND R <= 5) AND (F >= 2 AND F <= 3) AND (M >= 2 AND M <= 3) THEN 'Potential Loyalist'
        WHEN (R >= 4 AND R <= 5) AND (F >= 1 AND F <= 3) AND (M >= 1 AND M <= 2) THEN 'New Customers'
        WHEN (R >= 3 AND R <= 4) AND (F >= 1 AND F <= 3) AND (M >= 1 AND M <= 2) THEN 'Promising'
        WHEN (R >= 2 AND R <= 3) AND (F >= 1 AND F <= 2) AND (M >= 1 AND M <= 2) THEN 'Customers Needing Attention'
        WHEN (R >= 1 AND R <= 2) AND (F >= 2 AND F <= 3) AND (M >= 1 AND M <= 2) THEN 'About to Sleep'
        WHEN (R >= 1 AND R <= 2) AND (F >= 1 AND F <= 2) AND (M >= 2 AND M <= 5) THEN 'At Risk'
        WHEN (R >= 1 AND R <= 2) AND (F >= 2 AND F <= 3) AND (M >= 1 AND M <= 2) THEN "Can't Lose Them"
        WHEN (R >= 1 AND R <= 2) AND (F >= 1 AND F <= 2) AND (M >= 1 AND M <= 2) THEN 'Hibernating'
        WHEN (R >= 1 AND R <= 2) AND (F >= 1 AND F <= 2) AND (M >= 0 AND M <= 1) THEN 'Lost'
        ELSE 'Other'
    END AS customer_segment
FROM (
    SELECT 
        CustomerName,
        MAX(STR_TO_DATE(order_date, '%d-%m-%Y')) AS latest_order_date,
        DATEDIFF('2023-03-31', MAX(STR_TO_DATE(order_date, '%d-%m-%Y'))) AS recency,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(amount) AS monetary,
        NTILE(5) OVER (ORDER BY DATEDIFF('2023-03-31', MAX(STR_TO_DATE(order_date, '%d-%m-%Y'))) ASC) AS R,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT order_id) ASC) AS F,
        NTILE(5) OVER (ORDER BY SUM(amount) ASC) AS M
    FROM combined_orders
    GROUP BY CustomerName
) AS rfm_table;

SELECT * FROM combined_orders;

-- Langkah 3: Menghitung Persentase Segmen Pelanggan
SELECT 
    customer_segment,
    COUNT(DISTINCT CustomerName) AS num_of_customers,
    ROUND(COUNT(DISTINCT CustomerName) * 100.0 / (SELECT COUNT(*) FROM customer_grouping), 2) AS pct_of_customers
FROM customer_grouping
GROUP BY customer_segment
ORDER BY pct_of_customers DESC;


SELECT 
	COUNT(DISTINCT order_id) as num_of_orders,
    COUNT(DISTINCT CustomerName) as num_of_customer,
    COUNT(DISTINCT city) as num_of_cities,
    COUNT(DISTINCT state) as num_of_states
FROM combined_orders;

SELECT 
	CustomerName,
    state, 
    city,
    SUM(amount) as sales
FROM combined_orders
WHERE CustomerName NOT IN(
	SELECT DISTINCT CustomerName
    FROM combined_orders
    WHERE YEAR(STR_TO_DATE(order_date, "%d-%m-%Y")) = 2018)
AND YEAR(STR_TO_DATE(order_date, "%d-%m-%Y")) = 2019
GROUP BY CustomerName, state, city
ORDER BY sales DESC
LIMIT 5;


select 
	state, 
	city,
	COUNT(distinct CustomerName) as num_of_customer,
	SUM(profit) as total_profit,
	SUM(quantity) as total_quantity
from combined_orders 
group by state, city
order by total_profit desc 
limit 10;


select 
	order_date,
	order_id,
	state,
	CustomerName
from (select *, row_number() over (partition by state order by state, order_id) as RowNumberPerState
from combined_orders) as firstorder
where RowNumberPerState = 1
order by order_id;

-- sales in different days
SELECT
  day_of_order,
  LPAD('*', num_of_orders, '*') AS num_of_orders,
  sales
FROM (
  SELECT
    DAYNAME(STR_TO_DATE(order_date, '%d-%m-%Y')) AS day_of_order,
    COUNT(DISTINCT order_id) AS num_of_orders,
    SUM(Quantity) AS quantity,
    SUM(Amount) AS sales
  FROM combined_orders
  GROUP BY day_of_order
) sales_per_day
ORDER BY sales DESC;

SELECT 
	CONCAT(MONTHNAME(STR_TO_DATE(order_date, '%d-%m-%Y')), "-", 
	YEAR(STR_TO_DATE(order_date, '%d-%m-%Y'))) AS month_of_year,
	SUM(Profit) AS total_profit, SUM(Quantity) AS total_quantity
FROM combined_orders
GROUP BY month_of_year
ORDER BY month_of_year= 'April-2018'DESC,
month_of_year= 'May-2018'DESC,
month_of_year= 'June-2018'DESC,
month_of_year= 'July-2018'DESC,
month_of_year= 'August-2018'DESC,
month_of_year= 'September-2018'DESC,
month_of_year= 'October-2018'DESC,
month_of_year= 'November-2018'DESC,
month_of_year= 'December-2018' DESC,
month_of_year= 'January-2019'DESC,
month_of_year= 'February-2019'DESC,
month_of_year= 'March-2019'DESC;


--- find out the sales for each category in each month

CREATE VIEW sales_by_category AS
SELECT 
	CONCAT(SUBSTR(MONTHNAME (STR_TO_DATE(order_date, '%d-%m-%Y')),1,3), "-", 
	SUBSTR(YEAR(STR_TO_DATE(order_date, '%d-%m-%Y')),3,2)) AS order_monthyear, 
	Category, 
	SUM(Amount) AS Sales
FROM combined_orders
GROUP BY order_monthyear, Category;

--- check if the sales hit the target set for each category in each month

CREATE VIEW sales_vs_target AS
SELECT *, CASE
WHEN Sales > Target THEN 'Hit'
ELSE 'Fail'
END AS hit_or_fail
FROM
(SELECT s.order_monthyear, s. Category, s.Sales, t.Target
FROM sales_by_category AS S
INNER JOIN sales_target AS t ON S.order_monthyear = t.month_of_order
AND s. Category = t. Category) st;

-- return the number of times that the target is met & the number of times that the target is not met
SELECT h.Category, h.Hit, f.Fail
FROM
(SELECT Category, COUNT(*) AS Hit
FROM sales_vs_target
WHERE hit_or_fail LIKE 'Hit'
GROUP BY Category) h
INNER JOIN
(SELECT Category, COUNT(*) AS Fail
FROM sales_vs_target
WHERE hit_or_fail LIKE 'Fail'
GROUP BY Category) f
ON h.Category = f.Category;

-- find order quantity, profit, amount for each subcategory
-- electronic games & tables subcategories resulted in loss
CREATE VIEW order_details_by_total AS
SELECT Category, sub_category,
SUM(Quantity) AS total_order_quantity,
SUM(Profit) AS total_profit,
SUM(Amount) AS total_amount
FROM order_details
GROUP BY Category, sub_category
ORDER BY total_order_quantity DESC;

drop view order_details_by_total ;

-- maximum cost per unit & maximum price per unit for each subcategory
CREATE VIEW order_details_by_unit AS
SELECT Category, sub_category, MAX(cost_per_unit) AS max_cost, MAX(price_per_unit) AS max_price
FROM (SELECT *, round((Amount-Profit)/Quantity, 2) AS cost_per_unit, round(Amount/Quantity, 2) AS price_per_unit
FROM order_details)c
GROUP BY Category, sub_category
ORDER BY max_cost DESC;

drop view order_details_by_unit ;

-- combine order_details_by_unit table and order_details_by_total table

SELECT 
	t.Category, 
	t.sub_category, 
	t.total_order_quantity, 
	t.total_profit, 
	t.total_amount, 
	u.max_cost, 
	u.max_price
FROM order_details_by_total AS t
INNER JOIN order_details_by_unit AS u
ON t.sub_category = u.sub_category;

SELECT * FROM combined_orders;
SELECT * FROM customer_grouping;