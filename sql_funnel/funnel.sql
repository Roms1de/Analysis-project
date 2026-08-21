-- воронка продаж, различные этапы воронки за последнии 30 дней записей

with funnel_Stages as (
	select 
		count(distinct case when event_type = 'page_view' then user_id end) as stage_1,
		count(distinct case when event_type = 'add_to_cart' then user_id end) as stage_2,
		count(distinct case when event_type = 'checkout_start' then user_id end) as stage_3,
		count(distinct case when event_type = 'payment_info' then user_id end) as stage_4,
		count(distinct case when event_type = 'purchase' then user_id end) as stage_5
	from user_events
	where event_date::date >= 
		((select max(event_date::date) as max_date from user_events) - INTERVAL '30 days')
	)

select stage_1, stage_2, stage_3, stage_4, stage_5 from funnel_Stages;




-- конверсия в каждый этап

with funnel_Stages as (
	select 
		count(distinct case when event_type = 'page_view' then user_id end) as stage_1_view,
		count(distinct case when event_type = 'add_to_cart' then user_id end) as stage_2_cart,
		count(distinct case when event_type = 'checkout_start' then user_id end) as stage_3_checkout,
		count(distinct case when event_type = 'payment_info' then user_id end) as stage_4_info,
		count(distinct case when event_type = 'purchase' then user_id end) as stage_5_purchase
	from user_events
	where event_date::date >= 
		((select max(event_date::date) as max_date from user_events) - INTERVAL '30 days')
	)

select 
	stage_1_view,
	round((stage_2_cart * 100 / stage_1_view), 2) as view_to_cart_rate,
	stage_2_cart,
	round((stage_3_checkout * 100 / stage_2_cart), 2) as cart_to_checkout_rate,
	stage_3_checkout,
	round((stage_4_info * 100 / stage_3_checkout), 2) as checkout_to_payinfo_rate,
	stage_4_info,
	round((stage_5_purchase * 100 / stage_4_info), 2) as info_to_purchase_rate,
	stage_5_purchase
from 
	funnel_Stages;

-- Хорошая конверсия из информации об оплате в покупку (>90%). Вопрос как можно было бы 
-- повысить конверсию перехода в корзину (<31%).


-- воронка по источнику притока пользователей

with funnel_Stages as (
	select 
		traffic_source,
		count(distinct case when event_type = 'page_view' then user_id end) as view,
		count(distinct case when event_type = 'add_to_cart' then user_id end) as cart,
		count(distinct case when event_type = 'purchase' then user_id end) as purchase
	from user_events
	where event_date::date >= 
		((select max(event_date::date) as max_date from user_events) - INTERVAL '30 days')
	group by traffic_source
	)

select 
	traffic_source,
	view,
	cart,
	purchase,
	round(purchase * 100 / view) as view_to_purchase_rate
from 
	funnel_Stages
order by view_to_purchase_rate desc, view desc;

-- по текущим данным видно, что из социальных сетей большой приток пользователей, но покупки они
-- совершают редко (<10%). В то время как приток из email расслок в 3 раза меньше, но 
-- имеет >30% конверсию в покупку.
-- Отделу маркетинга, вероятно, стоит пересмотреть траты на превлечение пользователей из сотсетей, 
-- и направить этот бюджет на имеил рассылки


-- Среднее время просмотра этапов к покупке

with user_journey as (
	select 
		user_id,
		min(case when event_type = 'page_view' then event_date end) as view_time,
		min(case when event_type = 'add_to_cart' then event_date end) as cart_time,
		min(case when event_type = 'purchase' then event_date end) as purchase_time
	from user_events
	where event_date::date >= 
		((select max(event_date::date) as max_date from user_events) - INTERVAL '30 days')
	group by user_id
	having min(case when event_type = 'purchase' then event_date end) is not null
	)

select 
	count(*) as users,
	round(avg(EXTRACT(EPOCH FROM (cart_time - view_time)) / 60), 2) as view_to_cart_time,
	round(avg(EXTRACT(EPOCH FROM (purchase_time - cart_time)) / 60), 2) as cart_to_purchase_time,
	round(avg(EXTRACT(EPOCH FROM (purchase_time - view_time)) / 60), 2) as total_journey_time
from user_journey;

-- revenue воронки продаж

with funnel_revenue as (
	select 
		count(distinct case when event_type = 'page_view' then user_id end) as total_visitors,
		count(distinct case when event_type = 'purchase' then user_id end) as total_buyers,
		round(sum(case when event_type = 'purchase' then amount end), 2) as total_revenue,
		count(case when event_type = 'purchase' then 1 end) as total_orders
 	from user_events
	where event_date::date >= 
		((select max(event_date::date) as max_date from user_events) - INTERVAL '30 days')
	)

select 
	total_visitors,
	total_buyers,
	total_orders,
	total_revenue,
	round(total_revenue / total_orders, 2) as AOV, -- avg_order_value
	round(total_revenue / total_buyers, 2) as ARPPU, -- avg_revenue_per_paying_user
	round(total_revenue / total_visitors, 2) as ARPU -- avg_revenue_per_user
from funnel_revenue;

-- Получены ценные метрики, которые можно в другие отделы для оценки роста бизнеса  
-- Например сравнив CAC с ARPU 

	







	

