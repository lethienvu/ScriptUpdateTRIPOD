USE Paradise_TRIPOD
GO
if object_id('[dbo].[spDailyAttendanceData]') is null
	EXEC ('CREATE PROCEDURE [dbo].[spDailyAttendanceData] as select 1')
GO

ALTER PROCEDURE [dbo].[spDailyAttendanceData] (@FromDate DATE = NULL, @ToDate DATE = NULL, @Month INT = NULL, @Year INT = NULL, @LoginID INT = 3, @EmployeeID_Pram NVARCHAR(20) = '-1', @OptionView INT = 0)
AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFIRST 1;

	IF (len(isnull(@EmployeeID_Pram, '')) < 1)
		SET @EmployeeID_Pram = '-1'

	-- truncate bảng tblDataTempForCheckRemainAL
	TRUNCATE TABLE tblDataTempForCheckRemainAL

	SELECT elb.EmployeeID, elb.FullName, HireDate, LastWorkingDate, d.DepartmentName
	INTO #fn_vtblEmployeeList_Bydate
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@ToDate, @EmployeeID_Pram, @LoginID) elb
	INNER JOIN tblDepartment d ON elb.DepartmentID = d.DepartmentID
	WHERE (ISNULL(@OptionView, '-1') = '-1' OR @OptionView = 0 OR (@OptionView = 1 AND elb.IsForeign = 0) OR (@OptionView = 2 AND elb.IsForeign = 1))

	CREATE CLUSTERED INDEX IX_Employees ON #fn_vtblEmployeeList_Bydate (EmployeeID);

	SELECT EmployeeID, AttDate, AttStart, AttEnd, TAStatus, Period, WorkingTimeApproved, TimeReason, WorkingTime
	INTO #tblHasTA
	FROM tblHasTA
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND AttDate BETWEEN @FromDate AND @ToDate

	CREATE CLUSTERED INDEX IX_Attendance ON #tblHasTA (EmployeeID, AttDate);

	SELECT ws.EmployeeID, ws.ScheduleDate, ws.ShiftID, ws.HolidayStatus, ws.Approved, ws.DateStatus, w.WeekDayEN AS [DateName], ss.ShiftCode, ws.System_Notes Notes, ss.Std_Hour_PerDays
	INTO #tblWSchedule
	FROM tblWSchedule ws
	INNER JOIN tblShiftSetting ss ON ws.ShiftID = ss.ShiftID
	LEFT JOIN WeekDayVietnamese w ON DATEPART(WEEKDAY, ws.ScheduleDate) = w.WeekDayID
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND ScheduleDate BETWEEN @FromDate AND @ToDate
	
	DELETE w
	FROM #tblWSchedule w
	INNER JOIN #fn_vtblEmployeeList_Bydate e ON e.EmployeeID = w.EmployeeID
	WHERE w.ScheduleDate < e.HireDate OR w.ScheduleDate > e.LastWorkingDate

	CREATE CLUSTERED INDEX IX_Schedule ON #tblWSchedule (EmployeeID, ScheduleDate);

	SELECT l.EmployeeID, l.LeaveCode, LeaveDate, LeaveStatus, LvAmount, StatusID, Reason, l.LvAmount * (lt.PaidRate / 100) AS PaidLeave
	INTO #tblLvHistory
	FROM tblLvHistory l
	INNER JOIN tblLeaveType lt ON lt.LeaveCode = l.LeaveCode
	WHERE l.EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND LeaveDate BETWEEN @FromDate AND @ToDate

	SELECT EmployeeId, OTDate, SUM(ApprovedHours) AS OTHours
	INTO #tblOTList
	FROM tblOTList
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND Approved = 1 AND OTDate BETWEEN @FromDate AND @ToDate
	GROUP BY EmployeeId, OTDate

	CREATE CLUSTERED INDEX IX_OTList ON #tblOTList (EmployeeId, OTDate);

	SELECT EmployeeID, [Date], SUM(HourApprove) NSHours
	INTO #tblNightShiftList
	FROM tblNightShiftList
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND Approval = 1 AND [Date] BETWEEN @FromDate AND @ToDate
	GROUP BY EmployeeID, [Date]

	SELECT EmployeeID, IODate, SUM(IOMinutesDeduct / 60.0) AS IOMinutes
	INTO #tblInLateOutEarly
	FROM tblInLateOutEarly
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND ApprovedDeduct = 1 AND IODate BETWEEN @FromDate AND @ToDate
	GROUP BY EmployeeID, IODate

	DECLARE @bit BIT

	-- data nền
	SELECT elb.EmployeeID, ws.[DateName], ws.ScheduleDate AS AttDate, elb.FullName, ws.ScheduleDate, ws.ShiftID, ws.ShiftCode, hta.TimeReason, hta.Period, hta.AttStart, hta.AttStart In_0, hta.AttEnd Out_0, hta.AttEnd, hta.TAStatus, hta.WorkingTime WorkingTime_0, lh.PaidLeave, ot.OTHours, ns.NSHours, IO.IOMinutes, elb.DepartmentName DepartmentName, lh.LeaveCode AS LeaveCode, lh.LeaveDate, lh.LeaveStatus, lh.LvAmount, lh.StatusID, hta.WorkingTimeApproved WorkingTimeApproved_0, isnull(lh.Reason, hta.TimeReason) Reason, ws.HolidayStatus, isnull(ws.Approved, 0) Approved, ws.DateStatus, ws.Notes, CAST(0 AS INT) IsReadInout2, @bit NoIn, @bit NoOut, @bit NoInNoOut, @bit WorkOnHoliday, @bit Holiday, @bit Leave, ws.Std_Hour_PerDays, @bit OTPlan
	INTO #tempData
	FROM #fn_vtblEmployeeList_Bydate elb
	INNER JOIN #tblWSchedule ws ON ws.EmployeeID = elb.EmployeeID
	LEFT JOIN #tblHasTA hta ON hta.EmployeeID = elb.EmployeeID AND hta.AttDate = ws.ScheduleDate
	LEFT JOIN #tblOTList ot ON ot.EmployeeID = ws.EmployeeID AND ot.OTDate = hta.AttDate
	LEFT JOIN #tblLvHistory lh ON lh.LeaveDate = ws.ScheduleDate AND lh.EmployeeID = ws.EmployeeID
	LEFT JOIN #tblNightShiftList ns ON ns.EmployeeID = ws.EmployeeID AND ns.[Date] = hta.AttDate
	LEFT JOIN #tblInLateOutEarly IO ON IO.EmployeeID = ws.EmployeeID AND IO.IODate = hta.AttDate
	WHERE ws.ScheduleDate BETWEEN @FromDate AND @ToDate
	ORDER BY EmployeeID, AttDate

	ALTER TABLE #tempData

	DROP COLUMN NoIn, NoOut, NoInNoOut, WorkOnHoliday, Holiday, Leave, AttStart, AttEnd

	UPDATE t
	SET Reason = d.Reason
	FROM #tempData t
	INNER JOIN #tempData d ON t.EmployeeID = d.EmployeeID AND t.AttDate = d.AttDate AND t.Period <> d.Period
	WHERE t.Reason IS NULL AND d.Reason IS NOT NULL

	UPDATE t
	SET IsReadInout2 = 1
	FROM #tempData t
	INNER JOIN tblShiftSetting ss ON t.ShiftID = ss.ShiftID
	WHERE CAST(ss.WorkEnd AS TIME) = CAST(ss.OTAfterStart AS TIME)

	UPDATE #tempData
	SET FullName = '|Action=|Object=DataSetting.sp_GetTmpAttendByDate|Params=@EmployeeID=' + EmployeeID + '&@AttDate=' + convert(VARCHAR, AttDate, 23) + '&@LoginID=' + cast(@LoginID AS VARCHAR(6)) + N'&@LanguageID=VN&@datasetting=1|Text=' + FullName

	DECLARE @css NVARCHAR(MAX) = '', @html NVARCHAR(MAX) = '', @js NVARCHAR(MAX) = ''

	SELECT
		COUNT(DISTINCT EmployeeID) AS TotalEmployees,
		COUNT(DISTINCT AttDate) AS TotalDays,
		DATEDIFF(SECOND, @FromDate, @ToDate) AS ProcessingSeconds,
		SUM(CASE WHEN In_0 IS NULL AND Out_0 IS NOT NULL THEN 1 ELSE 0 END) AS MissingCheckIn,
		SUM(CASE WHEN In_0 IS NOT NULL AND Out_0 IS NULL THEN 1 ELSE 0 END) AS MissingCheckOut,
		SUM(CASE WHEN In_0 IS NULL AND Out_0 IS NULL THEN 1 ELSE 0 END) AS MissingCheckInOut,
		SUM(CASE WHEN WorkingTime_0 IS NULL OR WorkingTime_0 = 0 THEN 1 ELSE 0 END) AS MissingWorkingTime,
		SUM(CASE WHEN (ISNULL(PaidLeave,0) + ISNULL(WorkingTime_0,0)) > t.Std_Hour_PerDays THEN 1 ELSE 0 END) AS OverStandardTime,
		SUM(CASE WHEN IOMinutes > 0 THEN 1 ELSE 0 END) AS LateOrEarly,
		SUM(CASE WHEN OTHours > 0 AND t.OTPlan IS NULL THEN 1 ELSE 0 END) AS OTWithoutPlan,
		SUM(CASE WHEN HolidayStatus > 0 THEN 1 ELSE 0 END) AS WorkOnHoliday,
		SUM(CASE WHEN LeaveCode IS NOT NULL THEN 1 ELSE 0 END) AS OnLeave,
		SUM(CASE WHEN HolidayStatus > 0 THEN 1 ELSE 0 END) AS OnHoliday
	INTO #Summary
	FROM #tempData t

	SELECT @html = N'
	<div class="stat-widget">
	<h3>Thống kê chấm công</h3>
	<div class="stat-row">
		<div class="stat-card">
		<span class="stat-icon">👤</span>
		<span class="stat-label">Nhân viên</span>
		<span class="stat-value" id="stat-employees">' + CAST(TotalEmployees AS NVARCHAR) + '</span>
		</div>
		<div class="stat-card">
		<span class="stat-icon">📅</span>
		<span class="stat-label">Số ngày</span>
		<span class="stat-value" id="stat-days">' + CAST(TotalDays AS NVARCHAR) + '</span>
		</div>
	</div>
	<div class="stat-row">
		<div class="stat-card">
		<span class="stat-icon">⏱️</span>
		<span class="stat-label">Xử lý (giây)</span>
		<span class="stat-value" id="stat-seconds">' + CAST(ProcessingSeconds AS NVARCHAR) + '</span>
		</div>
	</div>
	<div class="stat-row">
		<div class="stat-card">
		<span class="stat-icon">⚠️</span>
		<span class="stat-label">Thiếu vào</span>
		<span class="stat-value" id="stat-missing-in">' + CAST(MissingCheckIn AS NVARCHAR) + '</span>
		</div>
		<div class="stat-card">
		<span class="stat-icon">⚠️</span>
		<span class="stat-label">Thiếu ra</span>
		<span class="stat-value" id="stat-missing-out">' + CAST(MissingCheckOut AS NVARCHAR) + '</span>
		</div>
	</div>
	<div class="stat-row">
		<div class="stat-card">
		<span class="stat-icon">⏳</span>
		<span class="stat-label">Thiếu giờ công</span>
		<span class="stat-value" id="stat-missing-work">' + CAST(MissingWorkingTime AS NVARCHAR) + '</span>
		</div>
		<div class="stat-card">
		<span class="stat-icon">🚩</span>
		<span class="stat-label">Vượt giờ chuẩn</span>
		<span class="stat-value" id="stat-over-standard">' + CAST(OverStandardTime AS NVARCHAR) + '</span>
		</div>
	</div>
	<div class="stat-row">
		<div class="stat-card">
		<span class="stat-icon">🕒</span>
		<span class="stat-label">Trễ/Sớm</span>
		<span class="stat-value" id="stat-late-early">' + CAST(LateOrEarly AS NVARCHAR) + '</span>
		</div>
		<div class="stat-card">
		<span class="stat-icon">💼</span>
		<span class="stat-label">OT không KH</span>
		<span class="stat-value" id="stat-ot-noplan">' + CAST(OTWithoutPlan AS NVARCHAR) + '</span>
		</div>
	</div>
	<div class="stat-row">
		<div class="stat-card">
		<span class="stat-icon">🎉</span>
		<span class="stat-label">Làm ngày lễ</span>
		<span class="stat-value" id="stat-work-holiday">' + CAST(WorkOnHoliday AS NVARCHAR) + '</span>
		</div>
		<div class="stat-card">
		<span class="stat-icon">🌴</span>
		<span class="stat-label">Nghỉ phép</span>
		<span class="stat-value" id="stat-leave">' + CAST(OnLeave AS NVARCHAR) + '</span>
		</div>
		<div class="stat-card">
		<span class="stat-icon">🏖️</span>
		<span class="stat-label">Nghỉ lễ</span>
		<span class="stat-value" id="stat-holiday">' + CAST(OnHoliday AS NVARCHAR) + '</span>
		</div>
	</div>
	</div>

	<style>
	.stat-widget {
		position: fixed;
		top: 24px;
		left: 24px;
		width: 320px;
		background: #fff;
		border-radius: 16px;
		box-shadow: 0 4px 24px rgba(0,0,0,0.08);
		padding: 18px 16px 12px 16px;
		z-index: 1000;
		font-family: ''Segoe UI'', Arial, sans-serif;
		}
		.stat-widget h3 {
		margin: 0 0 12px 0;
		font-size: 1.15rem;
		font-weight: 600;
		color: #1890ff;
		letter-spacing: 0.5px;
		}
		.stat-row {
		display: flex;
		gap: 8px;
		margin-bottom: 8px;
		}
		.stat-card {
		flex: 1;
		background: #f6faff;
		border-radius: 8px;
		padding: 8px 6px;
		display: flex;
		flex-direction: column;
		align-items: center;
		box-shadow: 0 1px 4px rgba(24,144,255,0.05);
		}
		.stat-icon {
		font-size: 1.3rem;
		margin-bottom: 2px;
		}
		.stat-label {
		font-size: 0.85rem;
		color: #555;
		}
		.stat-value {
		font-size: 1.1rem;
		font-weight: 600;
		color: #1890ff;
		}
</style>'
	FROM #Summary

	SELECT *, @html Col1
	FROM #tempData
	ORDER BY EmployeeID, AttDate
END
GO