
if object_id('[dbo].[sp_processShiftChange]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_processShiftChange] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_processShiftChange] (@LoginID INT, @FromDate DATETIME, @ToDate DATETIME)
AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFIRST 1;

	DECLARE @Month INT = MONTH(@FromDate), @Year INT = YEAR(@FromDate)

	SELECT @Month = Month, @Year = Year
	FROM dbo.fn_Get_Sal_Month_Year(@FromDate)

	IF EXISTS (
			SELECT 1
			FROM tblDivision
			WHERE DivisionID NOT IN (
					SELECT DivisionID
					FROM tblDivisionSatWork
					WHERE Month = @Month AND Year = @Year
					)
			)
	BEGIN
			;

		WITH Saturdays
		AS (
			SELECT DATEADD(DAY, number, DATEFROMPARTS(@Year, @Month, 1)) AS SaturdayDate
			FROM master..spt_values
			WHERE type = 'P' AND DATEPART(MONTH, DATEADD(DAY, number, DATEFROMPARTS(@Year, @Month, 1))) = @Month AND DATENAME(WEEKDAY, DATEADD(DAY, number, DATEFROMPARTS(@Year, @Month, 1))) = 'Saturday'
			), NumberedSaturdays
		AS (
			SELECT SaturdayDate, ROW_NUMBER() OVER (
					ORDER BY SaturdayDate
					) AS rn
			FROM Saturdays
			)
		SELECT MAX(CASE
					WHEN rn = 2
						THEN SaturdayDate
					END) AS SecondSaturday, MAX(CASE
					WHEN rn = 4
						THEN SaturdayDate
					END) AS FourthSaturday
		INTO #tblMonthSat
		FROM NumberedSaturdays

		INSERT INTO tblDivisionSatWork (DivisionID, Month, Year, SaturdayDate, SaturdayDate_2nd)
		SELECT d.DivisionID, @Month, @Year, ms.SecondSaturday, ms.FourthSaturday
		FROM tblDivision d
		CROSS JOIN #tblMonthSat ms
		WHERE NOT EXISTS (
				SELECT 1
				FROM tblDivisionSatWork ds
				WHERE ds.DivisionID = d.DivisionID AND ds.Month = @Month AND ds.Year = @Year
				)
	END

	SELECT EmployeeID, EmployeeTypeID
	INTO #employeeList
	FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, '-1', @LoginID)

	SELECT *
	INTO #tblAtt_Lock
	FROM tblAtt_Lock l WITH (NOLOCK)
	WHERE EXISTS (
			SELECT 1
			FROM #employeeList te
			WHERE l.EmployeeID = te.EmployeeID
			) AND DATE BETWEEN @FromDate AND @ToDate

	SELECT EmployeeID, SaturdayDate AS SatDate
	INTO #SatWorkList
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)
	--WHERE SaturdayDate BETWEEN @FromDate AND @ToDate
	
	UNION
	
	SELECT EmployeeID, SaturdayDate_2nd AS SatDate
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)

	UPDATE s
	SET HolidayStatus = 0, DateStatus = 3
	FROM tblWSchedule s
	INNER JOIN #SatWorkList sw ON s.EmployeeID = sw.EmployeeID AND s.ScheduleDate = sw.SatDate
	LEFT JOIN #employeeList e ON s.EmployeeID = e.EmployeeID
	LEFT JOIN tblEmployeeType et ON e.EmployeeTypeID = et.EmployeeTypeID
	WHERE et.isLocalStaff = 1 AND s.ScheduleDate BETWEEN @FromDate AND @ToDate AND NOT EXISTS (
			SELECT 1
			FROM #tblAtt_Lock al
			WHERE s.EmployeeID = al.EmployeeID AND s.ScheduleDate = al.DATE
			)

	--Xử lý swap shift:
	SELECT *, CAST(NULL AS INT) HolidayStatus_SF, CAST(NULL AS INT) HolidayStatus_ST
	INTO #SwapShift
	FROM tblSwapShift
	WHERE (CAST(SwapFrom AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND CAST(SwapTo AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)) AND EmployeeID IN (
			SELECT EmployeeID
			FROM #employeeList te
			)

	UPDATE #SwapShift
	SET HolidayStatus_SF = CASE
			WHEN DATENAME(WEEKDAY, SwapFrom) = 'Sunday' OR (
					DATENAME(WEEKDAY, SwapFrom) = 'Saturday' AND NOT EXISTS (
						SELECT 1
						FROM #SatWorkList sat
						WHERE sat.SatDate = SwapFrom AND sat.EmployeeID = s.EmployeeID
						) AND et.IsLocalStaff = 1
					)
				THEN 1
			WHEN SwapFrom IN (
					SELECT LeaveDate
					FROM tblholiday
					WHERE YEAR(LeaveDate) = @Year
					)
				THEN 2
			ELSE 0
			END, HolidayStatus_ST = CASE
			WHEN DATENAME(WEEKDAY, SwapTo) = 'Sunday' OR (
					DATENAME(WEEKDAY, SwapTo) = 'Saturday' AND NOT EXISTS (
						SELECT 1
						FROM #SatWorkList sat
						WHERE sat.SatDate = SwapTo AND sat.EmployeeID = s.EmployeeID
						) AND et.IsLocalStaff = 1
					)
				THEN 1
			WHEN SwapTo IN (
					SELECT LeaveDate
					FROM tblholiday
					WHERE YEAR(LeaveDate) = @Year
					)
				THEN 2
			ELSE 0
			END
	FROM #SwapShift s
	INNER JOIN #employeeList e ON s.EmployeeID = e.EmployeeID
	LEFT JOIN tblEmployeeType et ON e.EmployeeTypeID = et.EmployeeTypeID

	--swap to phải là ngày đi làm -> ngày nghỉ
	-- Đổi HolidayStatus cho SwapFrom và SwapTo
	UPDATE d
	SET HolidayStatus = CASE
			WHEN d.ScheduleDate = ss.SwapFrom
				THEN ss.HolidayStatus_ST
			WHEN d.ScheduleDate = ss.SwapTo
				THEN ss.HolidayStatus_SF
			ELSE d.HolidayStatus
			END, System_Notes = N'Change day off: ' + CAST(DAY(SwapFrom) AS VARCHAR(2)) + ' -> ' + CAST(DAY(SwapTo) AS VARCHAR(2))
	FROM tblWSchedule d
	INNER JOIN #SwapShift ss ON d.EmployeeID = ss.EmployeeID AND (d.ScheduleDate = ss.SwapFrom OR d.ScheduleDate = ss.SwapTo)
	WHERE NOT EXISTS (
			SELECT 1
			FROM #tblAtt_Lock al
			WHERE d.EmployeeID = al.EmployeeID AND d.ScheduleDate = al.DATE
			)
		--WHERE d.DateStatus <> 3
END
GO


insert into tblTmpAttend(AttTime,EmployeeID,AttState,MachineNo)select AttTime,EmployeeID,AttState,MachineNo from (	select CAST(N'2025-09-23 07:30:00' as datetime) AttTime,CAST(N'62250050' as varchar(20)) EmployeeID,CAST(1 as tinyint) AttState,CAST(999 as int) MachineNo	union all select N'2025-09-23 16:07:00',N'62250050',2,999	union all select N'2025-09-24 07:05:00',N'62250050',1,999	union all select N'2025-09-24 07:30:00',N'62250051',1,999	union all select N'2025-09-24 16:00:00',N'62250051',2,999	union all select N'2025-09-24 16:06:00',N'62250050',2,999	union all select N'2025-09-25 07:05:00',N'62250050',1,999	union all select N'2025-09-25 07:22:00',N'62250051',1,999	union all select N'2025-09-25 16:05:00',N'62250050',2,999	union all select N'2025-09-25 16:16:00',N'62250051',2,999	union all select N'2025-09-26 07:06:00',N'62250050',1,999	union all select N'2025-09-26 07:20:00',N'62250051',1,999	union all select N'2025-09-26 16:04:00',N'62250050',2,999	union all select N'2025-09-26 16:04:00',N'62250051',2,999	union all select N'2025-09-27 07:03:00',N'62250050',1,999	union all select N'2025-09-27 07:21:00',N'62250051',1,999	union all select N'2025-09-27 16:03:00',N'62250050',2,999	union all select N'2025-09-27 16:04:00',N'62250051',2,999) tmpData