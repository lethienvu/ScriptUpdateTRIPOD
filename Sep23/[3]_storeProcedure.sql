-- select top (200) * from sys.objects where name not in ('sp_GetupdateScriptVer','SC_Login_CheckLogin','SC_Login_GetWebInfo') and type_desc = 'SQL_STORED_PROCEDURE' AND modify_date < '20250920' order by modify_date desc
IF object_id('[dbo].[TA_ShiftDetector_task_NextMonth]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[TA_ShiftDetector_task_NextMonth] as select 1')
GO

ALTER PROCEDURE [dbo].[TA_ShiftDetector_task_NextMonth] @LoginID INT = 3
AS
BEGIN
	DECLARE @ToDate DATETIME, @FromDate DATETIME
	DECLARE @month INT, @Year INT

	SELECT @month = Month, @Year = Year
	FROM dbo.fn_Get_Sal_Month_Year(getdate())

	SELECT @month = month, @Year = Year
	FROM dbo.fn_GetMonthYearFromIntValue(@Year * 12 + @month + 1)

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@month, @Year)

	SET @LoginID = @LoginID - 1100

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID

	INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
	SELECT DISTINCT EmployeeID, @LoginID
	FROM dbo.fn_vtblemployeeList_bydate(@todate, '-1', NULL) e
	WHERE isnull(e.TerminateDate, getdate()) > DATEADD(day, - 45, getdate())

	EXEC [sp_InsertPendingProcessAttendanceData] @LoginID = @LoginID, @Fromdate = @Fromdate, @ToDate = @ToDate, @EmployeeID = '-1', @HasShiftDetector = 1, @HasOvertime = 1

	EXEC sp_ShiftDetector @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	EXEC TA_Process_Main @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	DELETE tblProcessErrorMessage
	WHERE LoginID = @LoginID

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID
END
GO

IF object_id('[dbo].[TA_ShiftDetector_task_LastMonth]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[TA_ShiftDetector_task_LastMonth] as select 1')
GO

ALTER PROCEDURE [dbo].[TA_ShiftDetector_task_LastMonth] @LoginID INT = 3
AS
BEGIN
	DECLARE @ToDate DATETIME, @FromDate DATETIME, @conditionProcess DATETIME

	SELECT @conditionProcess = Fromdate
	FROM dbo.fn_Get_SalaryPeriod_ByDate(getdate())

	SET @conditionProcess = dateadd(dd, 15, @conditionProcess)

	IF GETDATE() >= @conditionProcess
		RETURN
	ELSE
	BEGIN
		DECLARE @month INT, @Year INT

		SELECT @month = Month, @Year = Year
		FROM dbo.fn_Get_Sal_Month_Year(getdate())

		SELECT @month = month, @Year = Year
		FROM dbo.fn_GetMonthYearFromIntValue(@Year * 12 + @month - 1)

		SELECT @FromDate = FromDate, @ToDate = ToDate
		FROM dbo.fn_Get_SalaryPeriod(@month, @Year)
	END

	SET @LoginID = @LoginID - 11014

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID

	INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
	SELECT DISTINCT EmployeeID, @LoginID
	FROM dbo.fn_vtblemployeeList_bydate(@todate, '-1', NULL) e
	WHERE isnull(e.TerminateDate, getdate()) > DATEADD(day, - 45, getdate())

	EXEC [sp_InsertPendingProcessAttendanceData] @LoginID = @LoginID, @Fromdate = @Fromdate, @ToDate = @ToDate, @EmployeeID = '-1', @HasShiftDetector = 1, @HasOvertime = 1

	EXEC sp_ShiftDetector @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	EXEC TA_Process_Main @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	DELETE tblProcessErrorMessage
	WHERE LoginID = @LoginID

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID
END
GO

IF object_id('[dbo].[TA_ShiftDetector_task_daily]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[TA_ShiftDetector_task_daily] as select 1')
GO

ALTER PROCEDURE [dbo].[TA_ShiftDetector_task_daily] @LoginID INT = 3
AS
BEGIN
	--xu ly full thang cua ki luong luon, bonus them 3 ngay trong tuong lai
	DECLARE @ToDate DATETIME, @FromDate DATETIME --,@month INT,@Year INT

	SET @ToDate = CAST(GETDATE() AS DATE)
	--SET @ToDate = DATEADD(DAY,3,@ToDate)
	SET @FromDate = @ToDate
	SET @LoginID = @LoginID - 479588

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID

	INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
	SELECT DISTINCT EmployeeID, @LoginID
	FROM dbo.fn_vtblemployeeList_bydate(@todate, '-1', NULL) e
	WHERE isnull(e.TerminateDate, getdate()) > DATEADD(day, - 45, getdate())

	EXEC [sp_InsertPendingProcessAttendanceData] @LoginID = @LoginID, @Fromdate = @Fromdate, @ToDate = @ToDate, @EmployeeID = '-1', @HasShiftDetector = 1, @HasOvertime = 1

	EXEC sp_ShiftDetector @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	EXEC TA_Process_Main @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	DELETE tblProcessErrorMessage
	WHERE LoginID = @LoginID

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID
END
GO

IF object_id('[dbo].[TA_ShiftDetector_task]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[TA_ShiftDetector_task] as select 1')
GO

ALTER PROCEDURE [dbo].[TA_ShiftDetector_task] @LoginID INT = 3
AS
BEGIN
	--xu ly full thang cua ki luong luon, bonus them 3 ngay trong tuong lai
	DECLARE @ToDate DATETIME, @FromDate DATETIME --,@month INT,@Year INT

	SET @ToDate = CAST(GETDATE() AS DATE)

	--SET @ToDate = DATEADD(DAY,3,@ToDate)
	SELECT @FromDate = Fromdate, @ToDate = Todate
	FROM dbo.fn_Get_SalaryPeriod_ByDate(getdate())

	SET @LoginID = @LoginID - 4795

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID

	INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
	SELECT DISTINCT EmployeeID, @LoginID
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@todate, '-1', NULL) e
	WHERE isnull(e.TerminateDate, getdate()) > DATEADD(day, - 45, getdate())

	EXEC [sp_InsertPendingProcessAttendanceData] @LoginID = @LoginID, @Fromdate = @Fromdate, @ToDate = @ToDate, @EmployeeID = '-1', @HasShiftDetector = 1, @HasOvertime = 1

	EXEC sp_ShiftDetector @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	EXEC TA_Process_Main @LoginID = @LoginID, @FromDate = @Fromdate, @ToDate = @Todate, @EmployeeID = '-1'

	DELETE tblProcessErrorMessage
	WHERE LoginID = @LoginID

	DELETE tmpEmployeeTree
	WHERE LoginID = @LoginID
END
GO

IF object_id('[dbo].[sp_ReadFile_Service]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_ReadFile_Service] as select 1')
GO

--exec sp_ReadFile_Service N'Y:\20230929.txt','2023-09-29 10:58:57',3
ALTER PROCEDURE [dbo].[sp_ReadFile_Service] @FileName NVARCHAR(255) = '', @LastModifyTime DATETIME, @LoginID INT = 3
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#TempTableData') IS NULL --chạy từ pm về không có dữ liệu trong file
		RETURN

	--Lưu nội dung file đọc được vào database
	EXEC ImportLogFile @LoginID = 3

	SET @FileName = (
			SELECT Value
			FROM tblParameter
			WHERE Code = 'ImportLogFile_Location'
			) --nơi lưu folder cần đọc file
		--if @FileName not like '%\'
		--	SET @FileName = @FileName + '\'
		--select top 1 @FileName = @FileName + FileName from #TempTableData

	DECLARE @FileNameBackup NVARCHAR(255), @LastIndexFolder INT

	SET @LastIndexFolder = CHARINDEX('\', REVERSE(@FileName))

	SELECT @FileNameBackup = LEFT(@FileName, LEN(@FileName) - @LastIndexFolder) + '\BackupFile' + RIGHT(@FileName, @LastIndexFolder)

	--SET @FileNameBackup = 'C:\Users\Vu.Le\Desktop\TVB_BarcodeLogsFile\' + RIGHT(@FileName, @LastIndexFolder)
	--di chuyển file
	SELECT 'MoveFile_Service' Function_Name, '' Class_Name, @FileName param1, @FileNameBackup AS param2, cast(1 AS BIT) param3
		--select @FileName
END
GO

USE Paradise_TRIPOD
GO

IF object_id('[dbo].[ImportLogFile]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[ImportLogFile] as select 1')
GO

ALTER PROCEDURE [dbo].[ImportLogFile] (@LoginID INT = 3)
AS
IF (OBJECT_ID('tmpLogFile')) IS NULL
BEGIN
	--drop table tmpLogFile
	SELECT *
	INTO tmpLogFile
	FROM #temptableData
END
ELSE
	INSERT INTO tmpLogFile
	SELECT *
	FROM #temptableData t
	WHERE NOT EXISTS (
			SELECT 1
			FROM tmpLogFile l
			WHERE l.FileName = t.FileName
			)

RETURN

IF (OBJECT_ID('tempdb..#temptableData')) IS NULL
	RETURN

DELETE
FROM #temptableData
WHERE ISNULL(Content, '') = ''

DECLARE @SN VARCHAR(max), @MachineNumber INT

SELECT TOP 1 @SN = sn, @MachineNumber = MachineNumber
FROM Machines

IF (@SN IS NULL OR @MachineNumber IS NULL)
	RETURN

/*
	00100 20080107 202309070826
	00700 10875726 202309070815
	00400 02520876 202309070729
	00400 10730585 202309070728
*/
SELECT SUBSTRING(Content, 6, 8) BadgeNumber, cast(2 AS INT) InOutMode, cast(2 AS INT) VerifyCode, cast(0 AS INT) WorkCode, cast(STUFF(STUFF(STUFF(STUFF(RIGHT(Content, 12), 5, 0, '-'), 8, 0, '-'), 11, 0, ' '), 14, 0, ':') AS DATETIME) CheckTime, @SN SN, @LoginID LoginID, 'S' EventType, @MachineNumber MachineNumber, cast(NULL AS VARBINARY) PhotoImage, cast(2 AS INT) temperature, cast(2 AS INT) maskflag, cast('' AS VARCHAR) CardNo
INTO #tmpInsert
FROM #temptableData

-- Xử lý số 0 đầu BadgeNumber
UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 2, 7)
WHERE BadgeNumber LIKE '0%'

UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 3, 6)
WHERE BadgeNumber LIKE '00%'

UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 4, 5)
WHERE BadgeNumber LIKE '000%'

UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 5, 4)
WHERE BadgeNumber LIKE '0000%'

UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 6, 3)
WHERE BadgeNumber LIKE '00000%'

UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 7, 2)
WHERE BadgeNumber LIKE '000000%'

UPDATE #tmpInsert
SET BadgeNumber = SUBSTRING(BadgeNumber, 8, 1)
WHERE BadgeNumber LIKE '0000000%'

IF (OBJECT_ID('tmpLogFile')) IS NOT NULL
	DROP TABLE tmpLogFile

SELECT *
INTO tmpLogFile
FROM #tmpInsert

SELECT DISTINCT FileName, LTRIM(RTRIM(SUBSTRING(Content, 1, 10))) AS [Status], LTRIM(RTRIM(SUBSTRING(Content, 11, 10))) AS Port, LTRIM(RTRIM(SUBSTRING(Content, 21, 10))) AS BadgeNumber, CONVERT(DATETIME, LTRIM(RTRIM(SUBSTRING(Content, 31, 23))), 121) AS [Timestamp], LTRIM(RTRIM(SUBSTRING(Content, 56, 20))) AS IP, LTRIM(RTRIM(SUBSTRING(Content, 76, 100))) AS Host
INTO #tmpLogFile
FROM tmpLogFile

INSERT INTO tbltmpAttend (EmployeeID, AttTime, AttState, MachineNo)
SELECT ui.SSN, t.[Timestamp], CASE 
		WHEN t.[Status] = 'IN'
			THEN 1
		ELSE 2
		END, m.MachineNumber
FROM #tmpLogFile t
INNER JOIN dbo.fn_USERINFO() ui ON t.BadgeNumber = SUBSTRING(ui.BadgeNumber, 3, LEN(ui.BadgeNumber) - 2)
LEFT JOIN Machines m ON t.IP = m.IP
WHERE NOT EXISTS (
		SELECT 1
		FROM tbltmpAttend a
		WHERE a.EmployeeID = ui.SSN AND a.AttTime = t.[Timestamp]
		)

RETURN

-- INSERT INTO tmpCHECKINOUT
-- SELECT *
-- FROM #tmpInsert t
-- WHERE NOT EXISTS (
-- 		SELECT 1
-- 		FROM tmpCHECKINOUT c
-- 		WHERE c.BadgeNumber = t.BadgeNumber AND c.CheckTime = t.CheckTime AND c.SN = t.SN
-- 		)
EXEC sp_MachineUpdateNew @LoginID = @LoginID, @LanguageID = 'VN', @Command = 'DOWNLOADLOGS', @sn = @SN, @MachineNumber = @MachineNumber
GO

IF object_id('[dbo].[SchemaImportLogFile]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[SchemaImportLogFile] as select 1')
GO

ALTER PROCEDURE [dbo].[SchemaImportLogFile]
AS
SELECT TOP 0 cast(NULL AS NVARCHAR(max)) FileName, cast(NULL AS NVARCHAR(max)) Content
GO

IF object_id('[dbo].[sp_RecentAttimeList]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_RecentAttimeList] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_RecentAttimeList] (@LoginID INT = 3, @LanguageID NVARCHAR(10) = 'EN', @EmployeeID VARCHAR(20) = '-1', @FromDate DATETIME = NULL, @ToDate DATETIME = NULL, @month INT = NULL, @Year INT = NULL)
AS
-- bỏ order by column
IF datepart(hour, @ToDate) = 0 AND datepart(minute, @ToDate) = 0 AND datepart(second, @ToDate) = 0
	SET @ToDate = dateadd(second, 68399, dbo.Truncate_Date(@ToDate))

DECLARE @DeleteLogsConsecutive INT = isnull((
			SELECT TOP (1) Value
			FROM tblParameter
			WHERE Code = 'DeleteLogsConsecutive'
			), 0), @GetDate DATETIME = getdate()

IF @DeleteLogsConsecutive > 0
BEGIN
	IF EXISTS (
			SELECT 1
			FROM tblEmployee
			HAVING count(1) > 500
			)
	BEGIN
		-- xoa du lieu cu 6 thang, và hinh cham cong cua thang truoc
		DELETE c
		FROM CHECKINOUT c
		WHERE c.CHECKTIME < dateadd(month, - 6, @GetDate)

		DELETE c
		FROM tblTmpAttend c
		WHERE c.AttTime < dateadd(month, - 12, @GetDate)

		UPDATE tblTmpAttend
		SET PhotoImage = NULL
		WHERE PhotoImage IS NOT NULL AND AttTime < dateadd(day, - 35, @GetDate)
	END

	BEGIN
		-- xoa nhung dong cham cong lien tiep trong khoang 10s
		SELECT row_number() OVER (
				ORDER BY EmployeeID, AttTime
				) ord, *, dateadd(second, @DeleteLogsConsecutive, AttTime) Next10Seconds
		INTO #tmptblTmpAttend
		FROM tblTmpAttend ta
		WHERE ta.AttTime BETWEEN @FromDate AND @ToDate

		/*HaiDang Edit 15 - 03 - 2022*/
		SELECT ta1.AttState, ta1.AttTime, ta1.EmployeeID, ta1.MachineNo
		INTO #tmptblTmpAttend_Del
		FROM #tmptblTmpAttend ta1
		WHERE EXISTS (
				SELECT 1
				FROM #tmptblTmpAttend ta2
				WHERE ta1.EmployeeID = ta2.EmployeeID AND ta1.ord > ta2.ord AND ta2.Next10Seconds > ta1.AttTime
				)

		DELETE tblTmpAttend
		FROM tblTmpAttend a
		INNER JOIN #tmptblTmpAttend_Del b ON a.EmployeeID = b.EmployeeID AND a.AttTime = b.AttTime AND a.AttState = b.AttState AND a.MachineNo = b.MachineNo

		--delete t
		--from tblTmpAttend t
		--left join (select ta1.*
		--   from #tmptblTmpAttend ta1
		--   left join #tmptblTmpAttend ta2 on ta1.EmployeeID=ta2.EmployeeID and ta1.ord>ta2.ord and ta2.Next10Seconds>ta1.AttTime
		--   where ta2.EmployeeID is not null) tmp on t.AttState=tmp.AttState and tmp.AttTime=t.AttTime and tmp.EmployeeID=t.EmployeeID and tmp.MachineNo=t.MachineNo
		--where tmp.EmployeeID is not null
		DROP TABLE #tmptblTmpAttend_Del

		DROP TABLE #tmptblTmpAttend
	END
END

--
SELECT t.sn, t.PhotoImage, cast(t.AttTime AS DATE) AttDate, cast(t.AttTime AS TIME) AttTime_View, t.maskflag, t.EmployeeID, te.FullName, m.MachineAlias, MachineNo, CASE 
		WHEN @LanguageID = 'VN'
			THEN InOutStatusName
		ELSE InOutStatusNameEN
		END AttStateName, AttState, t.AttTime, t.temperature, t.AttType
INTO #tbltmpAttendData
FROM tblTmpAttend t
LEFT JOIN tblEmployee te ON t.EmployeeID = te.EmployeeID
LEFT JOIN Machines m ON (t.sn = m.sn OR t.sn IS NULL) AND m.MachineNumber = t.MachineNo
LEFT JOIN tblInOutStatus ios ON ios.InOutStatus = t.AttState
LEFT JOIN tmpEmployeeTree tmpE ON tmpE.EmployeeID = te.EmployeeID AND tmpE.LoginID = @LoginID
WHERE t.AttTime BETWEEN @FromDate AND @ToDate AND (t.EmployeeID = @EmployeeID OR @EmployeeID = '-1') AND tmpE.EmployeeID IS NOT NULL
ORDER BY t.EmployeeID, t.AttTime, t.AttState

IF NOT EXISTS (
		SELECT 1
		FROM #tbltmpAttendData
		WHERE PhotoImage IS NOT NULL
		)
	ALTER TABLE #tbltmpAttendData

DROP COLUMN PhotoImage

SELECT att.*, ls.isReadOnlyRow
FROM #tbltmpAttendData att
LEFT JOIN vAttLockDateStatus ls ON att.EmployeeID = ls.EmployeeID AND att.AttDate = ls.AttDate
ORDER BY att.EmployeeID, att.AttDate
GO

IF object_id('[dbo].[spChangeStatus]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[spChangeStatus] as select 1')
GO

ALTER PROCEDURE [dbo].[spChangeStatus] (@loginID INT)
AS
BEGIN
	SELECT 3 AS [DateStatus]
END
GO

IF object_id('[dbo].[sp_accumulatedOT]') IS NULL
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

	IF COL_LENGTH('tblAttendanceSummary', 'DateStatus') IS NULL
		ALTER TABLE tblAttendanceSummary ADD [DateStatus] INT;

	-- Add Primary Key if not exists
	IF EXISTS (
			SELECT *
			FROM sys.columns
			WHERE object_id = OBJECT_ID('tblAttendanceSummary') AND name = 'EmployeeID' AND is_nullable = 1
			)
		ALTER TABLE tblAttendanceSummary

	ALTER COLUMN EmployeeID VARCHAR(20) NOT NULL;

	IF EXISTS (
			SELECT *
			FROM sys.columns
			WHERE object_id = OBJECT_ID('tblAttendanceSummary') AND name = 'Year' AND is_nullable = 1
			)
		ALTER TABLE tblAttendanceSummary

	ALTER COLUMN Year INT NOT NULL;

	IF EXISTS (
			SELECT *
			FROM sys.columns
			WHERE object_id = OBJECT_ID('tblAttendanceSummary') AND name = 'Month' AND is_nullable = 1
			)
		ALTER TABLE tblAttendanceSummary

	ALTER COLUMN Month INT NOT NULL;

	IF EXISTS (
			SELECT *
			FROM sys.columns
			WHERE object_id = OBJECT_ID('tblAttendanceSummary') AND name = 'PeriodID' AND is_nullable = 1
			)
		ALTER TABLE tblAttendanceSummary

	ALTER COLUMN PeriodID INT NOT NULL;

	IF NOT EXISTS (
			SELECT *
			FROM sys.key_constraints
			WHERE name = 'PK_tblAttendanceSummary'
			)
		ALTER TABLE tblAttendanceSummary ADD CONSTRAINT PK_tblAttendanceSummary PRIMARY KEY (EmployeeID, Year, Month, PeriodID);

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

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind, ots.ColumnDisplayName OTType, te.PeriodID
	INTO #OTList
	FROM tblOTList ot
	INNER JOIN #tblAttendanceSummary te ON ot.EmployeeID = te.EmployeeID AND ot.OTDate BETWEEN te.FromDate AND te.ToDate
	INNER JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OTKind
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0

	SELECT EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType, PeriodID
	INTO #tblOTSummary
	FROM #OTList
	GROUP BY EmployeeID, OTKind, OTType, PeriodID

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

	CREATE TABLE #SummaryData (STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), HireDate DATE, PeriodID INT)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, DepartmentName, PeriodID)
	SELECT ROW_NUMBER() OVER (
			ORDER BY t.EmployeeID
			), t.EmployeeID, FullName, t.HireDate, ISNULL(DepartmentName, ''), PeriodID
	FROM #tmpEMP t
	INNER JOIN #tblAttendanceSummary a ON t.EmployeeID = a.EmployeeID

	DECLARE @Query NVARCHAR(MAX) = 'ALTER TABLE #SummaryData ADD '

	SELECT @Query += ISNULL(ColumnDisplayName, '') + '_Total DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + ' DECIMAL(10, 2),' + ISNULL(ColumnDisplayName, '') + '_ExcessOT DECIMAL(10, 2),'
	FROM #tblOvertimeSetting
	ORDER BY ColumnDisplayName ASC

	SELECT @Query += ' TotalOT DECIMAL(10, 2), TotalExcessOT DECIMAL(10, 2), TotalExcessOT_Raw DECIMAL(10, 2)'

	EXEC sp_executesql @Query

	SET @Query = ''

	SELECT @Query += N'UPDATE s SET [' + ISNULL(ColumnDisplayName, '') + '] = ISNULL(w.ApprovedHours, 0),
                                    [' + ISNULL(ColumnDisplayName, '') + '_Total] = ISNULL(w.ApprovedHours, 0)
                        FROM #SummaryData s
                        LEFT JOIN #tblOTSummary w ON s.EmployeeID = w.EmployeeID
                        WHERE w.OTType = ''' + ISNULL(ColumnDisplayName, '') + N''';'
	FROM #tblOvertimeSetting

	EXEC sp_executesql @Query

	UPDATE s
	SET TotalOT = ISNULL(a.SumOTHours, 0)
	FROM #SummaryData s
	INNER JOIN (
		SELECT EmployeeID, PeriodID, SUM(ApprovedHours) SumOTHours
		FROM #tblOTSummary
		GROUP BY EmployeeID, PeriodID
		) a ON a.EmployeeID = s.EmployeeID AND a.PeriodID = s.PeriodID

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
	SET @Query = ''

	SELECT @Query += '
    UPDATE s SET  ' + ColumnDisplayName + ' = NULL
    FROM tblAttendanceSummary s
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ' AND ISNULL(s.DateStatus, 0) <> 3;
    UPDATE s SET  ' + ColumnDisplayName + ' = d.' + ColumnDisplayName + '
    FROM tblAttendanceSummary s
    LEFT JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ' AND ISNULL(s.DateStatus, 0) <> 3;
    UPDATE s SET  ' + ColumnDisplayName + '_ExcessOT = d.' + ColumnDisplayName + '_ExcessOT
    FROM tblAttendanceSummary s
    LEFT JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ' AND ISNULL(s.DateStatus, 0) <> 3;'
	FROM #tblOvertimeSetting

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TotalExcessOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT * ' + CAST(OvValue / 100 AS VARCHAR(5)) + ', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE #SummaryData SET TotalExcessOT_Raw = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N'_ExcessOT, 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM #SummaryData d
    INNER JOIN tblAttendanceSummary s ON s.EmployeeID = d.EmployeeID
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET TaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	SET @Query = 'UPDATE tblAttendanceSummary SET NonTaxableOT = '

	SELECT @Query += N'ISNULL(d.' + ISNULL(ColumnDisplayName, '') + N' * ' + CAST((
				CASE 
					WHEN 100 - OvValue < 0
						THEN 0
					ELSE (100 - OvValue)
					END
				) / 100 AS VARCHAR(5)) + N', 0) + '
	FROM #tblOvertimeSetting

	SET @Query = LEFT(@Query, LEN(@Query) - 1) + ' FROM tblAttendanceSummary s
    INNER JOIN #SummaryData d ON s.EmployeeID = d.EmployeeID
    WHERE s.Year = ' + CAST(@Year AS VARCHAR(4)) + ' AND s.Month = ' + CAST(@Month AS VARCHAR(2)) + ';'

	EXEC sp_executesql @Query

	IF ISNULL(@isView, '') = 0
		SELECT a.EmployeeID, d.FullName, d.DepartmentName, d.HireDate, d.TotalOT, d.TotalExcessOT, d.TotalExcessOT_Raw, a.[Month], a.[Year], a.PeriodID, d.OT1_Total, a.OT1, a.OT1_ExcessOT, d.OT2a_Total, a.OT2a, a.OT2a_ExcessOT, d.OT2b_Total, a.OT2b, a.OT2b_ExcessOT, d.OT3_Total, a.OT3, a.OT3_ExcessOT, d.OT4_Total, a.OT4, a.OT4_ExcessOT, d.OT5_Total, a.OT5, a.OT5_ExcessOT, d.OT6_Total, a.OT6, a.OT6_ExcessOT, d.OT7_Total, a.OT7, a.OT7_ExcessOT, a.DateStatus
		FROM tblAttendanceSummary a
		INNER JOIN #SummaryData d ON a.EmployeeID = d.EmployeeID
		WHERE a.Year = @Year AND a.Month = @Month AND (ISNULL(@isExcess, 0) = 0 OR (ISNULL(@isExcess, 0) = 1 AND d.TotalExcessOT > 0))
END
GO

IF object_id('[dbo].[sp_validateTotalOT]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_validateTotalOT] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_validateTotalOT] (@LoginID INT, @OT1_Total FLOAT, @OT1 FLOAT, @OT1_ExcessOT FLOAT, @OT2a_Total FLOAT, @OT2a FLOAT, @OT2a_ExcessOT FLOAT, @OT2b_Total FLOAT, @OT2b FLOAT, @OT2b_ExcessOT FLOAT, @OT3_Total FLOAT, @OT3 FLOAT, @OT3_ExcessOT FLOAT, @OT4_Total FLOAT, @OT4 FLOAT, @OT4_ExcessOT FLOAT, @OT5_Total FLOAT, @OT5 FLOAT, @OT5_ExcessOT FLOAT, @OT6_Total FLOAT, @OT6 FLOAT, @OT6_ExcessOT FLOAT, @OT7_Total FLOAT, @OT7 FLOAT, @OT7_ExcessOT FLOAT, @LanguageID VARCHAR(2) = 'VN')
AS
BEGIN
	IF (@OT1_Total <> ISNULL(@OT1, 0) + ISNULL(@OT1_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT1_ExcessOT

	IF (@OT2a_Total <> ISNULL(@OT2a, 0) + ISNULL(@OT2a_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT2a_ExcessOT

	IF (@OT2b_Total <> ISNULL(@OT2b, 0) + ISNULL(@OT2b_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT2b_ExcessOT

	IF (@OT3_Total <> ISNULL(@OT3, 0) + ISNULL(@OT3_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT3_ExcessOT

	IF (@OT4_Total <> ISNULL(@OT4, 0) + ISNULL(@OT4_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT4_ExcessOT

	IF (@OT5_Total <> ISNULL(@OT5, 0) + ISNULL(@OT5_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT5_ExcessOT

	IF (@OT6_Total <> ISNULL(@OT6, 0) + ISNULL(@OT6_ExcessOT, 0))
		SELECT CASE 
				WHEN @LanguageID = 'VN'
					THEN N'Tổng OT miễn thuế và OT vượt phải bằng tổng số giờ OT thực tế'
				ELSE 'Total OT and Excess OT must equal to Total OT'
				END AS OT6_ExcessOT
END
GO

IF object_id('[dbo].[sp_updateOTRemain_evtProc]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_updateOTRemain_evtProc] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_updateOTRemain_evtProc] (@LoginID INT, @OT1_Total FLOAT, @OT1 FLOAT, @OT1_ExcessOT FLOAT, @OT2a_Total FLOAT, @OT2a FLOAT, @OT2a_ExcessOT FLOAT, @OT2b_Total FLOAT, @OT2b FLOAT, @OT2b_ExcessOT FLOAT, @OT3_Total FLOAT, @OT3 FLOAT, @OT3_ExcessOT FLOAT, @OT4_Total FLOAT, @OT4 FLOAT, @OT4_ExcessOT FLOAT, @OT5_Total FLOAT, @OT5 FLOAT, @OT5_ExcessOT FLOAT, @OT6_Total FLOAT, @OT6 FLOAT, @OT6_ExcessOT FLOAT, @OT7_Total FLOAT, @OT7 FLOAT, @OT7_ExcessOT FLOAT)
AS
BEGIN
	SELECT @OT1_Total - ISNULL(@OT1_ExcessOT, 0) AS OT1, @OT2a_Total - ISNULL(@OT2a_ExcessOT, 0) AS OT2a, @OT2b_Total - ISNULL(@OT2b_ExcessOT, 0) AS OT2b, @OT3_Total - ISNULL(@OT3_ExcessOT, 0) AS OT3, @OT4_Total - ISNULL(@OT4_ExcessOT, 0) AS OT4, @OT5_Total - ISNULL(@OT5_ExcessOT, 0) AS OT5, @OT6_Total - ISNULL(@OT6_ExcessOT, 0) AS OT6, @OT7_Total - ISNULL(@OT7_ExcessOT, 0) AS OT7
END
GO

IF object_id('[dbo].[sp_AttendanceSummaryMonthly_STD]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_AttendanceSummaryMonthly_STD] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_AttendanceSummaryMonthly_STD] (@Month INT, @Year INT, @LoginID INT = 3, @LanguageID VARCHAR(2) = 'VN', @OptionView INT = 1, @isExport INT = 0)
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	DECLARE @GetDate DATETIME = dbo.Truncate_Date(GetDate())

	SELECT EmployeeID, FullName, DivisionID, DepartmentID, SectionID, HireDate, PositionID, TerminateDate, EmployeeTypeID, GroupID
	INTO #fn_vtblEmployeeList_Bydate
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) e
	WHERE EXISTS (
			SELECT 1
			FROM tblWSchedule ws
			WHERE ws.ScheduleDate BETWEEN @FromDate AND @ToDate AND ws.EmployeeID = e.EmployeeID
			) AND (ISNULL(@OptionView, '-1') = '-1' OR ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 1) = 1 AND IsForeign = 0) OR (ISNULL(@OptionView, '-1') = 2 AND ISNULL(IsForeign, 1) = 1))

	-- IF (@OptionView = 1)
	-- BEGIN
	-- 	DELETE f
	-- 	FROM #fn_vtblEmployeeList_Bydate f
	-- 	WHERE TerminateDate BETWEEN @FromDate AND @ToDate OR TerminateDate < @FromDate
	-- END
	-- IF (@OptionView = 2) --chỉ xem những người đã thôi việc
	-- BEGIN
	-- 	DELETE f
	-- 	FROM #fn_vtblEmployeeList_Bydate f
	-- 	WHERE NOT EXISTS (
	-- 			SELECT *
	-- 			FROM #fn_vtblEmployeeList_Bydate e
	-- 			WHERE e.EmployeeID = f.EmployeeID AND (TerminateDate BETWEEN @FromDate AND @ToDate OR TerminateDate < @FromDate)
	-- 			)
	-- END
	SELECT ROW_NUMBER() OVER (
			ORDER BY ORD, LeaveCode
			) AS ORD, LeaveCode, TACode
	INTO #LeaveCode
	FROM tblLeaveType
	WHERE IsVisible = 1

	SELECT ROW_NUMBER() OVER (
			ORDER BY e.EmployeeID
			) AS [No], e.EmployeeID, FullName, p.PositionName, d.DivisionName, dept.DepartmentName, s.SectionName, g.GroupName, HireDate, TerminateDate
	INTO #EmployeeList
	FROM #fn_vtblEmployeeList_Bydate e
	LEFT JOIN tblSection s ON s.SectionID = e.SectionID
	LEFT JOIN tblPosition p ON p.PositionID = e.PositionID
	LEFT JOIN tblDivision d ON d.DivisionID = e.DivisionID
	LEFT JOIN tblDepartment dept ON dept.DepartmentID = e.DepartmentID
	LEFT JOIN tblGroup g ON g.GroupID = e.GroupID

	SELECT *
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1 = 0

	ALTER TABLE #tblAttendanceSummary

	ALTER COLUMN PeriodID INT NULL

	-- Tạo danh sách các cột cần tính tổng động
	DECLARE @cols NVARCHAR(MAX) = '', @querySelector NVARCHAR(MAX) = ''

	SELECT @cols += N',SUM(' + QUOTENAME(COLUMN_NAME) + N') AS ' + QUOTENAME(COLUMN_NAME), @querySelector += N',' + QUOTENAME(COLUMN_NAME)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'tblAttendanceSummary' AND COLUMN_NAME NOT IN ('Month', 'Year', 'EmployeeID', 'PeriodID', 'FromDate', 'ToDate');

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
            SELECT EmployeeID FROM #EmployeeList
        )
        GROUP BY EmployeeID, Month, Year
    ';

	-- Thực thi truy vấn động
	EXEC sp_executesql @sql, N'@Month INT, @Year INT', @Month = @Month, @Year = @Year;

	SELECT EmployeeID, AttDate, AttStart, AttEnd
	INTO #tblHasTA
	FROM tblHasTA
	WHERE AttDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (
			SELECT te.EmployeeID
			FROM #EmployeeList te
			)

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind, ots.ColumnDisplayName OTType
	INTO #tblOTList
	FROM tblOTList ot
	INNER JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OTKind
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0 AND ot.EmployeeID IN (
			SELECT te.EmployeeID
			FROM #EmployeeList te
			)

	SELECT EmployeeID, SUM(HourApprove) NSHours
	INTO #NightShiftSum
	FROM tblNightShiftList
	WHERE DATE BETWEEN @FromDate AND @ToDate AND EmployeeID IN (
			SELECT te.EmployeeID
			FROM #EmployeeList te
			) AND Approval = 1
	GROUP BY EmployeeID

	SELECT EmployeeID, SUM(ApprovedHours) AS ApprovedHours, OTKind, OTType
	INTO #tblOTSummary
	FROM #tblOTList
	GROUP BY EmployeeID, OTKind, OTType

	SELECT e.EmployeeID, ROUND(SUM(IOMinutesDeduct) / 60, 1) AS IOHrs
	INTO #InLateOutEarly
	FROM tblInLateOutEarly e
	INNER JOIN #EmployeeList elb ON elb.EmployeeID = e.EmployeeID
	WHERE ApprovedDeduct = 1 AND IODate BETWEEN @FromDate AND @ToDate
	GROUP BY e.EmployeeID

	--Dữ liệu custom
	SELECT *
	INTO #tblCustomAttendanceData
	FROM tblCustomAttendanceData
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #EmployeeList
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
	INNER JOIN #EmployeeList e ON e.EmployeeID = h.EmployeeID
	LEFT JOIN #LeaveCode lc ON lc.LeaveCode = h.LeaveCode
	WHERE LeaveDate BETWEEN @FromDate AND @ToDate

	-- ko nằm trong danh sách thì ko tính lương nha
	CREATE TABLE #Tadata (EmployeeID VARCHAR(20), Attdate DATE, HireDate DATE, EmployeeStatusID INT, HolidayStatus INT, WorkingTime FLOAT(53), Std_Hour_PerDays FLOAT(53), Lvamount FLOAT(53), PaidAmount_Des FLOAT(53), UnpaidAmount_Des FLOAT(53), SalaryHistoryID INT, CutSI BIT, LeaveCode VARCHAR(5), EmployeeTypeID INT)

	EXEC sp_WorkingTimeProvider @Month = @Month, @Year = @Year, @fromdate = @FromDate, @todate = @ToDate, @loginId = @LoginID

	CREATE TABLE #SummaryData (
		--Hay dùng từ pivot lắm mà k bao giờ chịu pivot con ngta
		STT INT, EmployeeID VARCHAR(20), FullName NVARCHAR(MAX), Office NVARCHAR(MAX), DepartmentName NVARCHAR(MAX), HireDate DATE
		)

	INSERT INTO #SummaryData (STT, EmployeeID, FullName, HireDate, Office, DepartmentName)
	SELECT No, EmployeeID, FullName, HireDate, ISNULL(DivisionName, '') + ISNULL(DepartmentName, ''), DepartmentName
	FROM #EmployeeList

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
		--update workingTime
		SET @Query = ''

		SELECT @Query += N'UPDATE s SET [' + CAST(Number AS VARCHAR(3)) + 'Att] = w.WorkingTimeDisplay
                            FROM #SummaryData s
                            INNER JOIN #Tadata w ON s.EmployeeID = w.EmployeeID
                            WHERE CAST(DAY(w.Attdate) AS VARCHAR(5)) = ''' + CAST(Number AS VARCHAR(3)) + ''';'
		FROM dbo.fn_Numberlist(CAST(DAY(@FromDate) AS INT), CAST(DAY(@ToDate) AS INT))

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

	RETURN
		-- 	DECLARE @html NVARCHAR(MAX) = '', @css NVARCHAR(MAX) = '', @data NVARCHAR(MAX) = '', --cẩn thận k đủ chỗ chứa dữ liệu
		-- 		@Leave NVARCHAR(MAX) = '', @Date NVARCHAR(MAX) = '', @final NVARCHAR(MAX) = '', @javaScript NVARCHAR(MAX) = ''
		-- 	SET @css =
		-- 		N'
		-- 			<style>
		-- 	.table-container {
		-- 		width: auto;
		-- 		max-height: 97.8vh;
		-- 		font-family: ''Segoe UI'', Tahoma, Geneva, Verdana, sans-serif;
		-- 		padding: 0;
		-- 		min-height: 90vh;
		-- 		/* Make the container scrollable vertically so sticky headers work
		-- 		 Sticky positioning is relative to the nearest scrolling ancestor */
		-- 		overflow: auto;
		-- 		position: relative;
		-- 		background-color: white !important;
		-- 	}
		--     table {
		--         border-collapse: collapse;
		--         table-layout: fixed;
		--         font-size: 0.7rem;
		--         /* enforce specified column widths */
		--     }
		--     .th-td-css {
		--         border: 1px solid #eee;
		--         padding: 5px;
		--         text-align: center;
		--         white-space: nowrap;
		--         height: 30px;
		--         overflow: hidden;
		--         text-overflow: ellipsis;
		--     }
		-- 	thead {
		-- 		z-index: 2;
		-- 		/* position applied per-row below to support two stacked sticky header rows */
		-- 		border: 1px solid #FFF;
		-- 	}
		-- 	/* Make the first header row stick to the top */
		-- 	thead tr:first-child th {
		-- 		position: sticky;
		-- 		top: 0;
		-- 		z-index: 5;
		-- 	}
		-- 	/* Make the second header row stick right below the first row */
		-- 	thead tr:last-child th {
		-- 		position: sticky;
		-- 		top: 40px; /* adjust if header row height changes */
		-- 		z-index: 4;
		-- 	}
		--     .th-css {
		--         background-color: #004c39;
		--         color: #fff;
		--         font-size: 0.7rem;
		--         padding: 5px 10px;
		--     }
		--     .Sunday {
		--         background-color: #CFCFCF;
		--     }
		--     .section-name {
		--         padding-top: 5px;
		--         padding-bottom: 5px;
		--         padding-left: 170px;
		--         font-weight: bold;
		--         text-transform: uppercase;
		--         background-color: #DDDDDD;
		--     }
		--     .weekday {
		--         display: block;
		--         font-size: 0.6rem;
		--         color: #edffc8;
		--     }
		--     .day-num {
		--         display: block;
		--         font-weight: 600;
		--       border-bottom: 1px solid #d0d0d0;
		--         /* divider between day number and weekday */
		--     }
		--     td.sticky-col {
		--         position: sticky !important;
		--         z-index: 2;
		--         background-color: white;
		--         color: black;
		--     }
		--     th.sticky-col {
		--         position: sticky !important;
		--         z-index: 20;
		--     }
		--     /* Position first three sticky columns explicitly (adjust left values to match column widths) */
		--     th.sticky-col:nth-child(1),
		--     td.sticky-col:nth-child(1) {
		--         width: 35px;
		--         left: -1px;
		--     }
		-- 	th.sticky-col:nth-child(2),
		--     td.sticky-col:nth-child(2) {
		--     width: 60px;
		--         left: 32px;
		--     }
		--     th.sticky-col:nth-child(3),
		--     td.sticky-col:nth-child(3) {
		--         width: 120px;
		--         left: 118px;
		--         /* sum of widths of first and second columns */
		--     }
		--     /* Narrow day columns (T1..T31) */
		--     th:nth-child(n+10):nth-child(-n+40),
		--     td:nth-child(n+10):nth-child(-n+40) {
		--         width: 32px;
		--         min-width: 28px;
		--         max-width: 40px;
		--         white-space: nowrap;
		--         text-align: center;
		-- 		z-index: 1;
		--     }
		--     /* Work summary columns */
		--     th:nth-child(41),
		--     td:nth-child(41),
		--     th:nth-child(42),
		--     td:nth-child(42),
		--     th:nth-child(43),
		--     td:nth-child(43),
		--     th:nth-child(44),
		--     td:nth-child(44),
		--     th:nth-child(45),
		--     td:nth-child(45) {
		--         width: 90px;
		--         min-width: 80px;
		--     }
		--     .table-container tr:nth-child(even) {
		--         background-color: #F8F8FF;
		--     }
		--     /* Hiệu ứng khi được chọn */
		--     .table-container tr.selected {
		--         background-color: #004c39;
		--         color: #fff;
		--     }
		--     .table-container tr.selected td.sticky-col {
		--         background-color: #004c39;
		--         color: #fff;
		--     }
		-- </style>'
		-- 	-- Build dynamic two-row header: fixed columns (rowspan=2), day numbers (row1) and weekday abbreviations (row2)
		-- 	-- Create date list for the period
		-- 	IF OBJECT_ID('tempdb..#DateList') IS NOT NULL DROP TABLE #DateList;
		-- 	SELECT DAY([DATE]) AS JDate, DATEPART(WEEKDAY, [DATE]) AS DW, [DATE] AS FullDate
		-- 	INTO #DateList
		-- 	FROM dbo.fn_datelist(@FromDate, @ToDate)
		-- 	ORDER BY [DATE];
		-- 	DECLARE @dayHeader NVARCHAR(MAX) = N'', @weekdayHeader NVARCHAR(MAX) = N'';
		-- 	-- Build ordered day number header safely using FOR XML PATH
		-- 	SELECT @dayHeader = (
		-- 		SELECT N'<th class="th-td-css th-css">' + CAST(JDate AS NVARCHAR(3)) + N'</th>'
		-- 		FROM #DateList
		-- 		ORDER BY FullDate
		-- 		FOR XML PATH(''), TYPE
		-- 	).value('.', 'NVARCHAR(MAX)');
		-- 	-- Build ordered weekday header (3-letter EN abbreviations)
		-- 	SELECT @weekdayHeader = (
		-- 		SELECT N'<th class="th-td-css th-css"><span class="weekday">' +
		-- 			(CASE WHEN DW = 1 THEN N'Sun' WHEN DW = 2 THEN N'Mon' WHEN DW = 3 THEN N'Tue' WHEN DW = 4 THEN N'Wed' WHEN DW = 5 THEN N'Thu' WHEN DW = 6 THEN N'Fri' WHEN DW = 7 THEN N'Sat' END)
		-- 			+ N'</span></th>'
		-- 		FROM #DateList
		-- 		ORDER BY FullDate
		-- 		FOR XML PATH(''), TYPE
		-- 	).value('.', 'NVARCHAR(MAX)');
		-- 	DECLARE @queryTop NVARCHAR(MAX) = N'';
		-- 	DECLARE @queryBottom NVARCHAR(MAX) = N'';
		-- 	SET @queryTop = @queryTop + N'<th class="th-td-css th-css sticky-col" rowspan="2">STT</th>'
		-- 		+ N'<th class="th-td-css th-css sticky-col" rowspan="2">Mã nhân viên</th>'
		-- 		+ N'<th class="th-td-css th-css sticky-col" rowspan="2">Họ tên</th>'
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">HireDate</th>'
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">DepartmentName</th>'
		-- 		+ @dayHeader
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">WorkHours</th>'
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">Workdays</th>'
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">PaidLeaveHrs</th>'
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">PaidLeave</th>'
		-- 		+ N'<th class="th-td-css th-css" rowspan="2">UnpaidLeave</th>';
		-- 	SET @queryBottom = @weekdayHeader;
		-- 	SET @html = N'
		-- 			<div class="table-container">
		-- 				<table>
		-- 					<thead>
		-- 						<tr>' + @queryTop + N'</tr>
		-- 						<tr>' + @queryBottom + N'</tr>
		-- 					</thead>
		-- 					<tbody>
		-- 					';
		-- 	-- Build @data by concatenating rows from #SummaryData including dynamic day columns (T1..Tn)
		-- 	DECLARE @cols NVARCHAR(MAX) = N'';
		-- 	DECLARE @sql NVARCHAR(MAX) = N'';
		-- 		-- Check whether any T* columns exist in #SummaryData
		-- 		DECLARE @hasCols INT = 0;
		-- 		SELECT @hasCols = COUNT(*)
		-- 		FROM tempdb.INFORMATION_SCHEMA.COLUMNS
		-- 		WHERE TABLE_NAME LIKE '#SummaryData%'
		-- 			AND COLUMN_NAME LIKE 'T%';
		-- 		IF @hasCols > 0
		-- 	BEGIN
		-- 		DECLARE @colsExpr NVARCHAR(MAX) = N'';
		-- 		DECLARE @colname sysname;
		-- 		DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
		-- 			SELECT COLUMN_NAME
		-- 			FROM tempdb.INFORMATION_SCHEMA.COLUMNS
		-- 			WHERE TABLE_NAME LIKE '#SummaryData%'
		-- 			AND COLUMN_NAME LIKE 'T%'
		-- 			ORDER BY COLUMN_NAME;
		-- 		OPEN col_cursor;
		-- 		FETCH NEXT FROM col_cursor INTO @colname;
		-- 		WHILE @@FETCH_STATUS = 0
		-- 		BEGIN
		-- 			SET @colsExpr = @colsExpr + N' + N''<td class="th-td-css">'' + ISNULL(CAST(' + QUOTENAME(@colname) + N' AS VARCHAR(50)), N'''') + N''</td>'' ';
		-- 			FETCH NEXT FROM col_cursor INTO @colname;
		-- 		END
		-- 		CLOSE col_cursor;
		-- 		DEALLOCATE col_cursor;
		-- 		SET @sql = N'SELECT @out = (
		-- 			SELECT N''<tr>''
		-- 				+ N''<td class="th-td-css sticky-col">'' + CAST(STT AS NVARCHAR(10)) + N''</td>''
		-- 				+ N''<td class="th-td-css sticky-col">'' + ISNULL(EmployeeID, '''') + N''</td>''
		-- 				+ N''<td class="th-td-css sticky-col">'' + ISNULL(FullName, '''') + N''</td>''
		-- 				+ N''<td class="th-td-css">'' + ISNULL(CONVERT(VARCHAR(20), HireDate, 103), '''') + N''</td>''
		-- 				+ N''<td class="th-td-css">'' + ISNULL(DepartmentName, '''') + N''</td>''
		-- 				' + @colsExpr + N' + N''</tr>''
		-- 			FROM #SummaryData
		-- 			ORDER BY STT
		-- 			FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)'')';
		-- 		EXEC sp_executesql @sql, N'@out NVARCHAR(MAX) OUTPUT', @out=@data OUTPUT;
		-- 	END
		-- 	ELSE
		-- 	BEGIN
		-- 		SET @data = N''; -- no dynamic day columns found
		-- 	END
		-- 	SET @javaScript = N'<script>
		-- 						// Lấy tất cả các hàng trong tbody
		-- 						var rows = document.querySelectorAll("tbody tr");
		-- 						// Thêm sự kiện click cho mỗi hàng
		-- 						rows.forEach(function(row) {
		-- 							row.addEventListener("click", function() {
		-- 								// Loại bỏ hiệu ứng chọn từ tất cả các hàng
		-- 								rows.forEach(function(r) {
		-- 									r.classList.remove("selected");
		-- 								});
		-- 								// Thêm hiệu ứng chọn cho hàng được click và hàng kế tiếp (nếu có)
		-- 								this.classList.add("selected");
		-- 								var nextRow = this.nextElementSibling;
		-- 								if (nextRow) {
		-- 									nextRow.classList.add("selected");
		-- 								}
		-- 							});
		-- 						});
		-- 					</script>'
		-- 	SELECT @css + @html + ISNULL(@data, '') + N'</tbody>' + @javaScript AS Col1
END
GO

IF object_id('[dbo].[sp_getMonthlyPayrollCheckList]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_getMonthlyPayrollCheckList] as select 1')
GO

--exec sp_getMonthlyPayrollCheckList 12,2017
ALTER PROCEDURE [dbo].[sp_getMonthlyPayrollCheckList] (@LoginID INT = 3, @Month INT = 1, @Year INT = 2019, @SalaryTermID INT = 0, @NotSelect BIT = 0, @OptionView INT = 0)
AS
BEGIN
	DECLARE @ToDate DATE, @FromDate DATE

	SELECT @ToDate = ToDate, @FromDate = FromDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT EmployeeID, FullName, HireDate, TerminateDate, LastWorkingDate, EmployeeStatusID, DivisionID, DepartmentID, EmployeeTypeID
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
			) AND PeriodID = 0

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
			END ActualMonth
	INTO #tblMonthlyPayrollCheckList
	FROM #tmpEmployeeList te
	INNER JOIN #AttendanceSummary a ON te.EmployeeID = a.EmployeeID
	WHERE te.EmployeeID NOT IN (
			SELECT EmployeeID
			FROM tblMonthlyPayrollCheckList m
			WHERE m.Month = @Month AND m.Year = @Year
			)

	-- nhan vien da nghi viecj hoan nghi thai san nhung co khoa tra bo sung
	INSERT INTO #tblMonthlyPayrollCheckList (EmployeeID, FullName, HireDate, Month, Year, TerminateDate, isLowTaxableInCome, EmployeeStatusID, DaysOfYear)
	SELECT te.EmployeeID, te.FullName, te.HireDate, @Month Month, @Year Year, TerminateDate, cast(0 AS BIT) AS isLowTaxableInCome, te.EmployeeStatusID, CASE 
			WHEN (@Year % 400 = 0) OR (@Year % 4 = 0 AND @Year % 100 <> 0)
				THEN 366
			ELSE 365
			END
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
			)

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

	-- bỏ vào tạm làm cho nhanh
	SELECT *
	INTO #tblMonthlyPayrollCheckList1
	FROM tblMonthlyPayrollCheckList
	WHERE month = @Month AND YEAR = @Year

	IF @SalaryTermID = 0
	BEGIN
		IF isnull(@NotSelect, 0) = 0
			SELECT m.*, e.FullName, e.DivisionID, e.DepartmentID
				--,sal.TotalPaidDay_C
				--,sal.AttHours_C
				, e.HireDate, e.TerminateDate, e.EmployeeStatusID
			FROM #tblMonthlyPayrollCheckList1 m
			INNER JOIN #tmpEmployeeList e ON m.EmployeeID = e.EmployeeID
			WHERE m.Month = @month AND m.Year = @year
			ORDER BY m.EmployeeID
	END
END
	--exec sp_getMonthlyPayrollCheckList 3, 8,2025
GO

IF object_id('[dbo].[sp_processSummaryAttendance]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_processSummaryAttendance] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_processSummaryAttendance] (@LoginID INT, @Year INT, @Month INT, @ViewType INT = 0, @Payroll BIT = 0)
AS
BEGIN
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

	--Tạo bảng tạm để lưu trữ dữ liệu
	SELECT *, CAST(NULL AS DATETIME) TerminateDate, CAST(NULL AS DATETIME) HireDate, CAST(NULL AS FLOAT) PercentProbation, CAST(NULL AS DATETIME) ProbationEndDate, CAST(NULL AS INT) isForeign
	INTO #tblAttendanceSummary
	FROM tblAttendanceSummary
	WHERE 1 = 0

	SELECT te.EmployeeID, te.DivisionID, te.DepartmentID, te.SectionID, te.GroupID, te.EmployeeTypeID, te.PositionID, te.EmployeeStatusID, te.Sex, CASE 
			WHEN te.HireDate > @fromDate
				THEN cast(1 AS BIT)
			ELSE 0
			END AS NewStaff, CAST(0 AS BIT) AS TerminatedStaff, HireDate, CAST(NULL AS DATETIME) TerminateDate, ProbationEndDate, te.LastWorkingDate, CAST(0 AS BIT) hasTwoPeriods, et.isLocalStaff, te.isForeign
	INTO #EmployeeList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID) te
	INNER JOIN tblDivision div ON te.DivisionID = div.DivisionID
	LEFT JOIN tblEmployeeType et ON te.EmployeeTypeID = et.EmployeeTypeID

	-- WHERE NOT EXISTS (
	-- 		SELECT 1
	-- 		FROM tblSal_Lock l
	-- 		WHERE te.EmployeeID = l.EmployeeID AND l.Month = @Month AND l.Year = @Year
	-- 		)
	IF EXISTS (
			SELECT a.EmployeeID
			FROM tblAtt_LockMonth a
			INNER JOIN #EmployeeList e ON a.EmployeeID = e.EmployeeID
			WHERE a.Month = @Month AND a.Year = @Year
			)
	BEGIN
		DELETE
		FROM #EmployeeList
		WHERE EmployeeID IN (
				SELECT DISTINCT a.EmployeeID
				FROM tblAtt_LockMonth a
				INNER JOIN #EmployeeList e ON a.EmployeeID = e.EmployeeID
				WHERE a.Month = @Month AND a.Year = @Year
				)
	END

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
	INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, HireDate, TerminateDate, ProbationEndDate, PeriodID, SalaryHistoryID, FromDate, ToDate, isForeign)
	SELECT @Year, @Month, sh.EmployeeID, HireDate, TerminateDate, ProbationEndDate, 0, sh.SalaryHistoryID, CASE 
			WHEN sh.DATE < @FromDate
				THEN @FromDate
			ELSE sh.DATE
			END, @ToDate, te.isForeign
	FROM #EmployeeList te
	INNER JOIN #CurrentSalary s ON te.EmployeeID = s.EmployeeID
	INNER JOIN tblSalaryHistory sh ON s.SalaryHistoryID = sh.SalaryHistoryID
	WHERE sh.DATE >= te.HireDate

	INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, HireDate, TerminateDate, ProbationEndDate, PeriodID, SalaryHistoryID, FromDate, ToDate, isForeign)
	SELECT @Year, @Month, sh.EmployeeID, HireDate, TerminateDate, ProbationEndDate, 1, sh.SalaryHistoryID, CASE 
			WHEN sh.DATE < @FromDate
				THEN @FromDate
			ELSE sh.DATE
			END, @ToDate, te.isForeign
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

	UPDATE #tblAttendanceSummary
	SET PeriodID = 0
	WHERE ToDate < @ToDate

	UPDATE #tblAttendanceSummary
	SET PeriodID = 0
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #tblAttendanceSummary s
			GROUP BY EmployeeID
			HAVING COUNT(1) = 1
			)

	--Thử việc
	IF EXISTS (
			SELECT 1
			FROM #tblAttendanceSummary sh
			WHERE ProbationEndDate BETWEEN @FromDate AND @ToDate AND HireDate <> ProbationEndDate
			)
	BEGIN
		UPDATE #tblAttendanceSummary
		SET PercentProbation = ISNULL(CASE 
					WHEN ISNULL(tsh.PercentProbation, 0) = 0
						THEN NULL
					ELSE tsh.PercentProbation
					END, et.PercentProbation)
		FROM #tblAttendanceSummary sh
		LEFT JOIN tblSalaryHistory tsh ON sh.SalaryHistoryID = tsh.SalaryHistoryID
		LEFT JOIN #EmployeeList te ON sh.EmployeeID = te.EmployeeID
		LEFT JOIN tblEmployeeType et ON et.EmployeeTypeID = te.EmployeeTypeID
		WHERE sh.ProbationEndDate BETWEEN @FromDate AND @ToDate AND sh.HireDate <> sh.ProbationEndDate

		--het thu viec trong thang nay
		UPDATE #tblAttendanceSummary
		SET FromDate = DATEADD(day, 1, ProbationEndDate), PeriodID = 1
		FROM #tblAttendanceSummary sh
		WHERE ISNULL(PercentProbation, 0) > 0 AND ProbationEndDate BETWEEN @FromDate AND @ToDate AND sh.HireDate <> sh.ProbationEndDate AND FromDate <= ProbationEndDate AND ToDate >= ProbationEndDate

		DECLARE @MaxSalaryHistoryId BIGINT

		SET @MaxSalaryHistoryId = (
				SELECT MAX(SalaryHistoryID)
				FROM #tblAttendanceSummary
				) + 7121997

		INSERT INTO #tblAttendanceSummary (Year, Month, EmployeeID, HireDate, TerminateDate, PeriodID, SalaryHistoryID, FromDate, ToDate)
		SELECT @Year, @Month, sh.EmployeeID, sh.HireDate, sh.TerminateDate, 0, sh.SalaryHistoryID, CASE 
				WHEN @FromDate < HireDate
					THEN HireDate
				ELSE @FromDate
				END, ProbationEndDate
		FROM #tblAttendanceSummary sh
		WHERE sh.ProbationEndDate BETWEEN @FromDate AND @ToDate AND sh.HireDate <> sh.ProbationEndDate
	END

	SELECT ot.EmployeeID, ot.OTDate, ot.ApprovedHours, ot.OTKind
	INTO #tblOTList
	FROM tblOTList ot
	WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.Approved = 1 AND ApprovedHours <> 0 AND ot.EmployeeID IN (
			SELECT te.EmployeeID
			FROM #EmployeeList te
			)

	IF (@Payroll = 0)
	BEGIN
		-- ko nằm trong danh sách thì ko tính lương nha
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
	SET WorkingHrs_Total = ISNULL(ta.AttHrs, 0), WorkingDays_Total = ISNULL(ta.AttDays, 0) + ISNULL(ta.PaidLeaveDays, 0), PaidLeaveDays_Total = ta.PaidLeaveDays, Std_Hour_PerDays = ta.Std_Hour_PerDays, PaidLeaveHrs_Total = ta.PaidLeaveHrs, UnpaidLeaveDays = ta.UnpaidLeaveDays, UnpaidLeaveHrs = ta.UnpaidLeaveHrs
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

	--Người nước ngoài mặc định full công - trường hợp vào làm/nghỉ làm giữa tháng
	UPDATE att
	SET RegularWorkdays = ISNULL(RegularWorkdays, 0), WorkingHrs_Total = (RegularWorkdays * 8)
	FROM #tblAttendanceSummary att
	WHERE ISNULL(att.IsForeign, 0) = 1 AND (HireDate <= @FromDate AND (TerminateDate IS NULL OR TerminateDate >= @ToDate))

	-- UPDATE #tblAttendanceSummary
	-- SET WorkingHrs_Total = WorkingHrs_Total + ((RegularWorkdays * Std_Hour_PerDays) - (STD_WorkingDays * Std_Hour_PerDays))
	-- FROM #tblAttendanceSummary att
	-- WHERE STD_WorkingDays <> RegularWorkdays AND RegularWorkdays * ISNULL(Std_Hour_PerDays, 0) <> ISNULL(WorkingHrs_Total, 0) + ISNULL(PaidLeaveHrs_Total, 0) + ISNULL(UnpaidLeaveHrs, 0)
	-- Dynamic set-based update: pivot LvAmount from #tblLvHistory per LeaveCode and update #tblAttendanceSummary
	-- Aggregates by EmployeeID and SalaryHistoryID to match multiple salary periods per employee
	DECLARE @cols NVARCHAR(MAX), @assign NVARCHAR(MAX), @sql NVARCHAR(MAX)

	-- build column list and assignments from visible LeaveCode
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

	IF @cols IS NOT NULL AND LEN(@cols) > 0
	BEGIN
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
	END

	DELETE t
	FROM tblAttendanceSummary t
	WHERE EXISTS (
			SELECT 1
			FROM #tblAttendanceSummary s
			WHERE t.EmployeeID = s.EmployeeID AND t.Year = s.Year AND t.Month = s.Month
			)

	-- Insert processed summary rows from temp table into permanent table
	INSERT INTO tblAttendanceSummary (Year, Month, EmployeeID, PeriodID, SalaryHistoryID, FromDate, ToDate, WorkingHrs_Total, WorkingDays_Total, PaidLeaveDays_Total, UnpaidLeaveDays, PaidLeaveHrs_Total, UnpaidLeaveHrs, STD_WorkingDays, Std_Hour_PerDays, RegularWorkdays)
	SELECT Year, Month, EmployeeID, ISNULL(PeriodID, 0), SalaryHistoryID, FromDate, ToDate, WorkingHrs_Total, WorkingDays_Total, PaidLeaveDays_Total, UnpaidLeaveDays, PaidLeaveHrs_Total, UnpaidLeaveHrs, STD_WorkingDays, Std_Hour_PerDays, RegularWorkdays
	FROM #tblAttendanceSummary;

	SET @sql = '
    UPDATE s SET ' + @assign + N'
		FROM tblAttendanceSummary s
		INNER JOIN #tblAttendanceSummary p ON s.EmployeeID = p.EmployeeID AND s.Year = p.Year AND s.Month = p.Month
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

IF object_id('[dbo].[sp_SalaryHistory_List]') IS NULL
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
	WHERE IsNET = 1 AND ISNULL(InsSalary, 0) = 0

	UPDATE tblSalaryHistory
	SET Salary = NETSalary
	WHERE IsNET = 1 AND ISNULL(Salary, 0) = 0

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

IF object_id('[dbo].[TA_Process_Main]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[TA_Process_Main] as select 1')
GO

ALTER PROCEDURE [dbo].[TA_Process_Main] (@LoginID INT = NULL, @FromDate DATETIME = NULL, @ToDate DATETIME = NULL, @EmployeeID VARCHAR(20) = '-1')
AS
SET NOCOUNT ON;

--SET ANSI_WARNINGS OFF
IF @LoginID IS NULL
	SET @LoginID = 6900 --de phong truong hop LoginID null

DECLARE @BinVar VARBINARY(128);

SET @BinVar = CAST(CHECKSUM(NEWID()) AS VARBINARY(128))

IF dbo.CheckIsRunningByContextInfo(@BinVar) = 1 --login nay dang chay roi
	RETURN

SET CONTEXT_INFO @BinVar --set context de vao trong trigger lay ra

IF (OBJECT_ID('TA_ProcessMain_1Description') IS NULL)
BEGIN
	EXEC (
			'CREATE PROCEDURE TA_ProcessMain_1Description
as
begin
 -- Viet Ghi chu quan trong o day
 SET NOCOUNT ON;
end'
			)
END

DECLARE @IsAuditAccount BIT

SET @IsAuditAccount = dbo.fn_CheckAuditAccount(@LoginID)

DECLARE @StopUpdate BIT = 0, @p_ShiftID INT, @p_AttStart DATETIME, @p_AttEnd DATETIME, @MaternityStatusID TINYINT

BEGIN
	DECLARE @OT_ROUND_UNIT INT

	SET @OT_ROUND_UNIT = (
			SELECT cast(value AS INT)
			FROM tblParameter
			WHERE code = 'OT_ROUND_UNIT'
			)
	SET @OT_ROUND_UNIT = isnull(@OT_ROUND_UNIT, 1)

	--Khoa Luong hay chua
	DECLARE @Month INT, @Year INT

	--  get Fromdate, ToDate from Pendding data
	IF @FromDate IS NULL OR @ToDate IS NULL
	BEGIN
		SELECT @FromDate = MIN(DATE), @ToDate = MAX(DATE)
		FROM dbo.tblPendingTaProcessMain

		IF DATEDIFF(DAY, @FromDate, @ToDate) > 45
		BEGIN
			SET @ToDate = NULL
		END
	END

	IF @FromDate IS NULL OR @ToDate IS NULL
	BEGIN
		SELECT @FromDate = ISNULL(@FromDate, Fromdate), @ToDate = isnull(@ToDate, Todate)
		FROM dbo.fn_Get_SalaryPeriod_ByDate(getdate())
	END

	-- neu @loginID is null thì xử lý toàn bộ nhan vien trong pending
	IF @LoginID = 6900
	BEGIN
		SET @LoginID = 6900

		DELETE dbo.tmpEmployeeTree
		WHERE LoginID = @LoginID

		INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
		SELECT DISTINCT EmployeeID, @LoginID
		FROM tblPendingTaProcessMain
		WHERE DATE BETWEEN @FromDate AND @ToDate
	END

	SET @FromDate = DBO.Truncate_Date(@FromDate)
	SET @ToDate = DBO.Truncate_Date(@ToDate)

	IF (OBJECT_ID('TA_ProcessMain_PreConfigTAData') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE TA_ProcessMain_PreConfigTAData
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
 SET NOCOUNT ON;
end'
				)
	END

	SET @StopUpdate = 0

	EXEC TA_ProcessMain_PreConfigTAData @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

	--VŨ: chạy proc này để xác định các mốc đăng ký tăng ca chính xác (đky cả ngày chủ nhật sẽ đưa về các dòng chuẩn nhất)
	EXEC TA_Process_Main_ProcessBefore @LoginID = @LoginID, @FromDate = @FromDate, @ToDate = @ToDate, @EmployeeID = @EmployeeID

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblEmployeeType' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblEmployeeType ADD LATE_PERMIT FLOAT
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblDivision' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblDivision ADD LATE_PERMIT FLOAT
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblDepartment' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblDepartment ADD LATE_PERMIT FLOAT
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblSection' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblSection ADD LATE_PERMIT FLOAT
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblGroup' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblGroup ADD LATE_PERMIT FLOAT
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblPosition' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblPosition ADD LATE_PERMIT FLOAT
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = 'tblEmployee' AND COLUMN_NAME = 'LATE_PERMIT'
				)
			)
	BEGIN
		ALTER TABLE tblEmployee ADD LATE_PERMIT FLOAT
	END

	--------------------------------Lay dk cua Employee--------------------------------------------------------------
	/*CREATE TABLE #tmpEmployee(EmployeeID  varchar(20),FullName nvarchar(500),EmployeeTypeID int, PositionID int primary key(EmployeeID),DivisionID int, DepartmentID int,SectionID int,GroupID int )*/
	SELECT EmployeeID, EmployeeTypeID, PositionID, DivisionID, DepartmentID, SectionID, GroupID, HireDate, LastWorkingDate, CAST(NULL AS INT) LATE_PERMIT
	INTO #tmpEmployee
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@ToDate, @EmployeeID, @LoginID)

	DELETE #tmpEmployee
	WHERE HireDate > @ToDate OR LastWorkingDate < @FromDate

	--update nguoc len
	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblEmployeeType AS n ON n.EmployeeTypeID = te.EmployeeTypeID
	WHERE n.LATE_PERMIT IS NOT NULL

	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblDivision AS n ON n.DivisionID = te.DivisionID
	WHERE n.LATE_PERMIT IS NOT NULL

	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblDepartment AS n ON n.DepartmentID = te.DepartmentID
	WHERE n.LATE_PERMIT IS NOT NULL

	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblSection AS n ON n.SectionID = te.SectionID
	WHERE n.LATE_PERMIT IS NOT NULL

	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblGroup AS n ON n.GroupID = te.GroupID
	WHERE n.LATE_PERMIT IS NOT NULL

	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblPosition AS n ON n.PositionID = te.PositionID
	WHERE n.LATE_PERMIT IS NOT NULL

	UPDATE te
	SET te.LATE_PERMIT = n.LATE_PERMIT
	FROM #tmpEmployee AS te
	INNER JOIN tblEmployee AS n ON n.EmployeeID = te.EmployeeID
	WHERE n.LATE_PERMIT IS NOT NULL

	SELECT /*top 0*/ *
	INTO #tblAtt_Lock
	FROM tblAtt_Lock l
	WHERE EXISTS (
			SELECT 1
			FROM #tmpEmployee te
			WHERE l.EmployeeID = te.EmployeeID
			) AND DATE BETWEEN @FromDate AND @ToDate

	INSERT INTO tblRunningTaProcessMain (EmployeeID, DATE, LoginID)
	SELECT ta.EmployeeID, ta.DATE, @LoginID
	FROM tblPendingTaProcessMain ta
	--left join tblRunningTaProcessMain r on r.LoginID = @LoginID and ta.EmployeeID = r.EmployeeID and ta.Date = r.Date
	WHERE --r.EmployeeID is null and
		ta.DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tmpEmployee e
			WHERE e.EmployeeID = ta.EmployeeID AND ta.DATE BETWEEN e.HireDate AND e.LastWorkingDate
			) AND NOT EXISTS (
			SELECT 1
			FROM #tblAtt_Lock al
			WHERE ta.EmployeeID = al.EmployeeID AND ta.DATE = al.DATE
			);

	WITH cte
	AS (
		SELECT EmployeeID, DATE, ROW_NUMBER() OVER (
				PARTITION BY EmployeeID, DATE ORDER BY EmployeeID
				) rn
		FROM tblRunningTaProcessMain w
		WHERE LoginID = @LoginID
		)
	DELETE
	FROM cte
	WHERE rn > 1;

	DELETE tblPendingTaProcessMain
	FROM tblPendingTaProcessMain ta
	WHERE DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tmpEmployee e
			WHERE e.EmployeeID = ta.EmployeeID
			)

	SELECT EmployeeID, DATE, cast(0 AS INT) AS EmployeeStatusID, cast(0 AS INT) AS NotTrackTA, cast(NULL AS INT) EmployeeTypeID
	INTO #tblPendingTaProcessMain
	FROM tblRunningTaProcessMain ta
	WHERE LoginID = @LoginID AND DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tmpEmployee e
			WHERE e.EmployeeID = ta.EmployeeID AND ta.DATE BETWEEN e.HireDate AND e.LastWorkingDate
			) AND NOT EXISTS (
			SELECT 1
			FROM #tblAtt_Lock al
			WHERE ta.EmployeeID = al.EmployeeID AND ta.DATE = al.DATE
			)
	GROUP BY EmployeeID, DATE

	IF ROWCOUNT_BIG() <= 0
		GOTO ClearPendingOvertime

	CREATE NONCLUSTERED INDEX ix_tmpEmployee_tapro ON #tmpEmployee (EmployeeID)

	SELECT DISTINCT /*top 0*/ EmployeeID, [Date] AS LockDate
	INTO #DateLocked
	FROM tblAtt_Lock al
	WHERE al.DATE BETWEEN @FromDate AND @ToDate AND al.EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployee
			)

	DELETE #tblPendingTaProcessMain
	FROM #tblPendingTaProcessMain t
	INNER JOIN #DateLocked l ON t.EmployeeID = l.EmployeeID AND t.[Date] = l.LockDate

	DELETE #tmpEmployee
	WHERE EmployeeID NOT IN (
			SELECT DISTINCT EmployeeID
			FROM #tblPendingTaProcessMain
			)

	CREATE CLUSTERED INDEX indextblPendingTaProcessMain ON #tblPendingTaProcessMain (EmployeeID, [Date])

	--exec ('Disable trigger ALL on tblWSchedule')
	--exec ('Disable trigger ALL on tblHasTA')
	--exec ('Disable trigger ALL on tblLvhistory')
	------------------------------------------------------------------------------------------------------------------
	CREATE TABLE #tmpHasTA (
		EmployeeID NVARCHAR(20), AttDate DATETIME, Period INT, ShiftID INT, DayType INT, LeaveStatus INT, LvAmount FLOAT, AttStart DATETIME, -- Gio bat dau lam viec
		AttEnd DATETIME, -- Gio ket thuc lam viec
		WorkingTime FLOAT, WorkStart DATETIME, -- Gio bat dau cua ca
		WorkEnd DATETIME, -- Gio ket thuc cua ca,
		BreakStart DATETIME, -- Gio bat dau nghi giua ca(ket thuc lam nua ngay dau)
		BreakEnd DATETIME, -- Gio ket thu nghi giua ca(bat dau lam viec nua ngay cuoi)
		MiAttStart INT, -- Doi gio bat dau lam viec ra phut so voi AttDate
		MiAttEnd INT, -- Doi gio ket thuc lam viec ra phut so voi AttDate
		MiWorkStart INT, -- Doi gio bat dau cua ca ra phut so voi AttDate
		MiWorkEnd INT, -- Doi gio ket thuc cua ca ra phut so voi AttDate
		MiBreakStart INT, MiBreakEnd INT, SiAttStart FLOAT, -- Doi gio bat dau lam viec ra giay so voi AttDate de tinh In late, out early
		SiAttEnd FLOAT, -- Doi gio ket thuc lam viec ra giay so voi AttDate de tinh In late, out early
		SiWorkStart FLOAT, -- Doi gio bat dau cua ca ra giay so voi AttDate de tinh In late, out early
		SiWorkEnd FLOAT, -- Doi gio ket thuc cua ca ra giay so voi AttDate de tinh In late, out early
		IsMaternity BIT, DateStatus INT, Holidaystatus INT
		)

	-- Maternity Process - Xu ly nhan vien sau ho san
	DECLARE @MATERNITY_MUNITE INT

	SET @MATERNITY_MUNITE = (
			SELECT cast([value] AS INT)
			FROM tblParameter
			WHERE code = 'MATERNITY_MUNITE'
			)
	SET @MATERNITY_MUNITE = isnull(@MATERNITY_MUNITE, 60)

	CREATE TABLE #Maternity (EmployeeID VARCHAR(20), BornDate DATETIME, EndDate DATETIME, MinusMin INT)

	INSERT INTO #Maternity (EmployeeID, BornDate, EndDate, MinusMin)
	SELECT s.EmployeeID, s.ChangedDate, s.StatusEndDate, @MATERNITY_MUNITE
	FROM fn_EmployeeStatusRange(0) s
	WHERE EmployeeStatusID IN (10, 11) AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployee
			)

	DELETE #Maternity
	WHERE EndDate < @FromDate OR BornDate > @ToDate

	--không thiết lập ngày EndDate hoặc không tự xác định được thì mặc định cứ tính hết luôn
	UPDATE #Maternity
	SET EndDate = @ToDate
	WHERE EndDate IS NULL

	------------------------------------------Do du lieu vao bang #tmpHasTA------------------------------------------------
	SELECT ss.ShiftID, ShiftCode, WeekDays, (isnull(SwipeOptionID, 3)) SwipeOptionID, (datepart(hour, WorkStart) * 60 + datepart(minute, WorkStart)) MiWorkStart, (datepart(hour, WorkEnd) * 60 + datepart(minute, WorkEnd)) MiWorkEnd, (datepart(hour, BreakStart) * 60 + datepart(minute, BreakStart)) MiBreakStart, (datepart(hour, BreakEnd) * 60 + datepart(minute, BreakEnd)) MiBreakEnd, cast(0.0 AS FLOAT) AS ShiftHours, (datepart(hour, OTBeforeStart) * 60 + datepart(minute, OTBeforeStart)) MiOTBeforeStart, (datepart(hour, OTBeforeEnd) * 60 + datepart(minute, OTBeforeEnd)) MiOTBeforeEnd, (datepart(hour, OTAfterStart) * 60 + datepart(minute, OTAfterStart)) MiOTAfterStart, (datepart(hour, OTAfterEnd) * 60 + datepart(minute, OTAfterEnd)) MiOTAfterEnd, cast(0 AS BIT) AS isNightShift, isnull(isOfficalShift, 0) isOfficalShift, (WorkStart) AS WorkStart, (WorkEnd) AS WorkEnd, BreakStart, BreakEnd, OTBeforeStart, OTBeforeEnd, OTAfterStart, OTAfterEnd, (Std_Hour_PerDays
			) * 60 AS STDWorkingTime_SS, cast(NULL AS INT) MiDeductBearkTime
	INTO #ShiftInfo
	FROM tblShiftSetting ss

	UPDATE #ShiftInfo
	SET MiBreakStart = 1440 + MiBreakStart
	WHERE MiBreakStart < MiWorkStart AND MiWorkStart > MiWorkEnd

	UPDATE #ShiftInfo
	SET MiBreakEnd = 1440 + MiBreakEnd
	WHERE MiBreakEnd < MiWorkStart AND MiWorkStart > MiWorkEnd

	UPDATE #ShiftInfo
	SET MiWorkEnd = 1440 + MiWorkEnd
	WHERE MiWorkEnd < MiWorkStart

	UPDATE #ShiftInfo
	SET MiOTBeforeStart = MiWorkStart
	WHERE MiOTBeforeStart IS NULL

	UPDATE #ShiftInfo
	SET MiOTBeforeEnd = MiWorkStart + 960
	WHERE MiOTBeforeEnd IS NULL

	UPDATE #ShiftInfo
	SET MiOTBeforeEnd = 1440 + MiOTBeforeEnd
	WHERE MiOTBeforeEnd < MiOTBeforeStart

	UPDATE #ShiftInfo
	SET MiOTAfterStart = MiWorkEnd
	WHERE MiOTAfterStart IS NULL

	UPDATE #ShiftInfo
	SET MiOTAfterStart = 1440 + MiOTAfterStart
	WHERE MiOTAfterStart < MiWorkEnd

	UPDATE #ShiftInfo
	SET MiOTAfterEnd = MiWorkEnd + 960
	WHERE MiOTAfterEnd IS NULL

	UPDATE #ShiftInfo
	SET MiOTAfterEnd = 1440 + MiOTAfterEnd
	WHERE MiOTAfterEnd < MiOTAfterStart

	UPDATE #ShiftInfo
	SET MiBreakStart = MiWorkEnd
	WHERE MiBreakStart IS NULL OR MiBreakStart > MiWorkEnd OR MiBreakStart < MiWorkStart

	UPDATE #ShiftInfo
	SET MiBreakEnd = MiWorkEnd
	WHERE MiBreakEnd IS NULL OR MiBreakEnd > MiWorkEnd OR MiBreakEnd < MiWorkStart

	UPDATE #ShiftInfo
	SET MiBreakEnd = 1440 + MiBreakEnd
	WHERE MiBreakEnd < MiBreakStart

	UPDATE #ShiftInfo
	SET ShiftHours = (MiWorkEnd - MiWorkStart - (MiBreakEnd - MiBreakStart)) / 60.0

	UPDATE #ShiftInfo
	SET STDWorkingTime_SS = (MiWorkEnd - MiWorkStart - (MiBreakEnd - MiBreakStart))
	WHERE isnull(STDWorkingTime_SS, 0) <= 120

	UPDATE #ShiftInfo
	SET isNightShift = CASE 
			WHEN MiWorkEnd > 1440
				THEN 1
			ELSE 0
			END

	----vũ: Cập nhật lại ngày đúng nếu làm qua ngày
	UPDATE h
	SET AttEnd = CAST(DATEADD(DAY, 1, CAST(AttDate AS DATE)) AS DATETIME) + CAST(AttEnd AS TIME)
	FROM tblHasTA h
	INNER JOIN #tblPendingTaProcessMain p ON p.EmployeeID = h.EmployeeID AND p.DATE = h.AttDate
	WHERE CAST(AttEnd AS TIME) < CAST(AttStart AS TIME)

	SELECT ta.EmployeeID, ta.AttDate, ta.AttStart, ta.AttEnd, ta.WorkingTime, ta.[Period], TAStatus, CAST(NULL AS INT) minAttStart, CAST(NULL AS INT) maxAttEnd
	INTO #tblHasTA_Org
	FROM tblHasTA ta
	INNER JOIN #tblPendingTaProcessMain p ON ta.EmployeeID = p.EmployeeID AND ta.AttDate = p.[Date]
	WHERE @IsAuditAccount = 0

	UPDATE #tblHasTA_Org
	SET minAttStart = DATEPART(hh, AttStart) + DATEPART(mi, AttStart), maxAttEnd = DATEPART(hh, AttEnd) + DATEPART(mi, AttEnd)

	SELECT lv.*
	INTO #tblLvHistoryP
	FROM tblLvHistory lv
	INNER JOIN #tblPendingTaProcessMain p ON lv.EmployeeID = p.EmployeeID AND lv.LeaveDate = p.[Date]

	SELECT w.EmployeeID, w.ScheduleDate, w.ShiftID, w.HolidayStatus, w.DateStatus, ss.ShiftCode
	INTO #tblWSchedule
	FROM tblWSchedule w
	INNER JOIN tblShiftSetting ss ON ss.ShiftID = w.ShiftID
	INNER JOIN #tblPendingTaProcessMain p ON w.EmployeeID = p.EmployeeID AND w.ScheduleDate = p.[Date]

	INSERT INTO #tmpHasTA (EmployeeID, AttDate, Period, ShiftID, DayType, AttStart, AttEnd, WorkStart, WorkEnd, BreakStart, BreakEnd, LeaveStatus, LvAmount, WorkingTime, IsMaternity, MiAttStart, MiAttEnd, MiWorkStart, MiWorkEnd, MiBreakStart, MiBreakEnd, DateStatus, Holidaystatus)
	SELECT H.EmployeeID, H.AttDate, H.Period, W.ShiftID, W.HolidayStatus, H.AttStart, H.AttEnd, S.WorkStart, S.WorkEnd, S.BreakStart, S.BreakEnd, CASE 
			WHEN h.Period <> 3
				THEN ISNULL(tlh.LeaveStatus, 0)
			ELSE 0
			END, tlh.LvAmount, h.WorkingTime, CASE 
			WHEN m.EmployeeID IS NOT NULL
				THEN 1
			ELSE 0
			END, DATEDIFF(mi, h.AttDate, AttStart) AS MiAttStart, DATEDIFF(mi, h.AttDate, AttEnd) AS MiAttEnd, S.MiWorkStart, S.MiWorkEnd, S.MiBreakStart, S.MiBreakEnd, w.DateStatus, w.HolidayStatus
	FROM #tblHasTA_Org H
	INNER JOIN #tblWSchedule W ON H.EmployeeID = W.EmployeeID AND H.AttDate = W.ScheduleDate
	LEFT JOIN #ShiftInfo S ON W.ShiftID = S.ShiftID
	LEFT JOIN #Maternity AS M ON H.EmployeeID = M.EmployeeID AND H.AttDate BETWEEN M.BornDate AND M.EndDate
	CROSS APPLY (
		SELECT MAX(LeaveStatus) AS LeaveStatus, sum(LvAmount) AS LvAmount
		FROM #tblLvHistoryP tlh
		WHERE h.EmployeeID = tlh.EmployeeID AND h.AttDate = tlh.LeaveDate AND tlh.LeaveCode IN (
				SELECT LeaveCode
				FROM tblLeavetype lt
				WHERE lt.LeaveCategory = 1
				)
		) tlh
	WHERE (H.AttStart IS NOT NULL OR H.AttEnd IS NOT NULL) -- Chi xu ly trong TH co day du gio vao va gio ra

	--TRIPOD; tất cả ngày thứ 7 đều là ngày thường, xem như OT 100%
	SELECT *
	INTO #OTSaturday
	FROM #tblWSchedule
	WHERE DATENAME(dw, ScheduleDate) = 'Saturday' AND HolidayStatus = 1

	UPDATE #tmpHasTA
	SET DayType = 0
	WHERE DATENAME(dw, AttDate) = 'Saturday' AND DayType = 1

	UPDATE #tmpHasTA
	SET WorkStart = DATEADD(mi, MiWorkStart, AttDate), WorkEnd = DATEADD(mi, MiWorkEnd, AttDate), BreakStart = DATEADD(mi, MiBreakStart, AttDate), BreakEnd = DATEADD(mi, MiBreakEnd, AttDate)

	SELECT *
	INTO #tblHoliday
	FROM tblHoliday
	WHERE LeaveDate BETWEEN @FromDate AND @ToDate

	UPDATE #tmpHasTA
	SET DayType = h.HolidayStatusOT
	FROM #tmpHasTA ta
	INNER JOIN #tmpEmployee e ON ta.EmployeeID = e.EmployeeID
	INNER JOIN #tblHoliday h ON h.LeaveDate = ta.AttDate AND (e.EmployeeTypeID = h.EmployeeTypeID OR h.EmployeeTypeID = - 1)
	WHERE h.HolidayStatusOT IS NOT NULL

	UPDATE ta
	SET MiBreakStart = MiWorkEnd, BreakStart = WorkEnd
	FROM #tmpHasTA ta
	WHERE MiBreakStart < MiWorkStart OR MiBreakStart > MiWorkEnd

	UPDATE ta
	SET MiBreakEnd = MiWorkEnd, BreakEnd = WorkEnd
	FROM #tmpHasTA ta
	WHERE MiBreakEnd < MiWorkStart OR MiBreakEnd > MiWorkEnd

	------------------------------ Goi thu tuc tinh late early-------------------------------------------
	--update #tmpHasTA set SiAttStart = MiAttStart*60.0, SiAttEnd = MiAttEnd*60
	CREATE TABLE #LateEarly (EmployeeID VARCHAR(20), IODate DATE, Period INT, IOKind INT, IOStart DATETIME, IOEnd DATETIME, IOMinutes FLOAT, IOMinutesDeduct FLOAT, ApprovedDeduct BIT)

	--late
	INSERT INTO #LateEarly (EmployeeID, IODate, Period, IOKind, IOStart, IOEnd, IOMinutes, IOMinutesDeduct, ApprovedDeduct)
	SELECT EmployeeID, AttDate, Period, 1 AS IOKind, WorkStart, AttStart, ((MiAttStart - MiWorkStart + 7) / 15) * 15, ((MiAttStart - MiWorkStart + 7) / 15) * 15, 0
	FROM #tmpHasTA
	WHERE Holidaystatus = 0 AND MiAttStart BETWEEN MiWorkStart + 1 AND MiWorkStart + 480

	INSERT INTO #LateEarly (EmployeeID, IODate, Period, IOKind, IOStart, IOEnd, IOMinutes, IOMinutesDeduct, ApprovedDeduct)
	SELECT EmployeeID, AttDate, Period, 2 AS IOKind, AttEnd, WorkEnd, ((MiWorkEnd - MiAttEnd + 7) / 15) * 15, ((MiWorkEnd - MiAttEnd + 7) / 15) * 15, 0
	FROM #tmpHasTA
	WHERE Holidaystatus = 0 AND MiAttEnd BETWEEN MiWorkEnd - 480 AND MiWorkEnd - 1

	--TRIPOD: không trừ các trường hợp có tăng ca bù
	UPDATE #LateEarly
	SET ApprovedDeduct = 1
	FROM #LateEarly l
	INNER JOIN #tmpHasTA ta ON l.EmployeeID = ta.EmployeeID AND l.IODate = ta.AttDate
	WHERE IOKind = 1 AND MiAttEnd < MiWorkEnd + (MiAttStart - MiWorkStart)

	UPDATE #LateEarly
	SET ApprovedDeduct = 1
	FROM #LateEarly l
	INNER JOIN #tmpHasTA ta ON l.EmployeeID = ta.EmployeeID AND l.IODate = ta.AttDate
	WHERE IOKind = 2 AND MiAttStart > MiWorkStart - IOMinutes

	DELETE tblInLateOutEarly
	FROM tblInLateOutEarly l
	WHERE ISNULL(l.StatusID, 1) = 1 AND EXISTS (
			SELECT 1
			FROM #tblPendingTaProcessMain p
			WHERE l.EmployeeID = p.EmployeeID AND l.IODate = p.DATE
			)

	DELETE l
	FROM #LateEarly l
	WHERE EXISTS (
			SELECT 1
			FROM tblInLateOutEarly i
			WHERE l.EmployeeID = i.EmployeeID AND l.IODate = i.IODate AND l.IOKind = i.IOKind
			)

	INSERT INTO tblInLateOutEarly (EmployeeID, IODate, Period, IOKind, IOStart, IOEnd, IOMinutes, IOMinutesDeduct, ApprovedDeduct)
	SELECT EmployeeID, IODate, Period, IOKind, IOStart, IOEnd, IOMinutes, IOMinutesDeduct, 1 ApprovedDeduct
	FROM #LateEarly

	--TRIPOD
	UPDATE #tmpHasTA
	SET MiAttStart = ((MiAttStart + 7) / 15) * 15
	FROM #tmpHasTA ta
	WHERE MiAttStart > MiWorkStart + 15

	UPDATE #tmpHasTA
	SET MiAttEnd = ((MiAttEnd + 7) / 15) * 15
	FROM #tmpHasTA ta
	WHERE MiAttEnd < MiWorkEnd - 15

	--begin OT
	BEGIN
		DECLARE @OT_MIN_BEFORE INT, @OT_MIN_AFTER INT, @OT_MIN_HOLIDAY INT, @Value T_Value, @OTBEFORE_LEAVE_FULLDAY INT

		BEGIN
			SET @OTBEFORE_LEAVE_FULLDAY = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'OTBEFORE_LEAVE_FULLDAY'
					)
			SET @OTBEFORE_LEAVE_FULLDAY = isnull(@OTBEFORE_LEAVE_FULLDAY, 0)
			SET @OT_MIN_BEFORE = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'OT_MIN_BEFORE'
					)
			SET @OT_MIN_BEFORE = isnull(@OT_MIN_BEFORE, 30)
			SET @OT_MIN_AFTER = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'OT_MIN_AFTER'
					)
			SET @OT_MIN_AFTER = isnull(@OT_MIN_AFTER, 30)
			SET @OT_MIN_HOLIDAY = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'OT_MIN_HOLIDAY'
					)
			SET @OT_MIN_HOLIDAY = isnull(@OT_MIN_HOLIDAY, 30)

			DECLARE @OT_MIN_BREAKTEA FLOAT, @OT_BREAKTEA FLOAT

			SET @OT_BREAKTEA = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'OT_BREAKTEA'
					)
			SET @OT_BREAKTEA = isnull(@OT_BREAKTEA, 45)
			SET @OT_MIN_BREAKTEA = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'OT_MIN_BREAKTEA'
					)
			SET @OT_MIN_BREAKTEA = isnull(@OT_MIN_BREAKTEA, 3)

			CREATE TABLE #tmpOTTemp (EmployeeID NVARCHAR(20), AttDate DATETIME, Period TINYINT NULL, ShiftID INT, DayType INT, OTCategoryID INT, AttStart DATETIME, AttEnd DATETIME, MiAttStart INT, MiAttEnd INT, MiOTStart INT, MiOTEnd INT, MiOTStartR INT, MiOTEndR INT, MiWorkStart INT, MiWorkEnd INT, MiOTBeforeStart INT, MiOTBeforeEnd INT, MiOTAfterStart INT, MiOTAfterEnd INT, OutStart INT, InStart INT)

			/*
  CREATE TABLE #OTNotOverwrite(EmployeeID varchar(20),OTDate datetime primary key(EmployeeID,OTDate))
  if @IsAuditAccount = 0
  begin
   insert into #OTNotOverwrite(EmployeeID,OTDate)
   select distinct ot.EmployeeID,ot.OTDate from tblOTList ot inner join #tblPendingTaProcessMain p on ot.EmployeeID = p.EmployeeID and ot.OTDate = p.[Date]
    where ot.StatusID = 3
  end
  else
  begin
   insert into #OTNotOverwrite(EmployeeID,OTDate)
   select distinct ot.EmployeeID,ot.OTDate from tblOTList_CT ot inner join #tblPendingTaProcessMain p on ot.EmployeeID = p.EmployeeID and ot.OTDate = p.[Date]
    where ot.StatusID = 3
  end
  */
			SELECT *, CAST(8 AS INT) STD_WD
			INTO #tmpHasTA_OT
			FROM #tmpHasTA ta
			WHERE ta.AttStart IS NOT NULL AND ta.AttEnd IS NOT NULL

			--lichien : Chinese not calculate ot
			--delete #tmpHasTA_OT from #tmpHasTA_OT where EmployeeID like 'C%' and AttDate < '2024-05-01'
			-- tuy chọn, đi làm ngày chủ nhật, tăng ca có tính theo ca làm việc không?
			DECLARE @HolidayOTBaseOnShiftInfo BIT = 0

			IF NOT EXISTS (
					SELECT 1
					FROM tblParameter
					WHERE Code = 'HolidayOTBaseOnShiftInfo'
					)
				INSERT INTO tblParameter (Code, Value, Type, Category, Description, Visible)
				VALUES ('HolidayOTBaseOnShiftInfo', '1', '1', 'TIME ATTENDANCE', N'Đi làm ngày chủ nhật, tăng ca có tính theo ca làm việc không? 0: không theo ca, lấy giờ đầu trừ giờ cuối. 1: theo thiết lập của ca làm việc', 1)

			IF NOT EXISTS (
					SELECT 1
					FROM tblParameter
					WHERE Code = 'HolidayOTBaseOnShiftInfo' AND Value = '0'
					)
				SET @HolidayOTBaseOnShiftInfo = 1

			-- nghỉ nửa đầu hoặc nửa sau thì chỉ tính OT sau hoăc OT trước
			UPDATE #tmpHasTA_OT
			SET MiWorkStart = DATEPART(hh, OTBeforeEnd) * 60 + DATEPART(mi, OTBeforeEnd)
			FROM #tmpHasTA_OT ta
			INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTBeforeEnd IS NOT NULL AND ta.MiWorkStart < DATEPART(hh, OTBeforeEnd) * 60 + DATEPART(mi, OTBeforeEnd)
			WHERE (ta.Holidaystatus = 0)

			UPDATE #tmpHasTA_OT
			SET MiWorkEnd = DATEPART(hh, OTAfterStart) * 60 + DATEPART(mi, OTAfterStart)
			FROM #tmpHasTA_OT ta
			INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTAfterStart IS NOT NULL AND DATEPART(hh, ta.WorkStart) < DATEPART(hh, ta.WorkEnd) AND ta.MiWorkEnd < 1440
			WHERE (ta.Holidaystatus = 0)

			UPDATE #tmpHasTA_OT
			SET MiWorkEnd = 1440 + DATEPART(hh, OTAfterStart) * 60 + DATEPART(mi, OTAfterStart)
			FROM #tmpHasTA_OT ta
			INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTAfterStart IS NOT NULL AND ta.MiWorkEnd > 1440 + DATEPART(hh, OTAfterStart) * 60 + DATEPART(mi, OTAfterStart) AND DATEPART(hh, ta.WorkStart) > DATEPART(hh, ta.WorkEnd) --  AND ta.MiWorkEnd >= DATEPART(hh,OTAfterStart)* 60 + DATEPART(mi,OTAfterStart)
			WHERE (ta.Holidaystatus = 0)

			UPDATE #tmpHasTA_OT
			SET MiAttStart = DATEPART(hh, OTBeforeStart) * 60 + DATEPART(mi, OTBeforeStart)
			FROM #tmpHasTA_OT ta
			INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTBeforeEnd IS NOT NULL AND ta.MiAttStart < DATEPART(hh, OTBeforeStart) * 60 + DATEPART(mi, OTBeforeStart)
			WHERE (ta.Holidaystatus = 0 OR (@HolidayOTBaseOnShiftInfo = 1 AND ta.Holidaystatus <> 0))

			UPDATE #tmpHasTA_OT
			SET MiAttStart = MiWorkStart
			WHERE MiWorkStart - MiAttStart < @OT_MIN_BEFORE AND MiWorkStart - MiAttStart > 0 AND (Holidaystatus = 0 OR (@HolidayOTBaseOnShiftInfo = 1 AND Holidaystatus <> 0))

			UPDATE #tmpHasTA_OT
			SET MiAttEnd = DATEPART(hh, OTAfterEnd) * 60 + DATEPART(mi, OTAfterEnd)
			FROM #tmpHasTA_OT ta
			INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTAfterEnd IS NOT NULL AND ta.MiAttEnd > (DATEPART(hh, OTAfterEnd) * 60 + DATEPART(mi, OTAfterEnd)) AND ta.MiAttEnd <= 1440 AND (DATEPART(hh, OTAfterEnd) * 60 + DATEPART(mi, OTAfterEnd)) >= (DATEPART(hh, OTAfterStart) * 60 + DATEPART(mi, OTAfterStart))
			WHERE (ta.Holidaystatus = 0 OR (@HolidayOTBaseOnShiftInfo = 1 AND ta.Holidaystatus <> 0)) AND ((LvAmount IS NULL AND @OTBEFORE_LEAVE_FULLDAY = 1) OR (@OTBEFORE_LEAVE_FULLDAY = 0)) -- tri.le

			UPDATE #tmpHasTA_OT
			SET MiAttEnd = 1440 + DATEPART(hh, OTAfterEnd) * 60 + DATEPART(mi, OTAfterEnd)
			FROM #tmpHasTA_OT ta
			INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTAfterEnd IS NOT NULL AND ta.MiAttEnd > (1440 + DATEPART(hh, OTAfterEnd) * 60 + DATEPART(mi, OTAfterEnd))
			WHERE (ta.Holidaystatus = 0 OR (@HolidayOTBaseOnShiftInfo = 1 AND ta.Holidaystatus <> 0))

			UPDATE #tmpHasTA_OT
			SET MiAttEnd = MiWorkEnd
			FROM #tmpHasTA_OT ot
			WHERE MiAttEnd - MiWorkEnd > 0 AND MiAttEnd - MiWorkEnd < @OT_MIN_AFTER AND (Holidaystatus = 0 OR (@HolidayOTBaseOnShiftInfo = 1 AND Holidaystatus <> 0)) AND NOT EXISTS (
					SELECT 1
					FROM #Maternity m
					WHERE ot.EmployeeID = m.EmployeeID AND ot.AttDate BETWEEN BornDate AND EndDate
					) --loai bo nhung nguoi huong che do truoc sau sinh

			-- xu ly truong hop ngay chu nhat, le, di lam nua buoi
			UPDATE o
			SET MiAttStart = MiBreakEnd
			FROM #tmpHasTA_OT o
			WHERE @HolidayOTBaseOnShiftInfo = 1 AND o.Holidaystatus > 0 AND MiAttStart BETWEEN MiBreakStart AND MiBreakEnd

			UPDATE o
			SET MiAttEnd = MiBreakStart
			FROM #tmpHasTA_OT o
			WHERE @HolidayOTBaseOnShiftInfo = 1 AND o.Holidaystatus > 0 AND MiAttEnd BETWEEN MiBreakStart AND MiBreakEnd

			--select miWorkStart - miAttStart,MiAttEnd - MiAttStart ,* from #tmpHasTA_OT ot
			-- loại bỏ những record không có OT + TRIPOD: Trừ các thứ 7 OFF
			DELETE #tmpHasTA_OT
			FROM #tmpHasTA_OT ot
			WHERE DayType = 0 AND NOT EXISTS (
					SELECT 1
					FROM #OTSaturday s
					WHERE s.EmployeeID = ot.EmployeeID AND s.ScheduleDate = ot.AttDate
					) AND ((miWorkStart - miAttStart < @OT_MIN_BEFORE AND MiAttEnd - MiWorkEnd < @OT_MIN_AFTER) OR MiAttEnd - MiAttStart < @OT_MIN_AFTER) AND NOT EXISTS (
					SELECT 1
					FROM #Maternity m
					WHERE ot.EmployeeID = m.EmployeeID AND ot.AttDate BETWEEN BornDate AND EndDate
					) --loai bo nhung nguoi huong che do truoc sau sinh

			SELECT EmployeeID
			INTO #tblEmployeeWithoutOT
			FROM #tmpEmployee
			WHERE (
					PositionID IN (
						SELECT PositionID
						FROM tblPosition
						WHERE OTCalculated = 0
						) OR DepartmentID IN (
						SELECT DepartmentID
						FROM tblDepartment
						WHERE OTCalculated = 0
						)
					) AND EmployeeID IN (
					SELECT EmployeeID
					FROM #tmpEmployee
					)

			IF (OBJECT_ID('TA_ProcessMain_Begin_InsertOTTemp') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_Begin_InsertOTTemp
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
 SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_Begin_InsertOTTemp @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			--------------------------- Insert cac ban ghi de tinh OT before(OTCategoryID = 1 )---------------------------
			INSERT INTO #tmpOTTemp (EmployeeID, Period, AttDate, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiAttStart, MiAttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR, MiWorkEnd, MiWorkStart)
			SELECT EmployeeID, Period, AttDate, ShiftID, DayType, 1, AttStart, AttEnd, MiAttStart, MiAttEnd, MiAttStart, CASE 
					WHEN MiWorkStart > MiAttend
						THEN MiAttend
					ELSE MiWorkStart
					END, MiAttStart, CASE 
					WHEN MiWorkStart > MiAttend
						THEN MiAttend
					ELSE MiWorkStart
					END, MiWorkEnd, MiWorkStart
			FROM #tmpHasTA_OT o
			WHERE (
					CASE 
						WHEN MiWorkStart > MiAttend
							THEN MiAttend
						ELSE MiWorkStart
						END - MiAttStart >= @OT_MIN_BEFORE AND isnull(MiBreakStart, MiWorkStart) - MiAttStart >= 0 -- Neu  nghi nua buoi sang, chieu di lam som thi` phai lam truoc BreakStart moi duoc tinh OT truoc
					AND DayType = 0 -- Neu lam ca ngay hoac nua buoi sang thi` ko bi anh huong gi boi cau lenh nay vi khi do BreakStart luon > gio vao lam viec
					AND NOT EXISTS (
						SELECT EmployeeID
						FROM #tblEmployeeWithoutOT n
						WHERE o.EmployeeID = n.EmployeeID
						)
					) OR EmployeeID IN (
					SELECT EmployeeID
					FROM #OTSaturday s
					WHERE s.EmployeeID = o.EmployeeID AND s.ScheduleDate = o.AttDate
					)

			--------------------------- Insert cac ban ghi de tinh OT after(OTCategoryID = 2 )---------------------------
			INSERT INTO #tmpOTTemp (EmployeeID, Period, AttDate, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiAttStart, MiAttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR, MiWorkEnd, MiWorkStart)
			SELECT EmployeeID, Period, AttDate, ShiftID, DayType, 2, AttStart, AttEnd, MiAttStart, MiAttEnd, CASE 
					WHEN MiAttstart > MiWorkEnd
						THEN MiAttStart
					ELSE MiWorkEnd
					END, MiAttEnd, CASE 
					WHEN MiAttstart > MiWorkEnd
						THEN MiAttStart
					ELSE MiWorkEnd
					END, MiAttEnd, MiWorkEnd, MiWorkStart
			FROM #tmpHasTA_OT o
			WHERE MiAttEnd - CASE 
					WHEN MiAttstart > MiWorkEnd
						THEN MiAttStart
					ELSE MiWorkEnd
					END >= (@OT_MIN_AFTER - 10) AND DayType = 0 AND NOT EXISTS (
					SELECT EmployeeID
					FROM #tblEmployeeWithoutOT n
					WHERE o.EmployeeID = n.EmployeeID
					)

			--------------------------- Insert cac ban ghi de tinh OT IN HOLIDAY(OTCategoryID = 3 )---------------------------
			INSERT INTO #tmpOTTemp (EmployeeID, Period, AttDate, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiAttStart, MiAttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR, MiWorkEnd, MiWorkStart)
			SELECT EmployeeID, Period, AttDate, ShiftID, DayType, 3, AttStart, AttEnd, MiAttStart, MiAttEnd, MiAttStart, MiAttEnd, MiAttStart, MiAttEnd, MiWorkEnd, MiWorkStart
			FROM #tmpHasTA_OT o
			WHERE MiAttEnd - MiAttStart >= @OT_MIN_AFTER AND DayType <> 0 AND NOT EXISTS (
					SELECT EmployeeID
					FROM #tblEmployeeWithoutOT n
					WHERE o.EmployeeID = n.EmployeeID
					)

			UPDATE #ShiftInfo
			SET MiDeductBearkTime = datepart(hh, BreakEnd) * 60 + DATEPART(Mi, BreakEnd) - (datepart(hh, BreakStart) * 60 + DATEPART(Mi, BreakStart))

			--TN:gio nghi giua ca bao 0:00
			UPDATE #ShiftInfo
			SET MiDeductBearkTime = datepart(hh, BreakEnd) * 60 + DATEPART(Mi, BreakEnd) + 1440 - (datepart(hh, BreakStart) * 60 + DATEPART(Mi, BreakStart))
			WHERE MiDeductBearkTime < 0

			-- Xu ly thong tin cho cac co nang sau ho san
			DECLARE @MATERNITY_OT INT

			SET @MATERNITY_OT = (
					SELECT cast(value AS INT)
					FROM tblParameter
					WHERE code = 'MATERNITY_OT'
					)
			SET @MATERNITY_OT = isnull(@MATERNITY_OT, 1)

			--TN:hộ thai sản thì k có tăng ca
			DELETE #tmpOTTemp
			FROM #tmpOTTemp a
			INNER JOIN #Maternity b ON a.EmployeeID = b.EMployeeID AND datediff(day, a.AttDate, EndDate) >= 0 AND DATEDIFF(day, a.AttDate, BornDate) <= 0

			IF @MATERNITY_OT = 1 -- neu co tang ca thi them vao lai thoi
			BEGIN
				SELECT a.*, a.MiAttStart - a.MiWorkStart InLate, a.MiWorkEnd - a.MiAttEnd OutEarly, b.MinusMin MaternityMinus, b.MinusMin
				INTO #tmpHasTAMaternity
				FROM #tmpHasTA_OT a
				INNER JOIN #Maternity b ON a.EmployeeID = b.EMployeeID AND a.AttDate BETWEEN BornDate AND EndDate AND (a.LeaveStatus <> 3 OR a.DayType <> 0)

				-- chỉnh lại thời gian bắt đầu tăng ca cho nhân viên thai sản, MiWorkEnd
				UPDATE #tmpHasTAMaternity
				SET MiWorkEnd = DATEPART(hh, ts.WorkEnd) * 60 + DATEPART(mi, ts.WorkEnd)
				FROM #tmpHasTAMaternity ta
				INNER JOIN #ShiftInfo ts ON ta.ShiftID = ts.ShiftID AND ts.OTAfterStart IS NOT NULL AND DATEPART(hh, ta.WorkStart) < DATEPART(hh, ta.WorkEnd) AND ta.MiWorkEnd < 1440
				WHERE (ta.Holidaystatus = 0)

				UPDATE #tmpHasTAMaternity
				SET InLate = InLate - LvAmount * 60
				WHERE LvAmount > 0 AND LeaveStatus = 1

				UPDATE #tmpHasTAMaternity
				SET OutEarly = OutEarly - LvAmount * 60
				WHERE LvAmount > 0 AND LeaveStatus = 2

				DECLARE @MinusApproveLateEarlyBeign INT = - 10, @MinusApproveLateEarlyEnd INT = 10

				DELETE #tmpHasTAMaternity
				WHERE InLate + OutEarly - (MiBreakEnd - MiBreakStart) >= MaternityMinus AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET InLate = 0
				WHERE InLate < @MinusApproveLateEarlyEnd

				UPDATE #tmpHasTAMaternity
				SET OutEarly = 0
				WHERE OutEarly < @MinusApproveLateEarlyEnd

				UPDATE #tmpHasTAMaternity
				SET InLate = MinusMin
				WHERE (InLate - MinusMin) BETWEEN @MinusApproveLateEarlyBeign AND @MinusApproveLateEarlyEnd

				UPDATE #tmpHasTAMaternity
				SET InLate = InLate - MaternityMinus
				WHERE MaternityMinus > 0 AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET MaternityMinus = - 1 * InLate
				WHERE InLate < 0 AND MaternityMinus > 0 AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET MaternityMinus = 0
				WHERE InLate >= 0 AND MaternityMinus IS NOT NULL AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET InLate = 0
				WHERE InLate < 0 AND MaternityMinus IS NOT NULL AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET OutEarly = OutEarly - MaternityMinus
				WHERE MaternityMinus > 0 AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET MaternityMinus = - 1 * OutEarly
				WHERE OutEarly <= 0 AND MaternityMinus > 0 AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET MaternityMinus = 0
				WHERE OutEarly >= 0 AND MaternityMinus > 0 AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET OutEarly = 0
				WHERE OutEarly < 0 AND MaternityMinus > 0 AND DayType = 0

				UPDATE #tmpHasTAMaternity
				SET MaternityMinus = 0
				WHERE MaternityMinus < 30

				UPDATE #tmpHasTAMaternity
				SET MaternityMinus = MinusMin
				WHERE MaternityMinus > MinusMin

				UPDATE #tmpHasTAMaternity
				SET MiWorkStart = CASE 
						WHEN MiAttStart > MiWorkStart
							THEN MiWorkStart + MaternityMinus
						ELSE MiWorkStart
						END, MiWorkEnd = CASE 
						WHEN MiAttStart <= MiWorkStart
							THEN MiWorkEnd - MinusMin
						ELSE MiWorkEnd - MaternityMinus
						END
				FROM #tmpHasTAMaternity m

				INSERT INTO #tmpOTTemp (EmployeeID, Period, AttDate, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR)
				SELECT EmployeeID, Period, AttDate, ShiftID, DayType, 1, AttStart, AttEnd, MiAttStart, MiWorkStart, MiAttStart, MiWorkStart
				FROM #tmpHasTAMaternity
				WHERE MiWorkStart - MiAttStart >= @OT_MIN_BEFORE AND isnull(MiBreakStart, MiWorkStart) - MiAttStart >= 0 -- Neu  nghi nua buoi sang, chieu di lam som thi` phai lam truoc BreakStart moi duoc tinh OT truoc
					AND DayType = 0 -- Neu lam ca ngay hoac nua buoi sang thi` ko bi anh huong gi boi cau lenh nay vi khi do BreakStart luon > gio vao lam viec
					AND EmployeeID NOT IN (
						SELECT EmployeeID
						FROM #tblEmployeeWithoutOT
						)

				--------------------------- Insert cac ban ghi de tinh OT after(OTCategoryID = 2 )---------------------------
				INSERT INTO #tmpOTTemp (EmployeeID, Period, AttDate, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR)
				SELECT EmployeeID, Period, AttDate, ShiftID, DayType, 2, AttStart, AttEnd, MiWorkEnd, MiAttEnd, MiWorkEnd, MiAttEnd
				FROM #tmpHasTAMaternity
				WHERE MiAttEnd - MiWorkEnd >= @OT_MIN_AFTER AND DayType = 0 AND EmployeeID NOT IN (
						SELECT EmployeeID
						FROM #tblEmployeeWithoutOT
						)

				--------------------------- Insert cac ban ghi de tinh OT IN HOLIDAY(OTCategoryID = 3 )---------------------------
				INSERT INTO #tmpOTTemp (EmployeeID, Period, AttDate, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR)
				SELECT EmployeeID, Period, AttDate, ShiftID, DayType, 3, AttStart, AttEnd, MiAttStart, MiAttEnd, MiAttStart, MiAttEnd
				FROM #tmpHasTAMaternity
				WHERE MiAttEnd - MiAttStart >= @OT_MIN_HOLIDAY AND DayType <> 0 AND EmployeeID NOT IN (
						SELECT EmployeeID
						FROM #tblEmployeeWithoutOT
						)
					-- Ket Thuc Xu ly thong tin cho cac co nang sau ho san
			END

			IF (OBJECT_ID('TA_ProcessMain_Finish_InsertOTTemp') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_Finish_InsertOTTemp
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)

as
begin
 SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_Finish_InsertOTTemp @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			UPDATE #ShiftInfo
			SET WorkEnd = DATEADD(DAY, 1, WorkEnd)
			WHERE WorkStart > WorkEnd

			UPDATE #ShiftInfo
			SET BreakStart = DATEADD(DAY, 1, BreakStart)
			WHERE WorkStart > BreakStart

			UPDATE #ShiftInfo
			SET BreakEnd = DATEADD(DAY, 1, BreakEnd)
			WHERE BreakStart > BreakEnd

			UPDATE #ShiftInfo
			SET OTAfterStart = DATEADD(DAY, 1, OTAfterStart)
			WHERE WorkEnd > OTAfterStart

			UPDATE #ShiftInfo
			SET OTAfterEnd = DATEADD(DAY, 1, OTAfterEnd)
			WHERE OTAfterStart > OTAfterEnd

			--SELECT 999, DATEDIFF(mi,t.AttDate, DATEADD(DAY,DATEDIFF(DAY,s.WorkStart,t.AttDate),s.OTAfterStart)),  DATEDIFF(mi,t.AttDate,DATEADD(DAY,DATEDIFF(DAY,s.WorkStart,t.AttDate),s.OTAfterEnd))
			UPDATE t
			SET t.MiOTAfterStart = DATEDIFF(mi, t.AttDate, DATEADD(DAY, DATEDIFF(DAY, s.WorkStart, t.AttDate), s.OTAfterStart)), t.MiOTAfterEnd = DATEDIFF(mi, t.AttDate, DATEADD(DAY, DATEDIFF(DAY, s.WorkStart, t.AttDate), s.OTAfterEnd)), t.MiOTBeforeStart = DATEDIFF(mi, t.AttDate, DATEADD(DAY, DATEDIFF(DAY, s.WorkStart, t.AttDate), s.OTBeforeStart)), t.MiOTBeforeEnd = DATEDIFF(mi, t.AttDate, DATEADD(DAY, DATEDIFF(DAY, s.WorkStart, t.AttDate), s.OTBeforeEnd))
			FROM #tmpOTTemp t
			INNER JOIN #ShiftInfo s ON t.ShiftID = s.ShiftID

			----------------------------------------Kiem tra du lieu overwrite hay ko-------------------------------------------
			---------------------------Them cac point, cac KindOT de tinh OT, dua vao cac DayType-------------------------------
			CREATE TABLE #tmpOT (
				EmployeeID NVARCHAR(20), AttDate DATETIME, Period TINYINT, ShiftID INT, DayType INT, OTCategoryID INT, AttStart DATETIME, AttEnd DATETIME, MiWorkStart INT, MiWorkEnd INT, MiAttStart INT, MiAttEnd INT, MiBreakStart INT, MiBreakEnd INT, DeductBreakTime INT, MiOTStart INT, MiOTEnd INT, MiOTStartR INT, MiOTEndR INT, MiOTStartTmp INT, MiOTEndTmp INT, Point1 INT, Point2 INT, Point3 INT, Point4 INT, Point5 INT, Point6 INT, AdjustTime INT, V12 FLOAT,
				-- gia tri OT tinh duoc trong khoang point1 den point2
				V34 FLOAT, -- gia tri OT tinh duoc trong khoang point3 den point4
				V56 FLOAT, OTValue FLOAT, OTKind INT, OTFrom12 DATETIME, -- Thoi gian bat dau OT trong khoang tu point1 den point2
				OTTo12 DATETIME, -- Thoi gian ket thuc OT trong khoang tu point1 den point2
				OTFrom34 DATETIME, OTTo34 DATETIME, OTFrom56 DATETIME, OTTo56 DATETIME, MealDeductHours FLOAT -- bi tru tien nghi an trua
				, V12Real FLOAT, V34Real FLOAT, V56Real FLOAT, Approved BIT DEFAULT(0)
				)

			INSERT INTO #tmpOT (EmployeeID, AttDate, Period, ShiftID, DayType, OTCategoryID, AttStart, AttEnd, MiWorkStart, MiWorkEnd, MiAttStart, MiAttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR, Point1, Point2, Point3, Point4, Point5, Point6, OTKind, DeductBreakTime)
			SELECT EmployeeID, AttDate, Period, ShiftID, t.DayType, OTCategoryID, AttStart, AttEnd, MiWorkStart, MiWorkEnd, MiAttStart, MiAttEnd, MiOTStart, MiOTEnd, MiOTStartR, MiOTEndR, Point1, Point2, Point3, Point4, Point5, Point6, OTKind, 0
			--,CASE WHEN t.DayType > 0 AND t.MiOTAfterStart > t.MiWorkEnd AND t.MiOTEnd > t.MiOTAfterStart THEN t.MiOTAfterStart - t.MiWorkEnd WHEN t.DayType > 0 AND t.MiOTEnd > t.MiWorkEnd THEN t.MiOTEnd - t.MiWorkEnd ELSE 0 end
			FROM #tmpOTTemp t
			INNER JOIN tblOvertimeRange r ON r.DayType = t.DayType

			--TRIPOD: Xoá các ngày loại OT thứ 7 nhưng k phải thứ 7
			DELETE
			FROM #tmpOT
			WHERE NOT EXISTS (
					SELECT 1
					FROM #OTSaturday s
					WHERE s.EmployeeID = #tmpOT.EmployeeID AND s.ScheduleDate = #tmpOT.AttDate
					) AND OTKind = 34

			UPDATE #tmpOT
			SET MiOTStartR = MiOTStart
			WHERE MiOTStartR IS NULL

			UPDATE #tmpOT
			SET MiOTEndR = MiOTEnd
			WHERE MiOTEndR IS NULL

			IF (OBJECT_ID('TA_ProcessMain_Finish_SetPointOT') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_Finish_SetPointOT
(
 @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_Finish_SetPointOT @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			DROP TABLE #tmpOTTemp

			-----------------------------Dieu chinh gia tri cua cac Point theo cac shift theo gia tri AdjustTime trong bang tblShiftSetting
			--select * from #tmpOT
			UPDATE #tmpOT
			SET AdjustTime = ISNULL(tblShiftSetting.AdjustTime, 0)
			FROM tblShiftSetting
			WHERE tblShiftSetting.ShiftID = #tmpOT.ShiftID

			--làm tròn
			UPDATE #tmpOT
			SET AdjustTime = 0
			WHERE AdjustTime IS NULL

			UPDATE #tmpOT
			SET Point1 = Point1 + AdjustTime, Point2 = Point2 + AdjustTime, Point3 = Point3 + AdjustTime, Point4 = Point4 + AdjustTime, Point5 = Point5 + AdjustTime, Point6 = Point6 + AdjustTime

			--tinh luong t.c doan sua vao chu nhat
			--update #tmpOT set  DeductBreakTime = 0 where daytype = 1
			UPDATE #tmpOT
			SET DeductBreakTime = ISNULL(DeductBreakTime, 0) + s.MiDeductBearkTime, MiBreakStart = datepart(hh, s.BreakStart) * 60 + DATEPART(mi, s.BreakStart) + CASE 
					WHEN DATEPART(hh, s.BreakStart) < DATEPART(hh, s.WorkStart)
						THEN 1440
					ELSE 0
					END, MiBreakEnd = datepart(hh, s.BreakEnd) * 60 + DATEPART(mi, s.BreakEnd) + CASE 
					WHEN DATEPART(hh, s.BreakEnd) < DATEPART(hh, s.WorkStart)
						THEN 1440
					ELSE 0
					END
			FROM #tmpOT t, #ShiftInfo s
			WHERE t.ShiftID = s.ShiftID

			-- chinh lai BreakStart, BreakEnd cho ca đêm
			UPDATE #tmpOT
			SET DeductBreakTime = 0
			WHERE MiOTEnd <= MiBreakStart OR MiOTStart >= MiBreakEnd

			UPDATE #tmpOT
			SET DeductBreakTime = ISNULL(DeductBreakTime, 0) + MiOTEnd - MiBreakStart
			WHERE MiOTEnd < MiBreakEnd AND MiOTEnd > MiBreakStart

			UPDATE #tmpOT
			SET DeductBreakTime = ISNULL(DeductBreakTime, 0) + MiBreakEnd - MiOTStart
			WHERE MiOTStart < MiBreakEnd AND MiOTStart > MiBreakStart

			UPDATE #tmpOT
			SET DeductBreakTime = 0
			WHERE daytype > 0 AND @HolidayOTBaseOnShiftInfo = 0 -- tri.le: chủ nhật làm luôn giờ nghỉ trưa
				-------------------------------Tinh OT-------------------------------------------------------
				-------1:OT trong doan tu Point5 den Point6--------------------------

			SELECT *
			INTO #tmpOTUpdate_OTStartEnd
			FROM #tmpOT

			UPDATE #tmpOT
			SET MiOTStartTmp = MiOTStart
			WHERE MiOTStart >= Point5

			UPDATE #tmpOT
			SET MiOTStartTmp = Point5
			WHERE MiOTStart < Point5

			UPDATE #tmpOT
			SET MiOTEndTmp = Point6
			WHERE MiOTEnd >= Point6

			UPDATE #tmpOT
			SET MiOTEndTmp = MiOTEnd
			WHERE MiOTEnd < Point6

			UPDATE #tmpOT
			SET V56 = MiOTEndTmp - MiOTStartTmp

			IF (
					EXISTS (
						SELECT 1
						FROM tblOTDeductedTime
						)
					)
				UPDATE #tmpOT -- Kiem tra OT co thuoc thoi gian bi tru ko
				SET V56 = V56 - (
						SELECT isnull(SUM(DeductedValue), 0)
						FROM tblOTDeductedTime
						WHERE tblOTDeductedTime.ShiftID = #tmpOT.ShiftID AND MiOTStartTmp <= MiDeductedStart AND MiOTEndTmp >= MiDeductedEnd
						)

			UPDATE #tmpOT
			SET V56 = V56 - DeductBreakTime
			WHERE V56 >= DeductBreakTime AND MiBreakStart >= MiOTStartTmp AND MiBreakEnd <= MiOTEndTmp

			UPDATE #tmpOT
			SET V56Real = ROUND(V56 / 60.0, 2), V56 = (CAST(V56 AS INT) / @OT_ROUND_UNIT) * (CAST(@OT_ROUND_UNIT AS FLOAT) / 60) + CASE 
					WHEN @OT_ROUND_UNIT < 0 AND (V56 - cast(CAST(V56 AS INT) / @OT_ROUND_UNIT AS FLOAT) * @OT_ROUND_UNIT) <> 0
						THEN CAST(abs(@OT_ROUND_UNIT) AS FLOAT) / 60
					ELSE 0.0
					END

			--V56 = CEILING(CAST(V56 AS FLOAT) / @OT_ROUND_UNIT) * (CAST(@OT_ROUND_UNIT AS FLOAT) / 60)
			UPDATE #tmpOT
			SET V56 = 0
			WHERE isnull(V56, 0) <= 0

			-- Tinh OTFrom56, OTTo56
			UPDATE #tmpOT
			SET OTFrom56 = dateadd(hh, cast(MiOTStartTmp AS INT) / 60, AttDate), OTTo56 = dateadd(hh, cast(MiOTEndTmp AS INT) / 60, AttDate)
			WHERE V56 > 0

			UPDATE #tmpOT
			SET OTFrom56 = dateadd(mi, cast(MiOTStartTmp AS INT) % 60, OTFrom56), OTTo56 = dateadd(mi, cast(MiOTEndTmp AS INT) % 60, OTTo56)
			WHERE V56 > 0

			--tringuyen:neu k co tang ca trong doan v34 thi cap nhat lai otstart,otEnd
			UPDATE #tmpOT
			SET MiOTStartTmp = up.MiOTStartTmp, MiOTEndTmp = up.MiOTEndTmp
			FROM #tmpOT ot
			INNER JOIN #tmpOTUpdate_OTStartEnd up ON ot.EmployeeID = up.EmployeeID AND ot.AttDate = up.AttDate AND ot.OTKind = up.OTKind AND ot.Point1 = up.Point1 AND ot.Point2 = up.Point2 AND ot.Point3 = up.Point3 AND ot.Point4 = up.Point4 AND ot.Point5 = up.Point5
			WHERE ot.V56 = 0

			-------2:OT trong doan tu Point3 den Point4--------------------------
			TRUNCATE TABLE #tmpOTUpdate_OTStartEnd

			INSERT INTO #tmpOTUpdate_OTStartEnd
			SELECT *
			FROM #tmpOT

			UPDATE #tmpOT
			SET MiOTStartTmp = MiOTStart
			WHERE MiOTStart >= Point3

			UPDATE #tmpOT
			SET MiOTStartTmp = Point3
			WHERE MiOTStart < Point3

			UPDATE #tmpOT
			SET MiOTEndTmp = Point4
			WHERE MiOTEnd >= Point4

			UPDATE #tmpOT
			SET MiOTEndTmp = MiOTEnd
			WHERE MiOTEnd < Point4

			--TRIPOD: thứ 7 100%
			IF EXISTS (
					SELECT 1
					FROM #OTSaturday
					)
			BEGIN
				UPDATE #tmpOT
				SET MiOTStartTmp = CASE 
						WHEN MiAttStart <= MiWorkStart
							THEN MiWorkStart
						WHEN MiAttStart <= MiBreakStart
							THEN MiAttStart
						WHEN MiAttStart <= MiBreakEnd
							THEN MiBreakEnd
						WHEN MiAttStart <= MiWorkEnd
							THEN MiAttStart
						ELSE MiWorkEnd
						END, MiOTEndTmp = CASE 
						WHEN MiAttEnd >= MiWorkEnd
							THEN MiWorkEnd
						WHEN MiAttEnd >= MiBreakEnd
							THEN MiAttEnd
						WHEN MiAttEnd >= MiBreakStart
							THEN MiBreakStart
						WHEN MiAttEnd >= MiWorkStart
							THEN MiAttEnd
						ELSE MiWorkStart
						END, DeductBreakTime = MiBreakEnd - MiBreakStart
				WHERE OTKind = 34
			END

			UPDATE #tmpOT
			SET V34 = MiOTEndTmp - MiOTStartTmp

			IF (
					EXISTS (
						SELECT 1
						FROM tblOTDeductedTime
						)
					)
				UPDATE #tmpOT -- Kiem tra OT co thuoc thoi gian bi tru ko
				SET V34 = V34 - (
						SELECT isnull(SUM(DeductedValue), 0)
						FROM tblOTDeductedTime
						WHERE tblOTDeductedTime.ShiftID = #tmpOT.ShiftID AND MiOTStartTmp <= MiDeductedStart AND MiOTEndTmp >= MiDeductedEnd
						)

			--tăng ca đến luôn đến hôm sau thì không nghỉ
			UPDATE #tmpOT
			SET DeductBreakTime = 0
			WHERE OTKind = 26

			UPDATE #tmpOT
			SET V34 = V34 - DeductBreakTime
			WHERE V34 >= DeductBreakTime AND MiBreakStart >= MiOTStartTmp AND MiBreakEnd <= MiOTEndTmp

			UPDATE #tmpOT
			SET V34Real = ROUND(V34 / 60.0, 2),
				--V34 = (CAST(V34 AS INT)/@OT_ROUND_UNIT)*(CAST(@OT_ROUND_UNIT AS FLOAT)/60)
				--+ case when @OT_ROUND_UNIT < 0 and (V34-cast(CAST(V34 AS INT)/@OT_ROUND_UNIT as float)*@OT_ROUND_UNIT) <> 0 then CAST(abs(@OT_ROUND_UNIT) AS FLOAT)/60 else 0.0 end
				V34 = CEILING(CAST(V34 AS FLOAT) / @OT_ROUND_UNIT) * (CAST(@OT_ROUND_UNIT AS FLOAT) / 60)

			UPDATE #tmpOT
			SET V34 = 0
			WHERE isnull(V34, 0) <= 0

			-- Tinh OTFrom, OTTo
			UPDATE #tmpOT
			SET OTFrom34 = dateadd(hh, cast(MiOTStartTmp AS INT) / 60, AttDate), OTTo34 = dateadd(hh, cast(MiOTEndTmp AS INT) / 60, AttDate)
			WHERE V34 > 0

			UPDATE #tmpOT
			SET OTFrom34 = dateadd(mi, cast(MiOTStartTmp AS INT) % 60, OTFrom34), OTTo34 = dateadd(mi, cast(MiOTEndTmp AS INT) % 60, OTTo34)
			WHERE V34 > 0

			--tringuyen:neu k co tang ca trong doan v34 thi cap nhat lai otstart,otEnd
			UPDATE #tmpOT
			SET MiOTStartTmp = up.MiOTStartTmp, MiOTEndTmp = up.MiOTEndTmp
			FROM #tmpOT ot
			INNER JOIN #tmpOTUpdate_OTStartEnd up ON ot.EmployeeID = up.EmployeeID AND ot.AttDate = up.AttDate AND ot.OTKind = up.OTKind AND ot.Point1 = up.Point1 AND ot.Point2 = up.Point2 AND ot.Point3 = up.Point3 AND ot.Point4 = up.Point4 AND ot.Point5 = up.Point5
			WHERE ot.V34 = 0

			-------3:OT trong doan tu Point1 den Point2--------------------------
			TRUNCATE TABLE #tmpOTUpdate_OTStartEnd

			INSERT INTO #tmpOTUpdate_OTStartEnd
			SELECT *
			FROM #tmpOT

			UPDATE #tmpOT
			SET MiOTStartTmp = MiOTStart
			WHERE MiOTStart >= Point1

			UPDATE #tmpOT
			SET MiOTStartTmp = Point1
			WHERE MiOTStart < Point1

			UPDATE #tmpOT
			SET MiOTEndTmp = Point2
			WHERE MiOTEnd >= Point2

			UPDATE #tmpOT
			SET MiOTEndTmp = MiOTEnd
			WHERE MiOTEnd < Point2

			UPDATE #tmpOT
			SET V12 = MiOTEndTmp - MiOTStartTmp

			IF (
					EXISTS (
						SELECT 1
						FROM tblOTDeductedTime
						)
					)
				UPDATE #tmpOT -- Kiem tra OT co thuoc thoi gian bi tru ko
				SET V12 = V12 - (
						SELECT ISNULL(SUM(DeductedValue), 0)
						FROM tblOTDeductedTime
						WHERE tblOTDeductedTime.ShiftID = #tmpOT.ShiftID AND MiOTStartTmp <= MiDeductedStart AND MiOTEndTmp >= MiDeductedEnd
						)

			UPDATE #tmpOT
			SET V12 = V12 - DeductBreakTime
			WHERE V12 >= DeductBreakTime AND MiBreakStart >= MiOTStartTmp AND MiBreakEnd <= MiOTEndTmp

			-- xu ly truong hop ngay chu nhat, le, có nghỉ ca sau đó tăng ca tiếp
			--select V12,*
			UPDATE o
			SET V12 = V12 - s.MIOTAfterStart + s.MIWorkEnd
			FROM #tmpOT o
			INNER JOIN #ShiftInfo s ON o.ShiftID = s.ShiftID
			WHERE V12 > 0 AND o.DayType > 0 AND s.MIWorkEnd < s.MIOTAfterStart AND o.MiOTEnd > s.MIOTAfterStart AND o.MiOTStart < s.MIWorkEnd

			UPDATE #tmpOT
			SET V12Real = ROUND(V12 / 60.0, 2), V12 = (CAST(V12 AS INT) / @OT_ROUND_UNIT) * (CAST(@OT_ROUND_UNIT AS FLOAT) / 60) + CASE 
					WHEN @OT_ROUND_UNIT < 0 AND (V12 - cast(CAST(V12 AS INT) / @OT_ROUND_UNIT AS FLOAT) * @OT_ROUND_UNIT) <> 0
						THEN CAST(abs(@OT_ROUND_UNIT) AS FLOAT) / 60
					ELSE 0.0
					END

			--V12 = CEILING(CAST(V12 AS FLOAT) / @OT_ROUND_UNIT) * (CAST(@OT_ROUND_UNIT AS FLOAT) / 60)
			--làm tròn cho ca V
			UPDATE #tmpOT
			SET V12 = 0
			WHERE isnull(V12, 0) <= 0

			--TRIPOD OT T7 100% đã xử lý ở OT34 nên xoá ở đây
			UPDATE #tmpOT
			SET V12 = 0
			FROM #tmpOT
			WHERE OTKind = 34 AND V12 > 0

			-- Tinh OTFrom, OTTo
			UPDATE #tmpOT
			SET OTFrom12 = dateadd(hh, cast(MiOTStartTmp AS INT) / 60, AttDate), OTTo12 = dateadd(hh, cast(MiOTEndTmp AS INT) / 60, AttDate)
			WHERE V12 > 0

			UPDATE #tmpOT
			SET OTFrom12 = dateadd(mi, cast(MiOTStartTmp AS INT) % 60, OTFrom12), OTTo12 = dateadd(mi, cast(MiOTEndTmp AS INT) % 60, OTTo12)
			WHERE V12 > 0

			--tringuyen:neu k co tang ca o v12 thi cap nhat lai otstarttmp, OTEndTmp
			UPDATE #tmpOT
			SET MiOTStartTmp = up.MiOTStartTmp, MiOTEndTmp = up.MiOTEndTmp
			FROM #tmpOT ot
			INNER JOIN #tmpOTUpdate_OTStartEnd up ON ot.EmployeeID = up.EmployeeID AND ot.AttDate = up.AttDate AND ot.OTCategoryID = up.OTCategoryID AND ot.OTKind = up.OTKind AND ot.Point1 = up.Point1 AND ot.Point2 = up.Point2 AND ot.Point3 = up.Point3 AND ot.Point4 = up.Point4 AND ot.Point5 = up.Point5
			WHERE ot.V12 = 0

			DROP TABLE #tmpOTUpdate_OTStartEnd

			--update #tmpOT SET V12 = V12 - DeductBreakTime/60.0 where V12 >= DeductBreakTime/60.0
			--update #tmpOT SET V34 = V34 - DeductBreakTime/60.0 where V34 >= DeductBreakTime/60.0
			--update #tmpOT SET V56 = V56 - DeductBreakTime/60.0 where V56 >= DeductBreakTime/60.0
			------------------------------OT tong cong--------------------------------
			UPDATE #tmpOT
			SET OTValue = V12 + V34 + V56

			DELETE
			FROM #tmpOT
			WHERE OTValue <= 0 -- Xoa cac ban ghi ko phai OT

			IF EXISTS (
					SELECT 1
					FROM #tmpOT
					WHERE OTKind IN (22, 33)
					)
			BEGIN
				IF EXISTS (
						SELECT 1
						FROM #tblWSchedule sc
						INNER JOIN #tmpOT ot ON sc.EmployeeID = ot.EmployeeID AND sc.ScheduleDate = ot.AttDate
						WHERE ot.OTKind IN (22, 33) AND sc.ShiftCode = 'Shift2'
						)
				BEGIN
					DELETE
					FROM #tmpOT
					WHERE OTKind = 33
				END
				ELSE
				BEGIN
					DELETE
					FROM #tmpOT
					WHERE OTKind = 22
				END
			END

			-----------------------------Ket thuc tinh OT, gio trong bang #tmpOT chi bao gom nhung ngay, nhung nguoi co OT.
			IF COL_LENGTH('tblOTList', 'Period') IS NULL
				ALTER TABLE tblOTList ADD [Period] TINYINT NULL

			DECLARE @Approved INT = 1

			IF EXISTS (
					SELECT 1
					FROM tblParameter
					WHERE Code = 'OT_AUTO_Approved' AND value = '0'
					)
				SET @Approved = 0

			UPDATE #tmpOT
			SET Approved = @Approved

			IF (OBJECT_ID('TA_ProcessMain_Begin_InsertOTList') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_Begin_InsertOTList
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
 SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_Begin_InsertOTList @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			DELETE ot
			FROM tblOTList ot
			INNER JOIN (
				SELECT ta.EmployeeID, ta.AttDate, ta.AttStart, ta.AttEnd, ta.MIAttEnd, ta.MIAttStart --, isnull(ss.MIOTAfterStart,ss.MIWorkEnd) MIOTAfterStart, isnull(ss.MIOTBeforeEnd,ss.MiWorkStart) MIOTBeforeEnd
					, ta.MIAttEnd - isnull(ss.MIOTAfterStart, ss.MIWorkEnd) MIOTAfter, ta.MIAttStart - isnull(ss.MIOTBeforeEnd, ss.MiWorkStart) MIOTBefore
				FROM #tmpHasTA_OT ta
				INNER JOIN #tblWSchedule ws ON ta.EmployeeID = ws.EmployeeID AND ta.AttDate = ws.ScheduleDate
				INNER JOIN #ShiftInfo ss ON ws.ShiftID = ss.ShiftID
				) tmp ON ot.EmployeeID = tmp.EmployeeID AND ot.OTdate = tmp.AttDate
			WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND EXISTS (
					SELECT 1 EmployeeID
					FROM #tmpEmployee otl
					WHERE ot.EmployeeID = otl.EmployeeID
					) AND isnull(ot.StatusID, 0) = 3 AND isnull(Approved, 0) = 0 AND NOT EXISTS (
					SELECT 1
					FROM tblatt_lock al
					WHERE ot.EmployeeId = al.EmployeeId AND ot.OtDate = al.DATE
					) AND (ot.OTHour > MIOTAfter / 60.0 OR ot.OTHour > MIOTBefore / 60.0) AND NOT EXISTS (
					SELECT 1
					FROM #tmpOT t
					WHERE ot.EmployeeID = t.EmployeeID AND ot.OtDate = t.AttDate AND t.OTKind = ot.OTKind AND abs(t.OTValue - ot.OTHour) < 2
					)

			IF @IsAuditAccount = 0
			BEGIN
				DELETE tblOTList
				FROM tblOTList ot
				INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.[Date]
				WHERE NOT EXISTS (
						SELECT 1
						FROM #tmpOT ov
						WHERE ot.EmployeeID = ov.EmployeeID AND ot.OTDate = ov.AttDate AND ot.OTkind = ov.OTkind
						) AND isnull(StatusID, 0) <> 3

				DELETE o
				FROM #tmpOT o
				INNER JOIN tblOTList ot ON o.EmployeeID = ot.EmployeeID AND o.AttDate = ot.OTDate AND o.OTKind = ot.OTKind AND ot.OTCategoryID = o.OTCategoryID AND (datepart(hh, ot.OTFrom) * 60 + datepart(mi, ot.OTfrom) = o.MiOTStartTmp OR datepart(hh, ot.OTFrom) * 60 + datepart(mi, ot.OTfrom) = o.MiOTStartTmp - 1440)
				WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND ot.StatusID = 3

				DELETE ot
				FROM #tmpOT o
				INNER JOIN tblOTList ot ON o.EmployeeID = ot.EmployeeID AND o.AttDate = ot.OTDate AND o.OTKind = ot.OTKind AND ot.OTCategoryID = o.OTCategoryID -- and datepart(hh,ot.OTFrom) *60 + datepart(mi, ot.OTfrom) = o.MiOTStartTmp
				WHERE ot.OTDate BETWEEN @FromDate AND @ToDate AND isnull(ot.StatusID, 0) < 3

				DELETE tblOTList
				FROM tblOTList ot
				INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.[Date]
				WHERE
					-- not exists(select 1 from #OTNotOverwrite ov where ot.EmployeeID = ov.EmployeeID and ot.OTDate = ov.OTDate)  and
					isnull(StatusID, 0) <> 3

				--INSERT INTO tblOTList(EmployeeID, OTCategoryID,OTDate,Period,OTKind,ShiftID,OTFrom,OTTo,OTHour,Approved,ApprovedHours,StatusID,MealDeductHours)
				-- SELECT EmployeeID, OTCategoryID,AttDate,Period,OTKind,ShiftID,OTFrom12,OTTo12,ISNULL(v12Real,V12),Approved,V12,1,MealDeductHours
				-- FROM #tmpOT where V12 > 0
				-- union all
				-- SELECT EmployeeID, OTCategoryID,AttDate,Period,OTKind,ShiftID,OTFrom34,OTTo34,ISNULL(V34Real,V34),Approved,V34,1,MealDeductHours
				-- FROM #tmpOT WHERE V34 > 0
				-- union all
				-- SELECT EmployeeID, OTCategoryID,AttDate,Period,OTKind,ShiftID,OTFrom56,OTTo56,ISNULL(V56Real,V56),Approved,V56,1,MealDeductHours
				-- FROM #tmpOT WHERE V56 > 0
				--HPSF insert giờ đã làm tròn
				INSERT INTO tblOTList (EmployeeID, OTCategoryID, OTDate, Period, OTKind, ShiftID, OTFrom, OTTo, OTHour, Approved, ApprovedHours, StatusID, MealDeductHours)
				SELECT EmployeeID, OTCategoryID, AttDate, Period, OTKind, ShiftID, OTFrom12, OTTo12, V12, Approved, V12, 1, MealDeductHours
				FROM #tmpOT
				WHERE V12 > 0
				
				UNION ALL
				
				SELECT EmployeeID, OTCategoryID, AttDate, Period, OTKind, ShiftID, OTFrom34, OTTo34, V34, Approved, V34, 1, MealDeductHours
				FROM #tmpOT
				WHERE V34 > 0
				
				UNION ALL
				
				SELECT EmployeeID, OTCategoryID, AttDate, Period, OTKind, ShiftID, OTFrom56, OTTo56, V56, Approved, V56, 1, MealDeductHours
				FROM #tmpOT
				WHERE V56 > 0

				IF (OBJECT_ID('TA_ProcessMain_ROUND_OT') IS NULL)
				BEGIN
					EXEC (
							'CREATE PROCEDURE TA_ProcessMain_ROUND_OT
(

  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output

)
as
begin
 SET NOCOUNT ON;
end'
							)
				END

				SET @StopUpdate = 0

				EXEC TA_ProcessMain_ROUND_OT @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

				IF @StopUpdate = 0
				BEGIN
					-- làm tròn OT theo quy tắc
					PRINT ''
				END

				IF @MATERNITY_OT = 1
					UPDATE tblOTList
					SET OTHour = OTHour + 1, ApprovedHours = ApprovedHours + 1
					FROM tblOTList ot
					INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.[Date]
					WHERE OTHour >= 7
						--AND ot.EmployeeID in (select EmployeeID from #tmpHasTAMaternity) and DATEPART(dw,ot.OTDate) = 1
						AND EXISTS (
							SELECT 1
							FROM #tmpHasTAMaternity m
							WHERE m.EmployeeID = ot.EmployeeID AND m.AttDate = ot.OTDate AND m.DayType > 0
							) AND StatusID <> 3
			END
			ELSE
			BEGIN
				DELETE tblOTList_CT
				FROM tblOTList_CT ot
				INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.[Date]

				--where not exists(select 1 from #OTNotOverwrite ov where ot.EmployeeID = ov.EmployeeID and ot.OTDate = ov.OTDate)
				INSERT INTO tblOTList_CT (EmployeeID, OTCategoryID, OTDate, OTKind, ShiftID, OTFrom, OTTo, OTHour, Approved, ApprovedHours, StatusID)
				SELECT EmployeeID, OTCategoryID, AttDate, OTKind, ShiftID, OTFrom12, OTTo12, ISNULL(v12Real, V12), Approved, V12, 1
				FROM #tmpOT
				WHERE V12 > 0
				
				UNION ALL
				
				SELECT EmployeeID, OTCategoryID, AttDate, OTKind, ShiftID, OTFrom34, OTTo34, V34, Approved, V34, 1
				FROM #tmpOT
				WHERE V34 > 0
				
				UNION ALL
				
				SELECT EmployeeID, OTCategoryID, AttDate, OTKind, ShiftID, OTFrom56, OTTo56, V56, Approved, V56, 1
				FROM #tmpOT
				WHERE V56 > 0

				-- làm tròn OT theo quy tắc
				UPDATE tblOTList_CT
				SET ApprovedHours = (ROUND((ApprovedHours + 0.5) / 0.5, 0) - 0.5) * 0.5 - 0.25
				FROM tblOTList_CT ot
				INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.[Date]
				WHERE ApprovedHours <> (ROUND((ApprovedHours + 0.5) / 0.5, 0) - 0.5) * 0.5 - 0.25 AND ot.StatusID <> 3

				IF @MATERNITY_OT = 1
					UPDATE tblOTList_CT
					SET OTHour = OTHour + 1, ApprovedHours = ApprovedHours + 1
					FROM tblOTList_CT ot
					INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.[Date]
					WHERE OTHour >= 7 AND ot.EmployeeID IN (
							SELECT EmployeeID
							FROM #tmpHasTAMaternity
							) AND DATEPART(dw, ot.OTDate) = 1 AND StatusID <> 3
			END

			--200%-> 210% neu truoc do co tang ca
			--update tblOTList set OTKind = 33 from tblOTList ot
			--inner join #ShiftInfo s on ot.ShiftID = s.ShiftID and s.isNightShift = 0
			--where exists(select 1 from #tblPendingTaProcessMain p where ot.EmployeeID = p.EmployeeID and ot.OTDate = p.Date)
			--and ot.OTKind = 22 and exists(select 1 from tblOTList o where ot.EmployeeID = o.EmployeeID and ot.OTDate = o.OTDate and ot.OTFrom = o.OTTo)
			--and isnull(ot.StatusID,0) <> 3
			IF (OBJECT_ID('TA_ProcessMain_Finish_OTCalculator') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_Finish_OTCalculator
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
 SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_Finish_OTCalculator @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			DROP TABLE #tmpHasTA_OT
		END
	END

	--end OT
	--cong 30p an chieu
	--lichien : duyet nhung don co dang ky
	UPDATE tblOTList
	SET Approved = 1, ApprovedHours = CASE 
			WHEN ot.ApprovedHours < lr.OTHours_Reg
				THEN ot.ApprovedHours
			ELSE lr.OTHours_Reg
			END, Identity_ID = lr.Identity_ID, OTHours_Reg = lr.OTHours_Reg
	FROM tblOTList ot
	INNER JOIN tblOTList_Register lr ON ot.EmployeeID = lr.EmployeeID AND ot.OTDate = lr.OTDate AND ot.OTKind = lr.OTKind AND ot.OTCategoryID = lr.OTCategoryID
	WHERE isnull(ot.StatusID, 1) <> 3 AND (ABS(DATEDIFF(mi, ot.OTFrom, lr.OTFrom)) <= 30 OR ABS(DATEDIFF(mi, ot.OTTo, lr.OTTo)) <= 30) AND ot.OTTo <> lr.OTFrom -- gio ket thuc = gio bat dau dang ky ( thuogn xay ra voi chu nhat , le di lam som hon dang ky)
		AND ot.OTFrom <> lr.OTTo AND EXISTS (
			SELECT 1
			FROM #tblPendingTaProcessMain p
			WHERE ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.DATE
			)

	SELECT EmployeeID, OTKind, OTDate, COUNT(OTKind) Cnt
	INTO #OTNonContinuous
	FROM tblOTList_Register ot
	WHERE EXISTS (
			SELECT 1
			FROM #tblPendingTaProcessMain p
			WHERE ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.DATE
			)
	GROUP BY EmployeeID, OTKind, OTDate
	HAVING COUNT(OTKind) > 1

	--cùng 1 mức tăng ca nhưng làm ở 2 khung giờ không liên tục
	IF EXISTS (
			SELECT *
			FROM #OTNonContinuous
			)
	BEGIN
		SELECT *
		INTO #tblOTList_Register
		FROM tblOTList_Register ot
		WHERE EXISTS (
				SELECT 1
				FROM #tblPendingTaProcessMain p
				WHERE ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.DATE
				)

		--approved -> delete
		DELETE lr
		FROM #tblOTList_Register lr
		INNER JOIN tblOTList ot ON ot.EmployeeID = lr.EmployeeID AND ot.OTDate = lr.OTDate AND ot.OTKind = lr.OTKind AND ot.OTCategoryID = lr.OTCategoryID
		WHERE isnull(ot.StatusID, 1) <> 3 AND (ABS(DATEDIFF(mi, ot.OTFrom, lr.OTFrom)) <= 30 OR ABS(DATEDIFF(mi, ot.OTTo, lr.OTTo)) <= 30) AND ot.OTTo <> lr.OTFrom -- gio ket thuc = gio bat dau dang ky ( thuogn xay ra voi chu nhat , le di lam som hon dang ky)
			AND ot.OTFrom <> lr.OTTo AND EXISTS (
				SELECT 1
				FROM #tblPendingTaProcessMain p
				WHERE ot.EmployeeID = p.EmployeeID AND ot.OTDate = p.DATE
				)

		UPDATE tblOTList
		SET ApprovedHours = CASE 
				WHEN ot.OTHour < ot.OTHours_Reg + lr.OTHours_Reg
					THEN ot.ApprovedHours
				ELSE ot.OTHours_Reg + lr.OTHours_Reg
				END, OTHours_Reg = lr.OTHours_Reg + ot.OTHours_Reg
		FROM tblOTList ot
		INNER JOIN #tblOTList_Register lr ON ot.EmployeeID = lr.EmployeeID AND ot.OTDate = lr.OTDate AND ot.OTKind = lr.OTKind AND ot.OTCategoryID = lr.OTCategoryID
		WHERE isnull(ot.StatusID, 1) <> 3 AND (ot.OTFrom <= lr.OTFrom OR ot.OTTo >= lr.OTTo)
	END

	--begin  Night Shift
	IF (OBJECT_ID('TA_ProcessMain_InsertOTAddition') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE TA_ProcessMain_InsertOTAddition
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)

as
begin
 SET NOCOUNT ON;
end'
				)
	END

	SET @StopUpdate = 0

	EXEC TA_ProcessMain_InsertOTAddition @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

	--begin ns, begin night shift
	IF (@StopUpdate = 0 AND @IsAuditAccount = 0)
	BEGIN
		DECLARE @IS_OT_IN_NIGHTSHIFT BIT, @NIGHT_SHIFT_START DATETIME, @NIGHT_SHIFT_STOP DATETIME, @Point1 INT, @Point2 INT, @Point3 INT, @Point4 INT

		BEGIN
			DECLARE @NS_ROUND_UNIT INT

			SET @NS_ROUND_UNIT = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'NS_ROUND_UNIT'
					)
			SET @NS_ROUND_UNIT = isnull(@NS_ROUND_UNIT, 30)

			IF @NS_ROUND_UNIT <= 0
				SET @NS_ROUND_UNIT = 1
			SET @IS_OT_IN_NIGHTSHIFT = (
					SELECT cast(value AS FLOAT)
					FROM tblParameter
					WHERE code = 'IS_OT_IN_NIGHTSHIFT'
					)
			SET @IS_OT_IN_NIGHTSHIFT = isnull(@IS_OT_IN_NIGHTSHIFT, 30)

			---------------------------------------------------------------------------------------------------
			CREATE TABLE #tmpNS (
				EmployeeID NVARCHAR(20), AttDate DATETIME, Period INT, ShiftID INT, DayType INT, AttStart DATETIME, AttEnd DATETIME, MiAttStart INT, -- Doi gio bat dau lam viec ra phut so voi AttDate
				MiAttEnd INT, -- Doi gio ket thuc lam viec ra phut so voi AttDate
				MiBreakStart INT, MiBreakEnd INT, MiWorkStart INT, -- Doi gio bat dau cua ca ra phut so voi AttDate
				MiWorkEnd INT, -- Doi gio ket thuc cua ca ra phut so voi AttDate
				MiNSStart INT, MiNSEnd INT, MiNSStartTmp INT, MiNSEndTmp INT, Point1 INT, Point2 INT, Point3 INT, Point4 INT, V12 FLOAT, V34 FLOAT, NSKind INT, NSValue FLOAT
				)

			--create table #NSSetting(NSKind int, DayType int, NSFrom time, NSTo Time,NSFromDate datetime, NSToDate DateTime, NSValue float)
			--insert into #NSSetting(NSKind,DayType,NSFrom,NSTo,NSFromDate,NSToDate,NSValue)
			--select NSKind,DayType,NSFrom,NSTo,NSFrom,NSTo,NSValue from tblNightShiftSetting
			--select * from #NSSetting return
			INSERT INTO #tmpNS (EmployeeID, AttDate, ShiftID, DayType, AttStart, AttEnd, MiAttStart, MiAttEnd, MiBreakStart, MiBreakEnd, MiWorkStart, MiWorkEnd, Period)
			SELECT ta.EmployeeID, ta.AttDate, ta.ShiftID, ta.DayType, ta.AttStart MinAttTime, ta.AttEnd MaxAttTime, ta.MiAttStart MinMiAttStart, ta.MiAttEnd MaxMiAttEnd, MiBreakStart, MiBreakEnd, ta.MiWorkStart MinMiWorkStart, ta.MiWorkEnd MaxMiWorkEnd, Period
			FROM #tmpHasTA ta
			WHERE ta.AttStart IS NOT NULL AND ta.AttEnd IS NOT NULL

			---------------------------------------Kiem tra
			DELETE tmp
			FROM #tmpNS tmp -- Xoa du lieu ko can tinh toan
			WHERE EXISTS (
					SELECT 1
					FROM tblNightShiftList ns
					WHERE tmp.EmployeeID = ns.EmployeeID AND tmp.AttDate = ns.[Date] AND ns.StatusID = 3
					)

			----------------------------------------------------------------------------------------------------------
			IF @IS_OT_IN_NIGHTSHIFT = 0 -- Neu thoi gian night shift khong bao gom thoi gian OT (vi da co loai OT 30% hoac 180,230...)
			BEGIN -- Khi do thoi gian de tinh night shift chi co the trong gio cua ca
				--DELETE FROM #tmpNS WHERE DayType <> 0 -- Xoa thoi gian ngay nghi (HolidayStatus <>0) do da duoc tinh trong OT
				UPDATE #tmpNS
				SET MiNSStart = MiAttStart
				WHERE MiAttStart >= MiWorkStart -- Di lam muon, gio bat dau tinh Nigh shift la gio vao thuc te MiAttStart

				UPDATE #tmpNS
				SET MiNSStart = MiWorkStart
				WHERE MiAttStart <= MiWorkStart -- Di lam som (co OT before), gio bat dau tinh night shift la gio vao cua ca MiWorkStart

				UPDATE #tmpNS
				SET MiNSEnd = MiAttEnd -- Di ve som, gio ket thuc tinh nightshift la gio ra thuc te MiAttEnd
				WHERE MiAttEnd <= MiWorkEnd

				UPDATE #tmpNS
				SET MiNSEnd = MiWorkEnd -- Di ve muon (co OT after), gio bat dau tinh night shift la gio ket thuc ca MiWorkEnd
				WHERE MiAttEnd > MiWorkEnd
			END
			ELSE ------------------- Thoi gian tinh NS bao gom ca thoi gian cua OT (vi ko co loai OT 30%, 180%,230%....)
			BEGIN --------------------Truong hop nay se lay thoi gian bat dau va ket thuc lam viec thuc te de tinh night shift
				-- OT trong NS thì đã được trợ cấp 30% lương của OT đó rồi, nên NS ko tinh cho ca thường nữa, chỉ tính cho ca đêm (Ca3)
				DELETE #tmpNS
				WHERE ShiftID NOT IN (
						SELECT ShiftID
						FROM tblShiftSetting
						WHERE datepart(hh, WorkStart) > datepart(hh, WorkEnd)
						)

				UPDATE #tmpNS
				SET MiNSStart = MiAttStart, MiNSEnd = MiAttEnd

				UPDATE #tmpNS
				SET MiNSStart = MiWorkStart
				WHERE MiNSStart < MiWorkStart

				UPDATE #tmpNS
				SET MiNSEnd = MiWorkEnd
				WHERE MiNSEnd > MiWorkEnd
			END

			----------------------------------------------Tinh night shift ---------------------------------
			SELECT DayType, NSKind, NSValue, datepart(hh, NSFrom) * 60 + datepart(mi, NSFrom) AS NSFrom, datepart(hh, NSTo) * 60 + datepart(mi, NSTo) AS NSTo
			INTO #tmpNSSetting
			FROM tblNightShiftSetting

			UPDATE #tmpNS
			SET Point1 = 0, Point2 = 0, Point3 = NSFrom, Point4 = NSTo, NSKind = s.NSKind
			FROM #tmpNS t
			INNER JOIN #tmpNSSetting s ON t.DayType = s.DayType

			-- Trong TH vat qua ngay` thi phai kiem tra 2 doan (Point1 den Point2, Point3 den Point4)
			-- VD:Khoang tu 0h - 6h va` khoang tu 22h den 6h+24h
			UPDATE #tmpNS
			SET Point2 = Point4, Point4 = Point4 + 24 * 60
			WHERE Point3 > Point4

			IF (OBJECT_ID('TA_ProcessMain_Finish_NightShift_SetPoint') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_Finish_NightShift_SetPoint
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_Finish_NightShift_SetPoint @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			-------1: Night Shift trong khoang Point1 den Point2:
			UPDATE #tmpNS
			SET MiNSStartTmp = MiNSStart
			WHERE MiNSStart >= Point1

			UPDATE #tmpNS
			SET MiNSStartTmp = Point1
			WHERE MiNSStart < Point1

			UPDATE #tmpNS
			SET MiNSEndTmp = Point2
			WHERE MiNSEnd >= Point2

			UPDATE #tmpNS
			SET MiNSEndTmp = MiNSEnd
			WHERE MiNSEnd < Point2

			--select * from #tmpNS
			UPDATE #tmpNS
			SET V12 = MiNSEndTmp - MiNSStartTmp

			UPDATE #tmpNS
			SET V12 = (MiNSEndTmp - MiBreakEnd) + (MiBreakStart - MiNSStartTmp)
			WHERE MiBreakStart > MiNSStartTmp AND MiBreakEnd < MiNSEndTmp --lam day du

			UPDATE #tmpNS
			SET V12 = (
					CASE 
						WHEN MiNSEndTmp >= MiBreakStart
							THEN MiBreakStart
						ELSE MiNSEndTmp
						END
					) - MiNSStartTmp
			WHERE MiBreakStart >= MiNSStartTmp AND MiNSEndTmp <= MiBreakEnd --lam toi gio nghi giua gio roi ve

			UPDATE #tmpNS
			SET V12 = MiNSEndTmp - (
					CASE 
						WHEN MiNSStartTmp >= MiBreakEnd
							THEN MiNSStartTmp
						ELSE MiBreakEnd
						END
					)
			WHERE MiNSStartTmp >= MiBreakStart AND MiNSEndTmp > MiBreakEnd --vao lam sau khi nghi giua gio

			UPDATE #tmpNS
			SET V12 = (CAST(ISNULL(V12, 0) AS INT) / @NS_ROUND_UNIT) * (CAST(@NS_ROUND_UNIT AS FLOAT) / 60) --(CAST(MiNSEndTmp - MiNSStartTmp AS INT)/@NS_ROUND_UNIT) * (CAST(@NS_ROUND_UNIT AS FLOAT)/60)

			UPDATE #tmpNS
			SET V12 = 0
			WHERE isnull(V12, 0) <= 0

			--------2: Night shift trong khoang Point3 den Point4
			UPDATE #tmpNS
			SET MiNSStartTmp = MiNSStart
			WHERE MiNSStart >= Point3

			UPDATE #tmpNS
			SET MiNSStartTmp = Point3
			WHERE MiNSStart < Point3

			UPDATE #tmpNS
			SET MiNSEndTmp = Point4
			WHERE MiNSEnd >= Point4

			UPDATE #tmpNS
			SET MiNSEndTmp = MiNSEnd
			WHERE MiNSEnd < Point4

			UPDATE #tmpNS
			SET V34 = MiNSEndTmp - MiNSStartTmp

			UPDATE #tmpNS
			SET V34 = (MiNSEndTmp - MiBreakEnd) + (MiBreakStart - MiNSStartTmp)
			WHERE MiBreakStart > MiNSStartTmp AND MiBreakEnd < MiNSEndTmp --lam day du

			UPDATE #tmpNS
			SET V34 = (
					CASE 
						WHEN MiNSEndTmp >= MiBreakStart
							THEN MiBreakStart
						ELSE MiNSEndTmp
						END
					) - MiNSStartTmp
			WHERE MiBreakStart >= MiNSStartTmp AND MiNSEndTmp <= MiBreakEnd --lam toi gio nghi giua gio roi ve

			UPDATE #tmpNS
			SET V34 = MiNSEndTmp - (
					CASE 
						WHEN MiNSStartTmp >= MiBreakEnd
							THEN MiNSStartTmp
						ELSE MiBreakEnd
						END
					)
			WHERE MiNSStartTmp >= MiBreakStart AND MiNSEndTmp > MiBreakEnd --vao lam sau khi nghi giua gio

			UPDATE #tmpNS
			SET V34 = (CAST(ISNULL(V34, 0) AS INT) / @NS_ROUND_UNIT) * (CAST(@NS_ROUND_UNIT AS FLOAT) / 60)

			--UPDATE #tmpNS SET V34 = (CAST(MiNSEndTmp - MiNSStartTmp AS INT)/@NS_ROUND_UNIT) * (CAST(@NS_ROUND_UNIT AS FLOAT)/60)
			UPDATE #tmpNS
			SET V34 = 0
			WHERE isnull(V34, 0) <= 0

			-----------Night shift tong:
			UPDATE #tmpNS
			SET NSValue = V12 + V34

			----------------------------Xoa nhung ban ghi ko co night shift ----------------------------
			DELETE
			FROM #tmpNS
			WHERE NSValue <= 0 OR NSValue IS NULL

			IF (OBJECT_ID('TA_ProcessMain_ROUND_NS') IS NULL)
			BEGIN
				EXEC (
						'CREATE PROCEDURE TA_ProcessMain_ROUND_NS

(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)

as
begin
 SET NOCOUNT ON;
end'
						)
			END

			SET @StopUpdate = 0

			EXEC TA_ProcessMain_ROUND_NS @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

			IF @StopUpdate = 0
			BEGIN
				UPDATE #tmpNS
				SET NSValue = ROUND(NSValue, 4)
			END

			-- Note: sau nay co the phai dieu chinh Point, point 2, Point3, Point4 theo shift nhu gia tri AdjustTime khi tinh overtime, It's so easy :D
			DELETE #tmpNS
			WHERE NSKind <> 1

			-----------------------------Ket thuc tinh ns, gio trong bang #tmpNS chi bao gom nhung ngay, nhung nguoi co OT.
			--Xoa du lieu truoc khi insert
			DELETE tblNightShiftList
			FROM tblNightShiftList ot
			INNER JOIN #tblPendingTaProcessMain p ON ot.EmployeeID = p.EmployeeID AND ot.DATE = p.DATE
			WHERE StatusID <> 3

			INSERT INTO tblNightShiftList (EmployeeID, DATE, Period, NSKind, ShiftID, AttStart, AttEnd, Hours, Approval, HourApprove, StatusID)
			SELECT EmployeeID, AttDate, min(Period), min(NSKind), min(ShiftID), min(DATEADD(mi, tmp.MiNSStartTmp, tmp.AttDate)), max(DATEADD(mi, tmp.MiNSEndTmp, tmp.AttDate)), sum(NSValue), 1, sum(NSValue), 1
			FROM #tmpNS tmp
			WHERE NOT EXISTS (
					SELECT 1
					FROM tblNightShiftList ns
					WHERE ns.EmployeeID = tmp.EmployeeID AND ns.DATE = tmp.AttDate
					) AND NSValue > 0.499999
			GROUP BY EmployeeID, AttDate

			-- làm tròn OT theo quy tắc
			/*
 2.1, 2.2 tính 2
 , 2.3 2.4 - 2.5- 2.6, 2.7  tính 2.5
 , 2.8 2.9, 3, 3.1, 3.2, 3.3 tính 3
 */
			--UPDATE tblNightShiftList SET HourApprove = (ROUND((HourApprove+0.5)/0.5,0)-0.5)*0.5-0.25 FROM tblNightShiftList ot INNER JOIN #tmpNS ta ON ot.EmployeeID = ta.EmployeeID AND ot.Date = ta.AttDate
			DROP TABLE #tmpNS
		END
	END

	--end Night Shift
	IF (OBJECT_ID('TA_ProcessMain_ConfigTAData') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE TA_ProcessMain_ConfigTAData
(
  @FromDate datetime
 ,@ToDate datetime
 ,@LoginID int
 ,@IsAuditAccount bit
 ,@StopUpdate bit output
)
as
begin
 SET NOCOUNT ON;
end'
				)
	END

	SET @StopUpdate = 0

	EXEC TA_ProcessMain_ConfigTAData @FromDate = @FromDate, @ToDate = @ToDate, @LoginID = @LoginID, @IsAuditAccount = @IsAuditAccount, @StopUpdate = @StopUpdate OUTPUT

	ClearPendingOvertime:

	DELETE tblRunningTaProcessMain
	WHERE LoginID = @LoginID

	DELETE tblPendingTaProcessMain
	FROM tblPendingTaProcessMain p
	WHERE p.DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tmpEmployee e
			WHERE p.EmployeeID = e.EmployeeID
			)

	--exec ('Enable trigger ALL on tblWSchedule')
	--exec ('Enable trigger ALL on tblHasTA')
	--exec ('Enable trigger ALL on tblLvhistory')
	PRINT 'eof'
		--exec sp_ReCalculate_TAData @LoginID=3, @Fromdate='20250801', @ToDate='20250831', @EmployeeID_Pram='-1', @RunShiftDetector=0, @RunTA_Precess_Main=1
END
GO

IF object_id('[dbo].[EmpInsuranceMonthly_List]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[EmpInsuranceMonthly_List] as select 1')
GO

--exec EmpInsuranceMonthly_List 8,2022,3
ALTER PROCEDURE [dbo].[EmpInsuranceMonthly_List] @Month INT, @Year INT, @LoginID INT, @CalFromSalCal BIT = 0, @CalculateRetro BIT = 0, @languageId VARCHAR(2) = 'EN', @EmployeeID VARCHAR(20) = '-1', @OptionView INT = 0
AS
BEGIN
	--set mặc định cho thằng bit tính retro cho tháng trước
	SELECT @CalculateRetro = ISNULL(@CalculateRetro, 0) --, @CalFromSalCal = ISNULL(@CalFromSalCal,0)

	DECLARE @nextMonth INT = @month + 1, @nextYear INT = @Year

	IF (@nextMonth = 13)
	BEGIN
		SET @nextMonth = 1
		SET @nextYear += 1
	END -- lấy next month ra để tý còn update

	DECLARE @SalStart DATETIME, @SalStop DATETIME, @SIDate DATETIME

	SELECT @SalStart = FromDate, @SalStop = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT @SIDate = cast(cast(Year(@SalStop) AS NVARCHAR(20)) + '-' + cast(Month(@SalStop) AS NVARCHAR(20)) + '-15' AS DATE)

	SELECT te.EmployeeID, ISNULL(te.RenewHireDate, te.HireDate) HireDate, DepartmentID, PositionID, te.ProbationEndDate, te.EmployeeTypeID, EmployeeStatusID, TerminateDate, isnull(dateadd(dd, - 1, TerminateDate), '9999-12-31') LastWorkingDate, CAST(NULL AS DATE) AS StatusChangedDate, CAST(NULL AS DATE) AS StatusEndDate, isnull(te.EmpInsuranceStatusID, - 1) EmpInsuranceStatusID, CAST(NULL AS DATE) FormalDate
	INTO #tmpEmpInsList_WorkingOn
	FROM dbo.fn_vtblEmployeeList_Bydate(@SalStop, @EmployeeID, @LoginID) te
	WHERE ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 0) = 1 AND ISNULL(te.isForeign, 0) = 0) OR (ISNULL(@OptionView, 0) = 2 AND ISNULL(te.isForeign, 0) = 1)

	SELECT *
	INTO #tmpEmpInsList
	FROM #tmpEmpInsList_WorkingOn

	SELECT *
	INTO #fn_EmployeeStatus_ByDate
	FROM dbo.fn_EmployeeStatus_ByDate(@SalStop)

	UPDATE #tmpEmpInsList_WorkingOn
	SET FormalDate = CASE 
			WHEN ProbationEndDate > HireDate
				THEN DATEADD(DD, 1, ProbationEndDate)
			ELSE HireDate
			END

	-- nếu tính insurance bình thường thì sẽ kiểm tra khóa thôi
	IF @CalculateRetro = 0
	BEGIN
		DELETE #tmpEmpInsList
		FROM #tmpEmpInsList te
		WHERE EXISTS (
				SELECT 1
				FROM tblSal_Lock sl
				WHERE Month = @Month AND Year = @Year AND sl.EmployeeID = te.EmployeeID
				)
	END
	ELSE IF @CalculateRetro = 1
	BEGIN -- nếu tính lương retro thì cần kiểm tra khóa tháng sau nhé
		DELETE #tmpEmpInsList
		FROM #tmpEmpInsList te
		WHERE EXISTS (
				SELECT 1
				FROM tblSal_Lock sl
				WHERE Month = @nextMonth AND Year = @nextYear AND sl.EmployeeID = te.EmployeeID
				)

		-- kiểm tra coi nó có nằm trong danh sách tính lương retro ko, bởi ko thay đổi công thì đâu có làm gì đâu mà :D
		DELETE #tmpEmpInsList
		WHERE EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_AttendanceData_Retro re
				WHERE re.Month = @Month AND re.Year = @Year
				
				UNION
				
				SELECT EmployeeID
				FROM tblCustomAttendanceData
				WHERE Month = @Month AND Year = @Year AND IsRetro = 1 AND Approved = 1
				)
	END

	-- nếu ko có ai thì thôi khỏi làm gì
	IF (
			SELECT COUNT(1)
			FROM #tmpEmpInsList
			) = 0
		GOTO Finished

	CREATE TABLE #InsuranceTmp (EmployeeID VARCHAR(20), Month INT, Year INT, IsEmpSI BIT, IsEmpHI BIT, IsEmpUI BIT, IsComSI BIT, IsComHI BIT, IsComUI BIT, Salary MONEY, HIIncome MONEY, SIIncome MONEY, UIIncome MONEY, EmployeeStatusID INT, EmployeeSI MONEY, EmployeeHI MONEY, EmployeeUI MONEY, CompanySI MONEY, CompanySM MONEY, CompanyHI MONEY, CompanyUI MONEY, OtherCompanyIns BIT, ExpatIns BIT, Notes NVARCHAR(max), InsPaymentStatus INT DEFAULT 0, SalaryHistoryID BIGINT, EmployeeTotal MONEY, CompanyTotal MONEY, Total MONEY, CurrencyCode VARCHAR(20), ExchangeRate MONEY, InsStatusDefault BIT)

	DECLARE @StopUpdate BIT = 0

	-- nếu công ty không sử dụng module bảo hiểm
	IF NOT EXISTS (
			SELECT 1
			FROM tblSISummaryInfo_BHXH s
			WHERE s.Month = @Month AND Year = @Year AND EmployeeID IN (
					SELECT EmployeeID
					FROM #tmpEmpInsList
					)
			)
	BEGIN
		UPDATE #tmpEmpInsList
		SET EmployeeStatusID = stt.EmployeeStatusID, StatusChangedDate = stt.ChangedDate, StatusEndDate = stt.StatusEndDate, TerminateDate = CASE 
				WHEN stt.EmployeeStatusID = 20
					THEN stt.ChangedDate
				ELSE NULL
				END
		FROM #tmpEmpInsList te
		INNER JOIN #fn_EmployeeStatus_ByDate stt ON te.EmployeeID = stt.EmployeeID

		UPDATE #tmpEmpInsList
		SET StatusChangedDate = DATEADD(day, - 1, StatusChangedDate)
		WHERE EmployeeStatusID = 20 --nghi viec thi phai tru 1 ngay de giong voi thai san

		DELETE #tmpEmpInsList
		FROM #tmpEmpInsList e
		WHERE TerminateDate <= @SalStart --nghi viec tu thang truoc roi

		--delete #tmpEmpInsList where HireDate > @SIDate --lam lam sau ngay 15
		--delete #tmpEmpInsList where TerminateDate > @SIDate --lam lam sau ngay 15					
		--delete from #tmpEmpInsList where EmployeeStatusID = 1 and StatusChangedDate < @SalStart and StatusEndDate > @SalStop --thang sau moi het thai san
		DECLARE @SI_NEED_INPUTSALARY BIT, @SI_USING_CONTRACT BIT

		SET @SI_NEED_INPUTSALARY = (
				SELECT Value
				FROM tblParameter
				WHERE Code = 'SI_NEED_INPUTSALARY'
				)
		SET @SI_NEED_INPUTSALARY = ISNULL(@SI_NEED_INPUTSALARY, 1)
		SET @SI_USING_CONTRACT = (
				SELECT Value
				FROM tblParameter
				WHERE Code = 'SI_USING_CONTRACT'
				)
		SET @SI_USING_CONTRACT = ISNULL(@SI_USING_CONTRACT, 1)

		INSERT INTO #InsuranceTmp (EmployeeID, EmployeeStatusID, Month, Year, Salary, HIIncome, SIIncome, UIIncome, IsEmpHI, IsEmpUI, IsEmpSI, IsComHI, IsComUI, IsComSI, InsPaymentStatus, SalaryHistoryID, CurrencyCode, ExchangeRate)
		SELECT te.EmployeeID, te.EmployeeStatusID, @Month, @Year, e.Salary, e.SI_Salary, e.SI_Salary, e.UI_Salary, 1, 1, 1, 1, 1, 1, 0, e.SalaryHistoryID, sh.CurrencyCode, sh.ExchangeRate_Contract
		FROM #tmpEmpInsList te
		LEFT JOIN dbo.fn_CurrentSISalary_byDate(@SIDate, @LoginID) e ON e.EmployeeID = te.EmployeeID
		LEFT JOIN tblSalaryHistory sh ON e.SalaryHistoryID = sh.SalaryHistoryID
		WHERE NOT EXISTS (
				SELECT 1
				FROM tblSal_Insurance si
				WHERE te.EmployeeID = si.EmployeeID AND si.Month = @Month AND si.Year = @Year AND si.Approval = 1
				)

		UPDATE ta1
		SET InsPaymentStatus = ISNULL(ta2.InsPaymentStatus, 0)
		FROM #InsuranceTmp ta1
		INNER JOIN tblSal_Insurance ta2 ON ta1.EmployeeID = ta2.EmployeeID AND ta2.Month = @Month AND ta2.Year = @Year

		--can cu vao hop dong truoc (neu co)	
		IF @SI_USING_CONTRACT = 1
		BEGIN
			UPDATE #InsuranceTmp
			SET IsEmpSI = ISNULL(c.EmpSI, 0), IsEmpHI = ISNULL(c.EmpHI, 0), IsEmpUI = ISNULL(c.EmpUI, 0), IsComSI = ISNULL(CompSI, 0), IsComHI = ISNULL(c.CompHI, 0), IsComUI = ISNULL(CompUI, 0), Notes = CASE 
					WHEN c.EmployeeID IS NOT NULL
						THEN CASE 
								WHEN @languageId = 'VN'
									THEN N'Dựa vào hợp đồng'
								ELSE 'Follow labour contract'
								END
					ELSE CASE 
							WHEN @languageId = 'VN'
								THEN N'Chưa có hợp đồng'
							ELSE 'Has no contract!'
							END
					END
			FROM #InsuranceTmp tmp
			LEFT JOIN (
				SELECT c.EmployeeID, cis.*
				FROM dbo.fn_CurrentContractListByDate(@SIDate) c
				INNER JOIN tblLabourContract lb ON c.ContractID = lb.ContractID
				INNER JOIN ContractInsuranceStatus cis ON isnull(lb.InsuranceStatusID, - 1) = cis.InsuranceStatusID
				) c ON tmp.EmployeeID = c.EmployeeID
			WHERE InsPaymentStatus = 0
		END

		UPDATE #InsuranceTmp
		SET SIIncome = 0, HIIncome = 0, UIIncome = 0, IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0, Notes = CASE 
				WHEN @languageId = 'VN'
					THEN N'Không có lương đóng BH'
				ELSE 'Empty Insurance salary!'
				END + ISNULL(' - ' + Notes, '')
		WHERE (SalaryHistoryID IS NULL OR ISNULL(SIIncome, 0) = 0)

		--Khách hàng không mua module bảo hiểm phải nhập lương đóng BH hay tự động tính theo công thức ? 1: bắt buộc nhập mới đóng, 0: tự động tính, nếu muốn bỏ thì tick không tham gia
		UPDATE #InsuranceTmp
		SET SIIncome = 0, HIIncome = 0, UIIncome = 0, Notes = CASE 
				WHEN @languageId = 'VN'
					THEN N'Chưa nhập lương đóng BH'
				ELSE 'Insurance salary not inputted!'
				END + ISNULL(' - ' + Notes, '')
		FROM #InsuranceTmp t
		INNER JOIN tblSalaryHistory sh ON t.SalaryHistoryID = sh.SalaryHistoryID
		WHERE (@SI_NEED_INPUTSALARY = 1) AND ISNULL(sh.InsSalary, 0) = 0 AND SIIncome <> 0

		/*--nghi viec, thai san thi ko khai bao nua
		UPDATE #InsuranceTmp SET IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0
			, Notes =
			case when @languageId = 'VN'
			then   N'Trạng thái làm việc thay đổi' else 'Working Status changed' end
	
		from #InsuranceTmp t
		inner join #tmpEmpInsList te on t.EmployeeID = te.EmployeeID
		inner join tblEmployeeStatus stt on te.EmployeeStatusID = stt.EmployeeStatusID
			where /*StatusChangedDate <= @SIDate and*/ stt.CutSI = 1 and InsPaymentStatus = 0
		
		--van con thai san trong thang
		UPDATE #InsuranceTmp SET IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0
		, Notes =
		case when @languageId = 'VN'
			then N'Vẫn còn thai sản' else 'Still maternity period' end
		from #InsuranceTmp t inner join #tmpEmpInsList te on t.EmployeeID = te.EmployeeID
		where te.EmployeeStatusID = 1 and StatusEndDate <= @SalStop
		*/
		-- nếu nghỉ ko lương >=14 ngày thì ko đóng
		-- đoạn xxxx này chỉ khác ở chỗ tên bảng thôi nhé  :tblSal_AttendanceData
		UPDATE #InsuranceTmp
		SET IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0, Notes = 'probation'
		FROM #InsuranceTmp t
		WHERE EXISTS (
				SELECT 1
				FROM #tmpEmpInsList te
				WHERE t.EmployeeID = te.EmployeeID AND te.ProbationEndDate >= @SIDate
				)

		-- SELECT ws.EmployeeID, ws.ScheduleDate, ws.HolidayStatus, ta.s_WorkingTime AS WorkingTime
		-- INTO #PaidDayJoinINS
		-- FROM tblWSchedule ws
		-- INNER JOIN #tmpEmpInsList te ON ws.EmployeeID = te.EmployeeID
		-- LEFT JOIN (
		-- 	SELECT EmployeeID, AttDate, sum(WorkingTime) s_WorkingTime
		-- 	FROM tblHasTA
		-- 	GROUP BY EmployeeID, AttDate
		-- 	) ta ON ws.EmployeeID = ta.EmployeeID AND ws.ScheduleDate = ta.AttDate AND ws.HolidayStatus = 0
		-- WHERE ws.ScheduleDate BETWEEN @SalStart AND @SalStop AND ws.ScheduleDate BETWEEN te.FormalDate AND te.LastWorkingDate
		-- UPDATE #PaidDayJoinINS
		-- SET WorkingTime = isnull(p.WorkingTime, 0) + isnull(lv.s_LvAmount, 0)
		-- FROM #PaidDayJoinINS p
		-- INNER JOIN (
		-- 	SELECT lv.EmployeeID, lv.LeaveDate, sum(lv.LvAmount / 100.0 * lt.PaidRate) s_LvAmount
		-- 	FROM tblLvHistory lv
		-- 	INNER JOIN tblLeaveType lt ON lv.LeaveCode = lt.LeaveCode AND lt.PaidRate > 0
		-- 	GROUP BY lv.EmployeeID, lv.LeaveDate
		-- 	) lv ON p.EmployeeID = lv.EmployeeID AND p.ScheduleDate = lv.LeaveDate AND p.HolidayStatus IN (0, 2)
		--TRIPOD
		--TRIPOD
		EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 0

		SELECT Year, Month, a.EmployeeID, SUM(WorkingHrs_Total) WorkingHrs_Total, SUM(WorkingDays_Total) WorkingDays_Total, SUM(PaidLeaveHrs_Total) PaidLeaveHrs_Total, SUM(PaidLeaveDays_Total) PaidLeaveDays_Total, Std_Hour_PerDays
		INTO #AttendanceSummary
		FROM tblAttendanceSummary a
		INNER JOIN #tmpEmpInsList_WorkingOn te ON a.EmployeeID = te.EmployeeID
		WHERE Year = @Year AND Month = @Month
		GROUP BY Year, Month, a.EmployeeID, Std_Hour_PerDays

		UPDATE #InsuranceTmp
		SET InsStatusDefault = 1
		WHERE InsPaymentStatus = 0

		-- UPDATE #InsuranceTmp
		-- SET IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0, Notes = isnull(Notes, N'Nghỉ không lương >= 14 ngày'), InsPaymentStatus = CASE
		-- 		WHEN t.InsStatusDefault = 1 AND te.TerminateDate > te.FormalDate
		-- 			THEN 7
		-- 		ELSE t.InsPaymentStatus
		-- 		END
		-- FROM #InsuranceTmp t
		-- LEFT JOIN #tmpEmpInsList te ON t.EmployeeID = te.EmployeeID
		-- LEFT JOIN tblWorkingDaySetting w ON w.EmployeeTypeID = te.EmployeeTypeID AND w.Year = @Year AND w.Month = @Month
		-- LEFT JOIN (
		-- 	SELECT EmployeeID, sum(WorkingTime / 8.0) TotalPaidDays
		-- 	FROM #PaidDayJoinINS
		-- 	GROUP BY EmployeeID
		-- 	) sal ON t.EmployeeID = sal.EmployeeID
		-- WHERE w.WorkingDays_Std - isnull(sal.TotalPaidDays, 0) >= 14
		UPDATE #InsuranceTmp
		SET IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0, Notes = isnull(Notes, N'Nghỉ không lương >= 14 ngày'), InsPaymentStatus = CASE 
				WHEN t.InsStatusDefault = 1 AND te.TerminateDate > te.FormalDate
					THEN 7
				ELSE t.InsPaymentStatus
				END
		FROM #InsuranceTmp t
		LEFT JOIN #tmpEmpInsList te ON t.EmployeeID = te.EmployeeID
		LEFT JOIN tblWorkingDaySetting w ON w.EmployeeTypeID = te.EmployeeTypeID AND w.Year = @Year AND w.Month = @Month
		LEFT JOIN (
			SELECT EmployeeID, ISNULL(WorkingHrs_Total / Std_Hour_PerDays, 0) + ISNULL(PaidLeaveHrs_Total / Std_Hour_PerDays, 0) TotalPaidDays
			FROM #AttendanceSummary
			) sal ON t.EmployeeID = sal.EmployeeID
		WHERE w.WorkingDays_Std - isnull(sal.TotalPaidDays, 0) >= 14
			-- hết đoạn xxxx này chỉ khác ở chỗ tên bảng thôi nhé  :tblSal_AttendanceData
	END
	ELSE -- su dung menu khai bao bao hiem hang thang
	BEGIN
		INSERT INTO #InsuranceTmp (EmployeeID, EmployeeStatusID, Month, Year, Salary, HIIncome, SIIncome, UIIncome, IsEmpSI, IsEmpHI, IsEmpUI, IsComSI, IsComHI, IsComUI)
		SELECT e.EmployeeID, stt.EmployeeStatusID, @Month, @Year, e.Salary, e.SI_Salary, e.SI_Salary, e.UI_Salary, 1, 1, 1, 1, 1, 1
		FROM tblSISummaryInfo_BHXH e
		INNER JOIN #tmpEmpInsList te ON e.EmployeeID = te.EmployeeID AND e.Month = @Month AND e.Year = @Year
		LEFT JOIN #fn_EmployeeStatus_ByDate stt ON te.EmployeeID = stt.EmployeeID
		WHERE e.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_Insurance
				WHERE Approval = 1 AND Month = @Month AND Year = @Year
				)
	END

	SELECT cs.*
	INTO #tblCurrencySetting
	FROM (
		SELECT CurrencyCode, max(DateEffect) AS DateEffect
		FROM tblCurrencySetting cs
		GROUP BY cs.CurrencyCode
		) m
	INNER JOIN tblCurrencySetting cs ON m.CurrencyCode = cs.CurrencyCode AND cs.DateEffect = m.DateEffect

	UPDATE #InsuranceTmp
	SET ExchangeRate = ISNULL(ins.ExchangeRate, cs.ExchangeRate), Salary = Salary * ISNULL(ins.ExchangeRate, cs.ExchangeRate), HIIncome = HIIncome * ISNULL(ins.ExchangeRate, cs.ExchangeRate), SIIncome = SIIncome * ISNULL(ins.ExchangeRate, cs.ExchangeRate), UIIncome = UIIncome * ISNULL(ins.ExchangeRate, cs.ExchangeRate)
	FROM #InsuranceTmp ins
	INNER JOIN #tblCurrencySetting cs ON ins.CurrencyCode = cs.CurrencyCode
	WHERE isnull(ins.CurrencyCode, 'VND') <> 'VND'

	INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID)
	SELECT N'Tỷ giá', N'Vui lòng nhập tỷ giá: ' + ins.CurrencyCode, @LoginID
	FROM #InsuranceTmp ins
	WHERE isnull(ins.CurrencyCode, 'VND') <> 'VND' AND ExchangeRate IS NULL

	--khai bao bao hiem dua vao setup ben thong tin nhan vien
	UPDATE #InsuranceTmp
	SET IsEmpSI = ISNULL(c.EmpSI, 0), IsEmpHI = ISNULL(c.EmpHI, 0), IsEmpUI = ISNULL(c.EmpUI, 0), IsComSI = ISNULL(CompSI, 0), IsComHI = ISNULL(c.CompHI, 0), IsComUI = ISNULL(CompUI, 0)
	FROM #InsuranceTmp tmp
	INNER JOIN #tmpEmpInsList te ON tmp.EmployeeID = te.EmployeeID
	INNER JOIN ContractInsuranceStatus c ON te.EmpInsuranceStatusID = c.InsuranceStatusID
	WHERE isnull(te.EmpInsuranceStatusID, - 1) <> - 1 --bat thuong moi xu ly, chu binh thuong thi "kemedi"

	INSERT #InsuranceTmp (EmployeeID, EmployeeStatusID, Month, Year, Salary, HIIncome, SIIncome, UIIncome, IsEmpHI, IsEmpUI, IsEmpSI, IsComHI, IsComUI, IsComSI, InsPaymentStatus, SalaryHistoryID)
	SELECT te.EmployeeID, te.EmployeeStatusID, @Month, @Year, e.Salary, ins.SIIncome, ins.SIIncome, ins.UIIncome, 1, 1, 1, 1, 1, 1, ins.InsPaymentStatus, e.SalaryHistoryID
	FROM tblSal_Insurance ins
	INNER JOIN #tmpEmpInsList te ON ins.EmployeeID = te.EmployeeID
	LEFT JOIN dbo.fn_CurrentSISalary_byDate(@SIDate, @LoginID) e ON e.EmployeeID = te.EmployeeID
	LEFT JOIN tblSalaryHistory sh ON e.SalaryHistoryID = sh.SalaryHistoryID
	WHERE ins.Month = @Month AND ins.Year = @Year AND ins.InsPaymentStatus = 5

	-- select * from Insurance_Payment_Status
	--xu ly Payment status
	UPDATE #InsuranceTmp
	SET IsComSI = 1, IsComHI = 1, IsComUI = 1, IsEmpSI = 1, IsEmpHI = 1, IsEmpUI = 1
	WHERE InsPaymentStatus IN (1, 5) --dong day du

	UPDATE #InsuranceTmp
	SET IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0
	WHERE InsPaymentStatus = 2 --cty dong het thi setup nhan vien ve 0  ==> ko nen setup ca phan cua cty vi con can cu vao hop dong nua

	UPDATE #InsuranceTmp
	SET IsComSI = 0, IsComHI = 0, IsComUI = 0
	WHERE InsPaymentStatus = 3 --nhan vien dong het thi nguoc voi cty

	UPDATE #InsuranceTmp
	SET IsComSI = 0, IsComHI = 0, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 0, IsEmpUI = 0
	WHERE InsPaymentStatus = 4 --khong dong bh

	UPDATE #InsuranceTmp
	SET IsEmpSI = 0, IsEmpUI = 0
	WHERE InsPaymentStatus = 6 -- Nhân viên chỉ đóng bảo hiểm ý tế

	UPDATE #InsuranceTmp
	SET IsComSI = 0, IsComHI = 1, IsComUI = 0, IsEmpSI = 0, IsEmpHI = 1, IsEmpUI = 0
	WHERE InsPaymentStatus = 7 --truy thu 4.5%

	IF (OBJECT_ID('EmpInsuranceMonthly_BeforeCalculate') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE EmpInsuranceMonthly_BeforeCalculate
(
	 @Month int
	,@Year int
	,@LoginID int
	,@CalFromSalCal bit = 0
	,@StopUpdate bit output
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUpdate = 0

	EXEC EmpInsuranceMonthly_BeforeCalculate @Month = @Month, @Year = @Year, @LoginID = @LoginID, @CalFromSalCal = @CalFromSalCal, @StopUpdate = @StopUpdate OUTPUT

	--xu ly muc luong tran dong bao hiem
	UPDATE #InsuranceTmp
	SET SIIncome = CASE 
			WHEN SIIncome <= SI_Salary
				THEN SIIncome
			ELSE SI_Salary
			END, HIIncome = CASE 
			WHEN HIIncome <= HI_Salary
				THEN HIIncome
			ELSE HI_Salary
			END
	--,UIIncome = CASE WHEN UIIncome <= UI_Salary THEN UIIncome ELSE UI_Salary END
	FROM #InsuranceTmp ins
	CROSS JOIN (
		SELECT SI_Salary, HI_Salary, UI_Salary
		FROM dbo.tblSI_CeilSalary AS tscs
		WHERE (
				EffectiveDate = (
					SELECT MAX(EffectiveDate) AS Expr1
					FROM dbo.tblSI_CeilSalary tmp
					WHERE tmp.EffectiveDate <= @SIDate
					)
				)
		) tmp

	--tringuyen
	UPDATE i
	SET UIIncome = c.Salary * 20
	FROM #InsuranceTmp i
	LEFT JOIN tblSalaryHistory sal ON i.SalaryHistoryID = sal.SalaryHistoryID
	LEFT JOIN dbo.fn_CurrentBaseSalRegionalByDate(@SIDate) c ON sal.BaseSalRegionalID = c.BaseSalRegionalID
	WHERE i.UIIncome > c.Salary * 20

	--Tinh luong Insurance
	UPDATE #InsuranceTmp
	SET EmployeeSI = ROUND(SIIncome * p.SI_EmpPercent / 100.0, 0), CompanySI = ROUND(SIIncome * p.SI_CompPercent / 100.0, 0), CompanySM = ROUND(SIIncome * p.SM_CompPercent / 100.0, 0), EmployeeHI = ROUND(HIIncome * p.HI_EmpPercent / 100.0, 0), CompanyHI = ROUND(HIIncome * p.HI_CompPercent / 100.0, 0), EmployeeUI = ROUND(UIIncome * p.UI_EmpPercent / 100.0, 0), CompanyUI = ROUND(UIIncome * p.UI_CompPercent / 100.0, 0)
	FROM #InsuranceTmp tmp
	CROSS JOIN dbo.fn_CurrentInsurancePercentage(@SIDate) p

	--cong tru neu chi dong 1 ben
	UPDATE #InsuranceTmp
	SET EmployeeSI = EmployeeSI * IsEmpSI + CompanySI * ~ IsComSI + CompanySM * ~ IsComSI, CompanySI = CompanySI * IsComSI + EmployeeSI * ~ IsEmpSI, EmployeeHI = EmployeeHI * IsEmpHI + CompanyHI * ~ IsComHI, CompanyHI = CompanyHI * IsComHI + EmployeeHI * ~ IsEmpHI, EmployeeUI = EmployeeUI * IsEmpUI + CompanyUI * ~ IsComUI, CompanyUI = CompanyUI * IsComUI + EmployeeUI * ~ IsEmpUI
	WHERE (IsEmpSI <> IsComSI OR IsEmpHI <> IsComHI OR IsEmpUI <> IsComUI)

	--truong hop 2 ben deu khong dong 1 loai bao hiem, vd nguoi nuoc ngoai chi dong BHYT
	UPDATE #InsuranceTmp
	SET EmployeeSI = 0, CompanySI = 0, CompanySM = 0
	WHERE IsEmpSI = 0 AND IsComSI = 0

	UPDATE #InsuranceTmp
	SET EmployeeHI = 0, CompanyHI = 0
	WHERE IsEmpHI = 0 AND IsComHI = 0

	UPDATE #InsuranceTmp
	SET EmployeeUI = 0, CompanyUI = 0
	WHERE IsEmpUI = 0 AND IsComUI = 0

	UPDATE #InsuranceTmp
	SET EmployeeHI = EmployeeHI + CompanyHI, CompanyHI = 0
	FROM #InsuranceTmp isn
	WHERE InsPaymentStatus = 7 AND EXISTS (
			SELECT 1
			FROM tblEmployee ee
			INNER JOIN tblNation na ON ISNULL(ee.NationID, 234) = na.NationID AND na.IsVietNam = 1
			WHERE isn.EmployeeID = ee.EmployeeID
			)

	UPDATE #InsuranceTmp
	SET CompanyHI = EmployeeHI + CompanyHI, EmployeeHI = 0
	FROM #InsuranceTmp isn
	WHERE InsPaymentStatus = 7 AND NOT EXISTS (
			SELECT 1
			FROM tblEmployee ee
			INNER JOIN tblNation na ON ISNULL(ee.NationID, 234) = na.NationID AND na.IsVietNam = 1
			WHERE isn.EmployeeID = ee.EmployeeID
			)

	UPDATE #InsuranceTmp
	SET Notes = CASE 
			WHEN @languageId = 'VN'
				THEN N'Thay đổi lương'
			ELSE 'Salary changed'
			END
	FROM #InsuranceTmp t
	INNER JOIN tblSal_Insurance s ON t.EmployeeID = s.EmployeeID AND s.Year * 12 + s.Month = @Year * 12 + @Month - 1
	WHERE (t.SIIncome <> s.SIIncome OR t.UIIncome <> s.UIIncome) AND t.Notes IS NULL

	UPDATE #InsuranceTmp
	SET Notes = CASE 
			WHEN @languageId = 'VN'
				THEN N'Tăng mới'
			ELSE 'Encrease'
			END
	FROM #InsuranceTmp t
	LEFT JOIN tblSal_Insurance s ON t.EmployeeID = s.EmployeeID AND s.Year * 12 + s.Month = @Year * 12 + @Month - 1
	WHERE (s.EmployeeID IS NULL OR ISNULL(s.Total, 0) = 0) AND (t.EmployeeSI <> 0 OR t.CompanySI <> 0 OR t.EmployeeHI <> 0 OR t.CompanyHI <> 0 OR t.EmployeeUI <> 0 OR t.CompanyUI <> 0) AND t.Notes IS NULL

	-- đóng ở cty khác thì chỉ đong 0.5% Bảo hiểm tai nạn
	UPDATE tmp
	SET OtherCompanyIns = 1
	FROM #InsuranceTmp tmp
	INNER JOIN #tmpEmpInsList te ON tmp.EmployeeID = te.EmployeeID
	WHERE te.EmpInsuranceStatusID = 3

	UPDATE #InsuranceTmp
	SET EmployeeSI = 0, CompanySI = ROUND(SIIncome * p.AI_CompPercent / 100.0, 0), EmployeeHI = 0, CompanyHI = 0, EmployeeUI = 0, CompanyUI = 0
	FROM #InsuranceTmp tmp
	CROSS JOIN dbo.fn_CurrentInsurancePercentage(@SIDate) p
	WHERE tmp.OtherCompanyIns = 1

	-- người nước ngoài mà có tham gia bảo hiểm thì đóng BHYT và BHXH, và đóng theo mức riêng (nếu có set) ExpatIns
	UPDATE tmp
	SET ExpatIns = 1
	FROM #InsuranceTmp tmp
	INNER JOIN tblEmployee te ON tmp.EmployeeID = te.EmployeeID
	WHERE isnull(te.EmpInsuranceStatusID, - 1) = - 1 AND (
			te.NationID IS NOT NULL AND te.NationID NOT IN (
				SELECT NationID
				FROM tblNation
				WHERE IsVietNam = 1
				)
			)

	UPDATE #InsuranceTmp
	SET EmployeeSI = ROUND(SIIncome * ISNULL(p.Ex_SI_EmpPercent, p.SI_EmpPercent) / 100.0, 0), CompanySI = ROUND(SIIncome * ISNULL(p.Ex_SI_CompPercent, p.SI_CompPercent) / 100.0, 0), EmployeeHI = ROUND(HIIncome * isnull(p.Ex_HI_EmpPercent, p.HI_EmpPercent) / 100.0, 0), CompanyHI = ROUND(HIIncome * isnull(p.Ex_HI_CompPercent, p.HI_CompPercent) / 100.0, 0), EmployeeUI = 0, CompanyUI = 0
	FROM #InsuranceTmp tmp
	CROSS JOIN dbo.fn_CurrentInsurancePercentage(@SIDate) p
	WHERE tmp.ExpatIns = 1 AND tmp.InsPaymentStatus = 0

	IF (OBJECT_ID('EmpInsuranceMonthly_AfterCalculate') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE EmpInsuranceMonthly_AfterCalculate
(
	 @Month int
	,@Year int
	,@LoginID int
	,@CalFromSalCal bit = 0
	,@StopUpdate bit output
)
as
begin
	SET NOCOUNT ON;
end'
				)
	END

	SET @StopUpdate = 0

	EXEC EmpInsuranceMonthly_AfterCalculate @Month = @Month, @Year = @Year, @LoginID = @LoginID, @CalFromSalCal = @CalFromSalCal, @StopUpdate = @StopUpdate OUTPUT

	IF @CalculateRetro = 0
	BEGIN -- nếu là tính lương thường thì cộng bthuong thôi
		--save to database
		DELETE tblSal_Insurance
		FROM tblSal_Insurance si
		WHERE Month = @Month AND Year = @Year AND ISNULL(Approval, 0) = 0 AND EXISTS (
				SELECT 1
				FROM tmpEmployeeTree tr
				WHERE si.EmployeeID = tr.EmployeeID AND tr.LoginID = @LoginID
				) AND si.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_Lock
				WHERE Month = @Month AND Year = @Year
				) --khoa luong roi thi ko xoa
			AND si.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM #tmpEmpInsList
				)

		INSERT INTO tblSal_Insurance (EmployeeID, Year, Month, HIIncome, SIIncome, UIIncome, EmployeeHI, EmployeeSI, EmployeeUI, CompanyHI, CompanySI, CompanySM, CompanyUI, SalaryHistoryID, InsPaymentStatus, Notes, Approval)
		SELECT tmp.EmployeeID, @Year, @Month, HIIncome, SIIncome, UIIncome, EmployeeHI, EmployeeSI, EmployeeUI, CompanyHI, CompanySI, CompanySM, CompanyUI, SalaryHistoryID, InsPaymentStatus, Notes, 0
		FROM #InsuranceTmp tmp
		WHERE EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_Insurance
				WHERE Month = @Month AND Year = @Year
				)

		INSERT INTO tblSal_Insurance (EmployeeID, Month, Year, Notes)
		SELECT EmployeeID, @Month, @Year, N'due to adjustment'
		FROM tblSal_Retro re
		WHERE re.Month = @Month AND re.Year = @Year AND re.EmployeeID IN (
				SELECT EmployeeID
				FROM tmpEmployeeTree
				WHERE LoginID = @LoginID
				) AND re.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM #tmpEmpInsList
				) AND re.EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_Insurance i
				WHERE i.Month = @Month AND i.Year = @Year AND i.EmployeeID = re.EmployeeID
				)

		UPDATE tblSal_Insurance
		SET HIIncome = tmp.HIIncome, SIIncome = tmp.SIIncome, UIIncome = tmp.UIIncome, EmployeeSI = tmp.EmployeeSI, EmployeeHI = tmp.EmployeeHI, EmployeeUI = tmp.EmployeeUI, CompanySI = tmp.CompanySI, CompanySM = tmp.CompanySM, CompanyHI = tmp.CompanyHI, CompanyUI = tmp.CompanyUI, SalaryHistoryID = tmp.SalaryHistoryID, Approval = ISNULL(Approval, 0), Notes = tmp.Notes, InsPaymentStatus = tmp.InsPaymentStatus
		FROM tblSal_Insurance si
		INNER JOIN #InsuranceTmp tmp ON si.EmployeeID = tmp.EmployeeID AND si.Month = @Month AND si.Year = @Year
		WHERE (ISNULL(si.Approval, 0) = 0 OR ISNULL(si.InsPaymentStatus, 1) = 5)
	END -- nếu là tính lương thường thì cứ insert thôi
	ELSE
	BEGIN -- nếu là tính retro thì phải chạy đoạn này để insert vào bảng retro
		-- delete bảng thực : xóa những cậu nào nằm trong worKingon  mà đã khóa nhé
		DELETE tblSal_Insurance_Retro
		FROM tblSal_Insurance_Retro re
		WHERE re.Month = @Month AND re.Year = @Year AND NOT EXISTS (
				SELECT 1
				FROM tblSal_Lock sl
				WHERE re.EmployeeID = sl.EmployeeID AND sl.Month = @nextMonth AND sl.Year = @nextYear
				) AND EmployeeID IN (
				SELECT EmployeeID
				FROM #tmpEmpInsList_WorkingOn
				) -- working on rồi nhé

		-- insert - update ko quan tâm khóa nữa
		-- update cho bảng tạm cái
		DELETE tmp
		FROM tblSal_Insurance si
		INNER JOIN #InsuranceTmp tmp ON si.EmployeeID = tmp.EmployeeID AND si.Month = @Month AND si.Year = @Year
		WHERE (ISNULL(si.Approval, 0) <> 0 AND ISNULL(si.InsPaymentStatus, 1) <> 5)

		INSERT INTO tblSal_Insurance_Retro (EmployeeID, Year, Month, HIIncome, SIIncome, UIIncome, EmployeeHI, EmployeeSI, EmployeeUI, CompanyHI, CompanySI, CompanySM, CompanyUI, SalaryHistoryID, InsPaymentStatus, Notes)
		SELECT tmp.EmployeeID, @Year, @Month, HIIncome, SIIncome, UIIncome, EmployeeHI, EmployeeSI, EmployeeUI, CompanyHI, CompanySI, CompanySM, CompanyUI, SalaryHistoryID, InsPaymentStatus, Notes
		FROM #InsuranceTmp tmp
		WHERE EmployeeID NOT IN (
				SELECT EmployeeID
				FROM tblSal_Insurance_Retro
				WHERE Month = @Month AND Year = @Year
				)

		UPDATE tblSal_Insurance_Retro
		SET EmployeeTotal = ISNULL(EmployeeHI, 0) + ISNULL(EmployeeSI, 0) + ISNULL(EmployeeUI, 0) + ISNULL(re.INS_Retro_Amount_EE, 0), CompanyTotal = ISNULL(CompanyHI, 0) + ISNULL(CompanySI, 0) + ISNULL(CompanySM, 0) + ISNULL(CompanyUI, 0) + ISNULL(re.INS_Retro_Amount_ER, 0), Total = ISNULL(EmployeeHI, 0) + ISNULL(EmployeeSI, 0) + ISNULL(EmployeeUI, 0) + ISNULL(CompanyHI, 0) + ISNULL(CompanySI, 0) + ISNULL(CompanySM, 0) + ISNULL(CompanyUI, 0) + ISNULL(re.INS_Retro_Amount_EE, 0) + ISNULL(re.INS_Retro_Amount_ER, 0)
		FROM tblSal_Insurance_Retro ins
		LEFT JOIN tblSal_Retro re ON ins.EmployeeID = re.EmployeeID AND re.Month = @Month AND re.Year = @Year
		WHERE ins.Month = @Month AND ins.Year = @Year

		-- diff nó với bảng chốt nào
		RETURN
	END

	Finished:

	UPDATE tblSal_Insurance
	SET EmployeeTotal = ISNULL(EmployeeHI, 0) + ISNULL(EmployeeSI, 0) + ISNULL(EmployeeUI, 0) + ISNULL(re.INS_Retro_Amount_EE, 0), CompanyTotal = ISNULL(CompanyHI, 0) + ISNULL(CompanySI, 0) + ISNULL(CompanySM, 0) + ISNULL(CompanyUI, 0) + ISNULL(re.INS_Retro_Amount_ER, 0), Total = ISNULL(EmployeeHI, 0) + ISNULL(EmployeeSI, 0) + ISNULL(EmployeeUI, 0) + ISNULL(CompanyHI, 0) + ISNULL(CompanySI, 0) + ISNULL(CompanySM, 0) + ISNULL(CompanyUI, 0) + ISNULL(re.INS_Retro_Amount_EE, 0) + ISNULL(re.INS_Retro_Amount_ER, 0)
	FROM tblSal_Insurance ins
	LEFT JOIN tblSal_Retro re ON ins.EmployeeID = re.EmployeeID AND re.Month = @Month AND re.Year = @Year
	WHERE ins.Month = @Month AND ins.Year = @Year

	IF (@CalFromSalCal = 0)
		SELECT ins.Month, ins.Year, ins.EmployeeID, te.FullName, CASE 
				WHEN @languageId = 'VN'
					THEN stt.EmployeeStatus
				ELSE stt.EmployeeStatusEN
				END AS EmployeeStatus, stt.ChangedDate, ins.SIIncome, ins.UIIncome, ins.EmployeeSI, ins.EmployeeHI, ins.EmployeeUI, re.INS_Retro_Amount_EE, ins.EmployeeTotal, ins.CompanySI, ins.CompanySM, ins.CompanyHI, ins.CompanyUI, re.INS_Retro_Amount_ER, ins.CompanyTotal, ins.Total AS InsTotal, InsPaymentStatus, Approval, Notes
		FROM tblSal_Insurance ins
		INNER JOIN tblEmployee te ON ins.EmployeeID = te.EmployeeID
		LEFT JOIN #fn_EmployeeStatus_ByDate stt ON ins.EmployeeID = stt.EmployeeID
		LEFT JOIN tblSal_Retro re ON ins.EmployeeID = re.EmployeeID AND re.Month = @Month AND re.Year = @Year
		WHERE ins.Month = @Month AND ins.Year = @Year AND te.EmployeeID IN (
				SELECT EmployeeID
				FROM tmpEmployeeTree
				WHERE LoginID = @LoginID
				)
END
GO

IF object_id('[dbo].[sp_CompanySalarySummary]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_CompanySalarySummary] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_CompanySalarySummary] (@LoginID INT = NULL, @Month INT = NULL, @Year INT = NULL, @EmployeeID VARCHAR(20) = '-1', @IsPayslip BIT = 0, @isSummary BIT = 0)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	IF nullif(@EmployeeID, '') IS NULL
		SET @EmployeeID = '-1'

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

	SELECT s.EmployeeID, Month, Year, SUM(ATTHours) ATTHours, SUM(WorkingHours) WorkingHours, MAX(BasicSalary) BasicSalary, SUM(ActualMonthlyBasic) ActualMonthlyBasic, SUM(TaxableAllowance) TaxableAllowance, SUM(TotalEarn) TotalEarn, SUM(DaysOfSalEntry) DaysOfSalEntry, SUM(Raw_BasicSalary) Raw_BasicSalary, SUM(UnpaidLeaveAmount) UnpaidLeaveAmount, SUM(NSAmount) NSAmount, SUM(RegularAmt) RegularAmt, SUM(PaidLeaveAmt) PaidLeaveAmt, MAX(GrossSalary) GrossSalary, SUM(AnnualBonus_Total) AnnualBonus_Total, SUM(AnnualBonus_EvMonth) AnnualBonus_EvMonth, SUM(Bonus6Month_Total) Bonus6Month_Total, SUM(Bonus6M_EveryMonth) Bonus6M_EveryMonth, SUM(TaxableIncomeBeforeDeduction) TaxableIncomeBeforeDeduction, SUM(TotalIncome) TotalIncome
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

	SELECT Year, Month, a.EmployeeID, SUM(WorkingHrs_Total) WorkingHrs_Total, SUM(WorkingDays_Total) WorkingDays_Total, SUM(PaidLeaveHrs_Total) PaidLeaveHrs_Total, SUM(PaidLeaveDays_Total) PaidLeaveDays_Total, SUM([A]) [A], SUM(Std_Hour_PerDays) Std_Hour_PerDays, SUM(STD_WorkingDays) STD_WorkingDays, SUM(UnpaidLeaveHrs) UnpaidLeaveHrs, SUM(UnpaidLeaveDays) UnpaidLeaveDays, SUM(RegularWorkdays) RegularWorkdays, SUM(OT1) OT1, SUM(OT1_ExcessOT) OT1_ExcessOT, SUM(OT2a) OT2a, SUM(OT2a_ExcessOT) OT2a_ExcessOT, SUM(OT2b) OT2b, SUM(OT2b_ExcessOT) OT2b_ExcessOT, SUM(OT3) OT3, SUM(OT3_ExcessOT) OT3_ExcessOT, SUM(OT4) OT4, SUM(OT4_ExcessOT) OT4_ExcessOT, SUM(OT5) OT5, SUM(OT5_ExcessOT) OT5_ExcessOT, SUM(OT6) OT6, SUM(OT6_ExcessOT) OT6_ExcessOT, SUM(OT7) OT7, SUM(OT7_ExcessOT) OT7_ExcessOT, SUM(TotalOT) TotalOT, SUM(TaxableOT) TaxableOT, SUM(NontaxableOT) NontaxableOT, SUM(TotalExcessOT) TotalExcessOT
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
			SELECT EmployeeID, ' + LEFT(@OTList, LEN(@OTList) - 1) + '
			FROM #AttendanceSummary
		) AS src
		UNPIVOT
		(
			OTHours FOR OTType IN (' + LEFT(@OTList, LEN(@OTList) - 1) + ')
		) AS unpvt'

	EXEC sp_executesql @Query

	SELECT ot.EmployeeID, ot.OverTimeID, SUM(ot.OTAmount) OTAmount, SUM(os.OTHours * (
				CASE 
					WHEN ots.OvValue - 100 < 0
						THEN 0
					ELSE (ots.OvValue - 100)
					END
				) / 100) NoneTaxableOTAmount, SUM(ot.OTHour) Amount --SUM(os.OTHours) Amount,
	INTO #OTAmount
	FROM tblSal_OT_Detail ot
	INNER JOIN #tmpEmployeeList te ON ot.EmployeeID = te.EmployeeID
	LEFT JOIN tblOvertimeSetting ots ON ots.OTKind = ot.OverTimeID
	LEFT JOIN #OTSummary os ON ot.EmployeeID = os.EmployeeID AND ots.ColumnDisplayName = os.OTType
	WHERE ot.Year = @Year AND ot.Month = @Month
	GROUP BY ot.EmployeeID, ot.OverTimeID

	--night shift
	SELECT s.*
	INTO #Sal_NS
	FROM tblSal_NS_Detail s
	INNER JOIN #tmpEmployeeList te ON s.EmployeeID = te.EmployeeID
	WHERE s.Year = @Year AND s.Month = @Month

	SELECT *, Salary BasicSalary
	INTO #CurrentSalary
	FROM dbo.fn_CurrentSalaryByDate_TRIPOD(@ToDate, @LoginID)

	SELECT st.*
	INTO #tblSal_Tax
	FROM tblSal_Tax st
	INNER JOIN #tmpEmployeeList te ON st.EmployeeID = te.EmployeeID
	WHERE st.Year = @Year AND st.Month = @Month

	--đi trễ về sớm
	SELECT ioc.EmployeeID, COUNT(1) IOCount
	INTO #InLateOutEarly
	FROM tblInLateOutEarly ioc
	INNER JOIN #tmpEmployeeList te ON ioc.EmployeeID = te.EmployeeID
	WHERE IODate BETWEEN @FromDate AND @ToDate
	GROUP BY ioc.EmployeeID

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
			) AS STT, s.EmployeeID, s.FullName, s.DepartmentName, s.PositionName, cs.Salary, cs.[14] AS Allowance, sd.BasicSalary TotalSalary, sd.GrossSalary GrossTotal, a.WorkingHrs_Total AS RegularHrs, sd.RegularAmt, a.PaidLeaveHrs_Total, sd.PaidLeaveAmt, ot1.Amount AS OT1, ot2a.Amount AS ot2a, ot2b.Amount AS ot2b, ot3.Amount AS OT3, ot4.Amount AS OT4, ot5.Amount AS OT5, ot6.Amount AS OT6, ot7.Amount AS OT7, ROUND(totalOT.OTAmount, 0) AS TotalOT, ot1.NoneTaxableOTAmount AS OT1_ReduceTax, ot2a.NoneTaxableOTAmount AS ot2a_ReduceTax, ot2b.NoneTaxableOTAmount AS ot2b_ReduceTax, ot3.NoneTaxableOTAmount AS OT3_ReduceTax, ot4.NoneTaxableOTAmount AS OT4_ReduceTax, ot6.NoneTaxableOTAmount AS OT6_ReduceTax, ot7.NoneTaxableOTAmount AS OT7_ReduceTax, ROUND(totalOT.NoneTaxableOTAmount, 0) AS TotalOT_ReduceTax, totalOT.TaxableOTAmount AS TotalOT_Taxable, seniority.Amount AS Seniority, lang.Amount AS LANGUAGE, environment.Amount AS Environment, shift.Amount AS Shift, ns.NSHours, ns.NSAmount, petrol.Amount AS Petrol, design.Amount AS Design, attendance.Amount AS Attendance, meal.Amount AS Meal, area
		.Amount AS Area, incentive.Amount AS Incentive, cs.Allowance AS RegularAllowance, ISNULL(petrol.Amount, 0) + ISNULL(ns.NSAmount, 0) + ISNULL(attendance.Amount, 0) + ISNULL(meal.Amount, 0) + ISNULL(incentive.Amount, 0) AS IrregularAllowance, ISNULL(addition.Amount, 0) + ISNULL(excessOT.Amount, 0) Addition, ISNULL(al.Amount, 0) AS AnnualBonus, bonus6.Amount AS Bonus6Month, ROUND(sal.TotalIncome, 0) TotalIncome, st.DependantNumber, ROUND(sd.TaxableIncomeBeforeDeduction, 0) TaxableIncomeBeforeDeduction, ROUND(st.IncomeTaxable, 0) IncomeAfterPIT, ins.EmployeeSI, ins.EmployeeHI, ins.EmployeeUI, st.TaxAmt, sal.EmpUnion, deduction.Amount Deduction, sal.GrossTakeHome AS Balance1, sal.GrossTakeHome AS Balance2, CASE 
			WHEN (sal.GrossTakeHome % 1000) = 0
				THEN sal.GrossTakeHome
			WHEN (sal.GrossTakeHome % 1000) > 500
				THEN CEILING(sal.GrossTakeHome / 1000.0) * 1000
			WHEN (sal.GrossTakeHome % 1000) = 500
				THEN sal.GrossTakeHome
			WHEN (sal.GrossTakeHome % 1000) < 500
				THEN FLOOR(sal.GrossTakeHome / 1000.0) * 1000 + 500
			ELSE sal.GrossTakeHome
			END AS Total, ins.CompanySI, ins.CompanyHI, ins.CompanyUI, sal.CompUnion, sd.AnnualBonus_Total AS ALTotal, sd.AnnualBonus_EvMonth AS ALEveryM, sd.Bonus6Month_Total AS Bonus6M, sd.Bonus6M_EveryMonth AS Bonus6M_EveryM, CONCAT (@Month, '.', @Year) AS MonthYear, ROUND((a.WorkingHrs_Total / a.Std_Hour_PerDays), 1) AS Workdays, ISNULL(ins.EmployeeUI, 0) + ISNULL(ins.EmployeeHI, 0) + ISNULL(ins.EmployeeSI, 0) + ISNULL(sal.EmpUnion, 0) + ISNULL(st.TaxAmt, 0) + ISNULL(deduction.Amount, 0) + ISNULL(sd.UnpaidLeaveAmount, 0) AS TotalDeduction,
		--tổng thu = tổng các khoản thực lãnh (bao gồm cả gross salary nếu đủ công)
		ISNULL(sd.TotalIncome, 0) - ISNULL(sd.RegularAmt, 0) - ISNULL(sd.PaidLeaveAmt, 0) + ISNULL(sd.GrossSalary, 0) AS TotalEarning, a.UnpaidLeaveHrs UnpaidLeaveDays, st.EmployeeExemption, st.FamilyExemption, ins.EmployeeTotal, a.[A] AnnualLeaveHrs, ISNULL(a.PaidLeaveHrs_Total, 0) - ISNULL(a.[A], 0) PaidLeavePS,
		--đặc thù của TVC
		ISNULL(incentive.Amount, 0) + ISNULL(meal.Amount, 0) + ISNULL(addition.Amount, 0) + ISNULL(excessOT.Amount, 0) AS OrtherIncome, ioc.IOCount, bonus6att.Amount AS Bonus6Month_FullAttendance, sd.UnpaidLeaveAmount, ISNULL(sd.TotalIncome, 0) - ISNULL(sd.RegularAmt, 0) - ISNULL(sd.PaidLeaveAmt, 0) + ISNULL(sd.GrossSalary, 0) - ISNULL(sd.UnpaidLeaveAmount, 0) AS TotalEarning_ExcludeUnpaidLeave, s.CostCenterName, EmployeeClass, EmployeeType
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

	IF (@IsPayslip = 1)
	BEGIN
		SELECT *
		FROM #DetailOfSalary

		RETURN
	END

	IF ISNULL(@isSummary, 0) = 0 AND ISNULL(@IsPayslip, 0) = 0
	BEGIN
		ALTER TABLE #DetailOfSalary

		DROP COLUMN MonthYear, Workdays, UnpaidLeaveDays, EmployeeExemption, FamilyExemption, TotalDeduction, AnnualLeaveHrs, EmployeeTotal, PaidLeavePS, OrtherIncome, IOCount, Bonus6Month_FullAttendance, UnpaidLeaveAmount, TotalEarning, TotalEarning_ExcludeUnpaidLeave, CostCenterName, EmployeeClass, EmployeeType

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

		ALTER TABLE #ExcessOT

		ALTER COLUMN AnnualBonus FLOAT NULL

		--OT Vượt TVC
		DELETE d
		FROM #ExcessOT d
		INNER JOIN #AttendanceSummary o ON d.EmployeeID = o.EmployeeID AND ISNULL(o.TotalExcessOT, 0) <= 0

		UPDATE d
		SET OT1 = o.OT1_ExcessOT, OT2a = o.OT2a_ExcessOT, OT2b = o.OT2b_ExcessOT, OT3 = o.OT3_ExcessOT, OT4 = o.OT4_ExcessOT, OT5 = o.OT5_ExcessOT, OT6 = o.OT6_ExcessOT, OT7 = o.OT7_ExcessOT, TotalOT = o.TotalExcessOT, OT1_ReduceTax = 0, ot2a_ReduceTax = 0, ot2b_ReduceTax = 0, OT3_ReduceTax = 0, OT4_ReduceTax = 0, OT6_ReduceTax = 0, OT7_ReduceTax = 0, TotalOT_ReduceTax = 0, TotalOT_Taxable = 0,
			-- cập nhật các cột còn lại về NULL, trừ các cột đang selected và 9 cột đầu
			RegularHrs = NULL, RegularAmt = NULL, PaidLeaveHrs_Total = NULL, PaidLeaveAmt = NULL, Seniority = NULL, LANGUAGE = NULL, Environment = NULL, Shift = NULL, NSHours = NULL, NSAmount = NULL, Petrol = NULL, Design = NULL, Attendance = NULL, Meal = NULL, Area = NULL, Incentive = NULL, RegularAllowance = NULL, IrregularAllowance = NULL, Addition = NULL, AnnualBonus = NULL, Bonus6Month = NULL, TotalIncome = NULL, DependantNumber = NULL, TaxableIncomeBeforeDeduction = NULL, IncomeAfterPIT = NULL, EmployeeSI = NULL, EmployeeHI = NULL, EmployeeUI = NULL, TaxAmt = NULL, EmpUnion = NULL, Deduction = NULL, Balance1 = NULL, Balance2 = NULL, Total = NULL, CompanySI = NULL, CompanyHI = NULL, CompanyUI = NULL, CompUnion = NULL, ALTotal = NULL, ALEveryM = NULL, Bonus6M = NULL, Bonus6M_EveryM = NULL
		FROM #ExcessOT d
		INNER JOIN #AttendanceSummary o ON d.EmployeeID = o.EmployeeID AND ISNULL(o.TotalExcessOT, 0) > 0

		ALTER TABLE #ExcessOT

		DROP COLUMN STT

		UPDATE d
		SET TotalOT = ISNULL(excessOT.Amount, 0)
		FROM #ExcessOT d
		LEFT JOIN #NonFixed excessOT ON excessOT.IncomeID = 16 AND d.EmployeeID = excessOT.EmployeeID

		SELECT ROW_NUMBER() OVER (
				ORDER BY EmployeeID
				) STT, *
		FROM #ExcessOT
	END

	IF (ISNULL(@isSummary, 0) = 1)
	BEGIN
		SELECT CostCenterName, EmployeeClass, EmployeeType, DepartmentName, COUNT(1) Qty, SUM(GrossTotal) GrossTotal, SUM(ISNULL(RegularAmt, 0) + ISNULL(PaidLeaveAmt, 0)) GrossTotal, SUM(RegularAllowance) RegularAllowance, SUM(IrregularAllowance) IrregularAllowance, SUM(Addition) Addition, SUM(Deduction) Deduction, SUM(TotalOT) TaxableOTAmount, SUM(TotalOT_ReduceTax) NontaxableOTAmount, SUM(EmployeeSI) EmployeeSI, SUM(EmployeeHI) EmployeeHI, SUM(EmployeeUI) EmployeeUI, SUM(TaxAmt) TaxAmt, SUM(EmpUnion) EmployeeUnion, CAST(NULL AS FLOAT) Advanced, SUM(Total) GrossTakeHome, SUM(CompanySI) CompanySI, SUM(CompanyHI) CompanyHI, sum(CompanyUI) CompanyUI, SUM(CompUnion) CompUnion, SUM(ALEveryM) ALEveryM, SUM(Bonus6M_EveryM) Bonus6M_EveryM
		FROM #DetailOfSalary
		GROUP BY CostCenterName, EmployeeClass, EmployeeType, DepartmentName

		SELECT CostCenterName, EmployeeClass, EmployeeType, CAST(NULL AS INT) Department, COUNT(1) Qty, SUM(GrossTotal) GrossTotal, SUM(ISNULL(RegularAmt, 0) + ISNULL(PaidLeaveAmt, 0)) GrossTotal, SUM(RegularAllowance) RegularAllowance, SUM(IrregularAllowance) IrregularAllowance, SUM(Addition) Addition, SUM(Deduction) Deduction, SUM(TotalOT) TaxableOTAmount, SUM(TotalOT_ReduceTax) NontaxableOTAmount, SUM(EmployeeSI) EmployeeSI, SUM(EmployeeHI) EmployeeHI, SUM(EmployeeUI) EmployeeUI, SUM(TaxAmt) TaxAmt, SUM(EmpUnion) EmployeeUnion, CAST(NULL AS FLOAT) Advanced, SUM(Total) GrossTakeHome, SUM(CompanySI) CompanySI, SUM(CompanyHI) CompanyHI, sum(CompanyUI) CompanyUI, SUM(CompUnion) CompUnion, SUM(ALEveryM) ALEveryM, SUM(Bonus6M_EveryM) Bonus6M_EveryM
		FROM #DetailOfSalary
		GROUP BY CostCenterName, EmployeeClass, EmployeeType
		ORDER BY CostCenterName DESC

		SELECT CONCAT (@Year, '.', FORMAT(DATEFROMPARTS(@Year, @Month, 1), 'MM', 'en-US'), '.', DAY(@ToDate)) AS MonthYear

		RETURN
	END

	SELECT CONCAT (@Year, '.', FORMAT(DATEFROMPARTS(@Year, @Month, 1), 'MMMM', 'en-US')) AS MonthYear

	CREATE TABLE #ExportConfig (ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200), SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200))

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

IF object_id('[dbo].[sp_ProcessProductionAllowance]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_ProcessProductionAllowance] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_ProcessProductionAllowance] (@LoginID INT, @Year INT, @Month INT, @LanguageID NVARCHAR(2) = 'VN')
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	DECLARE @Parameter INT = (
			SELECT Parameter
			FROM tblAllowanceSetting
			WHERE AllowanceID = 2
			)

	SELECT EmployeeID, FullName, DepartmentID, SectionID, PositionID
	INTO #EmployeeList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(GETDATE(), '-1', @LoginID)

	IF NOT EXISTS (
			SELECT *
			FROM sys.tables
			WHERE name = 'tblProductionAllowance'
			)
	BEGIN
		CREATE TABLE tblProductionAllowance (ID INT IDENTITY(1, 1) PRIMARY KEY, EmployeeID VARCHAR(20) NOT NULL, Year INT NOT NULL, Month INT NOT NULL, WorkingDays FLOAT, LevelBonus INT, ProductionBonusAmount DECIMAL(18, 2), ProcessedDate DATETIME DEFAULT GETDATE())
	END

	INSERT INTO tblProductionAllowance (EmployeeID, Year, Month)
	SELECT emp.EmployeeID, @Year, @Month
	FROM #EmployeeList emp
	INNER JOIN tblPosition pos ON emp.PositionID = pos.PositionID
	WHERE pos.ProductionBonusAllowance = 1 AND NOT EXISTS (
			SELECT 1
			FROM tblProductionAllowance pa
			WHERE pa.EmployeeID = emp.EmployeeID AND pa.Year = @Year AND pa.Month = @Month
			)

	UPDATE tblProductionAllowance
	SET WorkingDays = att.WorkingDays_Total
	FROM tblProductionAllowance pa
	INNER JOIN tblAttendanceSummary att ON pa.EmployeeID = att.EmployeeID AND att.Year = pa.[Year] AND att.Month = pa.[Month]
	WHERE pa.Year = @Year AND pa.Month = @Month

	SELECT EmployeeID, GrossSalary
	INTO #GrossSalary
	FROM dbo.fn_CurrentSalaryByDate_TRIPOD(@ToDate, @LoginID)
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #EmployeeList
			)

	UPDATE gs
	SET ProductionBonusAmount = ISNULL(GrossSalary, 0) * (ISNULL(p.ProductionBonusPercentage, 0) / 100)
	FROM tblProductionAllowance gs
	INNER JOIN #GrossSalary pa ON gs.EmployeeID = pa.EmployeeID
	LEFT JOIN tblProductionBonusLevel p ON p.ProductionBonusID = gs.ProductionBonusID
	WHERE ProductionBonusAmount IS NULL AND gs.Year = @Year AND gs.Month = @Month

	UPDATE gs
	SET ProductionBonusAmount = NULL
	FROM tblProductionAllowance gs
	WHERE gs.Year = @Year AND gs.Month = @Month AND ISNULL(WorkingDays, 0) < (
			SELECT Parameter
			FROM tblAllowanceSetting
			WHERE AllowanceID = 2
			)

	SELECT pa.*, emp.FullName, CASE 
			WHEN @LanguageID = 'VN'
				THEN pos.PositionName
			ELSE pos.PositionNameEN
			END AS PositionName, CASE 
			WHEN @LanguageID = 'VN'
				THEN dep.DepartmentName
			ELSE dep.DepartmentNameEN
			END AS DepartmentName, CASE 
			WHEN @LanguageID = 'VN'
				THEN sec.SectionName
			ELSE sec.SectionNameEN
			END AS SectionName
	FROM tblProductionAllowance pa
	INNER JOIN #EmployeeList emp ON pa.EmployeeID = emp.EmployeeID
	LEFT JOIN tblPosition pos ON emp.PositionID = pos.PositionID
	LEFT JOIN tblDepartment dep ON emp.DepartmentID = dep.DepartmentID
	LEFT JOIN tblSection sec ON emp.SectionID = sec.SectionID
	WHERE pa.Year = @Year AND pa.Month = @Month
END
GO

IF object_id('[dbo].[sp_processAllAllowance]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_processAllAllowance] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_processAllAllowance] (@LoginID INT = 3, @Year INT, @Month INT, @SalCal BIT = 0)
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT f.EmployeeID, FullName, HireDate, LastWorkingDate, CAST(0 AS INT) Prio, f.DepartmentID, f.DivisionID, f.PositionID, s.SectionID, s.SectionName, ROW_NUMBER() OVER (
			ORDER BY f.EmployeeID
			) STTView, d.DepartmentName, p.PositionNameEN PositionName, CASE 
			WHEN f.ProbationEndDate > @FromDate
				THEN 1
			ELSE 0
			END AS Probationary, f.IsForeign
	INTO #tmpEmployeeList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginId) f
	LEFT JOIN tblSection s ON s.SectionID = f.SectionID
	LEFT JOIN tblDepartment d ON d.DepartmentID = f.DepartmentID
	LEFT JOIN tblPosition p ON p.PositionID = f.PositionID

	SELECT a.*
	INTO #AttendanceSummary
	FROM tblAttendanceSummary a
	INNER JOIN #tmpEmployeeList e ON e.EmployeeID = a.EmployeeID
	WHERE Year = @Year AND Month = @Month

	IF EXISTS (
			SELECT *
			FROM #AttendanceSummary a
			WHERE EmployeeID NOT IN (
					SELECT s.EmployeeID
					FROM tblCustomInputImportMonthly s
					INNER JOIN #tmpEmployeeList t ON t.EmployeeID = s.EmployeeID AND s.[Year] = @Year AND s.[Month] = @Month
					)
			)
	BEGIN
		INSERT INTO tblCustomInputImportMonthly (EmployeeID, [Year], [Month])
		SELECT EmployeeID, @Year, @Month
		FROM #AttendanceSummary a
		WHERE EmployeeID NOT IN (
				SELECT s.EmployeeID
				FROM tblCustomInputImportMonthly s
				INNER JOIN #tmpEmployeeList t ON t.EmployeeID = s.EmployeeID AND s.[Year] = @Year AND s.[Month] = @Month
				)
	END

	CREATE TABLE #tblAllowance (EmployeeID INT, AllowanceID INT, ReceiveAmount MONEY, TotalPaidDays FLOAT)

	--     1	Seniority allowance
	-- 2	Production bonus
	-- 3	Foreign language allowance
	-- 4	Environmental allowance
	-- 5	Shift allowance
	-- 6	Fuel allowance
	-- 7	Professional allowance
	-- 8	Attendance allowance
	-- 9	Meal allowance
	-- 10	Regional (area) allowance
	-- 11	Incentive allowance
	-- 12	Key process allowance
	-- 13	Bonus 6 month
	-- 14	Performance & Responsibility
	-- TRIPOD: Xử lý các allowance
	EXEC sp_ProcessSeniorityAllowance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @isView = 1

	INSERT INTO #tblAllowance (EmployeeID, AllowanceID, ReceiveAmount, TotalPaidDays)
	SELECT EmployeeID, 1, SeniorityAmount, WorkingDays
	FROM tblSeniorityAllowance
	WHERE Month = @Month AND Year = @Year AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			WHERE ISNULL(IsForeign, 0) = 0
			) AND SeniorityAmount > 0

	SELECT EmployeeID, COUNT(1) CntLanguage, CAST(NULL AS FLOAT) AttDays, CAST(NULL AS MONEY) AmountAllowance, al.Parameter Min_AttDays, al.DefaultAmount
	INTO #tmpEmployeeForeignLanguage
	FROM tblEmployeeForeignLanguage
	LEFT JOIN tblAllowanceSetting AS al ON al.AllowanceID = 3
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			WHERE ISNULL(IsForeign, 0) = 0
			) AND @FromDate BETWEEN EffectiveDate AND ISNULL(ExpiryDate, '9999-12-31') AND @ToDate BETWEEN EffectiveDate AND ISNULL(ExpiryDate, '9999-12-31')
	GROUP BY EmployeeID, al.Parameter, al.DefaultAmount

	DELETE
	FROM #tmpEmployeeForeignLanguage
	WHERE EXISTS (
			SELECT *
			FROM #AttendanceSummary a
			WHERE a.EmployeeID = #tmpEmployeeForeignLanguage.EmployeeID AND a.WorkingDays_Total < #tmpEmployeeForeignLanguage.Min_AttDays
			)

	UPDATE #tmpEmployeeForeignLanguage
	SET AttDays = a.WorkingDays_Total
	FROM #tmpEmployeeForeignLanguage e
	INNER JOIN #AttendanceSummary a ON e.EmployeeID = a.EmployeeID

	UPDATE #tmpEmployeeForeignLanguage
	SET AmountAllowance = CntLanguage * DefaultAmount
	FROM #tmpEmployeeForeignLanguage

	INSERT INTO #tblAllowance (EmployeeID, AllowanceID, ReceiveAmount, TotalPaidDays)
	SELECT EmployeeID, 3, AmountAllowance, AttDays
	FROM #tmpEmployeeForeignLanguage

	--petro
	SELECT e.EmployeeID, a.WorkingDays_Total, DefaultAmount, al.AllowanceID
	INTO #PetroAllowance
	FROM #tmpEmployeeList e
	INNER JOIN #AttendanceSummary a ON a.EmployeeID = e.EmployeeID
	LEFT JOIN tblAllowanceSetting al ON al.AllowanceID = 6
	WHERE a.WorkingDays_Total > al.Parameter AND Probationary = 0 AND ISNULL(IsForeign, 0) = 0

	INSERT INTO #tblAllowance (EmployeeID, AllowanceID, ReceiveAmount, TotalPaidDays)
	SELECT EmployeeID, 6, DefaultAmount, WorkingDays_Total
	FROM #PetroAllowance

	SELECT e.EmployeeID, e.PositionID, p.PositionAllowance AmountAllowance, aL.WorkingDays_Total
	INTO #FullAttendance
	FROM #tmpEmployeeList e
	INNER JOIN tblPosition p ON p.PositionID = e.PositionID
	INNER JOIN #AttendanceSummary al ON al.EmployeeID = e.EmployeeID
	WHERE p.PositionAllowance > 0 AND Probationary = 0 AND (ISNULL(WorkingHrs_Total, 0) + ISNULL(PaidLeaveHrs_Total, 0)) = RegularWorkdays * ISNULL(Std_Hour_PerDays, 0) AND ISNULL(IsForeign, 0) = 0

	SELECT lv.*
	INTO #lvHistory
	FROM tblLvHistory lv
	INNER JOIN tblLeaveType lt ON lt.LeaveCode = lv.LeaveCode
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #FullAttendance
			) AND LeaveDate BETWEEN @FromDate AND @ToDate AND lt.CutDiligent = 1

	DELETE
	FROM #FullAttendance
	WHERE EXISTS (
			SELECT 1
			FROM #lvHistory l
			WHERE l.EmployeeID = #FullAttendance.EmployeeID
			) OR EXISTS (
			SELECT *
			FROM tblInLateOutEarly ie
			WHERE ie.EmployeeID = #FullAttendance.EmployeeID AND IODate BETWEEN @FromDate AND @ToDate AND ie.ApprovedDeduct = 1
			)

	INSERT INTO #tblAllowance (EmployeeID, AllowanceID, ReceiveAmount, TotalPaidDays)
	SELECT EmployeeID, 8, AmountAllowance, WorkingDays_Total
	FROM #FullAttendance

	-- Dynamic pivot + merge #tblAllowance -> tblCustomInputImportMonthly
	DECLARE @YearParam NVARCHAR(10) = CAST(@Year AS NVARCHAR(10));
	DECLARE @MonthParam NVARCHAR(10) = CAST(@Month AS NVARCHAR(10));
	DECLARE @cols NVARCHAR(MAX), @colsList NVARCHAR(MAX), @colsUpdate NVARCHAR(MAX), @colsInsert NVARCHAR(MAX), @colsValues NVARCHAR(MAX), @sql NVARCHAR(MAX);

	-- 1) Build quoted column list from AllowanceID values that actually exist as columns in target table
	SELECT @cols = STUFF((
				SELECT ',' + QUOTENAME(CAST(a.AllowanceID AS NVARCHAR(50)))
				FROM (
					SELECT DISTINCT AllowanceID
					FROM #tblAllowance
					) a
				INNER JOIN sys.columns c ON c.name = CAST(a.AllowanceID AS NVARCHAR(50)) AND c.object_id = OBJECT_ID(N'dbo.tblCustomInputImportMonthly')
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

	IF @cols IS NULL OR LEN(@cols) = 0
	BEGIN
		PRINT 'No matching AllowanceID columns found in tblCustomInputImportMonthly. Skipping pivot/merge.';
	END
	ELSE
	BEGIN
		-- 2) Build helper fragments (unquoted names for iteration)
		-- @cols contains something like: [1],[2],[5]
		-- Extract bare names into XML to iterate
		SELECT @colsList = REPLACE(REPLACE(REPLACE(@cols, '[', ''), ']', ''), ' ', '');

		-- Build update assignments: t.[1] = ISNULL(s.[1],0), ...
		SELECT @colsUpdate = STUFF((
					SELECT ', t.' + QUOTENAME(value) + ' = ISNULL(s.' + QUOTENAME(value) + ',0)'
					FROM (
						SELECT value = y.i.value('.', 'NVARCHAR(4000)')
						FROM (
							SELECT CONVERT(XML, '<r>' + REPLACE(@colsList, ',', '</r><r>') + '</r>') AS xmlcol
							) z
						CROSS APPLY xmlcol.nodes('/r') y(i)
						) t
					FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

		-- Build insert columns and corresponding values list
		SELECT @colsInsert = STUFF((
					SELECT ',' + QUOTENAME(value)
					FROM (
						SELECT value = y.i.value('.', 'NVARCHAR(4000)')
						FROM (
							SELECT CONVERT(XML, '<r>' + REPLACE(@colsList, ',', '</r><r>') + '</r>') AS xmlcol
							) z
						CROSS APPLY xmlcol.nodes('/r') y(i)
						) t
					FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

		SELECT @colsValues = STUFF((
					SELECT ', ISNULL(s.' + QUOTENAME(value) + ',0)'
					FROM (
						SELECT value = y.i.value('.', 'NVARCHAR(4000)')
						FROM (
							SELECT CONVERT(XML, '<r>' + REPLACE(@colsList, ',', '</r><r>') + '</r>') AS xmlcol
							) z
						CROSS APPLY xmlcol.nodes('/r') y(i)
						) t
					FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

		-- 3) Build and execute dynamic pivot + merge
		SET @sql = N'
    -- create aggregated source (sum per employee per allowance)
    SELECT CAST(AllowanceID AS NVARCHAR(50)) AS AllowanceIDStr, EmployeeID, SUM(ISNULL(ReceiveAmount,0)) AS ReceiveAmount
    INTO ##srcAllowance
    FROM #tblAllowance

    GROUP BY CAST(AllowanceID AS NVARCHAR(50)), EmployeeID;

    -- pivot into wide table
    SELECT EmployeeID, ' + @cols + N'
    INTO ##tmpAllowancePivot
    FROM (
        SELECT EmployeeID, AllowanceIDStr, ReceiveAmount FROM ##srcAllowance
    ) src
    PIVOT (
        SUM(ReceiveAmount) FOR AllowanceIDStr IN (' + @cols + N')
    ) pvt;

    -- MERGE into target
    MERGE dbo.tblCustomInputImportMonthly AS t
    USING ##tmpAllowancePivot AS s
    ON t.EmployeeID = s.EmployeeID AND t.[Year] = ' + @YearParam + N' AND t.[Month] = ' + @MonthParam + N'
    WHEN MATCHED THEN
        UPDATE SET ' + @colsUpdate + N'
    WHEN NOT MATCHED THEN
        INSERT (EmployeeID, [Year], [Month], ' + @colsInsert + N')
        VALUES (s.EmployeeID, ' + @YearParam + N', ' + 
			@MonthParam + N', ' + @colsValues + N');

    DROP TABLE ##srcAllowance;
    DROP TABLE ##tmpAllowancePivot;';

		EXEC sp_executesql @sql;
	END

	UPDATE tsh
	SET SalaryHistoryID = att.SalaryHistoryID
	FROM tblCustomInputImportMonthly AS tsh
	INNER JOIN #AttendanceSummary AS att ON tsh.EmployeeID = att.EmployeeID AND tsh.[Year] = att.[Year] AND tsh.[Month] = att.[Month]
	WHERE tsh.[Year] = @Year AND tsh.[Month] = @Month AND tsh.EmployeeID IN (
			SELECT EmployeeID
			FROM #tmpEmployeeList
			);

	EXEC sp_AllowanceMonthly @Year = @Year, @Month = @Month

	IF (@SalCal = 1)
	BEGIN
		RETURN
	END
END
GO

IF object_id('[dbo].[sp_CustomInputImportMonthly]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_CustomInputImportMonthly] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_CustomInputImportMonthly] (@LoginID INT, @Month INT, @Year INT, @OptionView INT = 0)
AS
BEGIN
	DECLARE @Query NVARCHAR(max) = ''

	SELECT @Query += '[' + AllowanceCode + '] money,'
	FROM tblAllowanceSetting
	WHERE Visible = 1 AND AllowanceCode NOT IN (
			SELECT name
			FROM sys.columns
			WHERE object_id = object_id('tblCustomInputImportMonthly')
			)
	ORDER BY Ord

	IF len(@Query) > 3
	BEGIN
		SET @Query = left(@Query, len(@Query) - 1)
		SET @Query = 'alter table tblCustomInputImportMonthly add ' + @Query

		EXEC (@query)
	END

	DECLARE @ToDate DATE

	SELECT @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod(@Month, @Year)

	SELECT EmployeeID, FullName
	INTO #tmpEmloyeeList
	FROM dbo.fn_vtblEmployeeList_Bydate(@ToDate, '-1', @LoginID)
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
		WHERE object_id = object_id('tblCustomInputImportMonthly') AND name NOT IN ('EmployeeID', 'Month', 'Year', 'Remark') AND name NOT IN (
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

IF object_id('[dbo].[sp_AllowanceMonthly]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_AllowanceMonthly] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_AllowanceMonthly] (@Year INT, @Month INT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @cols NVARCHAR(MAX), @sql NVARCHAR(MAX), @addQuery NVARCHAR(MAX) = '';

	SELECT @addQuery += N'
		IF NOT EXISTS (
			SELECT 1
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = ''tblCustomInputImportMonthly''
			AND COLUMN_NAME = ' + QUOTENAME(AllowanceID, '''') + N'
		)
		BEGIN
			ALTER TABLE dbo.tblCustomInputImportMonthly ADD [' + CAST(AllowanceID AS NVARCHAR(5)) + N'] MONEY NULL;
		END;'
	FROM tblAllowanceSetting
	WHERE Visible = 1

	EXEC sp_executesql @addQuery;

	DECLARE @alterQuery NVARCHAR(MAX) = '';

	SELECT @alterQuery += N'ALTER TABLE dbo.tblCustomInputImportMonthly ALTER COLUMN [' + CAST(AllowanceID AS NVARCHAR(5)) + N'] MONEY NULL;'
	FROM tblAllowanceSetting
	WHERE Visible = 1

	EXEC sp_executesql @alterQuery;

	SELECT @cols = STUFF((
				SELECT ', ' + QUOTENAME(AllowanceID)
				FROM tblAllowanceSetting
				WHERE Visible = 1
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Remove old rows for this period
		DELETE
		FROM dbo.tblAllowanceProcessMonthly
		WHERE [Year] = @Year AND [Month] = @Month;

		-- Build dynamic SQL to UNPIVOT columns into rows
		SET @sql = N'
        INSERT INTO dbo.tblAllowanceProcessMonthly (EmployeeID, [Year], [Month], AllowanceID, ReceiveAmount)
        SELECT EmployeeID, [Year], [Month], AllowanceID, TRY_CAST(ReceiveAmount AS MONEY)
        FROM (
            SELECT EmployeeID, [Year], [Month], ' + @cols + N'
            FROM dbo.tblCustomInputImportMonthly
            WHERE [Year] = ' + CAST(@Year AS NVARCHAR(10)) + N' AND [Month] = ' + CAST(@Month AS NVARCHAR(10)) + N'
        ) t
        UNPIVOT (
            ReceiveAmount FOR AllowanceID IN (' + @cols + N')
        ) u
        WHERE ReceiveAmount IS NOT NULL;';

		EXEC sp_executesql @sql;

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		IF XACT_STATE() <> 0
			ROLLBACK TRANSACTION;

		DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE();

		RAISERROR ('sp_AllowanceMonthly failed: %s', 16, 1, @errMsg);
	END CATCH
END
GO

IF object_id('[dbo].[SALCAL_MAIN]') IS NULL
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

	--TRIPOD: PercentProbation in tblEmployeeType
	IF EXISTS (
			SELECT 1
			FROM #tblSalDetail sh
			INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
			WHERE (ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate OR ProbationEndDate > @ToDateTruncate) AND te.HireDate <> te.ProbationEndDate
			)
		--IF @PROBATION_PERECNT < 100.0
	BEGIN
		UPDATE #tblSalDetail
		SET PercentProbation = ISNULL(tsh.PercentProbation, et.PercentProbation)
		FROM #tblSalDetail sh
		INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		LEFT JOIN tblSalaryHistory tsh ON sh.SalaryHistoryID = tsh.SalaryHistoryID
		LEFT JOIN tblEmployeeType et ON te.EmployeeTypeID = et.EmployeeTypeID
		WHERE (ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate OR ProbationEndDate > @ToDateTruncate) AND te.HireDate <> te.ProbationEndDate

		--cuoi thang hoac thang sau het thu viec
		-- UPDATE #tblSalDetail
		-- SET BasicSalaryOrg = BasicSalary, BasicSalary = BasicSalary * sh.PercentProbation / 100.0
		-- FROM #tblSalDetail sh
		-- INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		-- WHERE (ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate OR ProbationEndDate > @ToDateTruncate) AND te.HireDate <> te.ProbationEndDate
		--het thu viec trong thang nay
		UPDATE #tblSalDetail
		SET FromDate = DATEADD(day, 1, ProbationEndDate)
		FROM #tblSalDetail sh
		INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		WHERE ISNULL(sh.PercentProbation, 0) > 0 AND ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate AND te.HireDate <> te.ProbationEndDate

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
				END, te.ProbationEndDate, sh.BasicSalary, sh.BasicSalary * @PROBATION_PERECNT / 100.0, sh.SalCalRuleID, 1, sh.BaseSalRegionalID, IsNet, PayrollTypeCode, sh.WorkingHoursPerDay, sh.CurrencyCode
		FROM #tblSalDetail sh
		INNER JOIN #tblEmployeeIDList te ON sh.EmployeeID = te.EmployeeID
		WHERE te.ProbationEndDate BETWEEN @FromDate AND @ToDateTruncate AND te.HireDate <> te.ProbationEndDate AND ISNULL(sh.isNET, 0) = 0
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

	--TRIPOD
	EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 1

	SELECT *
	INTO #AttendanceSummary
	FROM tblAttendanceSummary
	WHERE Year = @Year AND Month = @Month AND EmployeeID IN (
			SELECT EmployeeID
			FROM #tblSalDetail
			)

	--TRIPOD: gross salary - (gross salary with allowances/number of working hours * (number of working hours - number of actual working hours))
	UPDATE #tblSalDetail
	SET RegularAmt = ROUND(GrossSalary - (TotalSalary / (m.STD_WorkingHours)) * ((m.STD_WorkingHours) - WorkingHrs_Total), 0), PaidLeaveAmt = ROUND(PaidLeaveHrs_Total * (TotalSalary / (m.STD_WorkingHours)), 0), SalaryPerHour = (TotalSalary / (m.STD_WorkingHours)), SalaryPerHourOT = (TotalSalary / (m.STD_WorkingHours)), UnpaidLeaveAmount = ROUND(a.UnpaidLeaveHrs * (TotalSalary / (m.STD_WorkingHours)), 0)
	FROM #tblSalDetail s
	INNER JOIN #AttendanceSummary a ON a.EmployeeID = s.EmployeeID AND CAST(a.FromDate AS DATE) = CAST(s.FromDate AS DATE) AND CAST(a.ToDate AS DATE) = CAST(s.ToDate AS DATE)
	LEFT JOIN #tmpMonthlyPayrollCheckList m ON m.EmployeeID = s.EmployeeID

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
	SELECT o.OTKind, o.EmployeeID, @Month Month, @Year Year, s.SalaryHistoryID, os.OvValue AS OTRate, SUM(o.ApprovedHours) AS OTHour, CAST(0 AS FLOAT(53)) OTAmount, s.SalaryPerDayOT, s.SalaryPerHourOT, s.STD_WD, s.LatestSalEntry, MAX(os.NSPercents) AS NSPercents, CAST(0 AS MONEY) AS NightShiftAmount
	INTO #tblSal_OT_Detail
	FROM #tblOTList o
	INNER JOIN #tblSalDetail s ON o.EmployeeID = s.EmployeeID AND o.OTDate BETWEEN s.FromDate AND s.ToDate
	INNER JOIN tblOvertimeSetting os ON o.OTKind = os.OTKind
	GROUP BY o.OTKind, o.EmployeeID, s.SalaryHistoryID, os.OvValue, s.SalaryPerDayOT, s.SalaryPerHourOT, s.SalaryPerHour, s.STD_WD, s.LatestSalEntry

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
		, ROUND(SUM(OTAmount), @ROUND_OT_NS_Detail_UNIT) TotalOTAmount, ROUND(SUM(NightShiftAmount), @ROUND_OT_NS_Detail_UNIT) NightShiftAmount
	INTO #SummaryOT
	FROM #tblSal_OT_Detail o
	LEFT JOIN #AttendanceSummary a ON o.EmployeeID = a.EmployeeID AND o.LatestSalEntry = a.PeriodID
	WHERE isnull(a.TotalExcessOT, 0) = 0
	GROUP BY o.EmployeeID, o.SalaryHistoryID, LatestSalEntry
	
	UNION
	
	SELECT o.EmployeeID, o.SalaryHistoryID, LatestSalEntry, ROUND(a.TaxableOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) TaxableOTAmount, ROUND(a.NontaxableOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) NoneTaxableOTAmount -- làm vầy cộng lại mới tròn
		, ROUND(a.TotalOT * SalaryPerHourOT, @ROUND_OT_NS_Detail_UNIT) TotalOTAmount, ROUND(SUM(NightShiftAmount), @ROUND_OT_NS_Detail_UNIT) NightShiftAmount
	FROM #tblSal_OT_Detail o
	LEFT JOIN #AttendanceSummary a ON o.EmployeeID = a.EmployeeID AND o.LatestSalEntry = a.PeriodID
	WHERE isnull(a.TotalExcessOT, 0) > 0
	GROUP BY o.EmployeeID, o.SalaryHistoryID, LatestSalEntry, a.TaxableOT, a.NontaxableOT, a.TotalOT, o.SalaryPerHourOT

	UPDATE #tblSalDetail
	SET TaxableOTTotal = round(tmp.TaxableOTAmount, @ROUND_SALARY_UNIT), NoneTaxableOTTotal = round(tmp.NoneTaxableOTAmount, @ROUND_OT_NS_Detail_UNIT), TotalOTAmount = tmp.TotalOTAmount, NightShiftAmount = tmp.NightShiftAmount
	FROM #tblSalDetail s
	INNER JOIN #SummaryOT tmp ON s.EmployeeID = tmp.EmployeeID AND s.SalaryHistoryID = tmp.SalaryHistoryID AND s.LatestSalEntry = tmp.LatestSalEntry

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

IF object_id('[dbo].[sp_foreignSalarySummary]') IS NULL
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

	SELECT st.*
	INTO #tblSal_Tax
	FROM tblSal_Tax st
	INNER JOIN #tmpEmployeeList te ON st.EmployeeID = te.EmployeeID
	WHERE st.Year = @Year AND st.Month = @Month

	SELECT ROW_NUMBER() OVER (
			ORDER BY Raw_BasicSalary DESC, HireDate
			) AS STT, s.EmployeeID, s.FullName, s.DepartmentName, sal.Raw_BasicSalary, sal.Raw_BasicSalary * sal.ExchangeRate_Contract AS SalaryContract, ats.WorkingHrs_Total, RegularAmt / Raw_ExchangeRate AS Net_RegularAmt, RegularAmt, CAST(NULL AS MONEY) AS percent15HouseRent, house.Amount AS House, house.Amount AS HouseCalcTax, meal.Amount AS MealCalcTax, ins.EmployeeUI, ins.EmployeeSI, ins.EmployeeHI, ins.EmployeeSI, ins.CompanySI, ins.CompanyHI, tax.EmployeeExemption, tax.FamilyExemption, tax.IncomeTaxable, tax.TaxAmt, tax.TaxableIncome_SalaryOnly, tax.TaxAmt_SalaryOnly, ISNULL(tax.TaxAmt, 0) - ISNULL(tax.TaxAmt_SalaryOnly, 0) AS CompanyPay, sal.GrossTakeHome, sal.GrossTakeHome / Raw_ExchangeRate AS Net_GrossTakeHome
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

	CREATE TABLE #ExportConfig (ORD INT identity PRIMARY KEY, TableIndex VARCHAR(max), RowIndex INT, ColumnName NVARCHAR(200), ParseType NVARCHAR(max), Position NVARCHAR(200), SheetIndex INT, TestDescription NVARCHAR(max), WithHeader INT, WithBestFit BIT, ColumnList_formatCell VARCHAR(200), formatCell VARCHAR(200))

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex)
	SELECT 0, 'Table|ZeroMeanNull=1 ', 'B11', 0

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (1, 'Table_NonInsert', 'B3', 0, 0)

	INSERT INTO #ExportConfig (TableIndex, ParseType, Position, SheetIndex, WithHeader)
	VALUES (2, 'Table_NonInsert', 'E16', 0, 0)

	SELECT *
	FROM #ExportConfig
END
	--exec sp_foreignSalarySummary 3,7,2025
GO


