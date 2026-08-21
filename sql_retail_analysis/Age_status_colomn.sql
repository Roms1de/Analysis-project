select 
	case 
		when age <= 30 then 'young'
		when age > 30 and age <= 50 then 'mature'
		when age > 50 then 'elderly'
	end as cust_status,
	sum(total_amount) as revenue,
	count(customer_id) as count_cust,
	sum(total_amount) / count(customer_id) as revenue_per_cust
from sales
group by cust_status