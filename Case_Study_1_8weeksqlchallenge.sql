-- Source : https://8weeksqlchallenge.com/case-study-1/
-- Case Study #1 - Danny's Diner  --
 
CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES 
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- ============================================================  
-- 1. What is the total amount each customer spent at the restaurant?

use dannys_diner;

select customer_id as "Customer ID",
		sum(price) as "Total Spending"
from sales
inner join menu
on sales.product_id = menu.product_id
group by customer_id;

-- ============================================================  
-- 2. How many days has each customer visited the restaurant?
 
select customer_id as "Customer ID",
		count(distinct order_date) as "Total Day Visited"
from sales
inner join menu
on sales.product_id = menu.product_id
group by customer_id;

-- ============================================================  
-- 3. What was the first item from the menu purchased by each customer?

with raw_sales as (
select customer_id,
		order_date,
        product_name,
		sales.product_id as s_pid,
		menu.product_id as m_pid,
		row_number() over(partition by customer_id order by order_date) as S_No
from sales
inner join menu
on sales.product_id = menu.product_id
)
select Customer_ID, Product_Name 
from raw_sales
where S_No = 1;

-- ============================================================  
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with raw_sales_menu as (
select Product_Name,
		customer_id
from sales
inner join menu
on sales.product_id = menu.product_id
)
select Product_Name,
		count(customer_id) as "Purchase Count"
from raw_sales_menu
group by Product_Name
order by count(customer_id) desc
limit 1;

-- ============================================================  
-- 5. Which item was the most popular for each customer?

with raw as (
select customer_id,
	   sales.product_id,
	   -- count(order_date),
       count(sales.product_id) as Times_Purchased,
       -- case when count(order_date) = count(sales.product_id) then 1 else 0 end as "Check",
        dense_rank() over(partition by customer_id order by count(sales.product_id)) as Rank_
from sales
inner join menu
on sales.product_id = menu.product_id
group by customer_id, sales.product_id
)
select customer_id, product_id, Rank_ 
from raw
where (customer_id, Rank_) in (select customer_id, max(Rank_) from raw group by customer_id);

-- =========================================================================================
-- 6. Which item was purchased first by the customer after they became a member?

with raw as (
select sales.customer_id, 
		order_date,
        product_id,
        join_date,
        datediff(join_date, order_date) as datediff
from sales
inner join members
on sales.customer_id = members.customer_id
where datediff(join_date, order_date)  < 1
order by datediff
)
select customer_id, 
		order_date, 
        product_id,
        join_date
from raw
where (customer_id, datediff) in (select customer_id, max(datediff) from raw group by customer_id);
;

-- =========================================================================================
-- 7. Which item was purchased just before the customer became a member?

with raw as (
select sales.customer_id, 
		order_date,
        product_id,
        join_date,
        datediff(join_date, order_date) as datediff
from sales
inner join members
on sales.customer_id = members.customer_id
where datediff(join_date, order_date)  > 0
order by datediff
)
-- select * from raw;
select customer_id, 
		order_date, 
        product_id,
        join_date
from raw
where (customer_id, datediff) in (select customer_id, min(datediff) from raw group by customer_id);
;

-- =========================================================================================
-- 8. What is the total items and amount spent for each member before they became a member?

with raw as (
select sales.customer_id,
		sales.product_id,
        price,
		order_date,
        join_date,
        datediff(join_date, order_date) as datediff
from sales
inner join members
on sales.customer_id = members.customer_id
inner join menu
on sales.product_id = menu.product_id
where datediff(join_date, order_date)  > 0
order by datediff
)
select customer_id,
	   count(product_id) as item_purchased,
       sum(price) as total_spending
from raw
group by customer_id;

-- =========================================================================================
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
--     how many points would each customer have?

with raw as (
select customer_id,
		product_name,
        price,
        case 
			when lower(product_name) not like '%sushi%' then price * 10 
            else price * 2 * 10 
            end as points
from sales
inner join menu
on sales.product_id = menu.product_id
)
select customer_id, sum(points) as points
from raw
group by customer_id;

-- =========================================================================================
-- 10. In the first week after a customer joins the program (including their join date) 
--      they earn 2x points on all items, not just sushi - 
--      how many points do customer A and B have at the end of January?

with raw as (
select sales.customer_id,
		product_name,
        price,
		order_date,
        join_date,
        datediff(join_date, order_date) as datediff,
        case
			when datediff(order_date, join_date) <= 7 then price * 20
            when abs(datediff(order_date, join_date)) > 7 and lower(product_name) like '%sushi%' then price * 20 
            else price * 10 end as Point 
from sales
inner join members
on sales.customer_id = members.customer_id
inner join menu
on sales.product_id = menu.product_id
where datediff(join_date, order_date)  < 1
order by datediff
)
select * from raw;
