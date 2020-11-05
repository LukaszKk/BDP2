CREATE OR ALTER PROCEDURE procedura @YearsAgo INTEGER
AS
BEGIN
select fcr.*, dc.CurrencyAlternateKey 
from dbo.FactCurrencyRate as fcr 
join dbo.DimCurrency as dc on fcr.CurrencyKey=dc.CurrencyKey 
where DATEDIFF(year, fcr.Date, GETDATE()) = @YearsAgo
and (dc.CurrencyAlternateKey = 'GBP' or dc.CurrencyAlternateKey = 'EUR');
END;
