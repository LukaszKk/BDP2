select 
	OrderDate, 
	count(OrderDate) as Order_cnt
from dbo.FactInternetSales
group by OrderDate
having count(OrderDate) < 100
order by Order_cnt desc;
