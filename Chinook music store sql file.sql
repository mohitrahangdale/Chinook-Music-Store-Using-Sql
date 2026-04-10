use chinook;

select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;

select * from track t 
join invoice_line il 
on t.track_id = il.track_id;

-- Question 1

-- to find null values
select 
    sum(case when customer_id is null then 1 else 0 end) as column1_null_count,
    sum(case when first_name is null then 1 else 0 end) as column2_null_count,
    sum(case when last_name is null then 1 else 0 end) as column3_null_count,
    sum(case when company is null then 1 else 0 end) as column4_null_count,
    sum(case when address is null then 1 else 0 end) as column5_null_count,
    sum(case when city is null then 1 else 0 end) as column6_null_count,
    sum(case when state is null then 1 else 0 end) as column6_null_count,
    sum(case when country is null then 1 else 0 end) as column7_null_count,
    sum(case when postal_code is null then 1 else 0 end) as column8_null_count,
    sum(case when phone is null then 1 else 0 end) as column8_null_count,
    sum(case when fax is null then 1 else 0 end) as column10_null_count,
    sum(case when email is null then 1 else 0 end) as column11_null_count,
    sum(case when support_rep_id is null then 1 else 0 end) as column12_null_count
from customer;

-- to handle null values 

SELECT 
    customer_id,
    first_name,
    last_name,
    COALESCE(company, 'NA') AS customer_type
FROM customer;

-- To find the DUPLICATES 

SELECT 
    first_name, 
    last_name, 
    email, 
    COUNT(*) AS total_occurrences
FROM customer
GROUP BY first_name, last_name, email
HAVING COUNT(*) > 1;

--  If you want to pick exactly one record from a set of duplicates (e.g., keep the oldest one), use a Window Function.

WITH unique_customers AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY first_name, last_name, email 
            ORDER BY customer_id ASC
        ) as row_num
    FROM customer
)
SELECT * FROM unique_customers WHERE row_num = 1;

-- Question 2


SELECT 
    t.name AS track_name, 
    art.name AS artist_name, 
    g.name AS genre_name, 
    COUNT(l.track_id) AS total_cnt
FROM invoice i
JOIN invoice_line l ON i.invoice_id = l.invoice_id
JOIN track t ON l.track_id = t.track_id
JOIN album a ON t.album_id = a.album_id
JOIN artist art ON a.artist_id = art.artist_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY 1, 2, 3
ORDER BY total_cnt DESC
LIMIT 5;




-- Question 3
select country,
count(*) as total_cust 
from customer 
group by country 
order by count(*) desc;



-- Question 4
-- Revenues Country Wise
select 
	billing_country,
	sum(unit_price*quantity) as total_rev_country
from invoice i 
join invoice_line il 
on i.invoice_id = il.invoice_id
group by billing_country;

-- Revenues State Wise
select 
	billing_state,
	sum(unit_price*quantity) as total_rev_state
from invoice i 
join invoice_line il 
on i.invoice_id = il.invoice_id
group by 
billing_state;

-- Revenues City Wise
select 
	billing_city,
	sum(unit_price*quantity) as total_rev_city
from invoice i 
join invoice_line il 
on i.invoice_id = il.invoice_id
group by 
billing_city;




-- Question 5 

with top_5_cust as (select c.customer_id,
concat(c.first_name,' ',c.last_name) as customer_name,
c.country,
sum(unit_price*quantity) as total_revenue,
rank() over(partition by c.country order by sum(unit_price*quantity) desc) as rnk
from customer c 
join invoice i 
on c.customer_id = i.customer_id 
join invoice_line il 
on il.invoice_id = i.invoice_id
group by c.customer_id,c.first_name, c.last_name, c.country
) 
select 
customer_id,
customer_name,
country,
total_revenue
from top_5_cust where rnk <=5
order by country,rnk;

-- Question 6 

with total_tracks_customer_wise as (select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    sum(il.quantity) as total_quantity
 from customer c 
 join invoice i on i.customer_id = c.customer_id 
 join invoice_line il on il.invoice_id = i.invoice_id
 group by c.customer_id
),
top_selling_track as (
	select ttcw.customer_id,
    ttcw.customer_name,
    ttcw.total_quantity,
    row_number() over(partition by ttcw.customer_id order by ttcw.total_quantity desc) as top_rnk,
    t.track_id,
    t.name as track_name
from total_tracks_customer_wise ttcw 
join invoice i on ttcw.customer_id = i.customer_id 
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id    
)
select customer_id,customer_name,track_name,total_quantity from top_selling_track
where top_rnk =1
order by customer_id;


-- Question 7 


SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(i.invoice_id) AS total_purchases,
    ROUND(SUM(i.total), 2) AS total_spent,
    ROUND(AVG(i.total), 2) AS average_order_value,
    MAX(i.invoice_date) AS last_purchase_date
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC;


-- Question 8

with monthly_active_customers as 
(select date_format(str_to_date(invoice_date, '%Y-%m-%d'), '%Y-%m') as month_year, count(distinct customer_id) as active_customers
from invoice
group by month_year),
	
churn_analysis as 
(select month_year, active_customers, 
lag(active_customers) over (order by month_year) as prev_month_customers,
lag(active_customers) over (order by month_year) - active_customers as churned_customers
from monthly_active_customers)

select month_year, active_customers, prev_month_customers,
case 
when churned_customers > 0 then concat('+', round((churned_customers / prev_month_customers) * 100, 2), '%')
else concat(round((churned_customers / prev_month_customers) * 100, 2), '%')
end as churn_rate
from churn_analysis
order by month_year;



-- Question 9 


 
  with genre_sales as 
(select g.name as genre_name, sum(i.total) as total_sales
from invoice i 
join invoice_line il 
on i.invoice_id = il.invoice_id 
join track t 
on il.track_id = t.track_id 
join genre g 
on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by genre_name),

total_sales as 
(select sum(total_sales) as usa_total_sales from genre_sales)

select gs.genre_name, gs.total_sales, 
concat(round((gs.total_sales / ts.usa_total_sales) * 100, 2),'%') as sales_contribution
from genre_sales gs 
join total_sales ts
order by total_sales desc, sales_contribution desc;
 
 
with artist_sales as 
(select g.name as genre_name, ar.name as artist_name, 
sum(i.total) as total_sales
from invoice i 
join invoice_line il 
on i.invoice_id = il.invoice_id 
join track t 
on il.track_id = t.track_id 
join album al 
on t.album_id = al.album_id 
join artist ar 
on al.artist_id = ar.artist_id 
join genre g 
on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by genre_name, artist_name),

total_sales as 
(select sum(total_sales) as usa_total_sales from artist_sales)

select ars.artist_name, ars.total_sales, 
concat(round((ars.total_sales / ts.usa_total_sales) * 100, 2),'%') as sales_contribution
from artist_sales ars 
join total_sales ts
order by ars.total_sales desc;
    

-- Qustion 10

with customer_genre_cnt as 
	(select i.customer_id, 
	concat(c.first_name,' ',c.last_name) as cust_name,
	count(distinct g.genre_id) as genre_cnt
from customer c     
join invoice i on c.customer_id = i.customer_id
join invoice_line il 
on i.invoice_id = il.invoice_id 
join track t 
on il.track_id = t.track_id 
join genre g 
on t.genre_id = g.genre_id
group by i.customer_id)

select 
	customer_id,
	cust_name,
	genre_cnt
from customer_genre_cnt
where genre_cnt >= 3
order by genre_cnt desc, customer_id;

	
-- Question 11 

select 
	g.name as genre_name,
	sum(il.quantity*il.unit_price) as total_revenue,
	dense_rank() over(order by sum(il.quantity*il.unit_price) desc) as sales_rnk
from genre g 
join track t
on g.genre_id = t.genre_id 
join invoice_line il 
on il.track_id = t.track_id
join invoice i 
on il.invoice_id = i.invoice_id
where i.billing_country = 'USA'
group by g.name;



-- Question 12 

select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as cust_name
from    
customer c 
join invoice i 
on c.customer_id = i.customer_id 
join invoice_line il 
on il.invoice_id = i.invoice_id
where i.invoice_date <= current_date()- interval 3 month
group by c.customer_id;




-- Subjective Questions 

-- Question 1

select
	g.name as genre_name,
	al.title as album_title,
	sum(il.quantity * t.unit_price) as total_sales,
	dense_rank() over (order by sum(il.quantity * t.unit_price) desc) as sales_rank
from track t
join album al on t.album_id = al.album_id
join invoice_line il on t.track_id = il.track_id
join invoice inv on il.invoice_id = inv.invoice_id
join customer cust on inv.customer_id = cust.customer_id
join genre g on t.genre_id = g.genre_id
where cust.country = 'USA'
group by genre_name, album_title
order by sales_rank
limit 3;



-- Question 2 

select
    g.name as genre_name,
    sum(il.quantity) as total_Quantity
from track t
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id
join genre g on t.genre_id = g.genre_id
where c.country <> "USA"
group by genre_name
order by total_Quantity desc;


-- Question 3

WITH CustomerTenure AS (
    -- Step 1: Find the first and last purchase for each customer
    SELECT 
        customer_id,
        MIN(invoice_date) as first_purchase,
        MAX(invoice_date) as latest_purchase,
        COUNT(invoice_id) as total_orders,
        SUM(total) as total_spent
    FROM invoice
    GROUP BY 1
),
Classification AS (
    -- Step 2: Classify customers (Example: Older than the median start date = Long-term)
    -- For Chinook, we'll split them by the year of their first purchase
    SELECT 
        *,
        CASE 
            WHEN first_purchase < '2011-01-01' THEN 'Long-term'
            ELSE 'New/Recent'
        END AS customer_segment
    FROM CustomerTenure
)
-- Step 3: Compare behavior
SELECT 
    customer_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(total_orders), 2) AS avg_frequency,
    ROUND(AVG(total_spent), 2) AS avg_lifetime_value,
    ROUND(SUM(total_spent) / SUM(total_orders), 2) AS avg_basket_size
FROM Classification
GROUP BY 1;




-- Question 4 

WITH TrackGenres AS (
    -- Get the genre for every track in every invoice
    SELECT 
        il.invoice_id,
        g.name AS genre_name
    FROM invoice_line il
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
)
SELECT 
    a.genre_name AS genre_a, 
    b.genre_name AS genre_b, 
    COUNT(*) AS times_bought_together
FROM TrackGenres a
JOIN TrackGenres b ON a.invoice_id = b.invoice_id
WHERE a.genre_name < b.genre_name -- Avoid duplicates (A,B and B,A) and self-pairing
GROUP BY 1, 2
ORDER BY times_bought_together DESC
LIMIT 10;

-- Question 5 


WITH regional_metrics AS (
    SELECT 
        c.country,
        c.customer_id,
        SUM(i.total) AS total_spent,
        MAX(i.invoice_date) AS last_purchase,
        -- Instead of CURRENT_DATE, we use the MAX date from the whole table
        DATEDIFF((SELECT MAX(invoice_date) FROM invoice), MAX(i.invoice_date)) AS recency
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 1, 2
),
regional_summary AS (
    SELECT 
        country,
        COUNT(customer_id) AS customer_count,
        ROUND(AVG(total_spent), 2) AS avg_customer_value,
        -- Calculate Churn Rate: % of customers with no purchase in > 180 days
        ROUND(SUM(CASE WHEN recency > 180 THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_id), 2) AS churn_rate_pct
    FROM regional_metrics
    GROUP BY 1
)
SELECT * FROM regional_summary
ORDER BY customer_count DESC, avg_customer_value DESC;

-- Question 6 



WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        MAX(i.invoice_date) AS last_purchase_date,
        COUNT(i.invoice_id) AS total_orders,
        SUM(i.total) AS total_spent,
        DATEDIFF(CURRENT_DATE(), MAX(i.invoice_date)) AS days_since_last_purchase
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 1, 2, 3
)
SELECT 
    customer_name,
    country,
    total_orders,
    total_spent,
    days_since_last_purchase,
    CASE 
        WHEN days_since_last_purchase > 180 THEN 'High Risk (Churned)'
        WHEN days_since_last_purchase > 90 THEN 'Medium Risk (Lapsing)'
        WHEN total_spent < 10 AND total_orders = 1 THEN 'Low Value / One-time Buyer'
        ELSE 'Active / Loyal'
    END AS risk_profile
FROM customer_metrics
ORDER BY days_since_last_purchase DESC;
-- Question 7 
WITH CustomerMetrics AS (
    SELECT 
        c.customer_id,
        concat(c.first_name,' ',c.last_name) AS name,
        (TIMESTAMPDIFF(MONTH, MIN(i.invoice_date), MAX(i.invoice_date)) + 1) AS tenure_months,
        COUNT(i.invoice_id) AS total_orders,
        SUM(i.total) AS total_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 1, 2
),
LTV_Projection AS (
    SELECT *,
        (total_spent / tenure_months) AS monthly_avg_spend,

        ((total_spent / tenure_months) * 24) AS projected_24mo_ltv
    FROM CustomerMetrics)
SELECT name,
    total_spent AS historical_ltv,
    ROUND(monthly_avg_spend, 2) AS monthly_velocity,
    ROUND(projected_24mo_ltv, 2) AS future_potential,
    CASE 
        WHEN monthly_avg_spend > 5 THEN 'Platinum (High Velocity)'
        WHEN total_spent > 45 THEN 'Gold (High History)'
        ELSE 'Silver (Low Engagement)'
    END AS segment
FROM LTV_Projection
ORDER BY projected_24mo_ltv DESC;

-- Question 10

ALTER TABLE album
ADD ReleaseYear INTEGER;







-- Question 11 

SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(AVG(customer_total_spent), 2) AS avg_spent_per_customer,
    ROUND(AVG(total_tracks_per_customer), 2) AS avg_tracks_per_customer
FROM customer c
JOIN (
    -- Subquery to aggregate data at the individual customer level first
    SELECT 
        customer_id, 
        SUM(total) AS customer_total_spent,
        (SELECT SUM(quantity) FROM invoice_line il 
         JOIN invoice i2 ON il.invoice_id = i2.invoice_id 
         WHERE i2.customer_id = i.customer_id) AS total_tracks_per_customer
    FROM invoice i
    GROUP BY customer_id
) AS customer_orders ON c.customer_id = customer_orders.customer_id
GROUP BY c.country
ORDER BY avg_spent_per_customer DESC;

