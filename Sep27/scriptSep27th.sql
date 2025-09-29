
if object_id('[dbo].[sp_processSummaryAttendance]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_processSummaryAttendance] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_processSummaryAttendance] (@LoginID INT, @Year INT, @Month INT, @ViewType INT = 0, @Payroll BIT = 0)
AS
BEGIN
	ALTER TABLE tblOvertimeSetting ALTER COLUMN ColumnDisplayName NVARCHAR(100) NOT NULL
	--View Type: 0: 0 view chỉ process, 1: view summary, 2: view in-out chi tiết
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	--LeaveType
	DECLARE @Query NVARCHAR(MAX) = ''

	SELECT @Query += N'IF COL_LENGTH(''tblAttendanceSummary'',''' + LeaveCode + N''') is null
                        ALTER TABLE tblAttendanceSummary ADD [' + LeaveCode + N'] FLOAT;'
	FROM tblLeaveType
	WHERE IsVisible = 1

	EXEC (@Query)

	SELECT *
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1 = 0

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
	UPDATE #EmployeeList
	SET EmployeeStatusID = stt.EmployeeStatusID
	FROM #EmployeeList te
	INNER JOIN #fn_EmployeeStatus_ByDate stt ON te.EmployeeID = stt.EmployeeID
	WHERE te.EmployeeStatusID <> stt.EmployeeStatusID

	UPDATE #EmployeeList
	SET EmployeeStatusID = stt.EmployeeStatusID, TerminateDate = stt.ChangedDate, LastWorkingDate = dateadd(dd, - 1, stt.ChangedDate)
	FROM #EmployeeList te
	INNER JOIN #fn_EmployeeStatus_ByDate_FirstLastMonth stt ON te.EmployeeID = stt.EmployeeID
	WHERE stt.EmployeeStatusID = 20

	UPDATE #EmployeeList
	SET TerminatedStaff = 1
	WHERE TerminateDate IS NOT NULL

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

	INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, PercentProbation)
	SELECT @Year, @Month, sh.EmployeeID, 1, sh.SalaryHistoryID, CASE
			WHEN sh.DATE < @FromDate
				THEN @FromDate
			ELSE sh.DATE
			END, @ToDate, te.PercentProbation
	FROM #EmployeeList te
	INNER JOIN tblSalaryHistory sh ON te.EmployeeID = sh.EmployeeID
	WHERE sh.SalaryHistoryID NOT IN (
			SELECT SalaryHistoryID
			FROM #CurrentSalary
			) AND [Date] > @FromDate AND NOT EXISTS (
			SELECT 1
			FROM #tblAttendanceSummary s
			WHERE sh.SalaryHistoryID = s.SalaryHistoryID
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
	SET RegularWorkdays = ISNULL(RegularWorkdays, 0), WorkingHrs_Total = (RegularWorkdays * 8), WorkingDays_Total = RegularWorkdays
	FROM #tblAttendanceSummary att
	INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
	WHERE ISNULL(e.IsForeign, 0) = 1 AND (e.HireDate <= @FromDate AND (e.TerminateDate IS NULL OR e.TerminateDate >= @ToDate))

	DECLARE @cols NVARCHAR(MAX), @assign NVARCHAR(MAX), @sql NVARCHAR(MAX)

	SELECT @cols = STUFF((
				SELECT ',' + QUOTENAME(LeaveCode)
				FROM tblLeaveType
				WHERE IsVisible = 1
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(LeaveCode) + ' = ISNULL(p.' + QUOTENAME(LeaveCode) + ',0)'
				FROM tblLeaveType
				WHERE IsVisible = 1
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

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

	SELECT @cols = STUFF((
				SELECT ',' + QUOTENAME(name)
				FROM sys.all_columns
				WHERE object_id = OBJECT_ID('tblAttendanceSummary')
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	-- Insert processed summary rows from temp table into permanent table
	SET @sql = '
	INSERT INTO tblAttendanceSummary (' + @cols + N')
	SELECT ' + @cols + N'
	FROM #tblAttendanceSummary'

	EXEC sp_executesql @sql

	SET @assign = ''

	SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ',0), ' + 's.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ', 0)'
				FROM tblOvertimeSetting
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

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

	IF COL_LENGTH('tblSal_Sal_Detail', 'RegularAmt') IS NULL
	BEGIN
		ALTER TABLE tblSal_Sal_Detail ADD RegularAmt MONEY
	END

	IF COL_LENGTH('tblSal_Sal_Detail', 'PaidLeaveAmt') IS NULL
	BEGIN
		ALTER TABLE tblSal_Sal_Detail ADD PaidLeaveAmt MONEY
	END

	IF COL_LENGTH('tblSal_Sal_Detail', 'GrossSalary') IS NULL
	BEGIN
		ALTER TABLE tblSal_Sal_Detail ADD GrossSalary MONEY
	END

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
		, ROUND(a.TotalOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) TotalOTAmount, ROUND(SUM(NightShiftAmount), @ROUND_OT_NS_Detail_UNIT) NightShiftAmount, a.FromDate, a.ToDate
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




if object_id('[dbo].[sp_accumulatedOT]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_accumulatedOT] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_accumulatedOT] @LoginID INT, @Month INT, @Year INT, @MaxOT FLOAT = 40.0, @isView BIT = 0, @isExcess BIT = 0
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	IF ISNULL(@MaxOT, 0) = 0
	BEGIN
		SET @MaxOT = 40.0
	END

	SELECT e.EmployeeID, FullName, d.DepartmentID, DepartmentName, p.PositionID, PositionName, HireDate, LastWorkingDate
	INTO #tmpEMP
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) e
	LEFT JOIN tblDepartment d ON e.DepartmentID = d.DepartmentID
	LEFT JOIN tblPosition p ON e.PositionID = p.PositionID

	DELETE #tmpEMP
	WHERE HireDate > @ToDate OR LastWorkingDate < @FromDate

	SELECT a.*
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary a
	INNER JOIN #tmpEMP t ON a.EmployeeID = t.EmployeeID
	WHERE Year = @Year AND Month = @Month

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind, ots.ColumnDisplayName OTType, te.FromDate, te.ToDate
	INTO #OTList
	FROM tblOTList ot
	INNER JOIN #tblAttendanceSummary te ON ot.EmployeeID = te.EmployeeID AND ot.OTDate BETWEEN te.FromDate AND te.ToDate
	INNER JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OTKind
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0


	SELECT EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType, FromDate, ToDate
	INTO #tblOTSummary
	FROM #OTList
	GROUP BY EmployeeID, OTKind, OTType, FromDate, ToDate

	DELETE
	FROM #tmpEMP
	WHERE EmployeeID NOT IN (
			SELECT DISTINCT EmployeeID
			FROM #tblOTSummary
			)

	SELECT *
	INTO #tblOvertimeSetting
	FROM tblOvertimeSetting

	-- WHERE OTKind IN (
	-- 		SELECT DISTINCT OTKind
	-- 		FROM #tblOTSummary
	-- 		WHERE ISNULL(OTKind, '') <> ''
	-- 		)
	IF NOT EXISTS (
			SELECT *
			FROM #tblOTSummary
			)
	BEGIN
		RETURN
	END

	CREATE TABLE #SummaryData (STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), HireDate DATE, FromDate DATE, ToDate DATE, PeriodID INT)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, DepartmentName, FromDate, ToDate, PeriodID)
	SELECT ROW_NUMBER() OVER (
			ORDER BY t.EmployeeID
			), t.EmployeeID, FullName, t.HireDate, ISNULL(DepartmentName, ''), FromDate, ToDate, ROW_NUMBER() OVER (
			ORDER BY FromDate ASC
			) AS PeriodID
	FROM #tmpEMP t
	INNER JOIN #tblAttendanceSummary a ON t.EmployeeID = a.EmployeeID

	--Xoá các dòng k có OT
	DELETE s
	FROM #SummaryData s
	LEFT JOIN #tblOTSummary o ON s.EmployeeID = o.EmployeeID AND s.FromDate = o.FromDate AND s.ToDate = o.ToDate
	WHERE o.EmployeeID IS NULL

	DECLARE @assign NVARCHAR(MAX) = '', @Query NVARCHAR(MAX) = 'ALTER TABLE #SummaryData ADD '

	SELECT @Query += ISNULL(ColumnDisplayName, '') + '_Total DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + ' DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + '_ExcessOT DECIMAL(10, 2),'
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	SELECT @Query += ' TotalOT DECIMAL(10, 2), TotalExcessOT DECIMAL(10, 2), TotalExcessOT_Raw DECIMAL(10, 2)'

	EXEC sp_executesql @Query

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(ColumnDisplayName, '') + '] = ISNULL(w.ApprovedHours, 0),
                                    [' + ISNULL(ColumnDisplayName, '') + '_Total] = ISNULL(w.ApprovedHours, 0)
                        FROM #SummaryData s
                        LEFT JOIN #tblOTSummary w ON s.EmployeeID = w.EmployeeID AND s.FromDate = w.FromDate AND s.ToDate = w.ToDate
                        WHERE w.OTType = ''' + ISNULL(ColumnDisplayName, '') + N''';'
	FROM #tblOvertimeSetting

	EXEC sp_executesql @Query

	UPDATE s
	SET TotalOT = ISNULL(a.SumOTHours, 0)
	FROM #SummaryData s
	INNER JOIN (
		SELECT EmployeeID, FromDate, ToDate, SUM(ApprovedHours) SumOTHours
		FROM #tblOTSummary
		GROUP BY EmployeeID, FromDate, ToDate
		) a ON a.EmployeeID = s.EmployeeID AND a.FromDate = s.FromDate AND a.ToDate = s.ToDate

    UPDATE a SET TotalOT = s.TotalOT
    FROM tblAttendanceSummary a
    INNER JOIN #SummaryData s ON a.EmployeeID = s.EmployeeID AND a.FromDate = s.FromDate AND a.ToDate = s.ToDate
    WHERE a.Year = @Year AND a.Month = @Month

	-- Tạo bảng tạm lưu loại OT theo thứ tự
	DECLARE @OTTypes TABLE (ColumnDisplayName NVARCHAR(MAX), SortOrder INT IDENTITY(1, 1))

	INSERT INTO @OTTypes (ColumnDisplayName)
	SELECT ColumnDisplayName
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName DESC

	DECLARE @EmployeeID VARCHAR(20), @Type NVARCHAR(MAX), @CurrentHours DECIMAL(10, 2), @Remaining DECIMAL(10, 2)

	DECLARE emp_cursor CURSOR
	FOR
	SELECT DISTINCT EmployeeID
	FROM #SummaryData

	OPEN emp_cursor

	FETCH NEXT
	FROM emp_cursor
	INTO @EmployeeID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @Remaining = @MaxOT

		-- Lấy các dòng của nhân viên, sắp xếp theo PeriodID ASC
		DECLARE period_cursor CURSOR
		FOR
		SELECT PeriodID
		FROM #SummaryData
		WHERE EmployeeID = @EmployeeID
		ORDER BY PeriodID ASC

		DECLARE @PeriodID INT

		OPEN period_cursor

		FETCH NEXT
		FROM period_cursor
		INTO @PeriodID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE type_cursor CURSOR
			FOR
			SELECT ColumnDisplayName
			FROM @OTTypes
			ORDER BY SortOrder ASC

			OPEN type_cursor

			FETCH NEXT
			FROM type_cursor
			INTO @Type

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Lấy số giờ OT hiện tại cho dòng này
				DECLARE @sql NVARCHAR(MAX), @val DECIMAL(10, 2)

				SET @sql = N'SELECT @val = ISNULL(' + QUOTENAME(@Type) + N', 0) FROM #SummaryData WHERE EmployeeID = @EmpID AND PeriodID = @PerID'

				EXEC sp_executesql @sql, N'@val DECIMAL(10,2) OUTPUT, @EmpID VARCHAR(20), @PerID INT', @val OUTPUT, @EmployeeID, @PeriodID

				SET @CurrentHours = @val

				IF @Remaining > 0
				BEGIN
					IF @CurrentHours <= @Remaining
					BEGIN
						SET @Remaining = @Remaining - @CurrentHours
					END
					ELSE
					BEGIN
						-- Gán tối đa @Remaining cho cột OT, phần còn lại sang ExcessOT
						SET @Query = N'UPDATE #SummaryData SET ' + QUOTENAME(@Type) + N' = @Rem, ' + QUOTENAME(@Type + '_ExcessOT') + N' = ISNULL(' + QUOTENAME(@Type + '_ExcessOT') + N', 0) + (@Curr - @Rem) WHERE EmployeeID = @Emp AND PeriodID = @PerID'

						EXEC sp_executesql @Query, N'@Rem DECIMAL(10,2), @Curr DECIMAL(10,2), @Emp VARCHAR(20), @PerID INT', @Rem = @Remaining, @Curr = @CurrentHours, @Emp = @EmployeeID, @PerID = @PeriodID

						SET @Remaining = 0
					END
				END
				ELSE
				BEGIN
					-- Chuyển toàn bộ sang ExcessOT và set OT = 0
					SET @Query = N'UPDATE #SummaryData SET ' + QUOTENAME(@Type) + N' = 0, ' + QUOTENAME(@Type + '_ExcessOT') + N' = ISNULL(' + QUOTENAME(@Type + '_ExcessOT') + N', 0) + @Curr WHERE EmployeeID = @Emp AND PeriodID = @PerID'

					EXEC sp_executesql @Query, N'@Curr DECIMAL(10,2), @Emp VARCHAR(20), @PerID INT', @Curr = @CurrentHours, @Emp = @EmployeeID, @PerID = @PeriodID
				END

				FETCH NEXT
				FROM type_cursor
				INTO @Type
			END

			CLOSE type_cursor

			DEALLOCATE type_cursor

			FETCH NEXT
			FROM period_cursor
			INTO @PeriodID
		END

		CLOSE period_cursor

		DEALLOCATE period_cursor

		FETCH NEXT
		FROM emp_cursor
		INTO @EmployeeID
	END

	CLOSE emp_cursor

	DEALLOCATE emp_cursor


	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' '

	EXEC sp_executesql @Query

	-- SET @Query = 'ALTER TABLE tblAttendanceSummary ADD '
	-- SELECT @Query += ISNULL(ColumnDisplayName, '') + ' FLOAT,' + ISNULL(ColumnDisplayName, '') + '_ExcessOT FLOAT,'
	-- FROM tblOvertimeSetting
	-- ORDER BY ColumnDisplayName ASC
	-- SELECT @Query += ' TotalOT FLOAT, TaxableOT FLOAT, NontaxableOT FLOAT, TotalExcessOT FLOAT'
	-- EXEC sp_executesql @Query

    SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ',0), ' + 's.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ', 0)'
				FROM #tblOvertimeSetting
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	SET @Query = ''

	SELECT @Query += '
    UPDATE s SET  ' + @assign + '
    FROM tblAttendanceSummary s
    LEFT JOIN #SummaryData p ON s.EmployeeID = p.EmployeeID AND s.FromDate = p.FromDate AND s.ToDate = p.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ' AND ISNULL(s.DateStatus, 0) <> 3'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT_Raw = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT, 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM #SummaryData d
    INNER JOIN tblAttendanceSummary s ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET NonTaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N' * ' + CAST((
				CASE
					WHEN OvValue - 100 > 0
						THEN OvValue - 100
					ELSE 0
					END
				) / 100 AS VARCHAR(5)) + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	IF ISNULL(@isView, '') = 0
		SELECT a.EmployeeID, d.FullName, d.DepartmentName, d.HireDate, d.TotalOT, d.TotalExcessOT, d.TotalExcessOT_Raw, a.[Month], a.[Year], a.PeriodID, d.OT1_Total, a.OT1, a.OT1_ExcessOT, d.OT2a_Total, a.OT2a, a.OT2a_ExcessOT, d.OT2b_Total, a.OT2b, a.OT2b_ExcessOT, d.OT3_Total, a.OT3, a.OT3_ExcessOT, d.OT4_Total, a.OT4, a.OT4_ExcessOT, d.OT5_Total, a.OT5, a.OT5_ExcessOT, d.OT6_Total, a.OT6, a.OT6_ExcessOT, d.OT7_Total, a.OT7, a.OT7_ExcessOT, a.DateStatus
		FROM tblAttendanceSummary a
		INNER JOIN #SummaryData d ON a.EmployeeID = d.EmployeeID AND a.FromDate = d.FromDate AND a.ToDate = d.ToDate
		WHERE a.Year = @Year AND a.Month = @Month AND (ISNULL(@isExcess, 0) = 0 OR (ISNULL(@isExcess, 0) = 1 AND d.TotalExcessOT > 0))
END
--exec sp_accumulatedOT 3,7,2025
GOUSE Paradise_TRIPOD
GO
if object_id('[dbo].[sp_accumulatedOT]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_accumulatedOT] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_accumulatedOT] @LoginID INT, @Month INT, @Year INT, @MaxOT FLOAT = 40.0, @isView BIT = 0, @isExcess BIT = 0
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	IF ISNULL(@MaxOT, 0) = 0
	BEGIN
		SET @MaxOT = 40.0
	END

	SELECT e.EmployeeID, FullName, d.DepartmentID, DepartmentName, p.PositionID, PositionName, HireDate, LastWorkingDate
	INTO #tmpEMP
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) e
	LEFT JOIN tblDepartment d ON e.DepartmentID = d.DepartmentID
	LEFT JOIN tblPosition p ON e.PositionID = p.PositionID

	DELETE #tmpEMP
	WHERE HireDate > @ToDate OR LastWorkingDate < @FromDate

	SELECT a.*
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary a
	INNER JOIN #tmpEMP t ON a.EmployeeID = t.EmployeeID
	WHERE Year = @Year AND Month = @Month

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind, ots.ColumnDisplayName OTType, te.FromDate, te.ToDate
	INTO #OTList
	FROM tblOTList ot
	INNER JOIN #tblAttendanceSummary te ON ot.EmployeeID = te.EmployeeID AND ot.OTDate BETWEEN te.FromDate AND te.ToDate
	INNER JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OTKind
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0


	SELECT EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType, FromDate, ToDate
	INTO #tblOTSummary
	FROM #OTList
	GROUP BY EmployeeID, OTKind, OTType, FromDate, ToDate

	DELETE
	FROM #tmpEMP
	WHERE EmployeeID NOT IN (
			SELECT DISTINCT EmployeeID
			FROM #tblOTSummary
			)

	SELECT *
	INTO #tblOvertimeSetting
	FROM tblOvertimeSetting

	-- WHERE OTKind IN (
	-- 		SELECT DISTINCT OTKind
	-- 		FROM #tblOTSummary
	-- 		WHERE ISNULL(OTKind, '') <> ''
	-- 		)
	IF NOT EXISTS (
			SELECT *
			FROM #tblOTSummary
			)
	BEGIN
		RETURN
	END

	CREATE TABLE #SummaryData (STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), HireDate DATE, FromDate DATE, ToDate DATE, PeriodID INT)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, DepartmentName, FromDate, ToDate, PeriodID)
	SELECT ROW_NUMBER() OVER (
			ORDER BY t.EmployeeID
			), t.EmployeeID, FullName, t.HireDate, ISNULL(DepartmentName, ''), FromDate, ToDate, ROW_NUMBER() OVER (
			ORDER BY FromDate ASC
			) AS PeriodID
	FROM #tmpEMP t
	INNER JOIN #tblAttendanceSummary a ON t.EmployeeID = a.EmployeeID

	--Xoá các dòng k có OT
	DELETE s
	FROM #SummaryData s
	LEFT JOIN #tblOTSummary o ON s.EmployeeID = o.EmployeeID AND s.FromDate = o.FromDate AND s.ToDate = o.ToDate
	WHERE o.EmployeeID IS NULL

	DECLARE @assign NVARCHAR(MAX) = '', @Query NVARCHAR(MAX) = 'ALTER TABLE #SummaryData ADD '

	SELECT @Query += ISNULL(ColumnDisplayName, '') + '_Total DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + ' DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + '_ExcessOT DECIMAL(10, 2),'
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	SELECT @Query += ' TotalOT DECIMAL(10, 2), TotalExcessOT DECIMAL(10, 2), TotalExcessOT_Raw DECIMAL(10, 2)'

	EXEC sp_executesql @Query

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(ColumnDisplayName, '') + '] = ISNULL(w.ApprovedHours, 0),
                                    [' + ISNULL(ColumnDisplayName, '') + '_Total] = ISNULL(w.ApprovedHours, 0)
                        FROM #SummaryData s
                        LEFT JOIN #tblOTSummary w ON s.EmployeeID = w.EmployeeID AND s.FromDate = w.FromDate AND s.ToDate = w.ToDate
                        WHERE w.OTType = ''' + ISNULL(ColumnDisplayName, '') + N''';'
	FROM #tblOvertimeSetting

	EXEC sp_executesql @Query

	UPDATE s
	SET TotalOT = ISNULL(a.SumOTHours, 0)
	FROM #SummaryData s
	INNER JOIN (
		SELECT EmployeeID, FromDate, ToDate, SUM(ApprovedHours) SumOTHours
		FROM #tblOTSummary
		GROUP BY EmployeeID, FromDate, ToDate
		) a ON a.EmployeeID = s.EmployeeID AND a.FromDate = s.FromDate AND a.ToDate = s.ToDate

    UPDATE a SET TotalOT = s.TotalOT
    FROM tblAttendanceSummary a
    INNER JOIN #SummaryData s ON a.EmployeeID = s.EmployeeID AND a.FromDate = s.FromDate AND a.ToDate = s.ToDate
    WHERE a.Year = @Year AND a.Month = @Month

	-- Tạo bảng tạm lưu loại OT theo thứ tự
	DECLARE @OTTypes TABLE (ColumnDisplayName NVARCHAR(MAX), SortOrder INT IDENTITY(1, 1))

	INSERT INTO @OTTypes (ColumnDisplayName)
	SELECT ColumnDisplayName
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName DESC

	DECLARE @EmployeeID VARCHAR(20), @Type NVARCHAR(MAX), @CurrentHours DECIMAL(10, 2), @Remaining DECIMAL(10, 2)

	DECLARE emp_cursor CURSOR
	FOR
	SELECT DISTINCT EmployeeID
	FROM #SummaryData

	OPEN emp_cursor

	FETCH NEXT
	FROM emp_cursor
	INTO @EmployeeID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @Remaining = @MaxOT

		-- Lấy các dòng của nhân viên, sắp xếp theo PeriodID ASC
		DECLARE period_cursor CURSOR
		FOR
		SELECT PeriodID
		FROM #SummaryData
		WHERE EmployeeID = @EmployeeID
		ORDER BY PeriodID ASC

		DECLARE @PeriodID INT

		OPEN period_cursor

		FETCH NEXT
		FROM period_cursor
		INTO @PeriodID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE type_cursor CURSOR
			FOR
			SELECT ColumnDisplayName
			FROM @OTTypes
			ORDER BY SortOrder ASC

			OPEN type_cursor

			FETCH NEXT
			FROM type_cursor
			INTO @Type

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Lấy số giờ OT hiện tại cho dòng này
				DECLARE @sql NVARCHAR(MAX), @val DECIMAL(10, 2)

				SET @sql = N'SELECT @val = ISNULL(' + QUOTENAME(@Type) + N', 0) FROM #SummaryData WHERE EmployeeID = @EmpID AND PeriodID = @PerID'

				EXEC sp_executesql @sql, N'@val DECIMAL(10,2) OUTPUT, @EmpID VARCHAR(20), @PerID INT', @val OUTPUT, @EmployeeID, @PeriodID

				SET @CurrentHours = @val

				IF @Remaining > 0
				BEGIN
					IF @CurrentHours <= @Remaining
					BEGIN
						SET @Remaining = @Remaining - @CurrentHours
					END
					ELSE
					BEGIN
						-- Gán tối đa @Remaining cho cột OT, phần còn lại sang ExcessOT
						SET @Query = N'UPDATE #SummaryData SET ' + QUOTENAME(@Type) + N' = @Rem, ' + QUOTENAME(@Type + '_ExcessOT') + N' = ISNULL(' + QUOTENAME(@Type + '_ExcessOT') + N', 0) + (@Curr - @Rem) WHERE EmployeeID = @Emp AND PeriodID = @PerID'

						EXEC sp_executesql @Query, N'@Rem DECIMAL(10,2), @Curr DECIMAL(10,2), @Emp VARCHAR(20), @PerID INT', @Rem = @Remaining, @Curr = @CurrentHours, @Emp = @EmployeeID, @PerID = @PeriodID

						SET @Remaining = 0
					END
				END
				ELSE
				BEGIN
					-- Chuyển toàn bộ sang ExcessOT và set OT = 0
					SET @Query = N'UPDATE #SummaryData SET ' + QUOTENAME(@Type) + N' = 0, ' + QUOTENAME(@Type + '_ExcessOT') + N' = ISNULL(' + QUOTENAME(@Type + '_ExcessOT') + N', 0) + @Curr WHERE EmployeeID = @Emp AND PeriodID = @PerID'

					EXEC sp_executesql @Query, N'@Curr DECIMAL(10,2), @Emp VARCHAR(20), @PerID INT', @Curr = @CurrentHours, @Emp = @EmployeeID, @PerID = @PeriodID
				END

				FETCH NEXT
				FROM type_cursor
				INTO @Type
			END

			CLOSE type_cursor

			DEALLOCATE type_cursor

			FETCH NEXT
			FROM period_cursor
			INTO @PeriodID
		END

		CLOSE period_cursor

		DEALLOCATE period_cursor

		FETCH NEXT
		FROM emp_cursor
		INTO @EmployeeID
	END

	CLOSE emp_cursor

	DEALLOCATE emp_cursor


	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' '

	EXEC sp_executesql @Query

	-- SET @Query = 'ALTER TABLE tblAttendanceSummary ADD '
	-- SELECT @Query += ISNULL(ColumnDisplayName, '') + ' FLOAT,' + ISNULL(ColumnDisplayName, '') + '_ExcessOT FLOAT,'
	-- FROM tblOvertimeSetting
	-- ORDER BY ColumnDisplayName ASC
	-- SELECT @Query += ' TotalOT FLOAT, TaxableOT FLOAT, NontaxableOT FLOAT, TotalExcessOT FLOAT'
	-- EXEC sp_executesql @Query

    SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ',0), ' + 's.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ', 0)'
				FROM #tblOvertimeSetting
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	SET @Query = ''

	SELECT @Query += '
    UPDATE s SET  ' + @assign + '
    FROM tblAttendanceSummary s
    LEFT JOIN #SummaryData p ON s.EmployeeID = p.EmployeeID AND s.FromDate = p.FromDate AND s.ToDate = p.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ' AND ISNULL(s.DateStatus, 0) <> 3'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT_Raw = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT, 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM #SummaryData d
    INNER JOIN tblAttendanceSummary s ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET NonTaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N' * ' + CAST((
				CASE
					WHEN OvValue - 100 > 0
						THEN OvValue - 100
					ELSE 0
					END
				) / 100 AS VARCHAR(5)) + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	IF ISNULL(@isView, '') = 0
		SELECT a.EmployeeID, d.FullName, d.DepartmentName, d.HireDate, d.TotalOT, d.TotalExcessOT, d.TotalExcessOT_Raw, a.[Month], a.[Year], a.PeriodID, d.OT1_Total, a.OT1, a.OT1_ExcessOT, d.OT2a_Total, a.OT2a, a.OT2a_ExcessOT, d.OT2b_Total, a.OT2b, a.OT2b_ExcessOT, d.OT3_Total, a.OT3, a.OT3_ExcessOT, d.OT4_Total, a.OT4, a.OT4_ExcessOT, d.OT5_Total, a.OT5, a.OT5_ExcessOT, d.OT6_Total, a.OT6, a.OT6_ExcessOT, d.OT7_Total, a.OT7, a.OT7_ExcessOT, a.DateStatus
		FROM tblAttendanceSummary a
		INNER JOIN #SummaryData d ON a.EmployeeID = d.EmployeeID AND a.FromDate = d.FromDate AND a.ToDate = d.ToDate
		WHERE a.Year = @Year AND a.Month = @Month AND (ISNULL(@isExcess, 0) = 0 OR (ISNULL(@isExcess, 0) = 1 AND d.TotalExcessOT > 0))
END
--exec sp_accumulatedOT 3,7,2025
GO



if object_id('[dbo].[sp_getMonthlyPayrollCheckList]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_getMonthlyPayrollCheckList] as select 1')
GO

--exec sp_getMonthlyPayrollCheckList 12,2017
ALTER PROCEDURE [dbo].[sp_getMonthlyPayrollCheckList] (@LoginID INT = 3, @Month INT = 1, @Year INT = 2019, @SalaryTermID INT = 0, @NotSelect BIT = 0, @OptionView INT = 0, @ViewAllPeriod BIT = 0)
AS
BEGIN
	DECLARE @ToDate DATE, @FromDate DATE

	SELECT @ToDate = ToDate, @FromDate = FromDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT EmployeeID, FullName, HireDate, TerminateDate, LastWorkingDate, EmployeeStatusID, DepartmentID, EmployeeTypeID, ProbationEndDate, PositionID, DivisionID
	INTO #tmpEmployeeList
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@ToDate, '-1', @LoginID)
	WHERE ISNULL(@OptionView, '-1') = '-1' OR @OptionView = 0 OR (ISNULL(@OptionView, 0) = 1 AND ISNULL(IsForeign, 0) = 0) OR (ISNULL(@OptionView, 0) = 2 AND ISNULL(IsForeign, 0) = 1)

	CREATE TABLE #Tadata (EmployeeID VARCHAR(20), Attdate DATE, HireDate DATE, EmployeeStatusID INT, HolidayStatus INT, WorkingTime FLOAT(53), Std_Hour_PerDays FLOAT(53), Lvamount FLOAT(53), PaidAmount_Des FLOAT(53), UnpaidAmount_Des FLOAT(53), SalaryHistoryID INT, CutSI BIT, EmployeeTypeID INT)

	EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 0

	SELECT *
	INTO #AttendanceSummary
	FROM tblAttendanceSummary
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			)

	IF (@ViewAllPeriod <> 1)
	BEGIN
		DELETE
		FROM #AttendanceSummary
		WHERE PeriodID = 1
	END

	DELETE tblMonthlyPayrollCheckList
	FROM tblMonthlyPayrollCheckList cl
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			) AND Month = @Month AND Year = @Year AND ISNULL(Approved, 0) <> 1 AND NOT EXISTS (
			SELECT 1
			FROM tblSal_Lock sl
			WHERE cl.EmployeeID = sl.EmployeeID AND sl.Month = @Month AND sl.Year = @Year
			)


	SELECT te.EmployeeID, te.FullName, te.HireDate, @Month Month, @Year Year, te.TerminateDate, te.EmployeeStatusID, cast(0 AS BIT) AS isLowTaxableInCome, CASE
			WHEN (@Year % 400 = 0) OR (@Year % 4 = 0 AND @Year % 100 <> 0)
				THEN 366
			ELSE 365
			END AS DaysOfYear, CAST(NULL AS FLOAT) ActualDayOfYear, CAST(NULL AS FLOAT) Bonus6Month_STD_Days, CAST(NULL AS FLOAT) Bonus6Month_ActualDays, a.RegularWorkdays * a.STD_Hour_PerDays STD_WorkingHours, CASE
			WHEN YEAR(te.HireDate) < @Year
				THEN 12
			WHEN YEAR(te.HireDate) > @Year
				THEN 0
			ELSE 12 - DATEPART(MONTH, te.HireDate) + 1
			END ActualMonth, ISNULL(PeriodID, 0) PeriodID
	INTO #tblMonthlyPayrollCheckList
	FROM #tmpEmployeeList te
	INNER JOIN #AttendanceSummary a ON te.EmployeeID = a.EmployeeID
	WHERE te.EmployeeID NOT IN (
			SELECT EmployeeID
			FROM tblMonthlyPayrollCheckList m
			WHERE m.Month = @Month AND m.Year = @Year
			)

    ALTER TABLE #tblMonthlyPayrollCheckList ALTER COLUMN PeriodID INT NULL

	-- nhan vien da nghi viecj hoan nghi thai san nhung co khoa tra bo sung
	INSERT INTO #tblMonthlyPayrollCheckList (EmployeeID, FullName, HireDate, Month, Year, TerminateDate, isLowTaxableInCome, EmployeeStatusID, DaysOfYear, PeriodID)
	SELECT te.EmployeeID, te.FullName, te.HireDate, @Month Month, @Year Year, TerminateDate, cast(0 AS BIT) AS isLowTaxableInCome, te.EmployeeStatusID, CASE
			WHEN (@Year % 400 = 0) OR (@Year % 4 = 0 AND @Year % 100 <> 0)
				THEN 366
			ELSE 365
			END, 0 AS PeriodID
	FROM #tmpEmployeeList te
	WHERE EXISTS (
			SELECT 1
			FROM tblPr_Adjustment a
			WHERE te.EmployeeID = a.EmployeeID AND a.Month = @month AND a.Year = @year
			) AND NOT EXISTS (
			SELECT 1
			FROM #tblMonthlyPayrollCheckList c
			WHERE te.EmployeeID = c.EmployeeID
			)

	DECLARE @HalfStart DATE, @HalfEnd DATE, @HalfDays INT;

	IF @Month BETWEEN 1 AND 6
	BEGIN
		SET @HalfStart = DATEFROMPARTS(@Year, 1, 1);
		SET @HalfEnd = EOMONTH(DATEFROMPARTS(@Year, 6, 1));
	END
	ELSE
	BEGIN
		SET @HalfStart = DATEFROMPARTS(@Year, 7, 1);
		SET @HalfEnd = DATEFROMPARTS(@Year, 12, 31);
	END

	SET @HalfDays = DATEDIFF(day, @HalfStart, @HalfEnd) + 1;

	UPDATE e
	SET ActualDayOfYear = CASE
			WHEN e.HireDate IS NULL
				THEN e.DaysOfYear
			WHEN YEAR(e.HireDate) < @Year
				THEN e.DaysOfYear
			WHEN YEAR(e.HireDate) > @Year
				THEN 0
			ELSE e.DaysOfYear - DATEPART(dayofyear, e.HireDate)
			END + 1,
		-- Số ngày chuẩn cho 6 tháng và số ngày thực tế trong 6 tháng
		Bonus6Month_STD_Days = @HalfDays, Bonus6Month_ActualDays = CASE
			WHEN e.HireDate IS NULL
				THEN @HalfDays
			WHEN YEAR(e.HireDate) < @Year
				THEN @HalfDays
			WHEN YEAR(e.HireDate) > @Year
				THEN 0
			WHEN e.HireDate > @HalfEnd
				THEN 0
			WHEN e.HireDate <= @HalfStart
				THEN @HalfDays
			ELSE DATEDIFF(day, e.HireDate, @HalfEnd) + 1
			END, ActualMonth = CASE
			WHEN YEAR(e.HireDate) < @Year
				THEN 12
			WHEN YEAR(e.HireDate) > @Year
				THEN 0
			ELSE 12 - DATEPART(MONTH, e.HireDate) + 1
			END
	FROM #tblMonthlyPayrollCheckList e

	--vao lam lai
	--chua vao lam
	DELETE #tblMonthlyPayrollCheckList
	WHERE HireDate > @ToDate

	--nghi viec hoac nghi thai san roi
	DELETE c
	FROM #tblMonthlyPayrollCheckList c
	WHERE TerminateDate <= @FromDate AND NOT EXISTS (
			SELECT 1
			FROM tblPR_Adjustment p
			WHERE p.EmployeeID = c.EmployeeID AND p.Month = c.Month AND p.year = c.Year
			)

	--dua du lieu vao bang thuc te
	INSERT INTO tblMonthlyPayrollCheckList (EmployeeID, Month, Year, isSalCal, isLowTaxableInCome, Number6DayMonth, Number6DayMonth_Actual, NumberDayOfYear, NumberDayOfYear_Actual, STD_WorkingHours, ActualMonthInYear)
	SELECT DISTINCT EmployeeID, Month, Year, 1, isLowTaxableInCome, Bonus6Month_STD_Days, Bonus6Month_ActualDays, DaysOfYear, ActualDayOfYear, STD_WorkingHours, ActualMonth
	FROM #tblMonthlyPayrollCheckList
	WHERE NOT EXISTS (
			SELECT 1
			FROM tblMonthlyPayrollCheckList m
			WHERE m.EmployeeID = #tblMonthlyPayrollCheckList.EmployeeID AND m.Month = @Month AND m.Year = @Year
			) AND PeriodID = 0

	--xu ly cam ket thu nhap thap
	DECLARE @LastMonth INT = CASE
			WHEN @month = 1
				THEN 12
			ELSE @month - 1
			END, @LastYear INT = CASE
			WHEN @month = 1
				THEN @year - 1
			ELSE @year
			END

	SELECT *
	INTO #LastMonth
	FROM tblMonthlyPayrollCheckList c2
	WHERE c2.Month = @LastMonth AND c2.Year = @LastYear

	UPDATE c1
	SET c1.isLowTaxableInCome = isnull(c2.isLowTaxableInCome, 0)
	FROM tblMonthlyPayrollCheckList c1
	INNER JOIN #LastMonth c2 ON c1.EmployeeID = c2.EmployeeID AND c1.isLowTaxableInCome <> c2.isLowTaxableInCome
	WHERE isnull(c1.Approved, 0) = 0

	--loai nhan vien khong tinh luong
	DELETE p
	FROM tblMonthlyPayrollCheckList p
	INNER JOIN #tmpEmployeeList e ON p.EmployeeID = e.EmployeeID AND isnull(p.Approved, 0) = 0 AND month = @Month AND year = @Year AND e.EmployeeTypeID IN (
			SELECT EmployeeTypeID
			FROM tblEmployeeType
			WHERE isNotSalCal = 1
			)

	--xóa tạm đi
	DROP TABLE #tblMonthlyPayrollCheckList

	UPDATE e
	SET STD_WorkingHours = a.RegularWorkdays * a.STD_Hour_PerDays
	FROM tblMonthlyPayrollCheckList e
	INNER JOIN #AttendanceSummary a ON e.EmployeeID = a.EmployeeID
	WHERE e.Month = @Month AND e.Year = @Year AND e.STD_WorkingHours IS NULL

	--Ratio bonus 6 month
	SELECT l.DivisionID, l.LevelID, l.Bonus6MAllowance, l.Ratio
	INTO #tblBonus6Ratio
	FROM tblBonus6Ratio l
	INNER JOIN (
		SELECT DivisionID, LevelID, MAX(EffectiveDate) AS EffectiveDate
		FROM tblBonus6Ratio
		WHERE EffectiveDate <= @ToDate
		GROUP BY DivisionID, LevelID
		) r ON l.DivisionID = r.DivisionID AND l.LevelID = r.LevelID

	UPDATE e
	SET Bonus6MonthAllowance = ISNULL(b.Bonus6MAllowance, 1), RatioBonus6Month = ISNULL(b.Ratio, 1)
	FROM tblMonthlyPayrollCheckList e
	INNER JOIN #tmpEmployeeList t ON e.EmployeeID = t.EmployeeID
	LEFT JOIN #tblBonus6Ratio b ON t.DivisionID = b.DivisionID AND e.LevelID = b.LevelID
	WHERE e.Month = @Month AND e.Year = @Year AND (e.Bonus6MonthAllowance IS NULL OR e.RatioBonus6Month IS NULL)

	UPDATE e
	SET STD_WorkingHours = a.RegularWorkdays * a.STD_Hour_PerDays
	FROM tblMonthlyPayrollCheckList e
	INNER JOIN #AttendanceSummary a ON e.EmployeeID = a.EmployeeID
	WHERE e.Month = @Month AND e.Year = @Year AND e.STD_WorkingHours IS NULL

	SELECT EmployeeID, Month, Year, isSalCal, isLowTaxableInCome, Number6DayMonth, Number6DayMonth_Actual, NumberDayOfYear, NumberDayOfYear_Actual, STD_WorkingHours, ActualMonthInYear, Bonus6MonthAllowance, RatioBonus6Month, Approved, LevelID
	INTO #tblMonthlyPayrollCheckList_View
	FROM tblMonthlyPayrollCheckList
	WHERE Month = @Month AND Year = @Year

	IF @SalaryTermID = 0
	BEGIN
		IF isnull(@NotSelect, 0) = 0
		BEGIN
			IF (@ViewAllPeriod = 1)
			BEGIN
				SELECT m.*, e.FullName, e.DepartmentID, e.PositionID
					--,sal.TotalPaidDay_C
					--,sal.AttHours_C
					, e.HireDate, e.ProbationEndDate, e.TerminateDate, e.EmployeeStatusID, sal.PercentProbation, sal.FromDate, sal.ToDate
				FROM #tblMonthlyPayrollCheckList_View m
				INNER JOIN #tmpEmployeeList e ON m.EmployeeID = e.EmployeeID
				LEFT JOIN #AttendanceSummary sal ON m.EmployeeID = sal.EmployeeID AND sal.Month = @month AND sal.Year = @year
				WHERE m.Month = @month AND m.Year = @year
				ORDER BY m.EmployeeID
			END
			ELSE
			BEGIN
				SELECT m.*, e.FullName, e.DepartmentID, e.PositionID
					--,sal.TotalPaidDay_C
					--,sal.AttHours_C
					, e.HireDate, e.ProbationEndDate, e.TerminateDate, e.EmployeeStatusID
				FROM #tblMonthlyPayrollCheckList_View m
				INNER JOIN #tmpEmployeeList e ON m.EmployeeID = e.EmployeeID
				WHERE m.Month = @month AND m.Year = @year
				ORDER BY m.EmployeeID
			END
		END
	END
END
	--exec sp_getMonthlyPayrollCheckList 3, 8,2025
GO

USE Paradise_TRIPOD
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

	SELECT @Query += N'IF COL_LENGTH(''tblAttendanceSummary'',''' + LeaveCode + N''') is null
                        ALTER TABLE tblAttendanceSummary ADD [' + LeaveCode + N'] FLOAT;'
	FROM tblLeaveType
	WHERE IsVisible = 1

	EXEC (@Query)

	SELECT *
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1 = 0

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

	INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, PercentProbation)
	SELECT @Year, @Month, sh.EmployeeID, 1, sh.SalaryHistoryID, CASE
			WHEN sh.DATE < @FromDate
				THEN @FromDate
			ELSE sh.DATE
			END, @ToDate, te.PercentProbation
	FROM #EmployeeList te
	INNER JOIN tblSalaryHistory sh ON te.EmployeeID = sh.EmployeeID
	WHERE sh.SalaryHistoryID NOT IN (
			SELECT SalaryHistoryID
			FROM #CurrentSalary
			) AND [Date] > @FromDate AND NOT EXISTS (
			SELECT 1
			FROM #tblAttendanceSummary s
			WHERE sh.SalaryHistoryID = s.SalaryHistoryID
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
	SET RegularWorkdays = ISNULL(RegularWorkdays, 0), WorkingHrs_Total = (RegularWorkdays * 8), WorkingDays_Total = RegularWorkdays
	FROM #tblAttendanceSummary att
	INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
	WHERE ISNULL(e.IsForeign, 0) = 1 AND (e.HireDate <= @FromDate AND (e.TerminateDate IS NULL OR e.TerminateDate >= @ToDate))

	DECLARE @cols NVARCHAR(MAX), @assign NVARCHAR(MAX), @sql NVARCHAR(MAX)

	SELECT @cols = STUFF((
				SELECT ',' + QUOTENAME(LeaveCode)
				FROM tblLeaveType
				WHERE IsVisible = 1
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(LeaveCode) + ' = ISNULL(p.' + QUOTENAME(LeaveCode) + ',0)'
				FROM tblLeaveType
				WHERE IsVisible = 1
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

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

	SELECT @cols = STUFF((
				SELECT ',' + QUOTENAME(name)
				FROM sys.all_columns
				WHERE object_id = OBJECT_ID('tblAttendanceSummary')
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	-- Insert processed summary rows from temp table into permanent table
	SET @sql = '
	INSERT INTO tblAttendanceSummary (' + @cols + N')
	SELECT ' + @cols + N'
	FROM #tblAttendanceSummary'

	EXEC sp_executesql @sql

	SET @assign = ''

	SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ',0), ' + 's.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ', 0)'
				FROM tblOvertimeSetting
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

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

ALTER PROCEDURE [dbo].[sp_accumulatedOT] @LoginID INT, @Month INT, @Year INT, @MaxOT FLOAT = 40.0, @isView BIT = 0, @isExcess BIT = 0
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	IF ISNULL(@MaxOT, 0) = 0
	BEGIN
		SET @MaxOT = 40.0
	END

	SELECT e.EmployeeID, FullName, d.DepartmentID, DepartmentName, p.PositionID, PositionName, HireDate, LastWorkingDate
	INTO #tmpEMP
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) e
	LEFT JOIN tblDepartment d ON e.DepartmentID = d.DepartmentID
	LEFT JOIN tblPosition p ON e.PositionID = p.PositionID

	DELETE #tmpEMP
	WHERE HireDate > @ToDate OR LastWorkingDate < @FromDate

	SELECT a.*
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary a
	INNER JOIN #tmpEMP e ON a.EmployeeID = e.EmployeeID
	WHERE a.Year = @Year AND a.Month = @Month AND ISNULL(a.DateStatus, 0) <> 3

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind, ots.ColumnDisplayName OTType, te.FromDate, te.ToDate
	INTO #OTList
	FROM tblOTList ot
	INNER JOIN #tblAttendanceSummary te ON ot.EmployeeID = te.EmployeeID AND ot.OTDate BETWEEN te.FromDate AND te.ToDate
	INNER JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OTKind
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0

	SELECT EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType, FromDate, ToDate
	INTO #tblOTSummary
	FROM #OTList
	GROUP BY EmployeeID, OTKind, OTType, FromDate, ToDate

	DELETE
	FROM #tmpEMP
	WHERE EmployeeID NOT IN (
			SELECT DISTINCT EmployeeID
			FROM #tblOTSummary
			)

	SELECT *
	INTO #tblOvertimeSetting
	FROM tblOvertimeSetting

	-- WHERE OTKind IN (
	-- 		SELECT DISTINCT OTKind
	-- 		FROM #tblOTSummary
	-- 		WHERE ISNULL(OTKind, '') <> ''
	-- 		)
	IF NOT EXISTS (
			SELECT *
			FROM #tblOTSummary
			)
	BEGIN
		RETURN
	END

	CREATE TABLE #SummaryData (STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), HireDate DATE, FromDate DATE, ToDate DATE, PeriodID INT)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, DepartmentName, FromDate, ToDate, PeriodID)
	SELECT ROW_NUMBER() OVER (
			ORDER BY t.EmployeeID
			), t.EmployeeID, FullName, t.HireDate, ISNULL(DepartmentName, ''), FromDate, ToDate, ROW_NUMBER() OVER (
			ORDER BY FromDate ASC
			) AS PeriodID
	FROM #tmpEMP t
	INNER JOIN #tblAttendanceSummary a ON t.EmployeeID = a.EmployeeID

	--Xoá các dòng k có OT
	DELETE s
	FROM #SummaryData s
	LEFT JOIN #tblOTSummary o ON s.EmployeeID = o.EmployeeID AND s.FromDate = o.FromDate AND s.ToDate = o.ToDate
	WHERE o.EmployeeID IS NULL

	DECLARE @assign NVARCHAR(MAX) = '', @Query NVARCHAR(MAX) = 'ALTER TABLE #SummaryData ADD '

	SELECT @Query += ISNULL(ColumnDisplayName, '') + '_Total DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + ' DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + '_ExcessOT DECIMAL(10, 2),'
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	SELECT @Query += ' TotalOT DECIMAL(10, 2), TotalExcessOT DECIMAL(10, 2), TotalExcessOT_Raw DECIMAL(10, 2)'

	EXEC sp_executesql @Query

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(ColumnDisplayName, '') + '] = ISNULL(w.ApprovedHours, 0),
                                    [' + ISNULL(ColumnDisplayName, '') + '_Total] = ISNULL(w.ApprovedHours, 0)
                        FROM #SummaryData s
                        LEFT JOIN #tblOTSummary w ON s.EmployeeID = w.EmployeeID AND s.FromDate = w.FromDate AND s.ToDate = w.ToDate
                        WHERE w.OTType = ''' + ISNULL(ColumnDisplayName, '') + N''';'
	FROM #tblOvertimeSetting

	EXEC sp_executesql @Query

	UPDATE s
	SET TotalOT = ISNULL(a.SumOTHours, 0)
	FROM #SummaryData s
	INNER JOIN (
		SELECT EmployeeID, FromDate, ToDate, SUM(ApprovedHours) SumOTHours
		FROM #tblOTSummary
		GROUP BY EmployeeID, FromDate, ToDate
		) a ON a.EmployeeID = s.EmployeeID AND a.FromDate = s.FromDate AND a.ToDate = s.ToDate

	UPDATE a
	SET TotalOT = s.TotalOT
	FROM tblAttendanceSummary a
	INNER JOIN #SummaryData s ON a.EmployeeID = s.EmployeeID AND a.FromDate = s.FromDate AND a.ToDate = s.ToDate
	WHERE a.Year = @Year AND a.Month = @Month

	-- Tối ưu: Loại bỏ hoàn toàn tham chiếu [OTType], dùng dynamic SQL set-based để cập nhật từng loại OT động
	DECLARE @ColName NVARCHAR(MAX), @sql NVARCHAR(MAX) = N'';
	DECLARE @MaxOT_DEC DECIMAL(10, 2) = @MaxOT;

	IF OBJECT_ID('tempdb..#RemainOT') IS NOT NULL
		DROP TABLE #RemainOT;

	CREATE TABLE #RemainOT (EmployeeID VARCHAR(20), PeriodID INT, Remain DECIMAL(10, 2));

	INSERT INTO #RemainOT (EmployeeID, PeriodID, Remain)
	SELECT EmployeeID, PeriodID, @MaxOT_DEC
	FROM #SummaryData;

	DECLARE curOT CURSOR
	FOR
	SELECT ColumnDisplayName
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName DESC;

	OPEN curOT;

	FETCH NEXT
	FROM curOT
	INTO @ColName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = N'
				IF OBJECT_ID(''tempdb..#CTE'') IS NOT NULL DROP TABLE #CTE;

				SELECT s.EmployeeID, s.PeriodID, s.[' + @ColName + N'] AS Curr, r.Remain
				INTO #CTE
				FROM #SummaryData s
				INNER JOIN #RemainOT r ON s.EmployeeID = r.EmployeeID AND s.PeriodID = r.PeriodID
				WHERE ISNULL(s.[' + @ColName + N'], 0) > 0;

				IF EXISTS (SELECT 1 FROM #CTE)
				BEGIN
					-- Nếu còn hạn mức, phân bổ vào OT, phần dư sang ExcessOT. Nếu hết hạn mức, toàn bộ sang ExcessOT
					UPDATE s
					SET
						[' + @ColName + N'_ExcessOT] = ISNULL([' + @ColName + N'_ExcessOT],0) +
							CASE WHEN c.Remain > 0 AND c.Curr > c.Remain THEN c.Curr - c.Remain
								 WHEN c.Remain <= 0 THEN c.Curr ELSE 0 END,
						[' + @ColName + 
                            N'] = CASE WHEN c.Remain > 0 THEN
													CASE WHEN c.Curr <= c.Remain THEN c.Curr ELSE c.Remain END
												ELSE 0 END
					FROM #SummaryData s
					INNER JOIN #CTE c ON s.EmployeeID = c.EmployeeID AND s.PeriodID = c.PeriodID;

					-- Cập nhật lại Remaining: nếu còn hạn mức, trừ đi số OT đã phân bổ, nếu hết thì giữ 0
					UPDATE r
					SET Remain = CASE WHEN c.Remain > 0 THEN
											CASE WHEN c.Curr <= c.Remain THEN c.Remain - c.Curr ELSE 0 END
									   ELSE 0 END
					FROM #RemainOT r
					INNER JOIN #CTE c ON r.EmployeeID = c.EmployeeID AND r.PeriodID = c.PeriodID;
				END

				DROP TABLE #CTE;
			';

		EXEC sp_executesql @sql;

		FETCH NEXT
		FROM curOT
		INTO @ColName;
	END

	CLOSE curOT;

	DEALLOCATE curOT;

	DROP TABLE #RemainOT;

	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' '

	EXEC sp_executesql @Query

	-- SET @Query = 'ALTER TABLE tblAttendanceSummary ADD '
	-- SELECT @Query += ISNULL(ColumnDisplayName, '') + ' FLOAT,' + ISNULL(ColumnDisplayName, '') + '_ExcessOT FLOAT,'
	-- FROM tblOvertimeSetting
	-- ORDER BY ColumnDisplayName ASC
	-- SELECT @Query += ' TotalOT FLOAT, TaxableOT FLOAT, NontaxableOT FLOAT, TotalExcessOT FLOAT'
	-- EXEC sp_executesql @Query
	SELECT @assign = STUFF((
				SELECT ',s.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName, '')) + ',0), ' + 's.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ' = ISNULL(p.' + QUOTENAME(ISNULL(ColumnDisplayName + '_ExcessOT', '')) + ', 0)'
				FROM #tblOvertimeSetting
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

	SET @Query = ''

	SELECT @Query += '
    UPDATE s SET  ' + @assign + '
    FROM tblAttendanceSummary s
    LEFT JOIN #SummaryData p ON s.EmployeeID = p.EmployeeID AND s.FromDate = p.FromDate AND s.ToDate = p.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ' AND ISNULL(s.DateStatus, 0) <> 3'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT_Raw = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT, 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM #SummaryData d
    INNER JOIN tblAttendanceSummary s ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET NonTaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N' * ' + CAST((
				CASE 
					WHEN OvValue - 100 > 0
						THEN OvValue - 100
					ELSE 0
					END
				) / 100 AS VARCHAR(5)) + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID AND s.FromDate = d.FromDate AND s.ToDate = d.ToDate
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	IF ISNULL(@isView, '') = 0
		SELECT a.EmployeeID, d.FullName, d.DepartmentName, d.HireDate, d.TotalOT, d.TotalExcessOT, d.TotalExcessOT_Raw, a.[Month], a.[Year], a.PeriodID, d.OT1_Total, a.OT1, a.OT1_ExcessOT, d.OT2a_Total, a.OT2a, a.OT2a_ExcessOT, d.OT2b_Total, a.OT2b, a.OT2b_ExcessOT, d.OT3_Total, a.OT3, a.OT3_ExcessOT, d.OT4_Total, a.OT4, a.OT4_ExcessOT, d.OT5_Total, a.OT5, a.OT5_ExcessOT, d.OT6_Total, a.OT6, a.OT6_ExcessOT, d.OT7_Total, a.OT7, a.OT7_ExcessOT, a.DateStatus
		FROM tblAttendanceSummary a
		INNER JOIN #SummaryData d ON a.EmployeeID = d.EmployeeID AND a.FromDate = d.FromDate AND a.ToDate = d.ToDate
		WHERE a.Year = @Year AND a.Month = @Month AND (ISNULL(@isExcess, 0) = 0 OR (ISNULL(@isExcess, 0) = 1 AND d.TotalExcessOT > 0))
END
	--exec sp_accumulatedOT 3,7,2025
GO

