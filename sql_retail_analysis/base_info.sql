select 
	count(*) as all_rows,
	count(DISTINCT customer_id) as uniq_customers,
	min(date) as min_date,
	max(date) as max_date,
	sum(total_amount) as revenue
from sales;



	