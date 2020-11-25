select 
	OrderDate,
	Order_cnt,
	productKey,
	UnitPrice
from
(
	select
		OrderDate,
		count(OrderDate) over(
			partition by OrderDate
		) as Order_cnt,
		row_number() over(
			partition by OrderDate
			Order by UnitPrice desc
		) as ranks,
		productKey,
		UnitPrice
	from dbo.FactInternetSales
) as a
where ranks <= 3
order by Order_cnt desc;