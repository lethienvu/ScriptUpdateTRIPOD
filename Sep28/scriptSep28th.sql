
if object_id('[dbo].[SALCAL_MAIN]') is null
	EXEC ('CREATE PROCEDURE [dbo].[SALCAL_MAIN] as select 1')
GO

--exec SALCAL_MAIN 7,2021,3,0,'-1',0
ALTER PROCEDURE [dbo].[SALCAL_MAIN] (@Month INT, @Year INT, @LoginID INT, @PeriodID INT = 0, @EmployeeID NVARCHAR(20) = '-1', @CalculateRetro INT = 0)
AS
BEGIN
	IF @CalculateRetro IS NULL
		SET @CalculateRetro = 0

	DECLARE @nextMonth INT = @month + 1, @nextYear INT = @Year

	IF (@nextMonth = 13)
	BEGIN
		SET @nextMonth = 1
		SET @nextYear += 1
	END

	IF ISNULL(@PeriodID, - 1) < 0
		SET @PeriodID = 0

	IF isnull(@EmployeeID, '') = ''
		SET @EmployeeID = '-1'

	DECLARE @Query NVARCHAR(max), @StopUPDATE BIT = 0

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	TRUNCATE TABLE tblProcessErrorMessage

	/*	Danh mục tính lương
	-- lấy 1 bảng bao gồm ngày công ,nghỉ
	- Phát sinh 2,3 mức lương trong tháng: muc luong phat sinh moi trong thang
	- Tính công chuẩn: standard working day
	- Tạo lvHistory để tính chuyên cần: tao nghi viec neu de tinh chuyen can, tru thieu cong
	- Xóa dữ liệu tính lương lần trước: Delete old data
	- Tính lương 1 ngày: Calculate salary per day
	- Tính lương 1 giờ: Calculate salary per hour
	- Tính nghỉ trả lương, trừ lương: Leave Amount
	- Tính lương cơ bản: Calculate Actual salary
	- Tính lương tăng ca: Calculate OT
	- Tính điều chỉnh trong tháng: Calculate Adjustment
	- Tính phụ cấp: Calculate Allowance
	- Tính phụ cấp thâm niên: thâm niên
	- Tính phụ cấp chuyên cần: chuyên cần, chuyen can chuyencan
	- Tính phụ cấp đồng phục, nhà ở: phụ cấp trang phục
	- Tính tiền bảo hiểm: Calculate Employee insurance
	- Phí công đoàn: Calculate Trade Union fee
	- Trừ tiền đi trễ về sớm: Calculate IO
	- Tổng lương thực lãnh lần 1: Payroll sumaried items
	- Tính thuế TNCN: Calculate tax
	- Cập nhật lại lương thực lãnh: UPDATE other sumaried items of Sumary Table
	- Cập nhật lương detail, bảng lương tổng: UPDATE salary detail records
*/
	EXEC sp_getMonthlyPayrollCheckList @Month = @Month, @Year = @Year, @LoginID = @LoginID, @NotSelect = 1

    	--TRIPOD
	--EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 1

	--exec sp_UnionMembershipList @LoginID = @LoginID, @NotSelect = 1
	CREATE TABLE #NameOfPhysicTables (TempTablename NVARCHAR(500), PhysicTableName NVARCHAR(500), ColumnNeedToBeDeduct VARCHAR(max), PrimaryKeyCOlumns VARCHAR(max))

	SELECT *
	INTO #tblSal_Adjustment_des
	FROM tblSal_Adjustment
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_Adjustment_des', 'tblSal_Adjustment', 'Amount,TaxableAmount,UntaxableAmount'

	SELECT *
	INTO #tblSal_Allowance_des
	FROM tblSal_Allowance
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_Allowance_des', 'tblSal_Allowance', 'Amount,AmountLastMonth,UntaxableAmount,TaxableAmount,RetroAmount,RetroAmountNonTax,MonthlyCustomAmount'

	SELECT *
	INTO #tblSal_IO_des
	FROM tblSal_IO
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_IO_des', 'tblSal_IO', ''

	SELECT *
	INTO #tblSal_NS_des
	FROM tblSal_NS
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_NS_des', 'tblSal_NS', 'NSHours,NSAmount'

	SELECT *
	INTO #tblSal_OT_des
	FROM tblSal_OT
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_OT_des', 'tblSal_OT', 'OTAmount,TaxableOTAmount,NoneTaxableOTAmount,NightShiftAmount'

	SELECT *
	INTO #tblSal_PaidLeave_des
	FROM tblSal_PaidLeave
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_PaidLeave_des', 'tblSal_PaidLeave', 'LeaveDays,LeaveHour,AmountDeduct,AmountPaid'

	----from detail table
	SELECT *
	INTO #tblSal_Allowance_Detail_des
	FROM tblSal_Allowance_Detail
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_Allowance_Detail_des', 'tblSal_Allowance_Detail', 'Amount,AmountLastMonth,TaxableAmount,UntaxableAmount,Raw_DefaultAmount,Raw_ExchangeRate,RetroAmount,RetroAmountNonTax,MonthlyCustomAmount'

	SELECT *
	INTO #tblSal_IO_Detail_des
	FROM tblSal_IO_Detail
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_IO_Detail_des', 'tblSal_IO_Detail', ''

	SELECT *
	INTO #tblSal_NS_Detail_des
	FROM tblSal_NS_Detail
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_NS_Detail_des', 'tblSal_NS_Detail', 'NSHours,NSAmount'

	SELECT *
	INTO #tblSal_OT_Detail_des
	FROM tblSal_OT_Detail
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_OT_Detail_des', 'tblSal_OT_Detail', 'OTHour,OTAmount,NightShiftAmount'

	SELECT *
	INTO #tblSal_PaidLeave_Detail_des
	FROM tblSal_PaidLeave_Detail
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_PaidLeave_Detail_des', 'tblSal_PaidLeave_Detail', 'LeaveDays,LeaveHour,AmountDeduct,AmountPaid'

	----other sal table
	SELECT *
	INTO #tblSal_Error_des
	FROM tblSal_Error
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName)
	SELECT '#tblSal_Error_des', 'tblSal_Error'

	SELECT *
	INTO #tblSal_Adjustment_ForAllowance_Des
	FROM tblSal_Adjustment_ForAllowance
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName)
	SELECT '#tblSal_Adjustment_ForAllowance_Des', 'tblSal_Adjustment_ForAllowance'

	SELECT *
	INTO #tblSal_Abroad_ForTaxPurpose_des
	FROM tblSal_Abroad_ForTaxPurpose
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_Abroad_ForTaxPurpose_des', 'tblSal_Abroad_ForTaxPurpose', 'NetAmountVND,Raw_NetAmount,GrossAmountVND,Raw_GrossAmount'

	SELECT *
	INTO #tblSal_tax_des
	FROM tblSal_tax
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_tax_des', 'tblSal_tax', 'IncomeTaxable,TaxAmt,OTDeduction,Salary13Amount,TaxableIncome_EROnly_ForNETOnly,PITAmt_ER,TaxRetroImported'

	SELECT *
	INTO #tblSal_Sal_des
	FROM tblSal_Sal
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_Sal_des', 'tblSal_Sal', 'ActualMonthlyBasic,TaxableAllowance,NontaxableAllowance,TaxableAdjustment,NontaxableAdj,TotalIncome,IOAmt,EmpUnion,CompUnion,TaxableIncomeBeforeDeduction,IncomeAfterPIT,GrossTakeHome,TotalEarn,RemainAL,TaxableAdjustmentTotal_ForSalary,TaxableAdjustmentTotal_NotForSalary,TotalIncome_Taxable_Without_INS_Persion_family,TotalIncome_ForSalaryTaxedAdj,TotalCostComPaid,TotalPayrollFund,TotalDeduction,UnpaidLeaveAmount,EmpUnion_RETRO,CompUnion_RETRO,TotalNetIncome_Custom,GrossedUpWithoutHousing_Custom,GrossedUpWithoutHousing_WithoutGrossIncome_Custom'

	SELECT *
	INTO #tblSal_Sal_Detail_des
	FROM tblSal_Sal_Detail
	WHERE 1 = 0

	INSERT INTO #NameOfPhysicTables (TempTablename, PhysicTableName, ColumnNeedToBeDeduct)
	SELECT '#tblSal_Sal_Detail_des', 'tblSal_Sal_Detail', 'ATTHours,WorkingHours,ActualMonthlyBasic,TaxableAllowance,NontaxableAllowance,TaxableAdjustment,NontaxableAdj,TotalIncome,IOAmt,EmpUnion,CompUnion,TaxableIncomeBeforeDeduction,IncomeAfterPIT,GrossTakeHome,TotalEarn,DaysOfSalEntry,TaxableAdjustmentTotal_ForSalary,TaxableAdjustmentTotal_NotForSalary,UnpaidLeaveAmount,TotalNetIncome_Custom,GrossedUpWithoutHousing_Custom,GrossedUpWithoutHousing_WithoutGrossIncome_Custom'

	DECLARE @FromDate DATETIME, @ToDate DATETIME, @ToDateTruncate DATE, @CAL_SALTAX_PROGRESSIVE_ALLEMPS INT, @FIXEDWORKINGDAY FLOAT = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'FIXEDWORKINGDAY'
			), @ROUND_TAKE INT, @ROUND_NET INT, @ROUND_SALARY_UNIT INT, @PROBATION_PERECNT FLOAT, @ROUND_OT_NS_Detail_UNIT INT, @ROUND_TOTAL_WORKINGDAYS INT, @ROUND_ATTDAYS INT

	SET @ROUND_TAKE = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_TAKE'
			)
	SET @ROUND_TAKE = ISNULL(@ROUND_TAKE, - 3)
	SET @ROUND_ATTDAYS = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_ATTDAYS'
			)
	SET @ROUND_ATTDAYS = ISNULL(@ROUND_ATTDAYS, 4)
	SET @ROUND_NET = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_NET'
			)
	SET @ROUND_NET = ISNULL(@ROUND_NET, - 3)
	SET @ROUND_SALARY_UNIT = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_SALARY_UNIT'
			)
	SET @ROUND_SALARY_UNIT = ISNULL(@ROUND_SALARY_UNIT, 4)
	SET @ROUND_OT_NS_Detail_UNIT = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_OT_NS_Detail_UNIT'
			)
	SET @ROUND_OT_NS_Detail_UNIT = ISNULL(@ROUND_OT_NS_Detail_UNIT, 4)
	SET @ROUND_TOTAL_WORKINGDAYS = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_TOTAL_WORKINGDAYS'
			)
	SET @ROUND_TOTAL_WORKINGDAYS = ISNULL(@ROUND_TOTAL_WORKINGDAYS, 2)
	SET @FIXEDWORKINGDAY = ISNULL(@FIXEDWORKINGDAY, 26.0)
	SET @CAL_SALTAX_PROGRESSIVE_ALLEMPS = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'CAL_SALTAX_PROGRESSIVE_ALLEMPS'
			)

	IF (@CAL_SALTAX_PROGRESSIVE_ALLEMPS IS NULL)
		SET @CAL_SALTAX_PROGRESSIVE_ALLEMPS = 0
	SET @PROBATION_PERECNT = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'PROBATION_PERECNT'
			)
	SET @PROBATION_PERECNT = ISNULL(@PROBATION_PERECNT, 100)

	SELECT @FromDate = FromDate, @ToDate = ToDate, @ToDateTruncate = ToDate
	FROM dbo.fn_Get_SalaryPeriod_Term(@Month, @Year, @PeriodID)

	CREATE TABLE #tblSalDetail (
		EmployeeID VARCHAR(20), BasicSalary FLOAT(53), BasicSalaryOrg FLOAT(53), GrossSalary FLOAT(53), TotalSalary FLOAT(53), STD_WD FLOAT, STD_WD_Schedule FLOAT, OTSalary FLOAT(53), SalaryPerDay FLOAT(53), RegularAmt FLOAT(53), PaidLeaveAmt FLOAT(53), SalaryPerHour FLOAT(53), SalaryPerDayOT FLOAT(53), SalaryPerHourOT FLOAT(53), WorkingHoursPerDay FLOAT(53), DaysOfSalEntry FLOAT, ActualMonthlyBasic FLOAT(53), UnpaidLeaveAmount FLOAT(53), TaxableOTTotal FLOAT(53), NoneTaxableOTTotal FLOAT(53), TotalOTAmount FLOAT(53) --dung de round
		, TotalNSAmt FLOAT(53), NightShiftAmount FLOAT(53), NoneTaxableNSAmt FLOAT(53), TaxableAllowanceTotal FLOAT(53), NoneTaxableAllowanceTotal FLOAT(53), TotalAllowanceForSalary FLOAT(53), TaxableAdjustmentTotal FLOAT(53), TaxableAdjustmentTotal_ForSalary FLOAT(53), TaxableAdjustmentTotal_NotForSalary FLOAT(53), NoneTaxableAdjustmentTotal FLOAT(53), TotalAdjustmentForSalary FLOAT(53), TotalAdjustment_WithoutForce FLOAT(53), TotalEarn FLOAT(53) -- Tổng thu nhập gồm toàn những khoản cộng
		, TotalIncome FLOAT(53) -- Tổng thu nhập\	
		, TotalIncome_ForSalaryTaxedAdj FLOAT(53) -- Tổng thu nhập + allowance + adjustment trong lương chịu thuế
		, TotalIncome_Taxable_Without_INS_Persion_family FLOAT(53) -- Tổng thu nhập + allowance + adjustment trong lương chịu thuế
		, TaxableIncomeBeforeDeduction FLOAT(53), TaxableIncomeBeforeDeduction_EROnly_ForNETOnly FLOAT(53), OwnerDeduction FLOAT(53), DependentDeduction FLOAT(53), TaxableIncome FLOAT(53), TaxableIncome_EROnly_ForNETOnly FLOAT(53), PITAmt FLOAT(53), PITAmt_ER FLOAT(53), EmpUnion_RETRO FLOAT(53), EmpUnion FLOAT(53), CompUnion_RETRO FLOAT(53), CompUnion FLOAT(53), InsAmt FLOAT(53) --10.5% cua nhan vien dong
		, InsAmtComp FLOAT(53), PITReturn FLOAT(53) -- điều chỉnh sau lương
		, IncomeAfterPIT FLOAT(53), OtherDeductionAfterPIT FLOAT(53) -- mục đích thể hiện số tiền bị trừ sau thuế, giống cột tạm ứng
		, AdvanceAmt FLOAT(53), TotalCostComPaid FLOAT(53), TotalPayrollFund FLOAT(53), Salary13thProvision FLOAT(53), FromDate DATETIME, ToDate DATETIME, SalaryHistoryID BIGINT, BaseSalRegionalID INT, isTwoSalLevel BIT, SalCalRuleID INT, LatestSalEntry BIT, IOAmt FLOAT(53) -- đi trễ về sớm
		, TotalDeduct FLOAT(53) -- tổng các khoản khấu trừ, cong đoàn, bảo hiểm,thuế, trừ khác
		, GrossTakeHome FLOAT(53), AverageSalary FLOAT(53) -- luong binh quan khi co nhieu muc luong trong thang
		, CurrencyCode NVARCHAR(20), ExchangeRate FLOAT(53), IsNet BIT, TotalNetIncome_Custom FLOAT(53), GrossedUpWithoutHousing_Custom FLOAT(53), GrossedUpWithoutHousing_WithoutGrossIncome_Custom FLOAT(53)
		--,SalaryCalculationDAte date
		, STDPerSalaryHistoryId FLOAT(53), PayrollTypeCode VARCHAR(50), ProbationSalaryHistoryID BIGINT, PercentProbation FLOAT, AnnualBonus_Total FLOAT(53), AnnualBonus_EvMonth FLOAT(53), Bonus6Month_Total FLOAT(53), Bonus6M_EveryMonth FLOAT(53), NETSalary FLOAT(53) --TRIPOD
		)

	IF (OBJECT_ID('SALCAL_ADD_COLUMN_INTO_TMP_TABLE') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ADD_COLUMN_INTO_TMP_TABLE
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ADD_COLUMN_INTO_TMP_TABLE @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	--TRIPOD: STD
	SELECT EmployeeID, isSalCal, isLowTaxableInCome, PayrollCutOffDate, Number6DayMonth, Number6DayMonth_Actual, NumberDayOfYear, NumberDayOfYear_Actual, STD_WorkingHours, ActualMonthInYear, Bonus6MonthAllowance, RatioBonus6Month
	INTO #tmpMonthlyPayrollCheckList
	FROM tblMonthlyPayrollCheckList
	WHERE Month = @Month AND Year = @Year

	IF @PeriodID = 1
		DELETE #tmpMonthlyPayrollCheckList
		WHERE ISNULL(PayrollCutOffDate, DATEADD(day, 1, @todate)) NOT BETWEEN @FromDate AND @ToDate

	SELECT te.EmployeeID, te.DivisionID, te.DepartmentID, te.SectionID, te.GroupID, te.EmployeeTypeID, te.PositionID, te.EmployeeStatusID, te.Sex, CASE
			WHEN te.HireDate > @fromDate
				THEN cast(1 AS BIT)
			ELSE 0
			END AS NewStaff, CAST(0 AS BIT) AS TerminatedStaff, HireDate, CAST(NULL AS DATETIME) TerminateDate, ProbationEndDate, te.LastWorkingDate
	INTO #tblEmployeeIDList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDateTruncate, @EmployeeID, @LoginID) te
	INNER JOIN tblDivision div ON te.DivisionID = div.DivisionID
	WHERE NOT EXISTS (
			SELECT 1
			FROM tblSal_Lock l
			WHERE te.EmployeeID = l.EmployeeID AND @CalculateRetro = 0 AND l.Month = @Month AND l.Year = @Year
			)

	-- khoa roi thi khong tinh luong nua
	SELECT *
	INTO #fn_EmployeeStatus_ByDate
	FROM dbo.fn_EmployeeStatus_ByDate(@ToDate)

	SELECT *
	INTO #fn_EmployeeStatus_ByDate_FirstLastMonth
	FROM dbo.fn_EmployeeStatus_ByDate(dateadd(dd, 1, @ToDate))

	--lay trang thai ben bang history cho chinh xac
	UPDATE #tblEmployeeIDList
	SET EmployeeStatusID = stt.EmployeeStatusID
	FROM #tblEmployeeIDList te
	INNER JOIN #fn_EmployeeStatus_ByDate stt ON te.EmployeeID = stt.EmployeeID

	UPDATE #tblEmployeeIDList
	SET EmployeeStatusID = stt.EmployeeStatusID, TerminateDate = stt.ChangedDate, LastWorkingDate = dateadd(dd, - 1, stt.ChangedDate)
	FROM #tblEmployeeIDList te
	INNER JOIN #fn_EmployeeStatus_ByDate_FirstLastMonth stt ON te.EmployeeID = stt.EmployeeID
	WHERE stt.EmployeeStatusID = 20

	UPDATE #tblEmployeeIDList
	SET TerminatedStaff = 1
	WHERE TerminateDate IS NOT NULL

	SELECT *
	INTO #tblEmployeeIDList_Needdelete
	FROM #tblEmployeeIDList
	WHERE 1 = 0

	-- ko nằm trong danh sách thì ko tính lương nha
	INSERT INTO #tblEmployeeIDList_Needdelete
	SELECT *
	FROM (
		DELETE #tblEmployeeIDList
		OUTPUT deleted.*
		FROM #tblEmployeeIDList te
		WHERE te.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM #tmpMonthlyPayrollCheckList
				WHERE isSalCal = 1
				)
		) de

	IF @@ROWCOUNT > 0
	BEGIN
		-- delete các bảng thực
		SELECT EmployeeID, @Month AS Month, @year AS Year, @PeriodID AS PeriodID
		INTO #delete_data
		FROM #tblEmployeeIDList_Needdelete

		DELETE #delete_data
		FROM #delete_data de
		INNER JOIN tblSal_lock s ON de.EmployeeID = s.EmployeeId AND s.Month = @Month AND s.Year = @Year

		DECLARE @deleteQuery_Phy VARCHAR(max) = ''

		SELECT @deleteQuery_Phy += '
		delete ' + PhysictableName + ' from ' + physictablename + ' p inner join #delete_data d on p.employeeId = d.EmployeeID and p.Month = d.Month and p.Year = d.Year and p.PeriodID = d.PeriodID'
		FROM #NameOfPhysicTables

		EXEC (@deleteQuery_Phy)

		DROP TABLE #delete_data
	END

	IF NOT EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList
			)
		RETURN;

	-- những ai chưa khóa công thì ko cho tính lương
	INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID)
	SELECT N'Khóa công!', '[' + de.EmployeeID + N']	-- Bạn chưa khóa công!', @LoginID
	FROM (
		DELETE #tblEmployeeIDList
		OUTPUT deleted.EmployeeID
		FROM #tblEmployeeIDList e
		WHERE NOT EXISTS (
				SELECT 1
				FROM tblAtt_LockMonth f
				WHERE e.EmployeeID = f.EmployeeID AND f.Month = @Month AND f.Year = @Year
				)
		) de

	DELETE c
	FROM #tmpMonthlyPayrollCheckList c
	WHERE employeeID NOT IN (
			SELECT employeeID
			FROM #tblEmployeeIDList
			)

	SELECT *
	INTO #EmployeeExchangeRate
	FROM dbo.fn_GetExchangeRateInSalaryPeriod(@loginid, @FromDate, @ToDate) c
	WHERE c.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			)

	IF EXISTS (
			SELECT 1
			FROM #EmployeeExchangeRate
			GROUP BY EmployeeId, CurrencyCode
			HAVING count(1) > 1
			)
	BEGIN
		RAISERROR ('MultiplecurrencyCode,Please Contact VietTinSoft to fix it!', 16, 1)

		RETURN;
	END

	IF (
			SELECT COUNT(1)
			FROM #tblEmployeeIDList
			) = 0
		RETURN

	-- move SAlretro here to query on sal OT, sal NS
	SELECT *
	INTO #tblSal_Retro
	FROM tblSal_Retro
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			)

	SELECT DISTINCT EmployeeID, Month, Year
	INTO #tblsal_retro_Final
	FROM #tblSal_Retro

	DECLARE @querytblSAl_Retro VARCHAR(max) = ''
	DECLARE @querytblSAl_Retro_update VARCHAR(max) = ''
	DECLARE @querytblSAl_Retro_sumQue VARCHAR(max) = ''

	SELECT @querytblSAl_Retro += ',' + c.name + ' money', @querytblSAl_Retro_update += ', [' + c.name + '] = [S_' + c.name + ']', @querytblSAl_Retro_sumQue += ', sum([' + c.name + ']) as S_' + c.name + ''
	FROM tempdb.sys.columns c
	INNER JOIN sys.types t ON c.user_type_id = t.user_type_id AND t.name = 'money'
	WHERE c.object_id = object_id('tempdb..#tblSal_Retro')

	SET @querytblSAl_Retro = 'alter table #tblsal_retro_Final add BalanceDays float ,' + SUBSTRING(@querytblSAl_Retro, 2, 99999)

	EXEC (@querytblSAl_Retro)

	SET @querytblSAl_Retro_update = 'update #tblsal_retro_Final set BalanceDays= S_BalanceDays,' + SUBSTRING(@querytblSAl_Retro_update, 2, 99999) + '
	from #tblsal_retro_Final r
	inner join (select EmployeeID,Max(case when BalanceDays = 0 then -9999 else BalanceDays end) as S_BalanceDays' + @querytblSAl_Retro_sumQue + '
	from #tblsal_retro group by EmployeeID) sal on r.EmployeeId = sal.EmployeeID '

	EXEC (@querytblSAl_Retro_update)

	EXEC sp_InsertUpdateFromTempTableTOTable @TempTableName = N'#tblsal_retro_Final', @TableName = tblSal_Retro_Sumary

	DELETE tblSal_Retro_Sumary
	FROM tblSal_Retro_Sumary re
	WHERE month = @month AND year = @year AND NOT EXISTS (
			SELECT 1
			FROM tblSal_lock sl
			WHERE sl.EmployeeID = re.EmployeeID AND sl.Month = @Month AND sl.Year = @Year
			) AND NOT EXISTS (
			SELECT 1
			FROM tblSal_Retro re1
			WHERE re.EmployeeID = re1.EmployeeID AND re1.Month = @Month AND re1.Year = @Year
			) AND ISNULL(re.IsImported, 0) = 0

	DROP TABLE #tblSal_Retro

	SELECT EmployeeID
	INTO #EmployeeWorkingOn
	FROM tmpEmployeeTree
	WHERE LoginID = @LoginID

	--SET @LoginID = @LoginID + 1000
	--delete tmpEmployeeTree where LoginID = @LoginID
	--insert into tmpEmployeeTree(EmployeeID,LoginID)
	--select EmployeeID,@LoginID from #tblEmployeeIDList
	DECLARE @SIDate DATETIME

	SELECT @SIDate = cast(cast(Year(@ToDate) AS NVARCHAR(20)) + '-' + cast(Month(@ToDate) AS NVARCHAR(20)) + '-15' AS DATE)

	-- nhan vien dong thue thoi vu
	-- dùng để tính thuế cho thời vụ, thử việc không có cam kết thu nhập thấp hoặc nhân viên không có hợp đồng
	SELECT e.EmployeeID, cast(isnull(pit.FixedPercents, 10) / 100 AS FLOAT) TaxPercentage, isnull(lb.isLowSalary, 0) isLowSalary, ISNULL(pit.PITStatus, 1) AS PITStatus, DivisionID
	INTO #tblTemporaryContractTax
	FROM #tblEmployeeIDList e
	INNER JOIN (
		SELECT EmployeeID, ContractID
		FROM dbo.fn_CurrentContractListByDate(@SIDate) c
		WHERE c.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)
		
		UNION
		
		SELECT EmployeeID, ContractID
		FROM dbo.fn_CurrentContractListByDate(@ToDate) c
		WHERE c.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList ee
				WHERE ee.HireDate > @SIDate
				)
		) c ON e.EmployeeID = c.EmployeeID
	INNER JOIN tblLabourContract lb ON c.ContractID = lb.ContractID
	INNER JOIN tblMST_ContractType mst ON lb.ContractCode = mst.ContractCode
	LEFT JOIN tblContract_PIT_Status pit ON lb.PITStatus = pit.PITStatus
	WHERE ((isnull(pit.FollowLabourContract, 0) = 1 AND ISNULL(mst.ShortTermTax, 0) = 1) OR (isnull(pit.Progressive, 0) = 0)) AND @CAL_SALTAX_PROGRESSIVE_ALLEMPS = 0 AND EXISTS (
			SELECT 1
			FROM tblParameter
			WHERE Code = 'DEDUCT_TAX_FOR_SHORT_TERM' AND Value = '1'
			)

	INSERT INTO #tblTemporaryContractTax (EmployeeID, TaxPercentage, isLowSalary, PITStatus, DivisionID)
	SELECT EmployeeID, 0.1, 0, 2, DivisionID
	FROM #tblEmployeeIDList
	WHERE TerminateDate <= @FromDate AND EmployeeID NOT IN (
			SELECT EmployeeID
			FROM #tblTemporaryContractTax
			)

	--and DivisionId in(Select DivisionID from tblDivision where Terminate_Mean_10PercentTax = 1)
	--tripod
	DELETE
	FROM #tblTemporaryContractTax

	--UPDATE $ set isLowSalary = 1 where EmployeeID in (
	--	select EmployeeID from dbo.fn_CurrentContractListByDate(@ToDate) where  = 1
	--)
	--if @PROBATION_PERECNT >= 100.0
	BEGIN
		-- mức lương cũ
		INSERT INTO #tblSalDetail (EmployeeID, SalaryHistoryID, FromDate, ToDate, BasicSalary, BasicSalaryOrg, SalCalRuleID, LatestSalEntry, BaseSalRegionalID, CurrencyCode, IsNet, PayrollTypeCode, WorkingHoursPerDay, NETSalary)
		SELECT sh.EmployeeID, sh.SalaryHistoryID, CASE
				WHEN sh.DATE < @FromDate
					THEN @FromDate
				ELSE sh.DATE
				END, @ToDate, ISNULL(sh.Salary, 0) + ISNULL([14], 0), ISNULL(sh.Salary, 0) + ISNULL([14], 0), sh.SalCalRuleID, 1, sh.BaseSalRegionalID, sh.CurrencyCode, sh.IsNet, sh.PayrollTypeCode, ISNULL(nullif(sh.WorkingHoursPerDay, 0), 8), ISNULL(sh.NETSalary, 0)
		FROM dbo.fn_CurrentSalaryHistoryIDByDate(@FromDate) s
		INNER JOIN tblSalaryHistory sh ON s.SalaryHistoryID = sh.SalaryHistoryID
		WHERE EXISTS (
				SELECT 1
				FROM #tblEmployeeIDList te
				WHERE sh.EmployeeID = te.EmployeeID AND sh.DATE >= te.HireDate
				)
	END

	-- muc luong phat sinh moi trong thang
	INSERT INTO #tblSalDetail (EmployeeID, SalaryHistoryID, FromDate, ToDate, BasicSalary, BasicSalaryOrg, SalCalRuleID, LatestSalEntry, BaseSalRegionalID, CurrencyCode, IsNet, PayrollTypeCode, WorkingHoursPerDay, NETSalary)
	SELECT sh.EmployeeID, sh.SalaryHistoryID, CASE
			WHEN sh.DATE < @FromDate
				THEN @FromDate
			ELSE sh.DATE
			END, @ToDate, ISNULL(sh.Salary, 0) + ISNULL([14], 0), ISNULL(sh.Salary, 0) + ISNULL([14], 0), sh.SalCalRuleID, 1, sh.BaseSalRegionalID, sh.CurrencyCode, sh.IsNet, sh.PayrollTypeCode, ISNULL(nullif(sh.WorkingHoursPerDay, 0), 8), ISNULL(sh.NETSalary, 0)
	FROM tblSalaryHistory sh
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList te
			WHERE sh.EmployeeID = te.EmployeeID AND sh.DATE >= te.HireDate
			) AND [Date] > @FromDate AND NOT EXISTS (
			SELECT 1
			FROM #tblSalDetail s
			WHERE sh.SalaryHistoryID = s.SalaryHistoryID
			) AND sh.DATE <= @ToDate

	-- lấy dữ liệu bảng custom attendance ra
	SELECT *
	INTO #tblCustomAttendanceData
	FROM tblCustomAttendanceData c
	WHERE Month = @Month AND Year = @Year AND Approved = 1 AND c.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			) AND IsRetro = @CalculateRetro -- nhớ where vụ retro nhé

	ALTER TABLE #tblCustomAttendanceData ADD PaidLeaves FLOAT(53), UnPaidLeaves FLOAT(53), TotalNonWorkingDays FLOAT(53)

	DECLARE @CustomAttendanceQuery VARCHAR(max) = ''

	SELECT @CustomAttendanceQuery += '+isnull(' + LeaveCode + ',0)*' + CAST(lt.PaidRate AS VARCHAR(10)) + '/100'
	FROM tblLeaveType lt
	WHERE lt.PaidRate > 0 AND lt.LeaveCode IN (
			SELECT Column_Name
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = 'tblCustomAttendanceData'
			)

	DECLARE @customAttendanceQuery_Unpaid VARCHAR(max) = ''

	SELECT @customAttendanceQuery_Unpaid += '+isnull(' + LeaveCode + ',0)'
	FROM tblLeaveType lt
	WHERE ISNULL(lt.PaidRate, 0) = 0 AND lt.LeaveCode IN (
			SELECT Column_Name
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = 'tblCustomAttendanceData'
			)

	SET @CustomAttendanceQuery = 'update #tblCustomAttendanceData set PaidLeaves = 0' + @CustomAttendanceQuery + ',UnpaidLeaves = 0' + @customAttendanceQuery_Unpaid

	-- update các giá chị cần thiết match up mới bảng truyền thống trrc giờ
	EXEC (@CustomAttendanceQuery)

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind
	INTO #tblOTList
	FROM tblOTList ot
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0 AND ot.EmployeeID IN (
			SELECT te.EmployeeID
			FROM #tblEmployeeIDList te
			
			EXCEPT
			
			SELECT c.EmployeeID
			FROM #tblCustomAttendanceData c
			)

	DECLARE @CustomOTInsert VARCHAR(max) = ''

	CREATE TABLE #tempDataForOT (EmployeeID VARCHAR(20), OTKindID INT, OTAmountHours FLOAT(53))

	SELECT @CustomOTInsert += '
	insert into #tempDataForOT(EmployeeID,OTKindID,OTAmountHours)
	select EmployeeID,''' + CAST(OTKind AS VARCHAR(10)) + ''',' + ColumnNameOn_CustomAttendanceTable + ' as LvAmountDays
	from #tblCustomAttendanceData where ' + ColumnNameOn_CustomAttendanceTable + ' <>0'
	FROM tblOvertimeSetting ov
	WHERE ov.ColumnNameOn_CustomAttendanceTable IN (
			SELECT COLUMN_NAME
			FROM INFORMATION_SCHEMA.COLUMNS c
			WHERE c.TABLE_NAME = 'tblCustomAttendanceData'
			)

	EXEC (@CustomOTInsert)

	INSERT INTO #tblOTList (EmployeeID, OTDate, ApprovedHours, OTKind)
	SELECT EmployeeID, @ToDateTruncate AS OTDate, OTAmountHours AS ApprovedHours, OTKindID AS OTKind
	FROM #tempDataForOT

	DROP TABLE #tempDataForOT

	DELETE #tblOTList
	FROM #tblOTList ot
	WHERE NOT EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList te
			WHERE ot.EmployeeID = te.EmployeeID AND ot.OTDate BETWEEN te.HireDate AND te.LastWorkingDate
			)

	--TRIPOD-Foreign Currency
	UPDATE sd
	SET sd.ExchangeRate = er.ExchangeRate
	FROM #tblSalDetail sd
	INNER JOIN #EmployeeExchangeRate er ON sd.EmployeeID = er.EmployeeID
	WHERE isNET = 1

	--TRIPOD-foreign: mặc định cột Salary = NetSalaryy, khách muốn nhập cột nào cx đc
	UPDATE sal
	SET sal.BasicSalary = sal.NetSalary, sal.BasicSalaryOrg = sal.NetSalary
	FROM #tblSalDetail sal
	WHERE ISNULL(sal.BasicSalary, 0) = 0 AND ISNULL(sal.NetSalary, 0) > 0

	-- update lại theo tỷ giá nếu có
	UPDATE sal
	SET sal.BasicSalary = sal.BasicSalary * ISNULL(cs.[ExchangeRate], 1)
	FROM #tblSalDetail sal
	INNER JOIN #EmployeeExchangeRate cs ON sal.EmployeeID = cs.EmployeeID AND cs.CurrencyCode = sal.CurrencyCode

	-- nếu có thông tin lương có currencyCode <>'VND' mà chưa thiết lập tỷ giá tháng này thì phải thiết lập tỷ giá trước khi tính lương
	IF EXISTS (
			SELECT 1
			FROM #tblSalDetail
			WHERE isnull(CurrencyCode, 'VND') <> 'VND' AND ExchangeRate IS NULL
			)
	BEGIN
		INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID) --,ResolveLink)
		SELECT 'Exchange Rate not seted!', 'Exchange rate for "' + CurrencyCode + '" is not seted!, Please access Function "Currency Setting" first!', @loginID - 1000
		--,N'Object=MnuMDT150|Params=txtFilter=&cbx@Month='+cast(@Month as varchar(2))+'&cbx@Year='+cast(@year as varchar(4))+'|Text=Currency Setting'
		FROM #tblSalDetail
		WHERE isnull(CurrencyCode, 'VND') <> 'VND' AND ExchangeRate IS NULL

		RETURN;
	END

    --TRIPOD
    SELECT *
	INTO #AttendanceSummary
	FROM tblAttendanceSummary
	WHERE Year = @Year AND Month = @Month AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblSalDetail
			)

	--TRIPOD PROBATION: PercentProbation in tblEmployeeType
	IF EXISTS (
			SELECT 1
			FROM #tblSalDetail sh
			INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
			WHERE (ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate OR ProbationEndDate > @ToDateTruncate) AND te.HireDate <> te.ProbationEndDate
			)
		--IF @PROBATION_PERECNT < 100.0
	BEGIN
		-- UPDATE #tblSalDetail
		-- SET PercentProbation = ISNULL(tsh.PercentProbation, et.PercentProbation)
		-- FROM #tblSalDetail sh
		-- INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		-- LEFT JOIN tblSalaryHistory tsh ON sh.SalaryHistoryID = tsh.SalaryHistoryID
		-- LEFT JOIN tblEmployeeType et ON te.EmployeeTypeID = et.EmployeeTypeID
		-- WHERE (ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate OR ProbationEndDate > @ToDateTruncate) AND te.HireDate <> te.ProbationEndDate

		--cuoi thang hoac thang sau het thu viec
		-- UPDATE #tblSalDetail
		-- SET BasicSalaryOrg = BasicSalary, BasicSalary = BasicSalary * sh.PercentProbation / 100.0
		-- FROM #tblSalDetail sh
		-- INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		-- WHERE (ProbationEndDate >= @ToDateTruncate) AND te.HireDate <> te.ProbationEndDate

		--het thu viec trong thang nay
		UPDATE #tblSalDetail
		SET FromDate = DATEADD(day, 1, ProbationEndDate)
		FROM #tblSalDetail sh
		INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		WHERE ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate AND te.HireDate <> te.ProbationEndDate

        DECLARE @MaxSalaryHistoryId BIGINT

		SET @MaxSalaryHistoryId = (
				SELECT MAX(SalaryHistoryID)
				FROM #tblSalDetail
				) + 7121997 --TN:fake id cao lên để tránh trùng lắp với ID real

		INSERT INTO #tblSalDetail (EmployeeID, SalaryHistoryID, ProbationSalaryHistoryID, FromDate, ToDate, BasicSalaryOrg, BasicSalary, SalCalRuleID, LatestSalEntry, BaseSalRegionalID, IsNet, PayrollTypeCode, WorkingHoursPerDay, CurrencyCode)
		SELECT sh.EmployeeID, SalaryHistoryID, SalaryHistoryID + @MaxSalaryHistoryId, CASE
				WHEN @FromDate < te.HireDate
					THEN te.HireDate
				ELSE @FromDate
				END, te.ProbationEndDate, sh.BasicSalary, sh.BasicSalary, sh.SalCalRuleID, 1, sh.BaseSalRegionalID, IsNet, PayrollTypeCode, sh.WorkingHoursPerDay, sh.CurrencyCode
		FROM #tblSalDetail sh
		INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		WHERE te.ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate AND te.HireDate <> te.ProbationEndDate AND ISNULL(sh.isNET, 0) = 0

        UPDATE #tblSalDetail
		SET PercentProbation = ats.PercentProbation
		FROM #tblSalDetail sh
		INNER JOIN #AttendanceSummary ats ON sh.EmployeeID = ats.EmployeeID AND CAST(ats.FromDate AS DATE) = CAST(sh.FromDate AS DATE) AND CAST(ats.ToDate AS DATE) = CAST(sh.ToDate AS DATE)
        WHERE ISNULL(ats.PercentProbation, 0) > 0

		UPDATE #tblSalDetail
		SET BasicSalaryOrg = BasicSalary, BasicSalary = BasicSalary * sh.PercentProbation / 100.0
		FROM #tblSalDetail sh
		WHERE ISNULL(sh.PercentProbation, 0) > 0

	END

	-- bao loi sai ngay hieu luc luong, hoac chua nhap thong tin luong
	INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID, ResolveLink)
	SELECT 'Wrong salary info', N'Bạn chưa nhập thông tin lương hoặc ngày hiệu lực lương lớn hơn kỳ tính lương', @LoginID, 'Object=MnuHRS145'
	FROM #tblEmployeeIDList e
	WHERE NOT EXISTS (
			SELECT 1
			FROM #tblSalDetail s
			WHERE e.employeeID = s.employeeID
			)

	UPDATE s1
	SET ToDate = dateadd(second, - 1, s2.FromDate)
	FROM #tblSalDetail s1
	CROSS APPLY (
		SELECT MIN(FromDate) FromDate
		FROM #tblSalDetail s2
		WHERE s1.EmployeeID = s2.EmployeeID AND s1.FromDate < s2.FromDate
		) s2
	WHERE s2.FromDate IS NOT NULL

	UPDATE #tblSalDetail
	SET isTwoSalLevel = 0

	UPDATE #tblSalDetail
	SET LatestSalEntry = 0
	WHERE ToDate < @ToDate

	UPDATE #tblSalDetail
	SET isTwoSalLevel = 1
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #tblSalDetail s
			GROUP BY EmployeeID
			HAVING COUNT(1) > 1
			)

	--dong luong moi, nhung đã nghỉ việc
	SELECT sal.EmployeeID, sal.SalaryHistoryID
	INTO #NewSalaryButTerminated
	FROM #tblSalDetail sal
	INNER JOIN #tblEmployeeIDList te ON sal.EmployeeID = te.EmployeeID AND sal.FromDate > te.LastWorkingDate
	WHERE sal.isTwoSalLevel = 1 AND sal.LatestSalEntry = 1

	DELETE sal
	FROM #tblSalDetail sal
	WHERE sal.LatestSalEntry = 1 AND EXISTS (
			SELECT 1
			FROM #NewSalaryButTerminated n
			WHERE sal.EmployeeID = n.EmployeeID
			)

	UPDATE sal
	SET ProbationSalaryHistoryID = NULL, LatestSalEntry = 1
	FROM #tblSalDetail sal
	WHERE sal.LatestSalEntry = 0 AND EXISTS (
			SELECT 1
			FROM #NewSalaryButTerminated n
			WHERE sal.EmployeeID = n.EmployeeID
			)

	UPDATE #tblSalDetail
	SET isTwoSalLevel = 0
	FROM #tblSalDetail sal
	WHERE EXISTS (
			SELECT 1
			FROM #NewSalaryButTerminated n
			WHERE sal.EmployeeID = n.EmployeeID
			)

	-- standard working day
	-- ngày công chuẩn -- người vận chuyển lên đây để chạy dc cho những thằng import custom attendance data
	IF NOT EXISTS (
			SELECT 1
			FROM tblWorkingDaySetting s
			WHERE Month = @Month AND YEAR = @Year AND (
					EXISTS (
						SELECT 1
						FROM #tblEmployeeIDList e
						WHERE s.EmployeeTypeID = e.EmployeeTypeID
						) OR s.EmployeeTypeID = - 1
					)
			)
		EXEC sp_WorkingDaySetting @Month = @Month, @Year = @Year, @LoginID = @LoginID

	--tung nhan vien
	UPDATE s
	SET STD_WD = ee.WorkingDays_Std, STD_WD_Schedule = ee.WorkingDays_Std
	FROM #tblSalDetail s
	INNER JOIN tblWorkingDaySettingPerEE ee ON s.EmployeeID = ee.EMployeeID AND ee.Month = @Month AND ee.Year = @Year

	-- -- tung loai nhan vien
	-- UPDATE s set STD_WD = std.WorkingDays_Std, STD_WD_Schedule = std.WorkingDays_Std from #tblSalDetail s
	-- inner join #tblEmployeeIDList e on s.EmployeeID = e.EmployeeID
	-- inner join tblWorkingDaySetting std on e.EmployeeTypeID = std.EmployeeTypeID and std.Month = @Month and std.Year = @Year
	--TRIPOD:
	UPDATE s
	SET STD_WD = std.WorkingDays_Std, STD_WD_Schedule = std.WorkingDays_Std
	FROM #tblSalDetail s
	INNER JOIN tblWorkingDaySetting std ON std.EmployeeTypeID = 0 AND std.Month = @Month AND std.Year = @Year

	-- toan cong ty
	UPDATE s
	SET STD_WD = (
			SELECT std.WorkingDays_Std
			FROM tblWorkingDaySetting std
			WHERE std.EmployeeTypeID = - 1 AND std.Month = @Month AND std.Year = @Year
			)
	FROM #tblSalDetail s
	WHERE s.STD_WD IS NULL

	--TRIPOD
	UPDATE s
	SET STD_WD = 26
	FROM #tblSalDetail s
	WHERE STD_WD > 26

	UPDATE #tblSalDetail
	SET STD_WD_Schedule = STD_WD
	WHERE STD_WD_Schedule IS NULL

	UPDATE #tblSalDetail
	SET STD_WD = sc.FixedStdPerMonth
	FROM #tblSalDetail s
	INNER JOIN tblSalaryCalculationRule sc ON s.SalCalRuleID = sc.SalCalRuleID AND sc.IsFixedStd = 1

	--and not exists (select 1 from #tblEmployeeIDList e where e.EmployeeID = s.EmployeeID and (e.NewStaff = 1 or e.TerminatedStaff = 1))
	-- lấy ngày công ở đây
	CREATE TABLE #Tadata (EmployeeID VARCHAR(20), Attdate DATE, HireDate DATE, EmployeeStatusID INT, HolidayStatus INT, WorkingTime FLOAT(53), Std_Hour_PerDays FLOAT(53), Lvamount FLOAT(53), PaidAmount_Des FLOAT(53), UnpaidAmount_Des FLOAT(53), SalaryHistoryID INT, CutSI BIT, EmployeeTypeID INT)

	EXEC sp_WorkingTimeProvider @Month = @Month, @Year = @Year, @fromdate = @FromDate, @todate = @ToDate, @loginId = @LoginID

	IF (OBJECT_ID('SALCAL_CUSTOMIZE_TADATA') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_CUSTOMIZE_TADATA
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_CUSTOMIZE_TADATA @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	IF @StopUPDATE = 0
	BEGIN
		DELETE #Tadata
		WHERE EmployeeID NOT IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		UPDATE #Tadata
		SET SalaryHistoryID = ISNULL(sal.ProbationSalaryHistoryID, sal.SalaryHistoryID)
		FROM #Tadata ta
		INNER JOIN #tblSalDetail sal ON ta.EmployeeID = sal.EmployeeID AND ta.Attdate BETWEEN sal.FromDate AND sal.ToDate

		/*
		update #Tadata set SalaryHistoryID = ISNULL(sal.ProbationSalaryHistoryID, sal.SalaryHistoryID)
		,WorkingTime = case when ISNULL(sc.IsSTDMinusUnpaidLeave,0) =0 or WorkingTime is not null then WorkingTime	else
		case when
		HolidayStatus = 0 and CutSI = 0 and ISNULL(Lvamount,0) <8 then 8 - ISNULL(Lvamount,0) else 0 end
		end
		from #Tadata  ta
		inner join #tblSalDetail sal on ta.EmployeeID= sal.EmployeeID and ta.Attdate  between sal.FromDate and sal.ToDate
		inner join tblSalaryCalculationRule sc on sal.SalCalRuleID = sc.SalCalRuleID
		*/
		DELETE #Tadata
		WHERE SalaryHistoryID IS NULL
			--delete đi để câu dưới nó đừng tính nữa mất thời gian
			--delete #Tadata  where EmployeeID in(select EmployeeID from #tblCustomAttendanceData)
	END

	SELECT EmployeeID, ta.SalaryHistoryID, SUM(CASE
				WHEN ISNULL(HolidayStatus, 0) <> 1
					THEN 1
				ELSE 0
				END) AS STD_PerHistoryID, ROUND(SUM(CASE
					WHEN ISNULL(HolidayStatus, 0) = 0
						THEN ta.WorkingTime / isnull(ta.Std_Hour_PerDays, 8)
					ELSE 0
					END), @ROUND_TOTAL_WORKINGDAYS) AS AttDays, SUM(ta.PaidAmount_Des / isnull(ta.Std_Hour_PerDays, 8)) AS PaidLeaves, SUM(ta.UnpaidAmount_Des / isnull(ta.Std_Hour_PerDays, 8)) AS UnPaidLeaves, SUM(CASE
				WHEN HolidayStatus = 1
					THEN 1
				ELSE 0
				END) AS TotalSunDay, SUM(CASE
				WHEN CutSI = 1 AND HolidayStatus <> 1
					THEN 1
				ELSE 0
				END) TotalNonWorkingDays
	INTO #tblSal_AttendanceData_PerHistory
	FROM #Tadata ta
	GROUP BY EmployeeID, ta.SalaryHistoryID

	-- mặc dù đã xóa ở trên nhưng ở đây vẫn nên xóa 1 lần nữa
	--delete #tblSal_AttendanceData_PerHistory where EmployeeID in(select EmployeeID from #tblCustomAttendanceData)
	-- insert các giá trị đã được chuẩn bị sẵn
	--  insert into #tblSal_AttendanceData_PerHistory(EmployeeID,SalaryHistoryID,STD_PerHistoryID,AttDays,PaidLeaves,UnPaidLeaves,TotalNonWorkingDays)
	--  select sd.EmployeeID,ISNULL(sd.ProbationSalaryHistoryID,sd.SalaryHistoryID),sd.STD_WD,c.AttDays,c.PaidLeaves,c.UnpaidLeaves,sd.STD_WD - ISNULL(c.AttDays,0) - ISNULL(c.PaidLeaves,0) - ISNULL(c.UnpaidLeaves,0)
	--   from #tblSalDetail sd
	--  inner join #tblCustomAttendanceData c on sd.EmployeeID = c.EmployeeID
	--  where sd.LatestSalEntry = 1
	SELECT EmployeeID, sum(STD_PerHistoryID) AS STDWorkingDays, SUM(AttDays) AS AttDays, SUM(PaidLeaves) AS PaidLeaves, SUM(UnPaidLeaves) AS UnPaidLeaves, SUM(ISNULL(AttDays, 0) + ISNULL(PaidLeaves, 0)) AS TotalPaidDays, SUM(TotalSunDay) AS TotalSunDay, 0 AS ProbationHours, 0 AS DeductionHours, sum(TotalNonWorkingDays) AS TotalNonWorkingDays
	INTO #tblSal_AttendanceData
	FROM #tblSal_AttendanceData_PerHistory
	GROUP BY EmployeeID

	UPDATE #tblSal_AttendanceData
	SET STDWorkingDays = sd.STD_WD
	FROM #tblSal_AttendanceData sal
	INNER JOIN #tblSalDetail sd ON sal.employeeId = sd.EmployeeID AND sd.LatestSalEntry = 1

	SELECT lv.EmployeeID, lv.LeaveCode, lv.LvAmount, lv.LeaveDate, lt.PaidRate, lv.LeaveStatus, lt.CutDiligent, ISNULL(lt.LeaveCategory, 0) AS LeaveCategory
	INTO #tblLvHistory
	FROM tblLvHistory lv
	INNER JOIN tblLeaveType lt ON lv.LeaveCode = lt.LeaveCode AND lv.EmployeeID IN (
			SELECT te.EmployeeID
			FROM #tblEmployeeIDList te
			
			EXCEPT
			
			SELECT c.EmployeeID
			FROM #tblCustomAttendanceData c -- except để giảm thời gian thực thi bớt di
			) AND lv.LeaveDate BETWEEN @FromDate AND @ToDate

	-- xóa những ngày nghỉ trong phần chưa đi làm hoặc nghỉ dài hạn đi
	DELETE #tblLvHistory
	FROM #tblLvHistory lv
	INNER JOIN #Tadata ta ON lv.EmployeeID = ta.EmployeeID AND lv.LeaveDate = ta.Attdate AND ta.CutSI = 1

	-- nhập custom leave
	DECLARE @CustomLeaveCodeInsert VARCHAR(max) = ''

	CREATE TABLE #tempDataForLeave (EmployeeID VARCHAR(20), LeaveCode VARCHAR(50), lvAmountdays FLOAT(53))

	SELECT @CustomLeaveCodeInsert += '
	insert into #tempDataForLeave(EmployeeID,LeaveCode,lvAmountdays)
	select EmployeeID,''' + LeaveCode + ''',' + LeaveCode + ' as LvAmountDays
	from #tblCustomAttendanceData where ' + LeaveCode + ' <>0'
	FROM tblLeaveType lt
	WHERE lt.LeaveCode IN (
			SELECT column_Name
			FROM INFORMATION_SCHEMA.COLUMNS c
			WHERE c.TABLE_NAME = 'tblCustomAttendanceData'
			)

	EXEC (@CustomLeaveCodeInsert)

	INSERT INTO #tblLvHistory (EmployeeID, LeaveCode, LvAmount, LeaveDate, PaidRate, LeaveStatus, CutDiligent, LeaveCategory)
	SELECT lv.EmployeeID, lv.LeaveCode, lv.lvAmountdays * 8, @ToDateTruncate AS LeaveDate, lt.PaidRate, 3 AS LeaveStatus, 0 AS CutDiligent, ISNULL(lt.LeaveCategory, 0) AS LeaveCategory
	FROM #tempDataForLeave lv
	INNER JOIN tblLeaveType lt ON lv.LeaveCode = lt.LeaveCode

	DROP TABLE #tempDataForLeave

	-- Nhung ngay khong di làm mà không có đăng ký nghỉ, không phải cuối tuần hay ngày lễ thì tính là nghỉ không phép
	IF NOT EXISTS (
			SELECT 1
			FROM tblLeaveType
			WHERE LeaveCode IN (
					SELECT Value
					FROM tblParameter
					WHERE Code = 'NO_TA_LEAVE_CODE'
					)
			)
		UPDATE tblParameter
		SET Value = (
				SELECT TOP 1 LeaveCode
				FROM tblLeaveType
				WHERE PaidRate = 0
				)
		WHERE Code = 'NO_TA_LEAVE_CODE'

	INSERT INTO #tblLvHistory (EmployeeID, LeaveCode, LvAmount, LeaveDate, PaidRate, LeaveStatus, LeaveCategory)
	SELECT EmployeeID, (
			SELECT Value
			FROM tblParameter
			WHERE Code = 'NO_TA_LEAVE_CODE'
			), Std_Hour_PerDays - (isnull(WorkingTime, 0) + isnull(Lvamount, 0)), Attdate, 0, 2, 1
	FROM #Tadata ta
	WHERE ta.HolidayStatus = 0 AND isnull(WorkingTime, 0) + isnull(Lvamount, 0) < Std_Hour_PerDays

	UPDATE TA
	SET Lvamount = isnull(Lvamount, 0) + (Std_Hour_PerDays - (isnull(WorkingTime, 0) + isnull(Lvamount, 0))), UnpaidAmount_Des = isnull(UnpaidAmount_Des, 0) + (Std_Hour_PerDays - (isnull(WorkingTime, 0) + isnull(Lvamount, 0)))
	FROM #Tadata ta
	WHERE ta.HolidayStatus = 0 AND isnull(WorkingTime, 0) + isnull(Lvamount, 0) < Std_Hour_PerDays

	SELECT LeaveCode, EmployeeID, round(SUM(LvAmount) / 8.0, @ROUND_ATTDAYS) AS LvAmount
	INTO #LeaveTMpDAta
	FROM (
		SELECT EmployeeID, LeaveDate, LeaveCode, LvAmount
		FROM #tblLvHistory
		
		UNION
		
		SELECT ta.EmployeeID, ta.Attdate AS LeaveDate, es.LeaveCodeForCutSI AS LeaveCode, 8 AS lvAmount
		FROM #Tadata ta
		INNER JOIN tblEmployeeStatus es ON ta.EmployeeStatusID = es.EmployeeStatusID AND es.LeaveCodeForCutSI IN (
				SELECT LeaveCode
				FROM tblLeaveType
				)
		WHERE ta.CutSI = 1 AND es.LeaveCodeForCutSI IS NOT NULL AND ta.HolidayStatus = 0
		) lv
	GROUP BY EmployeeID, LeaveCode

	-- DECLARE @altertblSal_AttDataSumary_ForReport NVARCHAR(max) = ''
	-- DECLARE @currLeaveCode NVARCHAR(50) = ''
	-- SELECT @altertblSal_AttDataSumary_ForReport += 'if col_length(''tblSal_AttDataSumary_ForReport'',''' + LeaveCode + ''') is null
	-- alter table tblSal_AttDataSumary_ForReport add ' + LeaveCode + ' float
	-- '
	-- FROM tblLeaveType
	-- EXEC (@altertblSal_AttDataSumary_ForReport)
	-- INSERT INTO tblSal_AttDataSumary_ForReport (EmployeeID, Month, Year, PeriodID)
	-- SELECT EmployeeID, @Month, @Year, @PeriodID
	-- FROM #tblEmployeeIDList e
	-- WHERE NOT EXISTS (
	-- 		SELECT 1
	-- 		FROM tblSal_AttDataSumary_ForReport s
	-- 		WHERE e.EmployeeID = s.EmployeeID AND s.Month = @Month AND s.Year = @Year AND s.PeriodID = @PeriodID
	-- 		)
	-- -- phải chơi hết ko thôi mấy cái update rồi giờ ko update nữa là khộ
	-- SELECT DISTINCT LeaveCode
	-- INTO #LeaveCode
	-- FROM tblLeaveType
	-- IF @CalculateRetro = 0
	-- 	WHILE EXISTS (
	-- 			SELECT 1
	-- 			FROM #LeaveCode
	-- 			)
	-- 	BEGIN
	-- 		SELECT @currLeaveCode = LeaveCode
	-- 		FROM #LeaveCode
	-- 		SET @altertblSal_AttDataSumary_ForReport = 'update tblSal_AttDataSumary_ForReport set ' + @currLeaveCode + ' = LvAmount from tblSal_AttDataSumary_ForReport sal
	-- 	left join #LeaveTMpDAta tmp on sal.EmployeeID = tmp.EmployeeID  and tmp.LEaveCode = ''' + @currLeaveCode + '''
	-- 	where sal.EmployeeID in(select EmployeeID from #tblEmployeeIDList) and sal.Month = ' + CAST(@Month AS VARCHAR(2)) + ' and sal.Year =' + CAST(@Year AS VARCHAR(4)) + ' and sal.PeriodID = ' + CAST(@PeriodID AS VARCHAR(2))
	-- 		EXEC (@altertblSal_AttDataSumary_ForReport)
	-- 		DELETE #LeaveCode
	-- 		WHERE LeaveCode = @currLeaveCode
	-- 		DELETE #LeaveTMpDAta
	-- 		WHERE LeaveCode = @currLeaveCode
	-- 	END
	DROP TABLE #LeaveTMpDAta

	DELETE #tblLvHistory
	WHERE LeaveCategory = 0

	--TRIPOD: process Allowance
	SET ANSI_WARNINGS ON;

	EXEC sp_processAllAllowance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @SalCal = 1

	UPDATE #tblSalDetail
	SET GrossSalary = BasicSalary

	-- cap nhat tong luong
	UPDATE sal
	SET TotalSalary = ISNULL(BasicSalary, 0) + ISNULL(c.Allowance, 0), BasicSalary = ISNULL(BasicSalary, 0) + ISNULL(c.Allowance, 0)
	FROM #tblSalDetail sal
	CROSS APPLY dbo.fn_CurrentSalaryByDate_TRIPOD(@ToDate, @LoginID) c
	WHERE sal.SalaryHistoryID = c.SalaryHistoryID

	--UPDATE sal set TotalSalary = c.Totalsalary from #tblSalDetail sal
	--inner join dbo.fn_CurrentSalaryByDate_TRIPOD(@FromDate) c on sal.SalaryHistoryID = c.SalaryHistoryID
	--where sal.TotalSalary is null
	--Insert into Salary PITAmt table
	SELECT EmployeeID, 'Has no salary entry' AS Reason, CAST(1 AS BIT) AS DoNotSalCal
	INTO #TableVarSalError
	FROM #tblEmployeeIDList
	WHERE EmployeeID IN (
			SELECT DISTINCT EmployeeID
			FROM #tblSalDetail
			WHERE TotalSalary <= 0
			)

	DELETE
	FROM #tblSalDetail
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #TableVarSalError
			WHERE DoNotSalCal = 1
			)

	--DELETE FROM #tblEmployeeIDList WHERE EmployeeID in (select EmployeeID from #TableVarSalError where DoNotSalCal = 1)
	------------------------------Calculate salary per day------------------------------------------
	UPDATE sal
	SET OTSalary = fnTO.OTSalary
	FROM (
		SELECT DISTINCT Fromdate
		FROM #tblSalDetail
		) f
	CROSS APPLY (
		SELECT *
		FROM dbo.fn_CurrentOTSalary_byDate(f.FromDate, @LoginID) fnTO
		) fnTO
	INNER JOIN #tblSalDetail sal ON sal.EmployeeID = fnTO.EmployeeID AND sal.SalaryHistoryID = fnTO.SalaryHistoryID
	INNER JOIN tblSalaryCalculationRule sc ON sal.SalCalRuleID = sc.SalCalRuleID AND isnull(IsDaily, 0) = 0 AND isnull(IsHourly, 0) = 0

	IF @PROBATION_PERECNT > 0 AND @PROBATION_PERECNT < 100.0
		UPDATE #tblSalDetail
		SET OTSalary = OTSalary * @PROBATION_PERECNT / 100.0
		WHERE BasicSalaryOrg IS NOT NULL AND BasicSalaryOrg <> BasicSalary

	--TRIPOD OT
	UPDATE #tblSalDetail
	SET OTSalary = CASE
			WHEN ISNULL(TotalSalary, 0) <> 0
				THEN TotalSalary
			ELSE OTSalary
			END

	UPDATE sal
	SET sal.OTSalary = sal.OTSalary * ISNULL(cs.[ExchangeRate], 1)
	FROM #tblSalDetail sal
	INNER JOIN #EmployeeExchangeRate cs ON sal.EmployeeID = cs.EmployeeID AND cs.CurrencyCode = sal.CurrencyCode

	UPDATE #tblSalDetail
	SET SalaryPerDay = CASE
			WHEN isnull(IsDaily, 0) = 1
				THEN BasicSalary
			WHEN isnull(IsHourly, 0) = 1
				THEN BasicSalary * 8.0
			ELSE TotalSalary / STD_WD
			END, SalaryPerDayOT = CASE
			WHEN isnull(IsDaily, 0) = 1
				THEN BasicSalary
			WHEN isnull(IsHourly, 0) = 0
				THEN OTSalary / STD_WD
			END
	FROM #tblSalDetail sal
	INNER JOIN tblSalaryCalculationRule sc ON sal.SalCalRuleID = sc.SalCalRuleID

	------------------------------Calculate salary per hour------------------------------------------
	UPDATE #tblSalDetail
	SET SalaryPerHour = CASE
			WHEN isnull(IsHourly, 0) = 1
				THEN BasicSalary
			ELSE SalaryPerDay / 8.0
			END, SalaryPerHourOT = CASE
			WHEN isnull(IsHourly, 0) = 1
				THEN BasicSalary
			ELSE SalaryPerDayOT / sal.WorkingHoursPerDay
			END
	FROM #tblSalDetail sal
	INNER JOIN tblSalaryCalculationRule sc ON sal.SalCalRuleID = sc.SalCalRuleID

	------------------------------Calculate Leave---------------------------------
	IF (OBJECT_ID('SALCAL_LEAVE_AUTOMATIC_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_LEAVE_AUTOMATIC_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_LEAVE_AUTOMATIC_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	CREATE TABLE #DataLeave (EmployeeID VARCHAR(20), LeaveDate DATETIME, LeaveCode VARCHAR(20), LeaveStatus INT, LeaveDays FLOAT, LeaveHours FLOAT, PaidRate FLOAT)

	CREATE TABLE #TableVarLeaveAmount (EmployeeID VARCHAR(20), SalaryHistoryID BIGINT, ContractSalary FLOAT(53), LeaveDate DATETIME, LeaveCode VARCHAR(20), PaidRate FLOAT, UnpaidRate FLOAT, LeaveDays FLOAT, LeaveHours FLOAT, SalaryPerDay FLOAT(53), AmountPaid FLOAT(53), AmountDeduct FLOAT(53))

	-------------------------Leave Days---------------------------------------
	INSERT INTO #DataLeave (EmployeeID, LeaveDate, LeaveCode, LeaveStatus, LeaveHours, LeaveDays, PaidRate)
	SELECT lv.EmployeeID, lv.LeaveDate, lv.LeaveCode, lv.LeaveStatus, lv.LvAmount, round(lv.LvAmount / 8.0, @ROUND_ATTDAYS), lv.PaidRate
	FROM #tblLvHistory lv
	WHERE lv.LeaveCategory = 1 AND Lv.LeaveCode <> 'FWC'

	--Remove illegal records
	DELETE l
	FROM #DataLeave l
	WHERE datename(dw, l.LeaveDate) = 'Sunday' AND EXISTS (
			SELECT 1
			FROM tblWSchedule ws
			WHERE ws.EmployeeID = l.EmployeeID AND ws.ScheduleDate = l.LeaveDate AND ws.HolidayStatus > 0
			)

	-------------------------Leave Amount---------------------------------------
	INSERT INTO #TableVarLeaveAmount (EmployeeID, LeaveCode, LeaveDays, LeaveHours, LeaveDate, PaidRate, UnpaidRate, SalaryHistoryID, SalaryPerDay) (SELECT t.EmployeeID, LeaveCode, SUM(ISNULL(LeaveDays, 0)), SUM(ISNULL(LeaveHours, 0)), LeaveDate, PaidRate, 100 - PaidRate, SalaryHistoryID, MAX(SalaryPerDay) AS SalaryPerDay FROM #DataLeave t INNER JOIN #tblSalDetail sal ON t.EmployeeID = sal.EmployeeID AND t.LeaveDate BETWEEN FromDate AND ToDate GROUP BY t.EmployeeID, LeaveCode, LeaveDate, PaidRate, SalaryHistoryID)

	---------------------------------------------------------------------------------------
	UPDATE #TableVarLeaveAmount
	SET AmountPaid = (PaidRate / 100.00) * LeaveDays * SalaryPerDay -- ContractSalary * (PaidRate/100.00) * (LeaveDays/TotalDays) --chinh xac hon lay SalaryPerDays * LeaveDays
		, AmountDeduct = (UnpaidRate / 100.00) * LeaveDays * SalaryPerDay -- ContractSalary * (UnpaidRate/100.00) * (LeaveDays/TotalDays) --chinh xac hon lay SalaryPerDays * LeaveDays

	-------------------------UPDATE into #tblSal_PaidLeave_Detail_des-------------------------------------
	INSERT INTO #tblSal_PaidLeave_Detail_des (EmployeeID, LeaveCode, Month, Year, SalaryHistoryID, LeaveDays, LeaveHour, AmountDeduct, AmountPaid, PeriodID) (SELECT EmployeeID, LeaveCode, @Month, @Year, SalaryHistoryID, SUM(LeaveDays), SUM(LeaveHours), ROUND(SUM(AmountDeduct), @ROUND_SALARY_UNIT), ROUND(SUM(AmountPaid), @ROUND_SALARY_UNIT), @PeriodID FROM #TableVarLeaveAmount GROUP BY EmployeeID, LeaveCode, SalaryHistoryID)

	-- tính tổng các ngày ko đi làm
	UPDATE #tblSalDetail
	SET UnpaidLeaveAmount = ROUND(tmp.AmountDeduct, @ROUND_SALARY_UNIT)
	FROM #tblSalDetail sal
	INNER JOIN tblSalaryCalculationRule sc ON sal.SalCalRuleID = sc.SalCalRuleID AND sc.IsSTDMinusUnpaidLeave = 1 -- nếu là STD trừ đi ngày nghỉ
	INNER JOIN (
		SELECT EmployeeID, SalaryHistoryID, SUM(ISNULL(AmountDeduct, 0)) AmountDeduct
		FROM #TableVarLeaveAmount
		GROUP BY EmployeeID, SalaryHistoryID
		) tmp ON sal.EmployeeID = tmp.EmployeeID AND sal.SalaryHistoryID = tmp.SalaryHistoryID

	------------------------UPDATE into #tblSal_PaidLeave_des-----------------------
	INSERT INTO #tblSal_PaidLeave_des (EmployeeID, LeaveCode, [Month], [Year], LeaveDays, LeaveHour, AmountDeduct, AmountPaid, SalaryNameID, SalaryTermID, PeriodID) (SELECT EmployeeID, LeaveCode, @Month, @Year, SUM(ISNULL(LeaveDays, 0)), SUM(ISNULL(LeaveHours, 0)), ROUND(SUM(ISNULL(AmountDeduct, 0)), @ROUND_SALARY_UNIT), ROUND(SUM(ISNULL(AmountPaid, 0)), @ROUND_SALARY_UNIT), '', 0, @PeriodID FROM #TableVarLeaveAmount GROUP BY EmployeeID, LeaveCode)

	------------------------------Calculate Actual salary---------------------------------
	-- Luong thuc nhan cua thang
	SET ANSI_NULLS ON;
	SET ANSI_PADDING ON;
	SET ANSI_WARNINGS ON;
	SET ARITHABORT ON;
	SET CONCAT_NULL_YIELDS_NULL ON;
	SET QUOTED_IDENTIFIER ON;
	SET NUMERIC_ROUNDABORT OFF;


	--TRIPOD: gross salary - (gross salary with allowances/number of working hours * (number of working hours - number of actual working hours))
	UPDATE #tblSalDetail
	SET RegularAmt = ROUND(GrossSalary - ((TotalSalary / m.STD_WorkingHours) * (m.STD_WorkingHours - WorkingHrs_Total)), 0), PaidLeaveAmt = ROUND(PaidLeaveHrs_Total * (TotalSalary / m.STD_WorkingHours), 0), SalaryPerHour = (TotalSalary / m.STD_WorkingHours), SalaryPerHourOT = (TotalSalary / m.STD_WorkingHours), UnpaidLeaveAmount = ROUND(a.UnpaidLeaveHrs * (TotalSalary / m.STD_WorkingHours), 0)
	FROM #tblSalDetail s
	INNER JOIN #AttendanceSummary a ON a.EmployeeID = s.EmployeeID AND CAST(a.FromDate AS DATE) = CAST(s.FromDate AS DATE) AND CAST(a.ToDate AS DATE) = CAST(s.ToDate AS DATE)
	LEFT JOIN #tmpMonthlyPayrollCheckList m ON m.EmployeeID = s.EmployeeID
    WHERE s.isTwoSalLevel = 0

	--Xử lý cho người có 2 dòng lương => tính theo thực tế đi làm
	UPDATE #tblSalDetail
	SET RegularAmt = a.WorkingHrs_Total * (GrossSalary / (m.STD_WorkingHours)), PaidLeaveAmt = ROUND(PaidLeaveHrs_Total * (GrossSalary / m.STD_WorkingHours), 0), SalaryPerHour = (GrossSalary / m.STD_WorkingHours), SalaryPerHourOT = (GrossSalary / m.STD_WorkingHours), UnpaidLeaveAmount = ROUND(a.UnpaidLeaveHrs * (GrossSalary / m.STD_WorkingHours), 0)
	FROM #tblSalDetail s
	INNER JOIN #AttendanceSummary a ON a.EmployeeID = s.EmployeeID AND CAST(a.FromDate AS DATE) = CAST(s.FromDate AS DATE) AND CAST(a.ToDate AS DATE) = CAST(s.ToDate AS DATE)
	LEFT JOIN #tmpMonthlyPayrollCheckList m ON m.EmployeeID = s.EmployeeID
	WHERE s.isTwoSalLevel = 1


	-- SELECT s.EmployeeID, s.FromDate, s.ToDate, a.FromDate, a.ToDate FROM #tblSalDetail s
	-- INNER JOIN #AttendanceSummary a ON a.EmployeeID = s.EmployeeID AND CAST(a.FromDate AS DATE) = CAST(s.FromDate AS DATE) AND CAST(a.ToDate AS DATE) = CAST(s.ToDate AS DATE)


	--TRIPOD: If salary increases in the middle of the month: Gross salary - leave allowance (including all types of leave and late/early departure) - ((new gross salary - old gross salary) /  number of working hours * number of working hours have old gross salary))
	UPDATE #tblSalDetail
	SET DaysOfSalEntry = ISNULL(ca.WorkingDays_Total, 0) + ISNULL(ca.PaidLeaveDays_Total, 0) + (ISNULL(ca.RegularWorkdays, 0) - ISNULL(ca.STD_WorkingDays, 0)), STDPerSalaryHistoryId = CASE
			WHEN ca.STD_WorkingDays > sal.STD_WD
				THEN sal.STD_WD
			ELSE ca.STD_WorkingDays
			END
	FROM #tblSalDetail sal
	CROSS APPLY (
		SELECT *
		FROM #AttendanceSummary ta
		WHERE sal.EmployeeID = ta.EmployeeID AND ta.SalaryHistoryID = ISNULL(sal.ProbationSalaryHistoryID, sal.SalaryHistoryID)
		) ca

	--TRIPOD: Annual bonus, bonus 6 month total
	UPDATE #tblSalDetail
	SET AnnualBonus_Total = ROUND(((sal.BasicSalaryOrg / a.NumberDayOfYear) * a.NumberDayOfYear_Actual), 0), AnnualBonus_EvMonth = ROUND(((sal.BasicSalaryOrg / a.NumberDayOfYear) * a.NumberDayOfYear_Actual) / a.ActualMonthInYear, 0), Bonus6Month_Total = ROUND(((c.Salary / a.Number6DayMonth * a.Number6DayMonth_Actual) * (a.Bonus6MonthAllowance / 100) * (a.RatioBonus6Month / 100)), 0), Bonus6M_EveryMonth = ROUND(((c.Salary / a.Number6DayMonth * a.Number6DayMonth_Actual) * (a.Bonus6MonthAllowance / 100) * (a.RatioBonus6Month / 100)) / 6, 0)
	FROM #tblSalDetail sal
	INNER JOIN #tmpMonthlyPayrollCheckList a ON a.EmployeeID = sal.EmployeeID
	LEFT JOIN dbo.fn_CurrentSalaryByDate_TRIPOD(@ToDate, @LoginID) c ON c.EmployeeID = sal.EmployeeID AND c.SalaryHistoryID = sal.SalaryHistoryID
    WHERE sal.LatestSalEntry = 1

	IF @CalculateRetro = 0
		-- update tblSal_AttDataSumary_ForReport set TotalPaidDays = ISNULL(s.AttDays,0)+ISNULL(s.PaidLeaves,0)
		-- ,Attdays = s.AttDays
		-- ,PaidLeaves = s.PaidLeaves
		-- ,UnPaidLeaves = s.UnPaidLeaves
		-- ,STDWorkingDays = s.STDWorkingDays
		-- ,TotalNonWorkingDays = s.TotalNonWorkingDays
		-- ,TotalSunDay = s.TotalSunDay
		--  from tblSal_AttDataSumary_ForReport sal
		--  inner join  #tblSal_AttendanceData s on sal.EmployeeId = s.EmployeeId and sal.Month=@month and sal.Year = @Year and sal.PeriodID= @PeriodID
		-- update sal set ActualMonthlyBasic =case
		-- 	 when isnull(sc.IsSTDMinusUnpaidLeave,0) =0 then SalaryPerDay * DaysOfSalEntry
		-- 	 else
		-- 		 /*case when STD_WD = STDPerSalaryHistoryId then BasicSalary else BasicSalary*STDPerSalaryHistoryId /STD_WD end*/ BasicSalary - isnull(UnpaidLeaveAmount,0)
		-- 	 end
		-- 	 from #tblSalDetail sal
		-- 	inner join tblSalaryCalculationRule sc on sal.SalCalRuleID = sc.SalCalRuleID
		UPDATE #tblSalDetail
		SET ActualMonthlyBasic = ROUND(ISNULL(RegularAmt, 0) + ISNULL(PaidLeaveAmt, 0), @ROUND_SALARY_UNIT)

	-- trừ thêm cho các ngày ko đi làm
	UPDATE sal
	SET ActualMonthlyBasic = ActualMonthlyBasic - (isnull(TotalNonWorkingDays, 0) * SalaryPerDay)
	FROM #tblSalDetail sal
	INNER JOIN #tblSal_AttendanceData_PerHistory n ON sal.EmployeeId = n.Employeeid AND sal.SalaryHistoryID = n.SalaryHistoryID
	INNER JOIN tblSalaryCalculationRule sc ON sal.SalCalRuleID = sc.SalCalRuleID
	WHERE isnull(sc.IsSTDMinusUnpaidLeave, 0) = 1

	-- IF COL_LENGTH('tblSal_Sal_Detail', 'RegularAmt') IS NULL
	-- BEGIN
	-- 	ALTER TABLE tblSal_Sal_Detail ADD RegularAmt MONEY
	-- END

	-- IF COL_LENGTH('tblSal_Sal_Detail', 'PaidLeaveAmt') IS NULL
	-- BEGIN
	-- 	ALTER TABLE tblSal_Sal_Detail ADD PaidLeaveAmt MONEY
	-- END

	-- IF COL_LENGTH('tblSal_Sal_Detail', 'GrossSalary') IS NULL
	-- BEGIN
	-- 	ALTER TABLE tblSal_Sal_Detail ADD GrossSalary MONEY
	-- END

	IF (OBJECT_ID('SALCAL_MONTHLYBASIC_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_MONTHLYBASIC_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_MONTHLYBASIC_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	------- lấy thông tin của Allowance ở đây do cần thông tin này
	CREATE TABLE #tblAllowance (EmployeeID VARCHAR(20), AllowanceID INT, AllowanceRuleID INT, AllowanceCode VARCHAR(200), SalaryHistoryID BIGINT, SalCalRuleID INT, FromDate DATETIME, ToDate DATETIME, DefaultAmount FLOAT(53), DefaultAmount_WithoutCustomAmount FLOAT(53), ReceiveAmount FLOAT(53), TaxableAmount FLOAT(53), UntaxableAmount FLOAT(53), TakeHome BIT, STD_WD FLOAT, TotalPaidDays FLOAT, CurrencyCode VARCHAR(20), Raw_DefaultAmount FLOAT(53), Raw_CurrencyCode NVARCHAR(20), Raw_ExchangeRate FLOAT(53), IsMutilCurrencyCode BIT, RetroAmount MONEY, RetroAmountNonTax MONEY, TaxFreeMaxAmount MONEY, MonthlyCustomAmount MONEY, MonthlyCustomReceiveAmount MONEY, LatestSalEntry BIT, IsTaxable BIT)

	CREATE TABLE #AllowanceCodeList (AllowanceCode VARCHAR(20), AllowanceID INT, DefaultAmount FLOAT(53), AllowanceRuleID INT, ForSalary BIT, TaxfreeMaxAmount FLOAT(53), IsHouseAllowance BIT, isUniformAllowance BIT, BasedOnSalaryScale BIT, IsTaxable BIT, IsMutilCurrencyCode BIT)

	INSERT INTO #AllowanceCodeList (AllowanceID, AllowanceCode, ForSalary, AllowanceRuleID, TaxfreeMaxAmount, IsHouseAllowance, isUniformAllowance, DefaultAmount, BasedOnSalaryScale, IsTaxable, IsMutilCurrencyCode)
	SELECT AllowanceID, AllowanceCode, ForSalary, AllowanceRuleID, TaxfreeMaxAmount, IsHouseAllowance, isUniformAllowance, DefaultAmount, BasedOnSalaryScale, IsTaxable, IsMutilCurrencyCode
	FROM tblAllowanceSetting
	WHERE AllowanceCode IN (
			SELECT c.COLUMN_NAME
			FROM INFORMATION_SCHEMA.COLUMNS c
			WHERE c.TABLE_NAME = N'tblSalaryHistory' AND c.DATA_TYPE = 'money' AND c.COLUMN_NAME NOT IN ('Salary', 'InsSalary', 'NETSalary') AND Visible = 1 AND ISNULL(ForSalary, 0) = 1
			)

	INSERT INTO #tblAllowance (EmployeeID, AllowanceID, AllowanceRuleID, AllowanceCode, SalaryHistoryID, FromDate, ToDate, DefaultAmount, TakeHome, SalCalRuleID, TotalPaidDays, IsMutilCurrencyCode, TaxFreeMaxAmount, LatestSalEntry, IsTaxable)
	SELECT s.EmployeeID, a.AllowanceID, a.AllowanceRuleID, a.AllowanceCode, s.SalaryHistoryID, s.FromDate, s.ToDate, a.DefaultAmount, a.ForSalary, s.SalCalRuleID, s.DaysOfSalEntry
		--,case when BasedOnSalaryScale = 1 then DaysOfSalEntry else s.DaysOfSalEntry end
		, a.IsMutilCurrencyCode, CASE
			WHEN isnull(a.IsTaxable, 0) = 0
				THEN 9999999999
			ELSE isnull(TaxFreeMaxAmount, 0)
			END AS TaxFreeMaxAmount, s.LatestSalEntry, a.IsTaxable
	FROM #AllowanceCodeList a
	CROSS JOIN #tblSalDetail s

	--on S.LatestSalEntry = 1 or a.BasedOnSalaryScale =1
	--left join #tblSal_AttendanceData sal on s.EmployeeID = sal.EmployeeID
	SET @Query = ''

	SELECT @Query += 'UPDATE #tblAllowance set DefaultAmount = sh.[' + c.AllowanceCode + ']
,CurrencyCode =' + CASE
			WHEN isnull(c.IsMutilCurrencyCode, 0) = 1
				THEN 'sh.[' + c.AllowanceCode + '_CurrencyCode]'
			ELSE 'sh.CurrencyCode'
			END + '
from #tblAllowance tmp
inner join tblSalaryHistory sh on tmp.SalaryHistoryID = sh.SalaryHistoryID and AllowanceID = ' + cast(c.AllowanceID AS VARCHAR) + '
'
	FROM #AllowanceCodeList c

	EXECUTE sp_executesql @Query

	UPDATE al
	SET SalaryHistoryID = ISNULL(s.ProbationSalaryHistoryID, s.SalaryHistoryID)
	FROM #tblAllowance al
	INNER JOIN #tblSalDetail s ON al.EmployeeID = s.EmployeeID AND al.LatestSalEntry = s.LatestSalEntry
	WHERE al.SalaryHistoryID <> ISNULL(s.ProbationSalaryHistoryID, s.SalaryHistoryID)

	DROP TABLE #AllowanceCodeList

	DELETE
	FROM #tblAllowance
	WHERE ISNULL(DefaultAmount, 0) = 0 AND LatestSalEntry = 0

	--tringuyen:huong tron goi & chuyen can lay theo muc luong moi
	DELETE
	FROM #tblAllowance
	WHERE AllowanceRuleID IN (1, 9) AND LatestSalEntry = 0

	-- kiểm tra coi có thằng nào bị miss exchange rate nữa hay ko
	INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID)
	SELECT 'Exchange Rate not seted!', 'Exchange rate for "' + a.CurrencyCode + '" is not seted!, Please complete Function "Currency Setting" first!', @loginID - 1000
	FROM #tblAllowance a
	INNER JOIN #tblSalDetail sal ON a.EmployeeID = sal.EmployeeID AND sal.LatestSalEntry = 1
	LEFT JOIN #EmployeeExchangeRate c ON a.CurrencyCode = c.CurrencyCode AND c.EmployeeID = a.EmployeeID
	WHERE isnull(a.CurrencyCode, 'vnd') <> 'vnd' AND c.[ExchangeRate] IS NULL

	IF @@ROWCOUNT > 0
	BEGIN
		-- nếu có lỗi thì
		RETURN;
	END

	-- update tỷ giá cho thằng default Amount trước khi tính toán để cho đúng hơn
	--,Raw_DefaultAmount float(53)
	--	,Raw_ReceiveAmount float(53)
	--	,Raw_ExchangeRate float(53)
	UPDATE al
	SET DefaultAmount = al.DefaultAmount * isnull(c.[ExchangeRate], 1), Raw_ExchangeRate = c.[ExchangeRate], Raw_DefaultAmount = al.DefaultAmount, Raw_CurrencyCode = al.CurrencyCode
	FROM #tblAllowance al
	INNER JOIN #tblSalDetail sal ON al.EmployeeID = sal.EmployeeID AND sal.LatestSalEntry = 1
	LEFT JOIN #EmployeeExchangeRate c ON al.CurrencyCode = c.CurrencyCode AND c.EmployeeID = al.EmployeeID

	IF @PROBATION_PERECNT < 100.0
	BEGIN
		--cuoi thang hoac thang sau moi ket thuc thu viec
		UPDATE #tblAllowance
		SET DefaultAmount = DefaultAmount * @PROBATION_PERECNT / 100.0
		FROM #tblAllowance al
		INNER JOIN #tblEmployeeIDList te ON al.EmployeeID = te.EmployeeID
		WHERE te.ProbationEndDate >= @ToDateTruncate AND @PROBATION_PERECNT > 0 AND al.DefaultAmount > 0 AND te.HireDate <> te.ProbationEndDate

		--het thu viec trong thang nay
		UPDATE #tblAllowance
		SET DefaultAmount = DefaultAmount * @PROBATION_PERECNT / 100.0
		FROM #tblAllowance al
		INNER JOIN #tblEmployeeIDList te ON al.EmployeeID = te.EmployeeID
		LEFT JOIN #NewSalaryButTerminated n ON al.EmployeeID = n.EmployeeID
		WHERE (al.LatestSalEntry = 0 OR (al.LatestSalEntry = 1 AND n.EmployeeID IS NOT NULL)) AND al.DefaultAmount > 0 AND @PROBATION_PERECNT > 0 AND te.ProbationEndDate >= @FromDate AND te.ProbationEndDate < @ToDateTruncate AND te.HireDate <> te.ProbationEndDate
	END

	-- kết thúc thông tin của allowance
	-------------------------calculate Adjustment--------------------------------------
	CREATE TABLE #tblAdjustment (EmployeeID VARCHAR(20), SalaryHistoryID INT, BasicSalary FLOAT(53), IncomeID INT, ByAmount BIT, SalaryPercent FLOAT(10), AdjustmentAmount FLOAT(53), Raw_AdjustmentAmount FLOAT(53), EmpAdjustmentID BIGINT, CurrencyCode VARCHAR(20), ExchangeRate FLOAT(53))

	-- xu ly nhung nhan vien co dc thanh toan tien phep chua su dung hang thang
	DELETE p
	FROM dbo.tblAnnualLeavePayment p
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList e
			WHERE p.EmployeeID = e.EmployeeID
			) AND p.Month = @Month AND p.Year = @Year AND ISNULL(p.Approved, 0) = 0

	DELETE p
	FROM dbo.tblAnnualLeavePayment p
	WHERE EXISTS (
			SELECT 1
			FROM tblALPaymentTracking t
			WHERE p.EmployeeID = t.EmployeeID AND p.Month = t.Month AND p.Year = t.Year AND ISNULL(t.ALPaidDays, 0) = 0
			) AND p.Month = @Month AND p.Year = @Year AND ISNULL(p.Approved, 0) = 0

	INSERT INTO tblAnnualLeavePayment (EmployeeID, EffectiveDate, SalaryHistoryID, Salary, ALDays, SalPerDay, Amount, ApprovedAmount, Approved, Year, Month)
	SELECT s.EmployeeID, @FromDate, s.SalaryHistoryID, s.BasicSalary, ap.ALPaidDays, s.SalaryPerDay, ap.ALPaidDays * s.SalaryPerDay, ap.ALPaidDays * s.SalaryPerDay, 0, @Year, @Month
	FROM tblALPaymentTracking ap
	INNER JOIN #tblSalDetail s ON ap.EmployeeID = s.EmployeeID AND s.LatestSalEntry = 1
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList e
			WHERE ap.EmployeeID = e.EmployeeID
			) AND ap.Month = @Month AND ap.Year = @Year AND ISNULL(ALPaidDays, 0) <> 0 AND NOT EXISTS (
			SELECT 1
			FROM dbo.tblAnnualLeavePayment p
			WHERE ap.EmployeeID = p.EmployeeID AND p.Approved = 1 AND ap.Month = p.Month AND ap.year = p.Year
			)

	-- dua vao bang tblPR_Adjustment
	UPDATE a
	SET a.Amount = p.ApprovedAmount
	FROM dbo.tblPR_Adjustment a
	INNER JOIN dbo.tblAnnualLeavePayment p ON a.EmployeeID = p.EmployeeID AND a.Month = p.Month AND a.Year = p.Year
	WHERE a.IncomeID = 5 AND a.Remark LIKE N'System automatic paid AL unused days%' AND a.Month = @Month AND a.Year = @Year AND ISNULL(a.SalaryTerm, 0) = 0 AND ISNULL(a.Amount, 0) <> ISNULL(p.ApprovedAmount, 0) AND EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList e
			WHERE e.EmployeeID = a.EmployeeID
			)

	DELETE a
	FROM dbo.tblPR_Adjustment a
	WHERE a.IncomeID = 5 AND a.Remark LIKE N'System automatic paid AL unused days%' AND NOT EXISTS (
			SELECT 1
			FROM tblAnnualLeavePayment p
			WHERE p.EmployeeID = a.EmployeeID AND p.Month = a.Month AND p.Year = a.Year AND a.IncomeID = 5 AND a.Remark LIKE N'System automatic paid AL unused days'
			) AND a.Month = @Month AND a.Year = @Year AND ISNULL(a.SalaryTerm, 0) = 0

	INSERT INTO dbo.tblPR_Adjustment (EmployeeID, Month, Year, IncomeID, ByAmount, Amount, Remark, SalaryTerm)
	SELECT p.EmployeeID, @Month, @Year, 5, 1, p.ApprovedAmount, N'System automatic paid AL unused days', 0
	FROM dbo.tblAnnualLeavePayment p
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList e
			WHERE p.EmployeeID = e.EmployeeID
			) AND p.Month = @Month AND p.Year = @Year AND NOT EXISTS (
			SELECT 1
			FROM dbo.tblPR_Adjustment a
			WHERE a.EmployeeID = p.EmployeeID AND a.Month = p.Month AND p.Year = a.Year AND a.IncomeID = 5
			)

	--TRIPOD
	SELECT o.EmployeeID, LatestSalEntry, ROUND(a.TotalExcessOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) ExcessOTAmount
	INTO #ExcessOT
	FROM #tblSalDetail o
	LEFT JOIN #AttendanceSummary a ON o.EmployeeID = a.EmployeeID AND CAST(a.FromDate AS DATE) = CAST(o.FromDate AS DATE) AND CAST(a.ToDate AS DATE) = CAST(o.ToDate AS DATE)
	WHERE isnull(a.TotalExcessOT, 0) > 0
	GROUP BY o.EmployeeID, LatestSalEntry, a.TotalExcessOT, o.SalaryPerHourOT

	DELETE
	FROM tblPR_Adjustment
	WHERE IncomeID = 16 AND EmployeeID IN (
			SELECT EmployeeID
			FROM #ExcessOT
			) AND [Month] = @Month AND [Year] = @Year

	INSERT INTO tblPR_Adjustment (EmployeeID, Month, Year, IncomeID, ByAmount, Amount)
	SELECT EmployeeID, @Month, @Year, 16, Amount, Amount
	FROM (
		SELECT EmployeeID, SUM(ExcessOTAmount) AS Amount
		FROM #ExcessOT
		GROUP BY EmployeeID
		) ex

	IF (OBJECT_ID('SALCAL_ADJUSTMENT_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ADJUSTMENT_INITIAL
(

	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
	,@CalculateRetro int =0
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ADJUSTMENT_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID, @CalculateRetro

	-------------------Employees who have Adjustment--------------------------------
	INSERT INTO #tblAdjustment (EmployeeID, IncomeID, ByAmount, SalaryPercent, AdjustmentAmount, EmpAdjustmentID, CurrencyCode, ExchangeRate) (
		SELECT p.EmployeeID, p.IncomeID, ByAmount, SalaryPercent, p.Amount * isnull(c.[ExchangeRate], 1) AS Amount, EmpAdjustmentID, p.CurrencyCode, ISNULL(c.[ExchangeRate], 1) AS ExchangeRate FROM tblPR_Adjustment p INNER JOIN tblIrregularIncome ir ON p.InComeID = ir.IncomeID AND isnull(ir.AppendToPIT, 0) = 0 INNER JOIN #tblSalDetail sal ON p.EmployeeID = sal.EmployeeID AND sal.LatestSalEntry = 1 LEFT JOIN #EmployeeExchangeRate c ON p.EmployeeID = c.EmployeeID AND p.CurrencyCode = c.CurrencyCode WHERE p.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			) AND [Month] = @Month AND [Year] = @Year
		)

	UPDATE #tblAdjustment
	SET CurrencyCode = 'VND'
	WHERE ISNULL(CurrencyCode, '-1') = '-1'

	INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID)
	SELECT 'Exchange Rate not seted!', 'Exchange rate for "' + a.CurrencyCode + '" is not seted!, Please complete Function "Currency Setting" first!', @loginID - 1000
	FROM #tblAdjustment a
	INNER JOIN #tblSalDetail sal ON a.EmployeeID = sal.EmployeeID AND sal.LatestSalEntry = 1
	LEFT JOIN #EmployeeExchangeRate c ON a.CurrencyCode = c.CurrencyCode AND c.EmployeeID = a.EmployeeID
	WHERE isnull(a.CurrencyCode, 'vnd') <> 'vnd' AND c.[ExchangeRate] IS NULL

	IF @@ROWCOUNT > 0
	BEGIN
		-- nếu có lỗi thì
		RETURN;
	END

	------------Determine whether Adjustment is calculated base on Salary percent or not----------
	UPDATE #tblAdjustment
	SET ByAmount = 1 -- ISNULL(ByAmount,1)
		, SalaryPercent = 0 -- ISNULL(SalaryPercent,0)

	UPDATE #tblAdjustment
	SET BasicSalary = sd.BasicSalary
	FROM #tblAdjustment adj, #tblSalDetail sd
	WHERE adj.EmployeeID = sd.EmployeeID AND adj.ByAmount = 0 --tinh theo salary percent
		AND sd.LatestSalEntry = 1

	-------------------Calculate if Adjustment is based on Salary percent---------------
	--UPDATE #tblAdjustment
	--SET AdjustmentAmount = BasicSalary * SalaryPercent/100.0
	--WHERE ByAmount = 0
	UPDATE #tblAdjustment
	SET AdjustmentAmount = ISNULL(AdjustmentAmount, 0)

	SELECT EmployeeID, als.AllowanceID, ad.IncomeID, AdjustmentAmount, EmpAdjustmentID, ir.TaxBaseOnAllowanceCode, ad.Raw_AdjustmentAmount, ad.CurrencyCode AS Raw_CurrencyCode, ad.ExchangeRate AS Raw_ExchangeRate
	INTO #tblAdjustmentForAllowance
	FROM #tblAdjustment ad
	INNER JOIN tblIrregularIncome ir ON ad.IncomeID = ir.IncomeID AND len(ir.TaxBaseOnAllowanceCode) > 0 AND ForAllowance = 1
	INNER JOIN tblAllowanceSetting als ON ir.TaxBaseOnAllowanceCode = als.AllowanceCode

	INSERT INTO #tblSal_Adjustment_ForAllowance_Des (EmployeeID, Month, Year, PeriodID, AllowanceID, IncomeID, AdjustmentAmount, Raw_AdjustmentAmount, Raw_CurrencyCode, Raw_ExchangeRate)
	SELECT EmployeeID, @Month, @Year, @PeriodID, AllowanceID, IncomeID, AdjustmentAmount, Raw_AdjustmentAmount, Raw_CurrencyCode, Raw_ExchangeRate
	FROM #tblAdjustmentForAllowance

	DELETE #tblAdjustment
	FROM #tblAdjustment a
	INNER JOIN #tblAdjustmentForAllowance aa ON a.EmployeeId = aa.EmployeeId AND a.IncomeID = aa.IncomeID

	-----------------Insert into the table #tblSal_Adjustment_des-------------------
	SELECT EmployeeID, IncomeID, SUM(AdjustmentAmount) AdjustmentAmount, sum(Raw_AdjustmentAmount) AS Raw_AdjustmentAmount, CAST(0 AS FLOAT(53)) TaxableAmount, CAST(0 AS FLOAT(53)) UntaxableAmount
	INTO #AdjustmentSum
	FROM #tblAdjustment
	GROUP BY EmployeeID, IncomeID

	UPDATE a
	SET UntaxableAmount = ISNULL(i.TaxfreeMaxAmount, 0)
	FROM #AdjustmentSum a
	INNER JOIN tblIrregularIncome i ON a.IncomeID = i.IncomeID AND i.Taxable = 1

	UPDATE a
	SET UntaxableAmount = isnull(UntaxableAmount, 0) + AdjustmentAmount
	FROM #AdjustmentSum a
	INNER JOIN tblIrregularIncome i ON a.IncomeID = i.IncomeID AND isnull(i.Taxable, 0) = 0

	UPDATE #AdjustmentSum
	SET UntaxableAmount = AdjustmentAmount
	WHERE UntaxableAmount > AdjustmentAmount AND AdjustmentAmount > 0

	UPDATE #AdjustmentSum
	SET TaxableAmount = AdjustmentAmount - UntaxableAmount

	UPDATE #AdjustmentSum
	SET Raw_AdjustmentAmount = AdjustmentAmount, AdjustmentAmount = ROUND(AdjustmentAmount, @ROUND_SALARY_UNIT), UntaxableAmount = ROUND(UntaxableAmount, @ROUND_SALARY_UNIT), TaxableAmount = ROUND(TaxableAmount, @ROUND_SALARY_UNIT)

	IF (OBJECT_ID('SALCAL_ADJUSTMENT_BEFORE_INSERT') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ADJUSTMENT_BEFORE_INSERT
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ADJUSTMENT_BEFORE_INSERT @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	------------------------------Calculate OT------------------------------------
	-- giống như thằng Leave thì đoạn này cũng cần phải
	SELECT o.OTKind, o.EmployeeID, @Month Month, @Year Year, s.SalaryHistoryID, os.OvValue AS OTRate, SUM(o.ApprovedHours) AS OTHour, CAST(0 AS FLOAT(53)) OTAmount, s.SalaryPerDayOT, s.SalaryPerHourOT, s.STD_WD, s.LatestSalEntry, MAX(os.NSPercents) AS NSPercents, CAST(0 AS MONEY) AS NightShiftAmount, s.FromDate, s.ToDate
	INTO #tblSal_OT_Detail
	FROM #tblOTList o
	INNER JOIN #tblSalDetail s ON o.EmployeeID = s.EmployeeID AND o.OTDate BETWEEN s.FromDate AND s.ToDate
	INNER JOIN tblOvertimeSetting os ON o.OTKind = os.OTKind
	GROUP BY o.OTKind, o.EmployeeID, s.SalaryHistoryID, os.OvValue, s.SalaryPerDayOT, s.SalaryPerHourOT, s.SalaryPerHour, s.STD_WD, s.LatestSalEntry, s.FromDate, s.ToDate

	IF (OBJECT_ID('SALCAL_OT_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_OT_INITIAL
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,

	@FromDatedatetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,

	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_OT_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	IF @StopUPDATE = 0
	BEGIN
		-- add thêm phần night shift
		UPDATE #tblSal_OT_Detail
		SET OTAmount = o.OTRate * o.OTHour * o.SalaryPerHourOT / 100.0, NightShiftAmount = o.NSPercents * o.OTHour * o.SalaryPerHourOT / 100.0
		FROM #tblSal_OT_Detail o
	END


	--TRIPOD
	SELECT o.EmployeeID, o.SalaryHistoryID, LatestSalEntry, SUM(OTAmount / OTRate * 100.0) TaxableOTAmount, SUM(OTAmount - round((OTAmount / OTRate * 100.0), @ROUND_SALARY_UNIT)) NoneTaxableOTAmount -- làm vầy cộng lại mới tròn
		, ROUND(SUM(OTAmount), @ROUND_OT_NS_Detail_UNIT) TotalOTAmount, ROUND(SUM(NightShiftAmount), @ROUND_OT_NS_Detail_UNIT) NightShiftAmount, a.FromDate, a.ToDate
	INTO #SummaryOT
	FROM #tblSal_OT_Detail o
	LEFT JOIN #AttendanceSummary a ON o.EmployeeID = a.EmployeeID AND CAST(o.FromDate AS DATE) = CAST(a.FromDate AS DATE) AND CAST(o.ToDate AS DATE) = CAST(a.ToDate AS DATE)
	WHERE isnull(a.TotalExcessOT, 0) = 0
	GROUP BY o.EmployeeID, o.SalaryHistoryID, LatestSalEntry, a.FromDate, a.ToDate
	
	UNION
	
	SELECT o.EmployeeID, o.SalaryHistoryID, LatestSalEntry, ROUND(a.TaxableOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) TaxableOTAmount, ROUND(a.NontaxableOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) NoneTaxableOTAmount -- làm vầy cộng lại mới tròn
		, ROUND(((ISNULL(a.TaxableOT, 0)) + ISNULL(a.NontaxableOT, 0))  * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) TotalOTAmount, ROUND(SUM(NightShiftAmount), @ROUND_OT_NS_Detail_UNIT) NightShiftAmount, a.FromDate, a.ToDate
	FROM #tblSal_OT_Detail o
	LEFT JOIN #AttendanceSummary a ON o.EmployeeID = a.EmployeeID AND CAST(o.FromDate AS DATE) = CAST(a.FromDate AS DATE) AND CAST(o.ToDate AS DATE) = CAST(a.ToDate AS DATE)
	WHERE isnull(a.TotalExcessOT, 0) > 0
	GROUP BY o.EmployeeID, o.SalaryHistoryID, LatestSalEntry, a.TaxableOT, a.NontaxableOT, a.TotalOT, o.SalaryPerHourOT, a.FromDate, a.ToDate

	UPDATE #tblSalDetail
	SET TaxableOTTotal = round(tmp.TaxableOTAmount, @ROUND_SALARY_UNIT), NoneTaxableOTTotal = round(tmp.NoneTaxableOTAmount, @ROUND_OT_NS_Detail_UNIT), TotalOTAmount = tmp.TotalOTAmount, NightShiftAmount = tmp.NightShiftAmount
	FROM #tblSalDetail s
	INNER JOIN #SummaryOT tmp ON s.EmployeeID = tmp.EmployeeID AND CAST(s.FromDate AS DATE) = CAST(tmp.FromDate AS DATE) AND CAST(s.ToDate AS DATE) = CAST(tmp.ToDate AS DATE)


	UPDATE #tblSalDetail
	SET TotalOTAmount = ISNULL(TotalOTAmount, 0) + ISNULL(re.OT_Retro_Amount, 0), TaxableOTTotal = ISNULL(TaxableOTTotal, 0) + ISNULL(re.Taxed_OT_REtro, 0), NoneTaxableOTTotal = ISNULL(NoneTaxableOTTotal, 0) + ISNULL(re.Nontax_OT_Retro_Amount, 0)
	FROM #tblSalDetail sal
	INNER JOIN (
		SELECT EmployeeID, OT_Retro_Amount, Nontax_OT_Retro_Amount, ISNULL(OT_Retro_Amount, 0) - ISNULL(Nontax_OT_Retro_Amount, 0) AS Taxed_OT_REtro
		FROM #tblsal_retro_Final
		) re ON sal.EmployeeID = re.EmployeeID
	WHERE sal.LatestSalEntry = 1

	INSERT INTO #tblSal_OT_Detail_des (OverTimeID, EmployeeID, Year, Month, SalaryHistoryID, OTHour, OTAmount, OTRate, SalaryPerDay, SalaryPerHour, LatestSalEntry, PeriodID, NightShiftAmount, TaxableOTAmount, NoneTaxableOTAmount)
	SELECT OTKind, EmployeeID, Year, Month, SalaryHistoryID, OTHour, ROUND(OTAmount, @ROUND_OT_NS_Detail_UNIT) OTAmount, OTRate, SalaryPerDayOT, SalaryPerHourOT, LatestSalEntry, @PeriodID, NightShiftAmount, OTAmount / OTRate * 100.0 AS TaxableOTAmount, OTAmount - round((OTAmount / OTRate * 100.0), @ROUND_SALARY_UNIT) AS NoneTaxableOTAmount
	FROM #tblSal_OT_Detail

	IF (OBJECT_ID('SALCAL_OT_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_OT_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_OT_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	UPDATE #tblSalDetail
	SET TotalOTAmount = ROUND(TotalOTAmount, @ROUND_OT_NS_Detail_UNIT), TaxableOTTotal = ROUND(TaxableOTTotal, @ROUND_OT_NS_Detail_UNIT), NoneTaxableOTTotal = ROUND(NoneTaxableOTTotal, @ROUND_OT_NS_Detail_UNIT), NightShiftAmount = ROUND(NightShiftAmount, @ROUND_OT_NS_Detail_UNIT)

	-- OT summary--
	INSERT INTO #tblSal_OT_des (EmployeeID, Month, Year, OTAmount, TaxableOTAmount, NoneTaxableOTAmount, PeriodID, NightShiftAmount)
	SELECT EmployeeID, @Month, @Year, round(SUM(TotalOTAmount), @ROUND_OT_NS_Detail_UNIT), round(SUM(TaxableOTTotal), @ROUND_OT_NS_Detail_UNIT), round(SUM(NoneTaxableOTTotal), @ROUND_OT_NS_Detail_UNIT), @PeriodID, sum(NightShiftAmount) AS NightShiftAmount
	FROM #tblSalDetail s
	WHERE s.TaxableOTTotal + s.NoneTaxableOTTotal > 0
	GROUP BY EmployeeID

	-------------------------calculate Nightshift adjustment--------------------------------------
	DECLARE @PERCENT FLOAT

	SELECT @PERCENT = CAST([Value] AS FLOAT)
	FROM tblParameter
	WHERE Code = 'NIGHT_SHIFT_PERCENT'

	SET @PERCENT = ISNULL(@PERCENT, 30)

	SELECT NSKind, EmployeeID, HourApprove, [Date]
	INTO #tblNightShiftList
	FROM tblNightShiftList
	WHERE Approval = 1 AND DATE BETWEEN @FromDate AND @ToDate AND EmployeeID IN (
			SELECT te.EmployeeId
			FROM #tblEmployeeIDList te
			
			EXCEPT
			
			SELECT c.EmployeeId
			FROM #tblCustomAttendanceData c
			)

	DELETE #tblNightShiftList
	WHERE EmployeeID IN (
			SELECT c.EmployeeId
			FROM #tblCustomAttendanceData c
			)

	INSERT INTO #tblNightShiftList (NSKind, EmployeeID, HourApprove, [Date])
	SELECT 1 AS NSKind, EmployeeID, NS_Hour_1 AS HourApprove, @ToDateTruncate AS DATE
	FROM #tblCustomAttendanceData
	WHERE NS_Hour_1 <> 0
	
	UNION
	

	SELECT 2 AS NSKind, EmployeeID, NS_Hour_2 AS HourApprove, @ToDateTruncate AS DATE
	FROM #tblCustomAttendanceData
	WHERE NS_Hour_2 <> 0
	
	UNION
	
	SELECT 3 AS NSKind, EmployeeID, NS_Hour_3 AS HourApprove, @ToDateTruncate AS DATE
	FROM #tblCustomAttendanceData
	WHERE NS_Hour_3 <> 0
	
	UNION
	
	SELECT 4 AS NSKind, EmployeeID, NS_Hour_4 AS HourApprove, @ToDateTruncate AS DATE
	FROM #tblCustomAttendanceData
	WHERE NS_Hour_4 <> 0

	SELECT o.NSKind, o.EmployeeID, @Month Month, @Year Year, s.SalaryHistoryID, os.NSValue AS OTRate, SUM(o.HourApprove) AS OTHour, CAST(0 AS FLOAT(53)) NSAmount, s.SalaryPerDayOT, s.SalaryPerHourOT, s.LatestSalEntry
	INTO #tblSal_NS_Detail
	FROM #tblNightShiftList o
	INNER JOIN #tblSalDetail s ON o.EmployeeID = s.EmployeeID AND o.[Date] BETWEEN s.FromDate AND s.ToDate
	INNER JOIN tblNightShiftSetting os ON o.NSKind = os.NSKind
	GROUP BY o.NSKind, o.EmployeeID, s.SalaryHistoryID, os.NSValue, s.SalaryPerDayOT, s.SalaryPerHourOT, s.LatestSalEntry

	UPDATE #tblSal_NS_Detail
	SET OTRate = @PERCENT
	WHERE OTRate IS NULL

	IF (OBJECT_ID('SALCAL_NS_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_NS_INITIAL
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_NS_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	IF @StopUPDATE = 0
	BEGIN
		UPDATE #tblSal_NS_Detail
		SET NSAmount = ROUND(o.OTRate * o.OTHour * o.SalaryPerHourOT / 100.0, @ROUND_OT_NS_Detail_UNIT)
		FROM #tblSal_NS_Detail o
	END

	UPDATE #tblSal_NS_Detail
	SET NSAmount = ROUND(NSAmount, @ROUND_OT_NS_Detail_UNIT)

	INSERT INTO #tblSal_NS_Detail_des (EmployeeID, Month, Year, SalaryHistoryID, NSKind, NSHours, NSAmount, LatestSalEntry, PeriodID)
	SELECT EmployeeID, Month, Year, SalaryHistoryID, NSKind, SUM(OTHour) OTHour, SUM(NSAmount) NSAmount, LatestSalEntry, @PeriodID
	FROM #tblSal_NS_Detail
	GROUP BY EmployeeID, Month, Year, SalaryHistoryID, LatestSalEntry, NSKind

	UPDATE #tblSalDetail
	SET TotalNSAmt = round(tmp.TotalNSAmt, @ROUND_OT_NS_Detail_UNIT), NoneTaxableNSAmt = round(tmp.NoneTaxableNSAmt, @ROUND_OT_NS_Detail_UNIT)
	FROM #tblSalDetail s
	INNER JOIN (
		SELECT EmployeeID, SalaryHistoryID, LatestSalEntry, SUM(NSAmount) TotalNSAmt, SUM(NSAmount) NoneTaxableNSAmt
		FROM #tblSal_NS_Detail
		GROUP BY EmployeeID, SalaryHistoryID, LatestSalEntry
		) tmp ON s.EmployeeID = tmp.EmployeeID AND s.SalaryHistoryID = tmp.SalaryHistoryID AND s.LatestSalEntry = tmp.LatestSalEntry

	-- update retro amount of night shift (normal days only)
	UPDATE #tblSalDetail
	SET TotalNSAmt = ISNULL(TotalNSAmt, 0) + ISNULL(re.NightShift_RETRO, 0)
	FROM #tblSalDetail sal
	INNER JOIN #tblsal_retro_Final re ON sal.EmployeeID = re.EmployeeID
	WHERE sal.LatestSalEntry = 1

	IF (OBJECT_ID('SALCAL_NS_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_NS_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_NS_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	UPDATE #tblSal_NS_Detail
	SET NSAmount = ROUND(NSAmount, @ROUND_OT_NS_Detail_UNIT)

	-- NS summary--
	INSERT INTO #tblSal_NS_des (EmployeeID, Month, Year, NSHours, NSAmount, PeriodID)
	SELECT EmployeeID, Month, Year, SUM(OTHour) NSHours, ROUND(SUM(NSAmount), @ROUND_OT_NS_Detail_UNIT) NSAmount, @PeriodID
	FROM #tblSal_NS_Detail s
	GROUP BY EmployeeID, Month, Year

	-----------------------Calculate Allowance---------------------------
	UPDATE #tblAllowance
	SET DefaultAmount_WithoutCustomAmount = DefaultAmount

	UPDATE #tblAllowance

	SET MonthlyCustomAmount = isnull(MonthlyCustomAmount, 0) + isnull(a.AdjustmentAmount, 0), DefaultAmount = isnull(DefaultAmount, 0) + isnull(a.AdjustmentAmount, 0)
	FROM #tblAllowance al
	INNER JOIN (
		SELECT EmployeeID, TaxBaseOnAllowanceCode, Sum(AdjustmentAmount) AS AdjustmentAmount
		FROM #tblAdjustmentForAllowance a
		GROUP BY EmployeeID, TaxBaseOnAllowanceCode
		) a ON al.EmployeeID = a.EmployeeId AND al.AllowanceCode = a.TaxBaseOnAllowanceCode
	WHERE al.LatestSalEntry = 1

	UPDATE #tblAllowance
	SET STD_WD = CASE
			WHEN A.AllowanceRuleID IN (3, 7)
				THEN @FIXEDWORKINGDAY
			WHEN AllowanceRuleID IN (4, 8)
				THEN sal.STD_WD_Schedule
			ELSE sal.STD_WD
			END
	FROM #tblAllowance a
	INNER JOIN #tblSalDetail sal ON a.EmployeeID = sal.EmployeeID

	UPDATE a
	SET TotalPaidDays = sal.STD_WD - lv.lvAmount
	FROM #tblSalDetail sal
	INNER JOIN tblSalaryCalculationRule sc ON sal.SalCalRuleID = sc.SalCalRuleID
	INNER JOIN #tblAllowance a ON sal.EmployeeID = a.EmployeeID
	INNER JOIN (
		SELECT EmployeeID, ISNULL(SUM(lv.LvAmount / 8.0), 0) AS lvAmount
		FROM #tblLvHistory lv
		INNER JOIN tblLeaveType lt ON lv.LeaveCode = lt.LeaveCode AND isnull(lt.PaidRate, 0) = 0 AND lv.LeaveDate BETWEEN @FromDate AND @ToDate
		GROUP BY lv.EmployeeID
		) lv ON a.EmployeeID = lv.EmployeeID
	WHERE a.AllowanceRuleID = 17 AND sc.IsSTDMinusUnpaidLeave = 1

	-- tinh theo luong co ban
	--chia cong chuan * cong thuc te
	UPDATE #tblAllowance
	SET TotalPaidDays = sal.AttDays
	FROM #tblAllowance al
	INNER JOIN #tblSal_AttendanceData_PerHistory sal ON al.EmployeeID = sal.EmployeeID AND al.SalaryHistoryID = sal.SalaryHistoryID
	WHERE al.AllowanceRuleID = 4

	--ngay cong di lam thuc te
	UPDATE #tblAllowance
	SET TotalPaidDays = ISNULL(att.AttDays, 0) + ISNULL(att.ProbationHours, 0) / 8.0
	FROM #tblAllowance a
	INNER JOIN #tblSal_AttendanceData att ON a.EmployeeID = att.EmployeeID AND AllowanceRuleID IN (2, 10, 19)

	UPDATE #tblAllowance
	SET TotalPaidDays = ISNULL(a.TotalPaidDays, 0) + ISNULL(lv.LvAmount, 0)
	FROM #tblAllowance a
	INNER JOIN (
		SELECT EmployeeID, ISNULL(SUM(lv.LvAmount / 8.0), 0) AS lvAmount
		FROM #tblLvHistory lv
		INNER JOIN tblLeaveType lt ON lv.LeaveCode = lt.LeaveCode AND lt.PaidRate > 0 AND lv.LeaveDate BETWEEN @FromDate AND @ToDate
		GROUP BY lv.EmployeeID
		) lv ON a.EmployeeID = lv.EmployeeID AND AllowanceRuleID IN (19)

	--ngay cong di lam thuc te + ngay chu nhat
	UPDATE #tblAllowance
	SET TotalPaidDays = ISNULL(a.TotalPaidDays, 0) + ISNULL(att.TotalSunDay, 0)
	FROM #tblAllowance a
	INNER JOIN (
		SELECT EmployeeID, SUM(CASE
					WHEN WorkingTime > Std_Hour_PerDays
						THEN 1
					ELSE WorkingTime / Std_Hour_PerDays
					END) AS TotalSunDay
		FROM #Tadata
		WHERE HolidayStatus > 0
		GROUP BY EmployeeID
		) att ON a.EmployeeID = att.EmployeeID AND AllowanceRuleID IN (10)

	-- rule 20 nhan voi so ngay Chu nhan di lam du cong
	UPDATE #tblAllowance
	SET TotalPaidDays = isnull(FullWorkingTimeSunDays, 0)
	FROM #tblAllowance a
	INNER JOIN (
		SELECT EmployeeID, COUNT(1) AS FullWorkingTimeSunDays
		FROM #Tadata
		WHERE WorkingTime >= Std_Hour_PerDays AND HolidayStatus = 1
		GROUP BY EmployeeID
		) att ON a.EmployeeID = att.EmployeeID AND AllowanceRuleID IN (20)

	--So ngay di lam tron cong (lam du 8h cong 1 ngay moi dc tinh 1 lan tra)
	UPDATE #tblAllowance
	SET TotalPaidDays = isnull(FullWorkingTimeDays, 0)
	FROM #tblAllowance a
	INNER JOIN (
		SELECT EmployeeID, COUNT(1) AS FullWorkingTimeDays
		FROM #Tadata
		WHERE WorkingTime >= Std_Hour_PerDays
		GROUP BY EmployeeID
		) att ON a.EmployeeID = att.EmployeeID AND AllowanceRuleID IN (18)

	IF (OBJECT_ID('SALCAL_ALLOWANCE_BEFORE_PROCESS') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_BEFORE_PROCESS
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_BEFORE_PROCESS @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	--hưởng trọn gói
	UPDATE #tblAllowance
	SET ReceiveAmount = CASE
			WHEN ISNULL(TotalPaidDays, 0) = 0
				THEN 0
			ELSE ISNULL(DefaultAmount, 0)
			END
	WHERE AllowanceRuleID = 1

	--theo ngày tổng ngày công hưởng lương
	UPDATE al
	SET ReceiveAmount = CASE
			/*
	 when isnull(sc.IsDaily,0)=1
			then DefaultAmount*TotalPaidDays -- ngày
			*/
			WHEN isnull(sc.IsFixedStd, 0) = 1
				THEN DefaultAmount * TotalPaidDays / FixedStdPerMonth
			ELSE DefaultAmount * TotalPaidDays / STD_WD
			END
	FROM #tblAllowance al
	INNER JOIN tblSalaryCalculationRule sc ON al.SalCalRuleID = sc.SalCalRuleID
	WHERE AllowanceRuleID IN (3, 4, 5, 7, 8, 17)

	UPDATE al
	SET ReceiveAmount = DefaultAmount * TotalPaidDays
	FROM #tblAllowance al
	INNER JOIN tblSalaryCalculationRule sc ON al.SalCalRuleID = sc.SalCalRuleID --and isnull(sc.IsDaily,0)=0
	WHERE AllowanceRuleID IN (2, 10, 18, 20)

	-- thâm niên
	-- select EmployeeID
	-- ,Hiredate BeginDate
	-- ,@ToDate EndDate
	-- ,1 FirstMonthAddition --mac dinh tinh luon thang vao lam
	-- ,1 LastMonthAddition --tinh ca thang ket thuc
	-- ,TerminateDate
	-- ,0 as Months
	-- into #tmpSeniority
	-- from #tblEmployeeIDList e where Hiredate < @ToDate
	-- --nhan vien nghi viec thi chi tinh den thang nghi viec thoi
	-- UPDATE #tmpSeniority SET EndDate = TerminateDate where TerminateDate is not null
	IF (OBJECT_ID('SALCAL_ALLOWANCE_SENIORIRY_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_SENIORIRY_INITIAL
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_SENIORIRY_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- if @StopUPDATE = 0
	-- begin
	-- 	DECLARE @SENIORITY_FOR_FIRST_MONTH int, @SENIORITY_FOR_LAST_MONTH int
	-- 	select @SENIORITY_FOR_FIRST_MONTH = [Value] from tblParameter where Code = 'SENIORITY_FOR_FIRST_MONTH'
	-- 	SET @SENIORITY_FOR_FIRST_MONTH = ISNULL(@SENIORITY_FOR_FIRST_MONTH,0)
	-- 	select @SENIORITY_FOR_LAST_MONTH = [Value] from tblParameter where Code = 'SENIORITY_FOR_LAST_MONTH'
	-- 	SET @SENIORITY_FOR_LAST_MONTH = ISNULL(@SENIORITY_FOR_LAST_MONTH,31)
	-- 	if @SENIORITY_FOR_FIRST_MONTH > 0 --VD: neu vao lam sau ngay 15 thi khong duoc tham nien thang dau
	-- 		UPDATE #tmpSeniority SET FirstMonthAddition = 0 where day(BeginDate) > @SENIORITY_FOR_FIRST_MONTH
	-- 	if @SENIORITY_FOR_LAST_MONTH <= 0 --nhap 0 thi tinh den cuoi thang truoc
	-- 		UPDATE #tmpSeniority SET LastMonthAddition = 0 where TerminateDate is not null
	-- 	else if @SENIORITY_FOR_LAST_MONTH < 31 --nhap ngay trong thang, gia su nhap 15 thi nghi viec truoc ngay 15 thi khong duoc, tu ngay 16 tro di thi duoc
	-- 		UPDATE #tmpSeniority SET LastMonthAddition = 0 where day(TerminateDate) < @SENIORITY_FOR_LAST_MONTH
	-- 	else if @SENIORITY_FOR_LAST_MONTH >= 31 --nhap 31 thi nghi viec ngay 1 thi khong duoc, vi LastWorkingDay la ngay cuoi cung cua thang truoc, tu ngay 2 duoc
	-- 		UPDATE #tmpSeniority SET LastMonthAddition = 0 where day(TerminateDate) = 1
	-- 	--tru 2 la tru thang dau tien va thang cuoi cung
	-- 	--UPDATE #tmpSeniority SET Months = DATEDIFF(month,BeginDate,EndDate) - 2 + FirstMonthAddition + LastMonthAddition
	-- end
	-- CREATE TABLE #tblSeniorityAllowance(EmployeeID varchar(20),AllowanceAmount float(53))
	-- insert into #tblSeniorityAllowance(EmployeeID,AllowanceAmount)
	-- select EmployeeID,c.AllowanceAmt from #tmpSeniority a cross apply (
	-- 	select Min(FromMonth) FromMonth
	-- 		from tblSeniorityAllwanceSetting b where a.Months between b.FromMonth and b.ToMonth
	-- ) b
	-- inner join tblSeniorityAllwanceSetting c on b.FromMonth = c.FromMonth
	-- UPDATE a set ReceiveAmount = s.AllowanceAmount
	-- from #tblAllowance a
	-- inner join #tblSeniorityAllowance s on a.EmployeeID = s.EmployeeID
	-- where a.AllowanceRuleID in (13)
	--cap nhat phu cap tham nien vao bang history
	SET @Query = ''

	SELECT @Query += '
update sal set [' + AllowanceCode + '] = ReceiveAmount
 from tblSalaryHistory sal
inner join #tblAllowance al on sal.SalaryHistoryID = al.SalaryHistoryID
where al.AllowanceCode= ''' + AllowanceCode + '''
'
	FROM (
		SELECT DISTINCT AllowanceCode
		FROM #tblAllowance al
		WHERE al.AllowanceRuleID = 13
		) al

	EXECUTE sp_executesql @Query

	IF (OBJECT_ID('SALCAL_ALLOWANCE_SENIORIRY_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_SENIORIRY_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_SENIORIRY_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- chuyên cần, chuyen can chuyencan
	-- RuleID = 9
	IF (OBJECT_ID('SALCAL_ALLOWANCE_DILIGENTALL_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_DILIGENTALL_INITIAL
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_DILIGENTALL_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- sp_DiligentDeductItems_DataSetting -- danh sach cac muc tru chuyen can
	-- tblDiligentAllowanceRule -- cac thiet lap tinh chuyen can
	SELECT s.Code, s.Qty, s.DeductPercentage, cast(0 AS FLOAT) AS ActualQty, cast(0 AS FLOAT(53)) DeductAmount, a.*
	INTO #tblDiligentAll
	FROM #tblAllowance a, tblDiligentAllowanceRule s
	WHERE a.AllowanceRuleID = 9
	ORDER BY a.EmployeeID, s.Code, s.PaidPercentage DESC

	-- Đi trễ về - sớm bao nhiêu phút
	SELECT EmployeeID, IODate, IOKind, IOMinutes, IOMinutesDeduct, ApprovedDeduct
	INTO #tblIOData
	FROM tblInLateOutEarly il
	WHERE ApprovedDeduct = 1 AND ApprovedDeduct > 0 AND IODate BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList te
			WHERE il.EmployeeID = te.EmployeeID AND il.IODate BETWEEN te.HireDate AND te.LastWorkingDate
			)

	UPDATE #tblDiligentAll
	SET ActualQty = tmp.IOMinute
	FROM #tblDiligentAll d
	INNER JOIN (
		SELECT EmployeeID, SUM(IOMinutesDeduct) AS IOMinute
		FROM #tblIOData
		GROUP BY EmployeeID
		) tmp ON d.EmployeeID = tmp.EmployeeID
	WHERE d.Code = 'IOMinute'

	-- so lan di tre
	-- Đi trễ về - sớm bao nhiêu lần trong tháng
	UPDATE #tblDiligentAll
	SET ActualQty = tmp.IOMinute
	FROM #tblDiligentAll d
	INNER JOIN (
		SELECT EmployeeID, count(1) AS IOMinute
		FROM #tblIOData
		GROUP BY EmployeeID
		) tmp ON d.EmployeeID = tmp.EmployeeID
	WHERE d.Code = 'IOCount'

	--Không xuống ca - không tăng ca theo lịch: NotOT
	UPDATE #tblDiligentAll
	SET ActualQty = tmp.NotOTCount
	FROM #tblDiligentAll D
	INNER JOIN (
		SELECT EmployeeID, Count(1) NotOTCount
		FROM tblNotOtList ot
		WHERE OTDate BETWEEN @FromDate AND @ToDate AND Approved = 1 AND EXISTS (
				SELECT 1
				FROM #tblEmployeeIDList te
				WHERE ot.EmployeeID = te.EmployeeID AND ot.OTDate BETWEEN te.HireDate AND te.LastWorkingDate
				)
		GROUP BY EmployeeID
		) TMP ON d.EmployeeID = tmp.EmployeeID
	WHERE d.Code = 'NotOT'

	-- Số lần quyên bấm thẻ, vân tay: FWCCount
	UPDATE #tblDiligentAll
	SET ActualQty = tmp.FWCCount
	FROM #tblDiligentAll D
	INNER JOIN (
		SELECT EmployeeID, SUM(CASE
					WHEN LeaveStatus = 3
						THEN 2
					ELSE 1
					END) FWCCount
		FROM #tblLvHistory
		WHERE LeaveCode = 'FWC'
		GROUP BY EmployeeID
		) TMP ON d.EmployeeID = tmp.EmployeeID
	WHERE d.Code = 'FWCCount'

	-- Tổng số ngày công hưởng lương
	UPDATE #tblDiligentAll
	SET ActualQty = STD_WD - TotalPaidDays
	WHERE Code IN ('PD', 'PDAWD')

	-- các loại nghỉ bị trừ chuyên cần
	UPDATE #tblDiligentAll
	SET ActualQty = lv.lvCount
	FROM #tblDiligentAll D
	CROSS APPLY (
		SELECT SUM(lv.LvAmount) / 8.0 lvCount
		FROM #tblLvHistory lv
		WHERE D.EmployeeID = lv.EmployeeID AND D.Code = lv.LeaveCode
		) lv
	WHERE lv.lvCount > 0 AND d.Code NOT IN ('PD', 'PDAWD', 'IOMinute', 'IOCount', 'NotOT', 'FWCCount', 'FWC')

	UPDATE #tblDiligentAll
	SET ActualQty = tmp.lvCount
	FROM #tblDiligentAll D
	INNER JOIN (
		SELECT lv.EmployeeID, lv.lvCount
		FROM #tblDiligentAll d
		INNER JOIN (
			SELECT SUM(lv.LvAmount) / 8.0 AS lvCount, EmployeeID
			FROM #tblLvHistory lv
			WHERE isnull(lv.CutDiligent, 0) = 1
			GROUP BY lv.EmployeeID
			) lv ON d.EmployeeID = lv.EmployeeID
		) TMP ON d.EmployeeID = tmp.EmployeeID
	WHERE Code IN ('ALL_leave')

	DELETE #tblDiligentAll
	WHERE Qty > ActualQty

	DELETE d
	FROM #tblDiligentAll d
	WHERE NOT EXISTS (
			SELECT 1
			FROM (
				SELECT Code, EmployeeID, MAX(Qty) Qty
				FROM #tblDiligentAll
				WHERE Qty <= ActualQty
				GROUP BY Code, EmployeeID
				) tmp
			WHERE d.EmployeeID = tmp.EmployeeID AND d.Code = tmp.Code AND d.Qty = tmp.Qty
			)

	UPDATE #tblDiligentAll
	SET DeductAmount = DefaultAmount * DeductPercentage / 100

	-- Get the remain of diligent allowance
	-- Negative set to zero
	UPDATE d
	SET ReceiveAmount = CASE
			WHEN tmp.DefaultAmount - tmp.DeductAmount > 0
				THEN tmp.DefaultAmount - tmp.DeductAmount
			ELSE 0
			END
	FROM #tblDiligentAll d
	INNER JOIN (
		SELECT d.EmployeeID, Max(d.DefaultAmount) DefaultAmount, SUM(d.DeductAmount) DeductAmount
		FROM #tblDiligentAll d
		GROUP BY d.EmployeeID
		) tmp ON d.EmployeeID = tmp.EmployeeID

	-- store the result
	UPDATE a
	SET ReceiveAmount = isnull(d.ReceiveAmount, a.DefaultAmount)
	FROM #tblAllowance a
	LEFT JOIN #tblDiligentAll d ON a.EmployeeID = d.EmployeeID AND a.AllowanceID = d.AllowanceID
	WHERE a.AllowanceRuleID = 9

	IF (OBJECT_ID('SALCAL_ALLOWANCE_DILIGENTALL_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_DILIGENTALL_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_DILIGENTALL_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- ket thuc chuyen can
	SELECT DISTINCT AllowanceCode, AllowanceID
	INTO #CustomColname
	FROM tblAllowanceSetting
	WHERE AllowanceCode IN (
			SELECT Column_Name
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = 'tblCustomInputImportMonthly'
			) AND Visible = 1

	SELECT *
	INTO #tblCustomInputImportMonthly
	FROM tblCustomInputImportMonthly c
	WHERE Month = @Month AND Year = @Year AND EXISTS (
			SELECT 1
			FROM #tblEmployeeIDList te
			WHERE c.EmployeeID = te.EmployeeID
			)

	SET @Query = ''

	DECLARE @AllowanceCustomInput NVARCHAR(100) = ''
	DECLARE @AllowanceID NVARCHAR(10) = ''

	WHILE EXISTS (
			SELECT 1
			FROM #CustomColname
			)
	BEGIN
		SELECT TOP 1 @AllowanceCustomInput = AllowanceCode, @AllowanceID = AllowanceID
		FROM #CustomColname

		SET @Query = 'update #tblAllowance
		set ReceiveAmount = isnull(c.[' + @AllowanceCustomInput + '] ,0)
		from #tblAllowance al
		inner join #tblCustomInputImportMonthly c on al.EmployeeId = c.EmployeeID
		where al.AllowanceID  =' + @AllowanceID + ' and c.[' + @AllowanceCustomInput + '] is not null
		and al.LatestSalEntry = 1'

		EXEC (@Query)

		--neu co import thi xoa nhung dong luong cu di
		SET @Query = 'delete #tblAllowance
		from #tblAllowance al
		inner join #tblCustomInputImportMonthly c on al.EmployeeId = c.EmployeeID
		where al.AllowanceID  =' + @AllowanceID + ' and c.[' + @AllowanceCustomInput + '] is not null
		and al.LatestSalEntry = 0'

		EXEC (@Query)

		DELETE #CustomColname
		WHERE AllowanceCode = @AllowanceCustomInput
	END

	DROP TABLE #tblCustomInputImportMonthly

	DROP TABLE #CustomColname

	-- Lap trinh rieng theo quy tac cua khach hang
	IF (OBJECT_ID('SALCAL_ALLOWANCE_CUSTOMER_RULE') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_CUSTOMER_RULE
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_CUSTOMER_RULE @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- cộng Retro allowance vào
	CREATE TABLE #tblRetro_Allowance_detail (EmployeeId VARCHAR(20), AllowanceCode NVARCHAR(200), Amount MONEY)

	SELECT SUBSTRING(SUBSTRING(c.COLUMN_NAME, 4, 9999), 1, LEN(SUBSTRING(c.COLUMN_NAME, 4, 9999)) - 6) AS AllowanceName, c.COLUMN_NAME
	INTO #AllowanceCodeFromRetroTable
	FROM INFORMATION_SCHEMA.COLUMNS c
	WHERE c.TABLE_NAME = 'tblSal_Retro_Sumary' AND c.COLUMN_NAME IN (
			SELECT 'AL_' + AllowanceCode + '_Retro'
			FROM tblAllowanceSetting
			WHERE Visible = 1
			)

	IF (
			SELECT COUNT(1)
			FROM #AllowanceCodeFromRetroTable
			) > 0
	BEGIN
		SET @Query = ''

		SELECT @Query += ' select EmployeeID,''' + AllowanceName + ''',' + COLUMN_NAME + '
	from #tblsal_retro_Final where ' + COLUMN_NAME + ' <> 0
	union all'
		FROM #AllowanceCodeFromRetroTable

		SET @Query = SUBSTRING(@Query, 1, len(@Query) - LEN('union all'))
		SET @Query = 'insert into #tblRetro_Allowance_detail(EmployeeId,AllowanceCode,Amount)
	' + @Query

		EXEC (@Query)
	END

	UPDATE al
	SET RetroAmount = re.Amount, ReceiveAmount = ISNULL(ReceiveAmount, 0) + ISNULL(re.Amount, 0)
	FROM #tblRetro_Allowance_detail re
	INNER JOIN #tblAllowance al ON re.EmployeeId = al.EmployeeID AND re.AllowanceCode = al.AllowanceCode

	-- hết cộng retro vào
	UPDATE #tblAllowance
	SET UntaxableAmount = TaxfreeMaxAmount
	FROM #tblAllowance a

	--inner join tblAllowanceSetting al on a.AllowanceID = al.AllowanceID
	SELECT al.EmployeeID, al.AllowanceID, SUM(al.ReceiveAmount) sum_ReceiveAmount, MAX(al.TaxFreeMaxAmount) max_TaxFreeMaxAmount
	INTO #TwoAllowanceFreeTax
	FROM #tblAllowance al
	WHERE al.isTaxable = 1 AND al.TaxfreeMaxAmount > 0 AND al.ReceiveAmount > 0
	GROUP BY al.EmployeeID, al.AllowanceID
	HAVING COUNT(1) > 1 AND SUM(al.ReceiveAmount) > max(al.TaxFreeMaxAmount)

	SELECT ROW_NUMBER() OVER (
			PARTITION BY al.EmployeeID, al.AllowanceID ORDER BY al.LatestSalEntry
			) ORD, al.EmployeeID, al.AllowanceID, al.LatestSalEntry, al.ReceiveAmount, tw.sum_ReceiveAmount, tw.max_TaxFreeMaxAmount, CAST(NULL AS MONEY) UntaxableAmount_Accummulate
	INTO #AccummulateUntaxableAmount
	FROM #tblAllowance al
	INNER JOIN #TwoAllowanceFreeTax tw ON al.EmployeeID = tw.EmployeeID AND al.AllowanceID = tw.AllowanceID

	UPDATE #AccummulateUntaxableAmount
	SET UntaxableAmount_Accummulate = CASE
			WHEN ReceiveAmount > max_TaxFreeMaxAmount
				THEN max_TaxFreeMaxAmount
			ELSE ReceiveAmount
			END
	WHERE ORD = 1

	UPDATE a2
	SET max_TaxFreeMaxAmount = a2.max_TaxFreeMaxAmount - a1.UntaxableAmount_Accummulate
	FROM #AccummulateUntaxableAmount a1
	INNER JOIN #AccummulateUntaxableAmount a2 ON a1.EmployeeID = a2.EmployeeID AND a1.AllowanceID = a2.AllowanceID
	WHERE a1.ORD = 1 AND a2.ORD = 2

	UPDATE #AccummulateUntaxableAmount
	SET UntaxableAmount_Accummulate = CASE
			WHEN ReceiveAmount > max_TaxFreeMaxAmount
				THEN max_TaxFreeMaxAmount
			ELSE ReceiveAmount
			END
	WHERE ORD = 2

	UPDATE #tblAllowance
	SET UntaxableAmount = ac.UntaxableAmount_Accummulate
	FROM #tblAllowance al
	INNER JOIN #AccummulateUntaxableAmount ac ON al.EmployeeID = ac.EmployeeID AND al.AllowanceID = ac.AllowanceID
	WHERE al.LatestSalEntry = ac.LatestSalEntry

	UPDATE #tblAllowance
	SET UntaxableAmount = 0
	WHERE UntaxableAmount IS NULL

	UPDATE #tblAllowance
	SET UntaxableAmount = round(CASE
				WHEN ISNULL(ReceiveAmount, 0) - ISNULL(RetroAmount, 0) > UntaxableAmount
					THEN UntaxableAmount
				ELSE ISNULL(ReceiveAmount, 0) - ISNULL(RetroAmount, 0)
				END, @ROUND_SALARY_UNIT), RetroAmountNonTax = round(CASE
				WHEN ISNULL(ReceiveAmount, 0) > UntaxableAmount
					THEN UntaxableAmount
				ELSE ISNULL(ReceiveAmount, 0)
				END, @ROUND_SALARY_UNIT) - round(CASE
				WHEN ISNULL(ReceiveAmount, 0) - ISNULL(RetroAmount, 0) > UntaxableAmount
					THEN UntaxableAmount
				ELSE ISNULL(ReceiveAmount, 0) - ISNULL(RetroAmount, 0)
				END, @ROUND_SALARY_UNIT)

	-- phụ cấp trang phục, đồng phục, 1 năm được miễn thuế 5tr, nếu vượt quá thì không được miễn thuế nữa
	UPDATE a
	SET UntaxableAmount = round(CASE
				WHEN ISNULL(a.ReceiveAmount, 0) > t.TaxfreeMaxAmount
					THEN t.TaxfreeMaxAmount
				ELSE a.ReceiveAmount
				END, @ROUND_SALARY_UNIT)
	FROM #tblAllowance a
	INNER JOIN (
		SELECT tmp.EmployeeID, tmp.AllowanceID, sa.TaxfreeMaxAmount - ISNULL(tmp.UntaxableAmount, 0) TaxfreeMaxAmount
		FROM tblAllowanceSetting sa
		INNER JOIN (
			SELECT a.EmployeeID, SUM(a.UntaxableAmount) UntaxableAmount, sa.AllowanceID
			FROM #tblSal_Allowance_Detail_des a
			INNER JOIN tblAllowanceSetting sa ON a.AllowanceID = sa.AllowanceID AND isnull(sa.isUniformAllowance, 0) = 1
			INNER JOIN #tblAllowance al ON a.EmployeeID = al.EmployeeID AND al.AllowanceID = a.AllowanceID
			WHERE (a.Month + a.Year * 12) BETWEEN @Year * 12 + 1 AND @Year * 12 + 12 AND a.Month + a.Year <> @month + @year
			GROUP BY a.EmployeeID, a.AllowanceID, sa.AllowanceID
			) tmp ON sa.AllowanceID = tmp.AllowanceID
		) t ON a.EmployeeID = t.EmployeeID AND a.AllowanceID = t.AllowanceID

	-- phụ cấp nhà ở
	DECLARE @HouseAllPercent REAL

	SET @HouseAllPercent = (
			SELECT cast(Value AS FLOAT(53))
			FROM tblParameter
			WHERE code = 'HOUSE_ALL_PER_COMP'
			)
	SET @HouseAllPercent = isnull(@HouseAllPercent, 15)

	--tổng số tiền tinh thuế kovượt quá 15% tổng thu nhập chịu thuế (không bao gồm phụ cấp nhà ở)
	-- tổng hợp thu nhập chịu thuế chua gồm tiền nhà
	UPDATE #tblAllowance
	SET ReceiveAmount = ROUND(ReceiveAmount, @ROUND_SALARY_UNIT)

	UPDATE #tblSalDetail
	SET ActualMonthlyBasic = ROUND(ActualMonthlyBasic, @ROUND_SALARY_UNIT)

	UPDATE #tblSalDetail
	SET ActualMonthlyBasic = ISNULL(ActualMonthlyBasic, 0) + ISNULL(sr.ActualMonthlyBasic_Retro_Amount, 0)
	FROM #tblSalDetail sal
	INNER JOIN #tblsal_retro_Final sr ON sal.EmployeeID = sr.EmployeeID --and sr.Month= @Month and sr.Year= @Year
	WHERE sal.LatestSalEntry = 1

	UPDATE #tblAllowance
	SET TaxableAmount = ISNULL(ReceiveAmount, 0) - ISNULL(RetroAmount, 0) - ISNULL(UntaxableAmount, 0)

	UPDATE #tblAllowance
	SET TaxableAmount = 0, UntaxableAmount = 0
	WHERE isnull(ReceiveAmount, 0) = 0

	CREATE TABLE #tblAdjustmentNeedConfig (EmployeeId VARCHAR(20), IncomeID INT)

	INSERT INTO #tblAdjustmentNeedConfig (EmployeeId, IncomeID)
	SELECT EmployeeId, IncomeID
	FROM (
		UPDATE #AdjustmentSum
		SET UntaxableAmount = CASE
				WHEN a.AdjustmentAmount > al.TaxFreeMaxAmount - al.UntaxableAmount
					THEN al.TaxFreeMaxAmount - al.UntaxableAmount
				ELSE a.AdjustmentAmount
				END
		OUTPUT inserted.EmployeeID, inserted.IncomeID
		FROM #AdjustmentSum a
		INNER JOIN tblIrregularIncome irr ON a.IncomeID = irr.IncomeID
		INNER JOIN tblAllowanceSetting als ON irr.TaxBaseOnAllowanceCode = als.AllowanceCode
		INNER JOIN #tblAllowance al ON als.AllowanceID = al.AllowanceID AND a.EmployeeID = al.EmployeeID
		WHERE al.TaxFreeMaxAmount > al.UntaxableAmount
		) ud

	IF @@ROWCOUNT > 0
	BEGIN
		UPDATE #AdjustmentSum
		SET TaxableAmount = AdjustmentAmount - ISNULL(a.UntaxableAmount, 0)
		FROM #AdjustmentSum a
		INNER JOIN #tblAdjustmentNeedConfig n ON a.EmployeeID = n.EmployeeId AND a.IncomeID = n.IncomeID
	END

	--tringuyen
	UPDATE #AdjustmentSum
	SET TaxableAmount = 0, UntaxableAmount = 0
	WHERE isnull(AdjustmentAmount, 0) = 0

	DROP TABLE #tblAdjustmentNeedConfig

	-- người vận chuyển đoạn insert update của thằng adjustment xuống đây
	INSERT INTO #tblSal_Adjustment_des (EmployeeID, Month, Year, IncomeID, Amount, Raw_Amount, PeriodID, UntaxableAmount, TaxableAmount)
	SELECT EmployeeID, @Month, @Year, IncomeID, AdjustmentAmount, Raw_AdjustmentAmount, @PeriodID, UntaxableAmount, TaxableAmount
	FROM #AdjustmentSum

	UPDATE #tblSalDetail
	SET TaxableAdjustmentTotal = round(tmp.TaxableAmount, @ROUND_SALARY_UNIT), TaxableAdjustmentTotal_ForSalary = round(tmp.TaxableAmount_ForSalary, @ROUND_SALARY_UNIT), TaxableAdjustmentTotal_NotForSalary = round(tmp.TaxableAmount_NotForSalary, @ROUND_SALARY_UNIT), NoneTaxableAdjustmentTotal = round(tmp.UntaxableAmount, @ROUND_SALARY_UNIT), TotalAdjustmentForSalary = round(tmp.TotalAdjustmentForSalary, @ROUND_SALARY_UNIT), TotalAdjustment_WithoutForce = round(tmp.TotalAdjustment_WithoutForce, @ROUND_SALARY_UNIT)
	FROM #tblSalDetail sal, (
			SELECT a.EmployeeID, SUM(CASE
						WHEN i.IncomeKind = 0
							THEN - 1 * UntaxableAmount
						ELSE UntaxableAmount
						END) UntaxableAmount, SUM(CASE
						WHEN i.IncomeKind = 0
							THEN - 1 * TaxableAmount
						ELSE TaxableAmount
						END) TaxableAmount, SUM(CASE
						WHEN isnull(i.ForSalary, 0) = 0
							THEN 0
						WHEN i.IncomeKind = 0
							THEN - 1 * AdjustmentAmount
						ELSE AdjustmentAmount
						END * CASE
						WHEN Taxable = 1
							THEN 1
						ELSE 0
						END) TaxableAmount_ForSalary, SUM(CASE
						WHEN isnull(i.ForSalary, 0) = 1
							THEN 0
						WHEN i.IncomeKind = 0
							THEN - 1 * TaxableAmount
						ELSE TaxableAmount
						END) TaxableAmount_NotForSalary, SUM(CASE
						WHEN ISNULL(i.ForSalary, 0) = 0
							THEN 0
						ELSE CASE
								WHEN i.IncomeKind = 0
									THEN - 1
								ELSE 1
								END * AdjustmentAmount
						END) TotalAdjustmentForSalary, SUM(CASE
						WHEN ISNULL(ForceNonTax, 0) = 0
							THEN CASE
									WHEN i.IncomeKind = 0
										THEN - 1
									ELSE 1
									END * AdjustmentAmount
						ELSE 0
						END) TotalAdjustment_WithoutForce, sum(CASE
						WHEN i.incomeKind = 1
							THEN 1
						ELSE 0
						END * a.AdjustmentAmount) AS TotalDeductFromTotalEarnCauseOfNegativeAmount
			FROM #AdjustmentSum a
			INNER JOIN tblIrregularIncome i ON a.IncomeID = i.IncomeID
			GROUP BY a.EmployeeID
			) tmp
	WHERE sal.EmployeeID = tmp.EmployeeID AND sal.LatestSalEntry = 1

	--OtherDeductionAfterPIT
	UPDATE #tblSalDetail
	SET OtherDeductionAfterPIT = tmp.Amount
	FROM #tblSalDetail s
	INNER JOIN (
		SELECT a.EmployeeID, sum(a.AdjustmentAmount) Amount
		FROM #AdjustmentSum a
		INNER JOIN tblIrregularIncome ir ON a.IncomeID = ir.IncomeID AND ir.IncomeKind = 0 AND isnull(ir.Taxable, 0) = 0
		GROUP BY a.EmployeeID
		) tmp ON s.EmployeeID = tmp.EmployeeID

	IF (OBJECT_ID('SALCAL_ADJUSTMENT_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ADJUSTMENT_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ADJUSTMENT_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- hết adjustment
	UPDATE #tblSalDetail
	SET TaxableIncomeBeforeDeduction = ISNULL(ActualMonthlyBasic, 0) + ROUND(ISNULL(TotalNSAmt, 0), 0) - ROUND(isnull(NoneTaxableNSAmt, 0), 0) + ROUND(ISNULL(TaxableAdjustmentTotal, 0), 0) + ROUND(isnull(TaxableOTTotal, 0), 0) - ROUND(ISNULL(NoneTaxableOTTotal, 0), 0)


	--tripod
	UPDATE s
	SET TaxableIncomeBeforeDeduction = isnull(s.TaxableIncomeBeforeDeduction, 0) + ISNULL(tmp.TaxableAmount, 0)
	FROM #tblSalDetail s
	INNER JOIN (
		SELECT a.EmployeeID, SUM(ISNULL(a.TaxableAmount, a.ReceiveAmount)) TaxableAmount
		FROM #tblAllowance a
		INNER JOIN tblAllowanceSetting sa ON a.AllowanceID = sa.AllowanceID AND isnull(sa.IsHouseAllowance, 0) = 0
		GROUP BY EmployeeID
		) tmp ON s.EmployeeID = tmp.EmployeeID

	-- cộng với lương từ nước ngoài để gross up
	-- delete first
	SELECT sa.*
	INTO #tblSalaryAbroad
	FROM #tblEmployeeIDList e
	CROSS APPLY (
		SELECT MAX(Month + Year * 12) MY
		FROM tblSalaryAbroad sa1
		WHERE e.EmployeeID = sa1.EmployeeID AND sa1.Month + sa1.Year * 12 <= @month + @year * 12 AND (sa1.ToMonth IS NULL OR sa1.ToYear IS NULL OR sa1.ToMonth + sa1.ToYear * 12 >= @month + @year * 12)
		) ca
	INNER JOIN tblSalaryAbroad sa ON sa.EmployeeID = e.EmployeeID AND sa.Month + sa.Year * 12 = ca.MY

	INSERT INTO #tblSal_Abroad_ForTaxPurpose_Des (EmployeeID, Month, Year, NetAmountVND, Raw_NetAmount, GrossAmountVND, Raw_GrossAmount, CurrencyCode, ExchangeRate, NationID, PeriodID, VND_Amount, Raw_Amount_AfterDeductVND)
	SELECT sa.EmployeeID, @month AS month, @Year AS year, round(isnull(NetAmount, 0) * c.[ExchangeRate], @ROUND_SALARY_UNIT) AS NetAmountVND, NetAmount AS Raw_NetAmount, round(isnull(GrossAmount, 0) * c.[ExchangeRate], @ROUND_SALARY_UNIT) AS GrossAmountVND, GrossAmount AS Raw_Amount, sa.CurrencyCode, c.[ExchangeRate] AS ExchangeRate, sa.NationID, @PeriodID, sa.VND_Amount, NetAmount - (sa.VND_Amount / c.[ExchangeRate]) AS Raw_Amount_AfterDeductVND
	FROM #tblSalaryAbroad sa
	INNER JOIN #tblSalDetail sal ON sa.EmployeeID = sal.EmployeeID AND sal.LatestSalEntry = 1
	LEFT JOIN #EmployeeExchangeRate c ON sa.CurrencyCode = c.CurrencyCode AND c.EmployeeID = sa.EmployeeID

	-- lấy danh sách allowance Gross ra trừ đi trước khi grossup
	-- có thể net hóa nó nhưng mà khó lém
	SELECT EmployeeID, sum(TaxableAmount) AS TotalGrossAllowanceAmount_Taxable
	INTO #grossAllowanceAmount
	FROM #tblAllowance a
	INNER JOIN tblAllowanceSetting al ON a.AllowanceCode = al.AllowanceCode
	WHERE al.IsTaxable = 1 AND al.IsGrossAllowance_InNetSal = 1
	GROUP BY EmployeeID

	IF @@ROWCOUNT > 0 -- nếu có gross allowance thì phải trừ đi rồi mới gross up
	BEGIN
		UPDATE #tblSalDetail
		SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction - isnull(gross.TotalGrossAllowanceAmount_Taxable, 0)
		FROM #tblSalDetail sal
		INNER JOIN #grossAllowanceAmount gross ON sal.EmployeeID = gross.EmployeeID AND sal.LatestSalEntry = 1
		WHERE sal.IsNet = 1
	END

	-- cộng cục này với phần Net từ nước ngoài trả
	UPDATE #tblSalDetail
	SET TaxableIncomeBeforeDeduction += isnull(ca.NetAmountVND, 0) -- cộng phần net để grossup trước
	FROM #tblSalDetail sal
	CROSS APPLY (
		SELECT sum(NetAmountVND) AS NetAmountVND
		FROM #tblSal_Abroad_ForTaxPurpose_des sa
		WHERE sa.Month = @Month AND sa.Year = @Year AND sa.EmployeeID = sal.EmployeeID
		) ca
	WHERE sal.LatestSalEntry = 1 AND sal.IsNet = 1

	-- custom lấy cái TotalNetIncome ra nào
	UPDATE #tblSalDetail
	SET TotalNetIncome_Custom = TaxableIncomeBeforeDeduction

	--gross it up
	SELECT (IncomeFrom - (IncomeFrom - 1)) * TaxPercent + ProgressiveAmount AS MinTax -- số thuế tối thiểu phải đóng
		, (IncomeTo - (IncomeFrom - 1)) * TaxPercent + ProgressiveAmount AS MaxTax -- số thuế tối đa phải đóng
		, IncomeFrom - 1 --+9000000
		- ((IncomeFrom - (IncomeFrom - 1)) * TaxPercent + ProgressiveAmount) AS MinNet -- số tiền net tối thiểu (chưa tính giảm trừ trong này nha)
		, IncomeTo - 1 --+9000000
		- ((IncomeTo - (IncomeFrom - 1)) * TaxPercent + ProgressiveAmount) AS MaxNet -- số tiền net tối đa (chưa tính giảm trừ trong này nha)
		, *
	INTO #TaxForGrossup
	FROM tblTax tt
	WHERE tt.EffectDate = (
			SELECT Max(EffectDate)
			FROM tblTax tx
			WHERE tx.EffectDate <= @FromDate
			) --for gross up

	DECLARE @PesonalDeduct FLOAT(53), @RelationDeduct FLOAT(53)

	SELECT @PesonalDeduct = TAX_PERSONAL_DEDUCT, @RelationDeduct = TAX_RELATE_DEDUCT
	FROM fn_TaxDeduction_byMonthYear(@Month, @Year)

	--set @PesonalDeduct = (select cast(Value as float(53)) from tblParameter where code = 'TAX_PERSONAL_DEDUCT')
	SET @PesonalDeduct = isnull(@PesonalDeduct, 9000000)
	--set @RelationDeduct = (select cast(Value as float(53)) from tblParameter where code = 'TAX_RELATE_DEDUCT')
	SET @RelationDeduct = isnull(@RelationDeduct, 3600000)

	SELECT EmployeeID, count(EmployeeID) AS CountDeduct
	INTO #CountRelation
	FROM tblFamilyInfo
	WHERE TaxDependant = 1 AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			) AND ISNULL(EffectiveDate, @ToDate) <= @ToDate AND ISNULL(EffectiveToDate, @FromDate) >= @FromDate
	GROUP BY EmployeeID

	-- đang làm tới đây
	----update dependant truocws nhes
	--select TaxableIncomeBeforeDeduction,-- tính before tax coi có ngon chưa nào
	UPDATE sal
	SET TaxableIncomeBeforeDeduction = round((IncomeFrom - 1) + -- lấy khoản Income from
			((TaxableIncomeBeforeDeduction - (MinNet + @PesonalDeduct + (isnull(c.CountDeduct, 0) * @RelationDeduct))) / (1 - TaxPercent)) -- cộng với công thức ba lăng nhăng
			+ @PesonalDeduct + (isnull(c.CountDeduct, 0) * @RelationDeduct) -- cộng với giảm trừ bản thân, gia đình, tới đây còn thiếu cái tiền bảo hiểm tý mới cộng
			--as TaxableIncomeBeforeDeduction_GrossedUp
			--,MinNet
			--,*
			, 0, 1)
	FROM #tblSalDetail sal
	LEFT JOIN #CountRelation c ON sal.EmployeeID = c.EmployeeID
	INNER JOIN #TaxForGrossup tg ON sal.TaxableIncomeBeforeDeduction -- đổi với những người lương NET thì cái này được hiểu là tổng lương net Nhé anh em
		- @PesonalDeduct - (isnull(c.CountDeduct, 0) * @RelationDeduct) BETWEEN tg.MinNet AND tg.MaxNet
	WHERE IsNet = 1

	UPDATE #tblSalDetail
	SET GrossedUpWithoutHousing_WithoutGrossIncome_Custom = TaxableIncomeBeforeDeduction

	IF EXISTS (
			SELECT 1
			FROM #grossAllowanceAmount
			) -- nếu có gross allowance thì cộng vào lại chứ ko vỡ mồm
	BEGIN
		UPDATE #tblSalDetail
		SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + isnull(gross.TotalGrossAllowanceAmount_Taxable, 0)
		FROM #tblSalDetail sal
		INNER JOIN #grossAllowanceAmount gross ON sal.EmployeeID = gross.EmployeeID AND sal.LatestSalEntry = 1
		WHERE sal.IsNet = 1
	END

	-------------------------Calculate Employee insurance --------------------------------
	IF @PeriodID IN (0, 2)
	BEGIN
		IF @CalculateRetro = 1
			EXEC EmpInsuranceMonthly_List @Month = @Month, @Year = @Year, @LoginID = @LoginID, @CalFromSalCal = 1, @CalculateRetro = 1, @EmployeeID = @EmployeeID
		ELSE
			EXEC EmpInsuranceMonthly_List @Month = @Month, @Year = @Year, @LoginID = @LoginID, @CalFromSalCal = 1, @EmployeeID = @EmployeeID
	END

	----khong co cham cong thi khong dong bao hiem
	--select si.EmployeeTotal,TaxableIncomeBeforeDeduction,TaxableIncomeBeforeDeduction*0.15,*
	UPDATE sal
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + isnull(si.EmployeeTotal, 0), GrossedUpWithoutHousing_WithoutGrossIncome_Custom = GrossedUpWithoutHousing_WithoutGrossIncome_Custom + isnull(si.EmployeeTotal, 0)
	FROM #tblSalDetail sal
	INNER JOIN tblSal_Insurance si ON sal.EmployeeID = si.EmployeeID AND si.Month = @Month AND si.Year = @Year
	WHERE sal.LatestSalEntry = 1 AND sal.IsNet = 1 AND @PeriodID IN (0, 2)

	-- cộng thêm lương gross từ nước ngoài
	UPDATE sal
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + isnull(ca.GrossAmountVND, 0)
	FROM #tblSalDetail sal
	CROSS APPLY (
		SELECT sum(GrossAmountVND) AS GrossAmountVND
		FROM #tblSal_Abroad_ForTaxPurpose_des sa
		WHERE sa.Month = @Month AND sa.Year = @Year AND sa.EmployeeID = sal.EmployeeID
		) ca
	WHERE sal.LatestSalEntry = 1 AND sal.IsNet = 1

	UPDATE #tblSalDetail
	SET GrossedUpWithoutHousing_Custom = round(TaxableIncomeBeforeDeduction, 0)

	--tien nha mac dinh tinh thue het, neu vuot qua 15% thu nhap chiu thue thi duoc mien thue phan du tren 15% đó ~~ TriNg: la khoản fixed - nen thue f lay full thang
	UPDATE a
	SET UntaxableAmount = round(CASE
				WHEN ISNULL(a.ReceiveAmount, 0) > s.TaxableIncomeBeforeDeduction * @HouseAllPercent / 100.0
					THEN a.ReceiveAmount - s.TaxableIncomeBeforeDeduction * @HouseAllPercent / 100.0
				ELSE 0
				END, @ROUND_SALARY_UNIT)
	FROM #tblAllowance a
	INNER JOIN tblAllowanceSetting sa ON a.AllowanceID = sa.AllowanceID AND sa.IsHouseAllowance = 1 AND a.ReceiveAmount > 0
	INNER JOIN (
		SELECT EmployeeID, SUM(TaxableIncomeBeforeDeduction) TaxableIncomeBeforeDeduction
		FROM #tblSalDetail
		GROUP BY EmployeeID
		) s ON a.EmployeeID = s.EmployeeID

	IF (OBJECT_ID('SALCAL_ALLOWANCE_FINISHED') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_ALLOWANCE_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,


	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20),
	@CalculateRetro bit =0
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_ALLOWANCE_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID, @CalculateRetro

	UPDATE #tblAllowance
	SET TaxableAmount = ISNULL(ReceiveAmount, 0) - ISNULL(RetroAmount, 0) - ISNULL(UntaxableAmount, 0)

	DELETE #tblAllowance
	WHERE isnull(DefaultAmount, 0) = 0 AND isnull(ReceiveAmount, 0) = 0

	UPDATE #tblAllowance
	SET ReceiveAmount = 0
	WHERE ReceiveAmount IS NULL

	UPDATE #tblAllowance
	SET ReceiveAmount = ROUND(ReceiveAmount, @ROUND_SALARY_UNIT), TaxableAmount = ROUND(TaxableAmount, @ROUND_SALARY_UNIT), UntaxableAmount = ROUND(UntaxableAmount, @ROUND_SALARY_UNIT), MonthlyCustomAmount = ROUND(MonthlyCustomAmount, @ROUND_SALARY_UNIT), DefaultAmount = ROUND(DefaultAmount_WithoutCustomAmount, @ROUND_SALARY_UNIT)

	--bang detail cung sum luôn, vi se co nhung thang thu viec trùng salaryhistoryid wtc
	INSERT INTO #tblSal_Allowance_Detail_des (
		EmployeeID, AllowanceID, Year, Month, SalaryHistoryID, Amount, TakeHome, TaxableAmount, UntaxableAmount, DefaultAmount --chay lenh nay neu bao loi:	ALTER TABLE #tblSal_Allowance_Detail_des ADD DefaultAmount float(53)
		, Raw_DefaultAmount, Raw_CurrencyCode, Raw_ExchangeRate, RetroAmount, RetroAmountNonTax, MonthlyCustomAmount, PeriodID, TotalPaidDays, LatestSalEntry
		)
	SELECT a.EmployeeID, a.AllowanceID, @Year, @Month, a.SalaryHistoryID, sum(a.ReceiveAmount), a.TakeHome, sum(a.TaxableAmount), sum(a.UntaxableAmount), sum(DefaultAmount), sum(a.Raw_DefaultAmount), max(a.Raw_CurrencyCode), max(a.Raw_ExchangeRate), sum(a.RetroAmount), sum(a.RetroAmountNonTax), sum(a.MonthlyCustomAmount), @PeriodID, sum(a.TotalPaidDays), MAX(cast(LatestSalEntry AS INT))
	FROM #tblAllowance a
	GROUP BY a.EmployeeID, a.AllowanceID, a.SalaryHistoryID, a.TakeHome

	INSERT INTO #tblSal_Allowance_des (EmployeeID, AllowanceID, [Year], [Month], Amount, TakeHome, UntaxableAmount, TaxableAmount, Raw_DefaultAmount, Raw_CurrencyCode, Raw_ExchangeRate, RetroAmount, RetroAmountNonTax, MonthlyCustomAmount, PeriodID) (
		SELECT al.EmployeeID, al.AllowanceID, @Year, @Month, SUM(ISNULL(al.ReceiveAmount, 0)), al.TakeHome, sum(UntaxableAmount) AS UntaxableAmount, sum(TaxableAmount) AS TaxableAmount, sum(CASE
				WHEN LatestSalEntry = 1
					THEN Raw_DefaultAmount
				ELSE 0
				END) AS Raw_DefaultAmount, max(Raw_CurrencyCode) AS Raw_CurrencyCode, max(Raw_ExchangeRate) AS Raw_ExchangeRate, sum(RetroAmount) AS RetroAmount, SUM(RetroAmountNonTax) AS RetroAmountNonTax, SUM(MonthlyCustomAmount) AS MonthlyCustomAmount, @PeriodID FROM #tblAllowance al GROUP BY al.EmployeeID, al.AllowanceID, al.TakeHome
		)

	-- taxable allowance
	UPDATE #tblSalDetail
	SET TaxableAllowanceTotal = round(tmp.TaxableAmount, @ROUND_SALARY_UNIT)
	FROM #tblSalDetail sal, (
			SELECT SUM(ISNULL(al.TaxableAmount, 0) + ISNULL(al.RetroAmount, 0) - ISNULL(al.RetroAmountNonTax, 0)) TaxableAmount, al.EmployeeID
			FROM #tblAllowance al
			GROUP BY al.EmployeeID
			) tmp
	WHERE sal.EmployeeID = tmp.EmployeeID AND sal.LatestSalEntry = 1

	-- Nonetaxable allowance
	UPDATE #tblSalDetail
	SET NoneTaxableAllowanceTotal = round(tmp.UntaxableAmount, @ROUND_SALARY_UNIT)
	FROM #tblSalDetail sal, (
			SELECT SUM(ISNULL(al.UntaxableAmount, 0) + ISNULL(al.RetroAmountNonTax, 0)) UntaxableAmount, al.EmployeeID
			FROM #tblAllowance al
			GROUP BY al.EmployeeID
			) tmp
	WHERE sal.EmployeeID = tmp.EmployeeID AND sal.LatestSalEntry = 1

	UPDATE #tblSalDetail
	SET TotalAllowanceForSalary = tmp.ReceiveAmount
	FROM #tblSalDetail sal, (
			SELECT SUM(ISNULL(al.ReceiveAmount, 0)) ReceiveAmount, al.EmployeeID
			FROM #tblAllowance al
			INNER JOIN tblAllowanceSetting a ON al.AllowanceID = a.AllowanceID
			GROUP BY al.EmployeeID
			) tmp
	WHERE sal.EmployeeID = tmp.EmployeeID AND sal.LatestSalEntry = 1

	--select TotalAllowanceForSalary,* from #tblSalDetail
	-------------------------Calculate Employee insurance --------------------------------
	EXEC EmpInsuranceMonthly_List @Month = @Month, @Year = @Year, @LoginID = @LoginID, @CalFromSalCal = 1

	--bao hiem
	UPDATE #tblSalDetail
	SET InsAmtComp = CompanyTotal --ISNULL(CompanySI,0) + ISNULL(CompanyHI,0) + ISNULL(CompanyUI,0)
		, InsAmt = EmployeeTotal --ISNULL(EmployeeSI,0) + ISNULL(EmployeeHI,0) + ISNULL(EmployeeUI,0)
	FROM #tblSalDetail sd
	INNER JOIN tblSal_Insurance ins ON sd.EmployeeID = ins.EmployeeID
		--AND sd.SalaryHistoryID = ins.SalaryHistoryID
		AND ins.[Month] = @Month AND ins.[Year] = @Year AND sd.LatestSalEntry = 1 AND @PeriodID IN (0, 2) AND sd.isNet = 0

	UPDATE #tblSalDetail
	SET InsAmtComp = CompanyTotal --ISNULL(CompanySI,0) + ISNULL(CompanyHI,0) + ISNULL(CompanyUI,0)
		, InsAmt = EmployeeTotal - ISNULL(ins.EmployeeSI, 0) --ISNULL(EmployeeSI,0) + ISNULL(EmployeeHI,0) + ISNULL(EmployeeUI,0)
	FROM #tblSalDetail sd
	INNER JOIN tblSal_Insurance ins ON sd.EmployeeID = ins.EmployeeID
		--AND sd.SalaryHistoryID = ins.SalaryHistoryID
		AND ins.[Month] = @Month AND ins.[Year] = @Year AND sd.LatestSalEntry = 1 AND @PeriodID IN (0, 2) AND sd.isNet = 1

	-------------------------Calculate Trade Union fee--------------------------------
	DECLARE @UNION_FEE_METHOD TINYINT

	-- 1: Dựa vào phần trăm lương,
	-- 2: Số tiền đóng cố định,
	-- 3: nhân viên đóng số tiền cố định, công ty đóng theo % lương cơ bản,
	-- 4: đóng theo phần trăm lương tối thiểu,
	-- 5: đóng theo phần trăm lương cơ bản, nhân viên đóng tối đa 10% lương tối thiểu
	SET @UNION_FEE_METHOD = (
			SELECT CAST([Value] AS FLOAT)
			FROM tblParameter
			WHERE Code = 'UNION_FEE_METHOD'
			)
	SET @UNION_FEE_METHOD = isnull(@UNION_FEE_METHOD, 1)

	-- danh sach tham gia cong doan
	--co phat sinh bao hiem xa hoi trong thang nay thi se dong tien cong doan
	SELECT EmployeeID
	INTO #Insurance
	FROM tblSal_Insurance
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			) AND CompanyTotal > 0

	--VU: tripod: tự động tham gia công đoàn
	INSERT INTO tblJoinedUnionEmployeeMonthly (EmployeeID, Month, Year, EmpPay)
	SELECT EmployeeID, @Month, @Year, 1
	FROM #tblEmployeeIDList t
	WHERE NOT EXISTS (
			SELECT *
			FROM tblJoinedUnionEmployeeMonthly m
			WHERE m.EmployeeID = t.EmployeeID AND m.Month = @Month AND m.Year = @Year
			)

	DECLARE @UnionPercentEmp FLOAT, @UnionPercentComp FLOAT, @UnionPackageEmp FLOAT, @UnionPackageComp FLOAT

	CREATE TABLE #tblTradeUnion (EmployeeID VARCHAR(20), BasicSalary FLOAT(53), BaseSalaryRegional FLOAT(53), IsEmpPaid BIT, IsComPaid BIT, UnionFeeEmp FLOAT(53), UnionFeeComp FLOAT(53), Comp_ByPercent BIT, Emp_ByPercent BIT, Is_CeilSalary BIT, UNION_PERCENT_COMP FLOAT, UNION_PERCENT_EMP FLOAT, UNION_PACKAGE_COMP FLOAT, UNION_PACKAGE_EMP FLOAT, UNION_PACKAGE_EMP_MAX FLOAT, UNION_PACKAGE_COMP_MAX FLOAT, MaximumByPercentsOfBaseSalaryRegional FLOAT)

	INSERT INTO #tblTradeUnion (EmployeeID, IsEmpPaid, IsComPaid, Comp_ByPercent, Emp_ByPercent, Is_CeilSalary, UNION_PERCENT_COMP, UNION_PERCENT_EMP, UNION_PACKAGE_COMP, UNION_PACKAGE_EMP, UNION_PACKAGE_EMP_MAX, UNION_PACKAGE_COMP_MAX, MaximumByPercentsOfBaseSalaryRegional)
	SELECT u.EmployeeID, 0, 1, Comp_ByPercent, Emp_ByPercent, Is_CeilSalary, UNION_PERCENT_COMP, UNION_PERCENT_EMP, UNION_PACKAGE_COMP, UNION_PACKAGE_EMP, isnull(UNION_PACKAGE_EMP_MAX, 0), isnull(UNION_PACKAGE_COMP_MAX, 0), MaximumByPercentsOfBaseSalaryRegional
	FROM #tblEmployeeIDList u
	INNER JOIN tblDivision div ON u.DivisionID = div.DivisionID
	CROSS APPLY (
		SELECT TOP 1 (UNION_FEE_METHOD) AS UNION_FEE_METHOD
		FROM tblCompany c
		) c
	LEFT JOIN tblUnionFeeMethod f ON f.UnionFeeMethodID = isnull(isnull(div.UNION_FEE_METHOD, c.UNION_FEE_METHOD), 3)

	UPDATE #tblTradeUnion
	SET IsEmpPaid = 1
	FROM #tblTradeUnion t
	WHERE EXISTS (
			SELECT 1
			FROM tblJoinedUnionEmployeeMonthly un
			WHERE t.EmployeeID = un.EmployeeID AND un.Month = @Month AND un.Year = @Year AND isnull(EmpPay, 0) = 1
			) AND t.EmployeeID IN (
			SELECT EmployeeID
			FROM #Insurance
			)

	SELECT EmployeeID, Year, Month, HIIncome, SIIncome, EmployeeHI, EmployeeSI, EmployeeTotal, CompanyHI, CompanySI, CompanySM, CompanyTotal, Total, SalaryHistoryID, UIIncome, EmployeeUI, CompanyUI, Approval, UnionFeeEmp, UnionFeeComp, Notes, InsPaymentStatus
	INTO #tblSal_Insurance_Forquery
	FROM tblSal_Insurance_Retro
	WHERE @CalculateRetro = 1 AND Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			)

	INSERT INTO #tblSal_Insurance_Forquery (EmployeeID, Year, Month, HIIncome, SIIncome, EmployeeHI, EmployeeSI, EmployeeTotal, CompanyHI, CompanySI, CompanySM, CompanyTotal, Total, SalaryHistoryID, UIIncome, EmployeeUI, CompanyUI, Approval, UnionFeeEmp, UnionFeeComp, Notes, InsPaymentStatus)
	SELECT EmployeeID, Year, Month, HIIncome, SIIncome, EmployeeHI, EmployeeSI, EmployeeTotal, CompanyHI, CompanySI, CompanySM, CompanyTotal, Total, SalaryHistoryID, UIIncome, EmployeeUI, CompanyUI, Approval, UnionFeeEmp, UnionFeeComp, Notes, InsPaymentStatus
	FROM tblSal_Insurance
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			) AND EmployeeID NOT IN (
			SELECT EmployeeID
			FROM #tblSal_Insurance_Forquery
			)

	--bao giam thi ko dong tien cong doan thang nay
	UPDATE #tblTradeUnion
	SET IsComPaid = 0, IsEmpPaid = 0
	FROM #tblTradeUnion u
	WHERE u.EmployeeID NOT IN (
			SELECT EmployeeID
			FROM #tblSal_Insurance_Forquery i
			WHERE (ISNULL(i.EmployeeSI, 0) <> 0 OR ISNULL(i.CompanySI, 0) <> 0)
			) AND u.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList e
			)

	UPDATE #tblTradeUnion
	SET IsEmpPaid = 0
	FROM #tblTradeUnion t
	LEFT JOIN #tblSal_AttendanceData ta ON t.EmployeeID = ta.EmployeeID
	WHERE (ta.EmployeeID IS NULL OR ISNULL(ta.TotalPaidDays, 0) = 0)

	UPDATE #tblTradeUnion
	SET BasicSalary = i.SIIncome
	FROM #tblTradeUnion u
	INNER JOIN #tblSal_Insurance_Forquery i ON u.EmployeeID = i.EmployeeID

	--where i.Month = @Month and i.Year = @Year and i.EmployeeID in (select EmployeeID from #tblEmployeeIDList)
	UPDATE #tblTradeUnion
	SET BasicSalary = s.SI_Salary
	FROM #tblTradeUnion u
	INNER JOIN dbo.fn_CurrentSISalary_byDate(@SIDate, @LoginID) s ON u.EmployeeID = s.EmployeeID
	WHERE u.BasicSalary IS NULL OR u.BasicSalary <= 0

	DECLARE @miniMumsal MONEY = (
			SELECT TOP 1 a.MinimumSal
			FROM tblSI_CeilSalary a
			WHERE a.EffectiveDate = (
					SELECT Max(sie.EffectiveDate) EffectiveDate
					FROM tblSI_CeilSalary sie
					WHERE sie.EffectiveDate <= @FromDate
					)
			)

	UPDATE u
	SET BaseSalaryRegional = @miniMumsal
	FROM #tblTradeUnion u -- thay đổi đóng theo lương tối thiểu
		-- inner join #tblSalDetail s on u.EmployeeID = s.EmployeeID
		--inner join dbo.fn_CurrentBaseSalRegionalByDate(@SIDate) b on s.BaseSalRegionalID = b.BaseSalRegionalID
		--where s.LatestSalEntry = 1

	-- nếu đóng theo lương cơ sở
	UPDATE #tblTradeUnion
	SET BasicSalary = @miniMumsal
	WHERE Is_CeilSalary = 1

	-- nếu dc chặn lại bởi 10% lương cơ sở vùng
	UPDATE #tblTradeUnion
	SET UnionFeeEmp = CASE
			WHEN isnull(Emp_ByPercent, 0) = 1
				THEN UNION_PERCENT_EMP * BasicSalary / 100
			ELSE UNION_PACKAGE_EMP
			END * IsEmpPaid, UnionFeeComp = CASE
			WHEN isnull(Comp_ByPercent, 0) = 1
				THEN UNION_PERCENT_COMP * BasicSalary / 100
			ELSE UNION_PACKAGE_COMP
			END * IsComPaid

	UPDATE #tblTradeUnion
	SET UnionFeeEmp = BaseSalaryRegional * MaximumByPercentsOfBaseSalaryRegional / 100
	WHERE MaximumByPercentsOfBaseSalaryRegional > 0 AND UnionFeeEmp > BaseSalaryRegional * MaximumByPercentsOfBaseSalaryRegional / 100

	UPDATE #tblTradeUnion
	SET UnionFeeEmp = ISNULL(i.UnionFeeEmp, u.UnionFeeEmp), UnionFeeComp = ISNULL(i.UnionFeeComp, u.UnionFeeComp)
	FROM #tblTradeUnion u
	INNER JOIN #tblSal_Insurance_Forquery i ON u.EmployeeID = i.EmployeeID
		--	and i.Month = @Month and i.Year = @Year
		AND (i.UnionFeeEmp IS NOT NULL OR i.UnionFeeComp IS NOT NULL)

	-- Bị chặn bởi mức max trong thiết lập công đoàn
	UPDATE #tblTradeUnion
	SET UnionFeeEmp = UNION_PACKAGE_EMP_MAX
	WHERE UNION_PACKAGE_EMP_MAX > 0 AND UnionFeeEmp > UNION_PACKAGE_EMP_MAX

	UPDATE #tblTradeUnion
	SET UnionFeeComp = UNION_PACKAGE_COMP_MAX
	WHERE UNION_PACKAGE_COMP_MAX > 0 AND UnionFeeComp > UNION_PACKAGE_COMP_MAX

	INSERT INTO #tblTradeUnion (EmployeeID, UnionFeeEmp, UnionFeeComp)
	SELECT EmployeeID, ISNULL(UnionFeeEmp, 0), ISNULL(UnionFeeComp, 0)
	FROM #tblSal_Insurance_Forquery i
	WHERE --i.Month = @Month and i.Year = @Year and
		(i.UnionFeeEmp IS NOT NULL OR i.UnionFeeComp IS NOT NULL) AND NOT EXISTS (
			SELECT 1
			FROM #tblTradeUnion u
			WHERE i.EmployeeID = u.EmployeeID
			) AND i.EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			)

	UPDATE sal
	SET EmpUnion_RETRO = round(re.Union_RETRO_EE, 0), EmpUnion = round(uni.UnionFeeEmp, 0), CompUnion_RETRO = round(re.Union_RETRO_ER, 0), CompUnion = round(uni.UnionFeeComp, 0)
	FROM #tblSalDetail sal
	LEFT JOIN #tblTradeUnion uni ON sal.EmployeeID = uni.EmployeeID
	LEFT JOIN #tblsal_retro_Final re ON sal.EmployeeID = re.EmployeeID --and re.Month = @Month and re.Year = @Year
	WHERE sal.LatestSalEntry = 1

	--------------------- Calculate IO ----------------------------------
	IF (OBJECT_ID('SALCAL_IO_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_IO_INITIAL
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_IO_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	IF @StopUPDATE = 0
	BEGIN
		INSERT INTO #tblSal_IO_des (EmployeeID, Month, Year, InLateHours, InLateAmount, PeriodID)
		SELECT EmployeeID, Month, Year, InLateHours, InLateAmount, @PeriodID
		FROM (
			INSERT INTO #tblSal_IO_Detail_des (EmployeeID, Month, Year, SalaryHistoryID, InLateHours, OutEarlyHours, InLateAmount, OutEarlyAmount, PeriodID)
			OUTPUT inserted.*
			SELECT sal1.EmployeeID, @Month, @Year, isnull(sal1.ProbationSalaryHistoryID, SalaryHistoryID), sal2.DeductionHours, 0, sal1.IOAmt, 0, @PeriodID
			FROM #tblSalDetail sal1
			INNER JOIN #tblSal_AttendanceData sal2 ON sal1.EmployeeID = sal2.EmployeeID
			WHERE sal2.DeductionHours IS NOT NULL
			) tmp
		WHERE tmp.InLateAmount IS NOT NULL
	END

	----------------------Payroll sumaried items-----------------------------------------
	UPDATE #tblSalDetail
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction - ISNULL(InsAmt, 0) - ISNULL(EmpUnion, 0)
	WHERE isNet = 0

	SELECT *, CAST(NULL AS FLOAT(53)) TaxableIncome_SalaryOnly
	INTO #tblSalDetail_ForTax
	FROM #tblSalDetail
	WHERE LatestSalEntry = 1 --lấy dòng lương cuối cùng chắc chắn có

	UPDATE #tblSalDetail_ForTax
	SET ActualMonthlyBasic = s.ActualMonthlyBasic, UnpaidLeaveAmount = s.UnpaidLeaveAmount, TaxableOTTotal = s.TaxableOTTotal, NoneTaxableOTTotal = s.NoneTaxableOTTotal, TotalOTAmount = s.TotalOTAmount, TotalNSAmt = s.TotalNSAmt, NoneTaxableNSAmt = s.NoneTaxableNSAmt
	FROM #tblSalDetail_ForTax t
	INNER JOIN (
		SELECT EmployeeID, SUM(ActualMonthlyBasic) ActualMonthlyBasic, SUM(UnpaidLeaveAmount) UnpaidLeaveAmount, SUM(TaxableOTTotal) TaxableOTTotal, SUM(NoneTaxableOTTotal) NoneTaxableOTTotal, SUM(TotalOTAmount) TotalOTAmount, SUM(TotalNSAmt) TotalNSAmt, SUM(NoneTaxableNSAmt) NoneTaxableNSAmt
		FROM #tblSalDetail d
		GROUP BY EmployeeID
		) s ON t.EmployeeID = s.EmployeeID

	UPDATE #tblSalDetail_ForTax
	SET GrossTakeHome = round((ActualMonthlyBasic + isnull(TotalOTAmount, 0) + isnull(TotalNSAmt, 0) + ISNULL(TotalAllowanceForSalary, 0) + isnull(TotalAdjustmentForSalary, 0)), @ROUND_TAKE) - (ISNULL(InsAmt, 0) + ISNULL(IOAmt, 0) + ISNULL(EmpUnion, 0)), TotalCostComPaid = ActualMonthlyBasic + isnull(TotalOTAmount, 0) + isnull(TotalNSAmt, 0) + ISNULL(TaxableAllowanceTotal, 0) + ISNULL(NoneTaxableAllowanceTotal, 0) + ISNULL(InsAmtComp, 0) - ISNULL(IOAmt, 0) + ISNULL(CompUnion, 0) + isnull(CompUnion_RETRO, 0) + CASE
			WHEN ISNULL(IsNet, 0) = 1
				THEN ISNULL(InsAmt, 0)
			ELSE 0
			END

	UPDATE #tblSalDetail_ForTax
	SET TotalPayrollFund = TotalCostComPaid

	--tripod
	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction - ISNULL(InsAmt, 0) - ISNULL(EmpUnion, 0)
	WHERE isNet = 0

	UPDATE #tblSalDetail_ForTax
	SET TotalCostComPaid = ISNULL(TotalCostComPaid, 0) + adj.AdjustmentAmount
	FROM #tblSalDetail_ForTax sal
	INNER JOIN (
		SELECT a.EmployeeID, SUM(CASE
					WHEN ir.IncomeKind = 1
						THEN a.AdjustmentAmount
					ELSE - 1 * a.AdjustmentAmount
					END) AS AdjustmentAmount
		FROM #AdjustmentSum a
		INNER JOIN tblIrregularIncome ir ON a.IncomeID = ir.IncomeID AND ISNULL(ir.isNotLabourCost, 0) = 0
		GROUP BY a.EmployeeID
		) adj ON sal.EmployeeID = adj.EmployeeID

	UPDATE #tblSalDetail_ForTax
	SET TotalPayrollFund = ISNULL(TotalPayrollFund, 0) + adj.AdjustmentAmount
	FROM #tblSalDetail_ForTax sal
	INNER JOIN (
		SELECT a.EmployeeID, SUM(CASE
					WHEN ir.IncomeKind = 1
						THEN a.AdjustmentAmount
					ELSE - 1 * a.AdjustmentAmount
					END) AS AdjustmentAmount
		FROM #AdjustmentSum a
		INNER JOIN tblIrregularIncome ir ON a.IncomeID = ir.IncomeID -- and ISNULL(ir.isNotLabourCost,0) = 0
		GROUP BY a.EmployeeID
		) adj ON sal.EmployeeID = adj.EmployeeID

	--Taxable before deduct co tru luon tien bao hiem 10.5% cua nhan vien
	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction = ISNULL(ActualMonthlyBasic, 0) + ISNULL(TotalNSAmt, 0) - isnull(NoneTaxableNSAmt, 0) + ISNULL(TaxableAllowanceTotal, 0) + ISNULL(TaxableAdjustmentTotal, 0) - ISNULL(IOAmt, 0) + ISNULL(TaxableOTTotal, 0) - ISNULL(InsAmt, 0), TotalIncome_Taxable_Without_INS_Persion_family = ISNULL(ActualMonthlyBasic, 0) + ISNULL(TotalNSAmt, 0) - isnull(NoneTaxableNSAmt, 0) + ISNULL(TaxableAllowanceTotal, 0) + ISNULL(TaxableAdjustmentTotal, 0) - ISNULL(IOAmt, 0) + ISNULL(TaxableOTTotal, 0)

	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + ISNULL(InsAmt, 0)
	WHERE IsNet = 1

	-- nếu muốn cộng insurance vào nếu 10%
	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + ISNULL(InsAmt, 0)
	FROM #tblSalDetail_ForTax t
	INNER JOIN #tblEmployeeIDList e ON t.EmployeeId = e.EmployeeID
	--inner join tblDivision div on e.DivisionId = div.DivisionID and div.Add_EE_Insurance_Into_TaxableIncome = 1
	WHERE isnull(t.IsNet, 0) = 0 AND t.employeeID IN (
			SELECT employeeId
			FROM #tblTemporaryContractTax
			)

	-- cộng INS vào làm tổng lương trước khi trừ deduction
	-- trừ các khoảng thuế gross ra
	-- + với net từ nước ngoài

	-- gross up nó
	-- + lại allowance gross
	-- + insurance + gross từ nước ngoài
	-- tính toán lại tổng số lương trước khi nhảy qua đoạn thu
	--select 9999,* from tblSal_Abroad_ForTaxPurpose
	-- lấy danh sách allowance Gross ra trừ đi trước khi grossup
	-- có thể net hóa nó nhưng mà khó lém
	TRUNCATE TABLE #grossAllowanceAmount

	INSERT INTO #grossAllowanceAmount
	SELECT EmployeeID, sum(TaxableAmount) AS TotalGrossAllowanceAmount_Taxable
	FROM #tblAllowance a
	INNER JOIN tblAllowanceSetting al ON a.AllowanceCode = al.AllowanceCode
	WHERE al.IsTaxable = 1 AND al.IsGrossAllowance_InNetSal = 1
	GROUP BY EmployeeID

	IF @@ROWCOUNT > 0 -- nếu có gross allowance thì phải trừ đi rồi mới gross up
	BEGIN
		UPDATE #tblSalDetail_ForTax
		SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction - isnull(gross.TotalGrossAllowanceAmount_Taxable, 0)
		FROM #tblSalDetail_ForTax sal
		INNER JOIN #grossAllowanceAmount gross ON sal.EmployeeID = gross.EmployeeID AND sal.LatestSalEntry = 1
		WHERE sal.IsNet = 1
	END

	-- cộng cục này với phần Net từ nước ngoài trả
	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction += ISNULL(ca.NetAmountVND, 0) -- cộng phần net để grossup trước
	FROM #tblSalDetail_ForTax sal
	CROSS APPLY (
		SELECT sum(NetAmountVND) AS NetAmountVND
		FROM #tblSal_Abroad_ForTaxPurpose_des sa
		WHERE sa.Month = @Month AND sa.Year = @Year AND sa.EmployeeID = sal.EmployeeID
		) ca
	WHERE sal.LatestSalEntry = 1 AND sal.IsNet = 1

	--gross it up
	----update dependant truocws nhes
	--select TaxableIncomeBeforeDeduction,-- tính before tax coi có ngon chưa nào
	UPDATE sal
	SET TaxableIncomeBeforeDeduction = round((IncomeFrom - 1) + -- lấy khoản Income from
			((TaxableIncomeBeforeDeduction - (MinNet + @PesonalDeduct + (isnull(c.CountDeduct, 0) * @RelationDeduct))) / (1 - TaxPercent)) -- cộng với công thức ba lăng nhăng
			+ @PesonalDeduct + (isnull(c.CountDeduct, 0) * @RelationDeduct) -- cộng với giảm trừ bản thân, gia đình, tới đây còn thiếu cái tiền bảo hiểm tý mới cộng
			--as TaxableIncomeBeforeDeduction_GrossedUp
			--,MinNet
			--,*
			, 0, 1)
	FROM #tblSalDetail_ForTax sal
	LEFT JOIN #CountRelation c ON sal.EmployeeID = c.EmployeeID
	INNER JOIN #TaxForGrossup tg ON sal.TaxableIncomeBeforeDeduction -- đổi với những người lương NET thì cái này được hiểu là tổng lương net Nhé anh em
		- @PesonalDeduct - (isnull(c.CountDeduct, 0) * @RelationDeduct) BETWEEN tg.MinNet AND tg.MaxNet
	WHERE IsNet = 1

	-- lấy cái net của cty ra trước khi cộng gross - ee trả thuế vào
	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction_EROnly_ForNETOnly = TaxableIncomeBeforeDeduction
	WHERE IsNet = 1

	IF EXISTS (
			SELECT 1
			FROM #grossAllowanceAmount
			) -- nếu có gross allowance thì cộng vào lại chứ ko vỡ mồm
	BEGIN
		UPDATE #tblSalDetail_ForTax
		SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + isnull(gross.TotalGrossAllowanceAmount_Taxable, 0)
		FROM #tblSalDetail_ForTax sal
		INNER JOIN #grossAllowanceAmount gross ON sal.EmployeeID = gross.EmployeeID
		WHERE sal.IsNet = 1 AND sal.LatestSalEntry = 1
	END

	-------------------------Calculate Employee insurance --------------------------------
	--select si.EmployeeTotal,TaxableIncomeBeforeDeduction,TaxableIncomeBeforeDeduction*0.15,*
	UPDATE sal
	SET TotalIncome_Taxable_Without_INS_Persion_family = TaxableIncomeBeforeDeduction + isnull(si.EmployeeTotal, 0)
	FROM #tblSalDetail_ForTax sal
	LEFT JOIN tblSal_Insurance si ON sal.EmployeeID = si.EmployeeID AND si.Month = @Month AND si.Year = @Year
	WHERE sal.LatestSalEntry = 1 AND IsNet = 1

	-- cộng thêm lương gross từ nước ngoài
	UPDATE sal
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction + isnull(ca.GrossAmountVND, 0)
	FROM #tblSalDetail_ForTax sal
	CROSS APPLY (
		SELECT sum(GrossAmountVND) AS GrossAmountVND
		FROM #tblSal_Abroad_ForTaxPurpose_des sa
		WHERE sa.Month = @Month AND sa.Year = @Year AND sa.EmployeeID = sal.EmployeeID
		) ca
	WHERE sal.LatestSalEntry = 1 AND sal.IsNet = 1

	-- kết thúc gross up
	UPDATE #tblSalDetail_ForTax
	SET TotalIncome = round(isnull(ActualMonthlyBasic, 0) + isnull(TotalOTAmount, 0) + isnull(TotalNSAmt, 0) + ISNULL(TotalAllowanceForSalary, 0) + isnull(TotalAdjustmentForSalary, 0) + isnull(OtherDeductionAfterPIT, 0) - ISNULL(IOAmt, 0), @ROUND_NET), TaxableIncome = TaxableIncomeBeforeDeduction - ROUND(ISNULL(NoneTaxableOTTotal, 0), 0) --TRIPOD
		, TaxableIncome_EROnly_ForNETOnly = TaxableIncomeBeforeDeduction_EROnly_ForNETOnly, TotalIncome_ForSalaryTaxedAdj = round(isnull(ActualMonthlyBasic, 0) + isnull(TotalOTAmount, 0) + isnull(TotalNSAmt, 0) + ISNULL(TotalAllowanceForSalary, 0) + isnull(TaxableAdjustmentTotal_ForSalary, 0) - ISNULL(IOAmt, 0), @ROUND_NET)

	UPDATE #tblSalDetail_ForTax
	SET TotalEarn = isnull(ActualMonthlyBasic, 0) + isnull(TotalOTAmount, 0) + isnull(TotalNSAmt, 0) + ISNULL(TotalAllowanceForSalary, 0)

	UPDATE #tblSalDetail_ForTax
	SET TotalEarn = ISNULL(TotalEarn, 0) + t.AdjustmentAmount
	FROM #tblSalDetail_ForTax tx
	INNER JOIN (
		SELECT a.EmployeeID, SUM(a.AdjustmentAmount) AdjustmentAmount
		FROM #tblAdjustment a
		INNER JOIN tblIrregularIncome ir ON a.IncomeID = ir.IncomeID AND ir.IncomeKind = 1 AND ir.ForSalary = 1 AND (ISNULL(DoNotAddToTotalEarnIfNegative, 0) = 0 OR AdjustmentAmount > 0)
		GROUP BY A.EmployeeID
		) t ON tx.EmployeeID = t.EmployeeID

	-- select 7878787878 as asdasdsa,EmployeeID
	-- ,sum(case when i.incomeKind = 1 then 1 else 0 end * a.AdjustmentAmount) as TotalDeductFromTotalEarnCauseOfNegativeAmount
	--from #AdjustmentSum a
	--inner join tblIrregularIncome i on a.IncomeID = i.IncomeID  and i.DoNotAddToTotalEarnIfNegative =1
	--group by a.EmployeeID
	-------------------------------------Calculate tax----------------------------------------------
	IF (OBJECT_ID('SALCAL_TAX_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_TAX_INITIAL
(
	@StopUPDATE bit output,
	@Month int,	@Year int,

	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_TAX_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	--tinh thue 10% thi khong duoc mien thue tang ca
	SELECT EMployeeId
	INTO #empNeedToFixTaxAmount
	FROM #tblTemporaryContractTax c

	UPDATE #tblSalDetail_ForTax
	SET TaxableIncomeBeforeDeduction = TaxableIncomeBeforeDeduction - ISNULL(TaxableOTTotal, 0) + ISNULL(TotalOTAmount, 0) - ISNULL(TaxableAdjustmentTotal, 0) + ISNULL(TotalAdjustment_WithoutForce, 0) - ISNULL(TaxableAllowanceTotal, 0) + ISNULL(TotalAllowanceForSalary, 0), TotalIncome_Taxable_Without_INS_Persion_family = TotalIncome_Taxable_Without_INS_Persion_family - ISNULL(TaxableOTTotal, 0) + ISNULL(TotalOTAmount, 0) - ISNULL(TaxableAdjustmentTotal, 0) + ISNULL(TotalAdjustment_WithoutForce, 0) - ISNULL(TaxableAllowanceTotal, 0) + ISNULL(TotalAllowanceForSalary, 0)
	FROM #tblSalDetail_ForTax s
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #empNeedToFixTaxAmount
			)

	-- ở đây sẽ xử lý hết mấy thằng OT, Allowance, Adjustment
	UPDATE #tblSal_OT_des
	SET Raw_TaxableOTAmount = TaxableOTAmount, Raw_NoneTaxableOTAmount = NoneTaxableOTAmount

	UPDATE #tblSal_OT_des
	SET TaxableOTAmount = OTAmount, NoneTaxableOTAmount = 0
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #empNeedToFixTaxAmount
			)

	UPDATE #tblSal_Allowance_des
	SET Raw_TaxableAmount = TaxableAmount, Raw_UntaxableAmount = UntaxableAmount, Raw_RetroAmountNonTax = RetroAmountNonTax

	UPDATE #tblSal_Allowance_des
	SET TaxableAmount = Amount, UntaxableAmount = 0, RetroAmountNonTax = 0
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #empNeedToFixTaxAmount
			)

	UPDATE #tblSal_Allowance_Detail_des
	SET Raw_TaxableAmount = TaxableAmount, Raw_UntaxableAmount = UntaxableAmount, Raw_RetroAmountNonTax = RetroAmountNonTax

	UPDATE #tblSal_Allowance_Detail_des
	SET TaxableAmount = Amount, UntaxableAmount = 0, RetroAmountNonTax = 0
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #empNeedToFixTaxAmount
			)

	UPDATE #tblSal_Adjustment_des
	SET Raw_TaxableAmount = TaxableAmount, Raw_UntaxableAmount = UntaxableAmount

	UPDATE #tblSal_Adjustment_des
	SET TaxableAmount = Amount, UntaxableAmount = 0
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #empNeedToFixTaxAmount
			) AND IncomeID NOT IN (
			SELECT IncomeID
			FROM tblIrregularIncome
			WHERE ForceNonTax = 1
			) AND IncomeID IN (
			SELECT IncomeID
			FROM tblIrregularIncome
			WHERE IncomeKind = 1
			)

	DROP TABLE #empNeedToFixTaxAmount

	IF (OBJECT_ID('SALCAL_TAX_10_INITIAL') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_TAX_10_INITIAL
(
	@StopUPDATE bit output,

	@Month int,	@Year int,

	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	-- custom
	EXEC SALCAL_TAX_10_INITIAL @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	-- TAX_DEDUCTION: Khấu trừ thuế khi tính lương? 0: không trừ, 1: có trừ tiền thuế
	-- không tính thuế từ phần mềm, có thể import từ bên ngoài vào
	DECLARE @TAX_DEDUCTION BIT

	SET @TAX_DEDUCTION = ISNULL((
				SELECT Value
				FROM tblParameter
				WHERE Code = 'TAX_DEDUCTION'
				), 1) --mot vai cong ty khong tinh thue ma import tu file - nếu từ file thì phải set = 0

	IF @TAX_DEDUCTION = 1
	BEGIN
		CREATE TABLE #TableVarTax (
			EmployeeID VARCHAR(20), TaxableIncome FLOAT(53), TaxableIncome_EROnly_ForNETOnly FLOAT(53), TaxableIncomeFrom FLOAT(53), TaxableIncomeFrom_EROnly_ForNETOnly FLOAT(53), TaxableIncomeTo FLOAT(53), TaxableIncomeTo_EROnly_ForNETOnly FLOAT(53), TaxPercent FLOAT, TaxPercent_EROnly_ForNETOnly FLOAT, ProgressiveAmount FLOAT(53), ProgressiveAmount_EROnly_ForNETOnly FLOAT(53), PITAmt FLOAT(53), PITAmt_ER FLOAT(53), SalaryHistoryID BIGINT, FixedPercent BIT, IncomeTaxableEmployeeOld FLOAT(53), TaxRetroImported FLOAT(53), TaxableIncome_SalaryOnly FLOAT(53), PITAmt_SalaryOnly FLOAT(53) --TRIPOD Foreigner
			)

		SELECT te.EmployeeID, te.TaxRegNo
		INTO #tmpEmpTaxNo
		FROM tblEmployee te
		INNER JOIN #tblEmployeeIDList a ON te.EmployeeID = a.EmployeeID

		-- Family deduction
		SELECT EmployeeID, cast(0.0 AS FLOAT(53)) AS DeductionAmount, cast(@PesonalDeduct AS FLOAT(53)) PesonalDeduct, CAST(0 AS FLOAT(53)) FamilyDeduction
		INTO #Deduction
		FROM #tblEmployeeIDList

		UPDATE #Deduction
		SET DeductionAmount = ISNULL(PesonalDeduct, @PesonalDeduct)

		UPDATE #Deduction
		SET DeductionAmount = DeductionAmount + @RelationDeduct * isnull(CountDeduct, 0), FamilyDeduction = @RelationDeduct * isnull(CountDeduct, 0)
		FROM #Deduction a
		INNER JOIN #CountRelation b ON a.EmployeeID = b.EmployeeID

		UPDATE #CountRelation
		SET CountDeduct = 0
		WHERE EmployeeID IN (
				SELECT EmployeeID
				FROM #tblTemporaryContractTax
				)

		UPDATE #Deduction
		SET DeductionAmount = 0, FamilyDeduction = 0, PesonalDeduct = 0
		WHERE EmployeeID IN (
				SELECT EmployeeID
				FROM #tblTemporaryContractTax
				)

		--TRIPOD
		UPDATE #tblSalDetail_ForTax
		SET TaxableIncome = TotalIncome - ROUND(ISNULL(NoneTaxableOTTotal, 0), 0) - ISNULL(DeductionAmount, 0) - ISNULL(InsAmt, 0) - ISNULL(EmpUnion, 0), TaxableIncome_SalaryOnly = RegularAmt - ISNULL(DeductionAmount, 0) - ISNULL(InsAmt, 0) - ISNULL(EmpUnion, 0), TaxableIncome_EROnly_ForNETOnly = TaxableIncome_EROnly_ForNETOnly - (ISNULL(DeductionAmount, 0))
		FROM #tblSalDetail_ForTax a
		INNER JOIN #Deduction b ON a.EmployeeID = b.EmployeeID
		WHERE isNet = 0

		UPDATE #tblSalDetail_ForTax
		SET TaxableIncome = TotalIncome - ROUND(ISNULL(NoneTaxableOTTotal, 0), 0) - ISNULL(DeductionAmount, 0) - ISNULL(InsAmt, 0) - ISNULL(EmpUnion, 0), TaxableIncome_SalaryOnly = RegularAmt - ISNULL(DeductionAmount, 0) - ISNULL(InsAmt, 0) - ISNULL(EmpUnion, 0), TaxableIncome_EROnly_ForNETOnly = TaxableIncome_EROnly_ForNETOnly - (ISNULL(DeductionAmount, 0))
		FROM #tblSalDetail_ForTax a
		INNER JOIN #Deduction b ON a.EmployeeID = b.EmployeeID
		WHERE isNet = 1

		--SELECT * FROM #tblSalDetail where EmployeeID = '62250010' return
		--nhung nguoi hd duoi 3 thang ko duoc huong tang ca mien thue, neu luong < 9tr va co tich lowincome va co ma so thue thi duoc giam tru OTnontax
		INSERT INTO #TableVarTax (EmployeeID, TaxableIncome, TaxableIncome_EROnly_ForNETOnly)
		SELECT EmployeeID, TaxableIncome, TaxableIncome_EROnly_ForNETOnly
		FROM #tblSalDetail_ForTax

		UPDATE #TableVarTax
		SET TaxableIncomeFrom = tx.IncomeFrom, TaxableIncomeTo = tx.IncomeTo, TaxPercent = tx.TaxPercent, ProgressiveAmount = tx.ProgressiveAmount
		FROM #TableVarTax txv, (
				SELECT *
				FROM tblTax tt
				WHERE tt.EffectDate = (
						SELECT MAX(EffectDate)
						FROM tblTax
						WHERE datediff(day, tt.EffectDate, @FromDate) >= 0
						)
				) tx
		WHERE txv.TaxableIncome BETWEEN tx.IncomeFrom AND tx.IncomeTo

		--TRIPOD Foreigner
		UPDATE t
		SET TaxableIncome_SalaryOnly = sal.TaxableIncome_SalaryOnly
		FROM #TableVarTax t
		INNER JOIN #tblSalDetail_ForTax sal ON t.EmployeeID = sal.EmployeeID
		WHERE sal.isNET = 1

		UPDATE #TableVarTax
		SET TaxableIncomeFrom_EROnly_ForNETOnly = tx.IncomeFrom, TaxableIncomeTo_EROnly_ForNETOnly = tx.IncomeTo, TaxPercent_EROnly_ForNETOnly = tx.TaxPercent, ProgressiveAmount_EROnly_ForNETOnly = tx.ProgressiveAmount
		FROM #TableVarTax txv, (
				SELECT *
				FROM tblTax tt
				WHERE tt.EffectDate = (
						SELECT MAX(EffectDate)
						FROM tblTax
						WHERE datediff(day, tt.EffectDate, @FromDate) >= 0
						)
				) tx
		WHERE txv.TaxableIncome_EROnly_ForNETOnly BETWEEN tx.IncomeFrom AND tx.IncomeTo

		UPDATE #TableVarTax
		SET TaxableIncomeFrom = ISNULL(TaxableIncomeFrom, 0), TaxableIncomeTo = ISNULL(TaxableIncomeTo, 0), TaxPercent = ISNULL(TaxPercent, 0), ProgressiveAmount = ISNULL(ProgressiveAmount, 0), TaxableIncomeFrom_EROnly_ForNETOnly = ISNULL(TaxableIncomeFrom_EROnly_ForNETOnly, 0), TaxableIncomeTo_EROnly_ForNETOnly = ISNULL(TaxableIncomeTo_EROnly_ForNETOnly, 0), TaxPercent_EROnly_ForNETOnly = ISNULL(TaxPercent_EROnly_ForNETOnly, 0), ProgressiveAmount_EROnly_ForNETOnly = ISNULL(ProgressiveAmount_EROnly_ForNETOnly, 0)

		UPDATE #TableVarTax
		SET PITAmt = (TaxableIncome - (TaxableIncomeFrom - 1)) * TaxPercent + ProgressiveAmount, PITAmt_SalaryOnly = (TaxableIncome_SalaryOnly - (TaxableIncomeFrom - 1)) * TaxPercent + ProgressiveAmount, PITAmt_ER = (TaxableIncome_EROnly_ForNETOnly - (TaxableIncomeFrom_EROnly_ForNETOnly - 1)) * TaxPercent_EROnly_ForNETOnly + ProgressiveAmount_EROnly_ForNETOnly
		FROM #TableVarTax a
		WHERE EmployeeID NOT IN (
				SELECT EmployeeID
				FROM #tblTemporaryContractTax
				)

		-- thuế cho người chưa có hợp đồng chính thức, mac dinh 10%
		UPDATE #TableVarTax
		SET TaxableIncome = CASE
				WHEN ISNULL(sal.TaxableIncomeBeforeDeduction, 0) < 0 AND e.DivisionID IS NULL
					THEN 0
				ELSE ISNULL(sal.TaxableIncomeBeforeDeduction, 0)
				END, PITAmt = CASE
				WHEN ISNULL(sal.TaxableIncomeBeforeDeduction, 0) < 2000000
					THEN 0
				ELSE ISNULL(sal.TaxableIncomeBeforeDeduction, 0) * tmp.TaxPercentage
				END, FixedPercent = 1
		FROM #TableVarTax a
		INNER JOIN #tblTemporaryContractTax tmp ON a.EmployeeID = tmp.EmployeeID
		LEFT JOIN #tblEmployeeIDList e ON a.EmployeeID = e.EmployeeId
		--and e.DivisionID in(select DivisionID from tblDivision where DoNotFixTaxableIncome = 1)
		INNER JOIN #tblSalDetail_ForTax sal ON a.EmployeeID = sal.EmployeeID

		UPDATE #TableVarTax
		SET PITAmt = 0, TaxableIncome = 0, FixedPercent = 0
		WHERE PITAmt <= 0.05

		--co ma so thue + cam ket thu nhap thap + < 9tr: khong tinh thue nhung duoc tru tang ca mien thue, dong phuc mien thue, tien an mien thue
		UPDATE #TableVarTax
		SET PITAmt = CASE
				WHEN LTRIM(RTRIM(ISNULL(te.TaxRegNo, ''))) <> '' AND tmp.IsLowSalary = 1 AND sal.TotalSalary <= @PesonalDeduct
					THEN 0
				ELSE t.PITAmt
				END, TaxableIncome = CASE
				WHEN LTRIM(RTRIM(ISNULL(te.TaxRegNo, ''))) <> '' AND tmp.IsLowSalary = 1 AND sal.TotalSalary <= @PesonalDeduct
					THEN 0
				ELSE t.TaxableIncome
				END
		FROM #TableVarTax t
		INNER JOIN #tblTemporaryContractTax tmp ON t.EmployeeID = tmp.EmployeeID
		INNER JOIN #tblSalDetail_ForTax sal ON t.EmployeeID = sal.EmployeeID
		INNER JOIN #tmpEmpTaxNo te ON t.EmployeeID = te.EmployeeID

		UPDATE #TableVarTax
		SET SalaryHistoryID = b.SalaryHistoryID
		FROM #TableVarTax a, (
				SELECT MAX(SalaryHistoryID) SalaryHistoryID, EmployeeID
				FROM #tblSalDetail_ForTax
				GROUP BY EmployeeID
				) b
		WHERE a.EmployeeID = b.EmployeeID

		UPDATE #TableVarTax
		SET TaxableIncome = 0, TaxableIncome_SalaryOnly = 0
		WHERE TaxableIncome < 0 OR TaxableIncome IS NULL

		UPDATE #TableVarTax
		SET TaxableIncome_EROnly_ForNETOnly = 0
		WHERE TaxableIncome_EROnly_ForNETOnly < 0 OR TaxableIncome_EROnly_ForNETOnly IS NULL

		UPDATE #TableVarTax
		SET TaxableIncome = ROUND(TaxableIncome, @ROUND_SALARY_UNIT), PITAmt = ROUND(PITAmt, @ROUND_SALARY_UNIT)

		--UPDATE #Sal_OT1_0 SET OTDeduction = OTDeduction
		UPDATE #TableVarTax
		SET FixedPercent = 0
		WHERE PITAmt <= 0.05

		UPDATE #TableVarTax
		SET TaxRetroImported = pit.totalPITRetro, PITAmt = round(ISNULL(PITAmt, 0) + ISNULL(pit.totalPITRetro, 0), 0)
		FROM #TableVarTax tax
		INNER JOIN (
			SELECT EmployeeID, SUM(Amount) AS totalPITRetro
			FROM tblPR_Adjustment p
			WHERE p.EmployeeID IN (
					SELECT EmployeeID
					FROM #tblEmployeeIDList
					) AND p.Month = @Month AND p.Year = @Year AND p.IncomeID IN (
					SELECT IncomeID
					FROM tblIrregularIncome
					WHERE AppendToPIT = 1
					)
			GROUP BY p.EmployeeID
			) pit ON tax.EmployeeID = pit.EmployeeID

		UPDATE #TableVarTax
		SET TaxRetroImported = isnull(TaxRetroImported, 0) + isnull(re.PIT_Retro_Amount, 0), PITAmt = round(ISNULL(PITAmt, 0) + ISNULL(re.PIT_Retro_Amount, 0), 0)
		FROM #TableVarTax tax
		INNER JOIN tblSal_Retro_Imported re ON tax.EmployeeID = re.EmployeeID AND re.Month = @month AND re.YEar = @year AND re.PIT_Retro_Amount <> 0

		UPDATE #TableVarTax
		SET PITAmt = ROUND(PITAmt, 0), PITAmt_ER = ROUND(PITAmt_ER, 0), PITAmt_SalaryOnly = ROUND(PITAmt_SalaryOnly, 0)

		-- calculate PIT retro by cal back dependants
		EXEC sp_ProcessDependentAdjustment @LoginID, @Month, @Year, @NotSelect = 1

		UPDATE #TableVarTax
		SET PITAmt = CASE
				WHEN Round(ISNULL(PITAmt, 0) + a.PITAdjustment, @ROUND_SALARY_UNIT) < 0
					THEN 0
				ELSE Round(ISNULL(PITAmt, 0) + a.PITAdjustment, @ROUND_SALARY_UNIT)
				END
		FROM #TableVarTax p
		INNER JOIN (
			SELECT EmployeeId, sum(PITAdjustment) AS PITAdjustment
			FROM tblPIT_Adjustment_For_ChangedDependants
			WHERE ToMonth = @month AND ToYear = @year
			GROUP BY EmployeeID
			) a ON p.EmployeeID = a.EmployeeID

		-- end calculate PIT retro by cal back dependants
		IF (OBJECT_ID('SALCAL_TAX_FINISHED') IS NULL)
		BEGIN
			EXEC (
					'CREATE PROCEDURE dbo.SALCAL_TAX_FINISHED
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20) = ''-1''
)
as
begin
	SET NOCOUNT ON;
end'
					)
		END

		SET @StopUPDATE = 0

		EXEC SALCAL_TAX_FINISHED @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

		--alter table tblSal_tax add FixedPercents float
		INSERT INTO #tblSal_tax_des (EmployeeID, Month, year, IncomeTaxable, DeductionAmt, EmployeeExemption, FamilyExemption, DependantNumber, OTDeduction, TaxAmt, IsNET, TaxableIncome_EROnly_ForNETOnly, PITAmt_ER, TaxRetroImported, FixedPercents, isLowSalary, PeriodID, TaxableIncome_SalaryOnly, TaxAmt_SalaryOnly) --TRIPOD Foreigner
		SELECT tx.EmployeeID, @Month, @Year, tx.TaxableIncome, d.DeductionAmount, d.PesonalDeduct, isnull(dp.CountDeduct, 0) * isnull(@RelationDeduct, 0), dp.CountDeduct, sal.NoneTaxableOTTotal, tx.PITAmt, sh.IsNET, tx.TaxableIncome_EROnly_ForNETOnly, tx.PITAmt_ER, TaxRetroImported, tc.TaxPercentage AS FixedPercents, tc.isLowSalary, @PeriodID, tx.TaxableIncome_SalaryOnly, tx.PITAmt_SalaryOnly
		FROM #TableVarTax tx
		INNER JOIN #tblSalDetail_ForTax sal ON tx.SalaryHistoryID = sal.SalaryHistoryID AND sal.LatestSalEntry = 1
		LEFT JOIN tblSalaryHistory sh ON tx.SalaryHistoryID = sh.SalaryHistoryID
		LEFT JOIN #Deduction d ON tx.EmployeeID = d.EmployeeID
		LEFT JOIN #CountRelation dp ON tx.EmployeeID = dp.EmployeeID
		LEFT JOIN #tblTemporaryContractTax tc ON tx.EmployeeID = tc.EmployeeID

		UPDATE #tblSalDetail_ForTax
		SET PITAmt = tx.PITAmt, PITAmt_ER = tx.PITAmt_ER
		FROM #tblSalDetail_ForTax sal
		INNER JOIN #TableVarTax tx ON sal.EmployeeID = tx.EmployeeID AND sal.LatestSalEntry = 1
	END
	ELSE
	BEGIN
		DELETE #tblSal_tax_des
		WHERE month = @Month AND Year = @Year AND EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		SELECT t.EmployeeID, t.IncomeTaxable, t.TaxAmt
		INTO #tblSal_TaxImport
		FROM tblSal_TaxImport t
		WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		INSERT INTO #tblSal_tax_des (EmployeeID, Month, Year, IncomeTaxable, TaxAmt)
		SELECT t.EmployeeID, @Month, @Year, t.IncomeTaxable, t.TaxAmt
		FROM #tblSal_TaxImport t

		UPDATE #tblSalDetail_ForTax
		SET PITAmt = tx.TaxAmt
		FROM #tblSalDetail_ForTax sal
		INNER JOIN #tblSal_TaxImport tx ON sal.EmployeeID = tx.EmployeeID AND sal.LatestSalEntry = 1
	END

	--------------------------UPDATE other sumaried items of Sumary Table--------------------------
	UPDATE #tblSalDetail_ForTax
	SET IncomeAfterPIT = TotalIncome - ISNULL(InsAmt, 0) - ISNULL(PITAmt, 0) - (ISNULL(EmpUnion, 0) + ISNULL(EmpUnion_RETRO, 0))
	WHERE isnull(IsNet, 0) = 0

	UPDATE #tblSalDetail_ForTax
	SET IncomeAfterPIT = TotalIncome - (ISNULL(PITAmt, 0) - isnull(PITAmt_ER, 0))
	WHERE isnull(IsNet, 0) = 1

	--UPDATE #tblSalDetail_ForTax set PITReturn = ISNULL(TaxableAdjustmentTotal,0) + ISNULL(NoneTaxableAdjustmentTotal,0) - ISNULL(TotalAdjustmentForSalary,0)
	--deduct advance and union
	UPDATE sal
	SET AdvanceAmt = av.AdvanceAmount
	FROM tblSal_Advance av
	INNER JOIN #tblSalDetail_ForTax sal ON av.EmployeeID = sal.EmployeeID AND sal.LatestSalEntry = 1
	WHERE av.Month = @Month AND av.Year = @Year AND av.IsLock = 1

	UPDATE #tblSalDetail_ForTax
	SET GrossTakeHome = ROUND(IncomeAfterPIT - ISNULL(OtherDeductionAfterPIT, 0) - ISNULL(PITReturn, 0) - ISNULL(AdvanceAmt, 0), @ROUND_SALARY_UNIT)
	WHERE IncomeAfterPIT <> 0

	--select GrossTakeHome,@ROUND_SALARY_UNIT from #tblSalDetail_ForTax
	-- total cost thì phải trừ các khoản không dc tính trong total Cót Com Paid
	-- use IsNotLabourCost column
	UPDATE sal
	SET sal.TotalCostComPaid = sal.TotalCostComPaid - isnull(al.Total_Allowance_NotInLabourCost, 0)
	FROM #tblSalDetail_ForTax sal
	INNER JOIN (
		SELECT employeeID, sum(ReceiveAmount) AS Total_Allowance_NotInLabourCost
		FROM #tblAllowance a
		INNER JOIN tblAllowanceSetting al ON a.AllowanceID = al.AllowanceID AND al.IsNotLabourCost = 1
		GROUP BY EmployeeID
		) al ON sal.EmployeeID = al.EmployeeID
	WHERE sal.LatestSalEntry = 1

	-----------------------UPDATE salary detail records-----------------------------
	--dong luong cu ko can update
	UPDATE #tblSalDetail
	SET TaxableIncomeBeforeDeduction = 0, TotalIncome_Taxable_Without_INS_Persion_family = 0
	WHERE LatestSalEntry = 0

	--already delete old data
	UPDATE #tblSalDetail
	SET GrossTakeHome = sal2.GrossTakeHome, TotalCostComPaid = sal2.TotalCostComPaid + CASE
			WHEN isnull(sal2.IsNet, 0) = 1
				THEN isnull(sal2.PITAmt_ER, 0)
			ELSE 0
			END -- nếu là net thì phải trả thêm nha
		, TotalPayrollFund = sal2.TotalPayrollFund + CASE
			WHEN isnull(sal2.IsNet, 0) = 1
				THEN isnull(sal2.PITAmt_ER, 0)
			ELSE 0
			END -- nếu là net thì phải trả thêm nha
		, TaxableIncomeBeforeDeduction = sal2.TaxableIncomeBeforeDeduction, TaxableIncomeBeforeDeduction_EROnly_ForNETOnly = sal2.TaxableIncomeBeforeDeduction_EROnly_ForNETOnly, TotalIncome = sal2.TotalIncome, TotalEarn = sal2.TotalEarn, TaxableIncome = sal2.TaxableIncome, TaxableIncome_EROnly_ForNETOnly = sal2.TaxableIncome_EROnly_ForNETOnly, PITAmt = sal2.PITAmt, PITAmt_ER = sal2.PITAmt_ER, IncomeAfterPIT = sal2.IncomeAfterPIT, PITReturn = sal2.PITReturn, AdvanceAmt = sal2.AdvanceAmt, TotalIncome_ForSalaryTaxedAdj = sal2.TotalIncome_ForSalaryTaxedAdj, TotalIncome_Taxable_Without_INS_Persion_family = sal2.TotalIncome_Taxable_Without_INS_Persion_family
	FROM #tblSalDetail sal1
	INNER JOIN #tblSalDetail_ForTax sal2 ON sal1.EmployeeID = sal2.EmployeeID AND sal1.LatestSalEntry = 1

	DROP TABLE #tblSalDetail_ForTax

	UPDATE #tblSalDetail
	SET GrossTakeHome = ROUND(GrossTakeHome, @ROUND_TAKE), TotalEarn = ROUND(TotalEarn, @ROUND_NET), TotalIncome = ROUND(TotalIncome, @ROUND_NET)

	IF @PROBATION_PERECNT > 0 AND @PROBATION_PERECNT < 100.0 --xu ly mot vai nguoi co probation tu dong
		UPDATE #tblSalDetail
		SET BasicSalaryOrg = BasicSalary
		WHERE LatestSalEntry = 0 AND BasicSalaryOrg IS NOT NULL

	--xoa mot so du lieu thua o lan tinh luong truoc
	DELETE
	FROM #tblSalDetail
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			WHERE TerminatedStaff = 1 AND TerminateDate <= @FromDate
			) AND GrossTakeHome = 0 AND ISNULL(TotalIncome, 0) = 0 AND ISNULL(PITAmt, 0) = 0 AND ISNULL(TotalCostComPaid, 0) = 0

	--luu du lieu truoc khi delete	
	SELECT EmployeeID, IsCash, RemainAL, Notes
	INTO #tmpSalSal_Backup
	FROM tblSal_Sal
	WHERE [Month] = @Month AND [Year] = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			)

	UPDATE #tblSalDetail
	SET ActualMonthlyBasic = ISNULL(ActualMonthlyBasic, 0) - isnull(sr.ActualMonthlyBasic_Retro_Amount, 0)
	FROM #tblSalDetail sal
	INNER JOIN #tblsal_retro_Final sr ON sal.EmployeeID = sr.EmployeeID --and sr.Month= @Month and sr.Year= @Year
	WHERE sal.LatestSalEntry = 1

	INSERT INTO #tblSal_Sal_Detail_des (EmployeeID, Month, Year, PeriodID, SalaryHistoryID, FromDate, ToDate, DepartmentID, SectionID, PositionID, StandardWDays, BasicSalary, SalaryPerDay, ActualMonthlyBasic, TaxableAllowance, NontaxableAllowance, TaxableAdjustment, NontaxableAdj, TaxableAdjustmentTotal_ForSalary, TaxableAdjustmentTotal_NotForSalary, TotalIncome, TotalEarn, IOAmt, EmpUnion, CompUnion, TaxableIncomeBeforeDeduction, IncomeAfterPIT, GrossTakeHome, SalaryPerHour, SalCalRuleID, LatestSalEntry, DaysOfSalEntry, Raw_BasicSalary, Raw_CurrencyCode, Raw_ExchangeRate, IsNet, UnpaidLeaveAmount, TotalNetIncome_Custom, GrossedUpWithoutHousing_Custom, GrossedUpWithoutHousing_WithoutGrossIncome_Custom, RegularAmt, PaidLeaveAmt, GrossSalary, AnnualBonus_Total, AnnualBonus_EvMonth, Bonus6Month_Total, Bonus6M_EveryMonth) --TRIPOD
	SELECT sal.EmployeeID, @Month, @Year, @PeriodID, ISNULL(sal.ProbationSalaryHistoryID, sal.SalaryHistoryID), sal.FromDate, sal.ToDate, e.DepartmentID, e.SectionID, e.PositionID, sal.STD_WD, sal.BasicSalary, sal.SalaryPerDay, sal.ActualMonthlyBasic, sal.TaxableAllowanceTotal, sal.NoneTaxableAllowanceTotal, sal.TaxableAdjustmentTotal, sal.NoneTaxableAdjustmentTotal, TaxableAdjustmentTotal_ForSalary, TaxableAdjustmentTotal_NotForSalary, sal.TotalIncome, TotalEarn, sal.IOAmt, sal.EmpUnion, sal.CompUnion, sal.TaxableIncomeBeforeDeduction, sal.IncomeAfterPIT, sal.GrossTakeHome, sal.SalaryPerHour, sal.SalCalRuleID, LatestSalEntry, DaysOfSalEntry, CASE
			WHEN ISNULL(sal.isNET, 0) = 1
				THEN sal.NetSalary
			ELSE sh.Salary
			END AS Raw_BasicSalary, sal.CurrencyCode AS Raw_CurrencyCode, sal.ExchangeRate AS Raw_ExchangeRate, sal.IsNet, UnpaidLeaveAmount, TotalNetIncome_Custom, GrossedUpWithoutHousing_Custom, round(GrossedUpWithoutHousing_WithoutGrossIncome_Custom, 0), sal.RegularAmt, sal.PaidLeaveAmt, sal.GrossSalary, AnnualBonus_Total, AnnualBonus_EvMonth, Bonus6Month_Total, Bonus6M_EveryMonth
	FROM #tblSalDetail sal
	INNER JOIN #tblEmployeeIDList e ON sal.EmployeeID = e.EmployeeID
	INNER JOIN tblSalaryHistory sh ON sal.SalaryHistoryID = sh.SalaryHistoryID

	--select 9999,TotalNetIncome_Custom,GrossedUpWithoutHousing_Custom,* from #tblSalDetail
	IF (OBJECT_ID('SALCAL_FinishUpdateSalDetail') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.SALCAL_FinishUpdateSalDetail
(
	@StopUPDATE bit output,
	@Month int,
	@Year int,
	@FromDate datetime,
	@ToDate datetime,
	@LoginID int,
	@PeriodID int = 0,
	@EmployeeID nvarchar(20)
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUPDATE = 0

	EXEC SALCAL_FinishUpdateSalDetail @StopUPDATE OUTPUT, @Month, @Year, @FromDate, @ToDate, @LoginID, @PeriodID, @EmployeeID

	----------------------------UPDATE Salary sumary record-----------------------------
	--already delete old data
	INSERT INTO #tblSal_Sal_des (EmployeeID, Month, Year, PeriodID, ActualMonthlyBasic, TaxableAllowance, NontaxableAllowance, TaxableAdjustment, NontaxableAdj, TaxableAdjustmentTotal_ForSalary, TaxableAdjustmentTotal_NotForSalary, TotalIncome, TotalEarn, IOAmt, EmpUnion, CompUnion, EmpUnion_RETRO, CompUnion_RETRO, TaxableIncomeBeforeDeduction, IncomeAfterPIT, GrossTakeHome, TotalCostComPaid, TotalPayrollFund, TotalIncome_ForSalaryTaxedAdj, TotalIncome_Taxable_Without_INS_Persion_family, UnpaidLeaveAmount, TotalNetIncome_Custom, GrossedUpWithoutHousing_Custom, GrossedUpWithoutHousing_WithoutGrossIncome_Custom)
	SELECT EmployeeID, @Month, @Year, @PeriodID, SUM(ActualMonthlyBasic), SUM(TaxableAllowanceTotal), SUM(NoneTaxableAllowanceTotal), SUM(TaxableAdjustmentTotal), SUM(NoneTaxableAdjustmentTotal), SUM(TaxableAdjustmentTotal_ForSalary), SUM(TaxableAdjustmentTotal_NotForSalary), SUM(TotalIncome), SUM(TotalEarn), SUM(IOAmt), SUM(EmpUnion), SUM(CompUnion), SUM(EmpUnion_RETRO), SUM(CompUnion_RETRO), SUM(TaxableIncomeBeforeDeduction), SUM(IncomeAfterPIT), SUM(GrossTakeHome), Round(SUM(TotalCostComPaid), @ROUND_SALARY_UNIT), Round(SUM(TotalPayrollFund), @ROUND_SALARY_UNIT), SUM(TotalIncome_ForSalaryTaxedAdj), SUM(TotalIncome_Taxable_Without_INS_Persion_family), SUM(UnpaidLeaveAmount), SUM(TotalNetIncome_Custom), SUM(GrossedUpWithoutHousing_Custom), sum(GrossedUpWithoutHousing_WithoutGrossIncome_Custom)
	FROM #tblSalDetail
	GROUP BY EmployeeID

	UPDATE #tblSal_Sal_des
	SET IsCash = b.IsCash, Notes = b.Notes
	FROM #tblSal_Sal_des sal
	INNER JOIN #tmpSalSal_Backup b ON sal.EmployeeID = b.EmployeeID AND sal.Month = @Month AND Year = @Year

	/*
TakeHome_Actual_VND

TakeHome_RequestedAmount
TakeHome_Requested_Currency
Takehome_Requested_ExchangeRate
*/
	-- kiểm tra coi có ai cần dc trả ngoại tệ không
	SELECT EmployeeID, CurrencyCode, RequestAmount, AlsoViewVNDAmount, TransferAll
	INTO #PaidInAnotherCurrency
	FROM tblSal_RequestPaidInAnotherCurrency
	WHERE @month + @year * 12 >= FromMonth + FromYear * 12 AND (ToMonth IS NULL OR @month + @year * 12 <= ToMonth + ToYear * 12) AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblEmployeeIDList
			)

	--select sal.EmployeeID,sal.GrossTakeHome,p.RequestAmount,p.CurrencyCode,ex.ExchangeRate
	UPDATE sal
	SET TakeHome_RequestedAmount = p.RequestAmount, TakeHome_Requested_Currency = p.CurrencyCode, Takehome_Requested_ExchangeRate = ex.ExchangeRate, TakeHome_Actual_VND = ROUND(CASE
				WHEN sal.GrossTakeHome - (p.RequestAmount * ex.ExchangeRate) > 0
					THEN sal.GrossTakeHome - (p.RequestAmount * ex.ExchangeRate)
				ELSE 0
				END, 0)
	FROM #tblSal_Sal_des sal
	INNER JOIN #PaidInAnotherCurrency p ON sal.EmployeeID = p.EmployeeID
	INNER JOIN #EmployeeExchangeRate ex ON p.EmployeeID = ex.EmployeeID AND p.CurrencyCode = ex.CurrencyCode

	-- cập nhật Key của table
	SET ANSI_WARNINGS ON

	SELECT KU.table_name AS TABLENAME, column_name AS PRIMARYKEYCOLUMN
	INTO #tmpPRIMARYKEYCOLUMN
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU ON TC.CONSTRAINT_TYPE = 'PRIMARY KEY' AND TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME AND KU.table_name IN (
			SELECT PhysicTableName
			FROM #NameOfPhysicTables
			)

	UPDATE t
	SET PrimaryKeyCOlumns = tmp.PrimaryKeyCOlumns
	FROM #NameOfPhysicTables t
	INNER JOIN (
		SELECT TABLENAME, STUFF((
					SELECT ',' + CAST(tmp.PRIMARYKEYCOLUMN AS VARCHAR(MAX))
					FROM #tmpPRIMARYKEYCOLUMN tmp
					WHERE (tmp.TABLENAME = Results.TABLENAME)
					FOR XML PATH(''), TYPE
					).value('.', 'VARCHAR(MAX)'), 1, 1, '') AS PrimaryKeyCOlumns
		FROM #tmpPRIMARYKEYCOLUMN Results
		GROUP BY TABLENAME
		) tmp ON t.PhysicTableName = tmp.TABLENAME

	SET ANSI_WARNINGS OFF

	DECLARE @tempTableName NVARCHAR(500), @PhysicTableName NVARCHAR(500)

	IF @CalculateRetro = 0 -- nếu @CalculateRetro= 0 thì chẳng có trong bảng tạm cũng như bảng danh sách nhân viên đâu, nhưng mà cứ chạy cái cho nó chắc
	BEGIN
		-- delêt bảng danh sách nhân viên
		--(EmployeeID IN (SELECT EmployeeID FROM #tblEmployeeIDList))
		DELETE #tblEmployeeIDList
		FROM #tblEmployeeIDList e
		WHERE EXISTS (
				SELECT 1
				FROM tblSal_Lock sl
				WHERE e.EmployeeID = sl.EmployeeID AND sl.Month = @Month AND sl.Year = @Year
				)

		-- tạo cái base query
		-- chắc ăn hơn nữa thì xóa 1 lần trong các bảng tạm đi nào a e
		SET @Query = N'delete %temptableName% from %temptableName% tmp where tmp.EmployeeId not in(select EmployeeID from #tblEmployeeIDList)
		-- delete bảng thực cho nó gọn
		delete %PhysicTableName% from %PhysicTableName% phy where phy.Month= ' + CAST(@Month AS VARCHAR(2)) + ' and phy.Year= ' + CAST(@year AS VARCHAR(4)) + ' and isnull(phy.PeriodID,0) = ' + cast(@PeriodID AS VARCHAR(20)) + '
		and exists (select 1 from #tblEmployeeIDList tel where phy.EmployeeID = tel.EmployeeID)
		'

		DECLARE @UpdateQuery NVARCHAR(max) = ''

		IF EXISTS (
				SELECT 1
				FROM #NameOfPhysicTables
				WHERE len(ISNULL(PrimaryKeyCOlumns, '')) <= 1
				)
		BEGIN
			SELECT N'Những bảng không có key cần xem lại', *
			FROM #NameOfPhysicTables
			WHERE len(ISNULL(PrimaryKeyCOlumns, '')) <= 1 -- không có key kô cho lưu

			DELETE #NameOfPhysicTables
			WHERE len(ISNULL(PrimaryKeyCOlumns, '')) <= 1 -- không có key kô cho lưu
		END

		WHILE EXISTS (
				SELECT 1
				FROM #NameOfPhysicTables
				)
		BEGIN
			SELECT TOP 1 @tempTableName = TempTablename, @PhysicTableName = PhysicTableName
			FROM #NameOfPhysicTables

			--print @tempTableName + '-'+@PhysicTableName
			SET @UpdateQuery = REPLACE(REPLACE(@Query, '%PhysicTableName%', @PhysicTableName), '%temptableName%', @tempTableName)

			--print @UpdateQuery
			EXECUTE (@UpdateQuery)

			EXEC sp_InsertUpdateFromTempTableTOTable @TempTableName = @tempTableName, @TableName = @PhysicTableName

			DELETE #NameOfPhysicTables
			WHERE @tempTableName = TempTablename AND @PhysicTableName = PhysicTableName
		END

		IF @CalculateRetro = 0
			UPDATE sal1
			SET Attdays = sal1.Attdays - ISNULL(sal2.Attdays, 0), TotalPaidDays = sal1.TotalPaidDays - ISNULL(sal2.TotalPaidDays, 0), PaidLeaves = sal1.PaidLeaves - ISNULL(sal2.PaidLeaves, 0), UnPaidLeaves = sal1.UnPaidLeaves - ISNULL(sal2.UnPaidLeaves, 0), TotalSunDay = sal1.TotalSunDay - ISNULL(sal2.TotalSunDay, 0)
			FROM tblSal_AttDataSumary_ForReport sal1
			INNER JOIN tblSal_AttDataSumary_ForReport sal2 ON sal1.EmployeeID = sal2.EmployeeID AND sal2.Month = @Month AND sal2.Year = @Year AND sal2.PeriodID = 1
			WHERE sal1.EmployeeID IN (
					SELECT EmployeeID
					FROM #tblEmployeeIDList
					) AND sal1.Month = @Month AND sal1.Year = @Year AND sal1.PeriodID = 0
	END
	ELSE IF @CalculateRetro = 1
	BEGIN
		SELECT sal1.EmployeeID, sal1.DaysOfSalEntry - ISNULL(sal2.DaysOfSalEntry, 0) AS BalanceDays
		INTO #DiffDaysofSalEntry
		FROM (
			SELECT EmployeeID, SUM(DaysOfSalEntry) AS DaysOfSalEntry
			FROM #tblSal_Sal_Detail_des
			GROUP BY EmployeeID
			) sal1
		CROSS APPLY (
			SELECT SUM(DaysOfSalEntry) AS DaysOfSalEntry
			FROM tblSal_Sal_Detail sd
			WHERE sd.EmployeeID = sal1.EmployeeID AND sd.Month = @Month AND sd.Year = @Year AND sd.PeriodID = 0
			) sal2

		-- diff basic
		SELECT sal1.EmployeeID, sal1.ActualMonthlyBasic AS ActualMonthlyBasic_Retro, sal2.ActualMonthlyBasic, sal1.ActualMonthlyBasic - isnull(sal2.ActualMonthlyBasic, 0) AS Diff
		INTO #DiffBasic
		FROM #tblSal_Sal_des sal1
		LEFT JOIN tblSal_Sal sal2 ON sal1.EmployeeID = sal2.EmployeeID AND sal2.Month = @Month AND sal2.Year = @Year AND sal2.PeriodID = 0
		WHERE ISNULL(sal1.ActualMonthlyBasic, 0) <> ISNULL(sal2.ActualMonthlyBasic, 0)

		--diff ot
		SELECT ot1.EmployeeID, ISNULL(ot1.OTAmount, 0) - ISNULL(ot2.OTAmount, 0) AS DiffOTAmount, ISNULL(ot1.TaxableOTAmount, 0) - ISNULL(ot2.TaxableOTAmount, 0) AS DiffTaxableOTAmount, ISNULL(ot1.NoneTaxableOTAmount, 0) - ISNULL(ot2.NoneTaxableOTAmount, 0) AS DiffNoneTaxableOTAmount
		INTO #DiffOT
		FROM #tblSal_OT_des ot1
		LEFT JOIN tblSal_OT ot2 ON ot1.EmployeeID = ot2.EmployeeID AND ot2.Month = @Month AND ot2.Year = @Year AND ot2.PeriodID = 0

		-- diff allowance
		SELECT al1.EmployeeID, sum(ISNULL(al1.Amount, 0) - isnull(al2.Amount, 0)) AS DiffAmount, sum(ISNULL(al1.TaxableAmount, 0) - isnull(al2.TaxableAmount, 0)) AS DiffTaxableAmount, sum(ISNULL(al1.UntaxableAmount, 0) - isnull(al2.UntaxableAmount, 0)) AS DiffNontaxableAmount, 'AL_' + als.AllowanceCode + '_Retro' AS RetroTablecolumnName
		INTO #DiffAllowance
		FROM #tblSal_Allowance_des al1
		INNER JOIN tblAllowanceSetting als ON al1.AllowanceID = als.AllowanceID
		LEFT JOIN tblSal_Allowance al2 ON al2.Month = @Month AND al2.Year = @Year AND al1.EmployeeID = al2.EmployeeID AND al1.AllowanceID = al2.AllowanceID AND al2.PeriodID = 0
		GROUP BY al1.EmployeeID, al1.AllowanceID, 'AL_' + als.AllowanceCode + '_Retro'

		DELETE #DiffAllowance
		WHERE ISNULL(DiffAmount, 0) = 0

		-- diff Night shift -- added
		SELECT ns1.EmployeeID, ISNULL(ns1.NSAmount, 0) - isnull(ns2.NSAmount, 0) AS DiffAmount
		INTO #DiffNightShift
		FROM #tblSal_NS_des ns1
		LEFT JOIN tblSal_NS ns2 ON ns1.EmployeeID = ns2.EmployeeID AND ns2.Month = @Month AND ns2.Year = @Year AND ns2.PeriodID = 0
		WHERE ISNULL(ns1.NSAmount, 0) - isnull(ns2.NSAmount, 0) <> 0

		DELETE #tblEmployeeIDList
		WHERE EmployeeID IN (
				SELECT EmployeeID
				FROM tblSal_Lock
				WHERE Month = @nextMonth AND Year = @nextYear
				) -- xóa những thằng đã khóa lương tháng sau

		DELETE tblSal_Retro
		FROM tblSal_Retro re
		WHERE Month = @nextMonth AND Year = @nextYear AND EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				) AND NOT EXISTS (
				SELECT 1
				FROM tblSal_Lock sl
				WHERE sl.Month = @nextMonth AND sl.Year = @nextYear
				) AND EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_AttendanceData_Retro r
				WHERE r.Month = @Month AND r.Year = @Year
				
				UNION
				
				SELECT c.EmployeeID
				FROM tblCustomAttendanceData c
				WHERE c.Month = @Month AND c.Year = @Year AND c.IsRetro = 1
				) AND ISNULL(IsImported, 0) = 0

		-- xóa những thằng ko phải imported, nằm trong danh sách working, mà ko nằm trong danh sách nhân viên retro
		-- ịn vào nếu chưa có
		INSERT INTO tblSal_Retro (EmployeeID, Month, Year)
		SELECT DISTINCT EmployeeID, @nextMonth, @nextYear
		FROM (
			SELECT EmployeeID
			FROM #DiffAllowance
			
			UNION
			
			SELECT EmployeeID
			FROM #DiffBasic
			
			UNION
			
			SELECT EmployeeID
			FROM #DiffOT
			) u
		WHERE u.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_Retro r
				WHERE r.Month = @nextMonth AND r.Year = @nextYear
				)

		-- update thôi
		-- basic
		UPDATE tblSal_Retro
		SET ActualMonthlyBasic_Retro_Amount = ROUND(b.Diff, 0)
		FROM tblSal_Retro re
		LEFT JOIN #DiffBasic b ON re.EmployeeID = b.EmployeeID
		WHERE re.Month = @nextMonth AND re.Year = @nextYear AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		-- ot
		UPDATE tblSal_Retro
		SET OT_Retro_Amount = ROUND(b.DiffOTAmount, 0), Nontax_OT_Retro_Amount = ROUND(b.DiffNoneTaxableOTAmount, 0)
		FROM tblSal_Retro re
		LEFT JOIN #DiffOT b ON re.EmployeeID = b.EmployeeID
		WHERE re.Month = @nextMonth AND re.Year = @nextYear AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		-- allowance
		SET @Query = ''

		SELECT @Query += '
	 if COL_LENGTH(''tblSal_Retro'',''' + RetroTablecolumnName + ''') is null
	 begin
		 alter table tblSal_Retro add [' + RetroTablecolumnName + '] money
		 alter table tblSal_Retro_Sumary add [' + RetroTablecolumnName + '] money
		 alter table #tblSal_Retro_tmpImport add [' + RetroTablecolumnName + '] money
	 end
	 '
		FROM (
			SELECT DISTINCT RetroTablecolumnName
			FROM #DiffAllowance
			) s

		EXEC (@Query)

		SET @Query = ''

		SELECT @Query += '
	 update tblSal_Retro set [' + RetroTablecolumnName + '] = ROUND(tmp.DiffAmount,0)
	 from tblSal_Retro  t
	 inner join #DiffAllowance tmp  on t.EmployeeID = tmp.EmployeeID and tmp.RetroTablecolumnName = ''' + RetroTablecolumnName + ''''
		FROM (
			SELECT DISTINCT RetroTablecolumnName
			FROM #DiffAllowance
			) s

		--print @Query
		EXEC (@Query)

		--select * from #DiffAllowance
		--  diff ins
		SELECT re.EmployeeID, ISNULL(re.EmployeeTotal, 0) - isnull(ins.EmployeeTotal, 0) AS DiffEMployee, ISNULL(re.CompanyTotal, 0) - ISNULL(ins.CompanyTotal, 0) AS DiffCompany
		INTO #DiffIns
		FROM tblSal_Insurance_Retro re
		LEFT JOIN tblSal_Insurance ins ON re.EmployeeID = ins.EmployeeID AND ins.Month = @Month AND ins.Year = @Year
		-- and  (ISNULL(re.EmployeeTotal,0) <> isnull(ins.EmployeeTotal,0) or ISNULL(re.CompanyTotal,0) <> ISNULL(ins.CompanyTotal,0))
		WHERE re.Month = @Month AND re.Year = @Year AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		UPDATE tblSal_Retro
		SET INS_Retro_Amount_EE = ROUND(b.DiffEMployee, 0), INS_Retro_Amount_ER = ROUND(b.DiffCompany, 0)
		FROM tblSal_Retro re
		LEFT JOIN #DiffIns b ON re.EmployeeID = b.EmployeeID
		WHERE re.Month = @nextMonth AND re.Year = @nextYear AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		-- diff union
		-- do đã delete đi add lại ròi nên đừng có sợ gì cả
		SELECT u.EmployeeID, ISNULL(u.UnionFeeEmp, 0) - ISNULL(sal.EmpUnion, 0) AS DiffEmployee, ISNULL(u.UnionFeeComp, 0) - ISNULL(sal.CompUnion, 0) AS DiffCompany
		INTO #diffUnion
		FROM #tblTradeUnion u
		LEFT JOIN tblSal_Sal sal ON u.EmployeeID = sal.EmployeeID AND sal.Month = @Month AND sal.Year = @Year
		WHERE ISNULL(u.UnionFeeEmp, 0) <> ISNULL(sal.EmpUnion, 0) OR ISNULL(u.UnionFeeComp, 0) <> ISNULL(sal.CompUnion, 0)

		UPDATE tblSal_Retro
		SET Union_RETRO_EE = ROUND(b.DiffEmployee, 0), Union_RETRO_ER = ROUND(b.DiffCompany, 0)
		FROM tblSal_Retro re
		LEFT JOIN #diffUnion b ON re.EmployeeID = b.EmployeeID
		WHERE re.Month = @nextMonth AND re.Year = @nextYear AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		-- diff Night Shift -- finalize
		UPDATE tblSal_Retro
		SET NightShift_RETRO = ROUND(b.DiffAmount, 0)
		FROM tblSal_Retro re
		LEFT JOIN #DiffNightShift b ON re.EmployeeID = b.EmployeeID
		WHERE re.Month = @nextMonth AND re.Year = @nextYear AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)

		-- balance days
		UPDATE tblSal_Retro
		SET BalanceDays = b.BalanceDays
		FROM tblSal_Retro re
		LEFT JOIN #DiffDaysofSalEntry b ON re.EmployeeID = b.EmployeeID
		WHERE re.Month = @nextMonth AND re.Year = @nextYear AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM #tblEmployeeIDList
				)
			--drop table #DiffBasic
			--drop table #DiffOT
			--drop table #DiffAllowance
			--drop table #DiffInspiut
	END

	----------------------Error in salary period-------------------------------
	INSERT INTO #tblSal_Error_des ([Month], [Year], EmployeeID, Remark, PeriodID)
	SELECT @Month, @Year, EmployeeID, Reason, @PeriodID
	FROM #TableVarSalError

	--------------------Drop temporary table--------------------------------
	DROP TABLE #tblEmployeeIDList

	DROP TABLE #tblSalDetail

	DROP TABLE #tblLvHistory
END

PRINT 'eof'
	--exec SALCAL_MAIN 7,2025,3,0,'-1',0
GO


if object_id('[dbo].[sp_CustomInputImportMonthly]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_CustomInputImportMonthly] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_CustomInputImportMonthly] (@LoginID INT, @Month INT, @Year INT, @OptionView INT = 0)
AS
BEGIN
	DECLARE @Query NVARCHAR(max) = ''

	-- SELECT @Query += '[' + AllowanceCode + '] money,'
	-- FROM tblAllowanceSetting
	-- WHERE Visible = 1 AND AllowanceCode NOT IN (
	-- 		SELECT name
	-- 		FROM sys.columns
	-- 		WHERE object_id = object_id('tblCustomInputImportMonthly')
	-- 		)
	-- ORDER BY Ord

	-- IF len(@Query) > 3
	-- BEGIN
	-- 	SET @Query = left(@Query, len(@Query) - 1)
	-- 	SET @Query = 'alter table tblCustomInputImportMonthly add ' + @Query

	-- 	EXEC (@query)
	-- END

	DECLARE @ToDate DATE

	SELECT @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT EmployeeID, FullName
	INTO #tmpEmloyeeList
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@ToDate, '-1', @LoginID)
	WHERE ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 0) = 1 AND ISNULL(IsForeign, 0) = 0) OR (ISNULL(@OptionView, 0) = 2 AND ISNULL(IsForeign, 0) = 1)

	SET @Query = ''

	IF (@OptionView = 2)
	BEGIN
		SELECT @Query += ', ci.[' + name + ']'
		FROM sys.columns
		WHERE object_id = object_id('tblCustomInputImportMonthly') AND name NOT IN ('EmployeeID', 'Month', 'Year', 'Remark') AND name IN (
				SELECT CAST(AllowanceID AS NVARCHAR(50))
				FROM tblAllowanceSetting
				WHERE ISNULL(IsGrossAllowance_InNetSal, 0) = 1
			)
		ORDER BY column_id
	END
	ELSE
	BEGIN
		SELECT @Query += ', ci.[' + name + ']'
		FROM sys.columns
		WHERE object_id = object_id('tblCustomInputImportMonthly') AND name NOT IN ('EmployeeID', 'Month', 'Year', 'Remark') AND name IN (
				SELECT CAST(AllowanceID AS NVARCHAR(50))
				FROM tblAllowanceSetting
				WHERE ISNULL(IsGrossAllowance_InNetSal, 0) = 0
				)
		ORDER BY column_id
	END

	--set @Query = stuff(@Query,1,1,'')
	SET @Query = 'select te.EmployeeID, te.FullName, @Month Month, @Year Year' + @Query + ',ci.Remark, cast(case when l.EmployeeID is not null then 1 else 0 end as bit) IsReadOnlyRow
	from #tmpEmloyeeList te
	inner join tblCustomInputImportMonthly ci on te.EmployeeID = ci.EmployeeID and ci.Month = @Month and ci.YEar = @YEar
	left join tblSal_Lock l on te.EmployeeID = l.EmployeeID and l.Month = ci.Month and l.Year = ci.Year
	order by te.EmployeeID
	'

	EXEC sp_executesql @Query, N'@Month int,@Year int', @Month, @Year

	SET @Query = ''

	SELECT @Query += '[' + AllowanceCode + '],'
	FROM tblAllowanceSetting
	WHERE Visible = 1 AND AllowanceCode IN (
			SELECT name
			FROM sys.columns
			WHERE object_id = object_id('tblCustomInputImportMonthly')
			)
	ORDER BY Ord

	CREATE TABLE #tmpColumnRange (ColumnList NVARCHAR(max), ExcelRange NVARCHAR(20), WithMergeCellOntop INT)

	INSERT INTO #tmpColumnRange
	SELECT @Query, 'F6:G8', 1

	SELECT *
	FROM #tmpColumnRange

	CREATE TABLE #ExportConfig (TableIndex INT, RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(Max), Position NVARCHAR(200), SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT)

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	SELECT 0, 'Table|ColumnRangeTableIndex=1', 'A7', 0, 1

	SELECT *
	FROM #ExportConfig
END
GO



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


if object_id('[dbo].[sp_AttendanceSummaryMonthly_STD]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_AttendanceSummaryMonthly_STD] as select 1')
GO
ALTER PROCEDURE [dbo].[sp_AttendanceSummaryMonthly_STD] (@Month INT, @Year INT, @LoginID INT = 3, @LanguageID VARCHAR(2) = 'VN', @OptionView INT = 1, @isExport INT = 0, @ViewProbationPeriod BIT = 0)
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	DECLARE @GetDate DATETIME = dbo.Truncate_Date(GetDate())

	SELECT EmployeeID, FullName, DivisionID, DepartmentID, SectionID, HireDate, PositionID, TerminateDate, EmployeeTypeID, GroupID
	INTO #fn_vtblEmployeeList_Bydate
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) e
	WHERE (ISNULL(@OptionView, '-1') = '-1' OR ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 1) = 1 AND IsForeign = 0) OR (ISNULL(@OptionView, '-1') = 2 AND ISNULL(IsForeign, 1) = 1))

	SELECT ROW_NUMBER() OVER (
			ORDER BY ORD, LeaveCode
			) AS ORD, LeaveCode, TACode
	INTO #LeaveCode
	FROM tblLeaveType
	WHERE IsVisible = 1

	SELECT ROW_NUMBER() OVER (
			ORDER BY e.EmployeeID
			) AS [No], e.EmployeeID, FullName, p.PositionName, d.DivisionName, dept.DepartmentName, s.SectionName, g.GroupName, HireDate, TerminateDate
	INTO #tmpEmployeeList
	FROM #fn_vtblEmployeeList_Bydate e
	LEFT JOIN tblSection s ON s.SectionID = e.SectionID
	LEFT JOIN tblPosition p ON p.PositionID = e.PositionID
	LEFT JOIN tblDivision d ON d.DivisionID = e.DivisionID
	LEFT JOIN tblDepartment dept ON dept.DepartmentID = e.DepartmentID
	LEFT JOIN tblGroup g ON g.GroupID = e.GroupID

	SELECT h.EmployeeID, h.AttDate, h.AttStart, h.AttEnd
	INTO #tblHasTA
	FROM tblHasTA h
	INNER JOIN #tmpEmployeeList elb ON elb.EmployeeID = h.EmployeeID
	WHERE AttDate BETWEEN @FromDate AND @ToDate

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind, ots.ColumnDisplayName OTType
	INTO #tblOTList
	FROM tblOTList ot
	INNER JOIN #tmpEmployeeList elb ON elb.EmployeeID = ot.EmployeeID
	LEFT JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OTKind
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0

	-- ko nằm trong danh sách thì ko tính lương nha
	CREATE TABLE #Tadata (EmployeeID VARCHAR(20), Attdate DATE, HireDate DATE, EmployeeStatusID INT, HolidayStatus INT, WorkingTime FLOAT(53), Std_Hour_PerDays FLOAT(53), Lvamount FLOAT(53), PaidAmount_Des FLOAT(53), UnpaidAmount_Des FLOAT(53), SalaryHistoryID INT, CutSI BIT, LeaveCode VARCHAR(5), EmployeeTypeID INT)

	EXEC sp_WorkingTimeProvider @Month = @Month, @Year = @Year, @fromdate = @FromDate, @todate = @ToDate, @loginId = @LoginID

	EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 1

	SELECT *
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1 = 0

	-- Tạo danh sách các cột cần tính tổng động
	DECLARE @cols NVARCHAR(MAX) = '', @querySelector NVARCHAR(MAX) = ''

	IF (@ViewProbationPeriod <> 1)
	BEGIN
		SELECT @cols += N',SUM(' + QUOTENAME(COLUMN_NAME) + N') AS ' + QUOTENAME(COLUMN_NAME), @querySelector += N',' + QUOTENAME(COLUMN_NAME)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'tblAttendanceSummary' AND COLUMN_NAME NOT IN ('Month', 'Year', 'EmployeeID', 'PeriodID', 'FromDate', 'ToDate');
	END
	ELSE
	BEGIN
		SELECT @cols += N',' + QUOTENAME(COLUMN_NAME) + N' AS ' + QUOTENAME(COLUMN_NAME), @querySelector += N',' + QUOTENAME(COLUMN_NAME)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'tblAttendanceSummary' AND COLUMN_NAME NOT IN ('Month', 'Year', 'EmployeeID', 'PeriodID', 'FromDate', 'ToDate');
	END

	-- Tạo truy vấn động
	DECLARE @sql NVARCHAR(MAX) = N'
        INSERT INTO #tblAttendanceSummary (EmployeeID, Month, Year, PeriodID, FromDate, ToDate ' + @querySelector + N')
        SELECT
            EmployeeID,
            @Month AS Month,
            @Year AS Year,
			ISNULL(PeriodID, 0), FromDate, ToDate
            ' + @cols + N'
        FROM tblAttendanceSummary
        WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
            SELECT EmployeeID FROM #tmpEmployeeList
        )
        GROUP BY EmployeeID, Month, Year, PeriodID, FromDate, ToDate
    ';

	-- Thực thi truy vấn động
	EXEC sp_executesql @sql, N'@Month INT, @Year INT', @Month = @Month, @Year = @Year;

	SELECT n.EmployeeID, SUM(HourApprove) NSHours, elb.FromDate, elb.ToDate
	INTO #NightShiftSum
	FROM tblNightShiftList n
	INNER JOIN #tblAttendanceSummary elb ON elb.EmployeeID = n.EmployeeID AND n.DATE BETWEEN elb.FromDate AND elb.ToDate
	WHERE n.DATE BETWEEN @FromDate AND @ToDate
	GROUP BY n.EmployeeID, elb.FromDate, elb.ToDate

	SELECT o.EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType, FromDate, ToDate
	INTO #tblOTSummary
	FROM #tblOTList o
	INNER JOIN #tblAttendanceSummary el ON el.EmployeeID = O.EmployeeID AND O.OTDate BETWEEN el.FromDate AND el.ToDate
	GROUP BY o.EmployeeID, OTKind, OTType, FromDate, ToDate

	SELECT e.EmployeeID, ROUND(SUM(IOMinutesDeduct) / 60, 1) AS IOHrs, el.FromDate, el.ToDate
	INTO #InLateOutEarly
	FROM tblInLateOutEarly e
	INNER JOIN #tblAttendanceSummary el ON el.EmployeeID = e.EmployeeID AND e.IODate BETWEEN el.FromDate AND el.ToDate
	WHERE ApprovedDeduct = 1 AND IODate BETWEEN @FromDate AND @ToDate
	GROUP BY e.EmployeeID, el.FromDate, el.ToDate

	--Dữ liệu custom
	SELECT *
	INTO #tblCustomAttendanceData
	FROM tblCustomAttendanceData
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			)

	DECLARE @CustomOTInsert NVARCHAR(MAX) = ''

	SELECT @CustomOTInsert += '
	insert into #tblOTSummary(EmployeeID,OTKind,ApprovedHours)
	select EmployeeID,''' + CAST(OTKind AS VARCHAR(10)) + ''',' + ColumnNameOn_CustomAttendanceTable + '
	from #tblCustomAttendanceData where ' + ColumnNameOn_CustomAttendanceTable + ' <>0'
	FROM tblOvertimeSetting ov
	WHERE ov.ColumnNameOn_CustomAttendanceTable IN (
			SELECT COLUMN_NAME
			FROM INFORMATION_SCHEMA.COLUMNS c
			WHERE c.TABLE_NAME = 'tblCustomAttendanceData'
			)

	EXEC (@CustomOTInsert)

	UPDATE s
	SET OTType = ov.ColumnDisplayName
	FROM #tblOTSummary s
	INNER JOIN tblOvertimeSetting ov ON ov.OTKind = s.OTKind
	WHERE OTType IS NULL

	-- --Thông tin nghỉ
	SELECT h.EmployeeID, h.LeaveCode, LeaveDate, LvAmount, LeaveStatus, lc.TACode
	INTO #LeaveHistory
	FROM tblLvHistory h
	INNER JOIN #tmpEmployeeList e ON e.EmployeeID = h.EmployeeID
	LEFT JOIN #LeaveCode lc ON lc.LeaveCode = h.LeaveCode
	WHERE LeaveDate BETWEEN @FromDate AND @ToDate

	CREATE TABLE #SummaryData (
		--Hay dùng từ pivot lắm mà k bao giờ chịu pivot con ngta
		STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), PositionName NVARCHAR(MAX), HireDate DATE, ProbationEndDate DATE, STD_WorkingDays FLOAT, Actual_WorkingDays FLOAT,
		TotalPaidDays FLOAT, WorkHours FLOAT, PaidLeaveHrs FLOAT, UnpaidLeave FLOAT, IOHrs DECIMAL(10, 1), TotalOT DECIMAL(10, 2), TotalNS DECIMAL(10, 2), TotalDayOff DECIMAL(10, 2)
		)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, DepartmentName, PositionName)
	SELECT No, EmployeeID, FullName, HireDate, DepartmentName, PositionName
	FROM #tmpEmployeeList

	DECLARE @Query NVARCHAR(MAX) = 'ALTER TABLE #SummaryData ADD '

	SELECT @Query += ISNULL(TACode, '') + ' DECIMAL(10, 1), '
	FROM #LeaveCode
	ORDER BY ORD ASC

	SELECT @Query += ISNULL(ColumnDisplayName, '') + ' DECIMAL(10, 1),'
	FROM tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	IF (ISNULL(@isExport, 0) = 0)
	BEGIN
		SELECT @Query += N'[' + CAST(Number AS VARCHAR(3)) + 'Att] VARCHAR(30), '
		FROM dbo.fn_Numberlist(CAST(DAY(@FromDate) AS INT), CAST(DAY(@ToDate) AS INT))
	END

	SET @Query = @Query + ' ForgetTimekeeper INT, Signture NVARCHAR(10), Notes NVARCHAR(200)'

	EXEC sp_executesql @Query

	ALTER TABLE #Tadata ADD WorkingTimeDisplay VARCHAR(100)

	UPDATE #Tadata
	SET WorkingTimeDisplay = CASE
			WHEN ISNULL(LeaveCode, '') <> ''
				THEN LeaveCode
			WHEN AttStart IS NOT NULL OR AttEnd IS NOT NULL AND ISNULL(LeaveCode, '') = ''
				THEN ISNULL(CONVERT(VARCHAR(5), AttStart, 8), '--:--') + ' | ' + ISNULL(CONVERT(VARCHAR(5), AttEnd, 8), '--:--')
			ELSE NULL
			END
	FROM #Tadata
	LEFT JOIN #tblHasTA t ON t.EmployeeID = #Tadata.EmployeeID AND t.Attdate = #Tadata.Attdate

	IF (ISNULL(@isExport, 0) = 0)
	BEGIN
		SET @Query = ''

		SELECT @Query = (
			SELECT 'UPDATE s SET [' + CAST(Number AS VARCHAR(3)) + 'Att] = w.WorkingTimeDisplay'
				+ ' FROM #SummaryData s'
				+ ' INNER JOIN #Tadata w ON s.EmployeeID = w.EmployeeID'
				+ ' WHERE DAY(w.Attdate) = ' + CAST(Number AS VARCHAR(3)) + ';'
				+ CHAR(13) + CHAR(10)
			FROM dbo.fn_Numberlist(CAST(DAY(@FromDate) AS INT), CAST(DAY(@ToDate) AS INT))
			FOR XML PATH(''), TYPE
		).value('.', 'NVARCHAR(MAX)')

		EXEC sp_executesql @Query
	END

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(TACode, '') + '] = w.' + ISNULL(TACode, '') + '
                        FROM #SummaryData s
                        INNER JOIN #tblAttendanceSummary w ON s.EmployeeID = w.EmployeeID;'
	FROM #LeaveCode

	EXEC sp_executesql @Query

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(ColumnDisplayName, '') + '] = w.ApprovedHours
                        FROM #SummaryData s
                        INNER JOIN #tblOTSummary w ON s.EmployeeID = w.EmployeeID
						WHERE w.OTType = ''' + ISNULL(ColumnDisplayName, '') + N''';'
	FROM tblOvertimeSetting

	EXEC sp_executesql @Query

	UPDATE s
	SET WorkHours = CAST(a.WorkingHrs_Total AS decimal(10, 2)), PaidLeaveHrs = a.PaidLeaveHrs_Total, UnpaidLeave = a.UnpaidLeaveDays * a.Std_Hour_PerDays, STD_WorkingDays = a.RegularWorkdays, Actual_WorkingDays = CAST(ROUND((a.WorkingHrs_Total / a.Std_Hour_PerDays), 2) AS decimal(10, 2)), TotalPaidDays = CAST(a.WorkingDays_Total AS decimal(10, 2))
	FROM #SummaryData s
	INNER JOIN #tblAttendanceSummary a ON a.EmployeeID = s.EmployeeID

	UPDATE s
	SET TotalNS = ISNULL(a.NSHours, 0)
	FROM #SummaryData s
	INNER JOIN #NightShiftSum a ON a.EmployeeID = s.EmployeeID

	UPDATE s
	SET IOHrs = ISNULL(a.IOHrs, 0)
	FROM #SummaryData s
	INNER JOIN #InLateOutEarly a ON a.EmployeeID = s.EmployeeID

	UPDATE s
	SET TotalOT = ISNULL(a.SumOTHours, 0)
	FROM #SummaryData s
	INNER JOIN (
		SELECT EmployeeID, SUM(ApprovedHours) SumOTHours
		FROM #tblOTSummary
		GROUP BY EmployeeID
		) a ON a.EmployeeID = s.EmployeeID

	SELECT EmployeeID, SaturdayDate AS SatDate
	INTO #SatWorkList
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)
	--WHERE SaturdayDate BETWEEN @FromDate AND @ToDate
	
	UNION
	
	SELECT EmployeeID, SaturdayDate_2nd AS SatDate
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)

	UPDATE s
	SET TotalDayOff = ISNULL(a.DayOff, 0)
	FROM #SummaryData s
	INNER JOIN (
		SELECT EmployeeID, COUNT(1) DayOff
		FROM #SatWorkList
		GROUP BY EmployeeID
		) a ON a.EmployeeID = s.EmployeeID

	--Ẩn các cột k có dữ liệu
	SELECT l.ORD, l.TACode, c.ColumnExcel
	INTO #HideColumn
	FROM #LeaveCode l
	INNER JOIN dbo.fn_ColumnExcel('G', 'Y') c ON c.ORD = l.ORD
	ORDER BY l.ORD ASC;

	WITH OTKind_CTE
	AS (
		SELECT ROW_NUMBER() OVER (
				ORDER BY ColumnDisplayName
				) AS ORD, ColumnDisplayName, OTKind
		FROM tblOvertimeSetting h
		)
	SELECT CTE.ORD, OTKind, c.ColumnExcel, ColumnDisplayName
	INTO #HideColumn_OT
	FROM OTKind_CTE CTE
	INNER JOIN dbo.fn_ColumnExcel('Z', 'AG') c ON c.ORD = CTE.ORD

	DELETE
	FROM #HideColumn
	WHERE TACode IN (
			SELECT DISTINCT TACode
			FROM #LeaveHistory
			) OR TACode IN ('P', 'AWP', 'S', 'O', 'M', 'SP')

	DELETE
	FROM #HideColumn_OT
	WHERE OTKind IN (
			SELECT DISTINCT OTKind
			FROM #tblOTSummary
			WHERE ISNULL(OTKind, '') <> ''
			)


	-- SET @Query = 'ALTER TABLE #SummaryData DROP COLUMN'
	-- SELECT @Query += N'[' + ISNULL(TACode, '') + N'],'
	-- FROM #HideColumn
	-- SELECT @Query += N'[' + ISNULL(ColumnDisplayName, '') + N'],'
	-- FROM #HideColumn_OT
	-- SELECT @Query = ISNULL(@Query, '') + ' Notes'
	-- EXEC sp_executesql @Query
	DECLARE @HideColumn NVARCHAR(MAX) = ''

	IF (ISNULL(@isExport, 0) = 1)
	BEGIN

		CREATE TABLE #ExportConfig (ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200), SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200))

		SET @Query = 'SELECT '

		SELECT @Query += N'''' + ISNULL(TACode, '') + N''' AS [' + ISNULL(TACode, '') + N'],'
		FROM #LeaveCode
		ORDER BY ORD ASC

		SET @Query += '''In Late/Out Early'''

		EXEC sp_executesql @Query

		SELECT @HideColumn += N'' + ISNULL(TACode, '') + N','
		FROM #HideColumn

		SELECT @HideColumn += N'' + ISNULL(ColumnDisplayName, '') + N','
		FROM #HideColumn_OT

		-- IF EXISTS (
		-- 		SELECT 1
		-- 		FROM #HideColumn
		-- 		) OR EXISTS (
		-- 		SELECT 1
		-- 		FROM #HideColumn_OT
		-- 		)
		-- BEGIN
		-- 	INSERT INTO #ExportConfig (ParseType, Position, SheetIndex)
		-- 	SELECT 'DeleteColumn', ColumnExcel, 0
		-- 	FROM #HideColumn
		-- 	UNION
		-- 	SELECT 'DeleteColumn', ColumnExcel, 0
		-- 	FROM #HideColumn_OT
		--     ORDER BY ColumnExcel desc
		-- END
		INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
		VALUES (0, 'Table_NonInsert', 'G6', 0, 0)

		ALTER TABLE #SummaryData

		DROP COLUMN WorkHours, PaidLeaveHrs, UnpaidLeave

		SELECT *
		FROM #SummaryData

		SELECT N'From/Từ:  ' + CONVERT(NVARCHAR(10), @FromDate, 103) + N'                                    To/Đến: ' + CONVERT(NVARCHAR(10), @ToDate, 103)

		SELECT ColumnDisplayName + ': ' + DescriptionEN
		FROM tblOvertimeSetting
		ORDER BY ColumnDisplayName ASC

		SELECT TACode + ': ' + DescriptionEN
		FROM tblLeaveType
		WHERE IsVisible = 1
		ORDER BY ORD

		INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
		VALUES (3, 'Table_NonInsert', 'B11', 0, 0)

		INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
		VALUES (4, 'Table_NonInsert', 'F11', 0, 0)

		INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
		VALUES (1, 'Table|HideColumn=' + @HideColumn, 'B7', 0, 0)

		INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
		VALUES (2, 'Table_NonInsert', 'G3', 0, 0)

		SELECT *
		FROM #ExportConfig
		ORDER BY ORD

		RETURN
	END

	IF (ISNULL(@isExport, 0) = 0)
	BEGIN
		SET @Query = 'ALTER TABLE #SummaryData DROP COLUMN '

		SELECT @Query += N'' + ISNULL(TACode, '') + N','
		FROM #LeaveCode
		WHERE TACode NOT IN (
				SELECT DISTINCT TACode
				FROM #LeaveHistory
				)

		SELECT @Query += N'' + ISNULL(ColumnDisplayName, '') + N','
		FROM #HideColumn_OT

		SELECT @Query = ISNULL(@Query, '') + ' Notes'

		EXEC sp_executesql @Query
	END

	SELECT *
	FROM #SummaryData
	ORDER BY EmployeeID
END
GO



if object_id('[dbo].[sp_processSummaryAttendance]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_processSummaryAttendance] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_processSummaryAttendance] (@LoginID INT, @Year INT, @Month INT, @ViewType INT = 0, @Payroll BIT = 0)
AS
BEGIN
	--    ALTER TABLE tblOvertimeSetting ALTER COLUMN ColumnDisplayName NVARCHAR(100) NOT NULL
	--View Type: 0: 0 view chỉ process, 1: view summary, 2: view in-out chi tiết
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	--LeaveType
	DECLARE @Query NVARCHAR(MAX) = ''

	-- SELECT @Query = (
	-- 	SELECT N'IF COL_LENGTH(''tblAttendanceSummary'',''' + LeaveCode + N''') is null
	-- 					ALTER TABLE tblAttendanceSummary ADD [' + LeaveCode + N'] FLOAT;'
	-- 	FROM tblLeaveType
	-- 	WHERE IsVisible = 1
	-- 	FOR XML PATH(''), TYPE
	-- ).value('.', 'NVARCHAR(MAX)')

	-- EXEC (@Query)

	SELECT *
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1=0

	--, CAST(NULL AS DATETIME) TerminateDate, CAST(NULL AS DATETIME) HireDate, CAST(NULL AS DATETIME) ProbationEndDate, CAST(NULL AS INT) isForeign
	SELECT te.EmployeeID, te.DivisionID, te.DepartmentID, te.SectionID, te.GroupID, te.EmployeeTypeID, te.PositionID, te.EmployeeStatusID, te.Sex, CASE
			WHEN te.HireDate > @fromDate
				THEN cast(1 AS BIT)
			ELSE 0
			END AS NewStaff, CAST(0 AS BIT) AS TerminatedStaff, HireDate, CAST(NULL AS DATETIME) TerminateDate, ProbationEndDate, te.LastWorkingDate, CAST(0 AS BIT) hasTwoPeriods, et.isLocalStaff, te.isForeign, et.PercentProbation
	INTO #EmployeeList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) te
	INNER JOIN tblEmployeeType et ON te.EmployeeTypeID = et.EmployeeTypeID

	DELETE e
	FROM #EmployeeList e
	INNER JOIN tblAtt_LockMonth l ON e.EmployeeID = l.EmployeeID AND l.Month = @Month AND l.Year = @Year

	DELETE e
	FROM #EmployeeList e
	INNER JOIN tblSal_Lock l ON e.EmployeeID = l.EmployeeID AND l.Month = @Month AND l.Year = @Year

	--INNER JOIN tblAtt_LockMonth a ON a.EmployeeID = e.EmployeeID AND a.Month = @Month AND a.Year = @Year
	-- khoa roi thi khong tinh luong nua
	SELECT *
	INTO #fn_EmployeeStatus_ByDate
	FROM dbo.fn_EmployeeStatus_ByDate(@ToDate)

	SELECT *
	INTO #fn_EmployeeStatus_ByDate_FirstLastMonth
	FROM dbo.fn_EmployeeStatus_ByDate(dateadd(dd, 1, @ToDate))

	SELECT l.*
	INTO #tblLvHistory
	FROM tblLvHistory l
	INNER JOIN #EmployeeList e ON l.EmployeeID = e.EmployeeID
	WHERE LeaveDate BETWEEN @FromDate AND @ToDate

	--lay trang thai ben bang history cho chinh xac
	-- UPDATE #EmployeeList
	-- SET EmployeeStatusID = stt.EmployeeStatusID
	-- FROM #EmployeeList te
	-- INNER JOIN #fn_EmployeeStatus_ByDate stt ON te.EmployeeID = stt.EmployeeID
	-- WHERE te.EmployeeStatusID <> stt.EmployeeStatusID

	-- UPDATE #EmployeeList
	-- SET EmployeeStatusID = stt.EmployeeStatusID, TerminateDate = stt.ChangedDate, LastWorkingDate = dateadd(dd, - 1, stt.ChangedDate)
	-- FROM #EmployeeList te
	-- INNER JOIN #fn_EmployeeStatus_ByDate_FirstLastMonth stt ON te.EmployeeID = stt.EmployeeID
	-- WHERE stt.EmployeeStatusID = 20

	-- UPDATE #EmployeeList
	-- SET TerminatedStaff = 1
	-- WHERE TerminateDate IS NOT NULL

	SELECT *
	INTO #CurrentSalary
	FROM dbo.fn_CurrentSalaryHistoryIDByDate(@ToDate)

	--Những người có 2 dòng công = 2 dòng lương
	INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, PercentProbation)
	SELECT @Year, @Month, sh.EmployeeID, 0, sh.SalaryHistoryID, CASE
			WHEN sh.DATE < @FromDate
				THEN @FromDate
			ELSE sh.DATE
			END, @ToDate, te.PercentProbation
	FROM #EmployeeList te
	INNER JOIN #CurrentSalary s ON te.EmployeeID = s.EmployeeID
	INNER JOIN tblSalaryHistory sh ON s.SalaryHistoryID = sh.SalaryHistoryID
	WHERE sh.DATE >= te.HireDate

	-- INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, PercentProbation)
	-- SELECT @Year, @Month, sh.EmployeeID, 1, sh.SalaryHistoryID, CASE
	-- 		WHEN sh.DATE < @FromDate
	-- 			THEN @FromDate
	-- 		ELSE sh.DATE
	-- 		END, @ToDate, te.PercentProbation
	-- FROM #EmployeeList te
	-- INNER JOIN tblSalaryHistory sh ON te.EmployeeID = sh.EmployeeID
	-- WHERE sh.SalaryHistoryID NOT IN (
	-- 		SELECT SalaryHistoryID
	-- 		FROM #CurrentSalary
	-- 		) AND [Date] > @FromDate AND NOT EXISTS (
	-- 		SELECT 1
	-- 		FROM #tblAttendanceSummary s
	-- 		WHERE sh.SalaryHistoryID = s.SalaryHistoryID
	-- 		) AND sh.DATE <= @ToDate AND ISNULL(te.isForeign, 0) = 0

	INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, PercentProbation)
    SELECT @Year, @Month, sh.EmployeeID, 1, sh.SalaryHistoryID,
        CASE WHEN sh.DATE < @FromDate THEN @FromDate ELSE sh.DATE END, @ToDate, te.PercentProbation
    FROM #EmployeeList te
    INNER JOIN tblSalaryHistory sh ON te.EmployeeID = sh.EmployeeID
    LEFT JOIN #CurrentSalary cs ON sh.SalaryHistoryID = cs.SalaryHistoryID
    WHERE cs.SalaryHistoryID IS NULL AND sh.Date > @FromDate
        AND NOT EXISTS (
            SELECT 1 FROM #tblAttendanceSummary s WHERE sh.SalaryHistoryID = s.SalaryHistoryID
        ) AND sh.DATE <= @ToDate AND ISNULL(te.isForeign, 0) = 0


	--Thử việc
	IF EXISTS (
			SELECT 1
			FROM #tblAttendanceSummary sh
			INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
			WHERE (ProbationEndDate BETWEEN @FromDate AND @ToDate OR ProbationEndDate > @ToDate) AND HireDate <> ProbationEndDate
			)
	BEGIN
		UPDATE #tblAttendanceSummary
		SET PercentProbation = ISNULL(CASE
					WHEN ISNULL(tsh.PercentProbation, 0) = 0
						THEN NULL
					ELSE tsh.PercentProbation
					END, sh.PercentProbation)
		FROM #tblAttendanceSummary sh
		INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
		LEFT JOIN tblSalaryHistory tsh ON sh.SalaryHistoryID = tsh.SalaryHistoryID
		WHERE (e.ProbationEndDate BETWEEN @FromDate AND @ToDate OR e.ProbationEndDate > @ToDate) AND e.HireDate <> e.ProbationEndDate

		UPDATE #tblAttendanceSummary
		SET PercentProbation = NULL
		FROM #tblAttendanceSummary sh
		INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
		WHERE e.ProbationEndDate IS NULL OR e.ProbationEndDate < @FromDate

		INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, PercentProbation)
		SELECT @Year, @Month, sh.EmployeeID, 1, sh.SalaryHistoryID, CASE
				WHEN @FromDate < HireDate
					THEN HireDate
				ELSE @FromDate
				END, ProbationEndDate, sh.PercentProbation
		FROM #tblAttendanceSummary sh
		INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
		WHERE e.ProbationEndDate BETWEEN @FromDate AND @ToDate AND e.HireDate <> e.ProbationEndDate

		--het thu viec trong thang nay
		UPDATE #tblAttendanceSummary
		SET FromDate = DATEADD(day, 1, ProbationEndDate), PercentProbation = 100
		FROM #tblAttendanceSummary sh
		INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
		WHERE ISNULL(sh.PercentProbation, 0) > 0 AND ProbationEndDate BETWEEN @FromDate AND @ToDate
	END

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind
	INTO #tblOTList
	FROM tblOTList ot
	INNER JOIN #EmployeeList e ON ot.EmployeeID = e.EmployeeID
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0

	IF (@Payroll = 0)
	BEGIN
		CREATE TABLE #Tadata (EmployeeID VARCHAR(20), Attdate DATE, HireDate DATE, EmployeeStatusID INT, HolidayStatus INT, WorkingTime FLOAT(53), Std_Hour_PerDays FLOAT(53), Lvamount FLOAT(53), PaidAmount_Des FLOAT(53), UnpaidAmount_Des FLOAT(53), SalaryHistoryID INT, CutSI BIT, EmployeeTypeID INT)

		SET ANSI_NULLS ON;
		SET ANSI_PADDING ON;
		SET ANSI_WARNINGS ON;
		SET ARITHABORT ON;
		SET CONCAT_NULL_YIELDS_NULL ON;
		SET QUOTED_IDENTIFIER ON;
		SET NUMERIC_ROUNDABORT OFF;

		EXEC sp_WorkingTimeProvider @Month = @Month, @Year = @Year, @fromdate = @FromDate, @todate = @ToDate, @loginId = @LoginID
	END

	DECLARE @ROUND_TOTAL_WORKINGDAYS INT

	SET @ROUND_TOTAL_WORKINGDAYS = (
			SELECT [Value]
			FROM tblParameter
			WHERE Code = 'ROUND_TOTAL_WORKINGDAYS'
			)
	SET @ROUND_TOTAL_WORKINGDAYS = ISNULL(@ROUND_TOTAL_WORKINGDAYS, 2)

	DELETE
	FROM #Tadata
	WHERE Attdate < HireDate

	--Người nước ngoài mặc định full công - trường hợp vào làm/nghỉ làm giữa tháng
	UPDATE att
	SET WorkingTime = 8, Std_Hour_PerDays = 8
	FROM #Tadata att
	INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
	WHERE ISNULL(e.IsForeign, 0) = 1 AND (e.HireDate BETWEEN @FromDate AND @ToDate OR e.TerminateDate BETWEEN @FromDate AND @ToDate)

    SELECT ta.EmployeeID, ta.SalaryHistoryID, SUM(CASE
				WHEN ISNULL(HolidayStatus, 0) <> 1
					THEN 1
				ELSE 0
				END) AS STD_PerHistoryID, ROUND(SUM(CASE
					WHEN ISNULL(HolidayStatus, 0) = 0
						THEN ta.WorkingTime / isnull(ta.Std_Hour_PerDays, 8)
					ELSE 0
					END), @ROUND_TOTAL_WORKINGDAYS) AS AttDays, ROUND(SUM(CASE
					WHEN ISNULL(HolidayStatus, 0) = 0
						THEN ta.WorkingTime
					ELSE 0
					END), @ROUND_TOTAL_WORKINGDAYS) AS AttHrs, SUM(ta.PaidAmount_Des) AS PaidLeaveHrs, SUM(ta.PaidAmount_Des / isnull(ta.Std_Hour_PerDays, 8)) AS PaidLeaveDays, SUM(ta.UnpaidAmount_Des) AS UnpaidLeaveHrs, SUM(ta.UnpaidAmount_Des / isnull(ta.Std_Hour_PerDays, 8)) AS UnpaidLeaveDays, SUM(CASE
				WHEN HolidayStatus = 1
					THEN 1
				ELSE 0
				END) AS TotalSunDay, SUM(CASE
				WHEN CutSI = 1 AND HolidayStatus <> 1
					THEN 1
				ELSE 0
				END) TotalNonWorkingDays, ta.Std_Hour_PerDays, s.PeriodID
	INTO #tblSal_AttendanceData
	FROM #Tadata ta
	INNER JOIN #tblAttendanceSummary s ON ta.EmployeeID = s.EmployeeID AND ta.AttDate BETWEEN s.FromDate AND s.ToDate
	GROUP BY ta.EmployeeID, ta.SalaryHistoryID, ta.Std_Hour_PerDays, s.PeriodID

	SELECT EmployeeID, SaturdayDate AS SatDate
	INTO #SatWorkList
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)
	--WHERE SaturdayDate BETWEEN @FromDate AND @ToDate
	
	UNION
	
	SELECT EmployeeID, SaturdayDate_2nd AS SatDate
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)

	-- Đếm số ngày thứ 7 cho từng nhân viên theo HireDate và TerminateDate
	UPDATE s
	SET AttHrs = ISNULL(s.AttHrs, 0) + (ISNULL(s.Std_Hour_PerDays, 8) * SatCount), AttDays = ISNULL(s.AttDays, 0) + SatCount
	FROM #tblSal_AttendanceData s
	INNER JOIN #EmployeeList e ON s.EmployeeID = e.EmployeeID
	INNER JOIN #tblAttendanceSummary ta ON ta.EmployeeID = s.EmployeeID AND s.PeriodID = ta.PeriodID
	CROSS APPLY (
		SELECT COUNT(*) AS SatCount
		FROM (
			SELECT TOP (
					DATEDIFF(DAY, CASE
							WHEN e.HireDate > FromDate
								THEN e.HireDate
							ELSE FromDate
							END, CASE
							WHEN e.TerminateDate IS NOT NULL AND e.TerminateDate < ToDate
								THEN e.TerminateDate
							ELSE ToDate
							END) + 1
					) DATEADD(DAY, ROW_NUMBER() OVER (
						ORDER BY (
								SELECT NULL
								)
						) - 1, CASE
						WHEN e.HireDate > FromDate
							THEN e.HireDate
						ELSE FromDate
						END) AS TheDate
			FROM sys.all_objects
			) AS Dates
		WHERE DATENAME(WEEKDAY, TheDate) = 'Saturday' AND TheDate NOT IN (
				SELECT SatDate
				FROM #SatWorkList sat
				WHERE sat.EmployeeID = e.EmployeeID
				)
		) Sat
	WHERE e.isLocalStaff = 1 AND e.HireDate <= @ToDate AND (e.TerminateDate IS NULL OR e.TerminateDate >= @FromDate)

	UPDATE #tblAttendanceSummary
	SET WorkingHrs_Total = ISNULL(ta.AttHrs, 0), WorkingDays_Total = ISNULL(ta.AttDays, 0), PaidLeaveDays_Total = ta.PaidLeaveDays, Std_Hour_PerDays = ta.Std_Hour_PerDays, PaidLeaveHrs_Total = ta.PaidLeaveHrs, UnpaidLeaveDays = ta.UnpaidLeaveDays, UnpaidLeaveHrs = ta.UnpaidLeaveHrs
	FROM #tblAttendanceSummary att
	INNER JOIN #tblSal_AttendanceData ta ON att.EmployeeID = ta.EmployeeID AND att.PeriodID = ta.PeriodID

	UPDATE #tblAttendanceSummary
	SET STD_WorkingDays = wds.WorkingDays_Std
	FROM #tblAttendanceSummary att
	INNER JOIN #EmployeeList te ON att.EmployeeID = te.EmployeeID
	LEFT JOIN tblWorkingDaySetting wds ON wds.EmployeeTypeID = te.EmployeeTypeID AND wds.Year = @Year AND wds.Month = @Month

	UPDATE #tblAttendanceSummary
	SET RegularWorkdays = ISNULL(wds.WorkingDays_Std, 26)
	FROM #tblAttendanceSummary att
	LEFT JOIN tblWorkingDaySetting wds ON wds.EmployeeTypeID = 0 AND wds.Year = @Year AND wds.Month = @Month

	UPDATE att
	SET WorkingHrs_Total = ISNULL(RegularWorkdays, 0) * STD_Hour_PerDays, WorkingDays_Total = RegularWorkdays
	FROM #tblAttendanceSummary att
	INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
	WHERE ISNULL(e.IsForeign, 0) = 0 AND WorkingDays_Total > RegularWorkdays * 8

	UPDATE #tblAttendanceSummary
	SET WorkingDays_Total = ISNULL(WorkingDays_Total, 0) + ISNULL(PaidLeaveDays_Total, 0)
	FROM #tblAttendanceSummary att
	INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
	WHERE ISNULL(e.IsForeign, 0) = 0

	--Người nước ngoài mặc định full công - trường hợp vào làm/nghỉ làm giữa tháng
	UPDATE att
	SET RegularWorkdays = ISNULL(RegularWorkdays, 0), WorkingHrs_Total = (RegularWorkdays * 8), WorkingDays_Total = RegularWorkdays, Std_Hour_PerDays = 8
	FROM #tblAttendanceSummary att
	INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
	WHERE ISNULL(e.IsForeign, 0) = 1 AND (e.HireDate <= @FromDate AND (e.TerminateDate IS NULL OR e.TerminateDate >= @ToDate))

	DECLARE @cols NVARCHAR(MAX), @assign NVARCHAR(MAX), @sql NVARCHAR(MAX)

	SELECT @cols = (
		SELECT ',' + QUOTENAME(LeaveCode)
		FROM tblLeaveType
		WHERE IsVisible = 1
		FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)')
	SET @cols = STUFF(@cols, 1, 1, '')

	SELECT @assign = (
		SELECT ',s.' + QUOTENAME(LeaveCode) + ' = ISNULL(p.' + QUOTENAME(LeaveCode) + ',0)'
		FROM tblLeaveType
		WHERE IsVisible = 1
		FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)')
	SET @assign = STUFF(@assign, 1, 1, '')

	SET @sql = N'
		;WITH lv AS (
			SELECT EmployeeID, LeaveCode, SUM(ISNULL(LvAmount,0)) AS LvAmount
			FROM #tblLvHistory
			GROUP BY EmployeeID, LeaveCode
		)
		SELECT * INTO #tmpLvPivot FROM (
			SELECT EmployeeID, LeaveCode, LvAmount FROM lv
		) src
		PIVOT (SUM(LvAmount) FOR LeaveCode IN (' + @cols + N')) AS pvt;

		UPDATE s
		SET ' + @assign + N'
		FROM #tblAttendanceSummary s
		LEFT JOIN #tmpLvPivot p ON s.EmployeeID = p.EmployeeID;

		DROP TABLE #tmpLvPivot;'

	EXEC sp_executesql @sql

	SELECT a.*
	INTO #ManualEdit
	FROM tblAttendanceSummary a
	INNER JOIN #EmployeeList s ON a.EmployeeID = s.EmployeeID
	WHERE [Year] = @Year AND [Month] = @Month AND ISNULL(DateStatus, 0) = 3

	DELETE t
	FROM tblAttendanceSummary t
	WHERE EXISTS (
			SELECT 1
			FROM #tblAttendanceSummary s
			WHERE t.EmployeeID = s.EmployeeID AND t.Year = s.Year AND t.Month = s.Month
			)

	SET @cols = ''

	SELECT @cols = (
		SELECT ',' + QUOTENAME(name)
		FROM sys.all_columns
		WHERE object_id = OBJECT_ID('tblAttendanceSummary')
		FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)')
	SET @cols = STUFF(@cols, 1, 1, '')

	-- Insert processed summary rows from temp table into permanent table
	SET @sql = '
	INSERT INTO tblAttendanceSummary (' + @cols + N')
	SELECT ' + @cols + N'
	FROM #tblAttendanceSummary'

	EXEC sp_executesql @sql

	SET @assign = ''


	SELECT @assign = (
		SELECT ',s.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ',0), ' + 's.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ', 0)'
		FROM tblOvertimeSetting
		FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)')
	SET @assign = STUFF(@assign, 1, 1, '')

	SET @assign = @assign + ' , s.TotalOT = ISNULL(p.TotalOT, 0), s.TotalExcessOT = ISNULL(p.TotalExcessOT, 0), TaxableOT = ISNULL(p.TaxableOT, 0), NonTaxableOT = ISNULL(p.NonTaxableOT, 0)'

	SET @sql = '
    UPDATE s SET ' + @assign + N'
		FROM tblAttendanceSummary s
		INNER JOIN #ManualEdit p ON s.EmployeeID = p.EmployeeID AND s.Year = p.Year AND s.Month = p.Month AND s.PeriodID = p.PeriodID
    '
	EXEC sp_executesql @sql


	EXEC sp_accumulatedOT @LoginID = @LoginID, @Month = @Month, @Year = @Year, @MaxOT = 40, @isView = 1

	IF (ISNULL(@ViewType, 0) = 1)
		SELECT *
		FROM tblAttendanceSummary t
		WHERE EXISTS (
				SELECT 1
				FROM #tblAttendanceSummary s
				WHERE t.EmployeeID = s.EmployeeID AND t.Year = s.Year AND t.Month = s.Month
				)
			--exec sp_processSummaryAttendance 3,2025,7
END
GO





IF OBJECT_ID('tempdb..#Paradise') IS NOT NULL DROP TABLE #Paradise

  create table #Paradise (
   [name] [nvarchar](MAX) NULL 
 , [IsEncrypted] [bit] NULL 
 , [type_desc] [nvarchar](MAX) NULL 
 , [ss_ViewDependencyOBject] [nvarchar](MAX) NULL 
)


 INSERT INTO #Paradise([name],[IsEncrypted],[type_desc],[ss_ViewDependencyOBject])
Select  N'sp_exportSummaryTimesheet' as [name],N'False' as [IsEncrypted],N'SQL_STORED_PROCEDURE' as [type_desc],NULL as [ss_ViewDependencyOBject] UNION ALL

Select  N'sp_AttendanceSummaryMonthlyInOutExport' as [name],N'False' as [IsEncrypted],N'SQL_STORED_PROCEDURE' as [type_desc],NULL as [ss_ViewDependencyOBject] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD' as [name],N'False' as [IsEncrypted],N'SQL_STORED_PROCEDURE' as [type_desc],NULL as [ss_ViewDependencyOBject]
select * from #Paradise
GO

--#region tblDataSetting
IF OBJECT_ID('tempdb..#tblDataSetting') IS NOT NULL DROP TABLE #tblDataSetting
  create table #tblDataSetting (
   [TableName] [nvarchar](MAX) NULL 
 , [ViewName] [nvarchar](MAX) NULL 
 , [AllowAdd] [bit] NULL 
 , [ReadOnlyColumns] [nvarchar](MAX) NULL 
 , [ComboboxColumns] [nvarchar](MAX) NULL 
 , [ColumnOrderBy] [nvarchar](MAX) NULL 
 , [ColumnHide] [nvarchar](MAX) NULL 
 , [ReadOnly] [bit] NULL 
 , [TableEditorName] [nvarchar](MAX) NULL 
 , [IsProcedure] [bit] NULL 
 , [PaintColumns] [nvarchar](MAX) NULL 
 , [FormatFontColumns] [nvarchar](MAX) NULL 
 , [PaintRows] [nvarchar](MAX) NULL 
 , [IsProcessForm] [bit] NULL 
 , [IsShowLayout] [bit] NULL 
 , [IsBatch] [bit] NULL 
 , [LoadDataAfterShow] [bit] NULL 
 , [GroupColumns] [nvarchar](MAX) NULL 
 , [FixedColumns] [nvarchar](MAX) NULL 
 , [ExportName] [nvarchar](MAX) NULL 
 , [CheckLockAttStore] [nvarchar](MAX) NULL 
 , [RptTemplate] [nvarchar](MAX) NULL 
 , [spAction] [nvarchar](MAX) NULL 
 , [DefaultValue] [nvarchar](MAX) NULL 
 , [FilterColumn] [nvarchar](MAX) NULL 
 , [IsEditForm] [bit] NULL 
 , [ColumnEditSpecial] [nvarchar](MAX) NULL 
 , [ColumnsFormatExtend] [nvarchar](MAX) NULL 
 , [AllowDelete] [bit] NULL 
 , [PaintCells] [nvarchar](MAX) NULL 
 , [LayoutDataConfig] varbinary(max) NULL 
 , [ColumnDataType] [nvarchar](MAX) NULL 
 , [ProcBeforeSave] [nvarchar](MAX) NULL 
 , [ProcAfterSave] [nvarchar](MAX) NULL 
 , [IsLayoutParam] [bit] NULL 
 , [ColumnSearch] [nvarchar](MAX) NULL 
 , [AlwaysReloadColumn] [bit] NULL 
 , [NotReloadAfterSave] [bit] NULL 
 , [ColumnChangeEventProc] [nvarchar](MAX) NULL 
 , [RowFontStyle] [nvarchar](MAX) NULL 
 , [isWrapHeader] [bit] NULL 
 , [ContextMenuIDs] [nvarchar](MAX) NULL 
 , [ColumnNotLock] [nvarchar](MAX) NULL 
 , [Import] [nvarchar](MAX) NULL 
 , [ProcBeforeDelete] [nvarchar](MAX) NULL 
 , [ProcAfterDelete] [nvarchar](MAX) NULL 
 , [ConditionFormatting] varbinary(max) NULL 
 , [ViewGridInShowLayout] [bit] NULL 
 , [ShortcutsControl] [nvarchar](MAX) NULL 
 , [LblMessage] [nvarchar](MAX) NULL 
 , [MinWidthColumn] [nvarchar](MAX) NULL 
 , [IsLayoutCommandButton] [bit] NULL 
 , [LayoutDataConfigCrazy] varbinary(max) NULL 
 , [NavigatorProcedure] [nvarchar](MAX) NULL 
 , [ValidateRowConditions] [nvarchar](MAX) NULL 
 , [ExecuteProcBeforeLoadData] [nvarchar](MAX) NULL 
 , [LayoutDataConfigWeb] varbinary(max) NULL 
 , [LayoutDataConfigMobile] varbinary(max) NULL 
 , [GridBandConfig] [nvarchar](MAX) NULL 
 , [ControlStateProcedure] [nvarchar](MAX) NULL 
 , [ValidationProcedures] [nvarchar](MAX) NULL 
 , [ReadonlyCellCondition] [nvarchar](MAX) NULL 
 , [ComboboxColumn_BackupForTransfer] [nvarchar](MAX) NULL 
 , [IsOpenSubForm] [bit] NULL 
 , [Validation] [nvarchar](MAX) NULL 
 , [ControlHiddenInShowLayout] [nvarchar](MAX) NULL 
 , [IgnoreColumnOrder] [bit] NULL 
 , [IgnoreLock] [bit] NULL 
 , [ReadonlyCellCondition_Backup] [nvarchar](MAX) NULL 
 , [SubDataSettingNames] [nvarchar](MAX) NULL 
 , [IsViewReportForm] [bit] NULL 
 , [ExportSeparateButton] [bit] NULL 
 , [HashLayoutConfig] [nvarchar](MAX) NULL 
 , [LayoutDataConfigFillter] varbinary(max) NULL 
 , [LayoutParamConfig] varbinary(max) NULL 
 , [OpenFormLink] [nvarchar](MAX) NULL 
 , [SaveTableByBulk] [nvarchar](MAX) NULL 
 , [IsNotPaintSaturday] [bit] NULL 
 , [IsNotPaintSunday] [bit] NULL 
 , [IsViewWeekName] [bit] NULL 
 , [IgnoreCheckEECode] [bit] NULL 
 , [ParadiseCommand] [int] NULL 
 , [Labels] [nvarchar](MAX) NULL 
 , [ColumnHideExport] [nvarchar](MAX) NULL 
 , [ColumnWidthCalcData] [bit] NULL 
 , [HideHeaderFilterButton] [bit] NULL 
 , [HideColumnGrid] [bit] NULL 
 , [TypeGrid] [int] NULL 
 , [ProcBeforeAdd] [nvarchar](MAX) NULL 
 , [ProcAfterAdd] [nvarchar](MAX) NULL 
 , [ExecuteProcAfterLoadData] [nvarchar](MAX) NULL 
 , [LayoutDataConfigColumnView] varbinary(max) NULL 
 , [LayoutDataConfigCardView] varbinary(max) NULL 
 , [HideFooter] [int] NULL 
 , [IsFilterBox] [bit] NULL 
 , [GetDefaultParamFromDB] [bit] NULL 
 , [TaskTimeLine] [int] NULL 
 , [HtmlCell] [int] NULL 
 , [MinPageSizeGrid] [int] NULL 
 , [ClickHereToAddNew] [int] NULL 
 , [IgnoreQuestion] [bit] NULL 
 , [FormLayoutJS] [int] NULL 
 , [CheckBoxText] [int] NULL 
 , [ColumnHideMobile] [nvarchar](MAX) NULL 
 , [LayoutMobileLocalConfig] varbinary(max) NULL 
 , [ViewMode] [int] NULL 
 , [Mode] [int] NULL 
 , [Template] [nvarchar](MAX) NULL 
 , [NotResizeImage] [int] NULL 
 , [DeleteOneRowReloadData] [int] NULL 
 , [AutoHeightGrid] [bit] NULL 
 , [ProcFileName] [nvarchar](MAX) NULL 
 , [HeightImagePercentHeightFont] [float] NULL 
 , [ColumnMinWidthPercent] [nvarchar](MAX) NULL 
 , [GridViewAutoAddRow] [int] NULL 
 , [GridViewNewItemRowPosition] [int] NULL 
 , [LastColumnRemainingWidth] [int] NULL 
 , [IsAutoSave] [bit] NULL 
 , [VirtualColumn] [nvarchar](MAX) NULL 
 , [GridTypeview] [int] NULL 
 , [selectionMode] [int] NULL 
 , [deleteMode] [int] NULL 
 , [ClearDataBeforeLoadData] [int] NULL 
 , [LockSort] [bit] NULL 
 , [HightLightControlProc] [nvarchar](MAX) NULL 
 , [ScriptInit0] [nvarchar](MAX) NULL 
 , [ScriptInit1] [nvarchar](MAX) NULL 
 , [ScriptInit2] [nvarchar](MAX) NULL 
 , [ScriptInit3] [nvarchar](MAX) NULL 
 , [ScriptInit4] [nvarchar](MAX) NULL 
 , [ScriptInit5] [nvarchar](MAX) NULL 
 , [ScriptInit6] [nvarchar](MAX) NULL 
 , [ScriptInit7] [nvarchar](MAX) NULL 
 , [ScriptInit8] [nvarchar](MAX) NULL 
 , [ScriptInit9] [nvarchar](MAX) NULL 
 , [FontSizeZoom0] [float] NULL 
 , [FontSizeZoom1] [float] NULL 
 , [FontSizeZoom2] [float] NULL 
 , [FontSizeZoom3] [float] NULL 
 , [FontSizeZoom4] [float] NULL 
 , [FontSizeZoom5] [float] NULL 
 , [FontSizeZoom6] [float] NULL 
 , [FontSizeZoom7] [float] NULL 
 , [FontSizeZoom8] [float] NULL 
 , [FontSizeZoom9] [float] NULL 
 , [NotBuildForm] [bit] NULL 
 , [NotUseCancelButton] [bit] NULL 
 , [GridUICompact] [float] NULL 
 , [DisableFilterColumns] [nvarchar](MAX) NULL 
 , [DisableFilterAll] [int] NULL 
)

 INSERT INTO #tblDataSetting([TableName],[ViewName],[AllowAdd],[ReadOnlyColumns],[ComboboxColumns],[ColumnOrderBy],[ColumnHide],[ReadOnly],[TableEditorName],[IsProcedure],[PaintColumns],[FormatFontColumns],[PaintRows],[IsProcessForm],[IsShowLayout],[IsBatch],[LoadDataAfterShow],[GroupColumns],[FixedColumns],[ExportName],[CheckLockAttStore],[RptTemplate],[spAction],[DefaultValue],[FilterColumn],[IsEditForm],[ColumnEditSpecial],[ColumnsFormatExtend],[AllowDelete],[PaintCells],[LayoutDataConfig],[ColumnDataType],[ProcBeforeSave],[ProcAfterSave],[IsLayoutParam],[ColumnSearch],[AlwaysReloadColumn],[NotReloadAfterSave],[ColumnChangeEventProc],[RowFontStyle],[isWrapHeader],[ContextMenuIDs],[ColumnNotLock],[Import],[ProcBeforeDelete],[ProcAfterDelete],[ConditionFormatting],[ViewGridInShowLayout],[ShortcutsControl],[LblMessage],[MinWidthColumn],[IsLayoutCommandButton],[LayoutDataConfigCrazy],[NavigatorProcedure],[ValidateRowConditions],[ExecuteProcBeforeLoadData],[LayoutDataConfigWeb],[LayoutDataConfigMobile],[GridBandConfig],[ControlStateProcedure],[ValidationProcedures],[ReadonlyCellCondition],[ComboboxColumn_BackupForTransfer],[IsOpenSubForm],[Validation],[ControlHiddenInShowLayout],[IgnoreColumnOrder],[IgnoreLock],[ReadonlyCellCondition_Backup],[SubDataSettingNames],[IsViewReportForm],[ExportSeparateButton],[HashLayoutConfig],[LayoutDataConfigFillter],[LayoutParamConfig],[OpenFormLink],[SaveTableByBulk],[IsNotPaintSaturday],[IsNotPaintSunday],[IsViewWeekName],[IgnoreCheckEECode],[ParadiseCommand],[Labels],[ColumnHideExport],[ColumnWidthCalcData],[HideHeaderFilterButton],[HideColumnGrid],[TypeGrid],[ProcBeforeAdd],[ProcAfterAdd],[ExecuteProcAfterLoadData],[LayoutDataConfigColumnView],[LayoutDataConfigCardView],[HideFooter],[IsFilterBox],[GetDefaultParamFromDB],[TaskTimeLine],[HtmlCell],[MinPageSizeGrid],[ClickHereToAddNew],[IgnoreQuestion],[FormLayoutJS],[CheckBoxText],[ColumnHideMobile],[LayoutMobileLocalConfig],[ViewMode],[Mode],[Template],[NotResizeImage],[DeleteOneRowReloadData],[AutoHeightGrid],[ProcFileName],[HeightImagePercentHeightFont],[ColumnMinWidthPercent],[GridViewAutoAddRow],[GridViewNewItemRowPosition],[LastColumnRemainingWidth],[IsAutoSave],[VirtualColumn],[GridTypeview],[selectionMode],[deleteMode],[ClearDataBeforeLoadData],[LockSort],[HightLightControlProc],[ScriptInit0],[ScriptInit1],[ScriptInit2],[ScriptInit3],[ScriptInit4],[ScriptInit5],[ScriptInit6],[ScriptInit7],[ScriptInit8],[ScriptInit9],[FontSizeZoom0],[FontSizeZoom1],[FontSizeZoom2],[FontSizeZoom3],[FontSizeZoom4],[FontSizeZoom5],[FontSizeZoom6],[FontSizeZoom7],[FontSizeZoom8],[FontSizeZoom9],[NotBuildForm],[NotUseCancelButton],[GridUICompact],[DisableFilterColumns],[DisableFilterAll])
Select  N'sp_attendancesummarymonthly_std_Datasetting' as [TableName],N'sp_AttendanceSummaryMonthly_STD' as [ViewName],N'True' as [AllowAdd],N',' as [ReadOnlyColumns],N'' as [ComboboxColumns],N'STT&0,EmployeeID&1,FullName&2,DepartmentName&3,HireDate&4,PositionName&5,ProbationEndDate&6,STD_WorkingDays&7,Actual_WorkingDays&8,TotalPaidDays&9,WorkHours&10,PaidLeaveHrs&11,UnpaidLeave&12,IOHrs&13,TotalOT&14,TotalNS&15,TotalDayOff&16,A&17,P&18,M&19,M1&20,S&21,S2&22,SP3&23,O&24,L&25,B1&26,AWP&27,OT1&28,OT2a&29,OT3&30,OT4&31,OT5&32,1Att&33,2Att&34,3Att&35,4Att&36,5Att&37,6Att&38,7Att&39,8Att&40,9Att&41,10Att&42,11Att&43,12Att&44,13Att&45,14Att&46,15Att&47,16Att&48,17Att&49,18Att&50,19Att&51,20Att&52,21Att&53,22Att&54,23Att&55,24Att&56,25Att&57,26Att&58,27Att&59,28Att&60,29Att&61,30Att&62,31Att&63,ForgetTimekeeper&64,Signture&65' as [ColumnOrderBy],N'isReadOnlyRow,dtftxxENGColumns' as [ColumnHide],N'False' as [ReadOnly],N'' as [TableEditorName],N'True' as [IsProcedure],N'Saturday&%Out&%In#CCFFCC ,Sunday&%Out&%In#FCD5B4,DepartmentName#e8760c' as [PaintColumns],N'' as [FormatFontColumns],N'' as [PaintRows],N'False' as [IsProcessForm],N'False' as [IsShowLayout],N'False' as [IsBatch],N'True' as [LoadDataAfterShow],N'SectionName&SectionPriority' as [GroupColumns],N'STT,EmployeeID,FullName,DepartmentName,HireDate' as [FixedColumns],N'' as [ExportName],N'' as [CheckLockAttStore],N'Export_AttandanceMonth,AttendanceSheet,SummaryTimesheet' as [RptTemplate],N'' as [spAction],N'' as [DefaultValue],N'' as [FilterColumn],N'False' as [IsEditForm],N'' as [ColumnEditSpecial],N'' as [ColumnsFormatExtend],N'True' as [AllowDelete],N'' as [PaintCells],0x1F8B0800000000000400ED9DCF6FDB4896C7F7BCC0FE0F8416989337AD5F96E54CDB8863C7B181C4096C25764E034AAA488429522029FFE86B1FE6B8E8C31E06734963D187E99DC1CE6EF7C93EF441C1FC1FFA0BF65FD8E20F59B44C8AAF8AB22591DF07231DA7F94A64BDAAC7579FF754F57FB7BF7D7BE658EA09B33455D7BE639672C12C5B338DAD42E959B1A0A8FDBEAEB554C7FB97DD81ED98BD37EAB53970764DC3B14CBDB0FD2FFFAC28DFF62DB3CF2CE75A31D41EDB2AFCAB7FCD47BFA982F24DE455EFFA6EB3F6BED91AD80545B38D81AE6F151C6BC0DCDFCED975F08BA7FC507DA7E56817AAC34E98CE5A0E6B0777F4CE786D3A7E9BDBAEFAB7DF8CF5E2DAD175F3D253B86BE18DDA64FA2E7FF0F3C2F66755B7931B7965A84D9DED0C1CB3A136DF596D66C97FFAF8C1DABCA9F76A8751EF61D2D46BCB1CF4C59F9F7F5E93B525958F99DA360DFDFA555B734C8BAAFFD6BC60BEBAD6E93A0DF30DFBEC509FF74E774FB3F8087047DAF64ECB326DBBD165C69E79694C3531FDEB547B6F4CF37CC768EF33A64B0CC79373CD38E27F2B6CEFB18B57577D8BD9B672E25CEBC90FE25D55D8765B48BCF683CDF6D86775A03BE1DBA57536D73DD58CB679699FBDE75DD48B195909DD74E8B09E7DBF4B940B551FF0FF55AEC6F58EAB5422F4EA43CDC6759FF9FDEA3B156F783E78D408BDC9607EAF5ACC70BC46025714A5E05DFAD274E7AEFD51B3B5A61E3BF362E6C19EA55EBE545BE71DDE92D18E314A9CEF3834DAFC26ED53CDE9F2A70CEEA3B0DDA0B511F852B79B1BECCA21F574449F71D5861938A23DCD7654A3C5152A113710ADBCA36B1DE3ADD9E64A7CB0F9FD1EDC5AD443243FD7AEEA691FF6B81FBC330AB15FF75D934C5C83EB5A1AA6E76708CAFE60F31FE5987506BA6A09DEEE1BD37F6FBA0EC19BB082FAEE80B82A6CFF5B893AFCFC31B36BEAA6F55267465B333A82635060CC5EF555A3FD8E7BD901D79BF9AA8C5316F8B4B1C7F36CE23A84C2368F2D1C1E98E804ED93AE7919BC4A7775D3662F078EE39A45686E1F383DFDC4B1789F1E1A8195C8B7EF35F05ABFEE775D176F7876A18F8960FEBCE79F2D3BAF77FA7DA65AEE64F69CDCF8FE698D454C2CD362DE300BBBD3A80B432332F152EE37C52E2C275DB9CFFD187FABB28EC9940F876B4AA9D88FEAEF28D5D796DAD6B8EFF2E7FF816969DFF1C622475BDC279FF0687A8FE98E5AD82E8AA8B9B140A017EF77227D67CCC0F306CE3DBBC78D5BF20B21D227CDFA78818F9C8C55F76586319AF9317ACFDEE36525CC9E2BB30BC4ACB079466C8E28249366A747B40D77C9115AD44B06B7C77C95C73E6B86E6351A0D268AF7ADF460D965EA839E21D60A65E1C13BBFB0FDA2BA76AAB59DEE56A9562EBEA8AC1D307709BAB559D9242F95FC158B3094082BFB63E8C8B47AA435D30153F99CF1556D9995AC67D1006C1D1A5D66690E6B53B04D74C4193578A35427B7DA30299468E292C6B0556E10FAFD95375F567FB69E6D671667680FD153C70ACCBDEAE6E67EC8C76330783E0C7E603A0D8B771B4C9E0393FB60D87D10183B63C6168A00D32C42620600D9FC44E3534D2F6FF854669732BABCC9695960777A7B0B30DA2A22589CFAB52EDA77AA00A388E4DF7B963A33DD13AB66F667AEB76496D902443D62951D24246956E4D79FF0D567619B962AF057E0429FE0ABC47F88400F99A6DED064A7FE9DF6AC09185CD4D01C9D91AE3C6C99869FE93C320D5AE6E4B0D7636D4D75D8F88E624141CC989BE438C506AC77AF945E085D48E889D0D512BD115455846E8D9E8372B5D2F4A6AB2FD0A384917AA4BA1530C7A649612F69386BCC14918E8C3ED8CCE532E36666D880F66E58EAD76CF849653BEC94DFFBA9A5F2F1E6FE99A6AB88DC39636F7C5AB1976B29619ECADF352D6F2A17D794E0877443EDB6B8D60464BE28AD9D6D15F99F9FB6288A6EB5CBA1712F7CE1B3A6472E56F15271D12FD4E917F0F467D0554F1CD5728ED8E51BCD10E87FCF609AAE39D785ED1DFD52BD7E5854965803E97AC4F25C0A110346ED3648E92CFF6ABF8156F3EAC55BFE0FDDA7A83E9AAACB736B94DD194ACC5FF0FBB61D4BD50CC7F65FC0F4148057C536DDD5F15352B8E8CD53F09EACE7AEDDB7DF6AED368F74D967F2CD354CB773265986754AA75C74041F6CAC11A4834A413AC89DD2412E48605D92A60C0CD53C8477FF3CF94AD673BD89A127AA79F2687654F3E4CFE6A8E6C9A4D90981C95BF5EA4164531E4736154A68F356338216CA410B9B1B824D046F9A5034D830FBC450D0D5E52AA25F2F39E077A7BB77E87D078DB5BD0047203C6E585ACF4F3BED584CBD8BCBC89F3FBE6DFE4FA1C716F8AE89AFCF07E27752FAA25F1999CBB72080E5EF37062C1F771FC0F2C0F211FA8F81E5F5A6FEA247C5397364F34B4EC341A0C9199B7B385A80EB4D854D95DA246C2A6D10DB882042240E960E8657D694E0470C8657D6CEB6CAD5121D87FB3D5419F75031D4451512AA9E0B4F6F74873F1A1D79A8EEEB3F5F245A8F7EB4E4DA701292AF2C1AC9371DE398E9A64AA95107920792079207B059466003240FB303C9C3E640F25935BB1092BFFBEEE966B9CC7F19AF0D8BD5B21497AF87564F65CA02135C1E5C1E5C3EF921C0E5A32E029707974FC7E5E94C075C3ED14E39E7F254961A02F3926029C5261829B17C890F07FF471CCBAF573764B17C69733158FECDF04B4F793BBAFDB3268FE645BCCC6AC2F96A4A38FFAAD777AEDD81C988645E7ADACD65E718E1507D155728B28B32990C42AA848070FA412683F070A55B0A15B19548456C116570424E3F9C8E22F7EFBC5351945D9B235C798A9414923748DEC4DF66BED01E9237303B9237B039923759353BF207D16118F207F71B43FE20EE3E903F40FE2042FF31F2071A9FBF94A5247207C936CA67EE201DA248C9F2CB6B4AF023C6F2AB6B675BA562B12E0BF3CBB5F585C07CEA748DE1F854F5C5EE5DB3BE8287E88904928F71869E70348A63F4C27E14C7E8E1183D8663F4708C5E3E10CDAC4C0D8ED1C3185DD2318A4411CC8E4451FE6C8E28249366974A38E4F118BD629DBC54C2317A38460FBE6C195E61793E452FAFD6CEEB217A79B5777ECFD0CB9FC5F37B845ED66D2D14FCE5E804BDBC143EE0003D54F4A1A28F38E650D117FAE465ADE8231502E0043D9CA097D757FE53ED937057DE2854A838A7E3F4CA6B9F9EBA3631C5997A54F5C5D626D616BD896FC76A7BC1DAABB6E698944233ECE43B53013BF9E2CBE094A000E425560D353E303B6A7C60F374531D353E59343B213049BDABD06467A3BBBDD6C247A0946BF4181B9BF8E24BF840F640F640F640F64F87ECF5A62EC874F06DFC446365885053D168EEB6F2953D612FC4C749C86EBA3ABB549D5467D76B944322E683D87FA73BBF6FB99366ABC5833FDB347ED7717E7F34BAF96DA0385DF55AF9FAC3E8F63F34A5D51DDDFEA5A5B455A3CBFF7DF857A539BAF9A9A75C0CBF984A7BF8BF4647E9B9FB017B977FEF5EF173EFD95167F8E55AE96AA3DB3F0E147D74FB3F2DE5BC3BFC955F6B8F6EFFA6F26BFFF1F7D1ED7FB61463F8B3A118DE671A0F756C55F33FF26AF88B1A7C98FB6F5F7FD0D6F85F06FC2FC35FFC8F544AF76EA6D535DDFF7963749EB98FF98DF79CEEF3C9A71484FDEA6AEE5DBCB1E89C8473E5EC6BBAC3908E98BE1CE908A423229A01AC5A4A58857404CC8E74046C8E744456CD2E998E986CF526998F28D504DB403E02F908E423921F02F988A88B908F403E225D3E82CE73908A48B453DE531102646FEA88AAF5D036BBA54DF95C0489842D321721B80FF15D2AA2520B47A7A4C79C4B26A231FC6B4F39D74637BF916871349F176B6435E17C7DD170BEE918AFAEFAA645094A57FFA835407A407A40FA2C231C407A981D901E3607A4CFAAD953437AB1E390275F1A2809B601480F480F489FFC1080F4511701D203D2A780F4425C07903ED14E7987F4F8BEC094D6F471812E6A973D2E70BDBA104A7F3618DDFCE428ECAAC5285BB9C7607A114FB39A907E73D190BED5BC7AF189910E8E43013DD83CD83CC8CD32921BB079981D6C1E36079BCFAAD953B379B102FA711D587D13F5F3D4DB6640F340F340F340F340F304FD47AA9F7F714DA43920F38966CA109997D96B5EBE7ABE5C0F55CF5376A9C949F5FC1D96AF862B3E9E6EA7FCA3AFDFA7A89A77B59F6716C5978A8B66F177E98E673B0E0F88DBEE1C38E9328602FAB8CB01E901E9239A01C2594A8403480FB303D2C3E680F459357B6A484F09E4220AE82B75C13640E941E941E9931F02943EEA22507A50FA74945E9EF300DB27DA2DE7D83E0FF5F4253E1CFC1F316AEFD5D357EB6559702F1E69CE07DCC7BA8CE71F8FE4817E1A47B4A290BFB43C90FF64D0EBA9D67543EB311B947FC6E5A0FCA0FC11CD80012D250302E587D941F9617350FEAC9A7D5194BF5605E5A7DE3603E507E507E507E507E527E83F2EE597013DC0FC898603E607E60F6B4D63FEF24645BA3EBFB8B960CC3FED33E6C4F9255CD18A82FEF2A241BFBBB38E1FB37CD4D825E03EE03EE03ED08F64F8B22CE807701F6607DC87CD01F7B36AF6D4705FF2A0DA4A191BED506F9B01EE03EE03EE03EE03EE13F41F6BA31DD31BB31744B803A09F68AC9C037DF9ED76362AF339AC96B205CE82B6DBA9AC9D6D6D54E5817E6D7D21407FB73BBAF94DF9FAC3E8F64FCA158D21C722FC90C3A165035694DC57164DEE9B8EB17FBAD36E83D983D983D983E8484628CB4274C0EC6176307BD81CCC3EAB664FCDEC716E2D983D987DD49380D983D9D3C61C98FD92337B11AC035A9F68A60CD1FA7BAF2B516C9F873AFC856C925F2AD626E165F5E9987DA33BFCB9A7F446B77FD6E479BD80B359514C5F5D0A4CCF5D0173C8712D483D483D483D384EA2FA92E23B90FA3C9A1DA43E7F3607A9CFA4D99F98D4DF9D625B01A8A7DE3603A807A807A807A807A827E83F1AA8A7831DB0FA444B81D583D5476A85587D79ED6CAB561385F57711667D21ACFE6CF88BAA3447B7FF9E92D493BDCD8AC2FAF5B9C0FAD79639E853EE5C6D3659DBBB3A347567205DEF52DFABDAC293751C7F5EBA6EB4C35B32E84174F0FAE40199E1D8A79AD3E54F19DC8744342D086B883E236A1ECF253D419832FEDBD4C3EDA2EBB97DD72A9AC55AFEF875178F0DF3D8751014BFE48D37FF5166BC3A66DC6EF2CC99AD2F9239F14660282878A933C377C642C35060D85EF1F540FB9DB1670EB81E5FF5B6CEE9F3C55716F8B4A0037D9BF8F1E9CC1022CAD57397F09EF7EAAE6EDAECE5C0715CC3084DF034A9BBB92C95D3648A2631AAE7E900F7EEFBB28CC0BD9881E70D9C7B76A72FD19062C4187DEC318A1423CC8E1463FE6C8E28249366974A9978E1897CCE8407D39AA1798DDE57532E547DC0AF29CE069B7E9243AC153AA39AECEA5C164C83FA4B257FBD22CC25C2CAFE083A32AD1E69C574C0543E637C555B6625EBD9D31B4485ED43A3CB2CCD61945AD414D8F23EAE6A981450347148C1FA507208FAFD054F16ABBA929E2CCECE3B2D47BBA00E15587BC5ADCDBD900FC760EF5CD8FBC0741A16EF35583CFB16F791B0FB20B075B66C2D14FCA5597DA06443D6E6F216A7A580DDC9ED2DBC68EB0754244636868AC4B8FB4045222A1223F41FA322B1AF77F64F77CD5E4F359E7AFB8060AA48C7471F6CE692997133336C417B472CF5DB36FCA4B21D76CAEFFDD452F9B873FF4CD355F97CF33F79B166CA7A4921AD077B1B54D63E6DD52BF5272B78DCED8E6EFFD2528CAFDF1B1DC531875F0CB7FCF14F4A6FF8E3B5D2EA8E6E7EEA29ADE1AF4647BE2052D0D93D5A4524ADB2B1B6E86D080E7BDEC98AFE7FDC83154FA867BC6247024AFBD891003B1250420B609C5835940BC1EC281782CDD34D75940B65D1EC84C064B223817C25CDC3DD83C5DBC0A604D894002980E487400A20EA22A400900248910290C73CD89F20D1681942DE82F414DB13CCD29AD756C2E2B1E67C687DB4D3A09DDE1743E7A5FDD08AEE5CB0B168BEEFED0F71CC6C30FDD8CBC1F4C1F4239A01F1594AE203A60FB383E9C3E660FA5935BB10D3C72EC3B904FA429B2F81E883E8937B08441F447FFA939791E88B811D50FC44436588E26397E1B83E4A89F12B6B675BE5A2F036C313905F5B08C87F33FCD253F4D1CD8F698F04A4FA9B15A5F5F5A5A0F527EA058E048CBB1CB01EB03EA219A09CA5443980F5303B603D6C0E589F55B32F08D6D74A80F5D4DB6680F580F580F580F580F514FD4783F554AE03569F6827B07AB0FA48ADF995DC2F88D4FFE3EF83948C9EE8665614D16F2E01A2F7BFBD00440F440F440F802319952C0BC001A287D981E8617320FAAC9A7D41887E7313889E7ADB6CD1881E1BE480D04FAB80D083D0CFF01A9923F474AC03429F6827107A10FA48ADA96AFA5AA92ECBE86B65D120753E8CFEA83BBAF95B5FB9187E3153A17AB2BF594D545F2ECE05D57BA76B51EE5C6D3659DBBB3A347967205DEF52DFAFDAC2D3751C7F5EBA8EB4C35B32E84174F0FAE40199E1D8A79AD3E54F19DC8744342D086B885E236A36CD253D419830FEFBD4C3EDA2EBB97DD72A9AC55AFEF875178F0DF3D8751014CFE48D37FF5166BC3C66DCAECC59C7617D91CC8937024361C14B9D19BE3B161A8602C3D63B10FA9DB1670EB81E5FF5B6CE454F9316F8B4A0037D9BF8F1E9CC2022CAD507A7B8EDEAA6CDFCD3A80527789AD4DD5C96CA69324553071402EEDDF76519817B3103CF1B38F7EC4E5FA221C58831FAD863142946981D29C6FCD91C514826CD2E953249736EF6315FE7B1CF9AA1DD9D963951532E547DC0AF29CE469B7E9243AC153AA4AA0690AA54AED4052995BF56F2172CC26022ACEC0FA123D3EA91964C074CE553C657B56596B29E41BD5154D83E34BACCD21C46DD455C925CDEE7550D93428A261E2958204A8E41BFBF72E7CACACFD6B3EDCCE22CBDD372B40BEA6081BD57DEDEDC13F9840C16CF89C50F4CA761F17E83CDF360739F0DBB0F026B67CDDA4261609A85C8AAD56FC45B3E95DDA5AC2E6F735A3ED89DE0DE2A8CB6964079626463284F8CBB0F9427A23C3142FF31CA13FB7AE70F2207B3CDB34431982BD241D2079BB99866DCCC0C63D05E124BFDC20D3FA96C879DF27B3FB5543EF0DC3FD374158A379FA4783365FDA490D6831D0E2A6B9FB636EAD5272B7F745DD1E7CB96EF8A9E5F503A35A60652D4A93D5A1D24AD9EB1B4E8AD075AE7CD57576ECDE809EB73E7EEB07D4DC74EC17197631B8284E017DB10AC12B2C97806393184458D501ECD8E1AA1FCD91C354299343B213099B90D4199F2EDB2C93604E36F89956A1B826D601F02EC4300D09FFC1000FD511701F403F4A700FD7A5397633CD89320D166C0DAF9D993A0C4C785FF23CBD4EB354AB0F8A0DCBB16DAF6AAFC749B1244FA8DE71F8FE4E9BCAC275AD1DD0ACA8BA6FBED76F3B8EF3458AFAFF3CEA63C3EB83EA97D707D707D4AD802EA13AB06AE0FB383EBC3E6E0FA30BBC4CA7536D72F0B71FDF1F6C2E5BA6013C0FAC0FAC0FAC90F01AC1F7511B03EB07E0AAC2F017700F413AD05A00FA01FA91502FAD5B5B3AD52B5B629BACBF038CE5C2F2E84E7BBB05DE98D6EFE6BA018FE7EC34667F8ABC1FF1CDDFEB73CD417F7432B8AF32B8BC6F94DC7F0D327CFFCFFFC61C7E193A5EDCE97B7FCBA2EF83EF83EF83EE88F6434B32CF4077C1F6607DF87CDC1F7B36AF6B47CBF4209E422EAF6AB25C13600F801F801F8931F02803FEA22007E00FE1480FFAE5A3605EE01F14F341F883F887FA4D6D4B182F5CD0DD96305CBD58A60E039E70AFE180F329F627E79F7B4A28980EAA21301ADF3E68B8F1ABB7C6F994DEF89DE334B33499BB8C5F27F91E98F0400120089EE1C0900E0212400607624006073699B23019049B3A74D00C86EDCB359C6C63DD4DB66480020018004001200480010F41F2901F0E2426397FD31E6E993310FB87FA2D5C0FDC1FD23B522B7EE295749146F2ADEAC2FA6D23FC671A4C5FDF26D2E3BE8BFF7EBB7DF9C39967AC21F4FD5B93DADED7F8240201008040281402010080402814020100804028140201008040281402010080402814020100804028140201008040281402010080402814020100804028140201008040281402010080402814020100804028140201008040281402010080402814020100804028140201041F97FCE1C7ABBE0FF0200 as [LayoutDataConfig],N'Col1&ViewHTML' as [ColumnDataType],N'' as [ProcBeforeSave],N'' as [ProcAfterSave],N'False' as [IsLayoutParam],N'' as [ColumnSearch],N'False' as [AlwaysReloadColumn],N'False' as [NotReloadAfterSave],N'' as [ColumnChangeEventProc],N'' as [RowFontStyle],N'True' as [isWrapHeader],N'' as [ContextMenuIDs],N'' as [ColumnNotLock],N'ImportTimeSheet' as [Import],N'' as [ProcBeforeDelete],N'' as [ProcAfterDelete],0x1F8B08000000000004007D8FB10AC24010447BC17F38D6564CAECF052BB1B032106D97B898C34BEED8EC45E2AF59F849FE82C1602188DD30CC1B669EF7477614C682D8A2B33762D51377D6B706F42A058521385BA1BC9DD2D215F2F94CA92CB00FC432A8161B32B0D8E1E0A394130B2AF9972A2A74B4C14A3C43BED6CB833D496DF4A8B664CFB5189D251FF267CFC67383B28F8E3A50B6BBD060403812A81E5D1C03E9B4204BBEBFE52FA791B64FEF000000 as [ConditionFormatting],N'True' as [ViewGridInShowLayout],N'' as [ShortcutsControl],N'' as [LblMessage],N'IOHrsFIX&63,UnpaidLeaveFIX&63,PaidLeaveHrsFIX&73,WorkHoursFIX&74,TotalPaidDaysFIX&79,Actual_WorkingDaysFIX&79,STD_WorkingDaysFIX&63,ProbationEndDateFIX&105,PositionNameFIX&98,HireDateFIX&76,DepartmentNameFIX&134,FullNameFIX&180,EmployeeIDFIX&73,STTFIX&47,DepartmentNameFIX&134' as [MinWidthColumn],N'True' as [IsLayoutCommandButton],NULL as [LayoutDataConfigCrazy],N'' as [NavigatorProcedure],N'' as [ValidateRowConditions],N'' as [ExecuteProcBeforeLoadData],NULL as [LayoutDataConfigWeb],0x1F8B0800000000000400ED9D4B72DBC81980B34E55EE8062AAB2626C91D47366A4926C59B6AAFC2A8933B69710D1925006D12C107A799B0BE408C93A39C1CC621633179913E40A69009444C900F103944512F8BE7252231B7FE3F1371A8DAF1BADFFFDF2EB0F1FC3C03E54816B7BEE171558E72A18BADADF6CB49E2C352C7B30F0DC9E1DC67FF3FC6C18EAFE6BFB4A9F85CFB51F06DA6B6CFDE5CF96F5C320D003158457966FF7D566E3AFC9363F254535ACA7A95BBD1B44C50EF774EF6CD8B0DCA17FE6799B8D303853D14F9FD5D5E88738F8EBF09D5EE89EDBA13A549EEA85CA191DD13BFFA50E9332B7A2F01F9E5EC76595E379FA220EB829E1B57DA4BCE7E6C43F37B68E6D6F985FC80BDF3EF2D4CE59A8BBF6D1BBC05141F9BD5F9F98638A7A6F9F28E931DC16F532D06783E2E76FF677A49C92C107CA76B4EF5DBD70DC5007D2F837FA5C25E1EEC969D8D5AFD571283DDF9BD85D37303520AA695B3BBD400F87DD53E5EFEA0BFF5E11F77FBC57DE6BAD3FEFF8CE9E525E89EA78F8D9F5DF9AFF6A6CEDAAF3179783400D87D66178E5E59F48BC55632B2A2177DB1F876A571DDB675E387EB8B28B6D623FB8BEA32F861FDF9B4BD4CFA8593997693F54FDE1DD4B629DDBDE99F9A7D67AD6D589825A82ABFA7564F76AA092EB9A342A71F5FCEA5453E26E2BF37B3B507E1817326A8AD202E24D9FE9E8DE1DFEE40EDD232FF3CECBB80F7603FBE299DDFB7C624AF29D8CA464B51DFBBE630E72F8C10D4FCD598E8EA3B1D59595316A4BA3CBDC5597A1E84AA75C3313DAD5A38668D71D86B6DF33019D9403480FDEF1DC13FF8D764C90A96CC9751F1D5ADA49E49FD7733B8EDEEF9B76F02629C2EBBA17A5E4B669889A96AE8EDB19417052D99253395027679E1D143CDCD73A796E460D427CC3168C8F2AC46563EBEF2D69F54BEACC73EDE9E099A77CC7F54FE41538A984052AEDE5C0F69D77A6993D3371139F9559C105F676DDE4C549895A84C696E95C84A667E209A20F4FF5C5E859FADCD343F5EC2C0CA3BC14BAB95F857DEF300CCC45DDF74769121F7E5CC04BEF6A701AB5F17E9C1879A518DD40EFCDBECBDED83B8381B283E86E8E5BB9EBE39715967267E940C5F56CBC3D4DDB70AC4AE66E6A1ACE621BB6F3B6DC330D9979ACAA13ADAC1FF79BD6FA939541DA054F8B7D19D88E6B5AAFA40578A503F78B292DB5BA65EDFAD0F4A7779517DA8DADA52261516F601497DDF2A4B69E19352FAE3977129F5571C58F84D45669D2EE0BECF2B6B2468F332A69F52BE99D845FBF59D62CEFADA57AA7BD40B7959C5724E7F443AA997779A7B61BBD758CBDD897ECDF1E98373D75ECFA6E5C68BA9C58BA9BA6AF5EBDB477D6F78B952279F73017BFB1B5BDDCFCE03AE1E9666BB5B3BCDD69BE52D16BE8E6C6F2BAF86D297969292C26C683933AF456077DD16BD32B659B9B26091D96799B8D333A925BFBFEA90ADC5039127593DEE74CABBC69A1B787DAD5125374DB265D0BD7729530B95E3466D9B10BD99865253AD6F4D2BA42BA173DDDA61D4A0C1909AF47C25FE9B01B98CB46CA6B90F2C40D472742B22B96EC423DC0695E42322A8038FDC2E44B535F3EF153A5BD54D2CBA75C36121CDDDEF10B98EC2D62F4729ACC7771BFD8052445AA01DF0DEC89233E99617A30F17DABCC6B7601A79EF2963D1A949465D16C7F68DE3E1B5BB2C182E40DBCD01E9290EC9D14B8425A7B5DB7ECAD7F133DE9061C6DD475434F89B6DCEF693F19EC7CAB7DD9D8C97EBFAF1CD70ED5F511658A828C3A773BCC59ACC2C6C72AB90A631B0AAEC4D8D625AEC66866C5D8A1C947A1A2A869AE66145FE08A0A6AEA5B3B9A0573A0B5C4BD4C235A17FCC19669D52BF65C934D6B8A8C58616B685AD45E5C61979AD6E88FE8801CA778D4ADAEDB6E353F6E2E99FFFFB429098CA675ECFB771ED2A6A6F6C5B332E211279382A11BCDBCB2CCC14773F624B374EEEF3229493251E730B483F0ADBA78EDFA05D211E7CFF5DCF0AAB1B5E35DD8575F1F65EEE4BFA819683FC80CBC91988D0A945CAC64EBA48093C089BB22C924D1C7987A736F565A344337BA6B85E6DE1CFC300C6CD70F87C9A3472EBFE3395CF7AF77F66D5A78CA571C109F593F7A6BDD7AE33A8EE9E3A963F1C1757574716EFDFA8AE4A29C9F143CB1EB88D140486B341012DDE6A35190023DF269E640319345F00CC62C309365DABCD77D56033359EA977366B25433EF82AEC91BFBF2DE248FCEFA72BB58F7E68DEB8FCA688FCA68B7CD7F8E4A68B7E5FDECB11E61570F84DDC128D68414FDC0E295393A2F3AC2F82B2CE5C49D9C025DE46EE0F69341979D40D9377D33F1FEAF0FDBFCD5D86917F8DA22893755F14BA9F8A2DF4C3CC8670048E9BB8521A5B38E03298D944E89FF1652DA3BF20A7A1DF4746EB2AAA3A7A58316A55C7514349D5C9A62BEE994A2BC65AA43F2A78C286F373F6DAEA47D9C9BA632332721AF6E6C3C9A6CFF9B177EDF8BEE196BD3EA99DEDF50FB7F3B09BFB7F68F2DD30DB07AA7B67FA2ACF0D4FC2F6A869B562FFAB0D4D2BE655BBEBAB03CD737FFA423576FB9E113AB6BB654C7C72A9E8A6939A651B47AB6EFEBD03A32FFE044F38D9BD6505BEE715CE8BD4DDDA1751168FFA46939CA5361B2E3F86FE21D35A39FFD785F77F7DED341F455F1132B3A9DA7F1F94467517EE4A070F3F9CD8611D213973FF95B34FCD099F5F043EFE872FB93127DC9CDC003030F0C3C60A5E6D24A31F0808466E0819C33F050D9BC971F78B81D36582D35F2B052B408461E187960E421FF24187948DB889107461EA61B79D8BE122A1DC61C72D3C49803630EE35163630E9DE6C7CDF5D69A7C7A7E727D3AA3EB138516EB573ECC9083D0F76698F9B7BFFFA3FF5D6585FC322BF2A6C64E5C91B770BFF9DB2CCA9B26CD734721589497457927074FB728EFC40E435AFBCEB2BC2CCBDB6A575DE665543DD6E5A596CE772D65549111264615EB97737A22154D7CA931921AAECCDBDA90182A56E665655E5AB3797A8CD57969DEFAE6BBAE6BF3D637E3F55D9CB78E39AFEFEABCD5CF76A16E608D96E79D90F9A9F25E2AEBE5732E1B17667D5E2624E65C2126243221F1FE9EE77142E2C03BD9FBF05CF7FBB62F312A4C4AACFCF3EDB12625CE74D1DE4EF3D3E6DA8A64A1AA795BB6B7E00D3BDB157C5766FD09FD51E8EF7DD871444DDB037F422F99BC763F597C4A9F7251F8949E592F99875937FF90DB2563D64B1DD3CEAC97FAE59C592F154DBCA07392FA31FDEAED174BCBE596F1DD285A041FD3F3313DEE3AFF2470D7691BE1AE71D753B8EB2272076F9D9BA60A79EB8292B4761FD5779AD6E84F1979FE109FD48B7A970FE3DE4D0B11AD875B5EB917686716F3C3FAD5B9D0F487F6F9A37C478BA7CF0DC6D3E3E9713878FA874F7CCD9D2D9EBE7E39C7D35734F1B3F3F46B6D3CBDF4B0D5AC3D7DA1058210F5887AF11542D423EAEFEF796E45BD54EF60EA73F384A9C7D4A7457DA3E56F1FD1D50B1B8949A25E58C4629AFAB5B930F5BBF1EF1FC4D5E3EA71F5789CD23D9379F138B87ABC2DAE9E9CE3EAAB9BF8D9B9FA755CBDF8B0D5AC5D3D73EA51F5F74350F5A8FA09AD460555BDDCEF20EB733385AC47D6A7457D35ADBEDDFC2454EDF3E1EAC5ADC4245B2F2E64317DFDFA5CF8FA033554928E29BA5E543EBA1E5D2FE991A0722684A1EB1F3AF13557B7E8FAFAE51C5D5FD1C4CF4ED7AF157D9942D733B51E5F2F38097C7DDA46F87A7CFDB4BE5EEC77D0F5B98942D7A3EBD3A252E6D62F9AB0973613937CBDB48CC5D4F51B73A0EB5F5C0E7480ADCFDA1C5B8FAD4F290693931B3EA70A0F5B5FC7B463EBEB97736C7D4513FFF8B6FEFA55AAD56176BDF8B0D5AC753DB3EBB1F5F743B0F5D8FA09AD46E56CBD5CEF20EB73F384AC47D6A745A5CEAD5F2FA0EAAF3BA9ADD5CEF24C5C7DD24C58A1B6D4654FA55568B9B51737398B29ED5B4B7360EDF7FB58FB099B63EDB1F629C52CA8D159AFBAD041DA237091F6E4BCBED2BEF24D7C59673FE6DB3BABE59C7D6BA96019387B9C3DCE3EFF2470F6691BE1EC71F6D3397BB9DCC1D9E7E609675F1B67DF32D522F953C6D9779A9F365BAB534B7B510FF361A4BDB89DC876F5E22216D4D5B766EDEA1DE7E8601076557FE099E78CE4F431F6A2F231F6187B49BF049D931D86B17FE0BCD7DDDE62ECEB97738C7D35F35ED6D83FC42CFB16B3ECA587AD30F6187B8C3DC61E632F88FF16C6BE84E2C1DBE7660B6F5F1B6F3FDD5CFBD8DBB71769B2FD4B155A8978B7AE5B0D6BCFF5A658DBBE7813B4A03EBF3D6B9FDF3BBADC7E63FEE27406267FE72CD4511DC6E063F031F8E81D0CFEC3E7BDEE3617835FBF9C63F0AB99F7B2067F6CCE7DBBD89CFBEB55ED578A1681C047E023F0F34F02819FB611021F813F85C0F78EBCEDBED4E9A0EE73F35421757FA0B5A82F5037653FDD54FB56F393E8FC262D642FEA563E8CAF97FADE0C39DF3DFDEDDFFEC977D595F29D594BF9F032DC73BD50A5DEF0931FC94879A43C523E73438CCD7C993AA47C1DD38E94AF5FCE91F2D5CC3B527E5218521E295FE69641CA4BAF10521E297F7FCF732AE5E54E07299F9B27A43C527E3C2AE317CCCAB4FA242FBFF6685EFED0DCF4BD69C4FC6FFFED5B9FDD3F7EFE55629C1754CE2FCF5ACE1F85FE81F2B42DF9F405398F9C47CE636EE6D2DC20E711B5C879728E9CAF6CDECBCBF9E59BF79FD66ABB949E5F5B2DF812859E47CFA3E7F34F023D9FB6117A1E3D3F9D9E975B1DF47C6E9ED0F3E8F9F1A8D45F29BB4872FE400D5DC7D409CB9C7EA08612ED9DA1E98B34350B2AE957662DE97B9F8F925FDB7BA806A6A90E95703D2216AB17958FB847DC4B7A2733B23AED8A6B1DCC3D1617734FCEEB6CEEABDEC69757F7B76F4792F5475396AB5F5D2A5806E61E738FB9CF3F09CC7DDA46987BCCFD74E6BE9CEAC1E2E7E6AC4216FFCEB30B9DFFD03A3F5AB57E6545A4E3EFAD5ADFEE8C7737253B7F18A16FDA0D15B71BC351BB716CDA8DEF94A46E648BFD522DD1824AFED53990FCDBC93755CFAE76CDE53EB0FD13247FD6E6487E247F4A310B2A806AEFFD50FC754C3B8ABF7E39AFA9E2AF7ADA6729F85711FCD2C356087E043F821FC18FE017C47FABE5EC8F63CD7374E598430BA49A07C19F9B33043F823F352A75BE7EA7CC22F7EB63BF94B6F3A87AFFEB56635ABD9F52E2B9A4C40535FC6BB336FC4E38D8DE0B743FB2FB887DC43E621FED53B2F3322FDA07B14FDA11FBE41CB15FD5B49713FB1B4BCBA557C4BF11FB2B2B2C892F3D6C85D847EC23F611FB887D41FC3713FB81EE3B42BB83CFCF4D153EBF505F644CE7DFFC56A18DDB2E546BA3BCD0974CAB98E5FAF8B1962FABF4D766A2F40F5D7365CBFBFBEE1FBFFCC7F24F7EFBD755758DFDFA3C18FBAEC6D74FD81C5F8FAF4F29069B339736075F4FDAF1F5E41C5F5FD5B4E3EB2786E1EBF1F565EE197CBDF40AE1EBF1F5F7F73CAFBE3ED4D87A6C3DB6FEF16CFD72F3E3666B6DADB57033F0BBD2A622C3D7FFFECF3F7EFED5AF8CB1BFF3E30F4F3F86817DA802D7F64CB682AD3F010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000406DF83F31A27AECE0FF0200 as [LayoutDataConfigMobile],N'' as [GridBandConfig],N'' as [ControlStateProcedure],N'' as [ValidationProcedures],N'' as [ReadonlyCellCondition],N'' as [ComboboxColumn_BackupForTransfer],N'False' as [IsOpenSubForm],N'' as [Validation],N'btnFWAdd,btnFWDelete,btnFWReset,btnFWSave,btnImport,ckbExportSeparateFile,ddbRptTemplates,btnExport.Export_AttandanceMonth,ckb@ViewProbationPeriod' as [ControlHiddenInShowLayout],N'True' as [IgnoreColumnOrder],N'False' as [IgnoreLock],N'' as [ReadonlyCellCondition_Backup],N'' as [SubDataSettingNames],N'False' as [IsViewReportForm],N'True' as [ExportSeparateButton],N'' as [HashLayoutConfig],NULL as [LayoutDataConfigFillter],NULL as [LayoutParamConfig],N'' as [OpenFormLink],N'' as [SaveTableByBulk],N'False' as [IsNotPaintSaturday],N'False' as [IsNotPaintSunday],N'False' as [IsViewWeekName],N'False' as [IgnoreCheckEECode],N'0' as [ParadiseCommand],N'' as [Labels],N'' as [ColumnHideExport],N'False' as [ColumnWidthCalcData],N'False' as [HideHeaderFilterButton],N'False' as [HideColumnGrid],N'0' as [TypeGrid],N'' as [ProcBeforeAdd],N'' as [ProcAfterAdd],N'' as [ExecuteProcAfterLoadData],NULL as [LayoutDataConfigColumnView],NULL as [LayoutDataConfigCardView],N'0' as [HideFooter],N'False' as [IsFilterBox],N'False' as [GetDefaultParamFromDB],N'0' as [TaskTimeLine],N'0' as [HtmlCell],N'0' as [MinPageSizeGrid],N'0' as [ClickHereToAddNew],N'False' as [IgnoreQuestion],N'0' as [FormLayoutJS],N'0' as [CheckBoxText],N'' as [ColumnHideMobile],NULL as [LayoutMobileLocalConfig],N'0' as [ViewMode],N'0' as [Mode],N'' as [Template],N'0' as [NotResizeImage],N'0' as [DeleteOneRowReloadData],N'False' as [AutoHeightGrid],N'' as [ProcFileName],N'0' as [HeightImagePercentHeightFont],N'' as [ColumnMinWidthPercent],N'0' as [GridViewAutoAddRow],N'0' as [GridViewNewItemRowPosition],N'0' as [LastColumnRemainingWidth],N'False' as [IsAutoSave],N'' as [VirtualColumn],N'0' as [GridTypeview],N'0' as [selectionMode],N'0' as [deleteMode],N'0' as [ClearDataBeforeLoadData],N'False' as [LockSort],N'' as [HightLightControlProc],N'' as [ScriptInit0],N'' as [ScriptInit1],N'' as [ScriptInit2],N'' as [ScriptInit3],N'' as [ScriptInit4],N'' as [ScriptInit5],N'' as [ScriptInit6],N'' as [ScriptInit7],N'' as [ScriptInit8],N'' as [ScriptInit9],N'0' as [FontSizeZoom0],N'0' as [FontSizeZoom1],N'0' as [FontSizeZoom2],N'0' as [FontSizeZoom3],N'0' as [FontSizeZoom4],N'0' as [FontSizeZoom5],N'0' as [FontSizeZoom6],N'0' as [FontSizeZoom7],N'0' as [FontSizeZoom8],N'0' as [FontSizeZoom9],N'False' as [NotBuildForm],N'False' as [NotUseCancelButton],N'4' as [GridUICompact],N'' as [DisableFilterColumns],N'0' as [DisableFilterAll]

EXEC sp_SaveData  @TableNameTmp = '#tblDataSetting' , @TableName = 'tblDataSetting' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0
IF OBJECT_ID('tempdb..#tblDataSetting') IS NOT NULL DROP TABLE #tblDataSetting
--#endregion _
GO

--#region tblDataSettingLayout
IF OBJECT_ID('tempdb..#tblDataSettingLayout') IS NOT NULL DROP TABLE #tblDataSettingLayout
  create table #tblDataSettingLayout (
   [TableName] [nvarchar](MAX) NULL 
 , [Name] [nvarchar](MAX) NULL 
 , [ControlName] [nvarchar](MAX) NULL 
 , [NamePa] [nvarchar](MAX) NULL 
 , [TabbedGroupParentName] [nvarchar](MAX) NULL 
 , [Type] [nvarchar](MAX) NULL 
 , [Lx] [int] NULL 
 , [Ly] [int] NULL 
 , [Sx] [int] NULL 
 , [Sy] [int] NULL 
 , [ShowCaption] [int] NULL 
 , [Padding] [int] NULL 
 , [TextLocation] [nvarchar](MAX) NULL 
 , [GroupBordersVisible] [int] NULL 
 , [TypeLayout] [nvarchar](MAX) NULL 
 , [Spacing] [int] NULL 
 , [BackColor] [nvarchar](MAX) NULL 
 , [ControlType] [nvarchar](MAX) NULL 
 , [ColumnSpan] [int] NULL 
 , [RowSpan] [int] NULL 
 , [CaptionHorizontalAlign] [nvarchar](MAX) NULL 
 , [CaptionVerticalAlign] [nvarchar](MAX) NULL 
 , [WidthPercentage] [int] NULL 
 , [FixMinSize] [bit] NULL 
 , [AlignContent] [nvarchar](MAX) NULL 
 , [BorderBottomColor] [nvarchar](MAX) NULL 
 , [BorderBottomSize] [nvarchar](MAX) NULL 
 , [BorderColor] [nvarchar](MAX) NULL 
 , [BorderLeftColor] [nvarchar](MAX) NULL 
 , [BorderLeftSize] [nvarchar](MAX) NULL 
 , [BorderRightColor] [nvarchar](MAX) NULL 
 , [BorderRightSize] [nvarchar](MAX) NULL 
 , [BorderSize] [nvarchar](MAX) NULL 
 , [BorderTopColor] [nvarchar](MAX) NULL 
 , [BorderTopSize] [nvarchar](MAX) NULL 
 , [BorderVisible] [bit] NULL 
 , [ControlBackColor] [nvarchar](MAX) NULL 
 , [ControlBorderBottomColor] [nvarchar](MAX) NULL 
 , [ControlBorderBottomSize] [nvarchar](MAX) NULL 
 , [ControlBorderColor] [nvarchar](MAX) NULL 
 , [ControlBorderLeftColor] [nvarchar](MAX) NULL 
 , [ControlBorderLeftSize] [nvarchar](MAX) NULL 
 , [ControlBorderRightColor] [nvarchar](MAX) NULL 
 , [ControlBorderRightSize] [nvarchar](MAX) NULL 
 , [ControlBorderSize] [nvarchar](MAX) NULL 
 , [ControlBorderTopColor] [nvarchar](MAX) NULL 
 , [ControlBorderTopSize] [nvarchar](MAX) NULL 
 , [ControlForeColor] [nvarchar](MAX) NULL 
 , [ControlHorizontalAlign] [nvarchar](MAX) NULL 
 , [ControlPadding] [int] NULL 
 , [ControlVerticalAlign] [nvarchar](MAX) NULL 
 , [FontSize] [nvarchar](MAX) NULL 
 , [IconName] [nvarchar](MAX) NULL 
 , [ItemBackColor] [nvarchar](MAX) NULL 
 , [ItemBorderBottomColor] [nvarchar](MAX) NULL 
 , [ItemBorderBottomSize] [nvarchar](MAX) NULL 
 , [ItemBorderColor] [nvarchar](MAX) NULL 
 , [ItemBorderLeftColor] [nvarchar](MAX) NULL 
 , [ItemBorderLeftSize] [nvarchar](MAX) NULL 
 , [ItemBorderRightColor] [nvarchar](MAX) NULL 
 , [ItemBorderRightSize] [nvarchar](MAX) NULL 
 , [ItemBorderSize] [nvarchar](MAX) NULL 
 , [ItemBorderTopColor] [nvarchar](MAX) NULL 
 , [ItemBorderTopSize] [nvarchar](MAX) NULL 
 , [ItemForeColor] [nvarchar](MAX) NULL 
 , [ItemPadding] [int] NULL 
 , [MinGridPageSize] [int] NULL 
 , [NotClientVisible] [bit] NULL 
 , [NullTextMessageID] [nvarchar](MAX) NULL 
 , [FullPageEmpty] [bit] NULL 
 , [PaddingTop] [int] NULL 
 , [PaddingLeft] [int] NULL 
 , [PaddingBottom] [int] NULL 
 , [PaddingRight] [int] NULL 
 , [ControlCellPadding] [int] NULL 
 , [MaxWidth] [float] NULL 
 , [MinWidth] [float] NULL 
 , [TabPageOrder] [int] NULL 
 , [SelectedTabPageIndex] [int] NULL 
 , [FixWidthClient] [int] NULL 
 , [ErrorMessage] [nvarchar](MAX) NULL 
 , [borderRadius] [nvarchar](MAX) NULL 
 , [boxShadow] [nvarchar](MAX) NULL 
 , [IsValidation] [bit] NULL 
 , [HorizontalAlign] [nvarchar](MAX) NULL 
 , [maxHeight] [int] NULL 
 , [TextAlignMode] [int] NULL 
 , [minHeight] [int] NULL 
 , [HeightPercentageClient] [float] NULL 
 , [ControlBorderRadius] [nvarchar](MAX) NULL 
 , [ControlBoxShadow] [nvarchar](MAX) NULL 
 , [ControlPaddingBottom] [float] NULL 
 , [ControlPaddingLeft] [float] NULL 
 , [ControlPaddingRight] [float] NULL 
 , [ControlPaddingTop] [float] NULL 
 , [ForeColor] [nvarchar](MAX) NULL 
 , [CaptionWrap] [int] NULL 
 , [LocationID] [int] NULL 
 , [ContainerType] [int] NULL 
 , [ControlNoBorder] [bit] NULL 
 , [BackgroundImage] varbinary(max) NULL 
 , [labelMode] [int] NULL 
 , [selectionMode] [int] NULL 
 , [deleteMode] [int] NULL 
)

 INSERT INTO #tblDataSettingLayout([TableName],[Name],[ControlName],[NamePa],[TabbedGroupParentName],[Type],[Lx],[Ly],[Sx],[Sy],[ShowCaption],[Padding],[TextLocation],[GroupBordersVisible],[TypeLayout],[Spacing],[BackColor],[ControlType],[ColumnSpan],[RowSpan],[CaptionHorizontalAlign],[CaptionVerticalAlign],[WidthPercentage],[FixMinSize],[AlignContent],[BorderBottomColor],[BorderBottomSize],[BorderColor],[BorderLeftColor],[BorderLeftSize],[BorderRightColor],[BorderRightSize],[BorderSize],[BorderTopColor],[BorderTopSize],[BorderVisible],[ControlBackColor],[ControlBorderBottomColor],[ControlBorderBottomSize],[ControlBorderColor],[ControlBorderLeftColor],[ControlBorderLeftSize],[ControlBorderRightColor],[ControlBorderRightSize],[ControlBorderSize],[ControlBorderTopColor],[ControlBorderTopSize],[ControlForeColor],[ControlHorizontalAlign],[ControlPadding],[ControlVerticalAlign],[FontSize],[IconName],[ItemBackColor],[ItemBorderBottomColor],[ItemBorderBottomSize],[ItemBorderColor],[ItemBorderLeftColor],[ItemBorderLeftSize],[ItemBorderRightColor],[ItemBorderRightSize],[ItemBorderSize],[ItemBorderTopColor],[ItemBorderTopSize],[ItemForeColor],[ItemPadding],[MinGridPageSize],[NotClientVisible],[NullTextMessageID],[FullPageEmpty],[PaddingTop],[PaddingLeft],[PaddingBottom],[PaddingRight],[ControlCellPadding],[MaxWidth],[MinWidth],[TabPageOrder],[SelectedTabPageIndex],[FixWidthClient],[ErrorMessage],[borderRadius],[boxShadow],[IsValidation],[HorizontalAlign],[maxHeight],[TextAlignMode],[minHeight],[HeightPercentageClient],[ControlBorderRadius],[ControlBoxShadow],[ControlPaddingBottom],[ControlPaddingLeft],[ControlPaddingRight],[ControlPaddingTop],[ForeColor],[CaptionWrap],[LocationID],[ContainerType],[ControlNoBorder],[BackgroundImage],[labelMode],[selectionMode],[deleteMode])
Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'btnexport' as [Name],N'btnexport' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'3' as [Lx],N'1900' as [Ly],N'3542' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#336633' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Export' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'btnfwadd' as [Name],N'btnfwadd' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'3' as [Lx],N'1820' as [Ly],N'1771' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'AddNew' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'btnfwdelete' as [Name],N'btnfwdelete' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'3' as [Lx],N'1860' as [Ly],N'1771' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleButton_FWDelete' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#E94235' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Delete' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'btnfwreset' as [Name],N'btnfwreset' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1774' as [Lx],N'1860' as [Ly],N'1771' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#FFC000' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'refresh' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'btnfwsave' as [Name],N'btnfwsave' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1774' as [Lx],N'1820' as [Ly],N'1771' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#25205E' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Save' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'btnimport' as [Name],N'btnimport' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1' as [Lx],N'1978' as [Ly],N'3542' as [Sx],N'36' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#336633' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'ImportFile' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'ddbrpttemplates' as [Name],N'ddbrpttemplates' as [ControlName],N'plgfwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'3' as [Lx],N'1940' as [Ly],N'3542' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'DropDownButton_VTS' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lbl@month' as [Name],N'cbx@month' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1' as [Lx],N'1' as [Ly],N'1771' as [Sx],N'26' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SearchLookUpEdit_VTS' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'1' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lbl@year' as [Name],N'cbx@year' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1772' as [Lx],N'1' as [Ly],N'1771' as [Sx],N'26' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SearchLookUpEdit_VTS' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'1' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lblfilter' as [Name],N'txtfilter' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1772' as [Lx],N'27' as [Ly],N'1771' as [Sx],N'27' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'PopupContainerEdit' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'1' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lblreload' as [Name],N'btnreload' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1' as [Lx],N'27' as [Ly],N'1771' as [Sx],N'27' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'ParadiseSimpleButtonBase' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'50' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lbltableeditor' as [Name],N'grdtableeditor' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1' as [Lx],N'54' as [Ly],N'3542' as [Sx],N'1764' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'GridControl' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'plgfwcommand' as [Name],N'' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'1817' as [Ly],N'3542' as [Sx],N'196' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'top' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'root' as [Name],N'' as [ControlName],N'' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'0' as [Ly],N'3542' as [Sx],N'2013' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'top' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'btnexport' as [Name],N'btnexport' as [ControlName],N'item1' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1360' as [Lx],N'0' as [Ly],N'254' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'17' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Export' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'item0' as [Name],N'' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'' as [Type],N'1008' as [Lx],N'0' as [Ly],N'265' as [Sx],N'31' as [Sy],N'0' as [ShowCaption],N'2' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'16' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'2' as [PaddingTop],N'2' as [PaddingLeft],N'2' as [PaddingBottom],N'2' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'item1' as [Name],N'' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'31' as [Ly],N'1620' as [Sx],N'906' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'Top' as [TextLocation],N'1' as [GroupBordersVisible],N'6' as [TypeLayout],N'2' as [Spacing],N'' as [BackColor],N'' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],NULL as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lbl@month' as [Name],N'cbx@month' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'241' as [Lx],N'0' as [Ly],N'306' as [Sx],N'31' as [Sy],N'1' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SearchLookUpEdit_VTS' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'18' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'lbl@optionview' as [Name],N'cbx@optionview' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'743' as [Lx],N'0' as [Ly],N'265' as [Sx],N'31' as [Sy],N'1' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SearchLookUpEdit_VTS' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'16' as [WidthPercentage],NULL as [FixMinSize],NULL as [AlignContent],NULL as [BorderBottomColor],NULL as [BorderBottomSize],NULL as [BorderColor],NULL as [BorderLeftColor],NULL as [BorderLeftSize],NULL as [BorderRightColor],NULL as [BorderRightSize],NULL as [BorderSize],NULL as [BorderTopColor],NULL as [BorderTopSize],NULL as [BorderVisible],NULL as [ControlBackColor],NULL as [ControlBorderBottomColor],NULL as [ControlBorderBottomSize],NULL as [ControlBorderColor],NULL as [ControlBorderLeftColor],NULL as [ControlBorderLeftSize],NULL as [ControlBorderRightColor],NULL as [ControlBorderRightSize],NULL as [ControlBorderSize],NULL as [ControlBorderTopColor],NULL as [ControlBorderTopSize],NULL as [ControlForeColor],NULL as [ControlHorizontalAlign],NULL as [ControlPadding],NULL as [ControlVerticalAlign],NULL as [FontSize],NULL as [IconName],NULL as [ItemBackColor],NULL as [ItemBorderBottomColor],NULL as [ItemBorderBottomSize],NULL as [ItemBorderColor],NULL as [ItemBorderLeftColor],NULL as [ItemBorderLeftSize],NULL as [ItemBorderRightColor],NULL as [ItemBorderRightSize],NULL as [ItemBorderSize],NULL as [ItemBorderTopColor],NULL as [ItemBorderTopSize],NULL as [ItemForeColor],NULL as [ItemPadding],NULL as [MinGridPageSize],N'False' as [NotClientVisible],NULL as [NullTextMessageID],NULL as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],NULL as [ControlCellPadding],NULL as [MaxWidth],NULL as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],NULL as [FixWidthClient],NULL as [ErrorMessage],NULL as [borderRadius],NULL as [boxShadow],NULL as [IsValidation],NULL as [HorizontalAlign],NULL as [maxHeight],N'0' as [TextAlignMode],NULL as [minHeight],NULL as [HeightPercentageClient],NULL as [ControlBorderRadius],NULL as [ControlBoxShadow],NULL as [ControlPaddingBottom],NULL as [ControlPaddingLeft],NULL as [ControlPaddingRight],NULL as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],NULL as [LocationID],NULL as [ContainerType],NULL as [ControlNoBorder],NULL as [BackgroundImage],NULL as [labelMode],NULL as [selectionMode],NULL as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lbl@year' as [Name],N'cbx@year' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'0' as [Ly],N'241' as [Sx],N'31' as [Sy],N'1' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SearchLookUpEdit_VTS' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'14' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'lblexport.attendancesheet' as [Name],N'btnexport.attendancesheet' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1482' as [Lx],N'0' as [Ly],N'138' as [Sx],N'31' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleExportButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'12' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'-1' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'-14838986' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'CloudFile' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'lblexport.summarytimesheet' as [Name],N'btnexport.summarytimesheet' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'1273' as [Lx],N'0' as [Ly],N'209' as [Sx],N'31' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleExportButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'12' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'-1' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'-14838986' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'CloudFile' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'lblfilter' as [Name],N'txtfilter' as [ControlName],N'item1' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'0' as [Ly],N'1360' as [Sx],N'35' as [Sy],N'1' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'PopupContainerEdit' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'83' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'lblreload' as [Name],N'btnreload' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'547' as [Lx],N'0' as [Ly],N'196' as [Sx],N'31' as [Sy],N'0' as [ShowCaption],N'1' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'ParadiseSimpleButtonBase' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'12' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting' as [TableName],N'lbltableeditor' as [Name],N'grdtableeditor' as [ControlName],N'item1' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'35' as [Ly],N'1614' as [Sx],N'865' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'GridControl' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'1' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting' as [TableName],N'root' as [Name],N'' as [ControlName],N'' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'0' as [Ly],N'1620' as [Sx],N'937' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'Top' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],NULL as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode]

DECLARE @sql VARCHAR(MAX) = 'TableName'+char(10)+'TypeLayout'
EXEC sp_SaveData  @TableNameTmp = '#tblDataSettingLayout' , @TableName = 'tblDataSettingLayout' , @Command = 'DeleteNot',@ColumnDeleteNot=@sql , @IsDropTableTmp =0,@IsPrint=0
EXEC sp_SaveData  @TableNameTmp = '#tblDataSettingLayout' , @TableName = 'tblDataSettingLayout' , @Command = 'insert,update', @IsDropTableTmp =0,@IsPrint=0
IF OBJECT_ID('tempdb..#tblDataSettingLayout') IS NOT NULL DROP TABLE #tblDataSettingLayout
--#endregion _
GO

--#region tblExportList
IF OBJECT_ID('tempdb..#tblExportList') IS NOT NULL DROP TABLE #tblExportList
  create table #tblExportList (
   [ExportName] [nvarchar](MAX) NULL 
 , [Description] [nvarchar](MAX) NULL 
 , [ProcedureName] [nvarchar](MAX) NULL 
 , [ExportType] [nvarchar](MAX) NULL 
 , [TemplateFileName] [nvarchar](MAX) NULL 
 , [StartRow] [int] NULL 
 , [StartColumn] [int] NULL 
 , [Catalog] [nvarchar](MAX) NULL 
 , [ObjectId] [bigint] NULL 
 , [Visible] [bit] NULL 
 , [OneSheet] [bit] NULL 
 , [TempStart] [int] NULL 
 , [TempEnd] [int] NULL 
 , [TempDataStart] [int] NULL 
 , [TempRowEmpty] [smallint] NULL 
 , [MergeFormat] [nvarchar](MAX) NULL 
 , [IsAllBoder] [bit] NULL 
 , [ListSheetMerge] [nvarchar](MAX) NULL 
 , [IsExportHeader] [bit] NULL 
 , [MultipleReport] [bit] NULL 
 , [BestFixColumn] [bit] NULL 
 , [BestFixHeaderCount] [int] NULL 
 , [TemplateSheetIndex] [int] NULL 
 , [OneHeaderPerRow] [int] NULL 
 , [NotShowInExportList] [bit] NULL 
 , [InsertCellInsRow] [decimal] NULL 
 , [ReloadFormAfterExport] [bit] NULL 
 , [FollowConfigTable] [bit] NULL 
 , [NotRequireSave] [bit] NULL 
 , [IsTemplateImport] [bit] NULL 
 , [RequireCheckHeader] [bit] NULL 
 , [Frequency] [int] NULL 
 , [LockExportData] [bit] NULL 
 , [DescriptionEN] [nvarchar](MAX) NULL 
 , [ProcExportCompleted] [nvarchar](MAX) NULL 
 , [ExportMergeEmployeeCount] [int] NULL 
 , [ProcAfterExport] [nvarchar](MAX) NULL 
)

 INSERT INTO #tblExportList([ExportName],[Description],[ProcedureName],[ExportType],[TemplateFileName],[StartRow],[StartColumn],[Catalog],[ObjectId],[Visible],[OneSheet],[TempStart],[TempEnd],[TempDataStart],[TempRowEmpty],[MergeFormat],[IsAllBoder],[ListSheetMerge],[IsExportHeader],[MultipleReport],[BestFixColumn],[BestFixHeaderCount],[TemplateSheetIndex],[OneHeaderPerRow],[NotShowInExportList],[InsertCellInsRow],[ReloadFormAfterExport],[FollowConfigTable],[NotRequireSave],[IsTemplateImport],[RequireCheckHeader],[Frequency],[LockExportData],[DescriptionEN],[ProcExportCompleted],[ExportMergeEmployeeCount],[ProcAfterExport])
Select  N'AttendanceSheet' as [ExportName],N'Attendance Sheet' as [Description],N'sp_AttendanceSummaryMonthlyInOutExport' as [ProcedureName],N'Excel' as [ExportType],N'TRIPOD_TimesheetDetail.xlsx' as [TemplateFileName],N'8' as [StartRow],N'1' as [StartColumn],N'TA' as [Catalog],N'501' as [ObjectId],N'True' as [Visible],NULL as [OneSheet],NULL as [TempStart],NULL as [TempEnd],NULL as [TempDataStart],NULL as [TempRowEmpty],NULL as [MergeFormat],NULL as [IsAllBoder],NULL as [ListSheetMerge],NULL as [IsExportHeader],NULL as [MultipleReport],NULL as [BestFixColumn],NULL as [BestFixHeaderCount],NULL as [TemplateSheetIndex],NULL as [OneHeaderPerRow],NULL as [NotShowInExportList],NULL as [InsertCellInsRow],NULL as [ReloadFormAfterExport],N'True' as [FollowConfigTable],NULL as [NotRequireSave],NULL as [IsTemplateImport],NULL as [RequireCheckHeader],N'41' as [Frequency],NULL as [LockExportData],NULL as [DescriptionEN],NULL as [ProcExportCompleted],NULL as [ExportMergeEmployeeCount],NULL as [ProcAfterExport] UNION ALL

Select  N'Export_AttandanceMonth' as [ExportName],N'Xuất báo cáo chấm công tháng' as [Description],N'sp_ExportAttendanceMonth' as [ProcedureName],N'Excel' as [ExportType],N'Export_AttandanceMonthly.xlsx' as [TemplateFileName],NULL as [StartRow],NULL as [StartColumn],N'PR' as [Catalog],N'501' as [ObjectId],N'True' as [Visible],NULL as [OneSheet],NULL as [TempStart],NULL as [TempEnd],NULL as [TempDataStart],NULL as [TempRowEmpty],NULL as [MergeFormat],NULL as [IsAllBoder],NULL as [ListSheetMerge],NULL as [IsExportHeader],NULL as [MultipleReport],NULL as [BestFixColumn],NULL as [BestFixHeaderCount],NULL as [TemplateSheetIndex],NULL as [OneHeaderPerRow],NULL as [NotShowInExportList],NULL as [InsertCellInsRow],NULL as [ReloadFormAfterExport],N'True' as [FollowConfigTable],NULL as [NotRequireSave],NULL as [IsTemplateImport],NULL as [RequireCheckHeader],N'615' as [Frequency],NULL as [LockExportData],NULL as [DescriptionEN],NULL as [ProcExportCompleted],NULL as [ExportMergeEmployeeCount],NULL as [ProcAfterExport] UNION ALL

Select  N'SummaryTimesheet' as [ExportName],N'Tổng kết giờ tăng ca và nghỉ phép' as [Description],N'sp_exportSummaryTimesheet' as [ProcedureName],N'Excel' as [ExportType],N'TRIPOD_Overtime&Leave_Summarization.xlsx' as [TemplateFileName],NULL as [StartRow],NULL as [StartColumn],N'TA' as [Catalog],N'501' as [ObjectId],N'True' as [Visible],NULL as [OneSheet],NULL as [TempStart],NULL as [TempEnd],NULL as [TempDataStart],NULL as [TempRowEmpty],NULL as [MergeFormat],NULL as [IsAllBoder],NULL as [ListSheetMerge],NULL as [IsExportHeader],NULL as [MultipleReport],NULL as [BestFixColumn],NULL as [BestFixHeaderCount],NULL as [TemplateSheetIndex],NULL as [OneHeaderPerRow],NULL as [NotShowInExportList],NULL as [InsertCellInsRow],NULL as [ReloadFormAfterExport],N'True' as [FollowConfigTable],NULL as [NotRequireSave],NULL as [IsTemplateImport],NULL as [RequireCheckHeader],N'33' as [Frequency],NULL as [LockExportData],NULL as [DescriptionEN],NULL as [ProcExportCompleted],NULL as [ExportMergeEmployeeCount],NULL as [ProcAfterExport]

EXEC sp_SaveData  @TableNameTmp = '#tblExportList' , @TableName = 'tblExportList' , @Command = 'DeleteNot',@ColumnDeleteNot='ExportName' , @IsDropTableTmp =0,@IsPrint=0
EXEC sp_SaveData  @TableNameTmp = '#tblExportList' , @TableName = 'tblExportList' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0
IF OBJECT_ID('tempdb..#tblExportList') IS NOT NULL DROP TABLE #tblExportList
--#endregion _
GO

--#region tblMD_Message
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message 
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
  create table #tblMD_Message (
   [MessageID] [nvarchar](MAX) NULL 
 , [Language] [nvarchar](MAX) NULL 
 , [Content] [nvarchar](MAX) NULL 
 , [Frequency] [bigint] NULL 
 , [IgnorePending] [bit] NULL 
)

 INSERT INTO #tblMD_Message([MessageID],[Language],[Content],[Frequency],[IgnorePending])
Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Att' as [MessageID],N'CN' as [Language],N'十六' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Att' as [MessageID],N'CN' as [Language],N'十七' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Att' as [MessageID],N'CN' as [Language],N'十八' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Att' as [MessageID],N'CN' as [Language],N'十九' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Att' as [MessageID],N'CN' as [Language],N'工作时间' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Att' as [MessageID],N'CN' as [Language],N'二十' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Att' as [MessageID],N'CN' as [Language],N'二十一' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Att' as [MessageID],N'CN' as [Language],N'二十二' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Att' as [MessageID],N'CN' as [Language],N'二十三' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Att' as [MessageID],N'CN' as [Language],N'二十四' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Att' as [MessageID],N'CN' as [Language],N'二十五' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Att' as [MessageID],N'CN' as [Language],N'二十六' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Att' as [MessageID],N'CN' as [Language],N'二十七' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Att' as [MessageID],N'CN' as [Language],N'二十八' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Att' as [MessageID],N'CN' as [Language],N'二十九' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Att' as [MessageID],N'CN' as [Language],N'三十' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.STD_WorkingDays' as [MessageID],N'CN' as [Language],N'標準工作天' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalDayOff' as [MessageID],N'CN' as [Language],N'休假' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.TotalPaidDays' as [MessageID],N'CN' as [Language],N'公开工资' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnpaidLeave' as [MessageID],N'CN' as [Language],N'无薪假期' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.10Att' as [MessageID],N'EN' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.11Att' as [MessageID],N'EN' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.12Att' as [MessageID],N'EN' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.13Att' as [MessageID],N'EN' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.14Att' as [MessageID],N'EN' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.15Att' as [MessageID],N'EN' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Att' as [MessageID],N'EN' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Att' as [MessageID],N'EN' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Att' as [MessageID],N'EN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Att' as [MessageID],N'EN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Att' as [MessageID],N'EN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Att' as [MessageID],N'EN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Att' as [MessageID],N'EN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Att' as [MessageID],N'EN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Att' as [MessageID],N'EN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Att' as [MessageID],N'EN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Att' as [MessageID],N'EN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Att' as [MessageID],N'EN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Att' as [MessageID],N'EN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Att' as [MessageID],N'EN' as [Language],N'28' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Att' as [MessageID],N'EN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.2Att' as [MessageID],N'EN' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Att' as [MessageID],N'EN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.31Att' as [MessageID],N'EN' as [Language],N'31' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.3Att' as [MessageID],N'EN' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.4Att' as [MessageID],N'EN' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.5Att' as [MessageID],N'EN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.6Att' as [MessageID],N'EN' as [Language],N'6' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.7Att' as [MessageID],N'EN' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.8Att' as [MessageID],N'EN' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.9Att' as [MessageID],N'EN' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT1' as [MessageID],N'EN' as [Language],N'OT1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT2a' as [MessageID],N'EN' as [Language],N'OT2a' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT3' as [MessageID],N'EN' as [Language],N'OT3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT4' as [MessageID],N'EN' as [Language],N'OT4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT5' as [MessageID],N'EN' as [Language],N'OT5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PaidLeaveHrs' as [MessageID],N'EN' as [Language],N'Paid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.STD_WorkingDays' as [MessageID],N'EN' as [Language],N'STD WKDs' as [Content],N'82' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.TotalPaidDays' as [MessageID],N'EN' as [Language],N'Total paid days' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnpaidLeave' as [MessageID],N'EN' as [Language],N'Unpaid Leave' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.WorkHours' as [MessageID],N'EN' as [Language],N'Regular Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.10Att' as [MessageID],N'VN' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.11Att' as [MessageID],N'VN' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.12Att' as [MessageID],N'VN' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.13Att' as [MessageID],N'VN' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.14Att' as [MessageID],N'VN' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.15Att' as [MessageID],N'VN' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Att' as [MessageID],N'VN' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Att' as [MessageID],N'VN' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Att' as [MessageID],N'VN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Att' as [MessageID],N'VN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Att' as [MessageID],N'VN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Att' as [MessageID],N'VN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Att' as [MessageID],N'VN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Att' as [MessageID],N'VN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Att' as [MessageID],N'VN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Att' as [MessageID],N'VN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Att' as [MessageID],N'VN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Att' as [MessageID],N'VN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Att' as [MessageID],N'VN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Att' as [MessageID],N'VN' as [Language],N'28' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Att' as [MessageID],N'VN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.2Att' as [MessageID],N'VN' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Att' as [MessageID],N'VN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.31Att' as [MessageID],N'VN' as [Language],N'31' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.3Att' as [MessageID],N'VN' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.4Att' as [MessageID],N'VN' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.5Att' as [MessageID],N'VN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.6Att' as [MessageID],N'VN' as [Language],N'6' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.7Att' as [MessageID],N'VN' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.8Att' as [MessageID],N'VN' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.9Att' as [MessageID],N'VN' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.Actual_WorkingDays' as [MessageID],N'VN' as [Language],N'Ngày công thực tế' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.DepartmentName' as [MessageID],N'VN' as [Language],N'Phòng ban' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.HireDate' as [MessageID],N'VN' as [Language],N'Ngày vào làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.IOHrs' as [MessageID],N'VN' as [Language],N'Trễ/
sớm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.item0' as [MessageID],N'VN' as [Language],N'item0' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.item1' as [MessageID],N'VN' as [Language],N'item1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@optionview' as [MessageID],N'VN' as [Language],N'Chế độ xem' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PaidLeaveHrs' as [MessageID],N'VN' as [Language],N'Paid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.STD_WorkingDays' as [MessageID],N'VN' as [Language],N'Ngày công chuẩn' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalDayOff' as [MessageID],N'VN' as [Language],N'Ngày nghỉ' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalNS' as [MessageID],N'VN' as [Language],N'NS Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalOT' as [MessageID],N'VN' as [Language],N'Tổng OT' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.TotalPaidDays' as [MessageID],N'VN' as [Language],N'Công hưởng lương' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnpaidLeave' as [MessageID],N'VN' as [Language],N'Unpaid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.WorkHours' as [MessageID],N'VN' as [Language],N'Regular Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending]
EXEC sp_SaveData  @TableNameTmp = '#tblMD_Message' , @TableName = 'tblMD_Message' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
--#endregion _
GO

--#region tblMD_Message
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message 
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
  create table #tblMD_Message (
   [MessageID] [nvarchar](MAX) NULL 
 , [Language] [nvarchar](MAX) NULL 
 , [Content] [nvarchar](MAX) NULL 
 , [Frequency] [bigint] NULL 
 , [IgnorePending] [bit] NULL 
)

 INSERT INTO #tblMD_Message([MessageID],[Language],[Content],[Frequency],[IgnorePending])
Select  N'0' as [MessageID],N'CN' as [Language],N'零' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0' as [MessageID],N'En' as [Language],N'Không đi làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0' as [MessageID],N'KR' as [Language],N'Không đi làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0' as [MessageID],N'vn' as [Language],N'Không đi làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0.vldt' as [MessageID],N'En' as [Language],N'Không đi làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0.vldt' as [MessageID],N'KR' as [Language],N'Không đi làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0.vldt' as [MessageID],N'vn' as [Language],N'Không đi làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1' as [MessageID],N'EN' as [Language],N'Seniority allowance (long term)' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1' as [MessageID],N'VN' as [Language],N'Seniority allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1.vldt' as [MessageID],N'EN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1.vldt' as [MessageID],N'KR' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1.vldt' as [MessageID],N'VN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10' as [MessageID],N'EN' as [Language],N'Regional(area) allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10' as [MessageID],N'VN' as [Language],N'Regional (area) allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10.vldt' as [MessageID],N'EN' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10.vldt' as [MessageID],N'KR' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10.vldt' as [MessageID],N'VN' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10Att' as [MessageID],N'CN' as [Language],N'10Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10Att' as [MessageID],N'EN' as [Language],N'10th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'10Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11' as [MessageID],N'EN' as [Language],N'Incentive allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11' as [MessageID],N'VN' as [Language],N'Incentive allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11.vldt' as [MessageID],N'EN' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11.vldt' as [MessageID],N'KR' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11.vldt' as [MessageID],N'VN' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11Att' as [MessageID],N'CN' as [Language],N'11Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11Att' as [MessageID],N'EN' as [Language],N'11th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'11Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12' as [MessageID],N'EN' as [Language],N'Key process allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12' as [MessageID],N'VN' as [Language],N'Key process allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12.vldt' as [MessageID],N'EN' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12.vldt' as [MessageID],N'KR' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12.vldt' as [MessageID],N'VN' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12Att' as [MessageID],N'CN' as [Language],N'12Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12Att' as [MessageID],N'EN' as [Language],N'12th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'12Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13' as [MessageID],N'EN' as [Language],N'Bonus 6 month' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13' as [MessageID],N'VN' as [Language],N'Bonus 6 month' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13.vldt' as [MessageID],N'EN' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13.vldt' as [MessageID],N'KR' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13.vldt' as [MessageID],N'VN' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13Att' as [MessageID],N'CN' as [Language],N'13Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13Att' as [MessageID],N'EN' as [Language],N'13th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'13Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14' as [MessageID],N'EN' as [Language],N'Performance & Responsibility' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14' as [MessageID],N'VN' as [Language],N'Performance & Responsibility' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14.vldt' as [MessageID],N'EN' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14.vldt' as [MessageID],N'KR' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14.vldt' as [MessageID],N'VN' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14Att' as [MessageID],N'CN' as [Language],N'14Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14Att' as [MessageID],N'EN' as [Language],N'14th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'14Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15' as [MessageID],N'EN' as [Language],N'Bonus 6 month full attendance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15' as [MessageID],N'VN' as [Language],N'Bonus 6 month full attendance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15.vldt' as [MessageID],N'EN' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15.vldt' as [MessageID],N'KR' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15.vldt' as [MessageID],N'VN' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15Att' as [MessageID],N'CN' as [Language],N'15Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15Att' as [MessageID],N'EN' as [Language],N'15th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'15Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16' as [MessageID],N'EN' as [Language],N'[Foreign] Meal allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16' as [MessageID],N'VN' as [Language],N'[Foreign] Meal allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16.vldt' as [MessageID],N'EN' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16.vldt' as [MessageID],N'KR' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16.vldt' as [MessageID],N'VN' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16Att' as [MessageID],N'CN' as [Language],N'16Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16Att' as [MessageID],N'EN' as [Language],N'16th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'16Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17' as [MessageID],N'EN' as [Language],N'[Foreign] House allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17' as [MessageID],N'VN' as [Language],N'[Foreign] House allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17.vldt' as [MessageID],N'EN' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17.vldt' as [MessageID],N'KR' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17.vldt' as [MessageID],N'VN' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17Att' as [MessageID],N'CN' as [Language],N'17Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17Att' as [MessageID],N'EN' as [Language],N'17th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'17Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18' as [MessageID],N'CN' as [Language],N'十八' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18' as [MessageID],N'EN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18' as [MessageID],N'KR' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18' as [MessageID],N'VN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18.vldt' as [MessageID],N'EN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18.vldt' as [MessageID],N'KR' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18.vldt' as [MessageID],N'VN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18Att' as [MessageID],N'CN' as [Language],N'18Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18Att' as [MessageID],N'EN' as [Language],N'18th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'18Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19' as [MessageID],N'CN' as [Language],N'十九' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19' as [MessageID],N'EN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19' as [MessageID],N'KR' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19' as [MessageID],N'VN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19.vldt' as [MessageID],N'EN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19.vldt' as [MessageID],N'KR' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19.vldt' as [MessageID],N'VN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19Att' as [MessageID],N'CN' as [Language],N'19Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19Att' as [MessageID],N'EN' as [Language],N'19th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'19Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1Att' as [MessageID],N'CN' as [Language],N'1Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1Att' as [MessageID],N'EN' as [Language],N'1st' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2' as [MessageID],N'EN' as [Language],N'Production bonus' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2' as [MessageID],N'VN' as [Language],N'Production bonus' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2.vldt' as [MessageID],N'EN' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2.vldt' as [MessageID],N'KR' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2.vldt' as [MessageID],N'VN' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20' as [MessageID],N'CN' as [Language],N'二十' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20' as [MessageID],N'EN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20' as [MessageID],N'KR' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20' as [MessageID],N'VN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20.vldt' as [MessageID],N'EN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20.vldt' as [MessageID],N'KR' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20.vldt' as [MessageID],N'VN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20Att' as [MessageID],N'CN' as [Language],N'20Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20Att' as [MessageID],N'EN' as [Language],N'20th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'20Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21' as [MessageID],N'CN' as [Language],N'二十一' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21' as [MessageID],N'EN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21' as [MessageID],N'KR' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21' as [MessageID],N'VN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21.vldt' as [MessageID],N'EN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21.vldt' as [MessageID],N'KR' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21.vldt' as [MessageID],N'VN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21Att' as [MessageID],N'CN' as [Language],N'21Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21Att' as [MessageID],N'EN' as [Language],N'21st' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'21Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22' as [MessageID],N'CN' as [Language],N'二十二' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22' as [MessageID],N'EN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22' as [MessageID],N'KR' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22' as [MessageID],N'VN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22.vldt' as [MessageID],N'EN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22.vldt' as [MessageID],N'KR' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22.vldt' as [MessageID],N'VN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22Att' as [MessageID],N'CN' as [Language],N'22Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22Att' as [MessageID],N'EN' as [Language],N'22nd' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'22Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23' as [MessageID],N'CN' as [Language],N'二十三' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23' as [MessageID],N'EN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23' as [MessageID],N'KR' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23' as [MessageID],N'VN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23.vldt' as [MessageID],N'EN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23.vldt' as [MessageID],N'KR' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23.vldt' as [MessageID],N'VN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23Att' as [MessageID],N'CN' as [Language],N'23Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23Att' as [MessageID],N'EN' as [Language],N'23rd' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'23Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24' as [MessageID],N'CN' as [Language],N'二十四' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24' as [MessageID],N'EN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24' as [MessageID],N'KR' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24' as [MessageID],N'VN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24.vldt' as [MessageID],N'EN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24.vldt' as [MessageID],N'KR' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24.vldt' as [MessageID],N'VN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24Att' as [MessageID],N'CN' as [Language],N'24Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24Att' as [MessageID],N'EN' as [Language],N'24th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'24Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25' as [MessageID],N'CN' as [Language],N'二十五' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25' as [MessageID],N'EN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25' as [MessageID],N'KR' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25' as [MessageID],N'VN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25.vldt' as [MessageID],N'EN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25.vldt' as [MessageID],N'KR' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25.vldt' as [MessageID],N'VN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25Att' as [MessageID],N'CN' as [Language],N'25Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25Att' as [MessageID],N'EN' as [Language],N'25th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'25Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26' as [MessageID],N'CN' as [Language],N'二十六' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26' as [MessageID],N'EN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26' as [MessageID],N'KR' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26' as [MessageID],N'VN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26.vldt' as [MessageID],N'EN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26.vldt' as [MessageID],N'KR' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26.vldt' as [MessageID],N'VN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26Att' as [MessageID],N'CN' as [Language],N'26Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26Att' as [MessageID],N'EN' as [Language],N'26th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'26Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27' as [MessageID],N'CN' as [Language],N'二十七' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27' as [MessageID],N'EN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27' as [MessageID],N'KR' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27' as [MessageID],N'VN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27.vldt' as [MessageID],N'EN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27.vldt' as [MessageID],N'KR' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27.vldt' as [MessageID],N'VN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27Att' as [MessageID],N'CN' as [Language],N'27Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27Att' as [MessageID],N'EN' as [Language],N'27th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'27Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28' as [MessageID],N'CN' as [Language],N'二十八' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28' as [MessageID],N'EN' as [Language],N'28' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28' as [MessageID],N'KR' as [Language],N'28' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28' as [MessageID],N'VN' as [Language],N'28' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28.vldt' as [MessageID],N'EN' as [Language],N'28' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28.vldt' as [MessageID],N'KR' as [Language],N'28' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28.vldt' as [MessageID],N'VN' as [Language],N'28' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28Att' as [MessageID],N'CN' as [Language],N'28Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28Att' as [MessageID],N'EN' as [Language],N'28th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'28Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29' as [MessageID],N'CN' as [Language],N'二十九' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29' as [MessageID],N'EN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29' as [MessageID],N'KR' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29' as [MessageID],N'VN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29.vldt' as [MessageID],N'EN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29.vldt' as [MessageID],N'KR' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29.vldt' as [MessageID],N'VN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29Att' as [MessageID],N'CN' as [Language],N'29Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29Att' as [MessageID],N'EN' as [Language],N'29th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'29Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2Att' as [MessageID],N'CN' as [Language],N'2Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2Att' as [MessageID],N'EN' as [Language],N'2nd' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3' as [MessageID],N'EN' as [Language],N'Foreign language allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3' as [MessageID],N'VN' as [Language],N'Foreign language allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3.vldt' as [MessageID],N'EN' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3.vldt' as [MessageID],N'KR' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3.vldt' as [MessageID],N'VN' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30' as [MessageID],N'CN' as [Language],N'三十' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30' as [MessageID],N'EN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30' as [MessageID],N'KR' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30' as [MessageID],N'VN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30.vldt' as [MessageID],N'EN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30.vldt' as [MessageID],N'KR' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30.vldt' as [MessageID],N'VN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30Att' as [MessageID],N'CN' as [Language],N'30Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30Att' as [MessageID],N'EN' as [Language],N'30th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'30Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'31' as [MessageID],N'EN' as [Language],N'31' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'31' as [MessageID],N'VN' as [Language],N'31' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'31Att' as [MessageID],N'CN' as [Language],N'31Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'31Att' as [MessageID],N'EN' as [Language],N'31st' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'31Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3Att' as [MessageID],N'CN' as [Language],N'3Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3Att' as [MessageID],N'EN' as [Language],N'3rd' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4' as [MessageID],N'EN' as [Language],N'Environmental allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4' as [MessageID],N'VN' as [Language],N'Environmental allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4.vldt' as [MessageID],N'EN' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4.vldt' as [MessageID],N'KR' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4.vldt' as [MessageID],N'VN' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'40' as [MessageID],N'VN' as [Language],N'40h' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'48' as [MessageID],N'VN' as [Language],N'48h' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4Att' as [MessageID],N'CN' as [Language],N'4Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4Att' as [MessageID],N'EN' as [Language],N'4th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5' as [MessageID],N'EN' as [Language],N'Shift allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5' as [MessageID],N'VN' as [Language],N'Shift allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5.vldt' as [MessageID],N'EN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5.vldt' as [MessageID],N'KR' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5.vldt' as [MessageID],N'VN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'53' as [MessageID],N'CN' as [Language],N'SECURITY: You have not authorized to access this function!' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'53' as [MessageID],N'EN' as [Language],N'SECURITY: You have not authorized to access this function!' as [Content],N'11' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'53' as [MessageID],N'VN' as [Language],N'Bảo mật: Bạn không có quyền truy cập chức năng này! ' as [Content],N'11' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5Att' as [MessageID],N'CN' as [Language],N'5Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5Att' as [MessageID],N'EN' as [Language],N'5th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6' as [MessageID],N'EN' as [Language],N'Fuel allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6' as [MessageID],N'VN' as [Language],N'Fuel allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6.vldt' as [MessageID],N'EN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6.vldt' as [MessageID],N'KR' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6.vldt' as [MessageID],N'VN' as [Language],N'6' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6Att' as [MessageID],N'CN' as [Language],N'6Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6Att' as [MessageID],N'EN' as [Language],N'6th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7' as [MessageID],N'EN' as [Language],N'Professional allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7' as [MessageID],N'VN' as [Language],N'Professional allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7.vldt' as [MessageID],N'EN' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7.vldt' as [MessageID],N'KR' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7.vldt' as [MessageID],N'VN' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7Att' as [MessageID],N'CN' as [Language],N'7Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7Att' as [MessageID],N'EN' as [Language],N'7th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8' as [MessageID],N'EN' as [Language],N'Attendance allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8' as [MessageID],N'VN' as [Language],N'Attendance allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8.vldt' as [MessageID],N'EN' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8.vldt' as [MessageID],N'KR' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8.vldt' as [MessageID],N'VN' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8Att' as [MessageID],N'CN' as [Language],N'8Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8Att' as [MessageID],N'EN' as [Language],N'8th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'8Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9' as [MessageID],N'EN' as [Language],N'Meal allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9' as [MessageID],N'VN' as [Language],N'Meal allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9.vldt' as [MessageID],N'EN' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9.vldt' as [MessageID],N'KR' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9.vldt' as [MessageID],N'VN' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9Att' as [MessageID],N'CN' as [Language],N'9Att' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9Att' as [MessageID],N'EN' as [Language],N'9th' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'9Att' as [MessageID],N'VN' as [Language],N'Att' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'A' as [MessageID],N'EN' as [Language],N'A' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'A' as [MessageID],N'VN' as [Language],N'A' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Actual_WorkingDays' as [MessageID],N'VN' as [Language],N'Ngày công thực tế' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'AWP' as [MessageID],N'EN' as [Language],N'AWP' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'AWP' as [MessageID],N'VN' as [Language],N'AWP' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'B1' as [MessageID],N'EN' as [Language],N'B1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'B1' as [MessageID],N'VN' as [Language],N'B1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'CN' as [Language],N'导出到Excel' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'EN' as [Language],N'Export to excel' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'JP' as [Language],N'リセット' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'KO' as [Language],N'엑셀로 내보내기' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'KR' as [Language],N'Export to excel' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'VN' as [Language],N'Xuất excel' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'CN' as [Language],N'新增' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'EN' as [Language],N'Add new' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'JP' as [Language],N'追加' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'KO' as [Language],N'새로 추가' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'KR' as [Language],N'Add new' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'VN' as [Language],N'Thêm mới' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWDelete' as [MessageID],N'CN' as [Language],N'删掉' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWDelete' as [MessageID],N'EN' as [Language],N'Delete' as [Content],N'36' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWDelete' as [MessageID],N'JP' as [Language],N'削除' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWDelete' as [MessageID],N'KO' as [Language],N'삭제' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWDelete' as [MessageID],N'KR' as [Language],N'Delete' as [Content],N'36' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWDelete' as [MessageID],N'VN' as [Language],N'Xóa bỏ' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'CN' as [Language],N'重做' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'EN' as [Language],N'Reset' as [Content],N'34' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'JP' as [Language],N'リセット' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'KO' as [Language],N'재실행' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'KR' as [Language],N'Reset' as [Content],N'34' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'VN' as [Language],N'Làm lại' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'CN' as [Language],N'保存数据' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'EN' as [Language],N'Save' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'JP' as [Language],N'保存' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'KO' as [Language],N'저장' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'BtnfwSave' as [MessageID],N'KR' as [Language],N'저장' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'VN' as [Language],N'Lưu' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnImport' as [MessageID],N'CN' as [Language],N'导入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnImport' as [MessageID],N'EN' as [Language],N'Import' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnImport' as [MessageID],N'KO' as [Language],N'들어가다' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnImport' as [MessageID],N'KR' as [Language],N'Import' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnImport' as [MessageID],N'VN' as [Language],N'Nhập vào' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'CN' as [Language],N'重新載入資料' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'EN' as [Language],N'Refresh' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'KO' as [Language],N'새로 고침' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'BtnReload' as [MessageID],N'KR' as [Language],N'새로 만들기' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'VN' as [Language],N'Làm Mới' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@month' as [MessageID],N'CN' as [Language],N'月份' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@month' as [MessageID],N'EN' as [Language],N'Month' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@month' as [MessageID],N'KO' as [Language],N'달' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@month' as [MessageID],N'VN' as [Language],N'Tháng' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@OptionView' as [MessageID],N'EN' as [Language],N'Option' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@OptionView' as [MessageID],N'VN' as [Language],N'Chế độ xem' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@Year' as [MessageID],N'CN' as [Language],N'年' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@Year' as [MessageID],N'EN' as [Language],N'Year' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@Year' as [MessageID],N'KO' as [Language],N'년' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'cbx@Year' as [MessageID],N'VN' as [Language],N'Năm' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ddbRptTemplates' as [MessageID],N'CN' as [Language],N'獲取導入模板文件' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ddbRptTemplates' as [MessageID],N'EN' as [Language],N'Get Import Template File' as [Content],N'3' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ddbRptTemplates' as [MessageID],N'KO' as [Language],N'언어 입력 템플릿 파일' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ddbRptTemplates' as [MessageID],N'KR' as [Language],N'잔업 신청서' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ddbRptTemplates' as [MessageID],N'VN' as [Language],N'File mẫu nhập ngôn ngữ' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'DepartmentName' as [MessageID],N'CN' as [Language],N'部门名称' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'DepartmentName' as [MessageID],N'EN' as [Language],N'Department name' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'DepartmentName' as [MessageID],N'VN' as [Language],N'Phòng ban' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'employeeid' as [MessageID],N'CN' as [Language],N'员工编号' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'employeeid' as [MessageID],N'EN' as [Language],N'Employee ID' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'EmployeeID' as [MessageID],N'JP' as [Language],N'従業員コード' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'employeeid' as [MessageID],N'KO' as [Language],N'직원 코드' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'EmployeeID' as [MessageID],N'KR' as [Language],N'사원 번호' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'employeeid' as [MessageID],N'VN' as [Language],N'Mã nhân viên' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'employeeid.vldt' as [MessageID],N'EN' as [Language],N'Employee code' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'EmployeeID.vldt' as [MessageID],N'JP' as [Language],N'従業員コード' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'EmployeeID.vldt' as [MessageID],N'KR' as [Language],N'사원 번호' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'employeeid.vldt' as [MessageID],N'VN' as [Language],N'Mã nhân viên' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName' as [MessageID],N'CN' as [Language],N'姓名' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName' as [MessageID],N'EN' as [Language],N'Full name' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName' as [MessageID],N'JP' as [Language],N'フルネーム' as [Content],N'400' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName' as [MessageID],N'KO' as [Language],N'직원 이름' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName' as [MessageID],N'KR' as [Language],N'날짜' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName' as [MessageID],N'VN' as [Language],N'Tên nhân viên' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName.vldt' as [MessageID],N'EN' as [Language],N'Staff''s name' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName.vldt' as [MessageID],N'JP' as [Language],N'フルネーム' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName.vldt' as [MessageID],N'KR' as [Language],N'날짜' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'FullName.vldt' as [MessageID],N'VN' as [Language],N'Tên nhân viên' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'grdTableEditor' as [MessageID],N'EN' as [Language],N'Training course list' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'grdTableEditor' as [MessageID],N'KR' as [Language],N'Training course list' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'grdTableEditor' as [MessageID],N'VN' as [Language],N'Danh sách đơn chờ duyệt' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate' as [MessageID],N'CN' as [Language],N'入职日期' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate' as [MessageID],N'EN' as [Language],N'Hire date' as [Content],N'23' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate' as [MessageID],N'KO' as [Language],N'하루는 일을 시작합니다' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate' as [MessageID],N'KR' as [Language],N'Join date' as [Content],N'23' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate' as [MessageID],N'VN' as [Language],N'Ngày bắt đầu vào làm' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate.vldt' as [MessageID],N'EN' as [Language],N'Join date' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate.vldt' as [MessageID],N'KR' as [Language],N'Join date' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'HireDate.vldt' as [MessageID],N'VN' as [Language],N'Ngày bắt đầu vào làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'IOHrs' as [MessageID],N'VN' as [Language],N'Trễ/sớm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item0' as [MessageID],N'CN' as [Language],N'修改密码' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item0' as [MessageID],N'EN' as [Language],N'item0' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item0' as [MessageID],N'KO' as [Language],N'월페이퍼' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item0' as [MessageID],N'KR' as [Language],N'승인 정보' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item0' as [MessageID],N'VN' as [Language],N'Hình nền' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item1' as [MessageID],N'CN' as [Language],N'年假' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item1' as [MessageID],N'EN' as [Language],N'annual leave' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item1' as [MessageID],N'KO' as [Language],N'연차' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item1' as [MessageID],N'KR' as [Language],N'신청 명단' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'item1' as [MessageID],N'VN' as [Language],N'Nghỉ phép năm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'L' as [MessageID],N'EN' as [Language],N'L' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'L' as [MessageID],N'VN' as [Language],N'L' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@month' as [MessageID],N'CN' as [Language],N'月份' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@month' as [MessageID],N'EN' as [Language],N'Month' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@month' as [MessageID],N'KO' as [Language],N'달' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@month' as [MessageID],N'VN' as [Language],N'Tháng' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@optionview' as [MessageID],N'CN' as [Language],N'选配' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@optionview' as [MessageID],N'EN' as [Language],N'Option' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@optionview' as [MessageID],N'VN' as [Language],N'Chế độ xem' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@Year' as [MessageID],N'CN' as [Language],N'年' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@Year' as [MessageID],N'EN' as [Language],N'Year' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@Year' as [MessageID],N'KO' as [Language],N'년' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lbl@Year' as [MessageID],N'VN' as [Language],N'Năm' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'CN' as [Language],N'搜索' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'EN' as [Language],N'Search' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'KO' as [Language],N'검색' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'KR' as [Language],N'검색' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'VN' as [Language],N'Tìm kiếm' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'CN' as [Language],N'影片播放清单' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'EN' as [Language],N'Resident address' as [Content],N'2' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'KO' as [Language],N'코드' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'KR' as [Language],N'Resident address' as [Content],N'2' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'VN' as [Language],N'Làm Mới' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'CN' as [Language],N'<color = crimson>如果更改标题，请单击新行以添加。生效日期无法更正，因此，如果生效日期不正确，请删除错误的行，然后添加一个新行以进行更正。</ color>' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'EN' as [Language],N'<color = crimson> If you change the title, click on a new line to add it. The effective date cannot be edited, so if the effective date is wrong, delete the wrong line, then add a new line to correct. </color>' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'KO' as [Language],N'<color = crimson> 제목을 변경하는 경우 추가 할 새 줄을 클릭하십시오. 유효 날짜를 편집 할 수 없으므로 유효 날짜가 틀린 경우 잘못된 줄을 삭제 한 다음 올바른 새 줄을 추가하십시오. </ color>' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'KR' as [Language],N'<color = crimson> If you change the title, click on a new line to add it. The effective date cannot be edited, so if the effective date is wrong, delete the wrong line, then add a new line to correct. </color>' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'VN' as [Language],N'<color=crimson>Nếu thay đổi chức danh thì bấm vào dòng mới để thêm.Ngày hiệu lực không sửa được nên nếu ngày hiệu lực sai thì xóa dòng sai đi, sau đó thêm 1 dòng mới cho đúng.</color>' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'M' as [MessageID],N'EN' as [Language],N'M' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'M' as [MessageID],N'VN' as [Language],N'M' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'M1' as [MessageID],N'EN' as [Language],N'M1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'M1' as [MessageID],N'VN' as [Language],N'M1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'MnuTAD999' as [MessageID],N'CN' as [Language],N'月度考勤汇总（标准数据设置）' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'MnuTAD999' as [MessageID],N'EN' as [Language],N'Timesheet' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'MnuTAD999' as [MessageID],N'VN' as [Language],N'Bảng tổng hợp công' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'O' as [MessageID],N'EN' as [Language],N'O' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'O' as [MessageID],N'VN' as [Language],N'O' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT1' as [MessageID],N'EN' as [Language],N'OT1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT1' as [MessageID],N'VN' as [Language],N'OT1 tính lương' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT2a' as [MessageID],N'EN' as [Language],N'OT2a' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT2a' as [MessageID],N'VN' as [Language],N'OT2a' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT3' as [MessageID],N'EN' as [Language],N'OT3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT3' as [MessageID],N'VN' as [Language],N'OT3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT4' as [MessageID],N'EN' as [Language],N'OT4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT4' as [MessageID],N'VN' as [Language],N'OT4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT5' as [MessageID],N'EN' as [Language],N'OT5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'OT5' as [MessageID],N'VN' as [Language],N'OT5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'P' as [MessageID],N'EN' as [Language],N'P' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'P' as [MessageID],N'VN' as [Language],N'P' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'PaidLeaveHrs' as [MessageID],N'EN' as [Language],N'Paid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'PaidLeaveHrs' as [MessageID],N'VN' as [Language],N'Paid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'plgfwcommand' as [MessageID],N'CN' as [Language],N'影片播放清单' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'plgfwcommand' as [MessageID],N'EN' as [Language],N'Resident address' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'plgfwcommand' as [MessageID],N'KR' as [Language],N'Resident address' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'plgFWCommand' as [MessageID],N'VN' as [Language],N'Chức năng toàn bộ máy chấm công' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'PositionName' as [MessageID],N'CN' as [Language],N'职位名称' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'PositionName' as [MessageID],N'EN' as [Language],N'Position name' as [Content],N'242' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'PositionName' as [MessageID],N'VN' as [Language],N'Chức danh' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ProbationEndDate' as [MessageID],N'CN' as [Language],N'试用期结束日期' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ProbationEndDate' as [MessageID],N'EN' as [Language],N'Probation end date' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ProbationEndDate' as [MessageID],N'VN' as [Language],N'Ngày kết thúc thử việc' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'CN' as [Language],N'根目錄' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'EN' as [Language],N'Root' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'KR' as [Language],N'Resident address' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'VN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'S' as [MessageID],N'EN' as [Language],N'S' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'S' as [MessageID],N'VN' as [Language],N'S' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'S2' as [MessageID],N'EN' as [Language],N'S2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'S2' as [MessageID],N'VN' as [Language],N'S2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.10Att' as [MessageID],N'EN' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.10Att' as [MessageID],N'VN' as [Language],N'10' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.10In' as [MessageID],N'CN' as [Language],N'[10]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.10Out' as [MessageID],N'CN' as [Language],N'[10]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.11Att' as [MessageID],N'EN' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.11Att' as [MessageID],N'VN' as [Language],N'11' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.11In' as [MessageID],N'CN' as [Language],N'[11]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.11Out' as [MessageID],N'CN' as [Language],N'[11]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.12Att' as [MessageID],N'EN' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.12Att' as [MessageID],N'VN' as [Language],N'12' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.12In' as [MessageID],N'CN' as [Language],N'[12]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.12Out' as [MessageID],N'CN' as [Language],N'[12]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.13Att' as [MessageID],N'EN' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.13Att' as [MessageID],N'VN' as [Language],N'13' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.13In' as [MessageID],N'CN' as [Language],N'[13]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.13Out' as [MessageID],N'CN' as [Language],N'[13]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.14Att' as [MessageID],N'EN' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.14Att' as [MessageID],N'VN' as [Language],N'14' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.14In' as [MessageID],N'CN' as [Language],N'[14]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.14Out' as [MessageID],N'CN' as [Language],N'[14]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.15Att' as [MessageID],N'EN' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.15Att' as [MessageID],N'VN' as [Language],N'15' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.15In' as [MessageID],N'CN' as [Language],N'[15]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.15Out' as [MessageID],N'CN' as [Language],N'[15]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Att' as [MessageID],N'CN' as [Language],N'十六' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Att' as [MessageID],N'EN' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Att' as [MessageID],N'VN' as [Language],N'16' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16In' as [MessageID],N'CN' as [Language],N'[16]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.16Out' as [MessageID],N'CN' as [Language],N'[16]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Att' as [MessageID],N'CN' as [Language],N'十七' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Att' as [MessageID],N'EN' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Att' as [MessageID],N'VN' as [Language],N'17' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17In' as [MessageID],N'CN' as [Language],N'[17]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.17Out' as [MessageID],N'CN' as [Language],N'[17]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Att' as [MessageID],N'CN' as [Language],N'十八' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Att' as [MessageID],N'EN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Att' as [MessageID],N'VN' as [Language],N'18' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18In' as [MessageID],N'CN' as [Language],N'[18]已进入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.18Out' as [MessageID],N'CN' as [Language],N'[18]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Att' as [MessageID],N'CN' as [Language],N'十九' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Att' as [MessageID],N'EN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Att' as [MessageID],N'VN' as [Language],N'19' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19In' as [MessageID],N'CN' as [Language],N'[19]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.19Out' as [MessageID],N'CN' as [Language],N'[19]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Att' as [MessageID],N'CN' as [Language],N'工作时间' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Att' as [MessageID],N'EN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Att' as [MessageID],N'VN' as [Language],N'1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1In' as [MessageID],N'CN' as [Language],N'在' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1In' as [MessageID],N'EN' as [Language],N'In' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1In' as [MessageID],N'VN' as [Language],N'Máy vào' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Out' as [MessageID],N'CN' as [Language],N'[1]出' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Out' as [MessageID],N'EN' as [Language],N'Out' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.1Out' as [MessageID],N'VN' as [Language],N'Ra' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Att' as [MessageID],N'CN' as [Language],N'二十' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Att' as [MessageID],N'EN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Att' as [MessageID],N'VN' as [Language],N'20' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20In' as [MessageID],N'CN' as [Language],N'[20]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.20Out' as [MessageID],N'CN' as [Language],N'[20]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Att' as [MessageID],N'CN' as [Language],N'二十一' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Att' as [MessageID],N'EN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Att' as [MessageID],N'VN' as [Language],N'21' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21In' as [MessageID],N'CN' as [Language],N'[21]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.21Out' as [MessageID],N'CN' as [Language],N'[21]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Att' as [MessageID],N'CN' as [Language],N'二十二' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Att' as [MessageID],N'EN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Att' as [MessageID],N'VN' as [Language],N'22' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22In' as [MessageID],N'CN' as [Language],N'[22]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.22Out' as [MessageID],N'CN' as [Language],N'[22]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Att' as [MessageID],N'CN' as [Language],N'二十三' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Att' as [MessageID],N'EN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Att' as [MessageID],N'VN' as [Language],N'23' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23In' as [MessageID],N'CN' as [Language],N'[23]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.23Out' as [MessageID],N'CN' as [Language],N'[23]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Att' as [MessageID],N'CN' as [Language],N'二十四' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Att' as [MessageID],N'EN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Att' as [MessageID],N'VN' as [Language],N'24' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24In' as [MessageID],N'CN' as [Language],N'[24]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.24Out' as [MessageID],N'CN' as [Language],N'[24]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Att' as [MessageID],N'CN' as [Language],N'二十五' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Att' as [MessageID],N'EN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Att' as [MessageID],N'VN' as [Language],N'25' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25In' as [MessageID],N'CN' as [Language],N'[25]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.25Out' as [MessageID],N'CN' as [Language],N'[25]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Att' as [MessageID],N'CN' as [Language],N'二十六' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Att' as [MessageID],N'EN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Att' as [MessageID],N'VN' as [Language],N'26' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26In' as [MessageID],N'CN' as [Language],N'[26]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.26Out' as [MessageID],N'CN' as [Language],N'[26]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Att' as [MessageID],N'CN' as [Language],N'二十七' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Att' as [MessageID],N'EN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Att' as [MessageID],N'VN' as [Language],N'27' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27In' as [MessageID],N'CN' as [Language],N'[27]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.27Out' as [MessageID],N'CN' as [Language],N'[27]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Att' as [MessageID],N'CN' as [Language],N'二十八' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Att' as [MessageID],N'EN' as [Language],N'28' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Att' as [MessageID],N'VN' as [Language],N'28' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28In' as [MessageID],N'CN' as [Language],N'[28]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.28Out' as [MessageID],N'CN' as [Language],N'[28]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Att' as [MessageID],N'CN' as [Language],N'二十九' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Att' as [MessageID],N'EN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Att' as [MessageID],N'VN' as [Language],N'29' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29In' as [MessageID],N'CN' as [Language],N'[29]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.29Out' as [MessageID],N'CN' as [Language],N'[29]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.2Att' as [MessageID],N'EN' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.2Att' as [MessageID],N'VN' as [Language],N'2' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.2In' as [MessageID],N'CN' as [Language],N'[2]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.2Out' as [MessageID],N'CN' as [Language],N'[2]出' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Att' as [MessageID],N'CN' as [Language],N'三十' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Att' as [MessageID],N'EN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Att' as [MessageID],N'VN' as [Language],N'30' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30In' as [MessageID],N'CN' as [Language],N'[30]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.30Out' as [MessageID],N'CN' as [Language],N'[30]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.31Att' as [MessageID],N'EN' as [Language],N'31' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.31Att' as [MessageID],N'VN' as [Language],N'31' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.31In' as [MessageID],N'CN' as [Language],N'[31]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.31Out' as [MessageID],N'CN' as [Language],N'[31]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.3Att' as [MessageID],N'EN' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.3Att' as [MessageID],N'VN' as [Language],N'3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.3In' as [MessageID],N'CN' as [Language],N'[3]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.3Out' as [MessageID],N'CN' as [Language],N'[3]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.4Att' as [MessageID],N'EN' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.4Att' as [MessageID],N'VN' as [Language],N'4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.4In' as [MessageID],N'CN' as [Language],N'[4]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.4Out' as [MessageID],N'CN' as [Language],N'[4]出' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.5Att' as [MessageID],N'EN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.5Att' as [MessageID],N'VN' as [Language],N'5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.5In' as [MessageID],N'CN' as [Language],N'[5]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.5Out' as [MessageID],N'CN' as [Language],N'[5]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.6Att' as [MessageID],N'EN' as [Language],N'6' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.6Att' as [MessageID],N'VN' as [Language],N'6' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.6In' as [MessageID],N'CN' as [Language],N'[6]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.6Out' as [MessageID],N'CN' as [Language],N'[6]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.7Att' as [MessageID],N'EN' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.7Att' as [MessageID],N'VN' as [Language],N'7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.7In' as [MessageID],N'CN' as [Language],N'[7]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.7Out' as [MessageID],N'CN' as [Language],N'[7]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.8Att' as [MessageID],N'EN' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.8Att' as [MessageID],N'VN' as [Language],N'8' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.8In' as [MessageID],N'CN' as [Language],N'[8]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.8Out' as [MessageID],N'CN' as [Language],N'[8]出' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.9Att' as [MessageID],N'EN' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.9Att' as [MessageID],N'VN' as [Language],N'9' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.9In' as [MessageID],N'CN' as [Language],N'[9]输入' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.9Out' as [MessageID],N'CN' as [Language],N'[9]外' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.Actual_WorkingDays' as [MessageID],N'VN' as [Language],N'Ngày công thực tế' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.AL' as [MessageID],N'CN' as [Language],N'海军陆战队' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.AttDays' as [MessageID],N'CN' as [Language],N'平日' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.AttDays' as [MessageID],N'VN' as [Language],N'Ngày thường' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.ATTHours' as [MessageID],N'CN' as [Language],N'总工作时间' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.ATTHours' as [MessageID],N'EN' as [Language],N'Total Hour' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.ATTHours' as [MessageID],N'VN' as [Language],N'Tổng giờ công' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_9' as [MessageID],N'EN' as [Language],N'9:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_EmployeeTypeID' as [MessageID],N'CN' as [Language],N'影片播放清单' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_EmployeeTypeID' as [MessageID],N'EN' as [Language],N'Resident address' as [Content],N'86' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_EmployeeTypeID' as [MessageID],N'VN' as [Language],N'Địa chỉ thường trú' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_K' as [MessageID],N'CN' as [Language],N'K：缺少' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_K' as [MessageID],N'EN' as [Language],N'K: Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_K' as [MessageID],N'VN' as [Language],N'K:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_NSCount' as [MessageID],N'CN' as [Language],N'夜津贴' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_NSCount' as [MessageID],N'EN' as [Language],N'Night allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_NSCount' as [MessageID],N'VN' as [Language],N'Phụ cấp đêm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_NSHour' as [MessageID],N'CN' as [Language],N'NSHour：缺少' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_NSHour' as [MessageID],N'EN' as [Language],N'NSHour: Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_NSHour' as [MessageID],N'VN' as [Language],N'NSHour:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT22' as [MessageID],N'CN' as [Language],N'OT22：缺少' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT22' as [MessageID],N'EN' as [Language],N'OT22: Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT22' as [MessageID],N'VN' as [Language],N'OT22:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT23' as [MessageID],N'CN' as [Language],N'OT23：缺少' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT23' as [MessageID],N'EN' as [Language],N'OT23: Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT23' as [MessageID],N'VN' as [Language],N'OT23:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT26' as [MessageID],N'CN' as [Language],N'夜津贴' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT26' as [MessageID],N'EN' as [Language],N'Night allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT26' as [MessageID],N'VN' as [Language],N'Phụ cấp đêm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT27' as [MessageID],N'CN' as [Language],N'随着时间的推移' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT27' as [MessageID],N'EN' as [Language],N'Overtime' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_OT27' as [MessageID],N'VN' as [Language],N'Tăng ca' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_SectionPriority' as [MessageID],N'EN' as [Language],N'SectionPriority:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_STT' as [MessageID],N'EN' as [Language],N'STT:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_WL' as [MessageID],N'EN' as [Language],N'WL:Missing' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_WPL' as [MessageID],N'CN' as [Language],N'休息日摘要' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_WPL' as [MessageID],N'EN' as [Language],N'Leave summary' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_WPL' as [MessageID],N'VN' as [Language],N'Thông tin nghỉ' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_xml' as [MessageID],N'CN' as [Language],N'合计' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_xml' as [MessageID],N'EN' as [Language],N'total' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.band_xml' as [MessageID],N'VN' as [Language],N'Tổng cộng' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.BDN' as [MessageID],N'CN' as [Language],N'BDN' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.cbx@DivisionID' as [MessageID],N'CN' as [Language],N'部門' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.ckb@FilterByDateRange' as [MessageID],N'EN' as [Language],N'Filter by date range' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.CO01' as [MessageID],N'CN' as [Language],N'CO01' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.CO02' as [MessageID],N'CN' as [Language],N'二氧化碳' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.Col1' as [MessageID],N'VN' as [Language],N'lblCol1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.DepartmentName' as [MessageID],N'VN' as [Language],N'Phòng ban' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.dtp@ToDate' as [MessageID],N'CN' as [Language],N'到' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.dtp@ToDate' as [MessageID],N'EN' as [Language],N'To' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.dtp@ToDate' as [MessageID],N'VN' as [Language],N'Làm thêm giờ dến khi' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_DataSetting.GeneralInfo' as [MessageID],N'VN' as [Language],N'Thông tin nhân viên員工資料' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.HireDate' as [MessageID],N'VN' as [Language],N'Ngày vào làm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.IOCount' as [MessageID],N'CN' as [Language],N'晚/早（次）' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.IOCount' as [MessageID],N'VN' as [Language],N'Số lần trễ/sớm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.IOHrs' as [MessageID],N'VN' as [Language],N'Trễ/
sớm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.IOSum' as [MessageID],N'VN' as [Language],N'Số phút trễ, sớm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.item0' as [MessageID],N'VN' as [Language],N'item0' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.item1' as [MessageID],N'VN' as [Language],N'item1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.LateEarlySixMinute' as [MessageID],N'VN' as [Language],N'Trễ, sớm trên 6 phút (công)' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@divisionid' as [MessageID],N'CN' as [Language],N'部門' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@employeeid_param' as [MessageID],N'CN' as [Language],N'員工工號' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@filterbydaterange' as [MessageID],N'EN' as [Language],N'Filter by date range' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@filterbydaterange' as [MessageID],N'VN' as [Language],N'Xem dữ liệu theo khoảng thời gian' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@fromdate' as [MessageID],N'CN' as [Language],N'從' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@fromdate' as [MessageID],N'VN' as [Language],N'Từ ngày' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@optionview' as [MessageID],N'VN' as [Language],N'Chế độ xem' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@todate' as [MessageID],N'CN' as [Language],N'到' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@todate' as [MessageID],N'EN' as [Language],N'To' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lbl@todate' as [MessageID],N'VN' as [Language],N'Đến ngày' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.lblCol1' as [MessageID],N'VN' as [Language],N'lblCol1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NDS' as [MessageID],N'CN' as [Language],N'NDS' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NSCount' as [MessageID],N'CN' as [Language],N'天數' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NSCount' as [MessageID],N'EN' as [Language],N'Number of days' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NSCount' as [MessageID],N'VN' as [Language],N'Số ngày' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NSHour' as [MessageID],N'CN' as [Language],N'那一刻' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NSHour' as [MessageID],N'EN' as [Language],N'Time' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NSHour' as [MessageID],N'VN' as [Language],N'Số giờ' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.NVS' as [MessageID],N'CN' as [Language],N'NVS' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.Oil_AL' as [MessageID],N'VN' as [Language],N'PC xăng' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT1' as [MessageID],N'EN' as [Language],N'OT1' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT11' as [MessageID],N'VN' as [Language],N'TC 150%' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT21' as [MessageID],N'VN' as [Language],N'Lễ 300%' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT22' as [MessageID],N'VN' as [Language],N'TC Đêm 210%' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.OT23' as [MessageID],N'CN' as [Language],N'CN 200％' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.OT23' as [MessageID],N'EN' as [Language],N'CN 200%' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.OT23' as [MessageID],N'VN' as [Language],N'CN 200%' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT26' as [MessageID],N'VN' as [Language],N'CN 270%' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT27' as [MessageID],N'VN' as [Language],N'Lễ đêm 390%' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT2a' as [MessageID],N'EN' as [Language],N'OT2a' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT2b' as [MessageID],N'EN' as [Language],N'OT2b' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT3' as [MessageID],N'EN' as [Language],N'OT3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT4' as [MessageID],N'EN' as [Language],N'OT4' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT5' as [MessageID],N'EN' as [Language],N'OT5' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT6' as [MessageID],N'EN' as [Language],N'OT6' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.OT7' as [MessageID],N'EN' as [Language],N'OT7' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PaidLeave' as [MessageID],N'EN' as [Language],N'Paid Leave Days' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PaidLeaveHrs' as [MessageID],N'EN' as [Language],N'Paid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PaidLeaveHrs' as [MessageID],N'VN' as [Language],N'Paid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.PaidLeaves' as [MessageID],N'CN' as [Language],N'带薪休假' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PaidLeaves' as [MessageID],N'VN' as [Language],N'Nghỉ hưởng lương' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PH' as [MessageID],N'VN' as [Language],N'PH' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.PL' as [MessageID],N'VN' as [Language],N'PL' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.plg_FWCommand' as [MessageID],N'VN' as [Language],N'plg_fwcommand:vn' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.PRG' as [MessageID],N'CN' as [Language],N'PRG' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.STD_WorkingDays' as [MessageID],N'CN' as [Language],N'標準工作天' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.STD_WorkingDays' as [MessageID],N'EN' as [Language],N'STD WKDs' as [Content],N'82' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.STD_WorkingDays' as [MessageID],N'VN' as [Language],N'Ngày công chuẩn' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalDayOff' as [MessageID],N'CN' as [Language],N'休假' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalDayOff' as [MessageID],N'VN' as [Language],N'Ngày nghỉ' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalNS' as [MessageID],N'VN' as [Language],N'NS Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.TotalOT' as [MessageID],N'VN' as [Language],N'Tổng OT' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.TotalPaidDays' as [MessageID],N'CN' as [Language],N'公开工资' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.TotalPaidDays' as [MessageID],N'EN' as [Language],N'Total paid days' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.TotalPaidDays' as [MessageID],N'VN' as [Language],N'Công hưởng lương' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.txt@OptionView' as [MessageID],N'VN' as [Language],N'Chế độ xem' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnpaidLeave' as [MessageID],N'CN' as [Language],N'无薪假期' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnpaidLeave' as [MessageID],N'EN' as [Language],N'Unpaid Leave' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnpaidLeave' as [MessageID],N'VN' as [Language],N'Unpaid Leave Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_AttendanceSummaryMonthly_STD_Datasetting.UnPaidLeaves' as [MessageID],N'CN' as [Language],N'无薪假期' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.UnPaidLeaves' as [MessageID],N'VN' as [Language],N'Nghỉ không lương' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.Workdays' as [MessageID],N'EN' as [Language],N'Working days' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.WorkHours' as [MessageID],N'EN' as [Language],N'Regular Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_attendancesummarymonthly_std_datasetting.WorkHours' as [MessageID],N'VN' as [Language],N'Regular Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'SP3' as [MessageID],N'EN' as [Language],N'SP3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'SP3' as [MessageID],N'VN' as [Language],N'SP3' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'STD_WorkingDays' as [MessageID],N'CN' as [Language],N'標準工作天' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'STD_WorkingDays' as [MessageID],N'EN' as [Language],N'Standard workday' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'STD_WorkingDays' as [MessageID],N'VN' as [Language],N'Ngày công chuẩn' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'STT' as [MessageID],N'CN' as [Language],N'不行' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'STT' as [MessageID],N'EN' as [Language],N'No' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'STT' as [MessageID],N'VN' as [Language],N'STT' as [Content],N'1' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalDayOff' as [MessageID],N'CN' as [Language],N'休假' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalDayOff' as [MessageID],N'VN' as [Language],N'Ngày nghỉ' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalNS' as [MessageID],N'VN' as [Language],N'NS Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalOT' as [MessageID],N'EN' as [Language],N'Total OT' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalOT' as [MessageID],N'VN' as [Language],N'Tổng OT
(Chưa quy đổi' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalPaidDays' as [MessageID],N'CN' as [Language],N'公开工资' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalPaidDays' as [MessageID],N'EN' as [Language],N'Total paid days' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'TotalPaidDays' as [MessageID],N'VN' as [Language],N'Công hưởng lương' as [Content],N'1' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'CN' as [Language],N'筛选条件' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'EN' as [Language],N'Filter' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'KR' as [Language],N'검색' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'VN' as [Language],N'Tìm kiếm' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'UnpaidLeave' as [MessageID],N'CN' as [Language],N'无薪假期' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'UnpaidLeave' as [MessageID],N'EN' as [Language],N'Unpaid leave' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'UnpaidLeave' as [MessageID],N'VN' as [Language],N'Nghỉ không lương' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'WorkHours' as [MessageID],N'EN' as [Language],N'Regular Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'WorkHours' as [MessageID],N'VN' as [Language],N'Regular Hrs' as [Content],NULL as [Frequency],NULL as [IgnorePending]
EXEC sp_SaveData  @TableNameTmp = '#tblMD_Message' , @TableName = 'tblMD_Message' , @Command = 'insert' , @IsDropTableTmp =0,@IsPrint=0IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
--#endregion _
GO

--#region tblProcedureName
IF OBJECT_ID('tempdb..#tblProcedureName') IS NOT NULL DROP TABLE #tblProcedureName
  create table #tblProcedureName (
   [ProcID] [int] NULL 
 , [ObjectID] [int] NULL 
 , [ProcName] [nvarchar](MAX) NULL 
 , [TemplateName] [nvarchar](MAX) NULL 
 , [Descriptions] [nvarchar](MAX) NULL 
 , [AutoGen] [bit] NULL 
 , [FixedParamter] [nvarchar](MAX) NULL 
 , [StartRow] [int] NULL 
 , [PreProcedureName] [nvarchar](MAX) NULL 
 , [PostProcedureName] [nvarchar](MAX) NULL 
 , [BlockImport] [bit] NULL 
 , [DontAlterMissingColumn] [bit] NULL 
 , [IsImportUsingEntireTable] [bit] NULL 
 , [FollowThreeStepImport] [nvarchar](MAX) NULL 
 , [PostCommand] [nvarchar](MAX) NULL 
 , [IsFollowThreeStepImport] [bit] NULL 
 , [AutoInsertUpdateToTable] [nvarchar](MAX) NULL 
 , [ParamDefineRowPosition] [int] NULL 
 , [TemplateBinary] varbinary(max) NULL 
 , [TemplateBinary_FilenName] [nvarchar](MAX) NULL 
 , [TemplateBinary_filename] [nvarchar](MAX) NULL 
 , [ImportSheetName] [nvarchar](MAX) NULL 
 , [DescriptionsEN] [nvarchar](MAX) NULL 
 , [DescriptionsLA] [nvarchar](MAX) NULL 
 , [IsImportAllSheet] [bit] NULL 
 , [FolderFilesCount] [int] NULL 
 , [TypeImport] [int] NULL 
 , [TypeImportRow] [int] NULL 
)

 INSERT INTO #tblProcedureName([ProcID],[ObjectID],[ProcName],[TemplateName],[Descriptions],[AutoGen],[FixedParamter],[StartRow],[PreProcedureName],[PostProcedureName],[BlockImport],[DontAlterMissingColumn],[IsImportUsingEntireTable],[FollowThreeStepImport],[PostCommand],[IsFollowThreeStepImport],[AutoInsertUpdateToTable],[ParamDefineRowPosition],[TemplateBinary],[TemplateBinary_FilenName],[TemplateBinary_filename],[ImportSheetName],[DescriptionsEN],[DescriptionsLA],[IsImportAllSheet],[FolderFilesCount],[TypeImport],[TypeImportRow])
Select  N'145' as [ProcID],N'501' as [ObjectID],N'ImportTimeSheet' as [ProcName],N'ImportAttendanceSheetToRawData' as [TemplateName],N'Nhập dữ liệu chấm công, timesheet' as [Descriptions],N'False' as [AutoGen],NULL as [FixedParamter],N'10' as [StartRow],NULL as [PreProcedureName],NULL as [PostProcedureName],NULL as [BlockImport],NULL as [DontAlterMissingColumn],N'True' as [IsImportUsingEntireTable],N'Template_ImportTimeSheet' as [FollowThreeStepImport],NULL as [PostCommand],N'True' as [IsFollowThreeStepImport],NULL as [AutoInsertUpdateToTable],NULL as [ParamDefineRowPosition],NULL as [TemplateBinary],NULL as [TemplateBinary_FilenName],NULL as [TemplateBinary_filename],NULL as [ImportSheetName],N'Import Timekeeping data, timesheet' as [DescriptionsEN],NULL as [DescriptionsLA],NULL as [IsImportAllSheet],NULL as [FolderFilesCount],NULL as [TypeImport],NULL as [TypeImportRow]

EXEC sp_SaveData  @TableNameTmp = '#tblProcedureName' , @TableName = 'tblProcedureName' , @Command = 'DeleteNot',@ColumnDeleteNot='TemplateName' , @IsDropTableTmp =0,@IsPrint=0
EXEC sp_SaveData  @TableNameTmp = '#tblProcedureName' , @TableName = 'tblProcedureName' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0
IF OBJECT_ID('tempdb..#tblProcedureName') IS NOT NULL DROP TABLE #tblProcedureName
--#endregion _


