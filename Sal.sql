
if object_id('[dbo].[sp_foreignSalarySummary]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_foreignSalarySummary] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_foreignSalarySummary] @LoginID INT = 3, @Month INT, @Year INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT f.EmployeeID, FullName, HireDate, LastWorkingDate, CAST(0 AS INT) Prio, f.DepartmentID, f.DivisionID, f.PositionID, s.SectionID, s.SectionName, ROW_NUMBER() OVER (
			ORDER BY f.EmployeeID
			) STTView, d.DepartmentName, p.PositionNameEN PositionName, f.CostCenter, cc.CostCenterName, CASE
			WHEN ISNULL(f.NationID, 234) = 234
				THEN 'Domestic'
			ELSE 'Foreign'
			END AS EmployeeClass, CASE
			WHEN et.isLocalStaff = 1
				THEN N'Indirect Labor'
			ELSE N'Direct Labor'
			END AS EmployeeType
	INTO #tmpEmployeeList
	FROM dbo.fn_vtblEmployeeList_ByDate(@ToDate, '-1', @LoginId) f
	LEFT JOIN tblSection s ON s.SectionID = f.SectionID
	LEFT JOIN tblDepartment d ON d.DepartmentID = f.DepartmentID
	LEFT JOIN tblPosition p ON p.PositionID = f.PositionID
	LEFT JOIN tblCostCenter cc ON cc.CostCenter = f.CostCenter
	LEFT JOIN tblEmployeeType et ON et.EmployeeTypeID = f.EmployeeTypeID

	SELECT s.*, sh.ExchangeRate_Contract
	INTO #Sal_Sal_Detail
	FROM tblSal_Sal_Detail s
	INNER JOIN #tmpEmployeeList te ON s.EmployeeID = te.EmployeeID
	LEFT JOIN tblSalaryHistory sh ON sh.SalaryHistoryID = s.SalaryHistoryID
	WHERE s.Year = @Year AND s.Month = @Month AND ISNULL(s.IsNet, 0) = 1

	DELETE
	FROM #tmpEmployeeList
	WHERE EmployeeID NOT IN (
			SELECT EmployeeID
			FROM tblSal_Sal_Detail s
			WHERE s.Year = @Year AND s.Month = @Month --AND ISNULL(isNET, 0) = 1
			)

	SELECT al.EmployeeID, al.AllowanceID, SUM(ROUND(al.Amount, 0)) Amount, SUM(al.DefaultAmount) DefaultAmount
	INTO #Allowance
	FROM tblSal_Allowance_Detail al
	INNER JOIN #tmpEmployeeList te ON al.EmployeeID = te.EmployeeID
	WHERE al.Year = @Year AND al.Month = @Month
	GROUP BY al.EmployeeID, al.AllowanceID

	--SELECT * FROM tblAllowanceSetting
	SELECT s.*
	INTO #AttendanceSummary
	FROM tblAttendanceSummary s
	INNER JOIN #tmpEmployeeList te ON s.EmployeeID = te.EmployeeID
	WHERE s.Year = @Year AND s.Month = @Month

	SELECT s.*
	INTO #tblSal_Insurance
	FROM tblSal_Insurance s
	INNER JOIN #tmpEmployeeList t ON s.EmployeeID = t.EmployeeID
	WHERE Year = @Year AND Month = @Month

--'Tháng 7 và 8 là người nn chỉ cần đóng BHYT, từ tháng 9 trở đi BHXH 8% người lao động đóng luôn nhé'
    IF(@Month IN (7, 8) AND @Year = 2025)
    BEGIN
        UPDATE #tblSal_Insurance SET EmployeeTotal = EmployeeHI
    END

	SELECT st.*
	INTO #tblSal_Tax
	FROM tblSal_Tax st
	INNER JOIN #tmpEmployeeList te ON st.EmployeeID = te.EmployeeID
	WHERE st.Year = @Year AND st.Month = @Month

	SELECT ROW_NUMBER() OVER (
			ORDER BY Raw_BasicSalary DESC, HireDate
			) AS STT, s.EmployeeID, s.FullName, s.DepartmentName, sal.Raw_BasicSalary, sal.Raw_BasicSalary * sal.ExchangeRate_Contract AS SalaryContract, ats.WorkingHrs_Total, RegularAmt / Raw_ExchangeRate AS Net_RegularAmt, RegularAmt, CAST(NULL AS MONEY) AS percent15HouseRent, house.Amount AS House, house.Amount AS HouseCalcTax, meal.Amount AS MealCalcTax, ins.EmployeeUI, ins.EmployeeSI, ins.EmployeeHI, ins.EmployeeSI, ins.CompanySI, ins.CompanyHI, tax.EmployeeExemption, tax.FamilyExemption, tax.IncomeTaxable, tax.TaxAmt, tax.TaxableIncome_SalaryOnly, tax.TaxAmt_SalaryOnly, ISNULL(tax.TaxAmt, 0) - ISNULL(tax.TaxAmt_SalaryOnly, 0) AS CompanyPay, ISNULL(RegularAmt, 0) - ISNULL(ins.EmployeeTotal, 0) - ISNULL(tax.TaxAmt_SalaryOnly, 0) AS GrossTakeHome, (ISNULL(RegularAmt, 0) - ISNULL(ins.EmployeeTotal, 0) - ISNULL(tax.TaxAmt_SalaryOnly, 0)) / Raw_ExchangeRate AS Net_GrossTakeHome
	FROM #tmpEmployeeList s
	INNER JOIN #Sal_Sal_Detail sal ON s.EmployeeID = sal.EmployeeID
	LEFT JOIN #AttendanceSummary ats ON s.EmployeeID = ats.EmployeeID
	LEFT JOIN #Allowance house ON s.EmployeeID = house.EmployeeID AND house.AllowanceID = 17
	LEFT JOIN #Allowance meal ON s.EmployeeID = meal.EmployeeID AND meal.AllowanceID = 16
	LEFT JOIN #tblSal_Insurance ins ON s.EmployeeID = ins.EmployeeID
	LEFT JOIN #tblSal_Tax tax ON s.EmployeeID = tax.EmployeeID
	ORDER BY Raw_BasicSalary DESC, HireDate

	SELECT CONCAT (@Year, ' ', FORMAT(DATEFROMPARTS(@Year, @Month, 1), 'MMMM', 'en-US')) AS MonthYear

	SELECT WorkingDays_Std * 8 AS STD_WorkingDays
	FROM tblWorkingDaySetting
	WHERE Year = @Year AND Month = @Month AND EmployeeTypeID = 0

    SELECT N' Exchange rate on ' + CONCAT (DAY(cs.DateEffect), ' ', FORMAT(DATEFROMPARTS(YEAR(cs.DateEffect), MONTH(cs.DateEffect), 1), 'MMMM', 'en-US'))
    FROM tblCurrencySetting cs
    INNER JOIN (SELECT MAX(DateEffect) DateEffect
                FROM tblCurrencySetting cs1
                WHERE cs1.CurrencyCode = 'USD' AND cs1.DateEffect <= @todate) de ON cs.DateEffect = de.DateEffect
    UNION ALL
    SELECT N' 1 USD = ' + CAST(cs.ExchangeRate AS NVARCHAR(20)) 
    FROM tblCurrencySetting cs
    INNER JOIN (SELECT MAX(DateEffect) DateEffect
                FROM tblCurrencySetting cs1
                WHERE cs1.CurrencyCode = 'USD' AND cs1.DateEffect <= @todate) de ON cs.DateEffect = de.DateEffect


	CREATE TABLE #ExportConfig (ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200), SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200))

    INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (2, 'Table_NonInsert', 'E16', 0, 0)

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex)
	SELECT 0, 'Table|ZeroMeanNull=1 ', 'B11', 0

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (1, 'Table_NonInsert', 'B3', 0, 0)

    INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (3, 'Table_NonInsert', 'AB1', 0, 0)

	SELECT *
	FROM #ExportConfig
END
	--exec sp_foreignSalarySummary 3,7,2025
GO
