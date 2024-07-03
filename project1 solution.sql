select * from credit_card_transcations;
--- chnaged the datatypes of the columns into amount(varchar into decimal, transaction_date varchar into date)
ALTER TABLE credit_card_transcations
 ALTER COLUMN amount decimal(18,2)
 ALTER COLUMN transaction_date date;

--1--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with totalspend as (
select city,  SUM(CAST(amount AS DECIMAL(18, 2)))  as total_spend
from credit_card_transcations
group by city
)
,topcity as 
(
select city, total_spend,
rank()over (order by total_spend desc) as rank_spend
from totalspend)

select city,total_spend
,(total_spend * 100.00/ (SELECT SUM(total_spend) FROM totalspend)) AS PercentageContribution
from topcity
WHERE rank_spend <= 5;

--2- write a query to print highest spend month and amount spent in that month for each card type

select * from credit_card_transcations;

with cte1 as (
select card_type ,datepart(year,transaction_date) as yt,datepart(month,transaction_date) as month_spend,sum(amount) as totalspend
from credit_card_transcations
group by datepart(year,transaction_date), datepart(month,transaction_date),card_type)
,cte2 as 
(
select * ,
rank() over(partition by card_type order by totalspend desc) as rn
from cte1)

select * from cte2
where rn =1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte1 as
(select *, 
sum(amount) over (partition by card_type order by transaction_id,transaction_date ) as totalspend
from credit_card_transcations),
cte2 as (select *, rank() over(partition by card_type order by totalspend) as rn  
from cte1 where totalspend >= 1000000) 
select * from cte2 
where rn=1


--4- write a query to find city which had lowest percentage spend for gold card type

with cte as (
select top 1 city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transcations
group by city,card_type)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio;

--5 write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type
--(example format : Delhi , bills, Fuel)


select * from credit_card_transcations;

with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transcations
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;

--6-write a query to find percentage contribution of spends by females for each expense type


select  exp_type,sum(case when gender='F' then amount else 0 end)*1.0/ SUM(amount) AS PercentageContribution
from credit_card_transcations
group by exp_type
order by PercentageContribution desc

--7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte1 as (
select exp_type,card_type,DATEPART(year,transaction_date) as yt,datepart(month, transaction_date) as mt,
sum(amount) as total 
from credit_card_transcations
group by DATEPART(year,transaction_date) ,datepart(month, transaction_date),exp_type,card_type)
,
cte2 as (select *
,lag(total,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte1)
select  top 1*,
(total-prev_mont_spend)as mom_growth
from cte2
where prev_mont_spend is not null and yt=2014 and mt=01;

--8-during weekends which city has highest total spend to total no of transcations ratio 


with cte1 as(
select count(*) as total_count, 
city,sum(amount) as total
from credit_card_transcations
where DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')
group by city) 
,cte2 as (
select *,total/ total_count AS transaction_ratio
from cte1)
select top 1 * 
from cte2
ORDER BY transaction_ratio DESC;


-- 10-which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transcations)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 








