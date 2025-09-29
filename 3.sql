USE Paradise_TRIPOD
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

	ALTER TABLE #tblAttendanceSummary

	ALTER COLUMN PeriodID INT NULL

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
        INSERT INTO #tblAttendanceSummary (EmployeeID, Month, Year ' + @querySelector + N')
        SELECT
            EmployeeID,
            @Month AS Month,
            @Year AS Year
            ' + @cols + N'
        FROM tblAttendanceSummary
        WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
            SELECT EmployeeID FROM #tmpEmployeeList
        )
        GROUP BY EmployeeID, Month, Year
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
		STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), PositionName NVARCHAR(MAX), HireDate DATE
		)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, DepartmentName, PositionName)
	SELECT No, EmployeeID, FullName, HireDate, DepartmentName, PositionName
	FROM #tmpEmployeeList

	DECLARE @Query NVARCHAR(MAX) = 'ALTER TABLE #SummaryData ADD '

	SELECT @Query += ISNULL(TACode, '') + ' DECIMAL(10, 1), '
	FROM #LeaveCode
	ORDER BY ORD ASC

	SELECT @Query += 'IOHrs DECIMAL(10, 1), TotalOT DECIMAL(10, 1), TotalDayOff DECIMAL(10, 1), TotalNS DECIMAL(10, 1),'

	SELECT @Query += ISNULL(ColumnDisplayName, '') + ' DECIMAL(10, 1),'
	FROM tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	IF (ISNULL(@isExport, 0) = 0)
	BEGIN
		SELECT @Query += N'[' + CAST(Number AS VARCHAR(3)) + 'Att] VARCHAR(30), '
		FROM dbo.fn_Numberlist(CAST(DAY(@FromDate) AS INT), CAST(DAY(@ToDate) AS INT))
	END

	SET @Query = @Query + ' WorkHours FLOAT, PaidLeaveHrs FLOAT, UnpaidLeave FLOAT, ForgetTimekeeper INT, Signture NVARCHAR(10), Notes NVARCHAR(200)'

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

	SELECT *
	FROM #SummaryData

	RETURN

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
	SET WorkHours = a.WorkingHrs_Total, PaidLeaveHrs = a.PaidLeaveHrs_Total, UnpaidLeave = a.UnpaidLeaveDays * a.Std_Hour_PerDays
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

	ALTER TABLE #SummaryData

	DROP COLUMN Office

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
exec sp_AttendanceSummaryMonthly_STD 8,2025,3