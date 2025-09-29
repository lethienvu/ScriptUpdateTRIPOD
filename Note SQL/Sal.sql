USE Paradise_TRIPOD
GO
if object_id('[dbo].[sp_LockAttendanceData_CheckStatus]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_LockAttendanceData_CheckStatus] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_LockAttendanceData_CheckStatus] @Month INT, @Year INT, @LoginID INT, @PeriodID INT = 0, @OptionView INT = 0
AS
BEGIN
	-- huy thong bao khoa cong
	DECLARE @Fromdate DATETIME, @Todate DATETIME

	SELECT @Fromdate = Fromdate, @Todate = Todate
	FROM dbo.fn_Get_SalaryPeriod_Term(@Month, @Year, @PeriodID)

	-- IF NOT EXISTS (
	-- 		SELECT ws.EmployeeID
	-- 		FROM dbo.tblWSchedule AS ws
	-- 		LEFT OUTER JOIN dbo.tblatt_lock AS l ON ws.EmployeeID = l.EmployeeID AND ws.ScheduleDate = l.DATE
	-- 		WHERE ScheduleDate BETWEEN @Fromdate AND @Todate AND DATE IS NULL
	-- 		)
	-- 	EXEC sp_DeleteRequirementsWorkflow @TaskName = 'Notify_LockAttendanceData_Mess', @CurrentMenuID = 'MnuTAD125'

	SET NOCOUNT ON;

	SELECT EmployeeID, HireDate, TerminateDate
	INTO #tmpEmpLock
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@Todate, '-1', @LoginID)
    WHERE ISNULL(@OptionView, '-1') = '-1'
	OR ISNULL(@OptionView, 0) = 0
	OR (ISNULL(@OptionView, 0) = 1 AND IsForeign = 0)
	OR (ISNULL(@OptionView, 0) = 2 AND (ISNULL(IsForeign, 0) = 1))

	SELECT te.EmployeeID, em.FullName, @PeriodID AS PeriodID, @Month AS Month, @Year AS Year, cast(N'Đang mở' AS NVARCHAR(max)) AS Remark
	INTO #tmp
	FROM #tmpEmpLock te
	LEFT JOIN tblEmployee em ON te.EmployeeID = em.EmployeeID

	UPDATE e
	SET e.Remark = N'Đã khóa công'
	FROM #tmp e
	INNER JOIN #tmpEmpLock te ON e.EmployeeID = te.EmployeeID
	INNER JOIN tblAtt_LockMonth l ON e.EmployeeID = l.EmployeeID AND l.Month = @Month AND l.Year = @Year AND l.PeriodID = @PeriodID

	UPDATE e
	SET e.Remark = e.Remark + N' - Đã khóa lương'
	FROM #tmp e
	INNER JOIN #tmpEmpLock te ON e.EmployeeID = te.EmployeeID
	INNER JOIN tblSal_Lock l ON e.EmployeeID = l.EmployeeID AND l.Month = @Month AND l.Year = @Year AND l.PeriodID = @PeriodID

	DELETE #tmp
	FROM #tmp e
	INNER JOIN #tmpEmpLock te ON e.EmployeeID = te.EmployeeID
	WHERE (te.HireDate > @ToDate OR te.TerminateDate <= @Fromdate) AND NOT EXISTS (
			SELECT 1
			FROM tblMonthlyPayrollCheckList m
			WHERE e.EmployeeID = m.EmployeeID AND m.Month = @Month AND m.Year = @Year AND m.isSalCal = 1
			)

	SELECT *
	FROM #tmp

	DROP TABLE #tmpEmpLock
END
GO
exec sp_LockSalary_CheckStatus @Month=8,@Year=2025,@LoginID=3,@OptionView=0