
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

        if @LoginID = 3 begin  
        SELECT @Year, @Month, sh.EmployeeID, 0, sh.SalaryHistoryID, CASE
                WHEN sh.DATE < @FromDate
                    THEN @FromDate
                ELSE sh.DATE
                END, @ToDate, te.PercentProbation
        FROM #EmployeeList te
        INNER JOIN #CurrentSalary s ON te.EmployeeID = s.EmployeeID
        INNER JOIN tblSalaryHistory sh ON s.SalaryHistoryID = sh.SalaryHistoryID
        WHERE sh.DATE >= te.HireDate
        return end 


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

    
	select * from #tblSal_AttendanceData where EmployeeID='62250009'
    select * from #tblAttendanceSummary where EmployeeID='62250009'
     return
    

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

exec sp_processSummaryAttendance 3,2025,8