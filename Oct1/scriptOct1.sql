
if object_id('[dbo].[ImportTimeSheet]') is null
	EXEC ('CREATE PROCEDURE [dbo].[ImportTimeSheet] as select 1')
GO
ALTER PROCEDURE [dbo].[ImportTimeSheet] (@LoginId INT)
AS
BEGIN
	SET NOCOUNT ON;

	--select * into ABC from #TempTableData return
	--	drop table ABC
	--SELECT * FROM ABC
	-- SELECT *
	-- INTO #TempTableData
	-- FROM ABC
	DECLARE @Month INT = NULL;
	DECLARE @Year INT = NULL;

	SELECT @Month = Month, @Year = Year
	FROM tblCurrentWorkingMonth

	DELETE #TempTableData
	WHERE len(isnull(RTRIM(LTRIM(EmployeeId)), '')) = 0

	-- -- check not exists employeeID
	UPDATE #TempTableData
	SET EmployeeId = LTRIM(RTRIM(EmployeeID))

	INSERT INTO tblProcessErrorMessage (LoginId, ErrorType, ErrorDetail)
	SELECT @loginID, 'Month - Year is null', 'Employee code:' + de.EmployeeID + ' is not exists, please check and reimport!'
	FROM (
		DELETE ta
		OUTPUT deleted.EmployeeID
		FROM #TempTableData ta
		WHERE NOT EXISTS (
				SELECT 1
				FROM tblEmployee e
				WHERE ta.EmployeeId = e.EmployeeID
				)
		) de

	SELECT EmployeeID
	INTO #Dup
	FROM #TempTableData
	GROUP BY EmployeeID
	HAVING COUNT(1) > 1

	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO tblProcessErrorMessage (LoginId, ErrorType, ErrorDetail)
		SELECT @loginID, 'Duplicate Employee Code', 'Employee code:' + de.EmployeeID + ' is duplicate, please check and reimport!'
		FROM (
			DELETE ta
			OUTPUT deleted.EmployeeID
			FROM #TempTableData ta
			WHERE employeeID IN (
					SELECT EmployeeId
					FROM #Dup
					)
			) de
	END

	-- INSERT INTO tblProcessErrorMessage (LoginId, ErrorType, ErrorDetail)
	-- SELECT @loginID, 'Month - Year is null', 'Timesheet import for Employee:' + de.EmployeeID + ' is null, please check and reimport!'
	-- FROM (
	-- 	DELETE #TempTableData
	-- 	OUTPUT deleted.EmployeeID
	-- 	WHERE Month IS NULL OR Year IS NULL
	-- 	) de
	INSERT INTO tblProcessErrorMessage (LoginId, ErrorType, ErrorDetail)
	SELECT @loginID, 'Month - Year Locked', 'Timesheet import for Employee:' + de.EmployeeID + ' is locked, please check and reimport!'
	FROM (
		DELETE #TempTableData
		OUTPUT deleted.EmployeeID
		FROM #TempTableData ex
		WHERE EXISTS (
				SELECT 1
				FROM tblAtt_LockMonth al
				WHERE ex.EmployeeID = al.EmployeeID AND al.Month = @Month AND al.Year = @Year
				)
		) de

	SELECT EmployeeID, AttTime, AttState, MachineNo
	INTO #tmpAttend
	FROM tbltmpAttend
	WHERE 1 = 0

	-- Tham số (gán đúng giá trị trước khi chạy)
	-- Build dynamic VALUES list cho CROSS APPLY (2 entries per day: In & Out)
	DECLARE @i INT = 1;
	DECLARE @vals NVARCHAR(MAX) = N'';

	WHILE @i <= 31
	BEGIN
		IF LEN(@vals) > 0
			SET @vals += N',';
		-- dùng unquoted column names via QUOTENAME
		SET @vals += N'(' + CAST(@i AS NVARCHAR(3)) + N', t.' + QUOTENAME(CAST(@i AS NVARCHAR(3)) + N'In') + N', 1)';
		SET @vals += N',(' + CAST(@i AS NVARCHAR(3)) + N', t.' + QUOTENAME(CAST(@i AS NVARCHAR(3)) + N'Out') + N', 2)';
		SET @i += 1;
	END

	-- Lưu ý: @vals giờ chứa 62 tuples: (1, t.[1In],1),(1,t.[1Out],2),...(31,t.[31Out],2)
	-- Tạo #tmpAttend từ #TempTableData
	DECLARE @sql NVARCHAR(MAX) = N'
		INSERT INTO #tmpAttend(EmployeeID, AttTime, AttState, MachineNo)
		SELECT
			t.EmployeeID,
			-- Tạo datetime bằng DATEFROMPARTS(@Year,@Month, v.Day) cộng với time v.TimeValue
			DATEADD(SECOND, DATEDIFF(SECOND, ''00:00:00'', v.TimeValue),
				CAST(DATEFROMPARTS(' + CAST(@Year AS NVARCHAR(4)) + N', ' + CAST(@Month AS NVARCHAR(2)) + N', v.Day) AS DATETIME)
			) AS AttTime,
			v.AttState, 999
		FROM #TempTableData t
		CROSS APPLY (VALUES ' + @vals + N') v(Day, TimeValue, AttState)
		WHERE v.TimeValue IS NOT NULL;
		';

	-- Xem SQL nếu muốn
	-- PRINT @sql; -- (để debug)
	EXEC sp_executesql @sql;

    UPDATE #tmpAttend SET AttTime = DATEADD(DAY, 1, AttTime)
    FROM #tmpAttend a
    WHERE EXISTS (
        SELECT 1
        FROM #tmpAttend t
        WHERE t.EmployeeID = a.EmployeeID AND CAST(t.AttTime AS DATE) = CAST(a.AttTime AS DATE)
                AND a.AttState = 2 AND t.AttState = 1 AND t.AttTime > a.AttTime
    ) AND a.AttState = 2

    DELETE tbltmpAttend
    WHERE EXISTS (
        SELECT 1
        FROM #tmpAttend t
        WHERE tbltmpAttend.EmployeeID = t.EmployeeID AND tbltmpAttend.AttTime = t.AttTime
                AND tbltmpAttend.AttState = t.AttState AND tbltmpAttend.MachineNo = t.MachineNo
    )

	INSERT INTO tbltmpAttend (EmployeeID, AttTime, AttState, MachineNo)
	SELECT EmployeeID, AttTime, AttState, MachineNo
	FROM #tmpAttend;
END
GO



if object_id('[dbo].[Template_ImportTimeSheet]') is null
	EXEC ('CREATE PROCEDURE [dbo].[Template_ImportTimeSheet] as select 1')
GO

ALTER PROCEDURE [dbo].[Template_ImportTimeSheet] (@LoginId INT = 3)
AS
BEGIN
	SELECT EmployeeID, FullName, HireDate, LastWorkingDate, DepartmentID
	INTO #tmpEmployeeList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(GETDATE(), '-1', @LoginID)


	CREATE TABLE #AttendanceData (STT INT, EmployeeID VARCHAR(20), DepartmentName NVARCHAR(50), FullName NVARCHAR(100), HireDate DATE)

	INSERT INTO #AttendanceData (STT, EmployeeID, FullName, DepartmentName, HireDate)
	SELECT ROW_NUMBER() OVER (
			ORDER BY e.EmployeeID
			), e.EmployeeID, e.FullName, d.DepartmentName, e.HireDate
	FROM #tmpEmployeeList e
	INNER JOIN tblDepartment d ON d.DepartmentID = e.DepartmentID

	------------------------------------------------------------------------------------
	DECLARE @Query NVARCHAR(MAX) = ''

	SET @Query = 'ALTER TABLE #AttendanceData ADD '

	SELECT @Query += '[' + Numbervarchar + 'In] TIME, [' + Numbervarchar + 'Out] TIME,'
	FROM dbo.fn_NumberlistVarchar(1, 31)

	SET @Query += 'NotUse FLOAT'

	EXEC (@Query)

	SET @Query = ''
	SET @Query += ' SELECT STT,
     s.EmployeeID,
	 s.FullName,
     s.DepartmentName,
	 s.HireDate'

	SELECT @Query += ', [' + NumberVarchar + 'In], [' + NumberVarchar + 'Out]'
	FROM dbo.fn_NumberlistVarchar(1, 31)

	SET @Query += N' FROM #AttendanceData s
     ORDER by EmployeeID'

	EXEC (@query)

	--SELECT @FromDate FromDate

	--DECLARE @HideColumn NVARCHAR(50) = '', @MaxDate INT, @MergeCol NVARCHAR(MAX) = ''

	CREATE TABLE #ExportConfig (ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200), SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200))

	-- DECLARE @DeleteDay INT

	-- SET @DeleteDay = 30 - DATEDIFF(dd, @FromDate, @ToDate)

	-- SELECT *
	-- INTO #ColumnExcel
	-- FROM dbo.fn_ColumnExcel('F', 'AJ')

	-- SELECT *
	-- INTO #ColumnView
	-- FROM dbo.fn_NumberlistVarchar(DAY(@FromDate), DAY(@ToDate)) d
	-- INNER JOIN #ColumnExcel c ON d.Number = c.ORD

	-- DELETE
	-- FROM #ColumnExcel
	-- WHERE ORD IN (
	-- 		SELECT ORD
	-- 		FROM #ColumnView
	-- 		)

	-- DECLARE @hideColumnExcel NVARCHAR(50) = ''

	-- IF @DeleteDay > 0
	-- BEGIN
	-- 	INSERT INTO #ExportConfig (ParseType, Position, SheetIndex)
	-- 	SELECT 'DeleteColumn', ColumnExcel, 0
	-- 	FROM (
	-- 		SELECT row_number() OVER (
	-- 				ORDER BY ORD DESC
	-- 				) ORD, ColumnExcel
	-- 		FROM #ColumnExcel
	-- 		) a
	-- 	WHERE ORD <= @DeleteDay
	-- END

	-- SET @Query = ''
	-- SELECT @Query += ',' + Numbervarchar
	-- FROM dbo.fn_NumberlistVarchar(DAY(@FromDate), DAY(@ToDate))
	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (0, 'Table', 'A10', 0, 0)

	-- INSERT INTO #ExportConfig (TableIndex, SheetIndex, ParseType, ColumnList_formatCell, formatCell, Position)
	-- VALUES (0, 0, 'formatcell', @Query, 'general', 'A9')
	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (1, 'Table', 'A1', 1, 0)

	SELECT *
	FROM #ExportConfig
END
GO



