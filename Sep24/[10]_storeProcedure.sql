
if object_id('[dbo].[sp_SalaryHistory_List]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_SalaryHistory_List] as select 1')
GO

--EXEC sp_salaryhistory_list @LoginID=3,@LanguageID='EN',@ViewAllRecord=0,@AddNewSalRecord=0,@Confirm=N'',@EmployeeID='-1'
ALTER PROCEDURE [dbo].[sp_SalaryHistory_List] (@LoginID INT, @LanguageID VARCHAR(2) = 'vn', @ViewAllRecord BIT = 0, @AddNewSalRecord BIT = 0, @Confirm NVARCHAR(50) = N'', @EmployeeID VARCHAR(20) = '-1', @IsExport BIT = 0, @OptionView INT = 0)
AS
BEGIN
	SET NOCOUNT ON;

	IF @IsExport = 1
	BEGIN
		EXEC Template_SalaryHistory_List @LoginID = @LoginID, @LanguageID = @LanguageID, @ViewAllRecord = @ViewAllRecord, @AddNewSalRecord = 0, @EmployeeID = @EmployeeID

		RETURN
	END

	UPDATE s
	SET CurrencyCode = UPPER(CurrencyCode)
	FROM tblSalaryHistory s
	WHERE CurrencyCode <> UPPER(CurrencyCode)

	-- SELECT in Correct columns order
	DECLARE @Query NVARCHAR(max), @TotalIncomeQry NVARCHAR(max), @ColumnNameCur VARCHAR(255), @SalCalRuleId INT = 1
	DECLARE @OnlyCurrent BIT = 0, @IsHasInsSalary BIT = 1

	SELECT @SalCalRuleId = isnull(Value, 1)
	FROM tblParameter
	WHERE Code = 'SalCalRuleID'

	IF NOT EXISTS (
			SELECT 1
			FROM tblParameter
			WHERE Value = 1 AND Code = 'SI_NEED_INPUTSALARY'
			)
		SET @IsHasInsSalary = 0

	IF @ViewAllRecord = 0
		SET @OnlyCurrent = 1
	SET @OnlyCurrent = ISNULL(@OnlyCurrent, 0)

	DECLARE @ViewDate DATE = GetDate(), @StopUPDATE BIT = 0

	IF len(rtrim(ltrim(isnull(@Confirm, '')))) = 0
		SET @AddNewSalRecord = 0

	--lay danh sach nhan vien
	SELECT te.EmployeeID, FullName, DivisionID, DepartmentID, PositionID, SectionID, GroupID, HireDate, TerminateDate, EmployeeStatusID, BankCode, AccountNo, TaxRegNo
	INTO #tblEmployee
	FROM fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID) te
	WHERE ISNULL(@OptionView, '-1') = '-1' OR @OptionView = 0 OR (ISNULL(@OptionView, 0) = 1 AND ISNULL(IsForeign, 0) = 0) OR (ISNULL(@OptionView, 0) = 2 AND ISNULL(IsForeign, 0) = 1)

	IF @AddNewSalRecord = 1
	BEGIN
		SELECT EmployeeID, DATE, Salary, Note, @SalCalRuleId SalCalRuleID
		INTO #tblSalaryHistoryTmpInsert
		FROM tblSalaryHistory
		WHERE 1 = 0

		--SELECT tr.EmployeeID, sh.DIL_AL,sh.MEAL_AL, sh.MEAL_AL2, from tmpEmployeeTree tr left join dbo.fn_CurrentSalaryHistoryIDByDate(@ViewDate) cs on tr.EmployeeID = cs.EmployeeID left join tblSalaryHistory sh on cs.SalaryHistoryID = sh.SalaryHistoryID
		INSERT INTO #tblSalaryHistoryTmpInsert (EmployeeID, DATE, Salary, SalCalRuleID, Note)
		SELECT tr.EmployeeID, @ViewDate, 0, @SalCalRuleId, N'system add new salary at: ' + CONVERT(VARCHAR(16), getdate(), 121) + ' ' + @Confirm
		FROM tmpEmployeeTree tr
		WHERE tr.LoginID = @LoginID AND tr.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM #tblEmployee
				WHERE EmployeeStatusID = 20
				) AND NOT EXISTS (
				SELECT 1
				FROM tblSalaryHistory sh
				WHERE sh.EmployeeID = tr.EmployeeID
				) -- and sh.Note like N'system add new salary at:%' and DATEDIFF(day,date,@ViewDate) < 30)
			--SELECT * from #tblSalaryHistoryTmpInsert

		IF (OBJECT_ID('sp_SalaryHistory_ProcessIncrement') IS NULL)
		BEGIN
			EXEC (
					'CREATE PROCEDURE dbo.sp_SalaryHistory_ProcessIncrement
   (
    @StopUPDATE bit output,
    @LoginID int
   )
   as
   BEGIN
    SET NOCOUNT ON;
   END'
					)
		END

		SET @StopUPDATE = 0

		EXEC sp_SalaryHistory_ProcessIncrement @StopUPDATE OUTPUT, @LoginID

		--IF @LoginID = 3 RETURN
		IF @StopUPDATE = 0
		BEGIN
			--INSERT INTO tblSalaryHistory(EmployeeID, Date,Salary,Note)
			--SELECT EmployeeID, Date,Salary,Note from #tblSalaryHistoryTmpInsert
			-- cap nhat cac khoan phu cap khac lay mac dinh ben thong tin luong cu
			SET @Query = 'INSERT INTO tblSalaryHistory(EmployeeID, Date,Salary,Note'

			SELECT @Query += ',' + c.column_name
			FROM Information_Schema.COLUMNS c
			WHERE Table_Name = 'tblsalaryHistory' AND Data_Type NOT IN ('nvarchar', 'varchar') AND column_Name NOT IN ('EmployeeID', 'Date', 'Salary', 'Note', 'SalaryHistoryId')

			SET @Query += ')
   SELECT i.EmployeeID, i.Date,i.Salary,i.Note'

			SELECT @Query += ',sh.' + c.column_name
			FROM Information_Schema.COLUMNS c
			WHERE Table_Name = 'tblsalaryHistory' AND Data_Type NOT IN ('nvarchar', 'varchar') AND column_Name NOT IN ('EmployeeID', 'Date', 'Salary', 'Note', 'SalaryHistoryId')

			SET @Query += '
   from
   #tblSalaryHistoryTmpInsert i
   left join tblSalaryHistory sh on i.EmployeeID = sh.EmployeeId
   left join (
   SELECT s.EmployeeID, max(s.Date) as Date
   from tblsalaryHistory s inner join #tblSalaryHistoryTmpInsert t on s.EmployeeID = t.EmployeeID and s.Date < t.Date
   group by s.EmployeeId
   ) tmp on sh.EmployeeID = tmp.EmployeeID and sh.Date = tmp.Date
   '

			--SELECT @Query RETURN
			EXECUTE (@Query)
		END
	END

	IF (OBJECT_ID('sp_SalaryHistory_ReOderColumn') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE sp_SalaryHistory_ReOderColumn
 (
  @StopUPDATE bit output,
  @LoginID int)
 as
 BEGIN
  SET NOCOUNT ON;
 END'
				)
	END

	SET @StopUPDATE = 0

	EXEC sp_SalaryHistory_ReOderColumn @StopUPDATE OUTPUT, @LoginID

	------------------------------Them vao neu chua co------------------------------
	INSERT INTO tblsalaryHistory (EmployeeID, DATE, IsNet, Salary)
	SELECT EmployeeID, HireDate, 0, 0
	FROM #tblEmployee te
	WHERE te.HireDate IS NOT NULL AND NOT EXISTS (
			SELECT 1
			FROM tblSalaryHistory s
			WHERE te.EmployeeID = s.EmployeeID AND te.HireDate = s.DATE
			) AND @OptionView IN (0, 1) -- chi them nhung nhan vien trong nuoc

	INSERT INTO tblsalaryHistory (EmployeeID, DATE, IsNet, NetSalary)
	SELECT EmployeeID, HireDate, 1, 0
	FROM #tblEmployee te
	WHERE te.HireDate IS NOT NULL AND NOT EXISTS (
			SELECT 1
			FROM tblSalaryHistory s
			WHERE te.EmployeeID = s.EmployeeID AND te.HireDate = s.DATE
			) AND @OptionView IN (2)

	SELECT c.EmployeeID, c.SalaryHistoryID, c.DATE
	INTO #tmpCurrentSalary
	FROM dbo.fn_CurrentSalaryHistoryIDByDate(@ViewDate) c
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployee te
			WHERE c.EmployeeID = te.EmployeeID
			)

	------------------------------cap nhap mot so thong tin khac------------------------------
	UPDATE tblSalaryHistory
	SET PositionID = d.PositionID
	FROM tblSalaryHistory sh
	INNER JOIN tblPositionHistory d ON sh.EmployeeID = d.EmployeeID AND sh.[Date] = d.EffectiveDate
	WHERE COALESCE(sh.PositionID, - 1) <> COALESCE(d.PositionID, - 1) AND sh.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployee
			)

	UPDATE tblSalaryHistory
	SET PositionID = d.PositionID
	FROM tblSalaryHistory sh
	CROSS APPLY (
		SELECT d.EmployeeID, MAX(d.EffectiveDate) ChangedDate
		FROM tblPositionHistory d
		WHERE sh.EmployeeID = d.EmployeeID AND d.EffectiveDate <= sh.[Date]
		GROUP BY d.EmployeeID
		) s
	INNER JOIN tblPositionHistory d ON s.EmployeeID = d.EmployeeID AND s.ChangedDate = d.EffectiveDate
	WHERE sh.EmployeeID = s.EmployeeID AND sh.PositionID IS NULL AND d.PositionID IS NOT NULL AND sh.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployee
			)

	UPDATE tblSalaryHistory
	SET SalCalRuleID = @SalCalRuleId
	WHERE SalCalRuleID IS NULL

	UPDATE tblSalaryHistory
	SET BaseSalRegionalID = CASE
			WHEN DivisionID = 1
				THEN 1
			ELSE 2
			END
	FROM tblSalaryHistory s
	INNER JOIN #tblEmployee te ON s.EmployeeID = te.EmployeeID
	WHERE ISNULL(s.BaseSalRegionalID, 0) = 0

	UPDATE tblSalaryHistory
	SET CurrencyCode = 'USD'
	WHERE IsNET = 1

	UPDATE tblSalaryHistory
	SET InsSalary = NETSalary
	WHERE IsNET = 1 --AND ISNULL(InsSalary, 0) = 0

	UPDATE tblSalaryHistory
	SET Salary = NETSalary
	WHERE IsNET = 1 --AND ISNULL(Salary, 0) = 0

	UPDATE tblSalaryHistory
	SET CurrencyCode = 'VND'
	WHERE IsNET = 0 AND (CurrencyCode IS NULL OR RTRIM(LTRIM(CurrencyCode)) = '')

	IF (OBJECT_ID('sp_SalaryHistory_FinishUpdateOtherInfo') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.sp_SalaryHistory_FinishUpdateOtherInfo
 (
  @StopUPDATE bit output,
  @LoginID int
 )
 as
 BEGIN
  SET NOCOUNT ON;
 END'
				)

	END

	SET @StopUPDATE = 0

	EXEC sp_SalaryHistory_FinishUpdateOtherInfo @StopUPDATE OUTPUT, @LoginID

	------------------------------lay thong tin luong------------------------------
	SELECT *
	INTO #tblSalaryHistory
	FROM tblSalaryHistory s
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployee te
			WHERE s.EmployeeID = te.EmployeeID
			) AND (
			@OnlyCurrent = 0 OR EXISTS (
				SELECT 1
				FROM #tmpCurrentSalary c
				WHERE s.SalaryHistoryID = c.SalaryHistoryID AND s.EmployeeID = c.EmployeeID
				)
			) AND ((@AddNewSalRecord = 1 AND s.Note LIKE N'system add new salary at:%') OR @AddNewSalRecord = 0)

	SELECT al.*
	INTO #tblAllowanceSETting
	FROM tblAllowanceSETting al
	WHERE AllowanceID = 14 --TRIPOD
		--	WHERE isnull(al.Visible, 1) = 1 --and isnull(NotInput,0) = 0

	--IF exists(SELECT 1 from #tblsalaryHistory WHERE IsNet = 1)
	-- SET @IsHasInsSalary  = 1
	SET @Query = '
 SELECT e.EmployeeID, e.FullName, dp.DepartmentName, tsh.PositionID, tsh.Date, tsh.RetroDate ' + CASE
			WHEN @IsHasInsSalary = 1
				THEN ',InsSalary'
			ELSE ''
			END -- ',InsSalary'
		+ '
 ,tsh.Salary '

	SELECT @Query += ',tsh.[' + al.AllowanceCode + ']' + CASE
			WHEN al.IsMutilCurrencyCode = 1
				THEN ',[' + al.AllowanceCode + '_CurrencyCode]'
			ELSE ''
			END
	FROM #tblAllowanceSETting al
	ORDER BY al.Ord

	-- tong luong
	SELECT @TotalIncomeQry = ', isnull(Salary,0) '

	SELECT @TotalIncomeQry += '+ isnull(tsh.[' + al.AllowanceCode + '],0)'
	FROM #tblAllowanceSETting al
	ORDER BY al.Ord

	--SET
	SELECT l.EmployeeID, d.ToDate
	INTO #LockedSalary
	FROM (
		SELECT l.EmployeeID, max(l.Year * 12 + l.Month) max_month_year
		FROM tblSal_Lock l
		WHERE EXISTS (
				SELECT 1
				FROM #tblEmployee te
				WHERE l.EmployeeID = te.EmployeeID
				)
		GROUP BY l.EmployeeID
		) l
	CROSS APPLY dbo.fn_GetMonthYearFromIntValue(l.max_month_year) my
	CROSS APPLY dbo.fn_Get_SalaryPeriod(my.Month, my.Year) d

	SET @Query = @Query + @TotalIncomeQry +
		N'as TotalIncome
   ,tsh.IsNet
   ,tsh.NETSalary
   , PercentProbation
   ,tsh.BaseSalRegionalID,tsh.CurrencyCode, ExchangeRate_Contract
   ,tsh.SalCalRuleID,tsh.SalaryHistoryID, @IsHasInsSalary as SI_NEED_INPUTSALARY
   ,tsh.Note,sc.SectionName,e.EmployeeStatusID,e.AccountNo, bk.BankName, bk.BankCode, e.TaxRegNo, depent.DepENDentNumber,case when tsh.Date <= l.ToDate then ''Salary Locked'' end StatusLock
   ,cast(case when tsh.Date <= l.ToDate then 1 else 0 end as bit) as IsReadOnlyRow, p.PositionNameEN PositionName
  FROM #tblsalaryHistory AS tsh
  INNER JOIN #tblEmployee AS e ON tsh.EmployeeID = e.EmployeeID
  LEFT JOIN tblDepartment dp on e.DepartmentID = dp.DepartmentID
  LEFT JOIN tblSection sc on e.SectionID = sc.SectionID
  LEFT JOIN tblPosition p on tsh.PositionID = p.PositionID
  left join #LockedSalary l on tsh.EmployeeID = l.EmployeeID
  LEFT JOIN dbo.fn_TaxDepENDentNumber_ByDate(getdate()) AS depent ON e.EmployeeID = depent.EmployeeID
  LEFT JOIN dbo.fn_BankInfoList(@LanguageID) AS bk ON e.BankCode = bk.BankCode
  order by ISNULL(dp.Priority,999),dp.DepartmentName,ISNULL(sc.Priority,999),sc.SectionName, tsh.EmployeeID, tsh.Date
 '

	EXECUTE sp_EXECutesql @Query, N'@LanguageID varchar(2), @LoginID int,@IsHasInsSalary bit', @LanguageID = @LanguageID, @LoginID = @LoginID, @IsHasInsSalary = @IsHasInsSalary
END
GO

DELETE FROM tblSalaryHistory WHERE isNet = 1

SET IDENTITY_INSERT tblSalaryHistory ON
insert into tblSalaryHistory(SalaryHistoryID,EmployeeID,Date,RetroDate,Salary,InsSalary,NETSalary,SalCalRuleID,Note,CurrencyCode,PositionID,BaseSalRegionalID,CDP_TAX_EE_AL_CurrencyCode,Trans_Tax_EE_AL_CurrencyCode,IsNet,PayrollTypeCode,WorkingHoursPerDay,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],PercentProbation,[15],[16],[17],ExchangeRate_Contract)
select SalaryHistoryID,EmployeeID,Date,RetroDate,Salary,InsSalary,NETSalary,SalCalRuleID,Note,CurrencyCode,PositionID,BaseSalRegionalID,CDP_TAX_EE_AL_CurrencyCode,Trans_Tax_EE_AL_CurrencyCode,IsNet,PayrollTypeCode,WorkingHoursPerDay,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],PercentProbation,[15],[16],[17],ExchangeRate_Contract
from (	select CAST(1746 as int) SalaryHistoryID,CAST(N'62250007' as varchar(20)) EmployeeID,CAST(N'2025-07-07' as date) Date,CAST(NULL as datetime) RetroDate,CAST(1500 as money) Salary,CAST(1500 as money) InsSalary,CAST(1500 as money) NETSalary,CAST(1 as tinyint) SalCalRuleID,CAST(NULL as nvarchar(max)) Note,CAST(N'USD' as varchar(20)) CurrencyCode,CAST(19 as int) PositionID,CAST(2 as int) BaseSalRegionalID,CAST(NULL as nvarchar(20)) CDP_TAX_EE_AL_CurrencyCode,CAST(NULL as nvarchar(20)) Trans_Tax_EE_AL_CurrencyCode,CAST(1 as bit) IsNet,CAST(NULL as nvarchar(20)) PayrollTypeCode,CAST(NULL as float) WorkingHoursPerDay,CAST(NULL as money) [1],CAST(NULL as money) [2],CAST(NULL as money) [3],CAST(NULL as money) [4],CAST(NULL as money) [5],CAST(NULL as money) [6],CAST(NULL as money) [7],CAST(NULL as money) [8],CAST(NULL as money) [9],CAST(NULL as money) [10],CAST(NULL as money) [11],CAST(NULL as money) [12],CAST(NULL as money) [13],CAST(NULL as money) [14],CAST(NULL as float) PercentProbation,CAST(NULL as money) [15],CAST(NULL as money) [16],CAST(NULL as money) [17],CAST(25058.0 as float) ExchangeRate_Contract	union all select 1747,N'62250008',N'2025-07-16',NULL,1000,1000,1000,1,NULL,N'USD',4,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1748,N'62250009',N'2025-06-15',NULL,1500,1500,1500,1,NULL,N'USD',19,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1749,N'62250010',N'2025-06-20',NULL,1500,1500,1500,1,NULL,N'USD',19,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1750,N'62250011',N'2025-06-15',NULL,1000,1000,1000,1,NULL,N'USD',18,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1751,N'62250012',N'2025-06-15',NULL,1500,1500,1500,1,NULL,N'USD',3,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1752,N'62250013',N'2025-07-16',NULL,1000,1000,1000,1,NULL,N'USD',18,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1766,N'62250029',N'2025-07-07',NULL,600,600,600,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1767,N'62250030',N'2025-07-07',NULL,600,600,600,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1768,N'62250031',N'2025-07-07',NULL,600,600,600,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 3458,N'62250042',N'2025-08-08',NULL,NULL,NULL,NULL,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL) tmpData
SET IDENTITY_INSERT tblSalaryHistory OFF


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
