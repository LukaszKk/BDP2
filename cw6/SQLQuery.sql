drop table if exists dbo.stg_dimemp;

select EmployeeKey, FirstName, LastName, Title 
into dbo.stg_dimemp
from dbo.DimEmployee
where EmployeeKey >= 270 and EmployeeKey <= 275;

create table dbo.scd_dimemp 
(EmployeeKey int, FirstName nvarchar(50), 
LastName nvarchar(50), Title nvarchar(50),
StartDate datetime, EndDate datetime);