
if object_id('[dbo].[sp_AttendanceSummaryMonthly_STD]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_AttendanceSummaryMonthly_STD] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_AttendanceSummaryMonthly_STD] (@Month INT, @Year INT, @LoginID INT = 3, @LanguageID VARCHAR(2) = 'VN', @OptionView INT = 1, @isExport INT = 0)
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE
	DECLARE @ViewProbationPeriod INT = 0 --0: ko xem thử việc, 1: xem thử việc

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	DECLARE @GetDate DATETIME = dbo.Truncate_Date(GetDate())

	SELECT EmployeeID, FullName, DivisionID, DepartmentID, SectionID, HireDate, PositionID, TerminateDate, EmployeeTypeID, GroupID, ProbationEndDate
	INTO #fn_vtblEmployeeList_Bydate
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) e
	WHERE (
			ISNULL(@OptionView, '-1') = '-1' OR ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 1) = 1 AND IsForeign = 0) OR (ISNULL(@OptionView, '-1') = 2 AND ISNULL(IsForeign, 1) = 1
				)
			)

	SELECT ROW_NUMBER() OVER (
			ORDER BY ORD, LeaveCode
			) AS ORD, LeaveCode, TACode
	INTO #LeaveCode
	FROM tblLeaveType
	WHERE IsVisible = 1

	SELECT ROW_NUMBER() OVER (
			ORDER BY e.EmployeeID
			) AS [No], e.EmployeeID, FullName, p.PositionName, d.DivisionName, dept.DepartmentName, s.SectionName, g.GroupName, HireDate, TerminateDate, ProbationEndDate
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
	CREATE TABLE #Tadata (
		EmployeeID VARCHAR(20), Attdate DATE, HireDate DATE, EmployeeStatusID INT, HolidayStatus INT, WorkingTime FLOAT(53), Std_Hour_PerDays FLOAT(53), Lvamount
		FLOAT(53), PaidAmount_Des FLOAT(53), UnpaidAmount_Des FLOAT(53), SalaryHistoryID INT, CutSI BIT, LeaveCode VARCHAR(5), EmployeeTypeID INT
		)

	EXEC sp_WorkingTimeProvider @Month = @Month, @Year = @Year, @fromdate = @FromDate, @todate = @ToDate, @loginId = @LoginID

	EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 1

	SELECT *
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1 = 0

	-- Tạo danh sách các cột cần tính tổng động
	DECLARE @cols NVARCHAR(MAX) = '', @querySelector NVARCHAR(MAX) = '', @sql NVARCHAR(MAX) = ''

	SELECT @cols += N',SUM(' + QUOTENAME(COLUMN_NAME) + N') AS ' + QUOTENAME(COLUMN_NAME), @querySelector += N',' + QUOTENAME(COLUMN_NAME)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'tblAttendanceSummary' AND COLUMN_NAME NOT IN ('Month', 'Year', 'EmployeeID', 'PeriodID', 'FromDate', 'ToDate', 'STD_WorkingDays', 'Std_Hour_PerDays'
			);

    SET @querySelector += N', STD_WorkingDays, Std_Hour_PerDays'

	SET @sql = N'
        INSERT INTO #tblAttendanceSummary (EmployeeID, Month, Year, PeriodID, FromDate, ToDate ' + @querySelector +
		N')
        SELECT
            EmployeeID,
            @Month AS Month,
            @Year AS Year,
			0, @FromDate, @ToDate
            '
		+ @cols +
		N', MAX(RegularWorkdays) AS STD_WorkingDays, MAX(Std_Hour_PerDays) AS Std_Hour_PerDays
        FROM tblAttendanceSummary
        WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
            SELECT EmployeeID FROM #tmpEmployeeList
        )
        GROUP BY EmployeeID, Month, Year'

	/*
	IF (ISNULL(@ViewProbationPeriod, 0) <> 1)
	BEGIN
		SELECT @cols += N',SUM(' + QUOTENAME(COLUMN_NAME) + N') AS ' + QUOTENAME(COLUMN_NAME), @querySelector += N',' + QUOTENAME(COLUMN_NAME)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'tblAttendanceSummary' AND COLUMN_NAME NOT IN ('Month', 'Year', 'EmployeeID', 'PeriodID', 'FromDate', 'ToDate', 'STD_WorkingDays');

		SET @sql = N'
        INSERT INTO #tblAttendanceSummary (EmployeeID, Month, Year, PeriodID, FromDate, ToDate ' + @querySelector +
			N')
        SELECT
            EmployeeID,
            @Month AS Month,
            @Year AS Year,
			0, @FromDate, @ToDate
            '
			+ @cols +
			N'
        FROM tblAttendanceSummary
        WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
            SELECT EmployeeID FROM #tmpEmployeeList
        )
        GROUP BY EmployeeID, Month, Year'

	END
	ELSE
	BEGIN
		SELECT @cols += N',' + QUOTENAME(COLUMN_NAME) + N' AS ' + QUOTENAME(COLUMN_NAME), @querySelector += N',' + QUOTENAME(COLUMN_NAME)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'tblAttendanceSummary' AND COLUMN_NAME NOT IN ('Month', 'Year', 'EmployeeID', 'PeriodID', 'FromDate', 'ToDate', 'STD_WorkingDays');

		SET @sql = N'
        INSERT INTO #tblAttendanceSummary (EmployeeID, Month, Year, PeriodID, FromDate, ToDate  ' + @querySelector +
			N')
        SELECT
            EmployeeID,
            @Month AS Month,
            @Year AS Year,
            ISNULL(PeriodID, 0), FromDate, ToDate
            '
			+ @cols +
			N'
        FROM tblAttendanceSummary
        WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
            SELECT EmployeeID FROM #tmpEmployeeList
        )'

	END */
	-- Thực thi truy vấn động
	EXEC sp_executesql @sql, N'@Month INT, @Year INT, @FromDate DATE, @ToDate DATE', @Month = @Month, @Year = @Year, @FromDate = @FromDate, @ToDate = @ToDate;


	SELECT n.EmployeeID, SUM(HourApprove) NSHours
	INTO #NightShiftSum
	FROM tblNightShiftList n
	INNER JOIN #tblAttendanceSummary elb ON elb.EmployeeID = n.EmployeeID
	WHERE n.DATE BETWEEN @FromDate AND @ToDate
	GROUP BY n.EmployeeID

	SELECT o.EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType
	INTO #tblOTSummary
	FROM #tblOTList o
	INNER JOIN #tblAttendanceSummary el ON el.EmployeeID = O.EmployeeID
	GROUP BY o.EmployeeID, OTKind, OTType

	SELECT e.EmployeeID, ROUND(SUM(IOMinutesDeduct) / 60, 1) AS IOHrs
	INTO #InLateOutEarly
	FROM tblInLateOutEarly e
	INNER JOIN #tblAttendanceSummary el ON el.EmployeeID = e.EmployeeID
	WHERE ApprovedDeduct = 1 AND IODate BETWEEN @FromDate AND @ToDate
	GROUP BY e.EmployeeID

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
	select EmployeeID,''' + CAST(OTKind AS VARCHAR(10)) + ''',' +
		ColumnNameOn_CustomAttendanceTable + '
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
		STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), PositionName NVARCHAR(MAX), HireDate DATE, ProbationEndDate DATE,
		STD_WorkingDays FLOAT, Actual_WorkingDays FLOAT, TotalPaidDays FLOAT, 	UnpaidLeaveDays FLOAT, WorkHours FLOAT, PaidLeaveHrs FLOAT, UnpaidLeave FLOAT, IOHrs DECIMAL(10, 1), TotalOT DECIMAL(10, 2), TotalNS DECIMAL(10, 2), TotalDayOff DECIMAL(10, 2), PeriodID INT, FromDate DATE, ToDate DATE
		)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, ProbationEndDate, DepartmentName, PositionName)
	SELECT No, EmployeeID, FullName, HireDate, ProbationEndDate, DepartmentName, PositionName
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
				SELECT 'UPDATE s SET [' + CAST(Number AS VARCHAR(3)) + 'Att] = w.WorkingTimeDisplay' + ' FROM #SummaryData s' +
					' INNER JOIN #Tadata w ON s.EmployeeID = w.EmployeeID' + ' WHERE DAY(w.Attdate) = ' + CAST(Number AS VARCHAR(3)) + ';' + CHAR(13) + CHAR(10)
				FROM dbo.fn_Numberlist(CAST(DAY(@FromDate) AS INT), CAST(DAY(@ToDate) AS INT))
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)')

		EXEC sp_executesql @Query
	END

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(TACode, '') + '] = w.' + ISNULL(TACode, '') +
		'
                        FROM #SummaryData s
                        INNER JOIN #tblAttendanceSummary w ON s.EmployeeID = w.EmployeeID;'
	FROM #LeaveCode

	EXEC sp_executesql @Query

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(ColumnDisplayName, '') +
		'] = w.ApprovedHours
                        FROM #SummaryData s
                        INNER JOIN #tblOTSummary w ON s.EmployeeID = w.EmployeeID
						WHERE w.OTType = '''
		+ ISNULL(ColumnDisplayName, '') + N''';'
	FROM tblOvertimeSetting

	EXEC sp_executesql @Query

	UPDATE s
	SET WorkHours = CAST(a.WorkingHrs_Total AS DECIMAL(10, 4)), PaidLeaveHrs = a.PaidLeaveHrs_Total, UnpaidLeave = a.UnpaidLeaveDays * a.Std_Hour_PerDays, UnpaidLeaveDays = a.UnpaidLeaveDays, Actual_WorkingDays = CAST(ROUND((a.WorkingHrs_Total / a.Std_Hour_PerDays), 4) AS DECIMAL(10, 4))
		, TotalPaidDays = CAST(a.WorkingDays_Total AS DECIMAL(10, 4)), STD_WorkingDays = a.STD_WorkingDays
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
		CREATE TABLE #ExportConfig (
			ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200),
			SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200)
			)

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


		--het thu viec trong thang nay
		UPDATE #tblAttendanceSummary
		SET FromDate = DATEADD(day, 1, ProbationEndDate)
		FROM #tblAttendanceSummary sh
		INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
		WHERE ISNULL(sh.PercentProbation, 0) > 0 AND ProbationEndDate BETWEEN @FromDate AND @ToDate

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

        UPDATE #tblAttendanceSummary
		SET PercentProbation = 100
		FROM #tblAttendanceSummary sh
		INNER JOIN #EmployeeList e ON sh.EmployeeID = e.EmployeeID
		WHERE ISNULL(sh.PercentProbation, 0) > 0 AND ProbationEndDate BETWEEN @FromDate AND @ToDate AND PeriodID = 0
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
    SET @ROUND_TOTAL_WORKINGDAYS = 4
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

	UPDATE #tblAttendanceSummary
	SET UnpaidLeaveHrs = ((RegularWorkdays * ISNULL(Std_Hour_PerDays, 8)) - ISNULL(sub.WorkingHrs_Total, 0) - ISNULL(sub.PaidLeaveHrs_Total, @ROUND_TOTAL_WORKINGDAYS)) - ISNULL(sub.UnpaidLeaveHrs, 0),
		UnpaidLeaveDays = ROUND(((RegularWorkdays * ISNULL(Std_Hour_PerDays, 8)) - ISNULL(sub.WorkingHrs_Total, 0) - ISNULL(sub.PaidLeaveHrs_Total, 0) - ISNULL(sub.UnpaidLeaveHrs, 0)) / ISNULL(Std_Hour_PerDays, 8), @ROUND_TOTAL_WORKINGDAYS)
	FROM #tblAttendanceSummary att
    INNER JOIN #EmployeeList e ON att.EmployeeID = e.EmployeeID
    LEFT JOIN (SELECT EmployeeID, SUM(WorkingHrs_Total) WorkingHrs_Total, SUM(PaidLeaveHrs_Total) PaidLeaveHrs_Total, SUM(UnpaidLeaveHrs) UnpaidLeaveHrs FROM #tblAttendanceSummary GROUP BY EmployeeID) AS sub ON att.EmployeeID = sub.EmployeeID
	WHERE RegularWorkdays * ISNULL(Std_Hour_PerDays, 8) > ISNULL(sub.WorkingHrs_Total, 0) + ISNULL(sub.PaidLeaveHrs_Total, 0) + ISNULL(sub.UnpaidLeaveHrs, 0) AND att.PeriodID = 0 AND ISNULL(e.IsForeign, 0) = 0

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
			SELECT lv.EmployeeID, LeaveCode, SUM(ISNULL(LvAmount,0)) AS LvAmount, FromDate, ToDate
			FROM #tblLvHistory lv
			INNER JOIN #tblAttendanceSummary s ON lv.EmployeeID = s.EmployeeID AND lv.LeaveDate BETWEEN s.FromDate AND s.ToDate
			GROUP BY lv.EmployeeID, LeaveCode, FromDate, ToDate
		)
		SELECT * INTO #tmpLvPivot FROM (
			SELECT EmployeeID, LeaveCode, LvAmount, FromDate, ToDate FROM lv
		) src
		PIVOT (SUM(LvAmount) FOR LeaveCode IN (' + @cols + N')) AS pvt;

		UPDATE s
		SET ' + @assign + N'
		FROM #tblAttendanceSummary s
		LEFT JOIN #tmpLvPivot p ON s.EmployeeID = p.EmployeeID AND s.FromDate = p.FromDate AND s.ToDate = p.ToDate;

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

	SET @assign = @assign + ' , DateStatus = p.DateStatus'

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



if object_id('[dbo].[sp_CompanySalarySummary]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_CompanySalarySummary] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_CompanySalarySummary] (@LoginID INT = NULL, @Month INT = NULL, @Year INT = NULL, @EmployeeID VARCHAR(20) = '-1', @IsPayslip BIT = 0, @isSummary BIT = 0
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	IF nullif(@EmployeeID, '') IS NULL
		SET @EmployeeID = '-1'

	SELECT f.EmployeeID, FullName, HireDate, LastWorkingDate, CAST(0 AS INT) Prio, f.DepartmentID, f.DivisionID, f.PositionID, s.SectionID, s.SectionName,
		ROW_NUMBER() OVER (
			ORDER BY f.EmployeeID
			) STTView, d.DepartmentName, p.PositionNameEN PositionName, f.CostCenter, cc.CostCenterName, CASE WHEN ISNULL(f.NationID, 234) = 234 THEN 'Domestic' ELSE 'Foreign' END AS EmployeeClass, CASE WHEN et.isLocalStaff = 1 THEN N'Indirect Labor' ELSE N'Direct Labor' END AS EmployeeType
	INTO #tmpEmployeeList
	FROM dbo.fn_vtblEmployeeList_ByDate(@ToDate, '-1', @LoginId) f
	LEFT JOIN tblSection s ON s.SectionID = f.SectionID
	LEFT JOIN tblDepartment d ON d.DepartmentID = f.DepartmentID
	LEFT JOIN tblPosition p ON p.PositionID = f.PositionID
	LEFT JOIN tblCostCenter cc ON cc.CostCenter = f.CostCenter
	LEFT JOIN tblEmployeeType et ON et.EmployeeTypeID = f.EmployeeTypeID

	SELECT s.EmployeeID, Month, Year, SUM(ATTHours) ATTHours, SUM(WorkingHours) WorkingHours, MAX(BasicSalary) BasicSalary, SUM(ActualMonthlyBasic)
		ActualMonthlyBasic, SUM(TaxableAllowance) TaxableAllowance, SUM(TotalEarn) TotalEarn, SUM(DaysOfSalEntry) DaysOfSalEntry, SUM(Raw_BasicSalary)
		Raw_BasicSalary, SUM(UnpaidLeaveAmount) UnpaidLeaveAmount, SUM(NSAmount) NSAmount, SUM(RegularAmt) RegularAmt, SUM(PaidLeaveAmt) PaidLeaveAmt, MAX(
			GrossSalary) GrossSalary, SUM(AnnualBonus_Total) AnnualBonus_Total, SUM(AnnualBonus_EvMonth) AnnualBonus_EvMonth, SUM(Bonus6Month_Total)
		Bonus6Month_Total, SUM(Bonus6M_EveryMonth) Bonus6M_EveryMonth, SUM(TaxableIncomeBeforeDeduction) TaxableIncomeBeforeDeduction, SUM(TotalIncome)
		TotalIncome
	INTO #Sal_Sal_Detail
	FROM tblSal_Sal_Detail s
	INNER JOIN #tmpEmployeeList te ON s.EmployeeID = te.EmployeeID
	WHERE s.Year = @Year AND s.Month = @Month AND ISNULL(s.IsNet, 0) = 0
	GROUP BY s.EmployeeID, Month, Year

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

	SELECT al.EmployeeID, al.IncomeID, SUM(ROUND(al.Amount, 0)) Amount, irr.Taxable, SUM(CASE
				WHEN irr.IncomeKind = 0
					THEN - 1
				ELSE 1
				END * al.Amount) AS AmountActual
	INTO #NonFixed
	FROM tblSal_Adjustment al
	INNER JOIN tblIrregularIncome irr ON al.IncomeID = irr.IncomeID
	INNER JOIN #tmpEmployeeList te ON al.EmployeeID = te.EmployeeID
	WHERE al.Year = @Year AND al.Month = @Month
	GROUP BY al.EmployeeID, al.IncomeID, irr.Taxable


	SELECT Year, Month, a.EmployeeID, SUM(WorkingHrs_Total) WorkingHrs_Total, SUM(WorkingDays_Total) WorkingDays_Total, SUM(PaidLeaveHrs_Total)
		PaidLeaveHrs_Total, SUM(PaidLeaveDays_Total) PaidLeaveDays_Total, SUM([A]) [A], MAX(Std_Hour_PerDays) Std_Hour_PerDays, max(STD_WorkingDays)
		STD_WorkingDays, SUM(UnpaidLeaveHrs) UnpaidLeaveHrs, SUM(UnpaidLeaveDays) UnpaidLeaveDays, SUM(RegularWorkdays) RegularWorkdays, SUM(OT1) OT1, SUM(
			OT1_ExcessOT) OT1_ExcessOT, SUM(OT2a) OT2a, SUM(OT2a_ExcessOT) OT2a_ExcessOT, SUM(OT2b) OT2b, SUM(OT2b_ExcessOT) OT2b_ExcessOT, SUM(OT3) OT3, SUM(
			OT3_ExcessOT) OT3_ExcessOT, SUM(OT4) OT4, SUM(OT4_ExcessOT) OT4_ExcessOT, SUM(OT5) OT5, SUM(OT5_ExcessOT) OT5_ExcessOT, SUM(OT6) OT6, SUM(OT6_ExcessOT
		) OT6_ExcessOT, SUM(OT7) OT7, SUM(OT7_ExcessOT) OT7_ExcessOT, SUM(TotalOT) TotalOT, SUM(TaxableOT) TaxableOT, SUM(NontaxableOT) NontaxableOT, SUM(
			TotalExcessOT) TotalExcessOT
	INTO #AttendanceSummary
	FROM tblAttendanceSummary a
	INNER JOIN #tmpEmployeeList te ON a.EmployeeID = te.EmployeeID
	WHERE Year = @Year AND Month = @Month
	GROUP BY Year, Month, a.EmployeeID

	DECLARE @Query NVARCHAR(MAX) = '', @OTList NVARCHAR(MAX) = ''

	SELECT @OTList += ISNULL(ColumnDisplayName, '') + ', '
	FROM tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	CREATE TABLE #OTSummary (EmployeeID VARCHAR(20), OTType NVARCHAR(50), OTHours DECIMAL(10, 2))

	SET @Query = '
		INSERT INTO #OTSummary (EmployeeID, OTType, OTHours)
		SELECT EmployeeID, OTType, OTHours
		FROM
		(
			SELECT EmployeeID, ' +
		LEFT(@OTList, LEN(@OTList) - 1) + '
			FROM #AttendanceSummary
		) AS src
		UNPIVOT
		(
			OTHours FOR OTType IN (' + LEFT(@OTList, LEN(@OTList) -
			1) + ')
		) AS unpvt'

	EXEC sp_executesql @Query

	SELECT ot.EmployeeID, ot.OverTimeID, SUM(ot.OTAmount) OTAmount, SUM(os.OTHours) NoneTaxableOTAmount, SUM(os.OTHours) Amount
	INTO #OTAmount
	FROM tblSal_OT_Detail ot
	INNER JOIN #tmpEmployeeList te ON ot.EmployeeID = te.EmployeeID
	LEFT JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OverTimeID
	LEFT JOIN #OTSummary os ON ot.EmployeeID = os.EmployeeID AND ots.ColumnDisplayName = os.OTType
	WHERE ot.Year = @Year AND ot.Month = @Month
	GROUP BY ot.EmployeeID, ot.OverTimeID

	--night shift
	SELECT *
	INTO #Sal_NS
	FROM tblSal_NS_Detail s
	WHERE s.Year = @Year AND s.Month = @Month AND EXISTS (
			SELECT 1
			FROM #tmpEmployeeList te
			WHERE s.EmployeeID = te.EmployeeID
			)

	SELECT *, Salary BasicSalary
	INTO #CurrentSalary
	FROM dbo.fn_CurrentSalaryByDate_TRIPOD(@ToDate, @LoginID)

	SELECT *
	INTO #tblSal_Tax
	FROM tblSal_Tax st
	WHERE st.Year = @Year AND st.Month = @Month AND EXISTS (
			SELECT 1
			FROM #tmpEmployeeList te
			WHERE st.EmployeeID = te.EmployeeID
			)

	--đi trễ về sớm
	SELECT EmployeeID, COUNT(1) IOCount
	INTO #InLateOutEarly
	FROM tblInLateOutEarly
	WHERE IODate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			)
	GROUP BY EmployeeID

	SELECT s.*
	INTO #tblSal_OT
	FROM tblSal_OT S
	INNER JOIN #tmpEmployeeList T ON S.EmployeeID = T.EmployeeID
	WHERE S.Year = @Year AND S.Month = @Month

	SELECT s.*
	INTO #tblSal_Sal
	FROM tblSal_Sal S
	INNER JOIN #tmpEmployeeList T ON S.EmployeeID = T.EmployeeID
	WHERE S.Year = @Year AND S.Month = @Month AND EXISTS (
			SELECT 1
			FROM tblMonthlyPayrollCheckList m
			WHERE m.isSalCal = 1 AND S.EmployeeID = m.EmployeeID AND m.Year = @Year AND m.Month = @Month
			)

	SELECT s.*
	INTO #tblSal_Insurance
	FROM tblSal_Insurance s
	INNER JOIN #tmpEmployeeList t ON s.EmployeeID = t.EmployeeID
	WHERE Year = @Year AND Month = @Month

	SELECT ROW_NUMBER() OVER (
			ORDER BY s.EmployeeID
			) AS STT, s.EmployeeID, s.FullName, s.DepartmentName, s.PositionName, cs.Salary, cs.[14] AS Allowance, sd.BasicSalary TotalSalary, sd.GrossSalary
		GrossTotal, a.WorkingHrs_Total AS RegularHrs, sd.RegularAmt, a.PaidLeaveHrs_Total, sd.PaidLeaveAmt, ot1.Amount AS OT1, ot2a.Amount AS ot2a, ot2b.Amount AS
		ot2b, ot3.Amount AS OT3, ot4.Amount AS OT4, ot5.Amount AS OT5, ot6.Amount AS OT6, ot7.Amount AS OT7, ROUND(totalOT.OTAmount, 0) AS TotalOT, ot1.
		NoneTaxableOTAmount AS OT1_ReduceTax, ot2a.NoneTaxableOTAmount AS ot2a_ReduceTax, ot2b.NoneTaxableOTAmount AS ot2b_ReduceTax, ot3.NoneTaxableOTAmount AS
		OT3_ReduceTax, ot4.NoneTaxableOTAmount AS OT4_ReduceTax, ot6.NoneTaxableOTAmount AS OT6_ReduceTax, ot7.NoneTaxableOTAmount AS OT7_ReduceTax, ROUND(
			totalOT.NoneTaxableOTAmount, 0) AS TotalOT_ReduceTax, totalOT.TaxableOTAmount AS TotalOT_Taxable, seniority.Amount AS Seniority, lang.Amount AS
		LANGUAGE, environment.Amount AS Environment, shift.Amount AS Shift, ns.NSHours, ns.NSAmount, petrol.Amount AS Petrol, design.Amount AS Design, attendance.
		Amount AS Attendance, meal.Amount AS Meal, area.Amount AS Area, incentive.Amount AS Incentive, cs.Allowance AS RegularAllowance, ISNULL(petrol.Amount, 0) +
		ISNULL(ns.NSAmount, 0) + ISNULL(attendance.Amount, 0) + ISNULL(meal.Amount, 0) + ISNULL(incentive.Amount, 0) AS IrregularAllowance, ISNULL(addition.Amount,
			0) + ISNULL(excessOT.Amount, 0) Addition, ISNULL(al.Amount, 0) AS AnnualBonus, bonus6.Amount AS Bonus6Month, ROUND(sal.TotalIncome, 0) TotalIncome, st.
		DependantNumber, ROUND(sd.TaxableIncomeBeforeDeduction, 0) TaxableIncomeBeforeDeduction, ROUND(st.IncomeTaxable, 0) IncomeAfterPIT, ins.EmployeeSI,
		ins.EmployeeHI, ins.EmployeeUI, st.TaxAmt, sal.EmpUnion, deduction.Amount Deduction, sal.GrossTakeHome AS Balance1, sal.GrossTakeHome AS Balance2, CASE
			WHEN (sal.GrossTakeHome % 1000) = 0
				THEN sal.GrossTakeHome
			WHEN (sal.GrossTakeHome % 1000) > 500
				THEN CEILING(sal.GrossTakeHome / 1000.0) * 1000
			WHEN (sal.GrossTakeHome % 1000) = 500
				THEN sal.GrossTakeHome
			WHEN (sal.GrossTakeHome % 1000) < 500
				THEN FLOOR(sal.GrossTakeHome / 1000.0) * 1000 + 500
			ELSE sal.GrossTakeHome
			END AS Total, ins.CompanySI, ins.CompanyHI, ins.CompanyUI, sal.CompUnion, sd.AnnualBonus_Total AS ALTotal, sd.AnnualBonus_EvMonth AS ALEveryM, sd.
		Bonus6Month_Total AS Bonus6M, sd.Bonus6M_EveryMonth AS Bonus6M_EveryM, CONCAT (@Month, '.', @Year) AS MonthYear, ROUND((a.WorkingHrs_Total / a.Std_Hour_PerDays
				), 1) AS Workdays, ISNULL(ins.EmployeeUI, 0) + ISNULL(ins.EmployeeHI, 0) + ISNULL(ins.EmployeeSI, 0) + ISNULL(sal.EmpUnion, 0) + ISNULL(st.TaxAmt, 0) +
		ISNULL(deduction.Amount, 0) + ISNULL(sd.UnpaidLeaveAmount, 0) AS TotalDeduction,
		--tổng thu = tổng các khoản thực lãnh (bao gồm cả gross salary nếu đủ công)
		ISNULL(sd.TotalIncome, 0) - ISNULL(sd.RegularAmt, 0) - ISNULL(sd.PaidLeaveAmt, 0) + ISNULL(sd.GrossSalary, 0) AS TotalEarning, a.UnpaidLeaveHrs
		UnpaidLeaveDays, st.EmployeeExemption, st.FamilyExemption, ins.EmployeeTotal, a.[A] AnnualLeaveHrs, ISNULL(a.PaidLeaveHrs_Total, 0) - ISNULL(a.[A], 0)
		PaidLeavePS,
		--đặc thù của TVC
		ISNULL(incentive.Amount, 0) + ISNULL(meal.Amount, 0) + ISNULL(addition.Amount, 0) + ISNULL(excessOT.Amount, 0) AS OrtherIncome, ioc.IOCount, bonus6att.
		Amount AS Bonus6Month_FullAttendance, sd.UnpaidLeaveAmount, ISNULL(sd.TotalIncome, 0) - ISNULL(sd.RegularAmt, 0) - ISNULL(sd.PaidLeaveAmt, 0) + ISNULL(sd.GrossSalary, 0) - ISNULL(sd.UnpaidLeaveAmount, 0) AS TotalEarning_ExcludeUnpaidLeave, s.CostCenterName, EmployeeClass, EmployeeType, CAST(NULL AS MONEY) OtherDeduction
	INTO #DetailOfSalary
	FROM #tmpEmployeeList s
	INNER JOIN #AttendanceSummary a ON s.EmployeeID = a.EmployeeID
	INNER JOIN #tblSal_Sal sal ON s.EmployeeID = sal.EmployeeID
	INNER JOIN #Sal_Sal_Detail sd ON s.EmployeeID = sd.EmployeeID
	LEFT JOIN #OTAmount ot1 ON ot1.OverTimeID = 11 AND s.EmployeeID = ot1.EmployeeID
	LEFT JOIN #OTAmount ot2a ON ot2a.OverTimeID = 22 AND s.EmployeeID = ot2a.EmployeeID
	LEFT JOIN #OTAmount ot2b ON ot2b.OverTimeID = 33 AND s.EmployeeID = ot2b.EmployeeID
	LEFT JOIN #OTAmount ot3 ON ot3.OverTimeID = 23 AND s.EmployeeID = ot3.EmployeeID
	LEFT JOIN #OTAmount ot4 ON ot4.OverTimeID = 26 AND s.EmployeeID = ot4.EmployeeID
	LEFT JOIN #OTAmount ot5 ON ot5.OverTimeID = 34 AND s.EmployeeID = ot5.EmployeeID
	LEFT JOIN #OTAmount ot6 ON ot6.OverTimeID = 21 AND s.EmployeeID = ot6.EmployeeID
	LEFT JOIN #OTAmount ot7 ON ot7.OverTimeID = 27 AND s.EmployeeID = ot7.EmployeeID
	LEFT JOIN #tblSal_OT totalOT ON s.EmployeeID = totalOT.EmployeeID
	LEFT JOIN #Allowance seniority ON seniority.AllowanceID = 1 AND s.EmployeeID = seniority.EmployeeID
	LEFT JOIN #Allowance lang ON lang.AllowanceID = 3 AND s.EmployeeID = lang.EmployeeID
	LEFT JOIN #Allowance environment ON environment.AllowanceID = 4 AND s.EmployeeID = environment.EmployeeID
	LEFT JOIN #Allowance shift ON shift.AllowanceID = 5 AND s.EmployeeID = shift.EmployeeID
	LEFT JOIN #Sal_NS ns ON ns.EmployeeID = s.EmployeeID AND ns.Year = @Year AND ns.Month = @Month
	LEFT JOIN #Allowance petrol ON petrol.AllowanceID = 6 AND s.EmployeeID = petrol.EmployeeID
	LEFT JOIN #Allowance design ON design.AllowanceID = 7 AND s.EmployeeID = design.EmployeeID
	LEFT JOIN #Allowance attendance ON attendance.AllowanceID = 8 AND s.EmployeeID = attendance.EmployeeID
	LEFT JOIN #Allowance meal ON meal.AllowanceID = 9 AND s.EmployeeID = meal.EmployeeID
	LEFT JOIN #Allowance area ON area.AllowanceID = 10 AND s.EmployeeID = area.EmployeeID
	LEFT JOIN #Allowance incentive ON incentive.AllowanceID = 11 AND s.EmployeeID = incentive.EmployeeID
	LEFT JOIN #NonFixed al ON al.IncomeID = 3 AND s.EmployeeID = al.EmployeeID
	LEFT JOIN #Allowance bonus6 ON bonus6.AllowanceID = 13 AND s.EmployeeID = bonus6.EmployeeID
	LEFT JOIN #tblSal_Tax st ON s.EmployeeID = st.EmployeeID AND st.Year = @Year AND st.Month = @Month
	LEFT JOIN #tblSal_Insurance ins ON s.EmployeeID = ins.EmployeeID
	LEFT JOIN #NonFixed addition ON addition.IncomeID = 17 AND s.EmployeeID = addition.EmployeeID
	LEFT JOIN #NonFixed excessOT ON excessOT.IncomeID = 16 AND s.EmployeeID = excessOT.EmployeeID
	LEFT JOIN #NonFixed deduction ON deduction.IncomeID = 4 AND s.EmployeeID = deduction.EmployeeID
	LEFT JOIN #Allowance bonus6att ON bonus6att.AllowanceID = 15 AND s.EmployeeID = bonus6att.EmployeeID
	LEFT JOIN #Allowance allowance ON allowance.AllowanceID = 14 AND s.EmployeeID = allowance.EmployeeID
	LEFT JOIN #CurrentSalary cs ON s.EmployeeID = cs.EmployeeID
	LEFT JOIN #InLateOutEarly ioc ON s.EmployeeID = ioc.EmployeeID
	ORDER BY s.EmployeeID

	UPDATE #DetailOfSalary SET UnpaidLeaveAmount = ISNULL(UnpaidLeaveAmount, 0) + ISNULL(GrossTotal, 0) - ISNULL(RegularAmt, 0) - ISNULL(PaidLeaveAmt, 0), TotalDeduction = ISNULL(TotalDeduction, 0) + (ISNULL(GrossTotal, 0) - ISNULL(RegularAmt, 0) - ISNULL(PaidLeaveAmt, 0))
	WHERE ISNULL(GrossTotal, 0) <> ISNULL(RegularAmt, 0) + ISNULL(PaidLeaveAmt, 0) AND ISNULL(TotalEarning, 0) - ISNULL(TotalDeduction, 0) <> ISNULL(Total, 0)

	-- UPDATE #DetailOfSalary SET OtherDeduction = ISNULL(TotalEarning, 0) - ISNULL(Total, 0), TotalDeduction = ISNULL(TotalDeduction, 0) + ISNULL(OtherDeduction, 0)
	-- WHERE ISNULL(TotalEarning, 0) - ISNULL(TotalDeduction, 0) <> ISNULL(Total, 0)

	IF (@IsPayslip = 1)
	BEGIN
		SELECT *
		FROM #DetailOfSalary

		RETURN
	END

	IF ISNULL(@isSummary, 0) = 0 AND ISNULL(@IsPayslip, 0) = 0
	BEGIN
		ALTER TABLE #DetailOfSalary

		DROP COLUMN MonthYear, Workdays, UnpaidLeaveDays, EmployeeExemption, FamilyExemption, TotalDeduction, AnnualLeaveHrs, EmployeeTotal, PaidLeavePS, OtherDeduction,
			OrtherIncome, IOCount, Bonus6Month_FullAttendance, UnpaidLeaveAmount, TotalEarning, TotalEarning_ExcludeUnpaidLeave, CostCenterName, EmployeeClass, EmployeeType

		--Standard workdays
		SELECT WorkingDays_Std * 8 AS STD_WorkingDays
		FROM tblWorkingDaySetting
		WHERE Year = @Year AND Month = @Month AND EmployeeTypeID = 0

        SELECT *
		FROM #DetailOfSalary

            --Lấy OT vượt TVC
		SELECT *
        INTO #ExcessOT
		FROM #DetailOfSalary

        ALTER TABLE #ExcessOT ALTER COLUMN AnnualBonus float null

        --OT Vượt TVC
        DELETE d
        FROM #ExcessOT d
        INNER JOIN #AttendanceSummary o ON d.EmployeeID = o.EmployeeID AND ISNULL(o.TotalExcessOT, 0) <= 0

        UPDATE d SET OT1 = o.OT1_ExcessOT, OT2a = o.OT2a_ExcessOT, OT2b = o.OT2b_ExcessOT, OT3 = o.OT3_ExcessOT, OT4 = o.OT4_ExcessOT, OT5 = o.OT5_ExcessOT, OT6 = o.OT6_ExcessOT, OT7 = o.OT7_ExcessOT,
			TotalOT = o.TotalExcessOT, OT1_ReduceTax = 0, ot2a_ReduceTax = 0, ot2b_ReduceTax = 0, OT3_ReduceTax = 0, OT4_ReduceTax = 0, OT6_ReduceTax = 0, OT7_ReduceTax = 0,
			TotalOT_ReduceTax = 0, TotalOT_Taxable = 0,
			-- cập nhật các cột còn lại về NULL, trừ các cột đang selected và 9 cột đầu
			RegularHrs = NULL, RegularAmt = NULL, PaidLeaveHrs_Total = NULL, PaidLeaveAmt = NULL,
			Seniority = NULL, LANGUAGE = NULL, Environment = NULL, Shift = NULL, NSHours = NULL, NSAmount = NULL, Petrol = NULL, Design = NULL, Attendance = NULL, Meal = NULL, Area = NULL, Incentive = NULL,
			RegularAllowance = NULL, IrregularAllowance = NULL, Addition = NULL, AnnualBonus = NULL, Bonus6Month = NULL, TotalIncome = NULL, DependantNumber = NULL, TaxableIncomeBeforeDeduction = NULL,
			IncomeAfterPIT = NULL, EmployeeSI = NULL, EmployeeHI = NULL, EmployeeUI = NULL, TaxAmt = NULL, EmpUnion = NULL, Deduction = NULL, Balance1 = NULL, Balance2 = NULL, Total = NULL,
			CompanySI = NULL, CompanyHI = NULL, CompanyUI = NULL, CompUnion = NULL, ALTotal = NULL, ALEveryM = NULL, Bonus6M = NULL, Bonus6M_EveryM = NULL
		FROM #ExcessOT d
		INNER JOIN #AttendanceSummary o ON d.EmployeeID = o.EmployeeID AND ISNULL(o.TotalExcessOT, 0) > 0

        ALTER TABLE #ExcessOT DROP COLUMN STT

        UPDATE d SET TotalOT = ISNULL(excessOT.Amount, 0)
        FROM #ExcessOT d
        LEFT JOIN #NonFixed excessOT ON excessOT.IncomeID = 16 AND d.EmployeeID = excessOT.EmployeeID

        SELECT ROW_NUMBER() OVER (
			ORDER BY EmployeeID
			) STT, * FROM #ExcessOT
	END

	IF (ISNULL(@isSummary, 0) = 1)
	BEGIN
		SELECT CostCenterName, EmployeeClass, EmployeeType, DepartmentName, COUNT(1) Qty, SUM(GrossTotal) GrossTotal, SUM(ISNULL(RegularAmt, 0) + ISNULL(PaidLeaveAmt, 0)) GrossTotal, SUM(RegularAllowance) RegularAllowance, SUM(
				IrregularAllowance) IrregularAllowance, SUM(Addition) Addition, SUM(Deduction) Deduction, SUM(TotalOT) TaxableOTAmount, SUM(TotalOT_ReduceTax)
			NontaxableOTAmount, SUM(EmployeeSI) EmployeeSI, SUM(EmployeeHI) EmployeeHI, SUM(EmployeeUI) EmployeeUI, SUM(TaxAmt) TaxAmt, SUM(EmpUnion) EmployeeUnion, CAST(NULL AS FLOAT) Advanced, SUM(Total)
			GrossTakeHome, SUM(CompanySI) CompanySI, SUM(CompanyHI) CompanyHI, sum(CompanyUI) CompanyUI, SUM(CompUnion) CompUnion, SUM(ALEveryM) ALEveryM, SUM(Bonus6M_EveryM) Bonus6M_EveryM
		FROM #DetailOfSalary
		GROUP BY CostCenterName, EmployeeClass, EmployeeType, DepartmentName

		SELECT CostCenterName, EmployeeClass, EmployeeType, CAST(NULL AS INT) Department, COUNT(1) Qty, SUM(GrossTotal) GrossTotal, SUM(ISNULL(RegularAmt, 0) + ISNULL(PaidLeaveAmt, 0)) GrossTotal, SUM(RegularAllowance) RegularAllowance, SUM(
				IrregularAllowance) IrregularAllowance, SUM(Addition) Addition, SUM(Deduction) Deduction, SUM(TotalOT) TaxableOTAmount, SUM(TotalOT_ReduceTax)
			NontaxableOTAmount, SUM(EmployeeSI) EmployeeSI, SUM(EmployeeHI) EmployeeHI, SUM(EmployeeUI) EmployeeUI, SUM(TaxAmt) TaxAmt, SUM(EmpUnion) EmployeeUnion, CAST(NULL AS FLOAT) Advanced, SUM(Total)
			GrossTakeHome, SUM(CompanySI) CompanySI, SUM(CompanyHI) CompanyHI, sum(CompanyUI) CompanyUI, SUM(CompUnion) CompUnion, SUM(ALEveryM) ALEveryM, SUM(Bonus6M_EveryM) Bonus6M_EveryM
		FROM #DetailOfSalary
		GROUP BY CostCenterName, EmployeeClass, EmployeeType
		ORDER BY CostCenterName DESC

		SELECT CONCAT (@Year, '.', FORMAT(DATEFROMPARTS(@Year, @Month, 1), 'MM', 'en-US'), '.', DAY(@ToDate)) AS MonthYear
		RETURN

	END

	SELECT CONCAT (@Year, '.', FORMAT(DATEFROMPARTS(@Year, @Month, 1), 'MMMM', 'en-US')) AS MonthYear

	CREATE TABLE #ExportConfig (
		ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200), SheetIndex INT
		, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200)
		)

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (0, 'Table_NonInsert', 'D11', 0, 0)

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex)
	SELECT 1, 'Table|ZeroMeanNull=1 ', 'A8', 0

    INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex)
	SELECT 2, 'Table|ZeroMeanNull=1 ', 'A8', 1

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (3, 'Table_NonInsert', 'A2', 0, 0)

	--  --Bank Transfer
	--  SELECT ROW_NUMBER()OVER(ORDER BY STTView) STT, e.FullName, PositionName, GrossTakeHome, AccountNo, ISNULL(BankName, '') + ' ' + ISNULL(BankAddress, '')
	--  FROM tblSal_Sal s
	--  INNER JOIN #tmpEmployeeList e ON e.EmployeeID = s.EmployeeID
	--  LEFT JOIN tblPosition pos ON e.PositionID = pos.PositionID
	--  LEFT JOIN tblEmployee ee ON ee.EmployeeID = e.EmployeeID
	--   LEFT JOIN dbo.fn_BankInfoList('VN') AS b ON b.BankCode = ee.BankCode
	--  WHERE Month = @Month AND Year = @Year
	--  INSERT INTO #ExportConfig(TableIndex, ParseType, Position, SheetIndex, WithHeader) VALUES (6, 'Table', 'A7', 3, 0)
	--  --sheet trợ cấp thôi việc
	--  IF EXISTS(SELECT 1 FROM #NonFixed WHERE IncomeID = 13 AND ISNULL(Amount, 0) > 0)
	--  BEGIN
	--  SELECT FullName, HireDate, TerminatedDate, ROUND(DATEDIFF(DAY, HireDate, LastWorkingDate) / 365.0,0) WorkingPeriod, PositionNameEN,
	--    DepartmentNameEN, SalaryPeriod_1,SalaryPeriod_1_Months,SalaryPeriod_2,SalaryPeriod_2_Months, ROUND(AverageSalary, 0), Severance_NumberOfMonth, Severance_Month, ROUND(Severance_ALL, 0), 'VND' Unit, NULL
	--  FROM tblTerminationDecision t
	--  INNER JOIN #tmpEmployeeList e ON t.EmployeeID = e.EmployeeID
	--  LEFT JOIN tblPosition p ON p.PositionID = e.PositionID
	--  LEFT JOIN tblDepartment d ON d.DepartmentID = e.DepartmentID
	--  WHERE t.EmployeeID IN (SELECT EmployeeID FROM #NonFixed WHERE IncomeID = 13 AND ISNULL(Amount, 0) > 0)
	--  INSERT INTO #ExportConfig(TableIndex, ParseType, Position, SheetIndex, WithHeader) VALUES (7, 'Table', 'B7', 4, 0)
	--  END
	SELECT *
	FROM #ExportConfig
END
	--exec sp_CompanySalarySummary 3,8,2025,'-1',0
GO
