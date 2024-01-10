create database telangana_govt_db;
use telangana_govt_db;
describe dim_date;
select * from dim_date;
alter table dim_date modify column month date; 
alter table dim_date modify column fiscal_year year; 
describe dim_districts;
alter table dim_districts modify column dist_code varchar(255);
alter table dim_districts modify column district varchar(255); 
delete from dim_districts where dist_code = "dist_code";
describe fact_stamps;
select * from fact_stamps;
alter table fact_stamps modify column dist_code varchar(255);
alter table fact_stamps modify column month date;
alter table fact_stamps modify column documents_registered_cnt int;
alter table fact_stamps modify column documents_registered_rev bigint;
alter table fact_stamps modify column estamps_challans_cnt int;
alter table fact_stamps modify column estamps_challans_rev bigint;
select * from fact_transport;
describe fact_transport;
alter table fact_transport modify column dist_code varchar(255);
alter table fact_transport modify column month date;
select* from fact_ts_ipass;
describe fact_ts_ipass;
UPDATE fact_ts_ipass
SET month = DATE_FORMAT(STR_TO_DATE(month, '%d-%m-%Y'), '%Y-%m-%d');
alter table fact_ts_ipass modify column month date;
alter table fact_ts_ipass modify column dist_code varchar(255);
alter table fact_ts_ipass modify column `investment in cr` bigint;

-- Stamp Registration

-- Top 5 districts with highest and lowest total revenue generated from documents and stamps between FY 2019 and FY 2022?
-- highest
select d.district ,sum(f.documents_registered_rev+ f.estamps_challans_rev) as total_revenue 
from fact_stamps f
join dim_districts d 
on d.dist_code = f.dist_code
join dim_date dd
on dd.month = f.month
where dd.fiscal_year between 2019 and 2022
group by d.district
order by total_revenue desc
limit 5;


-- lowest
select d.district ,sum(f.documents_registered_rev+ f.estamps_challans_rev) as total_revenue 
from fact_stamps f
join dim_districts d 
on d.dist_code = f.dist_code
join dim_date dd
on dd.month = f.month
where dd.fiscal_year between 2019 and 2022
group by d.district
order by total_revenue asc
limit 5;

-- How does the revenue generated from document registration vary across districts in Telangana?
select distinct(dim_districts.district), sum(fact_stamps.documents_registered_rev) as Total_Revenue
from fact_stamps
join dim_districts on fact_stamps.dist_code = dim_districts.dist_code
group by dim_districts.district
order by Total_Revenue desc;

-- List down the top 5 districts that showed the highest document registration revenue growth between FY 2019 and 2022
select distinct(d.district), sum(f.documents_registered_rev) as Total_Revenue, (sum(f.documents_registered_rev)*100/(select sum(documents_registered_rev) from fact_stamps)) as percentage_total
from fact_stamps f
join dim_districts d on f.dist_code = d.dist_code
join dim_date dd
on dd.month = f.month
where dd.fiscal_year between 2019 and 2022
group by d.district
order by Total_Revenue desc
limit 5;

-- How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts? List down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022?
select distinct d.district, sum(f.documents_registered_rev) as Documents_revenue, sum(f.estamps_challans_rev) as Estamps_revenue
from fact_stamps f
join dim_districts d on f.dist_code = d.dist_code
join dim_date dd
on dd.month = f.month
where dd.fiscal_year = 2022
group by d.district
having sum(f.estamps_challans_rev)> 1 * sum(f.documents_registered_rev)
order by sum(f.estamps_challans_rev) desc
limit 5;
---
-- Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp challan? If so, what suggestions would you propose to the government?
select date_format(month, '%Y-%m') as period, 'Before Implementation' AS implementation_phase, sum(documents_registered_cnt) as Documents_Registration_Count, sum(estamps_challans_cnt) as Estamps_challans_count
from fact_stamps
where month < "2020-01-01"
group by month
union all
select date_format(month, '%Y-%m') as period, 'After Implementation' as implementation_phase, sum(documents_registered_cnt), sum(estamps_challans_cnt)
from fact_stamps
where month >= "2020-01-01"
group by month;

-- Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022.
select dim_districts.district, sum(fact_stamps.estamps_challans_rev) as total_revenue,
case
when ntile(3) over (order by sum(fact_stamps.estamps_challans_rev)) = 1 then 'Low'
when ntile(3) over (order by sum(fact_stamps.estamps_challans_rev)) = 2 then 'Medium'
when ntile(3) over (order by sum(fact_stamps.estamps_challans_rev)) = 3 then 'High'
end as revenue_type
from fact_stamps
join dim_districts
on fact_stamps.dist_code = dim_districts.dist_code
join dim_date
on fact_stamps.month = dim_date.month
where (dim_date.fiscal_year) between "2021" and "2022" 
group by dim_districts.district;


-- Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts. Are there any months or seasons that consistently show higher or lower sales rate, and if yes, what could be the driving factors? (Consider Fuel-Type category only)
select distinct monthname(month) as month, sum(fuel_type_petrol+ fuel_type_diesel+fuel_type_electric+fuel_type_others) as vehicle_sales
from fact_transport
group by monthname(month)
order by vehicle_sales desc;

-- How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different districts? Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis.
select distinct(d.district), sum(t.vehicleClass_MotorCycle) as MotorCycle, sum(t.vehicleClass_MotorCar) as MotorCar,sum(t.vehicleClass_AutoRickshaw) as AutoRickshaw,sum(t.vehicleClass_Agriculture) as Agriculture
from fact_transport t
join dim_districts d 
on t.dist_code = d.dist_code
join dim_date dd
on t.month = dd.month
where dd.fiscal_year = 2022
group by d.district
order by sum(t.vehicleClass_MotorCycle) desc;

--  List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022? (Consider and compare categories: Petrol, Diesel and Electric)

-- Top 3 district with highest sales in 2022
select distinct d.district,sum(fuel_type_petrol), sum(fuel_type_diesel), sum(fuel_type_electric)
from fact_transport t
join dim_districts d
on t.dist_code = d.dist_code
join dim_date dd
on t.month = dd.month
where dd.fiscal_year = '2022' 
group by d.district
order by  sum(fuel_type_diesel) desc
limit 3;

-- Top 3 district with lowest sales in 2022
select distinct d.district,sum(fuel_type_petrol), sum(fuel_type_diesel), sum(fuel_type_electric)
from fact_transport t
join dim_districts d
on t.dist_code = d.dist_code
join dim_date dd
on t.month = dd.month
where dd.fiscal_year = '2022' 
group by d.district
order by sum(fuel_type_petrol) asc 
limit 3;

-- List down the top 5 sectors that have witnessed the most significant investments in FY 2022.
select (d.fiscal_year),f.sector, sum(f.`investment in cr`) as investment_value
from fact_ts_ipass f
join dim_date d
on f.month = d.month
where (d.fiscal_year) = 2022
group by d.fiscal_year, f.sector
order by sum(f.`investment in cr`) desc
limit 5;

-- List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022?
select ds.district, sum(f.`investment in cr`) as total_investment
from fact_ts_ipass f
join dim_date d
on f.month = d.month
join dim_districts ds
on ds.dist_code = f.dist_code
where (d.fiscal_year) between '2019' and '2022'
group by ds.district
order by sum(f.`investment in cr`) desc
limit 3;

-- Are there any particular sectors that have shown substantial investment in multiple districts between FY 2021 and 2022?
select  fi.sector,  count(distinct d.district) as District_Count, sum(fi.`investment in cr`) as Investment
from fact_ts_ipass fi
join dim_districts d
on d.dist_code = fi.dist_code
join dim_date dd
on dd.month = fi.month
where dd.fiscal_year between 2021 and 2022
group by fi.sector
order by count(d.district) desc;

-- Can we identify any seasonal patterns or cyclicality in the investment trends for specific sectors? Do certain sectors experience higher investments during particular months?
select  fi.sector, dd.Mmm, sum(fi.`investment in cr`) as Total_Investment
from fact_ts_ipass fi
join dim_date dd 
on dd.month = fi.month
group by fi.sector, dd.Mmm
order by Total_Investment desc;
