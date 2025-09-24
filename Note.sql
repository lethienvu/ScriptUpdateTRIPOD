USE Paradise_TRIPOD_20250921
GO
if object_id('[dbo].[fn_GetExchangeRateInSalaryPeriod]') is null
	EXEC('CREATE FUNCTION [dbo].[fn_GetExchangeRateInSalaryPeriod]() RETURNS TABLE AS RETURN (SELECT 1 as Test)')
GO

ALTER FUNCTION [dbo].[fn_GetExchangeRateInSalaryPeriod]
(
	@LoginId int
	,@Fromdate date
	,@todate date
)
RETURNS TABLE
AS
RETURN
(
	select EmployeeID,DivisionID,c.CurrencyCode,cs.DateEffect,cs.ExchangeRate,cs.Note
	from dbo.fn_DivDepSecPos_ByDate(@todate) div
	cross join(select distinct CurrencyCode from tblCurrencySetting ) c
	cross apply(
		select MAX(DateEffect)DateEffect
		from tblCurrencySetting cs1
		where cs1.CurrencyCode = c.CurrencyCode
		and cs1.DateEffect <= @todate
	) de
	inner join tblCurrencySetting cs on de.DateEffect = cs.DateEffect and cs.CurrencyCode = c.CurrencyCode
)
GO