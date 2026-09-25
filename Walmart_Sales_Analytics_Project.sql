select * from walmart_db;

select payment_method, count(*)
from walmart_db
group by payment_method;

select count(distinct branch) from walmart_db;

select max(quantity) from walmart_db;

--Bussiness Problems

--Q1. Find the different payment method and no. of transactions, no. of quantity sold
select 
	payment_method, 
	count(*) as no_payments,
	Sum(quantity) as no_of_quantity
from walmart_db
group by payment_method;

--Q2. Identify the highest rated category in each branch, displaying the branch, category,average rating
SELECT * FROM
(	select
  		branch,category, AVG(rating) as avg_rating,
  		RANK() OVER(PARTITION BY branch order by avg(rating) DESC) as rank
	from walmart_db  
	group by category, branch
	order by branch,3
)
WHERE rank = 1;

--Q3. Identify the busiest day for each branch based on the number of transaction
select * from
	(SELECT
	branch, 
	TO_CHAR(TO_DATE(date, 'DD_MM_YY'), 'Day') as day_name,
	count(*) as no_transaction,
	RANK() OVER(PARTITION BY branch ORDER BY Count(*) DESC) as rank
	from walmart_db
	group by 1,2
	)
WHERE rank = 1;

--Q4. Calculate the total quantity of items sold per payment method. List payment_method and total_quantity
select 
	payment_method, 
	Sum(quantity) as no_of_quantity
from walmart_db
group by payment_method;

--Q5. Determine the average, maximum, minimum rating of category for each city.
--List the city, average_rating, min_rating and max_rating.
select
	city,
	category,
  	Avg(rating) as avg_rating,
  	Max(rating) as max_rating,
	Min(rating) as min_rating
from walmart_db
group by city,category;

--Q6. Calculate the total profit for each category by considering total_profit
-- as (unit_price * quantity * profit_margin).
-- List category and total_profit, ordered from highest to lowest profit
select 
	category,
	SUM(total) as total_revenue,
	SUM(total * profit_margin) as profit
From walmart_db	
GROUP BY 1;

--Q7. Determine the most common payment method for each branch.
--Display Branch and the preferred_payment method.
with cte
AS
(select
	branch,
	payment_method,
	count(*) as total_trans,
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
From walmart_db
group by 1,2
)
SELECT *
FROM cte
WHERE rank = 1;

--Q8. Categorize sales into 3 group MORNING, AFTERNOON, EVENING.
--Find out each of the shift and number of invoices
SELECT
	branch,
	CASE 
		WHEN EXTRACT (HOUR FROM(time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT (HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END day_time,
	count(*)
FROM walmart_db
GROUP BY 1,2
order by 1,3 DESC

--Q9. Identify 5 branches with highest decrease ratio in
-- revenue compare to last year(current year 2023 and last year 2022)
select *,
extract (year from to_date(date,'DD/MM/YY')) as formatted_date
from walmart_db

--2022 sales
with revenue_2022
as
(
	select 
		branch,
		sum(total) as revenue
	from walmart_db
	where extract (year from to_date(date,'DD/MM/YY')) = 2022
	group by 1
),

--2023 sales
revenue_2023
as
(
	select 
		branch,
		sum(total) as revenue
	from walmart_db
	where extract (year from to_date(date,'DD/MM/YY')) = 2023
	group by 1
)
select 
	ls.branch, 
	ls.revenue as last_year_revenue,
	cs.revenue as cr_year_revenue,
	ROUND((ls.revenue - cs.revenue)::numeric/
	ls.revenue::numeric * 100,2) as revenue_dec_ratio
from revenue_2022 as ls
join revenue_2023 as cs
on ls.branch = cs.branch
where ls.revenue > cs.revenue
order by 4 DESC
limit 5