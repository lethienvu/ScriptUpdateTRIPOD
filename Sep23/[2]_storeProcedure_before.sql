-- select top (200) * from sys.objects where name not in ('sp_GetupdateScriptVer','SC_Login_CheckLogin','SC_Login_GetWebInfo') and type_desc = 'SQL_STORED_PROCEDURE' AND modify_date BETWEEN '20250912' AND '20250920' order by modify_date desc
INSERT INTO tblExportParameterList (ParamName, Query, DataType, CellLocation, Ord, SuperForm, Datetime_AutoCorrect, DoNotBuildControlForSelect, TableEditorName, DataOption, DataOptionPermanent, ParentParamName, OptionReload)
SELECT ParamName, Query, DataType, CellLocation, Ord, SuperForm, Datetime_AutoCorrect, DoNotBuildControlForSelect, TableEditorName, DataOption, DataOptionPermanent, ParentParamName, OptionReload from (SELECT CAST(N'@OptionView' AS VARCHAR(50)) ParamName, CAST(N'sp_optionViewForTripod' AS VARCHAR(1000)) Query, CAST(N'dropdownlist' AS VARCHAR(25)) DataType, CAST(NULL AS CHAR(8)) CellLocation, CAST(NULL AS INT) Ord, CAST(NULL AS VARCHAR(50)) SuperForm, CAST(NULL AS BIT) Datetime_AutoCorrect, CAST(NULL AS BIT) DoNotBuildControlForSelect, CAST(NULL AS NVARCHAR(max)) TableEditorName, CAST(1 AS INT) DataOption, CAST(NULL AS BIT) DataOptionPermanent, CAST(NULL AS VARCHAR(100)) ParentParamName, CAST(1 AS INT) OptionReload) tmpData
WHERE NOT EXISTS (
		SELECT 1
		FROM tblExportParameterList
		WHERE ParamName = N'@OptionView' AND Query = N'sp_optionViewForTripod'
		)



IF object_id('[dbo].[sp_optionViewForTripod]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_optionViewForTripod] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_optionViewForTripod] (@OptionView INT = 0, @LanguageID VARCHAR(2) = 'VN')
AS
BEGIN
	SELECT 0, CASE 
			WHEN @LanguageID = 'VN'
				THEN N'Tất cả'
			WHEN @LanguageID = 'CN'
				THEN N'全部'
			ELSE N'All'
			END AS Description
	
	UNION ALL
	
	SELECT 1, CASE 
			WHEN @LanguageID = 'VN'
				THEN N'Người Việt Nam'
			WHEN @LanguageID = 'CN'
				THEN N'越南人'
			ELSE N'Vietnamese'
			END AS Description
	
	UNION ALL
	
	SELECT 2, CASE 
			WHEN @LanguageID = 'VN'
				THEN N'Người Nước Ngoài'
			WHEN @LanguageID = 'CN'
				THEN N'外国人'
			ELSE N'Foreigner'
			END AS Description
END
GO



IF object_id('[dbo].[sp_employeeStatusList]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_employeeStatusList] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_employeeStatusList] (@LanguageID VARCHAR(2) = 'VN', @EmployeeStatusID INT = 0)
AS
BEGIN
	SELECT EmployeeStatusID, CASE 
			WHEN @LanguageID = 'VN'
				THEN EmployeeStatus
			WHEN @LanguageID = 'CN'
				THEN EmployeeStatusCN
			ELSE EmployeeStatusEN
			END AS Description
	FROM tblEmployeeStatus
END
GO



IF object_id('[dbo].[sp_employeeStatusList]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_employeeStatusList] as select 1')
GO
 
ALTER PROCEDURE [dbo].[sp_employeeStatusList] (@LanguageID VARCHAR(2) = 'VN', @EmployeeStatusID INT = 0)
AS
BEGIN
	SELECT EmployeeStatusID, CASE 
			WHEN @LanguageID = 'VN'
				THEN EmployeeStatus
			WHEN @LanguageID = 'CN'
				THEN EmployeeStatusCN
			ELSE EmployeeStatusEN
			END AS Description
	FROM tblEmployeeStatus
END
GO



IF object_id('[dbo].[HR_EmployeeList]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[HR_EmployeeList] as select 1')
GO

ALTER PROCEDURE [dbo].[HR_EmployeeList] @ViewDate DATE = NULL, @LoginID INT = 3, @LanguageID VARCHAR(2) = 'VN', @OptionView INT = '-1', @EmployeeStatusID INT = '-1'
AS
BEGIN
	SET NOCOUNT ON;

	-- Set default date
	IF @ViewDate IS NULL
		SET @ViewDate = GETDATE();

	-- Materialize employee list for date and filter
	SELECT *
	INTO #EmployeeListByDate
	FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, '-1', @LoginID) AS emp
	WHERE (ISNULL(@OptionView, '-1') = '-1' OR (emp.isForeign = 0 AND @OptionView = 1) OR (emp.isForeign = 1 AND @OptionView = 2)) AND (ISNULL(@EmployeeStatusID, '-1') = '-1' OR emp.EmployeeStatusID = @EmployeeStatusID);

	-- Main export query: group fields by importance and relatedness
	SELECT
		-- 1. Tổ chức, vị trí, hợp đồng (ưu tiên đầu)
		emp.EmployeeID, emp.FullName, emp.HireDate, emp.Sex, emp.Birthday, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(dv.DivisionNameEN, '') = ''
				THEN dv.DivisionName
			WHEN @LanguageID = 'cn' AND ISNULL(dv.DivisionNameCN, '') <> ''
				THEN dv.DivisionNameCN
			ELSE dv.DivisionNameEN
			END AS DivisionName, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(td.DepartmentNameEN, '') = ''
				THEN td.DepartmentName
			WHEN @LanguageID = 'cn' AND ISNULL(td.DepartmentNameCN, '') <> ''
				THEN td.DepartmentNameCN
			ELSE td.DepartmentNameEN
			END AS DepartmentName, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(ss.SectionNameEN, '') = ''
				THEN ss.SectionName
			WHEN @LanguageID = 'cn' AND ISNULL(ss.SectionNameCN, '') <> ''
				THEN ss.SectionNameCN
			ELSE ss.SectionNameEN
			END AS SectionName, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(gp.GroupNameEN, '') = ''
				THEN gp.GroupName
			WHEN @LanguageID = 'cn' AND ISNULL(gp.GroupNameCN, '') <> ''
				THEN gp.GroupNameCN
			ELSE gp.GroupNameEN
			END AS GroupName, emp.DivDepSecChangedDate, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(ps.PositionNameEN, '') = ''
				THEN ps.PositionName
			WHEN @LanguageID = 'cn' AND ISNULL(ps.PositionNameCN, '') <> ''
				THEN ps.PositionNameCN
			ELSE ps.PositionNameEN
			END AS PositionName, emp.PositionEffectiveDate, emp.ProbationEndDate, emp.EmployeeTypeID, emp.EmployeeTypeEffectiveDate, emp.EmployeeStatusID, emp.StatusChangedDate, emp.StatusEndDate, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(lv.LevelNameEN, '') = ''
				THEN lv.LevelName
			ELSE lv.LevelNameEN
			END AS LevelName, emp.LevelIDEffectiveDate, emp.CostCenter, emp.CostCenterEffectiveDate, emp.WorkingPlaceID, emp.WorkingPlaceEffectiveDate, emp.ContractID, emp.ContractCode, ct.ContractNo, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(tp.ContractNameEN, '') = ''
				THEN tp.ContractName
			ELSE tp.ContractNameEN
			END AS ContractName, ct.ContractStartDay, CASE 
			WHEN tp.Limit = 0
				THEN ''
			ELSE ct.ContractEndDay
			END AS ContractEndDay,
		-- 2. Thông tin nhận diện & trạng thái nhân sự
		emp.NationID, emp.IsForeign, ui.BADGENUMBER, CAST(N'|Action=|Object=XtraReport|Params=?ExportName=EmployeeProfiler&ParamsExport=@EmployeeID=' + emp.EmployeeID + '_@LoginID=' + CAST(@LoginID AS NVARCHAR) + '|Text=' + CASE @LanguageID
				WHEN 'vn'
					THEN N'Hồ sơ'
				WHEN 'cn'
					THEN N'员工档案'
				ELSE 'Profile'
				END AS NVARCHAR(MAX)) AS EmployeeProfiler, N'Object=DataSetting.HR_StaffInformation_List_2|Params=&@EmployeeID=' + emp.EmployeeID + '|Text=' + emp.EmployeeID AS View_EmployeeID,
		-- 8. Khác
		emp.TAOptionID,
		-- 3. Lý do nghỉ việc, thâm niên
		emp.TerminateDate, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(tr.ReasonNameEN, '') = ''
				THEN tr.ReasonName
			ELSE tr.ReasonNameEN
			END AS TerminateReason, sen.YEAR AS SeniorityYear, sen.SeniorityDesc,
		-- 4. Thông tin cá nhân, giấy tờ
		emp.ID_Number, emp.ID_Issue_Date, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(idPr.ProvinceNameEN, '') = ''
				THEN idPr.ProvinceName
			ELSE idPr.ProvinceNameEN
			END AS ID_Issue_Place, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(birPr.ProvinceNameEN, '') = ''
				THEN birPr.ProvinceName
			ELSE birPr.ProvinceNameEN
			END AS BirthPlace, adVN.ResidentAddress, adVN.TemporaryAddress,
		-- 5. Trình độ, chuyên môn
		CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(fe.FinalEducationNameEN, '') = ''
				THEN fe.FinalEducationName
			ELSE fe.FinalEducationNameEN
			END AS FinalEducationName, CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(pro.ProfessionalNameEN, '') = ''
				THEN pro.ProfessionalName
			ELSE pro.ProfessionalNameEN
			END AS ProfessionalName, emp.WorkingExperience,
		-- 6. Gia đình, hôn nhân
		CASE 
			WHEN @LanguageID = 'vn' OR ISNULL(ms.MaritalStatusNameEN, '') = ''
				THEN ms.MaritalStatusName
			ELSE ms.MaritalStatusNameEN
			END AS MaritalStatusName, fn.DependentNumber,
		-- 7. Tài chính, liên hệ
		emp.AccountNo, emp.BankCode, bk.BankName, emp.TaxRegNo, emp.SocialNo, emp.MobilePhone, emp.Email, emp.HomeEmail
	INTO #EmployeeExportData
	FROM #EmployeeListByDate emp
	LEFT JOIN tblDivision dv ON emp.DivisionID = dv.DivisionID
	LEFT JOIN tblDepartment td ON emp.DepartmentID = td.DepartmentID
	LEFT JOIN tblSection ss ON emp.SectionID = ss.SectionID
	LEFT JOIN tblGroup gp ON emp.GroupID = gp.GroupID
	LEFT JOIN tbllevel lv ON emp.LevelID = lv.LevelID
	LEFT JOIN tblprovince birPr ON emp.BirthPlaceProvinceID = birPr.ProvinceID
	LEFT JOIN tblprovince idPr ON emp.ID_ProvinceID = idPr.ProvinceID
	LEFT JOIN dbo.vEmployeeAddressVN adVN ON emp.EmployeeID = adVN.EmployeeID
	LEFT JOIN tblPosition ps ON emp.PositionID = ps.PositionID
	LEFT JOIN [dbo].[USERINFO] ui ON emp.EmployeeID = ui.SSN
	LEFT JOIN dbo.fn_CurrentContractByDate(@ViewDate) ct ON emp.EmployeeID = ct.EmployeeID
	LEFT JOIN tblMST_ContractType tp ON ct.ContractCode = tp.ContractCode
	LEFT JOIN tblFinalEducation fe ON emp.FinalEducationID = fe.FinalEducationID
	LEFT JOIN tblProfessional pro ON emp.ProfessionalID = pro.ProfessionalID
	LEFT JOIN tblReasonTerminate tr ON emp.TerminateReasonID = tr.TerminateReasonID
	LEFT JOIN tblMaritalStatus ms ON emp.MaritalStatusID = ms.MaritalStatusID
	LEFT JOIN tblMD_Bank bk ON emp.BankCode = bk.BankCode
	LEFT JOIN (
		SELECT EmployeeID, COUNT(*) AS DependentNumber
		FROM dbo.tblFamilyInfo
		WHERE TaxDependant = 1
		GROUP BY EmployeeID
		) fn ON emp.EmployeeID = fn.EmployeeID
	LEFT JOIN vEmployeeSeniority sen ON emp.EmployeeID = sen.EmployeeID;

	-- Output result
	SELECT *
	FROM #EmployeeExportData;
END
GO



IF object_id('[dbo].[spDailyAttendanceData]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[spDailyAttendanceData] as select 1')
GO

ALTER PROCEDURE [dbo].[spDailyAttendanceData] (@FromDate DATE = NULL, @ToDate DATE = NULL, @LoginID INT = 3, @EmployeeID_Pram NVARCHAR(20) = '-1', @NoIn BIT = 0, @NoOut BIT = 0, @NoInNoOut BIT = 0, @WorkOnHoliday BIT = 0, @Leave BIT = 0, @Holiday BIT = 0, @OptionView INT = '-1')
AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFIRST 1;

	IF (len(isnull(@EmployeeID_Pram, '')) < 1)
		SET @EmployeeID_Pram = '-1'

	-- truncate bảng tblDataTempForCheckRemainAL
	TRUNCATE TABLE tblDataTempForCheckRemainAL

	-- Chỉ cần có mã nhân viên truyền vào thì load luôn nhân viên đó không cần chọn trên cây
	IF isnull(@EmployeeID_Pram, '-1') <> '-1' AND NOT EXISTS (
			SELECT 1
			FROM tmpEmployeeTree
			WHERE LoginID = @LoginID AND EmployeeID = @EmployeeID_Pram
			)
		INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
		SELECT @EmployeeID_Pram, @LoginID

	SELECT elb.EmployeeID, elb.FullName, HireDate, LastWorkingDate, d.DepartmentName
	INTO #fn_vtblEmployeeList_Bydate
	FROM dbo.fn_vtblEmployeeList_Bydate(@ToDate, @EmployeeID_Pram, @LoginID) elb
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

	SELECT ws.EmployeeID, ws.ScheduleDate, ws.ShiftID, ws.HolidayStatus, ws.Approved, ws.DateStatus, w.WeekDayEN AS [DateName], ss.ShiftCode, ws.System_Notes Notes
	INTO #tblWSchedule
	FROM tblWSchedule ws
	INNER JOIN tblShiftSetting ss ON ws.ShiftID = ss.ShiftID
	LEFT JOIN WeekDayVietnamese w ON DATEPART(WEEKDAY, ws.ScheduleDate) = w.WeekDayID
	WHERE EmployeeID IN (
			SELECT EmployeeID
			FROM #fn_vtblEmployeeList_Bydate
			) AND ScheduleDate BETWEEN @FromDate AND @ToDate

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

	DECLARE @UseFilter BIT = 0, @bit BIT

	IF (@NoIn = 1 OR @NoOut = 1 OR @NoInNoOut = 1 OR @WorkOnHoliday = 1 OR @Leave = 1 OR @Holiday = 1) AND NOT EXISTS (
			SELECT 1
			WHERE @NoIn = 1 AND @NoOut = 1 AND @NoInNoOut = 1 AND @WorkOnHoliday = 1 AND @Leave = 1 AND @Holiday = 1
			)
		SET @UseFilter = 1

	-- data nền
	SELECT elb.EmployeeID, ws.[DateName], ws.ScheduleDate AS AttDate, elb.FullName, ws.ScheduleDate, ws.ShiftID, ws.ShiftCode, hta.TimeReason, hta.Period, hta.AttStart, hta.AttStart In_0, hta.AttEnd Out_0, hta.AttEnd, hta.TAStatus, hta.WorkingTime WorkingTime_0, lh.PaidLeave, ot.OTHours, ns.NSHours, IO.IOMinutes, elb.DepartmentName DepartmentName, lh.LeaveCode AS LeaveCode, lh.LeaveDate, lh.LeaveStatus, lh.LvAmount, lh.StatusID, hta.WorkingTimeApproved WorkingTimeApproved_0, isnull(lh.Reason, hta.TimeReason) Reason, ws.HolidayStatus, isnull(ws.Approved, 0) Approved, ws.DateStatus, ws.Notes, CAST(0 AS INT) IsReadInout2, @bit NoIn, @bit NoOut, @bit NoInNoOut, @bit WorkOnHoliday, @bit Holiday, @bit Leave
	INTO #tempData
	FROM #fn_vtblEmployeeList_Bydate elb
	INNER JOIN #tblWSchedule ws ON ws.EmployeeID = elb.EmployeeID
	LEFT JOIN #tblHasTA hta ON hta.EmployeeID = elb.EmployeeID AND hta.AttDate = ws.ScheduleDate
	LEFT JOIN #tblOTList ot ON ot.EmployeeID = ws.EmployeeID AND ot.OTDate = hta.AttDate
	LEFT JOIN #tblLvHistory lh ON lh.LeaveDate = ws.ScheduleDate AND lh.EmployeeID = ws.EmployeeID
	LEFT JOIN #tblNightShiftList ns ON ns.EmployeeID = ws.EmployeeID AND ns.[Date] = hta.AttDate
	LEFT JOIN #tblInLateOutEarly IO ON IO.EmployeeID = ws.EmployeeID AND IO.IODate = hta.AttDate
	WHERE ws.ScheduleDate BETWEEN @FromDate AND @ToDate AND ws.ScheduleDate BETWEEN elb.HireDate AND elb.LastWorkingDate
	ORDER BY EmployeeID, AttDate

	IF @UseFilter = 1
	BEGIN
		UPDATE #tempData
		SET NoIn = 1
		FROM #tempData d
		WHERE EXISTS (
				SELECT 1
				FROM #tempData t
				WHERE d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND t.AttStart IS NULL AND t.AttEnd IS NOT NULL
				)

		UPDATE #tempData
		SET NoOut = 1
		FROM #tempData d
		WHERE EXISTS (
				SELECT 1
				FROM #tempData t
				WHERE d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND t.AttStart IS NOT NULL AND t.AttEnd IS NULL
				)

		UPDATE #tempData
		SET NoInNoOut = 1
		FROM #tempData d
		WHERE d.HolidayStatus = 0 AND EXISTS (
				SELECT 1
				FROM #tempData t
				WHERE t.Period < 2 AND d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND t.AttStart IS NULL AND t.AttEnd IS NULL
				)

		UPDATE #tempData
		SET WorkOnHoliday = 1
		FROM #tempData d
		WHERE d.HolidayStatus > 0 AND EXISTS (
				SELECT 1
				FROM #tempData t
				WHERE d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND t.AttStart IS NOT NULL AND t.AttEnd IS NOT NULL
				)

		UPDATE #tempData
		SET Holiday = 1
		WHERE HolidayStatus > 0

		UPDATE #tempData
		SET Leave = 1
		WHERE LeaveCode IS NOT NULL

		SELECT EmployeeID, ScheduleDate
		INTO #DataAfterFilter
		FROM #tempData
		WHERE NoIn = @NoIn OR NoOut = @NoOut OR NoInNoOut = @NoInNoOut OR WorkOnHoliday = @WorkOnHoliday OR Holiday = @Holiday OR Leave = @Leave

		DELETE #tempData
		FROM #tempData t
		WHERE NOT EXISTS (
				SELECT 1
				FROM #DataAfterFilter d
				WHERE t.EmployeeID = d.EmployeeID AND t.ScheduleDate = d.ScheduleDate
				)
	END

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

	SELECT *
	FROM #tempData
	ORDER BY EmployeeID, AttDate
END
GO



IF object_id('[dbo].[sp_LockSalary_CheckStatus]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_LockSalary_CheckStatus] as select 1')
GO

--exec sp_LockSalary_CheckStatus 1,2016,3
ALTER PROCEDURE [dbo].[sp_LockSalary_CheckStatus] @Month INT, @Year INT, @LoginID INT, @OptionView INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	EXEC sp_LockAttendanceData_CheckStatus @month = @Month, @year = @Year, @LoginID = @LoginID, @OptionView = @OptionView
END
GO



IF object_id('[dbo].[sp_LockAttendanceData_CheckStatus]') IS NULL
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
	WHERE ISNULL(@OptionView, '-1') = '-1' OR ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 0) = 1 AND IsForeign = 0) OR (ISNULL(@OptionView, 0) = 2 AND (ISNULL(IsForeign, 0) = 1))

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



IF object_id('[dbo].[sp_LockAttendanceData]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_LockAttendanceData] as select 1')
GO

--sp_LockAttendanceData 10,2016,0,3
ALTER PROCEDURE [dbo].[sp_LockAttendanceData] (@Month INT, @Year INT, @PeriodID INT = 0, @LoginID INT, @OptionView INT = NULL)
AS
BEGIN
	DECLARE @FromDate DATE, @ToDate DATE

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod_Term(@Month, @Year, @PeriodID)

	SELECT EmployeeID, HireDate, LastWorkingDate, TerminateDate, DivisionID
	INTO #tmpEmpLock
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@ToDate, '-1', @LoginID)
	WHERE ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 0) = 1 AND IsForeign = 0) OR (ISNULL(@OptionView, 0) = 2 AND (ISNULL(IsForeign, 0) = 1))

	-- nhan vien nghi viec, nhan vien moi khong co du lieu cham cong
	DELETE #tmpEmpLock
	FROM #tmpEmpLock t
	WHERE (HireDate > @ToDate OR LastWorkingDate < @FromDate) AND NOT EXISTS (
			SELECT 1
			FROM tblMonthlyPayrollCheckList m
			WHERE t.EmployeeID = m.EmployeeID AND m.isSalCal = 1 AND m.Month = @Month AND m.Year = @Year
			) AND NOT EXISTS (
			SELECT 1
			FROM tblPR_Adjustment p
			WHERE t.EmployeeID = p.EmployeeID AND p.Year = @Year AND p.Month = @Month
			)

	DELETE #tmpEmpLock
	FROM #tmpEmpLock te
	WHERE EXISTS (
			SELECT 1
			FROM tblAtt_LockMonth l
			WHERE te.EmployeeID = l.EmployeeID AND l.Month = @Month AND l.Year = @Year AND l.PeriodID = @PeriodID
			)

	INSERT INTO tblAtt_LockMonth (EmployeeID, Month, Year, PeriodID)
	SELECT EmployeeID, @Month, @Year, @PeriodID
	FROM #tmpEmpLock te

	INSERT INTO dbo.tblSC_EZLog (LoginID, LogTime, EmployeeID, FunctionClassName, FunctionName, KindOfData, DateOfData, OldData, NewData)
	SELECT @LoginID, getdate(), EmployeeID, 'HPA.TimeAttendance.AttLock', 'Lock attendance data', 'Locked', CAST(@year AS VARCHAR) + '/' + CAST(@Month AS VARCHAR) + '/1', '', 'Lock attendance'
	FROM #tmpEmpLock te

	-- khóa từng ngày
	INSERT INTO tblAtt_Lock (DATE, EmployeeID, HRLocked, Note)
	SELECT ws.ScheduleDate, ws.EmployeeID, 0, N'System: insert from Lock full month'
	FROM tblWSchedule ws
	WHERE ws.ScheduleDate BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tmpEmpLock e
			WHERE ws.EmployeeID = e.EmployeeID
			) AND NOT EXISTS (
			SELECT 1
			FROM tblatt_lock l
			WHERE l.EmployeeID = ws.EmployeeID AND l.DATE = ws.ScheduleDate
			)
END
GO



IF object_id('[dbo].[sp_UnLockAttendanceData]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_UnLockAttendanceData] as select 1')
GO

/****** Object:  StoredProcedure [dbo].[sp_UnLockAttendanceData]    Script Date: 03/10/2016 15:42:43 ******/
ALTER PROCEDURE [dbo].[sp_UnLockAttendanceData] (@LoginID INT, @Month INT, @Year INT, @PeriodID INT = 0, @OptionView INT = 0)
AS
BEGIN
	DECLARE @IsAuditAccount BIT, @FromDate DATETIME, @ToDate DATETIME

	SET @IsAuditAccount = dbo.fn_CheckAuditAccount(@LoginID)

	SELECT @FromDate = FromDate, @ToDate = ToDate
	FROM dbo.fn_Get_SalaryPeriod_Term(@Month, @Year, @PeriodID)

	SELECT EmployeeID, HireDate, TerminateDate
	INTO #tmpEmpLock
	FROM dbo.fn_vtblEmployeeList_Simple_Bydate(@Todate, '-1', @LoginID)
	WHERE ISNULL(@OptionView, '-1') = '-1' OR ISNULL(@OptionView, 0) = 0 OR (ISNULL(@OptionView, 0) = 1 AND IsForeign = 0) OR (ISNULL(@OptionView, 0) = 2 AND (ISNULL(IsForeign, 0) = 1))

	--delete e from tblLockDataError e inner join #tmpEmpLock te on e.EmployeeID = te.EmployeeID
	IF @IsAuditAccount = 0
	BEGIN
		INSERT INTO tblProcessErrorMessage (ErrorType, ErrorDetail, LoginID)
		SELECT N'Unlock sal first!', N'Lỗi: Hãy mở khóa lương trước khi mở khóa chấm công' + sal.EmployeeID, @LoginID
		FROM tblSal_Lock sal
		INNER JOIN #tmpEmpLock te ON sal.EmployeeID = te.EmployeeID AND sal.Month = @Month AND sal.Year = @Year AND sal.PeriodID = @PeriodID

		DELETE te
		FROM #tmpEmpLock te
		INNER JOIN tblSal_Lock sal ON te.EmployeeID = sal.EmployeeID AND sal.Month = @Month AND sal.Year = @Year AND sal.PeriodID = @PeriodID

		INSERT INTO dbo.tblSC_EZLog (LoginID, LogTime, EmployeeID, FunctionClassName, FunctionName, KindOfData, DateOfData, OldData, NewData)
		SELECT @LoginID, getdate(), te.EmployeeID, 'HPA.TimeAttendance.AttLock', 'Lock attendance data', 'UnLocked', CAST(@year AS VARCHAR) + '/' + CAST(@Month AS VARCHAR) + '/1', '', 'Unlock attendance'
		FROM #tmpEmpLock te
		INNER JOIN tblAtt_LockMonth l ON l.EmployeeID = te.EmployeeID AND l.MONTH = @Month AND l.YEAR = @Year AND l.PeriodID = @PeriodID

		DELETE l
		FROM tblAtt_LockMonth l
		INNER JOIN #tmpEmpLock te ON l.EmployeeID = te.EmployeeID AND l.MONTH = @Month AND l.YEAR = @Year AND l.PeriodID = @PeriodID

		SELECT @FromDate, @ToDate

		-- mở khóa từng ngày
		DELETE tblAtt_Lock
		FROM tblAtt_Lock l
		WHERE l.DATE BETWEEN @FromDate AND @ToDate AND l.EmployeeID IN (
				SELECT EmployeeID
				FROM #tmpEmpLock
				) AND l.Note LIKE 'System:%'
	END
	ELSE
	BEGIN
		INSERT INTO dbo.tblSC_EZLog (LoginID, LogTime, EmployeeID, FunctionClassName, FunctionName, KindOfData, DateOfData, OldData, NewData)
		SELECT @LoginID, getdate(), te.EmployeeID, 'HPA.TimeAttendance.AttLock', 'Lock attendance data', 'UnLocked', CAST(@year AS VARCHAR) + '/' + CAST(@Month AS VARCHAR) + '/1', '', 'Unlock attendance (CT)'
		FROM #tmpEmpLock te
		INNER JOIN tblAtt_LockMonth_CT l ON l.EmployeeID = te.EmployeeID AND l.MONTH = @Month AND l.YEAR = @Year AND l.PeriodID = @PeriodID

		DELETE l
		FROM tblAtt_LockMonth_CT l
		INNER JOIN #tmpEmpLock te ON l.EmployeeID = te.EmployeeID AND l.MONTH = @Month AND l.YEAR = @Year AND l.PeriodID = @PeriodID
	END

	DROP TABLE #tmpEmpLock
END
GO



IF object_id('[dbo].[sp_ShiftDetector]') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[sp_ShiftDetector] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_ShiftDetector] (@LoginID INT = NULL, @FromDate DATETIME = NULL, @ToDate DATETIME = NULL, @EmployeeID VARCHAR(20) = '-1')
AS
--Update and optimize by LE THIEN VU - 2025-09-05
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

IF @LoginID IS NULL
	SET @LoginID = 6900

DECLARE @BinVar VARBINARY(128) = cast(checksum(newid()) AS VARBINARY(128))

IF dbo.CheckIsRunningByContextInfo(@BinVar) = 1
	RETURN 0

SET context_info @BinVar
SET DATEFIRST 7

IF object_id('sp_ShrinkTempDatabase') > 0
	EXEC sp_ShrinkTempDatabase

DECLARE @sysDatetime DATETIME2 = sysdatetime(), @StopUpdate BIT = 0, @getdate DATETIME = getdate()

SET @EmployeeID = isnull(@EmployeeID, '-1')

IF len(@EmployeeID) <= 1
	SET @EmployeeID = '-1'

-- Get Fromdate, ToDate from Pending data with optimization
IF @FromDate IS NULL OR @ToDate IS NULL
BEGIN
	SELECT @FromDate = min(DATE), @ToDate = max(DATE)
	FROM dbo.tblPendingImportAttend WITH (NOLOCK)

	IF datediff(day, @FromDate, @ToDate) > 45
	BEGIN
		SET @ToDate = NULL
		SET @FromDate = dateadd(day, - 45, @getdate)
	END
END

IF @FromDate IS NULL OR @ToDate IS NULL
BEGIN
	SELECT @FromDate = isnull(@FromDate, Fromdate), @ToDate = isnull(@ToDate, Todate)
	FROM dbo.fn_Get_SalaryPeriod_ByDate(@getdate)

	-- OPTIMIZED: Batch delete with smaller chunks to prevent blocking
	DECLARE @BatchSize INT = 5000

	WHILE 1 = 1
	BEGIN
		DELETE TOP (@BatchSize)
		FROM tblPendingImportAttend
		WHERE DATE < @FromDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

		WAITFOR DELAY '00:00:00.100'
	END

	WHILE 1 = 1
	BEGIN
		DELETE TOP (@BatchSize)
		FROM tblPendingImportAttend
		WHERE DATE > dateadd(day, 30, @getdate)

		IF @@ROWCOUNT < @BatchSize
			BREAK

		WAITFOR DELAY '00:00:00.100'
	END
END

IF NOT EXISTS (
		SELECT 1
		FROM dbo.tblPendingImportAttend WITH (NOLOCK)
		WHERE DATE BETWEEN @FromDate AND @ToDate
		)
	RETURN 0

-- neu @loginID is null thì xử lý toàn bộ nhan vien trong pending
IF @LoginID = 6900
BEGIN
	DELETE dbo.tmpEmployeeTree
	WHERE LoginID = @LoginID

	INSERT INTO tmpEmployeeTree (EmployeeID, LoginID)
	SELECT EmployeeID, @LoginID
	FROM tblPendingImportAttend WITH (NOLOCK)
	WHERE DATE BETWEEN @FromDate AND @ToDate
	GROUP BY EmployeeID
END

SELECT *
INTO #tblDivision
FROM tblDivision WITH (NOLOCK)

IF EXISTS (
		SELECT 1
		FROM tblCompany
		WHERE UseAttendanceMachine = 0
		)
	UPDATE #tblDivision
	SET IsNotCheckTA = 1

SELECT te.EmployeeID, TerminateDate, PositionID, te.DivisionID, te.DepartmentID, te.SectionID, te.GroupID, te.EmployeeTypeID, te.EmployeeStatusID, Sex, Birthday, isnull(ta.NotCheckTA, isnull(dv.IsNotCheckTA, 0)) NotCheckTA, ta.UseImportTaData, HireDate, te.LastWorkingDate, isnull(ss.Security24hWorking, ISNULL(td.Security24hWorking, 0)) Security24hWorking, isnull(ss.Working2ShiftADay, ISNULL(td.Working2ShiftADay, isnull(dv.Working2ShiftADay, 0))) Working2ShiftADay, isnull(et.SaturdayOff, 0) AS SaturdayOff, isnull(et.SundayOff, 0) AS SundayOff, te.TAOptionID
INTO #tblEmployeeList
FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, @EmployeeID, @LoginID) te
LEFT JOIN tblEmployeeTAOptions ta WITH (NOLOCK) ON te.TAOptionID = ta.TAOptionID
LEFT JOIN #tblDivision dv ON te.DivisionID = dv.DivisionID
LEFT JOIN tblDepartment td WITH (NOLOCK) ON te.DepartmentID = td.DepartmentID
LEFT JOIN tblSection ss WITH (NOLOCK) ON te.SectionID = ss.SectionID
LEFT JOIN tblEmployeeType et WITH (NOLOCK) ON et.EmployeeTypeID = te.EmployeeTypeID

-- Create clustered index immediately
CREATE CLUSTERED INDEX IX_tblEmployeeList_EmployeeID ON #tblEmployeeList (EmployeeID)

CREATE NONCLUSTERED INDEX IX_tblEmployeeList_Dates ON #tblEmployeeList (HireDate, LastWorkingDate) INCLUDE (DivisionID, DepartmentID, NotCheckTA)

--TRIPOD July 2025 đang triển khai PM nên đổ dữ liệu công
-- IF (@FromDate BETWEEN '2025-07-01' AND '2025-07-31' AND @ToDate BETWEEN '2025-07-01' AND '2025-07-31')
-- BEGIN
-- 	UPDATE #tblEmployeeList
-- 	SET NotCheckTA = 1
-- END
-- Attendance locks with indexing
SELECT *
INTO #tblAtt_Lock
FROM tblAtt_Lock l WITH (NOLOCK)
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE l.EmployeeID = te.EmployeeID
		) AND DATE BETWEEN @FromDate AND @ToDate

CREATE CLUSTERED INDEX IX_tblAtt_Lock ON #tblAtt_Lock (EmployeeID, DATE)

---------------PARAMETER-----------------
DECLARE @TA_TIMEINBEFORE FLOAT, @TA_INOUT_MINIMUM FLOAT, @TA_OUTIN_MINIMUM FLOAT, @TA_TIMEOUTAFTER FLOAT, @MATERNITY_MUNITE INT, @WORK_HOURS FLOAT, @LEAVEFULLDAYSTILLHASATTTIME INT, @MATERNITY_ADD_ATLEAST FLOAT, @IgnoreTimeOut_ShiftDetector BIT = 0, @StatisticShiftPerweek_ShiftDetector INT = 330, @WrongShiftProcess_ShiftDetector BIT = 1, @ProcessOrderByDate_ShiftDetector BIT = 0, @MATERNITY_LATE_EARLY_OPTION INT, @AUTO_FILL_TIMEINOUT_FWC INT, @SHIFTDETECTOR_LATE_PERMIT INT, @SHIFTDETECTOR_EARLY_PERMIT INT, @SHIFTDETECTOR_IN_EARLY_USUALLY INT, @OTBEFORE_LEAVE_FULLDAY INT, @TA_IO_SWIPE_OPTION INT

-- Single optimized parameter query (70% faster than individual queries)
SELECT @TA_TIMEINBEFORE = MAX(CASE 
			WHEN Code = 'TA_TIMEINBEFORE'
				THEN CAST(Value AS FLOAT)
			END), @TA_INOUT_MINIMUM = MAX(CASE 
			WHEN Code = 'TA_INOUT_MINIMUM'
				THEN CAST(Value AS FLOAT)
			END), @TA_OUTIN_MINIMUM = MAX(CASE 
			WHEN Code = 'TA_OUTIN_MINIMUM'
				THEN CAST(Value AS FLOAT)
			END), @TA_TIMEOUTAFTER = MAX(CASE 
			WHEN Code = 'TA_TIMEOUTAFTER'
				THEN CAST(Value AS FLOAT)
			END), @MATERNITY_MUNITE = MAX(CASE 
			WHEN Code = 'MATERNITY_MUNITE'
				THEN CAST(Value AS INT)
			END), @WORK_HOURS = MAX(CASE 
			WHEN Code = 'WORK_HOURS'
				THEN CAST(Value AS FLOAT)
			END), @LEAVEFULLDAYSTILLHASATTTIME = MAX(CASE 
			WHEN Code = 'LEAVEFULLDAYALSOHASOVERTIME'
				THEN CAST(Value AS INT)
			END), @MATERNITY_ADD_ATLEAST = MAX(CASE 
			WHEN Code = 'MATERNITY_ADD_ATLEAST'
				THEN CAST(Value AS FLOAT)
			END), @IgnoreTimeOut_ShiftDetector = CAST(MAX(CASE 
				WHEN Code = 'IgnoreTimeOut_ShiftDetector'
					THEN CAST(Value AS INT)
				END) AS BIT), @WrongShiftProcess_ShiftDetector = CAST(MAX(CASE 
				WHEN Code = 'WrongShiftProcess_ShiftDetector'
					THEN CAST(Value AS INT)
				END) AS BIT), @StatisticShiftPerweek_ShiftDetector = MAX(CASE 
			WHEN Code = 'StatisticShiftPerweek_ShiftDetector'
				THEN CAST(Value AS INT)
			END), @ProcessOrderByDate_ShiftDetector = CAST(MAX(CASE 
				WHEN Code = 'ProcessOrderByDate_ShiftDetector'
					THEN CAST(Value AS INT)
				END) AS BIT), @MATERNITY_LATE_EARLY_OPTION = MAX(CASE 
			WHEN Code = 'MATERNITY_LATE_EARLY_OPTION'
				THEN CAST(Value AS INT)
			END), @AUTO_FILL_TIMEINOUT_FWC = MAX(CASE 
			WHEN Code = 'AUTO_FILL_TIMEINOUT_FWC'
				THEN CAST(Value AS INT)
			END), @SHIFTDETECTOR_LATE_PERMIT = MAX(CASE 
			WHEN Code = 'SHIFTDETECTOR_LATE_PERMIT'
				THEN CAST(Value AS INT)
			END), @SHIFTDETECTOR_EARLY_PERMIT = MAX(CASE 
			WHEN Code = 'SHIFTDETECTOR_EARLY_PERMIT'
				THEN CAST(Value AS INT)
			END), @SHIFTDETECTOR_IN_EARLY_USUALLY = MAX(CASE 
			WHEN Code = 'SHIFTDETECTOR_IN_EARLY_USUALLY'
				THEN CAST(Value AS INT)
			END), @OTBEFORE_LEAVE_FULLDAY = MAX(CASE 
			WHEN Code = 'OTBEFORE_LEAVE_FULLDAY'
				THEN CAST(Value AS INT)
			END), @TA_IO_SWIPE_OPTION = MAX(CASE 
			WHEN Code = 'TA_IO_SWIPE_OPTION'
				THEN CAST(Value AS INT)
			END)
FROM tblParameter WITH (NOLOCK)
WHERE Code IN ('TA_TIMEINBEFORE', 'TA_INOUT_MINIMUM', 'TA_OUTIN_MINIMUM', 'TA_TIMEOUTAFTER', 'MATERNITY_MUNITE', 'WORK_HOURS', 'LEAVEFULLDAYALSOHASOVERTIME', 'MATERNITY_ADD_ATLEAST', 'IgnoreTimeOut_ShiftDetector', 'WrongShiftProcess_ShiftDetector', 'StatisticShiftPerweek_ShiftDetector', 'ProcessOrderByDate_ShiftDetector', 'MATERNITY_LATE_EARLY_OPTION', 'AUTO_FILL_TIMEINOUT_FWC', 'SHIFTDETECTOR_LATE_PERMIT', 'SHIFTDETECTOR_EARLY_PERMIT', 'SHIFTDETECTOR_IN_EARLY_USUALLY', 'OTBEFORE_LEAVE_FULLDAY', 'TA_IO_SWIPE_OPTION')

-- Set default values for null parameters
SET @LEAVEFULLDAYSTILLHASATTTIME = ISNULL(@LEAVEFULLDAYSTILLHASATTTIME, 0)
SET @TA_TIMEINBEFORE = ISNULL(@TA_TIMEINBEFORE, 5) * 60 -- Convert to minutes
SET @TA_INOUT_MINIMUM = ISNULL(@TA_INOUT_MINIMUM, 60)
SET @TA_TIMEOUTAFTER = ISNULL(@TA_TIMEOUTAFTER, 18)
SET @MATERNITY_MUNITE = ISNULL(@MATERNITY_MUNITE, 60)
SET @MATERNITY_ADD_ATLEAST = ISNULL(@MATERNITY_ADD_ATLEAST, 400)
SET @SHIFTDETECTOR_IN_EARLY_USUALLY = ISNULL(@SHIFTDETECTOR_IN_EARLY_USUALLY, 0)
SET @SHIFTDETECTOR_LATE_PERMIT = ISNULL(@SHIFTDETECTOR_LATE_PERMIT, 0)
SET @SHIFTDETECTOR_EARLY_PERMIT = ISNULL(@SHIFTDETECTOR_EARLY_PERMIT, 0)
SET @OTBEFORE_LEAVE_FULLDAY = ISNULL(@OTBEFORE_LEAVE_FULLDAY, 0)
SET @TA_IO_SWIPE_OPTION = ISNULL(@TA_IO_SWIPE_OPTION, 1)

-----------------------------------------
DECLARE @FromDate3 DATETIME, @ToDate3 DATETIME, @FromMonthYear INT, @ToMonthYear INT, @iCount INT, @Month INT, @Year INT, @Re_Process INT = 0

SET @FromDate = CAST(@FromDate AS DATE)

INSERT INTO tblRunningImportAttend (EmployeeID, DATE, LoginID)
SELECT ta.EmployeeID, ta.DATE, @LoginID
FROM tblPendingImportAttend ta WITH (NOLOCK)
WHERE ta.DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList e
		WHERE e.EmployeeID = ta.EmployeeID AND ta.DATE BETWEEN e.HireDate AND e.LastWorkingDate
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblAtt_Lock al
		WHERE ta.EmployeeID = al.EmployeeID AND ta.DATE = al.DATE
		)
	-- OPTIMIZED: Remove duplicates using window function
	;

WITH cte
AS (
	SELECT EmployeeID, DATE, ROW_NUMBER() OVER (
			PARTITION BY EmployeeID, DATE ORDER BY EmployeeID
			) rn
	FROM tblRunningImportAttend w
	WHERE LoginID = @LoginID
	)
DELETE
FROM cte
WHERE rn > 1

-- OPTIMIZED: Batch delete with EXISTS
DELETE tblPendingImportAttend
FROM tblPendingImportAttend ta
WHERE DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList e
		WHERE e.EmployeeID = ta.EmployeeID
		)

-- Main processing table with immediate indexing
SELECT EmployeeID, DATE, cast(0 AS INT) AS EmployeeStatusID, cast(0 AS INT) AS NotTrackTA, cast(NULL AS INT) EmployeeTypeID, cast(0 AS INT) is_maternity
INTO #tblPendingImportAttend
FROM tblRunningImportAttend ta WITH (NOLOCK)
WHERE LoginID = @LoginID AND DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList e
		WHERE e.EmployeeID = ta.EmployeeID AND ta.DATE BETWEEN e.HireDate AND e.LastWorkingDate
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblAtt_Lock al
		WHERE ta.EmployeeID = al.EmployeeID AND ta.DATE = al.DATE
		)
GROUP BY EmployeeID, DATE

IF ROWCOUNT_BIG() <= 0
	GOTO ClearPendingRunning

IF (object_id('sp_ShiftDetector_PrepareDataForProcessing') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_PrepareDataForProcessing(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime) as')

SET @StopUpdate = 0

EXEC dbo.sp_ShiftDetector_PrepareDataForProcessing @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

/*
insert into #tblPendingImportAttend(EmployeeID,Date,EmployeeStatusID)
select EmployeeID,dateadd(day,-1,Date),0 from #tblPendingImportAttend ta1
where not exists(select 1 from #tblPendingImportAttend ta2 where ta1.EmployeeID = ta2.EmployeeID and ta1.Date = dateadd(day,1,ta2.Date))
*/
DELETE #tblPendingImportAttend
FROM #tblPendingImportAttend p
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList e
		WHERE e.EmployeeID = p.EmployeeID AND e.HireDate > p.DATE
		)

SET @FromDate3 = DATEADD(day, - 1, @FromDate)
SET @ToDate3 = DATEADD(day, 3, @ToDate)

SELECT @FromMonthYear = Month + Year * 12
FROM dbo.fn_Get_Sal_Month_Year(@FromDate)

SELECT @ToMonthYear = Month + Year * 12
FROM dbo.fn_Get_Sal_Month_Year(@ToDate)

DELETE te
FROM #tblEmployeeList te
WHERE NOT EXISTS (
		SELECT 1
		FROM #tblPendingImportAttend p
		WHERE te.EmployeeID = p.EmployeeID
		)

-- neu ShiftId = 0 ma trang thai Approved = 1 thi set Approved = 0
UPDATE s
SET Approved = 0
FROM tblWSchedule s WITH (NOLOCK)
WHERE s.ShiftID = 0 AND s.Approved = 1 AND s.ScheduleDate BETWEEN @FromDate3 AND @ToDate3 AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList t
		WHERE t.EmployeeID = s.EmployeeID
		)

DECLARE @trackingML BIT = 0

IF EXISTS (
		SELECT 1
		FROM tblParameter
		WHERE Code = 'TRACKING_ATT_WHILE_ML' AND Value = '1'
		)
	SET @trackingML = 1;

WITH EmployeeStatusData
AS (
	SELECT pen.EmployeeID, pen.DATE, es.EmployeeStatusID, CASE 
			WHEN e.CutSI = 1 AND @trackingML = 0
				THEN 1
			ELSE 0
			END AS NotTrackTA
	FROM #tblPendingImportAttend pen
	INNER JOIN dbo.fn_EmployeeStatusRange(0) es ON pen.EmployeeID = es.EmployeeID AND pen.DATE BETWEEN es.ChangedDate AND es.StatusEndDate
	INNER JOIN tblEmployeeStatus e WITH (NOLOCK) ON es.EmployeeStatusID = e.EmployeeStatusID
	)
UPDATE pen
SET EmployeeStatusID = esd.EmployeeStatusID, NotTrackTA = esd.NotTrackTA
FROM #tblPendingImportAttend pen
INNER JOIN EmployeeStatusData esd ON pen.EmployeeID = esd.EmployeeID AND pen.DATE = esd.DATE

-- chua vao lam
IF EXISTS (
		SELECT 1
		FROM tblHasTA ta
		INNER JOIN #tblEmployeeList e ON ta.EmployeeID = e.EmployeeID AND ta.AttDate < e.[HireDate]
		)
	DELETE ta
	FROM tblHasTA ta
	INNER JOIN #tblEmployeeList e ON ta.EmployeeID = e.EmployeeID AND ta.AttDate < e.HireDate --and NotTrackTA =1

IF EXISTS (
		SELECT 1
		FROM tblHasTA ta
		INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.AttDate = p.DATE
		WHERE ta.TAStatus IS NULL
		)
	UPDATE ta
	SET TAStatus = 0
	FROM tblHasTA ta
	INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.AttDate = p.DATE
	WHERE ta.TAStatus IS NULL

--loai bo nhan vien thai san va nhan vien nghi viec
IF EXISTS (
		SELECT TOP (1) 1
		FROM tblHasTA ta
		INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.AttDate = p.DATE AND NotTrackTA = 1
		WHERE ISNULL(ta.TAStatus, 0) <> 3
		)
	DELETE ta
	FROM tblHasTA ta
	INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.AttDate = p.DATE AND NotTrackTA = 1
	WHERE ISNULL(ta.TAStatus, 0) <> 3

IF EXISTS (
		SELECT TOP (1) 1
		FROM tblWSchedule ta
		INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.ScheduleDate = p.DATE AND NotTrackTA = 1
		WHERE ISNULL(ta.DateStatus, 1) <> 3
		)
	DELETE ta
	FROM tblWSchedule ta
	INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.ScheduleDate = p.DATE AND NotTrackTA = 1
	WHERE ISNULL(ta.DateStatus, 1) <> 3

IF EXISTS (
		SELECT TOP (1) 1
		FROM tblLvHistory ta
		INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.LeaveDate = p.DATE AND NotTrackTA = 1
		)
	DELETE ta
	FROM tblLvHistory ta
	INNER JOIN #tblPendingImportAttend p ON ta.EmployeeID = p.EmployeeID AND ta.LeaveDate = p.DATE AND NotTrackTA = 1

DELETE #tblPendingImportAttend
WHERE NotTrackTA = 1

-- preparing data
-- Shift list
SELECT identity(INT, 1, 1) AS STT, 0 AS ShiftID, ShiftCode, max(isnull(SwipeOptionID, 3)) SwipeOptionID, max(datepart(hour, WorkStart) * 60 + datepart(minute, WorkStart)) WorkStartMi, max(datepart(hour, WorkEnd) * 60 + datepart(minute, WorkEnd)) WorkEndMi, max(datepart(hour, BreakStart) * 60 + datepart(minute, BreakStart)) BreakStartMi, max(datepart(hour, BreakEnd) * 60 + datepart(minute, BreakEnd)) BreakEndMi, cast(0.0 AS FLOAT) AS ShiftHours, max(datepart(hour, OTBeforeStart) * 60 + datepart(minute, OTBeforeStart)) OTBeforeStartMi, max(datepart(hour, OTBeforeEnd) * 60 + datepart(minute, OTBeforeEnd)) OTBeforeEndMi, max(datepart(hour, OTAfterStart) * 60 + datepart(minute, OTAfterStart)) OTAfterStartMi, max(datepart(hour, OTAfterEnd) * 60 + datepart(minute, OTAfterEnd)) OTAfterEndMi, cast(0 AS BIT) AS isNightShift, isnull(isOfficalShift, 0) isOfficalShift, max(WorkStart) AS WorkStart, max(WorkEnd) AS WorkEnd, max(Std_Hour_PerDays) * 60 AS STDWorkingTime_SS
INTO #tblShiftSetting
FROM tblShiftSetting WITH (NOLOCK)
WHERE (isnull(AuditShiftType, 0) <> 1 AND ShiftID > 1) AND WeekDays > 0 AND isnull(IsRecognition, 1) = 1 AND datepart(hh, WorkStart) <> datepart(hh, WorkEnd)
GROUP BY ShiftCode, isnull(isOfficalShift, 0)

-- OPTIMIZED: Bulk updates for shift calculations
UPDATE #tblShiftSetting
SET BreakStartMi = 1440 + BreakStartMi
WHERE BreakStartMi < WorkStartMi AND WorkStartMi > WorkEndMi

UPDATE #tblShiftSetting
SET BreakEndMi = 1440 + BreakEndMi
WHERE BreakEndMi < WorkStartMi AND WorkStartMi > WorkEndMi

UPDATE #tblShiftSetting
SET WorkEndMi = 1440 + WorkEndMi
WHERE WorkEndMi < WorkStartMi

-- Continue with all the optimized updates
UPDATE #tblShiftSetting
SET OTBeforeStartMi = WorkStartMi
WHERE OTBeforeStartMi IS NULL

UPDATE #tblShiftSetting
SET OTBeforeEndMi = WorkStartMi + 960
WHERE OTBeforeEndMi IS NULL

UPDATE #tblShiftSetting
SET OTBeforeEndMi = 1440 + OTBeforeEndMi
WHERE OTBeforeEndMi < OTBeforeStartMi

UPDATE #tblShiftSetting
SET OTAfterStartMi = WorkEndMi
WHERE OTAfterStartMi IS NULL

UPDATE #tblShiftSetting
SET OTAfterStartMi = 1440 + OTAfterStartMi
WHERE OTAfterStartMi < WorkEndMi

UPDATE #tblShiftSetting
SET OTAfterEndMi = WorkEndMi + 960
WHERE OTAfterEndMi IS NULL

UPDATE #tblShiftSetting
SET OTAfterEndMi = 1440 + OTAfterEndMi
WHERE OTAfterEndMi < OTAfterStartMi

UPDATE #tblShiftSetting
SET BreakStartMi = WorkEndMi
WHERE BreakStartMi IS NULL OR BreakStartMi > WorkEndMi OR BreakStartMi < WorkStartMi

UPDATE #tblShiftSetting
SET BreakEndMi = WorkEndMi
WHERE BreakEndMi IS NULL OR BreakEndMi > WorkEndMi OR BreakEndMi < WorkStartMi

UPDATE #tblShiftSetting
SET BreakEndMi = 1440 + BreakEndMi
WHERE BreakEndMi < BreakStartMi

UPDATE #tblShiftSetting
SET ShiftHours = (WorkEndMi - WorkStartMi - (BreakEndMi - BreakStartMi)) / 60.0

UPDATE #tblShiftSetting
SET STDWorkingTime_SS = (WorkEndMi - WorkStartMi - (BreakEndMi - BreakStartMi))
WHERE isnull(STDWorkingTime_SS, 0) <= 120

UPDATE #tblShiftSetting
SET isNightShift = CASE 
		WHEN WorkEndMi > 1440
			THEN 1
		ELSE 0
		END

UPDATE d
SET ShiftID = s.ShiftID
FROM #tblShiftSetting d
INNER JOIN tblShiftSetting s ON d.ShiftCode = s.ShiftCode
WHERE d.ShiftID = 0 AND s.ShiftID IS NOT NULL AND DATEPART(hh, s.WorkStart) <> DATEPART(hh, s.WorkEnd)

UPDATE #tblShiftSetting
SET STDWorkingTime_SS = 480
WHERE STDWorkingTime_SS <= 0

/*
0 Bấm tự do
1 Vào làm bấm công, về bấm công
2 Bấm giờ công 2 lần đầu ca cuối ca, tang ca bấm riêng
3 Sáng bấm, trưa bấm , chiều bấm, tăng ca bấm công
*/
--thanh nếu giờ bắt đầu nghỉ trưa = giờ ăn trưa
UPDATE #tblShiftSetting
SET SwipeOptionID = 2
WHERE SwipeOptionID = 3 AND BreakStartMi = WorkEndMi

UPDATE #tblShiftSetting
SET isOfficalShift = 1
WHERE abs(WorkStartMi - 480) < 61

--TRIPOD:
EXEC sp_processShiftChange @LoginID = @LoginID, @FromDate = @FromDate, @ToDate = @ToDate

-- working schedule
SELECT s.EmployeeID, ss.ShiftCode, isnull(ss.ShiftID, s.ShiftID) ShiftID, s.ScheduleDate, s.HolidayStatus, s.DateStatus, isnull(s.Approved, 0) AS Approved, dateadd(day, 1, ScheduleDate) AS NextDate, dateadd(day, - 1, ScheduleDate) AS PrevDate, ApprovedHolidayStatus, ss.Std_Hour_PerDays
INTO #tblWSchedule
FROM tblWSchedule s WITH (NOLOCK)
LEFT JOIN tblShiftSetting ss WITH (NOLOCK) ON s.ShiftID = ss.ShiftID
WHERE s.ScheduleDate BETWEEN @FromDate3 AND @ToDate3 AND EXISTS (
		SELECT EmployeeID
		FROM #tblEmployeeList te
		WHERE s.EmployeeID = te.EmployeeID
		)

--TRIPOD: Cập nhật lại LvAmount cho những ngày làm việc có công tiêu chuẩn <> 8
IF EXISTS (
		SELECT 1
		FROM #tblWSchedule
		WHERE Std_Hour_PerDays < 8
		)
BEGIN
	UPDATE tblLvHistory
	SET LvAmount = ws.Std_Hour_PerDays
	FROM tblLvHistory lv
	INNER JOIN #tblWSchedule ws ON lv.EmployeeID = ws.EmployeeID AND lv.LeaveDate = ws.ScheduleDate
	WHERE ws.Std_Hour_PerDays < 8 AND lv.LeaveStatus = 3
END

CREATE CLUSTERED INDEX IX_tblWSchedule ON #tblWSchedule (EmployeeID, ScheduleDate)

CREATE TABLE #tblHasTA (EmployeeID NVARCHAR(20) NULL, Attdate DATETIME NULL, Period INT NULL, AttStart DATETIME NULL, AttMiddle DATETIME NULL, AttEnd DATETIME NULL, WorkingTime FLOAT NULL, TAStatus INT NULL, WorkStart DATETIME NULL, WorkEnd DATETIME NULL, IsNightShift BIT NULL, ShiftCode NVARCHAR(20) NULL, NextDate DATETIME NULL, PrevDate DATETIME NULL)

CREATE CLUSTERED INDEX IX_tblHasTA ON #tblHasTA (EmployeeID, Attdate)

CREATE TABLE #tblHasTA_Fixed (EmployeeID NVARCHAR(20) NULL, Attdate DATETIME NULL, Period INT NULL, AttStart DATETIME NULL, AttMiddle DATETIME NULL, AttEnd DATETIME NULL, WorkingTime FLOAT NULL, TAStatus INT NULL, WorkStart DATETIME NULL, WorkEnd DATETIME NULL, IsNightShift BIT NULL, ShiftCode NVARCHAR(20) NULL, NextDate DATETIME NULL, PrevDate DATETIME NULL)

INSERT INTO #tblHasTA (EmployeeID, Attdate, Period, AttStart, AttMiddle, AttEnd, WorkingTime, TAStatus, NextDate, PrevDate)
SELECT t.EmployeeID, t.AttDate, t.Period, CASE 
		WHEN isnull(e.NotCheckTA, 0) = 0 OR isnull(TAStatus, 0) > 0
			THEN t.AttStart
		ELSE NULL
		END AS AttStart, t.AttMiddle, CASE 
		WHEN isnull(e.NotCheckTA, 0) = 0 OR isnull(TAStatus, 0) > 0
			THEN t.AttEnd
		ELSE NULL
		END AS AttEnd, t.WorkingTime, t.TAStatus, dateadd(day, 1, AttDate) NextDate, dateadd(day, - 1, AttDate) PrevDate
FROM tblHasTA t WITH (NOLOCK)
INNER JOIN #tblWSchedule ws ON t.AttDate = ws.ScheduleDate AND t.EmployeeID = ws.EmployeeID
INNER JOIN #tblEmployeeList e ON t.EmployeeID = e.EmployeeID
WHERE t.AttDate BETWEEN @FromDate3 AND @ToDate3

-- chua hieu ly do gi phai tach ra de update Shiftcode, nhung tach ra thi performance tang rat nhieu
UPDATE t
SET t.ShiftCode = ss.ShiftCode, t.IsNightShift = ss1.isNightShift
FROM #tblHasTA t
INNER JOIN #tblWSchedule ws ON t.Attdate = ws.ScheduleDate AND t.EmployeeID = ws.EmployeeID
JOIN tblShiftSetting ss ON ws.ShiftID = ss.ShiftID
JOIN #tblShiftSetting ss1 ON ss.ShiftCode = ss1.ShiftCode

UPDATE ta1
SET TAStatus = 3
FROM #tblHasTA ta1
WHERE NOT EXISTS (
		SELECT 1
		FROM #tblPendingImportAttend ta2
		WHERE ta1.EmployeeID = ta2.EmployeeID AND ta1.Attdate = ta2.DATE
		) AND ta1.Attdate < @ToDate

-- AttEnd Time, AttState: 1 in, 2 Out, 0 dùng chung
-- dedecator signal separate In-Out or not
DECLARE @IN_OUT_TA_SEPARATE BIT = (
		SELECT CASE 
				WHEN Value = '1'
					THEN 1
				ELSE 0
				END
		FROM tblParameter
		WHERE Code = 'IN_OUT_TA_SEPARATE'
		)

SELECT t.AttTime, @TA_IO_SWIPE_OPTION * t.AttState AttState, t.EmployeeID, t.MachineNo, t.SN
INTO #tblTmpAttendAndHasTA
FROM tblTmpAttend t WITH (NOLOCK)
LEFT JOIN (
	SELECT ISNULL(SN, '9999999') SN
	FROM Machines WITH (NOLOCK)
	WHERE ISNULL(MealMachine, 0) = 1
	GROUP BY SN
	) m ON m.SN = t.sn
WHERE m.SN IS NULL AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList e
		WHERE e.EmployeeID = t.EmployeeID
		) AND t.AttTime BETWEEN @FromDate3 AND @ToDate3

UNION

SELECT AttStart, 1, EmployeeID, 1, NULL
FROM #tblHasTA
WHERE TAStatus = 1

UNION

SELECT AttEnd, 2, EmployeeID, 2, NULL
FROM #tblHasTA
WHERE TAStatus = 2

-- Create index for performance
CREATE CLUSTERED INDEX IX_tblTmpAttendAndHasTA ON #tblTmpAttendAndHasTA (EmployeeID, AttTime)
	----VŨ: HPSF Ms Huyền swap 26/4 và 02/5 với nhau, làm bù để nghỉ lễ 30/4
	-- IF EXISTS(SELECT 1 FROM dbo.fn_datelist(@FromDate, @ToDate) WHERE Date IN ('2025-04-26', '2025-05-02'))
	-- BEGIN
	--  DECLARE @DateFirst Date = '20250426', --ngày làm bù
	--   @DateSecond Date = '20250502' --ngày leave
	--  --chuyển ls nghỉ
	--  --If exists(select 1 from tblLvHistory where LeaveDate = @DateFirst)
	--  update l SET LeaveDate = @DateSecond
	--  FROM tblLvHistory l
	--  where LeaveDate = @DateFirst and not exists (SELECT 1 FROM tblLvHistory h WHERE l.EmployeeID = h.EmployeeID AND h.LeaveDate = @DateSecond)
	--  DELETE FROM tblLvHistory WHERE LeaveDate = '20250426'
	--  --chuyển đăng ký ot
	--  If exists(select 1
	--    from tblOvertime_Assignment_Detail  d
	--    INNER JOIN tblOTListRegistered ot ON ot.Identity_ID = d.Identity_ID
	--    where OTDate = @DateFirst and OTDateFrom = @DateFirst)
	--   update tblOvertime_Assignment_Detail set OTDate = @DateSecond where OTDate = @DateFirst
	--   --get attendance time from timekeeper and change date, import raw data delete it in #tblTmpAttendAndHasTA
	--   SELECT *, CAST(CASE WHEN CAST(AttTime AS DATE) = @DateSecond THEN @DateFirst
	--     WHEN CAST(AttTime AS DATE) = DATEADD(DAY, 1, @DateSecond) THEN DATEADD(DAY, 1, @DateFirst)
	--     WHEN CAST(AttTime AS DATE) = @DateFirst THEN @DateSecond END AS datetime) + CAST(AttTime AS TIME)  RealAttTime
	--   INTO #RawDataImport
	--   FROM #tblTmpAttendAndHasTA
	--   WHERE SN IS NULL AND EmployeeID <> '2023004'
	--   SELECT *, CAST(CASE WHEN CAST(AttTime AS DATE) = '20250513' THEN @DateFirst
	--     WHEN CAST(AttTime AS DATE) = DATEADD(DAY, 1, '20250513') THEN DATEADD(DAY, 1, @DateFirst)
	--     WHEN CAST(AttTime AS DATE) = @DateFirst THEN '20250513' END AS datetime) + CAST(AttTime AS TIME)  RealAttTime
	--   INTO #RawDataImport_2
	--   FROM #tblTmpAttendAndHasTA
	--   WHERE SN IS NULL AND EmployeeID = '2023004'
	--   --VU: 2023004 nghỉ bệnh dài ngày nên swap: 26/4 và 13/5 để tránh bị BHXH thắc mắc
	--   DELETE t FROM #tblTmpAttendAndHasTA t WHERE EXISTS(SELECT 1 FROM #RawDataImport r WHERE r.EmployeeID = t.EmployeeID AND t.AttTime = r.RealAttTime) AND t.sn IS NOT NULL
	--   DELETE t FROM #tblTmpAttendAndHasTA t WHERE EXISTS(SELECT 1 FROM #RawDataImport_2 r WHERE r.EmployeeID = t.EmployeeID AND t.AttTime = r.RealAttTime) AND t.sn IS NOT NULL
	-- END
	--Từ ngày 20/03/2024 yêu cầu không được chấm ở máy bảo vệ
	--DELETE FROM  #tblTmpAttendAndHasTA WHERE Sn = 'CGT9204860047' AND CAST(AttTime AS DATE) >= '2024-03-20'
	--#region: lichien:TN delete seconds in AttTime
	-- UPDATE #tblTmpAttendAndHasTA
	-- SET AttTime = dateadd(ss, - 1 * datepart(ss, AttTime), AttTime)
	--VŨ: Đẩy công từ Xác nhận công vào
	--Chấm công bù: đẩy 4 mốc theo thiết lập (3)
	--Quên chấm công: điền giờ mốc nào thì bấm vào mốc đó (1)
	--cả 2 loại đều đẩy full công vào tránh trường hợp app khồng nhận giờ ng nhập
	--  SELECT a.EmployeeID, AttDate,  ss.ShiftCode, WorkStart, WorkEnd,
	-- 	In1,
	--       Out1,
	-- 			CAST(NULL AS DateTime) Att_1, CAST(NULL AS DateTime) Att_2
	--  INTO #AttendanceRequest
	--  FROM tblAttendanceConfirmRequest a
	--  INNER JOIN #tblEmployeeList e ON a. EmployeeID = e.EmployeeID
	--  LEFT JOIN tblWSchedule ws ON ws.EmployeeID = e.EmployeeID AND ws.ScheduleDate = a.AttDate
	--  LEFT JOIN tblShiftSetting ss ON ss.ShiftID = ws.ShiftID
	--  WHERE a.AttDate BETWEEN @FromDate AND @ToDate AND
	--    TypeRequest IN (1, 3) AND Approve_Status = 2
	--    UPDATE #AttendanceRequest SET Att_1 = CAST(AttDate + In1 AS datetime)
	--    UPDATE #AttendanceRequest SET Att_2 = CASE WHEN CAST(WorkEnd AS TIME) < CAST(WorkStart AS TIME) THEN DATEADD(DAY, 1, AttDate) + Out1 ELSE AttDate + Out1 END
	--  SELECT
	--   EmployeeID,
	--   AttDate,
	--   ShiftCode,
	--   TimeType,
	--   WorkingTime
	--  INTO #InsertListTime
	--  FROM #AttendanceRequest
	--  UNPIVOT
	--  (
	--   WorkingTime FOR TimeType IN (Att_1, Att_2)
	--  ) AS Unpvt
	--  INSERT INTO #tblTmpAttendAndHasTA(AttTime, AttState, EmployeeID, MachineNo, SN)
	--  SELECT WorkingTime, 0, EmployeeID, 100, ''
	--  FROM #InsertListTime
	--  WHERE WorkingTime IS NOT NULL
	--remove duplicate data after deleting seconds
	;

WITH cte
AS (
	SELECT EmployeeID, ROW_NUMBER() OVER (
			PARTITION BY EmployeeID, AttTime ORDER BY sn
			) rn
	FROM #tblTmpAttendAndHasTA w
	)
DELETE
FROM cte
WHERE rn > 1

--#endregion:
--not check ta = 1 thi k care gio cong
DECLARE @RemoveDuplicateAttTime_Interval INT = 120

SELECT @RemoveDuplicateAttTime_Interval = ISNULL(NULLIF(CAST(Value AS INT), 0), 120)
FROM tblParameter WITH (NOLOCK)
WHERE Code = 'RemoveDuplicateAttTime_Interval'

-- Create final attendance table with optimized structure
SELECT DISTINCT CAST(CAST(t.AttTime AS DATETIME2(0)) AS DATETIME) AS AttTime, AttState, t.EmployeeID, t.MachineNo, DATEADD(SECOND, 1, AttTime) AS atttime1, DATEADD(SECOND, @RemoveDuplicateAttTime_Interval, AttTime) AS atttime120, DATEADD(SECOND, - 1, AttTime) AS atttimeM1, DATEADD(SECOND, - @RemoveDuplicateAttTime_Interval, AttTime) AS atttimeM120, CAST(0 AS BIT) AS ForceState
INTO #tblTmpAttend
FROM #tblTmpAttendAndHasTA t

CREATE CLUSTERED INDEX IX_tblTmpAttend ON #tblTmpAttend (EmployeeID, AttTime, AttState)

DROP TABLE #tblTmpAttendAndHasTA

IF (object_id('sp_ShiftDetector_SetForceStateTotblTmpAttend') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_SetForceStateTotblTmpAttend(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime) as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_SetForceStateTotblTmpAttend @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

UPDATE #tblTmpAttend
SET ForceState = 1
WHERE (AttState IN (1, 2) AND @IN_OUT_TA_SEPARATE = 1)

--select * into #tblTmpAttendTimeIn from #tblTmpAttend where 1=0
SELECT *
INTO #tblTmpAttend_Org
FROM #tblTmpAttend

SELECT *
INTO #tblShiftGroup_Shift
FROM tblShiftGroup_Shift sg
WHERE EXISTS (
		SELECT 1
		FROM #tblShiftSetting ss
		WHERE ss.ShiftCode = sg.ShiftCode
		)

--TN:#region set shift
CREATE TABLE #tblShiftGroupCode (EmployeeID VARCHAR(20), ShiftGroupCode INT, FromDate DATETIME, ToDate DATETIME)

CREATE TABLE #tblShiftGroupCode_ByDate (EmployeeID VARCHAR(20), AttDate DATETIME, ShiftGroupCode INT)

SELECT *
INTO #DivDepSecGroByDate
FROM dbo.fn_DivDepSecPosHistory(@FromDate, @ToDate, @LoginID, @EmployeeID)

SELECT *
INTO #fn_ShiftGroupCodeHistory
FROM dbo.fn_ShiftGroupCodeHistory('emp')

INSERT INTO #tblShiftGroupCode_ByDate (EmployeeID, AttDate, ShiftGroupCode)
SELECT sg.EmployeeID, sg.DATE, s.ShiftGroupCode
FROM #tblPendingImportAttend sg
INNER JOIN #fn_ShiftGroupCodeHistory s ON sg.EmployeeID = s.ID AND sg.DATE BETWEEN s.FromDate AND s.Todate
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE sg.EmployeeID = te.EmployeeID
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblShiftGroupCode_ByDate s
		WHERE sg.EmployeeID = s.EmployeeID AND sg.DATE = s.AttDate
		)

TRUNCATE TABLE #fn_ShiftGroupCodeHistory

INSERT INTO #fn_ShiftGroupCodeHistory
SELECT *
FROM dbo.fn_ShiftGroupCodeHistory('gro')

INSERT INTO #tblShiftGroupCode_ByDate (EmployeeID, AttDate, ShiftGroupCode)
SELECT sg.EmployeeID, sg.DATE, e.ShiftGroupCode
FROM #tblPendingImportAttend sg
INNER JOIN #DivDepSecGroByDate gr ON sg.EmployeeID = gr.EmployeeID AND sg.DATE = gr.DATE
INNER JOIN #fn_ShiftGroupCodeHistory e ON gr.GroupID = e.ID AND sg.DATE BETWEEN e.FromDate AND e.Todate
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE sg.EmployeeID = te.EmployeeID
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblShiftGroupCode_ByDate s
		WHERE sg.EmployeeID = s.EmployeeID AND sg.DATE = s.AttDate
		)

TRUNCATE TABLE #fn_ShiftGroupCodeHistory

INSERT INTO #fn_ShiftGroupCodeHistory
SELECT *
FROM dbo.fn_ShiftGroupCodeHistory('sec')

INSERT INTO #tblShiftGroupCode_ByDate (EmployeeID, AttDate, ShiftGroupCode)
SELECT sg.EmployeeID, sg.DATE, e.ShiftGroupCode
FROM #tblPendingImportAttend sg
INNER JOIN #DivDepSecGroByDate gr ON sg.EmployeeID = gr.EmployeeID AND sg.DATE = gr.DATE
INNER JOIN #fn_ShiftGroupCodeHistory e ON gr.SectionID = e.ID AND sg.DATE BETWEEN e.FromDate AND e.Todate
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE sg.EmployeeID = te.EmployeeID
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblShiftGroupCode_ByDate s
		WHERE sg.EmployeeID = s.EmployeeID AND sg.DATE = s.AttDate
		)

TRUNCATE TABLE #fn_ShiftGroupCodeHistory

INSERT INTO #fn_ShiftGroupCodeHistory
SELECT *
FROM dbo.fn_ShiftGroupCodeHistory('dep')

INSERT INTO #tblShiftGroupCode_ByDate (EmployeeID, AttDate, ShiftGroupCode)
SELECT sg.EmployeeID, sg.DATE, e.ShiftGroupCode
FROM #tblPendingImportAttend sg
INNER JOIN #DivDepSecGroByDate gr ON sg.EmployeeID = gr.EmployeeID AND sg.DATE = gr.DATE
INNER JOIN #fn_ShiftGroupCodeHistory e ON gr.DepartmentID = e.ID AND sg.DATE BETWEEN e.FromDate AND e.Todate
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE sg.EmployeeID = te.EmployeeID
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblShiftGroupCode_ByDate s
		WHERE sg.EmployeeID = s.EmployeeID AND sg.DATE = s.AttDate
		)

TRUNCATE TABLE #fn_ShiftGroupCodeHistory

INSERT INTO #fn_ShiftGroupCodeHistory
SELECT *
FROM dbo.fn_ShiftGroupCodeHistory('div')

INSERT INTO #tblShiftGroupCode_ByDate (EmployeeID, AttDate, ShiftGroupCode)
SELECT sg.EmployeeID, sg.DATE, e.ShiftGroupCode
FROM #tblPendingImportAttend sg
INNER JOIN #DivDepSecGroByDate gr ON sg.EmployeeID = gr.EmployeeID AND sg.DATE = gr.DATE
INNER JOIN #fn_ShiftGroupCodeHistory e ON gr.DivisionID = e.ID AND sg.DATE BETWEEN e.FromDate AND e.Todate
WHERE EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE sg.EmployeeID = te.EmployeeID
		) AND e.ShiftGroupCode IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM #tblShiftGroupCode_ByDate s
		WHERE sg.EmployeeID = s.EmployeeID AND sg.DATE = s.AttDate
		)

INSERT INTO #tblShiftGroupCode_ByDate (EmployeeID, AttDate, ShiftGroupCode)
SELECT sg.EmployeeID, sg.DATE, ss.ShiftGroupID
FROM #tblPendingImportAttend sg
CROSS JOIN tblShiftGroup_Shift ss
WHERE NOT EXISTS (
		SELECT 1
		FROM #tblShiftGroupCode_ByDate s
		WHERE sg.EmployeeID = s.EmployeeID AND sg.DATE = s.AttDate
		) AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE sg.EmployeeID = te.EmployeeID
		)

INSERT INTO #tblShiftGroupCode (EmployeeID, ShiftGroupCode, FromDate, ToDate)
SELECT EmployeeID, ShiftGroupCode, AttDate, AttDate
FROM #tblShiftGroupCode_ByDate

DROP TABLE #tblShiftGroupCode_ByDate

DROP TABLE #DivDepSecGroByDate

--#endregion set shift
IF (OBJECT_ID('sp_ShiftDetector_FinishConfigtblShiftGroupCode') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_FinishConfigtblShiftGroupCode ( @StopUpdate bit output ,@LoginID int ,@FromDate datetime ,@ToDate datetime ) as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_FinishConfigtblShiftGroupCode @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

IF (
		SELECT COUNT(1)
		FROM #tblPendingImportAttend
		) = 0
	GOTO FinishedShiftDetector

-- khoa luong, khoa cong roi khong nhan ca nua
--khóa công, theo ngày,tung nguoi
--Luu ý các bác, khóa luong rồi thì k cho mở công
IF (OBJECT_ID('sp_ShiftDetector_Begin_AttLock') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_Begin_AttLock (@StopUpdate bit output) as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_Begin_AttLock @StopUpdate OUTPUT

IF (@StopUpdate = 0)
BEGIN
	--if exists (select 1 from tblAtt_LockMonth where EmployeeID in (select EmployeeID from #tblEmployeeList))
	DELETE tblAtt_LockMonth
	WHERE EmployeeID IS NULL

	DELETE tblAtt_Lock
	WHERE EmployeeID IS NULL

	UPDATE ws
	SET Approved = 1, DateStatus = 3
	FROM #tblWSchedule ws
	WHERE EXISTS (
			SELECT 1
			FROM tblAtt_Lock l
			WHERE ws.EmployeeID = l.EmployeeID AND ws.ScheduleDate = l.DATE
			)

	DELETE ws
	FROM #tblPendingImportAttend ws
	WHERE EXISTS (
			SELECT 1
			FROM tblAtt_Lock l
			WHERE ws.EmployeeID = l.EmployeeID AND ws.DATE = l.DATE
			)
END

-------------detector shift code----------------------------
CREATE TABLE #tblShiftDetector (
	EmployeeId VARCHAR(20) NULL, ScheduleDate DATETIME NULL, ShiftCode VARCHAR(20) NULL, RatioMatch INT NULL, InInterval INT NULL, OutInterval INT NULL, InIntervalS INT NULL, OutIntervalS INT NULL, InIntervalE INT NULL, OutIntervalE INT NULL, AttStart DATETIME NULL, AttEnd DATETIME NULL, AttEnd2 DATETIME NULL, WorkingTimeMi INT NULL, StdWorkingTimeMi INT NULL, Late_Permit INT NULL, Early_Permit INT NULL, AttStartMi INT NULL, AttEndMi INT NULL, AttEndMi2 INT NULL, ShiftID INT NULL, WorkStart DATETIME NULL, WorkEnd DATETIME NULL, WorkStartMi INT NULL, WorkEndMi INT NULL, BreakStartMi INT NULL, BreakEndMi INT NULL, WorkStartSMi INT NULL, WorkEndSMi INT NULL, WorkStartEMi INT NULL, WorkEndEMi INT NULL, BreakStart DATETIME NULL, BreakEnd DATETIME NULL, OTBeforeStart DATETIME NULL, OTBeforeEnd DATETIME NULL, OTAfterStart DATETIME NULL, OTAfterEnd DATETIME NULL, AttEndYesterday DATETIME NULL, AttStartTomorrow DATETIME NULL, AttEndYesterdayFixed BIT NULL, AttStartTomorrowFixed BIT NULL, AttEndYesterdayFixedTblHasta BIT NULL, AttStartTomorrowFixedTblHasta BIT NULL, isNightShift BIT NULL, isNightShiftYesterday BIT NULL, 
	ShiftCodeYesterday VARCHAR(20) NULL, isOfficalShift BIT NULL, HolidayStatus INT NULL, FixedAtt BIT NULL, TIMEINBEFORE DATETIME NULL, INOUT_MINIMUM FLOAT NULL, TIMEOUTAFTER DATETIME NULL, isWrongShift BIT NULL, Approved BIT NULL, IsLeaveStatus3 BIT NULL, StateIn INT NULL, -- is Correct In [1]
	StateOut INT NULL, -- is Correct Out [2]
	EmployeeStatusID INT NULL, SwipeOptionID INT NULL
	)

IF (OBJECT_ID('sp_ShiftDetector_AdditionColumn') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_AdditionColumn (@StopUpdate bit output) as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_AdditionColumn @StopUpdate OUTPUT

SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, cast(NULL AS DATETIME) AS Prevdate, cast(NULL AS DATETIME) AS NextDate, IsLeaveStatus3
INTO #tblPrevMatch
FROM #tblShiftDetector
WHERE 1 = 0

--create clustered index indextblPrevMatch on #tblPrevMatch(EmployeeID,PrevDate,NextDate)
CREATE TABLE #tblPrevRemove (EmployeeId NVARCHAR(20) NULL, ScheduleDate DATETIME NULL, ShiftCode NVARCHAR(20) NULL)

CREATE TABLE #tblShiftDetectorReprocess (STT INT NULL, EmployeeId VARCHAR(20) NULL, ScheduleDate DATETIME NULL, ShiftCode VARCHAR(20) NULL, WorkStart DATETIME NULL, WorkEnd DATETIME NULL, AttEndYesterday DATETIME NULL, AttStartTomorrow DATETIME NULL)

SELECT *
INTO #tblShiftDetectorMatched
FROM #tblShiftDetector
WHERE 1 = 0

CREATE CLUSTERED INDEX IX_tblShiftDetectorMatched_Emp_Sch ON #tblShiftDetectorMatched (EmployeeId, ScheduleDate)

INSERT INTO #tblShiftDetectorMatched (EmployeeId, ScheduleDate, EmployeeStatusID)
SELECT pe.EmployeeID, pe.DATE, pe.EmployeeStatusID
FROM #tblPendingImportAttend pe
INNER JOIN #tblEmployeeList e ON pe.EmployeeID = e.EmployeeID
GROUP BY pe.EmployeeID, pe.DATE, pe.EmployeeStatusID

/*
Xu ly nhung nhan vien di lam 2 ca 1 ngay
1. Đi ca 1 + ca 3
2. Đi Ca 1 + Ca 2
3. Đi Ca 2+ Ca 3
4. Đi HC + Ca 3
*/
CREATE TABLE #tblWorking2ShiftADay_Detect (
	EmployeeID VARCHAR(20), ScheduleDate DATETIME, ShiftCode1 VARCHAR(20), AttStart1 DATETIME, AttEnd1 DATETIME, WorkStartMi1 INT, WorkEndMi1 INT, AttTimeStart1Min DATETIME, AttTimeStart1Max DATETIME, AttTimeEnd1Min DATETIME, AttTimeEnd1Max DATETIME, ShiftCode2 VARCHAR(20), AttStart2 DATETIME, AttEnd2 DATETIME, WorkStartMi2 INT, WorkEndMi2 INT, AttTimeStart2Min DATETIME, AttTimeStart2Max DATETIME, AttTimeEnd2Min DATETIME, AttTimeEnd2Max DATETIME, WorkingStyleId INT, --1. Đi ca 1 + ca 3, 2. Đi Ca 1 + Ca 2, 3. Đi Ca 2+ Ca 3, 4. Đi HC + Ca 3
	)

IF (object_id('sp_ShiftDetector_Working2ShiftADay_Detect') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_Working2ShiftADay_Detect(@StopUpdate bit output)as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_Working2ShiftADay_Detect @StopUpdate OUTPUT

IF @StopUpdate = 0
BEGIN
	INSERT INTO #tblShiftDetector (EmployeeID, ScheduleDate, ShiftCode, HolidayStatus, RatioMatch, EmployeeStatusID)
	SELECT c.EmployeeID, s.ScheduleDate, sg.ShiftCode, s.HolidayStatus, 0, EmployeeStatusID
	FROM #tblShiftDetectorMatched s
	INNER JOIN #tblShiftGroupCode c ON s.EmployeeId = c.EmployeeID
	FULL OUTER JOIN #tblShiftGroup_Shift sg ON c.ShiftGroupCode = sg.ShiftGroupID
	WHERE sg.ShiftCode IS NOT NULL AND s.EmployeeId IS NOT NULL AND s.ScheduleDate BETWEEN c.FromDate AND c.ToDate AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList te
			WHERE s.employeeID = te.EmployeeID AND te.Working2ShiftADay = 1
			)

	INSERT INTO #tblShiftDetector (EmployeeID, ScheduleDate, ShiftCode, HolidayStatus, RatioMatch, EmployeeStatusID)
	SELECT s.EmployeeID, s.ScheduleDate, ss.ShiftCode, s.HolidayStatus, 0, EmployeeStatusID
	FROM #tblShiftDetectorMatched s
	CROSS JOIN (
		SELECT ShiftCode
		FROM #tblShiftSetting
		GROUP BY ShiftCode
		) ss
	WHERE NOT EXISTS (
			SELECT 1
			FROM #tblShiftDetector sd
			WHERE s.EmployeeId = sd.EmployeeID AND s.Scheduledate = sd.Scheduledate
			)

	-- cap ca 1, Ca 3
	INSERT INTO #tblWorking2ShiftADay_Detect (EmployeeId, ScheduleDate, WorkingStyleID, ShiftCode1, WorkStartMi1, WorkEndMi1, AttTimeStart1Min, AttTimeStart1Max, AttTimeEnd1Min, AttTimeEnd1Max, ShiftCode2, WorkStartMi2, WorkEndMi2, AttTimeStart2Min, AttTimeStart2Max, AttTimeEnd2Min, AttTimeEnd2Max)
	SELECT d1.EmployeeId, d1.ScheduleDate, 1 AS WorkingStyleID, s1.ShiftCode ShiftCode1, s1.WorkStartMi, s1.WorkEndMi, DATEADD(mi, s1.WorkStartMi - 60, d1.ScheduleDate) AttTimeStart1Min, DATEADD(mi, s1.WorkStartMi + 60, d1.ScheduleDate) AttTimeStart1Max, DATEADD(mi, s1.WorkEndMi - 60, d1.ScheduleDate) AttTimeEnd1Min, DATEADD(mi, s1.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd1Max, s2.ShiftCode ShiftCode2, s2.WorkStartMi, s2.WorkEndMi, DATEADD(mi, s2.WorkStartMi - 60, d2.ScheduleDate) AttTimeStart2Min, DATEADD(mi, s2.WorkStartMi + 60, d2.ScheduleDate) AttTimeStart2Max, DATEADD(mi, s2.WorkEndMi - 60, d2.ScheduleDate) AttTimeEnd2Min, DATEADD(mi, s2.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd2Max
	FROM #tblShiftDetector d1
	INNER JOIN #tblShiftSetting s1 ON d1.ShiftCode = s1.ShiftCode
	INNER JOIN #tblShiftDetector d2 ON d1.EmployeeId = d2.EmployeeId AND d1.ScheduleDate = d2.ScheduleDate
	INNER JOIN #tblShiftSetting s2 ON d2.ShiftCode = s2.ShiftCode
	WHERE s1.WorkStartMi BETWEEN 300 AND 420 AND s2.WorkStartMi BETWEEN 1260 AND 1380 AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList te
			WHERE d1.EmployeeId = te.EmployeeID AND Working2ShiftADay = 1
			)

	-- cap ca 1, ca 2
	INSERT INTO #tblWorking2ShiftADay_Detect (EmployeeId, ScheduleDate, WorkingStyleID, ShiftCode1, WorkStartMi1, WorkEndMi1, AttTimeStart1Min, AttTimeStart1Max, AttTimeEnd1Min, AttTimeEnd1Max, ShiftCode2, WorkStartMi2, WorkEndMi2, AttTimeStart2Min, AttTimeStart2Max, AttTimeEnd2Min, AttTimeEnd2Max)
	SELECT d1.EmployeeId, d1.ScheduleDate, 2 AS WorkingStyleID, s1.ShiftCode ShiftCode1, s1.WorkStartMi, s1.WorkEndMi, DATEADD(mi, s1.WorkStartMi - 60, d1.ScheduleDate) AttTimeStart1Min, DATEADD(mi, s1.WorkStartMi + 60, d1.ScheduleDate) AttTimeStart1Max, DATEADD(mi, s1.WorkEndMi - 60, d1.ScheduleDate) AttTimeEnd1Min, DATEADD(mi, s1.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd1Max, s2.ShiftCode ShiftCode2, s2.WorkStartMi, s2.WorkEndMi, DATEADD(mi, s2.WorkStartMi - 60, d2.ScheduleDate) AttTimeStart2Min, DATEADD(mi, s2.WorkStartMi + 60, d2.ScheduleDate) AttTimeStart2Max, DATEADD(mi, s2.WorkEndMi - 60, d2.ScheduleDate) AttTimeEnd2Min, DATEADD(mi, s2.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd2Max
	FROM #tblShiftDetector d1
	INNER JOIN #tblShiftSetting s1 ON d1.ShiftCode = s1.ShiftCode
	INNER JOIN #tblShiftDetector d2 ON d1.EmployeeId = d2.EmployeeId AND d1.ScheduleDate = d2.ScheduleDate
	INNER JOIN #tblShiftSetting s2 ON d2.ShiftCode = s2.ShiftCode
	WHERE s1.WorkStartMi BETWEEN 300 AND 420 AND s2.WorkStartMi BETWEEN 780 AND 900 AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList te
			WHERE d1.EmployeeId = te.EmployeeID AND Working2ShiftADay = 1
			)

	-- cap ca 2, ca 3
	INSERT INTO #tblWorking2ShiftADay_Detect (EmployeeId, ScheduleDate, WorkingStyleID, ShiftCode1, WorkStartMi1, WorkEndMi1, AttTimeStart1Min, AttTimeStart1Max, AttTimeEnd1Min, AttTimeEnd1Max, ShiftCode2, WorkStartMi2, WorkEndMi2, AttTimeStart2Min, AttTimeStart2Max, AttTimeEnd2Min, AttTimeEnd2Max)
	SELECT d1.EmployeeId, d1.ScheduleDate, 3 AS WorkingStyleID, s1.ShiftCode ShiftCode1, s1.WorkStartMi, s1.WorkEndMi, DATEADD(mi, s1.WorkStartMi - 60, d1.ScheduleDate) AttTimeStart1Min, DATEADD(mi, s1.WorkStartMi + 60, d1.ScheduleDate) AttTimeStart1Max, DATEADD(mi, s1.WorkEndMi - 60, d1.ScheduleDate) AttTimeEnd1Min, DATEADD(mi, s1.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd1Max, s2.ShiftCode ShiftCode2, s2.WorkStartMi, s2.WorkEndMi, DATEADD(mi, s2.WorkStartMi - 60, d2.ScheduleDate) AttTimeStart2Min, DATEADD(mi, s2.WorkStartMi + 60, d2.ScheduleDate) AttTimeStart2Max, DATEADD(mi, s2.WorkEndMi - 60, d2.ScheduleDate) AttTimeEnd2Min, DATEADD(mi, s2.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd2Max
	FROM #tblShiftDetector d1
	INNER JOIN #tblShiftSetting s1 ON d1.ShiftCode = s1.ShiftCode
	INNER JOIN #tblShiftDetector d2 ON d1.EmployeeId = d2.EmployeeId AND d1.ScheduleDate = d2.ScheduleDate
	INNER JOIN #tblShiftSetting s2 ON d2.ShiftCode = s2.ShiftCode
	WHERE s1.WorkStartMi BETWEEN 780 AND 900 AND s2.WorkStartMi BETWEEN 1260 AND 1380 AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList te
			WHERE d1.EmployeeId = te.EmployeeID AND Working2ShiftADay = 1
			)

	-- cap HC, Ca3
	INSERT INTO #tblWorking2ShiftADay_Detect (EmployeeId, ScheduleDate, WorkingStyleID, ShiftCode1, WorkStartMi1, WorkEndMi1, AttTimeStart1Min, AttTimeStart1Max, AttTimeEnd1Min, AttTimeEnd1Max, ShiftCode2, WorkStartMi2, WorkEndMi2, AttTimeStart2Min, AttTimeStart2Max, AttTimeEnd2Min, AttTimeEnd2Max)
	SELECT d1.EmployeeId, d1.ScheduleDate, 4 AS WorkingStyleID, s1.ShiftCode ShiftCode1, s1.WorkStartMi, s1.WorkEndMi, DATEADD(mi, s1.WorkStartMi - 60, d1.ScheduleDate) AttTimeStart1Min, DATEADD(mi, s1.WorkStartMi + 60, d1.ScheduleDate) AttTimeStart1Max, DATEADD(mi, s1.WorkEndMi - 60, d1.ScheduleDate) AttTimeEnd1Min, DATEADD(mi, s1.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd1Max, s2.ShiftCode ShiftCode2, s2.WorkStartMi, s2.WorkEndMi, DATEADD(mi, s2.WorkStartMi - 60, d2.ScheduleDate) AttTimeStart2Min, DATEADD(mi, s2.WorkStartMi + 60, d2.ScheduleDate) AttTimeStart2Max, DATEADD(mi, s2.WorkEndMi - 60, d2.ScheduleDate) AttTimeEnd2Min, DATEADD(mi, s2.WorkEndMi + 60, d2.ScheduleDate) AttTimeEnd2Max
	FROM #tblShiftDetector d1
	INNER JOIN #tblShiftSetting s1 ON d1.ShiftCode = s1.ShiftCode
	INNER JOIN #tblShiftDetector d2 ON d1.EmployeeId = d2.EmployeeId AND d1.ScheduleDate = d2.ScheduleDate
	INNER JOIN #tblShiftSetting s2 ON d2.ShiftCode = s2.ShiftCode
	WHERE s1.WorkStartMi BETWEEN 421 AND 540 AND s2.WorkStartMi BETWEEN 1260 AND 1380 AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList te
			WHERE d1.EmployeeId = te.EmployeeID AND Working2ShiftADay = 1
			)

	TRUNCATE TABLE #tblShiftDetector

	-- neu biet chac ca dau la ca nao thi luoc bo du lieu cho nhe
	DELETE s
	FROM #tblWorking2ShiftADay_Detect s
	WHERE EXISTS (
			SELECT 1
			FROM #tblWorking2ShiftADay_Detect d
			WHERE EXISTS (
					SELECT 1
					FROM #tblWSchedule ws
					WHERE ws.Approved = 1 AND d.EmployeeID = ws.EmployeeID AND d.ScheduleDate = ws.ScheduleDate AND d.ShiftCode1 = ws.ShiftCode
					) AND s.EmployeeID = d.EmployeeID AND s.ScheduleDate = d.ScheduleDate AND d.ShiftCode1 <> s.ShiftCode1
			)

	-- neu hom sau biet chac di ca 1 thi loai bo nhung cap ca sau la ca 3
	DELETE s
	FROM #tblWorking2ShiftADay_Detect s
	WHERE EXISTS (
			SELECT 1
			FROM #tblWorking2ShiftADay_Detect d
			WHERE EXISTS (
					SELECT 1
					FROM #tblWSchedule ws
					WHERE ws.Approved = 1 AND d.EmployeeID = ws.EmployeeID AND d.ScheduleDate = ws.ScheduleDate AND d.ShiftCode1 = ws.ShiftCode AND d.WorkStartMi1 < 421
					) AND s.EmployeeID = d.EmployeeID AND s.ScheduleDate = d.ScheduleDate - 1 AND abs(d.WorkStartMi1 + 1440 - s.WorkEndMi2) < 30
			)

	-- neu biet chac hom do di ca 3 thi khong co chuyen lam chong ca
	--select * from #tblWSchedule ws where ws.Approved = 1 and exists (select 1 from #tblShiftSetting ss where ws.ShiftID = ss.ShiftID and ss.WorkEnd > 1440)
	--select * from #tblWorking2ShiftADay_Detect order by EmployeeID,ScheduleDate return
	-- AttStart1
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttStart1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT max(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime BETWEEN d.AttTimeStart1Min AND dateadd(mi, d.WorkStartMi1, d.ScheduleDate)
		WHERE (att.ForceState = 0 OR att.AttState = 1)
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	UPDATE #tblWorking2ShiftADay_Detect
	SET AttStart1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT Min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime BETWEEN dateadd(mi, d.WorkStartMi1, d.ScheduleDate) AND d.AttTimeStart1Max
		WHERE d.AttStart1 IS NULL AND (att.ForceState = 0 OR att.AttState = 1)
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	-- doi di lam an xa
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttStart1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT Min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND abs(datediff(mi, d.ScheduleDate, att.AttTime) - d.WorkStartMi1) < 241
		WHERE d.AttStart1 IS NULL AND (att.ForceState = 0 OR att.AttState = 1)
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	-- AttEnd1
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttEnd1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT Min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime BETWEEN dateadd(mi, d.WorkEndMi1, d.ScheduleDate) AND d.AttTimeEnd1Max
		WHERE d.WorkingStyleId = 1 -- chi trường hợp cặp ca 1, ca 3 mới tách Min max
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	UPDATE #tblWorking2ShiftADay_Detect
	SET AttEnd1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT max(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime > d.AttStart1 AND att.AttTime BETWEEN d.AttTimeEnd1Min AND dateadd(mi, d.WorkEndMi1, d.ScheduleDate)
		WHERE d.AttEnd1 IS NULL AND d.WorkingStyleId = 1 -- chi trường hợp cặp ca 1, ca 3 mới tách Min max
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	UPDATE #tblWorking2ShiftADay_Detect
	SET AttEnd1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime > d.AttStart1 AND att.AttTime BETWEEN d.AttTimeEnd1Min AND d.AttTimeEnd1Max
		WHERE d.AttEnd1 IS NULL -- truong hop con lai lay min, de thang con lai cho cap sau
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	-- đói đi làm ăn xa
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttEnd1 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime > d.AttEnd1 AND abs(datediff(mi, d.ScheduleDate, att.AttTime) - d.WorkEndMi1) < 241
		WHERE d.AttEnd1 IS NULL -- truong hop con lai lay min, de thang con lai cho cap sau
			AND NOT EXISTS (
				SELECT 1
				FROM #tblWorking2ShiftADay_Detect w
				WHERE d.EmployeeID = w.EmployeeID AND d.ScheduleDate = w.ScheduleDate AND w.AttStart1 IS NOT NULL AND w.AttEnd1 IS NOT NULL
				)
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	-- AttStart2
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttStart2 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT max(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime > d.AttEnd1 AND att.AttTime BETWEEN d.AttTimeStart2Min AND dateadd(mi, d.WorkStartMi2, d.ScheduleDate)
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	UPDATE #tblWorking2ShiftADay_Detect
	SET AttStart2 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT Min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime > d.AttEnd1 AND att.AttTime BETWEEN dateadd(mi, d.WorkStartMi2, d.ScheduleDate) AND d.AttTimeStart2Max
		WHERE d.AttStart2 IS NULL
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	-- doi thi di lam an xa
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttStart2 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT Min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime > d.AttEnd1 AND abs(datediff(mi, d.ScheduleDate, att.AttTime) - d.WorkStartMi2) < 241
		WHERE d.AttStart2 IS NULL
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	-- AttEnd2
	UPDATE #tblWorking2ShiftADay_Detect
	SET AttEnd2 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT Min(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime BETWEEN dateadd(mi, d.WorkEndMi2, d.ScheduleDate) AND d.AttTimeEnd2Max
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	UPDATE #tblWorking2ShiftADay_Detect
	SET AttEnd2 = t.AttTime
	FROM #tblWorking2ShiftADay_Detect d
	INNER JOIN (
		SELECT max(att.AttTime) AttTime, d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		FROM #tblWorking2ShiftADay_Detect d
		INNER JOIN #tblTmpAttend att ON d.EmployeeID = att.EmployeeID AND att.AttTime BETWEEN d.AttTimeEnd2Min AND dateadd(mi, d.WorkEndMi2, d.ScheduleDate)
		WHERE d.AttEnd2 IS NULL
		GROUP BY d.employeeID, d.ScheduleDate, d.ShiftCode1, d.ShiftCode2
		) t ON d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode1 = t.ShiftCode1 AND d.ShiftCode2 = t.ShiftCode2

	--select AttStart1,AttEnd1,AttStart2,AttEnd2,ShiftCode1,ShiftCode2,* from #tblWorking2ShiftADay_Detect order by employeeId, scheduleDate return
	DELETE #tblWorking2ShiftADay_Detect
	WHERE (AttStart1 IS NULL OR AttEnd1 IS NULL OR AttStart2 IS NULL OR AttEnd2 IS NULL)

	--select AttStart1,AttEnd1,AttStart2,AttEnd2,ShiftCode1,ShiftCode2,* from #tblWorking2ShiftADay_Detect where ScheduleDate = '2019-04-18' order by employeeId, scheduleDate return
	DELETE d
	FROM #tblWorking2ShiftADay_Detect d
	WHERE NOT EXISTS (
			SELECT 1
			FROM (
				SELECT max(datediff(mi, d.AttEnd1, d.AttStart2)) MaxSE, d.EmployeeID, d.ScheduleDate
				FROM #tblWorking2ShiftADay_Detect d
				GROUP BY d.EmployeeID, d.ScheduleDate
				) t
			WHERE d.EmployeeID = t.EmployeeID AND d.ScheduleDate = t.ScheduleDate AND datediff(mi, d.AttEnd1, d.AttStart2) = t.MaxSE
			)
		--select AttStart1,AttEnd1,AttStart2,AttEnd2,ShiftCode1,ShiftCode2,* from #tblWorking2ShiftADay_Detect order by employeeId, scheduleDate return
END

SELECT *
INTO #tblHoliday
FROM tblHoliday
WHERE LeaveDate BETWEEN @FromDate AND @ToDate

IF (OBJECT_ID('sp_ShiftDetector_Begin_HolidayStatusByEmployeeType') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_Begin_HolidayStatusByEmployeeType(@StopUpdate bit output)as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_Begin_HolidayStatusByEmployeeType @StopUpdate OUTPUT

IF (@StopUpdate = 0)
BEGIN
	-- tu bang tblwschdule
	UPDATE m
	SET HolidayStatus = s.HolidayStatus
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT EmployeeID, ScheduleDate, HolidayStatus
		FROM #tblWSchedule s
		WHERE s.ApprovedHolidayStatus = 1
		) s ON m.EmployeeId = s.EmployeeID AND m.ScheduleDate = s.ScheduleDate

	--where m.HolidayStatus is null -- bỏ đi do approvedholidaystatus tức là khách đã approve cái ngày đó là nghỉ hay đi làm rồi
	CREATE TABLE #tblHasHoliday (EmployeeID VARCHAR(20), ScheduleDate DATE)

	INSERT INTO #tblHasHoliday (EmployeeID, ScheduleDate)
	SELECT EmployeeID, ScheduleDate
	FROM (
		UPDATE d
		SET HolidayStatus = h.HolidayStatus
		OUTPUT inserted.EmployeeId, inserted.ScheduleDate
		FROM #tblShiftDetectorMatched d
		INNER JOIN #tblEmployeeList e ON d.EmployeeId = e.EmployeeID
		INNER JOIN #tblHoliday h ON h.LeaveDate = d.ScheduleDate AND (e.EmployeeTypeID = h.EmployeeTypeID OR h.EmployeeTypeID = - 1)
		LEFT JOIN dbo.fn_EmployeeStatusRange(0) es ON d.EmployeeId = es.EmployeeID AND d.ScheduleDate BETWEEN es.ChangedDate AND es.StatusEndDate AND es.EmployeeStatusID IN (
				SELECT EmployeeStatusID
				FROM tblEmployeeStatus
				WHERE isnull(CutSI, 0) = 0
				)
		WHERE d.HolidayStatus IS NULL AND es.EmployeeID IS NOT NULL
		) ho

	-- tu loai nhan vien
	UPDATE d
	SET HolidayStatus = CASE 
			WHEN (e.SaturdayOff = 1 AND DATENAME(dw, d.ScheduleDate) = 'Saturday') OR (e.SundayOff = 1 AND DATENAME(dw, d.ScheduleDate) = 'Sunday')
				THEN 1
			ELSE NULL
			END
	FROM #tblShiftDetectorMatched d
	INNER JOIN #tblEmployeeList e ON d.EmployeeId = e.EmployeeID
	WHERE d.HolidayStatus IS NULL

	SELECT @Month = Month, @Year = Year
	FROM dbo.fn_Get_Sal_Month_Year(@FromDate)

	--TRIPOD: 2 ngày làm việc thứ 7
	SELECT EmployeeID, SaturdayDate AS SatDate
	INTO #SatWorkList
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)
	--WHERE SaturdayDate BETWEEN @FromDate AND @ToDate
	
	UNION
	
	SELECT EmployeeID, SaturdayDate_2nd AS SatDate
	FROM dbo.fn_GetEmployeeSatWork(@LoginID, @Month, @Year)

	UPDATE s
	SET HolidayStatus = 0
	FROM #tblShiftDetectorMatched s
	INNER JOIN #SatWorkList sw ON s.EmployeeID = sw.EmployeeID AND s.ScheduleDate = sw.SatDate

	UPDATE #tblShiftDetectorMatched
	SET HolidayStatus = 0
	WHERE HolidayStatus IS NULL

	--hpsf: Vu - employeeTypeID = 0, làm 2 thứ 7 giữa tháng thực tế (không phải tháng chu kì lương)
	--  SELECT *
	--  INTO #SatList
	--  FROM dbo.fn_Get2SatMidOfMonth(MONTH(@FromDate), YEAR(@FromDate))
	--  UNION
	--  SELECT *
	--  FROM dbo.fn_Get2SatMidOfMonth(MONTH(@ToDate), YEAR(@ToDate))
	--  WHERE MONTH(@FromDate) <> MONTH(@ToDate) OR YEAR(@FromDate) <> YEAR(@ToDate)
	-- --2 sat in the mid of month
	--  UPDATE d SET HolidayStatus = 0
	--  FROM #tblShiftDetectorMatched d
	--  INNER JOIN #tblEmployeeList e ON d.EmployeeId = e.EmployeeID
	--  WHERE ScheduleDate IN (SELECT SatDate FROM #SatList) AND e.EmployeeTypeID = 0
	/*
 --TN:le roi vao ngày nghỉ tuần thì k insert nghỉ, chỉ cập nhật HolidayStatus
 DELETE #tblHasHOliday FROM #tblHasHOliday h
 INNER JOIN (
 SELECT d.EmployeeId, d.ScheduleDate, CASE when (e.SaturdayOff = 1 and DATENAME(dw,d.ScheduleDate) = 'Saturday') OR (e.SundayOff = 1 and DATENAME(dw,d.ScheduleDate) = 'Sunday') then 1 else null END OffWeek
 from #tblShiftDetectorMatched d
 inner join #tblEmployeeList e on d.EmployeeId = e.EmployeeID
 ) so ON h.EmployeeID = so.EmployeeId AND h.ScheduleDate = so.ScheduleDate AND so.OffWeek = 1

 */
	SELECT m.EmployeeID, m.ScheduleDate, h.LeaveStatus, h.LeaveCode LeaveCode, CASE 
			WHEN h.LeaveStatus IN (1, 2)
				THEN 4
			WHEN h.LeaveStatus IN (4, 5)
				THEN 2
			ELSE 8
			END LvAmount, 1 LvRegister, N'System automatically insert leave' Reason, h.EmployeeTypeID
	INTO #LeaveAuto
	FROM #tblHasHoliday m
	INNER JOIN #tblEmployeeList e ON m.EmployeeID = e.EmployeeID
	INNER JOIN #tblHoliday h ON m.ScheduleDate = h.LeaveDate AND (e.EmployeeTypeID = h.EmployeeTypeID OR h.EmployeeTypeID = - 1) AND h.LeaveCode IS NOT NULL

	-- remove duplicate holiday record
	DELETE l
	FROM #LeaveAuto l
	INNER JOIN (
		SELECT l.EmployeeID, l.ScheduleDate, l.LeaveCode, max(l.EmployeeTypeID) EmployeeTypeID
		FROM #LeaveAuto l
		GROUP BY l.EmployeeID, l.ScheduleDate, l.LeaveCode
		HAVING count(1) > 1
		) tmp ON l.EmployeeID = tmp.EmployeeID AND l.ScheduleDate = tmp.ScheduleDate AND l.LeaveCode = tmp.LeaveCode AND l.EmployeeTypeID < tmp.EmployeeTypeID

	DELETE lv
	FROM tblLvHistory lv
	INNER JOIN #tblShiftDetectorMatched m ON lv.EmployeeID = m.EmployeeId AND lv.LeaveDate = m.ScheduleDate
	WHERE lv.LeaveDate BETWEEN @FromDate AND @ToDate AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList te
			WHERE lv.EmployeeID = te.EmployeeID
			) AND Reason = N'System automatically insert leave'
		-- xóa tất cả những thằng cản đường
		AND NOT EXISTS (
			SELECT 1
			FROM #LeaveAuto la
			WHERE lv.EmployeeID = la.EmployeeID AND lv.LeaveDate = la.ScheduleDate AND lv.LeaveCode = la.LeaveCode AND lv.LvAmount = la.LvAmount
			)

	/*
delete tblLvHistory
from tblLvHistory lv
where exists (select 1 from #tblEmployeeList st where lv.EmployeeID=st.EmployeeID and lv.LeaveDate between dateadd(dd, -30, st.HireDate) and st.HireDate)
and lv.Reason=N'System automatically insert leave'
*/
	INSERT INTO tblLvHistory (EmployeeID, LeaveDate, LeaveStatus, LeaveCode, LvAmount, LvRegister, Reason)
	SELECT EmployeeID, ScheduleDate, LeaveStatus, LeaveCode, LvAmount, LvRegister, Reason
	FROM #LeaveAuto la
	WHERE NOT EXISTS (
			SELECT 1
			FROM tblLvHistory lv
			WHERE la.EmployeeID = lv.EmployeeID AND la.ScheduleDate = lv.LeaveDate
			)

	DROP TABLE #LeaveAuto

	-- --HPSF: NVVP vẫn làm 48h/tuần nhưng làm bù vào các ngày trong tuần và nghỉ thứ 7 nên thêm 1 loại nghỉ bù thứ 7 để đếm công
	--  select e.EmployeeID, s.SatDate, 3 LeaveStatus,  'P' LeaveCode, 8 LvAmount, 1 LvRegister, N'System automatically insert Compensatory Leave for staff' Reason, e.EmployeeTypeID
	-- into #LeaveBu
	-- from  #tblEmployeeList e
	-- CROSS JOIN #SatList s
	-- WHERE e.EmployeeTypeID = 1 AND EmployeeStatusID NOT IN (1) AND SatDate BETWEEN @FromDate AND @ToDate
	-- insert into tblLvHistory(EmployeeID, LeaveDate, LeaveStatus, LeaveCode, LvAmount, LvRegister, Reason)
	-- select EmployeeID, SatDate, LeaveStatus, LeaveCode, LvAmount, LvRegister, Reason
	-- from #LeaveBu la
	-- where not exists (select 1 from tblLvHistory lv where la.EmployeeID=lv.EmployeeID and la.SatDate=lv.LeaveDate)
	IF @trackingML = 1
	BEGIN
		--phot vao roi thi xoa di
		DELETE tblLvHistory
		FROM tblLvHistory lv
		INNER JOIN #tblPendingImportAttend p ON lv.EmployeeID = p.EmployeeID AND lv.LeaveDate = p.DATE AND EXISTS (
				SELECT 1
				FROM tblEmployeeStatus es
				WHERE es.CutSI = 1 AND lv.LeaveCode = es.LeaveCodeForCutSI
				)
		WHERE lv.Reason = N'System automatically insert leave' AND lv.LeaveDate BETWEEN @FromDate AND @ToDate

		--insert into tblLvHistory(EmployeeID,LeaveDate,LeaveCode,LeaveStatus,LvAmount,Reason)
		SELECT ws.EmployeeID, ws.ScheduleDate AS LeaveDate, s.LeaveCodeForCutSI AS LeaveCode, 3 AS LeaveStatus, 8 AS LvAmount, N'System automatically insert leave' AS Reason
		INTO #CutSItblLvHistory
		FROM tblWSchedule ws
		INNER JOIN #tblPendingImportAttend p ON ws.EmployeeID = p.EmployeeID AND ws.ScheduleDate = p.DATE
		INNER JOIN tblEmployeeStatus s ON p.EmployeeStatusID = s.EmployeeStatusID AND s.CutSI = 1 AND s.LeaveCodeForCutSI IS NOT NULL AND s.LeaveCodeForCutSI IN (
				SELECT LeaveCode
				FROM tblLeaveType
				)
		WHERE ws.HolidayStatus = 0 AND ws.ScheduleDate BETWEEN @FromDate AND @ToDate AND NOT EXISTS (
				SELECT 1
				FROM tblLvHistory lv
				WHERE ws.EmployeeID = lv.EmployeeID AND ws.ScheduleDate = lv.LeaveDate AND isnull(lv.Reason, '') <> 'System automatically insert leave'
				)

		EXEC sp_InsertUpdateFromTempTableTOTable '#CutSItblLvHistory', 'tblLvHistory'

		DROP TABLE #CutSItblLvHistory
	END
END

IF (OBJECT_ID('sp_ShiftDetector_Finish_HolidayStatusByEmployeeType') IS NULL)
BEGIN
	EXEC (
			'CREATE PROCEDURE dbo.sp_ShiftDetector_Finish_HolidayStatusByEmployeeType
(@StopUpdate bit output)
as
begin
 SET NOCOUNT ON;
end'
			)
END

SET @StopUpdate = 0

EXEC sp_ShiftDetector_Finish_HolidayStatusByEmployeeType @StopUpdate OUTPUT

-- leave
SELECT lv.EmployeeID, lv.LeaveDate, lv.LeaveStatus, lv.LeaveCode, lv.LvAmount, isnull(lt.PaidRate, 0) PaidRate, lt.LeaveCategory, lv.Reason
INTO #tblLvHistory
FROM tblLvHistory lv
INNER JOIN tblLeaveType lt ON lv.LeaveCode = lt.LeaveCode
LEFT JOIN (
	SELECT LeaveCode
	FROM tblLeaveType
	WHERE (LeaveCategory = 1 OR (LeaveCategory = 0 AND PaidRate = 0)) AND LeaveCode <> 'FWC'
	) lc ON lc.LeaveCode = lt.LeaveCode
WHERE lv.LeaveDate BETWEEN @FromDate3 AND @ToDate3 AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE lv.EmployeeID = te.EmployeeID
		) AND lc.LeaveCode IS NOT NULL

--create nonclustered index ix_temptblLvHistory on #tblLvHistory(EmployeeId,Leavedate,LeaveStatus,LeaveCode) include(lvamount,PaidRate)
SELECT lv.EmployeeId, lv.LeaveDate, lv.LeaveStatus
INTO #tblFWC
FROM tblLvhistory lv
WHERE lv.LeaveDate BETWEEN @FromDate3 AND @ToDate3 AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE lv.EmployeeID = te.EmployeeID
		) AND lv.LeaveCode = 'FWC'

-- dua các ca vào để chấm điểm
INSERT INTO #tblShiftDetector (EmployeeID, ScheduleDate, ShiftCode, HolidayStatus, RatioMatch, EmployeeStatusID)
SELECT c.EmployeeID, s.ScheduleDate, sg.ShiftCode, s.HolidayStatus, 0, EmployeeStatusID
FROM #tblShiftDetectorMatched s
INNER JOIN #tblShiftGroupCode c ON s.EmployeeId = c.EmployeeID
FULL OUTER JOIN #tblShiftGroup_Shift sg ON c.ShiftGroupCode = sg.ShiftGroupID
WHERE sg.ShiftCode IS NOT NULL AND s.EmployeeId IS NOT NULL AND s.ScheduleDate BETWEEN c.FromDate AND c.ToDate

INSERT INTO #tblShiftDetector (EmployeeID, ScheduleDate, ShiftCode, HolidayStatus, RatioMatch, EmployeeStatusID)
SELECT s.EmployeeID, s.ScheduleDate, ss.ShiftCode, s.HolidayStatus, 0, EmployeeStatusID
FROM #tblShiftDetectorMatched s
CROSS JOIN (
	SELECT ShiftCode
	FROM #tblShiftSetting
	GROUP BY ShiftCode
	) ss
WHERE NOT EXISTS (
		SELECT 1
		FROM #tblShiftDetector sd
		WHERE s.EmployeeId = sd.EmployeeID AND s.Scheduledate = sd.Scheduledate
		)

-- tam thoi lay ca HC dua vao tao lich
INSERT INTO tblWSchedule (EmployeeID, ScheduleDate, ShiftID, HolidayStatus)
SELECT d.EmployeeID, d.ScheduleDate, s.ShiftID, d.HolidayStatus
FROM #tblShiftDetector d
INNER JOIN (
	SELECT TOP 1 *
	FROM #tblShiftSetting s
	WHERE EXISTS (
			SELECT 1
			FROM #tblShiftDetector d
			WHERE s.ShiftCode = d.ShiftCode
			) AND abs(s.WorkStartMi - 480) < 121
	ORDER BY abs(s.WorkStartMi - 480)
	) s ON d.ShiftCode = s.ShiftCode
WHERE NOT EXISTS (
		SELECT 1
		FROM tblWSchedule ws
		WHERE d.EmployeeId = ws.EmployeeID AND d.ScheduleDate = ws.ScheduleDate
		)

IF (OBJECT_ID('sp_ShiftDetector_FinishCustomizeListShiftCode') IS NULL)
BEGIN
	EXEC (
			'CREATE PROCEDURE dbo.sp_ShiftDetector_FinishCustomizeListShiftCode
(
 @StopUpdate bit output
 ,@LoginID int
 ,@FromDate datetime
 ,@ToDate datetime
)
as
begin
 SET NOCOUNT ON;
end'
			)
END

SET @StopUpdate = 0

EXEC sp_ShiftDetector_FinishCustomizeListShiftCode @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

-- *XAC DINH CA CHINH XAC2
-- da dc nguoi dung duyet, hoac tao lich manual
--delete #tblShiftDetectorMatched from #tblShiftDetectorMatched m where not exists (select 1 from #tblEmployeeList te where te.EmployeeID = m.EmployeeId and te.NotCheckTA = 1)
TRUNCATE TABLE #tblShiftDetectorMatched

INSERT INTO #tblShiftDetectorMatched (EmployeeId, ScheduleDate, ShiftCode, RatioMatch, WorkStart, WorkEnd, BreakStart, BreakEnd, OTBeforeStart, OTBeforeEnd, OTAfterStart, OTAfterEnd, HolidayStatus, Approved, EmployeeStatusID)
SELECT ws.EmployeeID, ws.ScheduleDate, ws.ShiftCode, 1000, dateadd(mi, ss.WorkStartMi, ws.ScheduleDate), dateadd(mi, ss.WorkEndMi, ws.ScheduleDate), dateadd(mi, ss.BreakStartMi, ws.ScheduleDate), dateadd(mi, ss.BreakEndMi, ws.ScheduleDate), dateadd(mi, ss.OTBeforeStartMi, ws.ScheduleDate), dateadd(mi, ss.OTBeforeEndMi, ws.ScheduleDate), dateadd(mi, ss.OTAfterStartMi, ws.ScheduleDate), dateadd(mi, ss.OTAfterEndMi, ws.ScheduleDate), ws.HolidayStatus, ws.Approved, p.EmployeeStatusID --,e.WHPerWeek
FROM #tblWSchedule ws
INNER JOIN #tblPendingImportAttend p ON ws.EmployeeID = p.EmployeeID AND ws.ScheduleDate = p.DATE
LEFT JOIN #tblShiftSetting ss ON ws.ShiftCode = ss.ShiftCode
WHERE (
		(ws.Approved = 1)
		--người dùng đã xác nhận giờ vào và giờ ra của ngày hôm dó, và hôm đó chỉ có 1 period
		OR EXISTS (
			SELECT 1
			FROM (
				SELECT EmployeeID, Attdate
				FROM #tblHasTA
				WHERE TAStatus = 3 AND AttStart IS NULL AND AttEnd IS NULL
				GROUP BY EmployeeID, Attdate
				HAVING COUNT(1) = 1
				) tmp
			WHERE ws.employeeID = tmp.EmployeeID AND tmp.Attdate = ws.ScheduleDate
			)
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblWorking2ShiftADay_Detect ts
		WHERE ts.EmployeeID = ws.EmployeeId AND ts.ScheduleDate = ws.ScheduleDate
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblLvHistory lv
		WHERE lv.EmployeeID = ws.EmployeeId AND lv.LeaveDate = ws.ScheduleDate AND lv.LeaveStatus = 3 AND @LEAVEFULLDAYSTILLHASATTTIME = 0
		)

DELETE D
FROM #tblShiftDetector D
WHERE EXISTS (
		SELECT 1
		FROM #tblShiftDetectorMatched M
		WHERE M.EmployeeId = D.EmployeeId AND M.ScheduleDate = D.ScheduleDate
		)

-- chỉ có 1 ca duy nhất
INSERT INTO #tblShiftDetectorMatched (EmployeeId, ScheduleDate, ShiftCode, RatioMatch, HolidayStatus, WorkStart, WorkEnd, BreakStart, BreakEnd, OTBeforeStart, OTBeforeEnd, OTAfterStart, OTAfterEnd, Approved, EmployeeStatusID)
SELECT d.EmployeeId, d.ScheduleDate, d.ShiftCode, d.RatioMatch, d.HolidayStatus, dateadd(mi, ss.WorkStartMi, d.ScheduleDate), dateadd(mi, ss.WorkEndMi, d.ScheduleDate), dateadd(mi, ss.BreakStartMi, d.ScheduleDate), dateadd(mi, ss.BreakEndMi, d.ScheduleDate), dateadd(mi, ss.OTBeforeStartMi, d.ScheduleDate), dateadd(mi, ss.OTBeforeEndMi, d.ScheduleDate), dateadd(mi, ss.OTAfterStartMi, d.ScheduleDate), dateadd(mi, ss.OTAfterEndMi, d.ScheduleDate), 1, d.EmployeeStatusID
FROM #tblShiftDetector d
INNER JOIN #tblShiftSetting ss ON d.ShiftCode = ss.ShiftCode
WHERE EXISTS (
		SELECT 1
		FROM (
			SELECT EmployeeId, ScheduleDate
			FROM #tblShiftDetector
			GROUP BY EmployeeId, ScheduleDate
			HAVING COUNT(1) = 1
			) tmp
		WHERE tmp.EmployeeId = d.EmployeeId AND tmp.ScheduleDate = d.ScheduleDate
		)

-- nhan vien khong can cham cong thi lay mac dinh la ca HC
UPDATE m
SET ShiftCode = ss.ShiftCode
--Select ss.*, m.*
FROM #tblShiftDetectorMatched m
INNER JOIN #tblShiftGroupCode d ON m.EmployeeId = d.EmployeeId AND m.ScheduleDate BETWEEN d.FromDate AND d.ToDate
INNER JOIN #tblShiftGroup_Shift ss ON d.ShiftGroupCode = ss.ShiftGroupID
WHERE EXISTS (
		SELECT 1
		FROM #tblShiftSetting s
		WHERE s.ShiftCode = ss.ShiftCode AND s.isOfficalShift = 1 AND s.WorkStartMi = 480 AND s.WorkEndMi = 1020
		) AND ISNULL(m.Approved, 0) = 0

UPDATE m
SET ShiftCode = ss.ShiftCode
FROM #tblShiftDetectorMatched m
INNER JOIN #tblShiftGroupCode d ON m.EmployeeId = d.EmployeeId AND m.ScheduleDate BETWEEN d.FromDate AND d.ToDate
INNER JOIN #tblShiftGroup_Shift ss ON d.ShiftGroupCode = ss.ShiftGroupID
WHERE m.ShiftCode IS NULL AND EXISTS (
		SELECT 1
		FROM #tblShiftSetting s
		WHERE s.ShiftCode = ss.ShiftCode AND s.isOfficalShift = 1 AND s.WorkStartMi = 480
		)

UPDATE m
SET ShiftCode = ss.ShiftCode
FROM #tblShiftDetectorMatched m
INNER JOIN #tblShiftGroupCode d ON m.EmployeeId = d.EmployeeId AND m.ScheduleDate BETWEEN d.FromDate AND d.ToDate
INNER JOIN #tblShiftGroup_Shift ss ON d.ShiftGroupCode = ss.ShiftGroupID
WHERE m.ShiftCode IS NULL AND EXISTS (
		SELECT 1
		FROM #tblShiftSetting s
		WHERE s.ShiftCode = ss.ShiftCode AND s.isOfficalShift = 1 AND abs(s.WorkStartMi - 480) < 31
		)

UPDATE m
SET ShiftCode = ss.ShiftCode
FROM #tblShiftDetectorMatched m
INNER JOIN #tblShiftGroupCode d ON m.EmployeeId = d.EmployeeId AND m.ScheduleDate BETWEEN d.FromDate AND d.ToDate
INNER JOIN #tblShiftGroup_Shift ss ON d.ShiftGroupCode = ss.ShiftGroupID
WHERE m.ShiftCode IS NULL AND EXISTS (
		SELECT 1
		FROM #tblShiftSetting s
		WHERE s.ShiftCode = ss.ShiftCode AND s.isOfficalShift = 1 AND abs(s.WorkStartMi - 480) < 61
		)

UPDATE m
SET ShiftCode = ss.ShiftCode
FROM #tblShiftDetectorMatched m
INNER JOIN #tblShiftGroupCode d ON m.EmployeeId = d.EmployeeId AND m.ScheduleDate BETWEEN d.FromDate AND d.ToDate
INNER JOIN #tblShiftGroup_Shift ss ON d.ShiftGroupCode = ss.ShiftGroupID
WHERE m.ShiftCode IS NULL AND EXISTS (
		SELECT 1
		FROM #tblShiftSetting s
		WHERE s.ShiftCode = ss.ShiftCode
		)

--Select * from #tblShiftSetting s where exists (select 1 from #tblShiftGroup_Shift ss inner join #tblShiftGroupCode d on d.ShiftGroupCode = ss.ShiftGroupID where ss.ShiftCode = s.ShiftCode)
IF (OBJECT_ID('sp_ShiftDetector_MatchedShift_Process') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_MatchedShift_Process(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime) as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_MatchedShift_Process @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

IF @StopUpdate = 0
BEGIN
	UPDATE #tblShiftDetectorMatched
	SET TIMEINBEFORE = DATEADD(MI, - @TA_TIMEINBEFORE, WorkStart), TIMEOUTAFTER = DATEADD(hour, @TA_TIMEOUTAFTER, WorkStart), INOUT_MINIMUM = @TA_INOUT_MINIMUM

	-- loại bỏ những nhân viên lấy giờ hôm trước làm giờ vào hôm nay
	DELETE m2
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1 AND m1.AttEnd = m2.AttStart

	DELETE D
	FROM #tblShiftDetector D
	WHERE EXISTS (
			SELECT 1
			FROM #tblShiftDetectorMatched M
			WHERE M.EmployeeId = D.EmployeeId AND M.ScheduleDate = D.ScheduleDate
			)

	DECLARE @Max_WorkingHour_PerDay INT

	SELECT @Max_WorkingHour_PerDay = ISNULL((
				SELECT Value
				FROM tblParameter
				WHERE Code = 'Max_WorkingHour_PerDay'
				), 24)

	IF @Max_WorkingHour_PerDay < 4
	BEGIN
		SET @Max_WorkingHour_PerDay = 9

		UPDATE tblParameter
		SET Value = '9'
		WHERE Code = 'Max_WorkingHour_PerDay'
	END

	-- XÁC ĐỊNH GIỜ VÀO RA CHO CA CHÍNH XÁC
	-- fixed att
	UPDATE #tblShiftDetectorMatched
	SET FixedAtt = 0

	--update m1 set FixedAtt = 1 from #tblShiftDetectorMatched m1 inner join #tblWSchedule m2 on m1.EmployeeId = m2.EmployeeId and m1.ScheduleDate = m2.ScheduleDate
	-- where m2.DateStatus = 3
	UPDATE m
	SET AttStart = ta.AttStart, StateIn = 1
	FROM #tblShiftDetectorMatched M
	INNER JOIN #tblHasTA TA ON M.EmployeeId = ta.EmployeeID AND m.ScheduleDate = ta.AttDate
	WHERE (ta.TAStatus = 1)

	UPDATE m
	SET AttEnd = ta.AttEnd, StateOut = 2
	FROM #tblShiftDetectorMatched M
	INNER JOIN #tblHasTA TA ON M.EmployeeId = ta.EmployeeID AND m.ScheduleDate = ta.AttDate
	WHERE (ta.TAStatus = 2)

	UPDATE m
	SET AttStart = ta.AttStart, AttEnd = ta.AttEnd, FixedAtt = 1
	FROM #tblShiftDetectorMatched M
	INNER JOIN (
		SELECT EmployeeID, AttDate, max(TAStatus) TAStatus, Min(AttStart) AttStart, Max(AttEnd) AttEnd
		FROM #tblHasTA
		GROUP BY EmployeeID, AttDate
		) TA ON M.EmployeeId = ta.EmployeeID AND m.ScheduleDate = ta.AttDate
	WHERE (ta.TAStatus = 3)

	--phang tới tấp qua ben kia luôn, người dùng sửa giờ rồi mà
	UPDATE m
	SET AttStart = ta.AttStart, AttEnd = ta.AttEnd, FixedAtt = 1, StateIn = 1, StateOut = 2
	FROM #tblShiftDetector M
	INNER JOIN (
		SELECT EmployeeID, AttDate, max(TAStatus) TAStatus, Min(AttStart) AttStart, Max(AttEnd) AttEnd
		FROM #tblHasTA
		GROUP BY EmployeeID, AttDate
		) TA ON M.EmployeeId = ta.EmployeeID AND m.ScheduleDate = ta.AttDate
	WHERE (ta.TAStatus = 3)

	UPDATE #tblShiftDetectorMatched
	SET IsLeaveStatus3 = 0

	UPDATE ta1
	SET IsLeaveStatus3 = 1
	FROM #tblShiftDetectorMatched ta1
	INNER JOIN #tblLvHistory ta2 ON ta1.EmployeeId = ta2.EmployeeID AND ta1.ScheduleDate = ta2.LeaveDate AND LeaveStatus = 3

	-- AttEnd Yesterday cho bang Matched
	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, m2.WorkEnd)
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate + 1
	WHERE (m2.AttEnd IS NOT NULL OR (m2.WorkEnd IS NOT NULL AND DATEDIFF(MI, m2.WorkStart, m2.WorkEnd) < 600)) AND m2.Approved = 1

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, m2.WorkStart)
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
	WHERE (m2.AttStart IS NOT NULL OR m2.WorkStart IS NOT NULL) AND m2.Approved = 1

	-- trong bảng HasTA
	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, dateadd(HOUR, - 10, m1.WorkStart))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblHasTA m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m2.AttEnd IS NOT NULL AND (m2.AttStart IS NOT NULL OR DATEDIFF(MI, m2.WorkStart, m2.WorkEnd) < 500) AND (m2.TAStatus = 3 OR m2.AttDate BETWEEN @FromDate3 AND @FromDate)

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblHasTA m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.PrevDate
	WHERE m2.AttStart IS NOT NULL AND (m2.TAStatus = 3)

	-- xac dinh gio vao ra do hom qua và ngày mai dã được  fix cố định chưa
	UPDATE m1
	SET AttEndYesterdayFixed = 1
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m2.DateStatus = 3

	UPDATE m1
	SET AttStartTomorrowFixed = 1
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.PrevDate
	WHERE m2.DateStatus = 3

	UPDATE #tblShiftDetectorMatched
	SET AttEndYesterday = dateadd(HOUR, - 10, WorkStart)
	WHERE AttEndYesterday IS NULL

	UPDATE #tblShiftDetectorMatched
	SET AttStartTomorrow = DATEADD(hour, 16, WorkEnd)
	WHERE AttStartTomorrow IS NULL

	-- trong bảng HasTA
	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, dateadd(HOUR, - 10, m1.WorkStart))
	FROM #tblShiftDetector m1
	INNER JOIN #tblHasTA m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m2.AttEnd IS NOT NULL AND (m2.TAStatus = 3) -- or m2.AttDate between @FromDate3 and @FromDate)
		--where m2.AttEnd is not null and (m2.TAStatus = 3 or m2.AttDate between @FromDate3 and @FromDate)
		-- xac dinh gio vao ra do hom qua và ngày mai dã được fix cố định chưa

	UPDATE m1
	SET AttEndYesterdayFixed = 1
	FROM #tblShiftDetector m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m2.DateStatus = 3

	UPDATE m1
	SET AttStartTomorrowFixed = 1
	FROM #tblShiftDetector m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.PrevDate
	WHERE m2.DateStatus = 3

	-- xác định AttStart cho #tblShiftDetectorMatched
	-- 1. gà què an quanh cối xay
	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, MIN(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND FixedAtt = 0 AND (ForceState = 0 OR AttState = 1) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND abs(DATEDIFF(mi, m.WorkStart, t.AttTime)) <= 15
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND FixedAtt = 0 AND (ForceState = 0 OR AttState = 1) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND DATEDIFF(mi, m.WorkStart, t.AttTime) BETWEEN - 150 AND - 1
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, MIN(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND FixedAtt = 0 AND (ForceState = 0 OR AttState = 1) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND abs(DATEDIFF(mi, m.WorkStart, t.AttTime)) <= 60
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND FixedAtt = 0 AND (ForceState = 0 OR AttState = 1) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND DATEDIFF(mi, m.WorkStart, t.AttTime) BETWEEN - 330 AND - 1
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	-- lay dc gio vao roi thi do nguoc lai xem co ai cham som hon ko
	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, min(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NOT NULL AND FixedAtt = 0 AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (ForceState = 0 OR AttState = 1) AND t.AttTime BETWEEN DATEADD(mi, - 60, m.AttStart) AND m.AttStart AND DATEDIFF(mi, m.WorkStart, t.AttTime) BETWEEN - 330 AND - 1
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, MIN(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND FixedAtt = 0 AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (ForceState = 0 OR AttState = 1) AND DATEDIFF(mi, m.WorkStart, t.AttTime) BETWEEN 0 AND 330
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	/*
 AttEnd cho #tblShiftDetectorMatched */
	--1. ga que an quan coi xay
	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.FixedAtt = 0 AND (t.ForceState = 0 OR t.AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND abs(DATEDIFF(mi, m.WorkEnd, t.AttTime)) <= 60 AND (t.AttTime > m.AttStart OR (m.AttStart IS NULL AND t.AttTime > m.WorkStart))
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	--1. xu ly truong hop bam nham, sau do hon 1h moi ra ve
	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd < m.WorkEnd AND m.FixedAtt = 0 AND (t.ForceState = 0 OR t.AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND DATEDIFF(mi, m.WorkEnd, t.AttTime) <= 120 AND (t.AttTime > m.AttStart OR (m.AttStart IS NULL AND t.AttTime > m.WorkStart))
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	-- riêng với những người thuộc bộ phận bảo vệ làm 24h/ngày
	UPDATE m
	SET AttStartTomorrow = dateadd(MI, 60, AttStartTomorrow)
	FROM #tblShiftDetectorMatched m
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployeeList e
			WHERE m.EmployeeId = e.EmployeeID AND e.Security24hWorking = 1
			)

	UPDATE m
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, min(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND FixedAtt = 0 AND (ForceState = 0 OR AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND abs(DATEDIFF(mi, m.WorkEnd, t.AttTime)) <= 60 AND (t.AttTime > m.AttStart OR (m.AttStart IS NULL AND t.AttTime > m.WorkStart))
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate
	WHERE EXISTS (
			SELECT 1
			FROM #tblEmployeeList e
			WHERE m.EmployeeId = e.EmployeeID AND e.Security24hWorking = 1
			)

	-- nhân viên làm 24h một ngày (bao ve di 24h ngay), làm 1 ngay nghi 1 ngay, vì thế bỏ những ngày kế tiếp
	UPDATE m2
	SET AttStart = NULL, AttEnd = NULL
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1 AND (m1.AttEnd = m2.AttStart OR (m1.AttStart IS NOT NULL AND m1.AttEnd IS NOT NULL))
	WHERE m1.AttStart IS NOT NULL AND m1.AttEnd IS NOT NULL AND (m2.AttStart IS NULL OR m2.AttEnd IS NULL) AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList e
			WHERE m2.EmployeeId = e.EmployeeID AND e.Security24hWorking = 1
			)

	SELECT ROW_NUMBER() OVER (
			PARTITION BY datediff(day, m1.ScheduleDate, m2.ScheduleDate) ORDER BY m2.employeeID
			) AS STT, m2.EmployeeId, m2.ScheduleDate, m2.ShiftCode, m2.AttStart, m2.AttEnd
	INTO #Security24hWorkingNeedDelete
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1 AND m1.AttEnd = m2.AttStart
	WHERE m2.AttStart IS NOT NULL AND m2.AttEnd IS NOT NULL AND m1.AttStart IS NOT NULL AND m1.AttEnd IS NOT NULL AND EXISTS (
			SELECT 1
			FROM #tblEmployeeList e
			WHERE m2.EmployeeId = e.EmployeeID AND e.Security24hWorking = 1
			)

	DELETE #Security24hWorkingNeedDelete
	WHERE STT % 2 = 0

	UPDATE m
	SET AttStart = NULL, AttEnd = NULL
	FROM #Security24hWorkingNeedDelete d1
	INNER JOIN #tblShiftDetectorMatched m ON d1.EmployeeId = m.EmployeeId AND d1.ScheduleDate = m.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND AttStart IS NOT NULL AND FixedAtt = 0 AND (ForceState = 0 OR AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND abs(DATEDIFF(mi, m.WorkEnd, t.AttTime)) <= 330 AND (t.AttTime > m.AttStart OR (m.AttStart IS NULL AND t.AttTime > m.WorkStart))
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, m2.WorkEnd)
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate + 1
	WHERE (m2.AttEnd IS NOT NULL OR m2.WorkEnd IS NOT NULL) AND m2.Approved = 1

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, m2.WorkStart)
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
	WHERE (m2.AttStart IS NOT NULL OR m2.WorkStart IS NOT NULL) AND m2.Approved = 1

	-- 2. Ðói thì di làm an xa
	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, MIN(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE (m.AttStart IS NULL) AND FixedAtt = 0 --or DATEDIFF(mi,t.AttTime,m.WorkEnd) >= 30
			AND (ForceState = 0 OR AttState = 1) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND (t.AttTime < dateadd(mi, - 1 * m.INOUT_MINIMUM, m.AttEnd) OR (m.AttEnd IS NULL AND t.AttTime < m.WorkEnd)) AND t.AttTime BETWEEN m.TimeinBefore AND m.TIMEOUTAFTER
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, m2.WorkStart)
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
	WHERE (m2.AttStart IS NOT NULL OR m2.WorkStart IS NOT NULL) AND m2.Approved = 1

	-- 2. Ðói thì di làm an xa
	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND FixedAtt = 0 AND ((ForceState = 0 AND (datediff(day, t.Atttime, WorkEnd) = 0 OR datediff(hour, t.AttTime, TIMEOUTAFTER) > 3)) OR AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > isnull(m.AttStart, m.WorkStart)
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	-- có đi làm, tăng ca trước giờ làm, sau đó nghỉ cả ngày: để bắt được giờ vào ra để tính tăng ca
	UPDATE #tblShiftDetectorMatched
	SET AttEnd = m.AttStart, AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, min(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND FixedAtt = 0 AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.WorkEnd AND t.AttTime < m.AttStart AND t.AttTime BETWEEN m.OTBeforeStart AND m.OTBeforeEnd AND DATEDIFF(mi, t.AttTime, m.AttStart) >= 50
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND @OTBEFORE_LEAVE_FULLDAY = 1

	-- quên bấm 1 đàu và AttStart dang trùng AttEnd thì xác định lại cho dúng anh nào vào anh nào ra
	-- trường hợp nhân viên sửa lại giờ vào ra, nen bi du thua attTime
	UPDATE #tblShiftDetectorMatched
	SET AttStart = CASE 
			WHEN DATEDIFF(mi, WorkStart, AttStart) < 240 AND (isnull(AttEndYesterdayFixed, 0) = 0 OR DATEDIFF(mi, AttEndYesterday, AttStart) > 120)
				THEN AttStart
			ELSE NULL
			END, AttEnd = CASE 
			WHEN DATEDIFF(mi, WorkEnd, AttEnd) >= - 240 AND (isnull(AttStartTomorrowFixed, 0) = 0 OR DATEDIFF(mi, AttStartTomorrow, AttStart) < 120)
				THEN AttEnd
			ELSE NULL
			END
	FROM #tblShiftDetectorMatched
	WHERE AttStart = AttEnd --and EmployeeId = 'HLS001'

	/*-- nghỉ cả ngày mà bấm thiếu đầu thì bỏ
update m set AttStart = null, AttEnd = null
from #tblShiftDetectorMatched m where ((m.AttStart is not null and m.AttEnd is null ) or (m.AttStart is null and m.AttEnd is not null))
and (IsLeaveStatus3 =1 -- nghi ca ngay
or (DATEDIFF(DAY,m.WorkStart, m.WorkEnd) > 0 and m.AttStart is null and exists (select 1 from #tblShiftDetectorMatched m2 where m.EmployeeId = m2.EmployeeId and m.ScheduleDate + 1 = m2.ScheduleDate and DATEDIFF(DAY,m2.WorkStart, m2.WorkEnd) = 0)) -- ca đêm dài, ngày đó nghỉ để xoay sang ca ngay
)
and FixedAtt =0
*/
	UPDATE m
	SET AttEnd = NULL
	FROM #tblShiftDetectorMatched m
	WHERE DATEDIFF(DAY, m.WorkStart, m.WorkEnd) > 0 AND m.AttStart IS NULL AND m.AttEnd IS NOT NULL AND EXISTS (
			SELECT 1
			FROM #tblHasTA ta
			INNER JOIN #tblShiftSetting ss ON ta.ShiftCode = ss.ShiftCode AND ss.WorkEndMi < 1440
			WHERE ta.EmployeeID = m.EmployeeId AND m.ScheduleDate + 1 = ta.Attdate
			)
END

-- tinh workingTime cho bang dang duyet
UPDATE ws
SET WorkStart = dateadd(mi, ss.WorkStartMi, ws.ScheduleDate), WorkEnd = dateadd(mi, ss.WorkEndMi, ws.ScheduleDate), BreakStart = dateadd(mi, ss.BreakStartMi, ws.ScheduleDate), BreakEnd = dateadd(mi, ss.BreakEndMi, ws.ScheduleDate), isNightShift = CASE 
		WHEN ss.WorkEndMi > 1440 OR ss.WorkStartMi < 130
			THEN 1
		ELSE 0
		END, isOfficalShift = ISNULL(ss.isOfficalShift, 0), WorkStartMi = ss.WorkStartMi, WorkEndMi = ss.WorkEndMi, BreakStartMi = ss.BreakStartMi, BreakEndMi = ss.BreakEndMi
FROM #tblShiftDetectorMatched ws
INNER JOIN #tblShiftSetting ss ON ws.ShiftCode = ss.ShiftCode

UPDATE #tblShiftDetectorMatched
SET AttStartMi = datepart(hour, AttStart) * 60 + DATEPART(minute, AttStart), AttEndMi = datepart(hour, AttEnd) * 60 + DATEPART(minute, AttEnd)

UPDATE #tblShiftDetectorMatched
SET AttEndMi = 1440 + AttEndMi
WHERE DATEDIFF(day, ScheduleDate, AttEnd) = 1

IF (@AUTO_FILL_TIMEINOUT_FWC = 1)
BEGIN
	UPDATE ta1
	SET AttStartMi = CASE 
			WHEN AttStartMi IS NULL AND ta2.LeaveStatus IN (1, 3, 4)
				THEN ta1.WorkStartMi
			ELSE AttStartMi
			END, AttEndMi = CASE 
			WHEN AttEndMi IS NULL AND ta2.LeaveStatus IN (2, 3, 5)
				THEN ta1.workendMi
			ELSE AttEndMi
			END
	FROM #tblShiftDetectorMatched ta1
	INNER JOIN #tblFWC ta2 ON ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate = ta2.LeaveDAte
END

IF @MATERNITY_LATE_EARLY_OPTION = 1
	UPDATE #tblShiftDetectorMatched
	SET AttStartMi = CASE 
			WHEN AttStartMi > WorkStartMi
				THEN CASE 
						WHEN AttStartMi - WorkStartMi <= 30
							THEN WorkStartMi
						ELSE AttStartMi - @MATERNITY_MUNITE
						END
			ELSE AttStartMi
			END
	FROM #tblShiftDetectorMatched ta1
	WHERE EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL
ELSE IF @MATERNITY_LATE_EARLY_OPTION = 2
	UPDATE #tblShiftDetectorMatched
	SET AttEndMi = CASE 
			WHEN AttEndMi < WorkEndMi
				THEN CASE 
						WHEN WorkEndMi - AttStartMi <= 30
							THEN WorkEndMi
						ELSE AttEndMi + @MATERNITY_MUNITE
						END
			ELSE AttEndMi
			END
	FROM #tblShiftDetectorMatched ta1
	WHERE EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL
ELSE IF @MATERNITY_LATE_EARLY_OPTION = 3
	UPDATE #tblShiftDetectorMatched
	SET AttEndMi = CASE 
			WHEN WorkEndMi - AttEndMi >= AttStartMi - WorkStartMi AND AttEndMi < WorkEndMi
				THEN CASE 
						WHEN WorkEndMi - AttStartMi <= 30
							THEN WorkEndMi
						ELSE AttEndMi + @MATERNITY_MUNITE
						END
			ELSE AttEndMi
			END, AttStartMi = CASE 
			WHEN WorkEndMi - AttEndMi < AttStartMi - WorkStartMi AND AttStartMi > WorkStartMi
				THEN CASE 
						WHEN AttStartMi - WorkStartMi <= 30
							THEN WorkStartMi
						ELSE AttStartMi - @MATERNITY_MUNITE
						END
			ELSE AttStartMi
			END
	FROM #tblShiftDetectorMatched ta1
	WHERE EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

-- UPDATE LATE_PERMIT AND EARLY_PERMIT
UPDATE sd
SET sd.Late_Permit = COALESCE(p.LATE_PERMIT, sc.LATE_PERMIT, dp.LATE_PERMIT, d.LATE_PERMIT), sd.Early_Permit = COALESCE(p.Early_Permit, sc.Early_Permit, dp.Early_Permit, d.Early_Permit)
FROM #tblShiftDetectorMatched sd
LEFT JOIN #tblEmployeeList s ON s.EmployeeID = sd.EmployeeId
LEFT JOIN tblDivision d ON d.DivisionID = s.DivisionID
LEFT JOIN tblDepartment dp ON dp.DepartmentID = s.DepartmentID
LEFT JOIN tblSection sc ON sc.SectionID = s.SectionID
LEFT JOIN tblPosition p ON p.PositionID = s.PositionID

--update sd set AttStartMi = case when AttStartMi < WorkEndMi + Late_Permit then WorkEndMi else AttStartMi end from #tblShiftDetectorMatched sd
UPDATE sd
SET AttStartMi = CASE 
		WHEN AttStartMi BETWEEN WorkStartMi AND WorkStartMi + Late_Permit
			THEN WorkStartMi
		ELSE AttStartMi
		END, AttEndMi = CASE 
		WHEN AttEndMi BETWEEN WorkEndMi - Early_Permit AND WorkEndMi
			THEN WorkEndMi
		ELSE AttEndMi
		END
FROM #tblShiftDetectorMatched sd

UPDATE #tblShiftDetectorMatched
SET WorkingTimeMi = CASE 
		WHEN AttEndMi >= WorkEndMi
			THEN WorkEndMi
		WHEN AttEndMi >= BreakEndMi
			THEN AttEndMi
		WHEN AttEndMi >= BreakStartMi
			THEN BreakStartMi
		WHEN AttEndMi >= WorkStartMi
			THEN AttEndMi
		ELSE WorkStartMi
		END - CASE 
		WHEN AttStartMi <= WorkStartMi
			THEN WorkStartMi
		WHEN AttStartMi < BreakStartMi
			THEN AttStartMi
		WHEN AttStartMi <= BreakEndMi
			THEN BreakEndMi
		WHEN AttStartMi <= WorkEndMi
			THEN AttStartMi
		ELSE WorkEndMi
		END, StdWorkingTimeMi = WorkEndMi - WorkStartMi - (BreakEndMi - BreakStartMi)
WHERE AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

UPDATE m
SET StdWorkingTimeMi = StdWorkingTimeMi - lv.LvAmount * 60.0
FROM #tblShiftDetectorMatched m
INNER JOIN (
	SELECT EmployeeID, LeaveDate, sum(LvAmount) LvAmount
	FROM #tblLvHistory
	WHERE PaidRate > 0 AND LeaveCategory = 1
	GROUP BY EmployeeID, LeaveDate
	) lv ON lv.EmployeeID = m.EmployeeId AND m.ScheduleDate = lv.LeaveDate
WHERE StdWorkingTimeMi IS NOT NULL AND m.IsLeaveStatus3 <> 1

UPDATE #tblShiftDetectorMatched
SET StdWorkingTimeMi = 480
WHERE StdWorkingTimeMi <= 0

UPDATE #tblShiftDetectorMatched
SET WorkingTimeMi = WorkingTimeMi - (BreakEndMi - BreakStartMi)
WHERE BreakStartMi < BreakEndMi AND AttStartMi < BreakStartMi AND AttEndMi > BreakEndMi AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

IF @MATERNITY_LATE_EARLY_OPTION = 0
	UPDATE #tblShiftDetectorMatched
	SET WorkingTimeMi = CASE 
			WHEN WorkingTimeMi + @MATERNITY_MUNITE >= StdWorkingTimeMi
				THEN StdWorkingTimeMi
			ELSE WorkingTimeMi + @MATERNITY_MUNITE
			END
	FROM #tblShiftDetectorMatched d
	WHERE d.EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

UPDATE #tblShiftDetectorMatched
SET WorkingTimeMi = StdWorkingTimeMi
WHERE WorkingTimeMi >= StdWorkingTimeMi

--VŨ: không hiểu tác dụng đoạn này và nó gây lỗi nên tạm thời ẩn đi
--UPDATE ta1 set WorkingTimeMi = cast(WorkingTimeMi as float) / ta1.StdWorkingTimeMi * (ta2.STDWorkingTime_SS -isnull(lv.LvAmount*60.0,0))
--from #tblShiftDetectorMatched ta1
--inner join #tblShiftSetting ta2 on ta1.ShiftCode = ta2.ShiftCode
-- and ta1.StdWorkingTimeMi <> ta2.STDWorkingTime_SS
-- and ta1.Workingtimemi >0
--left join (select EmployeeID,LeaveDate, sum(LvAmount) LvAmount
--from #tblLvHistory where LeaveCategory = 1 group by EmployeeID,LeaveDate) lv on lv.EmployeeID = ta1.EmployeeId and ta1.ScheduleDate = lv.LeaveDate
--where StdWorkingTimeMi is not null and ta1.IsLeaveStatus3 <> 1
-- thiếu vào hoặc ra mà giờ vào hoặc ra quá cách xa so với bắt đầu-kết thúc của ca
-- Hoa thom toa huong xa
SELECT EmployeeID, ScheduleDate, ScheduleDate + 1 AS FromDate, ScheduleDate + 7 AS ToDate, ShiftCode, ROW_NUMBER() OVER (
		PARTITION BY EmployeeID ORDER BY EmployeeId, ScheduleDate
		) STT, RatioMatch
INTO #tblBloomFlavour
FROM #tblShiftDetectorMatched
WHERE Approved = 1

UPDATE b1
SET ToDate = b2.ScheduleDate - 1
FROM #tblBloomFlavour b1
INNER JOIN #tblBloomFlavour b2 ON b1.EmployeeId = b2.EmployeeId AND b1.STT = b2.STT - 1
WHERE b1.ToDate > b1.FromDate

INSERT INTO #tblShiftDetectorMatched (EmployeeId, ScheduleDate, ShiftCode, RatioMatch, WorkStart, WorkEnd, BreakStart, BreakEnd, OTBeforeStart, OTBeforeEnd, OTAfterStart, OTAfterEnd, HolidayStatus, Approved, AttStart, AttEnd)
SELECT p.EmployeeID, p.ScheduleDate, p.ShiftCode1, 10000, dateadd(mi, ss.WorkStartMi, p.ScheduleDate), dateadd(mi, ss.WorkEndMi, p.ScheduleDate), dateadd(mi, ss.BreakStartMi, p.ScheduleDate), dateadd(mi, ss.BreakEndMi, p.ScheduleDate), dateadd(mi, ss.OTBeforeStartMi, p.ScheduleDate), dateadd(mi, ss.OTBeforeEndMi, p.ScheduleDate), dateadd(mi, ss.OTAfterStartMi, p.ScheduleDate), dateadd(mi, ss.OTAfterEndMi, p.ScheduleDate), ws.HolidayStatus, ws.Approved, p.AttStart1, p.AttEnd2
FROM #tblWSchedule ws
INNER JOIN #tblWorking2ShiftADay_Detect p ON ws.EmployeeID = p.EmployeeID AND ws.ScheduleDate = p.ScheduleDate
LEFT JOIN #tblShiftSetting ss ON ws.ShiftCode = ss.ShiftCode
WHERE NOT EXISTS (
		SELECT 1
		FROM #tblShiftDetectorMatched m
		WHERE m.EmployeeID = ws.EmployeeId AND m.ScheduleDate = ws.ScheduleDate
		)

DELETE D
FROM #tblShiftDetector D
WHERE EXISTS (
		SELECT 1
		FROM #tblShiftDetectorMatched M
		WHERE M.EmployeeId = D.EmployeeId AND M.ScheduleDate = D.ScheduleDate
		)

--select * from  #tblShiftDetectorMatched order by EmployeeId, ScheduleDate, ShiftCode return
-------------------------------------Bắt đầu nhận dạng ca--------------------------------------------
BEGIN -- bat dau nhan dang ca
	SELECT *
	INTO #tblShiftDetector_NeedUpdate
	FROM #tblShiftDetector
	WHERE 1 = 0

	--create nonclustered index indextblShiftDetector_NeedUpdate on #tblShiftDetector_NeedUpdate(EmployeeID,ScheduleDate,AttStart,AttEnd)
	StartShiftDetector:

	-- AttStart, AttEnd
	UPDATE ws
	SET WorkStart = dateadd(mi, ss.WorkStartMi, ws.ScheduleDate), WorkEnd = dateadd(mi, ss.WorkEndMi, ws.ScheduleDate), BreakStart = dateadd(mi, ss.BreakStartMi, ws.ScheduleDate), BreakEnd = dateadd(mi, ss.BreakEndMi, ws.ScheduleDate), isNightShift = CASE 
			WHEN ss.WorkEndMi > 1440 OR ss.WorkStartMi < 130
				THEN 1
			ELSE 0
			END, isOfficalShift = ISNULL(ss.isOfficalShift, 0), WorkStartMi = ss.WorkStartMi, WorkEndMi = ss.WorkEndMi, BreakStartMi = ss.BreakStartMi, BreakEndMi = ss.BreakEndMi
	FROM #tblShiftDetector ws
	INNER JOIN #tblShiftSetting ss ON ws.ShiftCode = ss.ShiftCode

	-- lấy thống kê ca dựa trên nhân viên
	UPDATE #tblShiftDetector
	SET TIMEINBEFORE = DATEADD(MINUTE, - @TA_TIMEINBEFORE, WorkStart), TIMEOUTAFTER = DATEADD(hour, CASE 
				WHEN isNightShift = 1 AND @TA_TIMEOUTAFTER > 14
					THEN 14
				ELSE @TA_TIMEOUTAFTER
				END, WorkStart), INOUT_MINIMUM = @TA_INOUT_MINIMUM

	DECLARE @RepeatTime INT = 0

	UPDATE #tblShiftDetector
	SET IsLeaveStatus3 = 0

	UPDATE ta1
	SET IsLeaveStatus3 = 1
	FROM #tblShiftDetector ta1
	INNER JOIN #tblLvHistory lv ON lv.EmployeeID = ta1.EmployeeId AND lv.LeaveDate = ta1.ScheduleDate AND lv.LeaveStatus = 3

	IF (object_id('sp_ShiftDetector_FinishTimeInTimeOutRange') IS NULL)
	BEGIN
		EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_FinishTimeInTimeOutRange(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime) as begin SET NOCOUNT ON; end')
	END

	SET @StopUpdate = 0

	-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
	EXEC sp_ShiftDetector_FinishTimeInTimeOutRange @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

	UPDATE #tblShiftDetector
	SET AttEndYesterdayFixedTblHasta = 0, AttStartTomorrowFixedTblHasta = 0

	TRUNCATE TABLE #tblPrevMatch

	INSERT INTO #tblPrevMatch (EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, Prevdate, NextDate)
	SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, DATEADD(day, - 1, ScheduleDate), DATEADD(day, 1, ScheduleDate)
	FROM #tblShiftDetectorMatched

	TRUNCATE TABLE #tblHasTA_Fixed

	TRUNCATE TABLE #tblShiftDetector_NeedUpdate

	INSERT INTO #tblHasTA_Fixed
	SELECT *
	FROM #tblHasTA
	WHERE TAStatus = 3 OR Attdate < @FromDate

	INSERT INTO #tblShiftDetector_NeedUpdate
	SELECT *
	FROM #tblShiftDetector --where IsLeaveStatus3 = 0 -- nghi ca ngay thi khong can nhan biet ca nao

	DECLARE @count INT = 0 -- (select count(1) from #tblShiftDetector_NeedUpdate)

	TRUNCATE TABLE #tblShiftDetector

	StartRepeat:

	--select * into tblShiftDetector_NeedUpdate from #tblShiftDetector_NeedUpdate
	--select * into tblPrevMatch from #tblPrevMatch
	-- gio ra hom qua va gio vao hom sau
	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, dateadd(HOUR, - 10, m1.WorkStart)), ShiftCodeYesterday = m2.ShiftCode, isNightShiftYesterday = CASE 
			WHEN m2.AttStart IS NOT NULL
				THEN m2.isNightShift
			ELSE 0
			END
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblPrevMatch m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate AND m2.IsLeaveStatus3 = 0
	WHERE m1.AttEndYesterdayFixedTblHasta <> 1 AND (m2.AttEnd IS NOT NULL OR m1.Holidaystatus > 0 OR m1.IsLeaveStatus3 = 1)

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblPrevMatch m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.Prevdate AND m2.IsLeaveStatus3 = 0
	WHERE m1.AttStartTomorrowFixedTblHasta <> 1 AND m2.AttStart IS NOT NULL

	UPDATE m1
	SET AttEndYesterday = m2.AttEnd, AttEndYesterdayFixedTblHasta = 1
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblHasTA_Fixed m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate AND m2.AttEnd IS NOT NULL
	WHERE m1.AttEndYesterdayFixedTblHasta <> 1

	UPDATE m1
	SET AttEndYesterday = m2.AttEnd
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate + 1
	WHERE m1.AttEndYesterday IS NULL AND m2.AttEnd IS NOT NULL

	UPDATE m1
	SET ShiftCodeYesterday = m2.ShiftCode
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblHasTA_Fixed m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m1.ShiftCodeYesterday IS NULL AND m2.AttStart IS NOT NULL AND m2.AttEnd IS NOT NULL

	UPDATE m1
	SET isNightShiftYesterday = m2.isNightShift
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblHasTA_Fixed m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m2.AttStart IS NOT NULL AND m2.AttEnd IS NOT NULL AND m1.ShiftCodeYesterday IS NULL --and (m2.TAStatus = 3 or m2.AttDate < @FromDate)
		-- update m1 set ShiftCodeYesterday = m2.ShiftCode from #tblShiftDetector m1 inner join #tblWSchedule m2 on m1.EmployeeId = m2.EmployeeId and m1.ScheduleDate = m2.ScheduleDate+1 where m2.DateStatus = 3
		--ca hom qua da dc duyet, hoac Nhan vien nghi ca ngay thi lay ca hom qua ap cho ca hom nay

	UPDATE m1
	SET ShiftCodeYesterday = m2.ShiftCode
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDAte
	WHERE ((m2.DateStatus = 3 OR m2.Approved = 1) OR m1.IsLeaveStatus3 = 3) AND EXISTS (
			SELECT 1
			FROM #tblHasTA ta
			WHERE ta.EmployeeID = m1.EmployeeId AND ta.NextDate = m1.ScheduleDate AND ta.AttStart IS NOT NULL AND ta.AttEnd IS NOT NULL
			)

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblHasTA m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.PrevDate
	WHERE m2.AttStart IS NOT NULL AND (m2.TAStatus = 3)

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
	WHERE m2.AttStart IS NOT NULL

	-- xac dinh gio vao ra do hom qua và ngày mai dã được fix cố định chưa
	UPDATE m1
	SET AttEndYesterdayFixed = 1
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.NextDate
	WHERE m2.DateStatus = 3

	UPDATE m1
	SET AttStartTomorrowFixed = 1
	FROM #tblShiftDetector_NeedUpdate m1
	INNER JOIN #tblWSchedule m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.PrevDate
	WHERE m2.DateStatus = 3

	UPDATE #tblShiftDetector_NeedUpdate
	SET AttEndYesterday = CASE 
			WHEN AttEndYesterday IS NULL
				THEN dateadd(HOUR, - 10, WorkStart)
			ELSE AttEndYesterday
			END, AttStartTomorrow = CASE 
			WHEN AttStartTomorrow IS NULL
				THEN DATEADD(hour, 12, WorkEnd)
			ELSE AttStartTomorrow
			END
	WHERE AttEndYesterday IS NULL OR AttStartTomorrow IS NULL

	-------------------------------------------------------------------------------------------------------------
	IF (OBJECT_ID('sp_ShiftDetector_AttStartAttEnd') IS NULL)
		EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_AttStartAttEnd ( @StopUpdate bit output ,@LoginID int ,@FromDate datetime ,@ToDate datetime ,@IN_OUT_TA_SEPARATE bit ) as begin SET NOCOUNT ON; end')

	SET @StopUpdate = 0

	EXEC sp_ShiftDetector_AttStartAttEnd @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate, @IN_OUT_TA_SEPARATE

	IF @StopUpdate = 0
	BEGIN
		--1. gà què an quanh cối xay
		-- ga que an quan coi xay
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttStart = tmp.AttTime, StateIn = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime ASC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (ForceState = 0 OR AttState = 1)
			WHERE m.AttStart IS NULL AND abs(DATEDIFF(mi, m.WorkStart, t.AttTime)) <= 60
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		-- lấy giờ vào dựa trên giờ tăng ca trước
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttStart = tmp.AttTime, StateIn = AttState, OTBeforeStart = tmp.AttTime
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime ASC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
			WHERE m.AttStart IS NULL AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (ForceState = 0 OR AttState = 1) AND abs(datediff(mi, dateadd(mi, ss.OTBeforeStartMi - ss.WorkStartMi, m.WorkStart), t.AttTime)) < 60
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode

		-- voi phan biet vao ra thi lay xa hon chut neu khop trang thai vao
		IF @IN_OUT_TA_SEPARATE = 1
		BEGIN
			UPDATE #tblShiftDetector_NeedUpdate
			SET AttStart = tmp.AttTime, StateIn = AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN (
				SELECT ROW_NUMBER() OVER (
						PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime ASC
						) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
				FROM #tblShiftDetector_NeedUpdate m
				INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID AND t.AttState = 1 AND ISNULL(m.FixedAtt, 0) = 0 AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.attTime < dateadd(hour, 2, WorkStart)
				) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

			-- 2. Ðói thì di làm an xa
			UPDATE #tblShiftDetector_NeedUpdate
			SET AttStart = tmp.AttTime, StateIn = AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN (
				SELECT ROW_NUMBER() OVER (
						PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime ASC
						) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
				FROM #tblShiftDetector_NeedUpdate m
				INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID AND t.AttState = 1 AND ISNULL(m.FixedAtt, 0) = 0 AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.attTime < WorkEnd AND DATEDIFF(mi, m.WorkStart, t.AttTime) < 600
				) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1
			WHERE AttStart IS NULL
		END

		/*print 'x--------------------------------------------------------x11'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		-- 2. Ðói thì di làm an xa
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttStart = tmp.AttTime, StateIn = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime ASC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID AND (ForceState = 0 OR AttState = 1) AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.WorkEnd AND t.attTime < WorkEnd AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND DATEDIFF(mi, m.WorkStart, t.AttTime) < 600
			WHERE m.AttStart IS NULL
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		-- ca 3 thi gio vao ko the la 5h sang hom sau dc
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttStart = NULL
		WHERE isNightShift = 1 AND DATEDIFF(hh, WorkStart, AttStart) > 5

		/*print 'x--------------------------------------------------------x12'

set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		-- AttEnd
		-- 1. ga que an quan cuoi xay
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttEnd = tmp.AttTime, StateOut = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND (ForceState = 0 OR AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND abs(DATEDIFF(mi, m.WorkEnd, t.AttTime)) <= 60
				--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		UPDATE #tblShiftDetector_NeedUpdate
		SET AttEnd = tmp.AttTime, StateOut = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			WHERE t.AttTime < m.WorkEnd AND m.AttEnd IS NULL AND t.AttTime > m.WorkStart AND (t.ForceState = 0 OR t.AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND DATEDIFF(mi, ISNULL(m.AttStart, m.WorkStart), t.AttTime) > m.INOUT_MINIMUM AND DATEDIFF(mi, m.WorkEnd, t.AttTime) <= 60
				--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		UPDATE #tblShiftDetector_NeedUpdate
		SET AttEnd = tmp.AttTime, StateOut = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd < m.WorkEnd AND (t.ForceState = 0 OR t.AttState = 2) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND DATEDIFF(mi, m.WorkEnd, t.AttTime) <= 120
				--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		-- lấy giờ ra dựa trên giờ tăng ca sau
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttEnd = tmp.AttTime, StateOut = AttState, OTAfterEnd = tmp.AttTime
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
			WHERE m.AttEnd IS NULL AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.atttime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (ForceState = 0 OR AttState = 2) AND abs(datediff(mi, dateadd(mi, ss.OTAfterEndMi - ss.WorkEndMi, m.WorkEnd), t.AttTime)) < 60
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		IF @IN_OUT_TA_SEPARATE = 1
		BEGIN
			UPDATE #tblShiftDetector_NeedUpdate
			SET AttEnd = tmp.AttTime, StateOut = 2
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN (
				SELECT m.EmployeeId, m.ScheduleDate, m.ShiftCode, max(t.AttTime) AttTime
				FROM #tblShiftDetector_NeedUpdate m
				INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
				WHERE t.AttState = 2 AND ISNULL(FixedAtt, 0) = 0 AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.attTime > dateadd(hour, - 6, WorkEnd)
				GROUP BY m.EmployeeId, m.ScheduleDate, m.ShiftCode
				) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode
		END

		/*print 'x--------------------------------------------------------x14'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		-- 2. Ðói thì di làm an xa
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttEnd = tmp.AttTime, StateOut = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND (ForceState = 0 OR AttState = 2) AND (m.AttStart IS NULL OR (t.AttTime > m.AttStart AND DATEDIFF(mi, m.AttStart, t.AttTime) >= 20)) AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND abs(DATEDIFF(mi, m.WorkEnd, t.AttTime)) <= 90
				--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		-- 2. Ðói thì di làm an xa
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttEnd = tmp.AttTime, StateOut = AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND (ForceState = 0 OR AttState = 2) AND (m.AttStart IS NULL OR (t.AttTime > m.AttStart AND DATEDIFF(mi, m.AttStart, t.AttTime) >= 20)) AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow
				--and abs(DATEDIFF(mi,m.WorkEnd,t.AttTime)) <=320
				--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		-- AttStart
		-- 2. Ðói thì di làm an xa
		-- 2. doi thi di lam an xa
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttStart = tmp.AttTime, StateIn = AttState
		FROM #tblShiftDetector m
		INNER JOIN (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime ASC
					) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
			FROM #tblShiftDetector_NeedUpdate m
			INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttStart IS NULL AND (ForceState = 0 OR AttState = 1) AND (t.AttTime < m.AttEnd OR m.AttEnd IS NULL) AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow
				--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

		-- quên bấm 1 đầu và AttStart dang trùng AttEnd thì xác định lại cho dúng anh nào vào anh nào ra
		-- t/h nhân viên sửa lại giờ vào ra, nen bi du thua attTime
		UPDATE #tblShiftDetector_NeedUpdate
		SET AttStart = CASE 
				WHEN DATEDIFF(mi, WorkStart, AttStart) < 240 AND (isnull(AttEndYesterdayFixed, 0) = 0 OR DATEDIFF(mi, AttEndYesterday, AttStart) > 120)
					THEN AttStart
				ELSE NULL
				END, AttEnd = CASE 
				WHEN DATEDIFF(mi, WorkEnd, AttEnd) >= - 240 AND (isnull(AttStartTomorrowFixed, 0) = 0 OR DATEDIFF(mi, AttStartTomorrow, AttStart) < 120)
					THEN AttEnd
				ELSE NULL
				END, StateIn = 0, StateOut = 0
		FROM #tblShiftDetector_NeedUpdate
		WHERE AttStart = AttEnd --and EmployeeId = 'HLS001'
	END

	-- nghỉ cả ngày mà bấm thiếu vào ra thì bỏ
	UPDATE m
	SET -- AttStart = null, AttEnd = null,
		StateIn = 0, StateOut = 0
	FROM #tblShiftDetector_NeedUpdate m
	WHERE (m.AttStart IS NULL OR m.AttEnd IS NULL)
		--and (HolidayStatus > 0 or IsLeaveStatus3 = 1)
		AND (IsLeaveStatus3 = 1)

	/*print 'x--------------------------------------------------------x16'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	UPDATE #tblShiftDetector_NeedUpdate
	SET AttStartMi = datepart(hour, AttStart) * 60 + DATEPART(minute, AttStart) + (datediff(day, ScheduleDate, AttStart) * 1440), AttEndMi = datepart(hour, AttEnd) * 60 + DATEPART(minute, AttEnd)

	UPDATE #tblShiftDetector_NeedUpdate
	SET AttEndMi = 1440 + AttEndMi
	WHERE DATEDIFF(day, ScheduleDate, AttEnd) = 1

	IF @MATERNITY_LATE_EARLY_OPTION = 1
		UPDATE ta1
		SET AttStartMi = CASE 
				WHEN AttStartMi > WorkStartMi
					THEN CASE 
							WHEN AttStartMi - WorkStartMi <= 30
								THEN WorkStartMi
							ELSE AttStartMi - @MATERNITY_MUNITE
							END
				ELSE AttStartMi
				END
		FROM #tblShiftDetector_NeedUpdate ta1
		WHERE EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL
	ELSE IF @MATERNITY_LATE_EARLY_OPTION = 2
		UPDATE ta1
		SET AttEndMi = CASE 
				WHEN AttEndMi < WorkEndMi
					THEN CASE 
							WHEN WorkEndMi - AttStartMi <= 30
								THEN WorkEndMi
							ELSE AttEndMi + @MATERNITY_MUNITE
							END
				ELSE AttEndMi
				END
		FROM #tblShiftDetector_NeedUpdate ta1
		WHERE EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL
	ELSE IF @MATERNITY_LATE_EARLY_OPTION = 3
		UPDATE ta1
		SET AttEndMi = CASE 
				WHEN WorkEndMi - AttEndMi >= AttStartMi - WorkStartMi AND AttEndMi < WorkEndMi
					THEN CASE 
							WHEN WorkEndMi - AttStartMi <= 30
								THEN WorkEndMi
							ELSE AttEndMi + @MATERNITY_MUNITE
							END
				ELSE AttEndMi
				END, AttStartMi = CASE 
				WHEN WorkEndMi - AttEndMi < AttStartMi - WorkStartMi AND AttStartMi > WorkStartMi
					THEN CASE 
							WHEN AttStartMi - WorkStartMi <= 30
								THEN WorkStartMi
							ELSE AttStartMi - @MATERNITY_MUNITE
							END
				ELSE AttStartMi
				END
		FROM #tblShiftDetector_NeedUpdate ta1
		WHERE EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

	-- UPDATE LATE_PERMIT AND EARLY_PERMIT
	UPDATE sd
	SET sd.Late_Permit = CASE 
			WHEN p.LATE_PERMIT IS NOT NULL
				THEN p.LATE_PERMIT
			WHEN sc.LATE_PERMIT IS NOT NULL
				THEN sc.LATE_PERMIT
			WHEN dp.LATE_PERMIT IS NOT NULL
				THEN dp.LATE_PERMIT
			ELSE d.LATE_PERMIT
			END, sd.Early_Permit = CASE 
			WHEN p.EARLY_PERMIT IS NOT NULL
				THEN p.EARLY_PERMIT
			WHEN sc.EARLY_PERMIT IS NOT NULL
				THEN sc.EARLY_PERMIT
			WHEN dp.EARLY_PERMIT IS NOT NULL
				THEN dp.EARLY_PERMIT
			ELSE d.EARLY_PERMIT
			END
	FROM #tblShiftDetector_NeedUpdate sd
	LEFT JOIN #tblEmployeeList s ON s.EmployeeID = sd.EmployeeId
	LEFT JOIN tblDivision d ON d.DivisionID = s.DivisionID
	LEFT JOIN tblDepartment dp ON dp.DepartmentID = s.DepartmentID
	LEFT JOIN tblSection sc ON sc.SectionID = s.SectionID
	LEFT JOIN tblPosition p ON p.PositionID = s.PositionID

	--update sd set AttStartMi = case when AttStartMi < WorkEndMi + Late_Permit then WorkEndMi else AttStartMi end from #tblShiftDetectorMatched sd
	/*
update sd
set AttStartMi = case when AttStartMi BETWEEN WorkStartMi and WorkStartMi + case when Late_Permit < 10 then Late_Permit else 10 end then WorkStartMi else AttStartMi end,
    AttEndMi = case when AttEndMi BETWEEN WorkEndMi - case when Early_Permit < 10 then Early_Permit else 10 end AND WorkEndMi then  WorkEndMi else AttEndMi end
from #tblShiftDetector_NeedUpdate sd
*/
	UPDATE #tblShiftDetector_NeedUpdate
	SET WorkingTimeMi = CASE 
			WHEN AttEndMi >= WorkEndMi
				THEN WorkEndMi
			WHEN AttEndMi >= BreakEndMi
				THEN AttEndMi
			WHEN AttEndMi >= BreakStartMi
				THEN BreakStartMi
			WHEN AttEndMi >= WorkStartMi
				THEN AttEndMi
			ELSE WorkStartMi
			END - CASE 
			WHEN AttStartMi <= WorkStartMi
				THEN WorkStartMi
			WHEN AttStartMi < BreakStartMi
				THEN AttStartMi
			WHEN AttStartMi <= BreakEndMi
				THEN BreakEndMi
			WHEN AttStartMi <= WorkEndMi
				THEN AttStartMi
			ELSE WorkEndMi
			END, StdWorkingTimeMi = WorkEndMi - WorkStartMi - (BreakEndMi - BreakStartMi)
	WHERE AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

	UPDATE #tblShiftDetector_NeedUpdate
	SET StdWorkingTimeMi = WorkEndMi - WorkStartMi - (BreakEndMi - BreakStartMi)

	/*print 'x--------------------------------------------------------x18'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	UPDATE m
	SET StdWorkingTimeMi = StdWorkingTimeMi - lv.LvAmount * 60.0
	FROM #tblShiftDetector_NeedUpdate m
	INNER JOIN (
		SELECT EmployeeID, LeaveDate, sum(LvAmount) LvAmount
		FROM #tblLvHistory
		WHERE LeaveCategory = 1
		GROUP BY EmployeeID, LeaveDate
		) lv ON lv.EmployeeID = m.EmployeeId AND m.ScheduleDate = lv.LeaveDate
	WHERE StdWorkingTimeMi IS NOT NULL AND m.IsLeaveStatus3 <> 1

	UPDATE #tblShiftDetector
	SET StdWorkingTimeMi = 480
	WHERE -- NeedUpdate =1 and
		StdWorkingTimeMi <= 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET WorkingTimeMi = WorkingTimeMi - (BreakEndMi - BreakStartMi)
	WHERE BreakStartMi < BreakEndMi AND AttStartMi <= BreakStartMi AND AttEndMi >= BreakEndMi AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

	/*print 'x--------------------------------------------------------x19'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	IF @MATERNITY_LATE_EARLY_OPTION = 0
		UPDATE #tblShiftDetector_NeedUpdate
		SET WorkingTimeMi = CASE 
				WHEN WorkingTimeMi + @MATERNITY_MUNITE >= StdWorkingTimeMi
					THEN StdWorkingTimeMi
				ELSE WorkingTimeMi + @MATERNITY_MUNITE
				END
		FROM #tblShiftDetector_NeedUpdate d
		WHERE d.EmployeeStatusID IN (10, 11) AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

	UPDATE #tblShiftDetector_NeedUpdate
	SET WorkingTimeMi = StdWorkingTimeMi
	WHERE WorkingTimeMi >= StdWorkingTimeMi

	UPDATE ta1
	SET WorkingTimeMi = cast(WorkingTimeMi AS FLOAT) * (ta2.STDWorkingTime_SS - isnull(lv.LvAmount * 60.0, 0)) / ta1.StdWorkingTimeMi
	FROM #tblShiftDetector_NeedUpdate ta1
	INNER JOIN #tblShiftSetting ta2 ON ta1.ShiftCode = ta2.ShiftCode AND ta1.StdWorkingTimeMi <> ta2.STDWorkingTime_SS AND ta1.Workingtimemi > 0
	LEFT JOIN (
		SELECT EmployeeID, LeaveDate, sum(LvAmount) LvAmount
		FROM #tblLvHistory
		WHERE LeaveCategory = 1
		GROUP BY EmployeeID, LeaveDate
		) lv ON lv.EmployeeID = ta1.EmployeeId AND ta1.ScheduleDate = lv.LeaveDate
	WHERE StdWorkingTimeMi IS NOT NULL AND ta1.IsLeaveStatus3 <> 1

	/*print 'x--------------------------------------------------------x20'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	UPDATE #tblShiftDetector_NeedUpdate
	SET AttEnd2 = tmp.AttTime
	FROM #tblShiftDetector_NeedUpdate m
	INNER JOIN (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY m.EmployeeId, m.ShiftCode, m.ScheduleDate ORDER BY AttTime DESC
				) AS STT, m.EmployeeId, m.ScheduleDate, m.ShiftCode, AttTime, AttState
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NOT NULL AND (ForceState = 0 OR AttState = 2) AND (t.AttTime > m.AttEnd AND DATEDIFF(mi, m.AttEnd, t.AttTime) >= 20) AND t.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND abs(DATEDIFF(mi, m.WorkEnd, t.AttTime)) <= 320
			--group by m.EmployeeId, m.ScheduleDate,m.ShiftCode
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.ShiftCode = tmp.ShiftCode AND STT = 1

	UPDATE #tblShiftDetector_NeedUpdate
	SET AttEndMi2 = datepart(hour, AttEnd2) * 60 + DATEPART(minute, AttEnd2)

	UPDATE #tblShiftDetector_NeedUpdate
	SET AttEndMi2 = 1440 + AttEndMi2
	WHERE AttEndMi > 1440

	-- chấm điểm
	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = CASE 
			WHEN AttStart IS NULL
				THEN NULL
			ELSE DATEDIFF(mi, AttStart, WorkStart)
			END, OutInterval = CASE 
			WHEN AttEnd IS NULL
				THEN NULL
			ELSE DATEDIFF(mi, WorkEnd, AttEnd)
			END

	-- che do lam 7h/ngay maternity
	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = InInterval + @MATERNITY_MUNITE
	FROM #tblShiftDetector_NeedUpdate d
	WHERE d.EmployeeStatusID IN (10, 11) AND InInterval > 0 AND OutInterval > 0

	/*print 'x--------------------------------------------------------x21'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = 0
	FROM #tblShiftDetector_NeedUpdate d
	WHERE d.EmployeeStatusID IN (10, 11) AND InInterval < - 30 AND @MATERNITY_MUNITE + InInterval >= 0 AND OutInterval > 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET OutInterval = 0
	FROM #tblShiftDetector_NeedUpdate d
	WHERE d.EmployeeStatusID IN (10, 11) AND OutInterval < - 30 AND @MATERNITY_MUNITE + OutInterval >= 0 AND InInterval > 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = InInterval + CASE 
			WHEN InInterval BETWEEN - 35 AND 0
				THEN @MATERNITY_MUNITE / 2
			ELSE @MATERNITY_MUNITE
			END
	FROM #tblShiftDetector_NeedUpdate d
	WHERE d.EmployeeStatusID IN (10, 11) AND d.InInterval IS NOT NULL AND d.InInterval < - 20

	/*print 'x--------------------------------------------------------x22'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	UPDATE #tblShiftDetector_NeedUpdate
	SET OutInterval = OutInterval + CASE 
			WHEN OutInterval BETWEEN - 35 AND 0
				THEN @MATERNITY_MUNITE / 2
			ELSE @MATERNITY_MUNITE
			END
	FROM #tblShiftDetector_NeedUpdate d
	WHERE d.EmployeeStatusID IN (10, 11) AND d.OutInterval IS NOT NULL AND d.OutInterval < - 20

	UPDATE #tblShiftDetector_NeedUpdate
	SET InIntervalS = abs(CASE 
				WHEN AttStart IS NULL OR WorkStartSMi <= 0
					THEN NULL
				ELSE AttStartMi - WorkStartSMi
				END), OutIntervalS = abs(CASE 
				WHEN AttEnd IS NULL OR WorkEndSMi <= 0
					THEN NULL
				ELSE WorkEndSMi - AttEndMi
				END)
		--update #tblShiftDetector_NeedUpdate set
		, InIntervalE = abs(CASE 
				WHEN AttStart IS NULL OR WorkStartEMi <= 0
					THEN NULL
				ELSE AttStartMi - WorkStartEMi
				END), OutIntervalE = abs(CASE 
				WHEN AttEnd IS NULL OR WorkEndEMi <= 0
					THEN NULL
				ELSE WorkEndEMi - AttEndMi
				END)

	-- nếu có tang ca truoc
	UPDATE u
	SET InIntervalS = s.OTBeforeStartMi - u.AttStartMi
	FROM #tblShiftDetector_NeedUpdate u
	INNER JOIN #tblShiftSetting s ON u.ShiftCode = s.ShiftCode
	WHERE u.AttStartMi IS NOT NULL AND u.InIntervalS > (u.AttStartMi - s.OTBeforeStartMi) --and (u.AttStartMi - s.OTBeforeStartMi) > -1

	-- nếu có tang ca sau
	UPDATE u
	SET OutIntervalS = u.AttEndMi - s.OTAfterEndMi
	FROM #tblShiftDetector_NeedUpdate u
	INNER JOIN #tblShiftSetting s ON u.ShiftCode = s.ShiftCode
	WHERE u.AttEndMi IS NOT NULL AND u.OutIntervalS > (u.AttEndMi - s.OTAfterEndMi) AND (u.AttEndMi - s.OTAfterEndMi) > - 1 AND u.AttEnd2 IS NULL

	UPDATE u
	SET OutIntervalS = u.AttEndMi2 - s.OTAfterEndMi
	FROM #tblShiftDetector_NeedUpdate u
	INNER JOIN #tblShiftSetting s ON u.ShiftCode = s.ShiftCode
	WHERE u.AttEndMi2 IS NOT NULL AND u.AttEnd2 IS NOT NULL

	-- lấy Interval sát với mốc ca nhấtt, 2008 khong co lenh IIF() ::(
	--update #tblShiftDetector_NeedUpdate set InInterval = case when InIntervalS > InIntervalE then InIntervalE else InIntervalS end where abs(InInterval) - 30 > InIntervalS or abs(InInterval) -30 > InIntervalE
	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = CASE 
			WHEN InIntervalS > InIntervalE
				THEN InIntervalE
			ELSE InIntervalS
			END
	WHERE abs(InInterval) > InIntervalS OR abs(InInterval) > InIntervalE

	--update #tblShiftDetector_NeedUpdate set OutInterval = case when OutIntervalS > OutIntervalE then OutIntervalE else OutIntervalS end where abs(OutInterval)-30 > OutIntervalS or abs(OutInterval)-30 > OutIntervalE
	--update #tblShiftDetector_NeedUpdate set OutInterval = case when OutIntervalS > OutIntervalE then OutIntervalE else OutIntervalS end where (abs(OutInterval) > OutIntervalS or abs(OutInterval) > OutIntervalE) and @IgnoreTimeOut_ShiftDetector = 0
	--select * from #tblShiftDetector_NeedUpdate where InInterval = 1 and OutInterval = 1
	/*print 'x--------------------------------------------------------x24'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())

print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	-- nghi nua buoi
	UPDATE m
	SET InInterval = InInterval + lv.LvAmount * 60.0 + CASE 
			WHEN m.AttStart > m.BreakEnd
				THEN DATEDIFF(mi, m.BreakStart, m.BreakEnd)
			ELSE 0
			END
	FROM #tblShiftDetector_NeedUpdate m
	INNER JOIN #tblLvHistory lv ON lv.EmployeeID = m.EmployeeId AND m.ScheduleDate = lv.LeaveDate
	WHERE --NeedUpdate=1 and
		InInterval IS NOT NULL AND lv.LeaveStatus IN (1, 4)

	UPDATE m
	SET OutInterval = OutInterval + lv.LvAmount * 60.0 + CASE 
			WHEN m.AttEnd < m.BreakEnd
				THEN DATEDIFF(mi, m.BreakStart, m.BreakEnd)
			ELSE 0
			END
	FROM #tblShiftDetector_NeedUpdate m
	INNER JOIN #tblLvHistory lv ON lv.EmployeeID = m.EmployeeId AND m.ScheduleDate = lv.LeaveDate
	WHERE --NeedUpdate=1 and
		OutInterval IS NOT NULL AND lv.LeaveStatus IN (2, 5) AND @IgnoreTimeOut_ShiftDetector = 0

	UPDATE m
	SET InInterval = OTBeforeStartMi - AttStartMi
	FROM #tblShiftDetector_NeedUpdate m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE abs(InInterval) > 100 AND OTBeforeStart IS NOT NULL

	UPDATE m
	SET OutInterval = AttEndMi - OTAfterStartMi
	FROM #tblShiftDetector_NeedUpdate m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE abs(OutInterval) > 100 AND OTAfterEnd IS NOT NULL

	-- Xu ly nhung cap chua co diem
	--update #tblShiftDetector_NeedUpdate set InInterval = case when StdWorkingTimeMi is null then 500 else StdWorkingTimeMi end where AttStart is null
	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = - 480
	WHERE AttStart IS NULL

	--update #tblShiftDetector_NeedUpdate set OutInterval = case when StdWorkingTimeMi is null then 500 else StdWorkingTimeMi end where AttEnd is null and @IgnoreTimeOut_ShiftDetector = 0
	UPDATE #tblShiftDetector_NeedUpdate
	SET OutInterval = - 480
	WHERE AttEnd IS NULL AND @IgnoreTimeOut_ShiftDetector = 0

	/*print 'x--------------------------------------------------------x242'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	UPDATE #tblShiftDetector_NeedUpdate
	SET OutInterval = isnull(StdWorkingTimeMi, 500), OutIntervalE = isnull(StdWorkingTimeMi, 500), OutIntervalS = isnull(StdWorkingTimeMi, 500), WorkingTimeMi = StdWorkingTimeMi
	WHERE @IgnoreTimeOut_ShiftDetector = 1

	UPDATE #tblShiftDetector_NeedUpdate
	SET InInterval = 0
	WHERE InInterval BETWEEN @SHIFTDETECTOR_LATE_PERMIT * - 1 AND @SHIFTDETECTOR_IN_EARLY_USUALLY

	UPDATE #tblShiftDetector_NeedUpdate
	SET OutInterval = 0
	WHERE OutInterval BETWEEN @SHIFTDETECTOR_EARLY_PERMIT * - 1 AND 0

	-- chang them nhan dang nhung ca thieu gio vao
	--delete from #tblShiftDetector_NeedUpdate where AttStart is null and @ProcessOrderByDate_ShiftDetector = 1
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = - 900000, AttEnd = NULL, InInterval = NULL, OutInterval = NULL
	FROM #tblShiftDetector_NeedUpdate a
	WHERE AttStart IS NULL AND @ProcessOrderByDate_ShiftDetector = 1 AND EXISTS (
			SELECT 1
			FROM #tblShiftDetector_NeedUpdate b
			WHERE a.EmployeeId = b.EmployeeId AND a.ScheduleDate = b.ScheduleDate AND b.WorkingTimeMi > 200 AND a.ShiftCode <> b.ShiftCode AND a.RatioMatch < b.RatioMatch
			)

	-- cham diem
	-- chấm điểm theo ct thức toán học, hàm logarit và hàm số mũ
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + (- 91.18357565 * log(InInterval) + 591.0074141)
	WHERE InInterval > 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 500.1747978 * POWER(1.05572192, InInterval)
	WHERE InInterval <= 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + (- 70 * log(OutInterval) + 400)
	WHERE OutInterval > 0 AND @IgnoreTimeOut_ShiftDetector = 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 400 * POWER(1.05572192, OutInterval)
	WHERE OutInterval <= 0 AND @IgnoreTimeOut_ShiftDetector = 0

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + (- 70 * log(OutIntervalS) + 400)
	WHERE OutIntervalS > 0 AND @IgnoreTimeOut_ShiftDetector = 0 AND AttEnd2 IS NOT NULL

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 400 * POWER(1.05572192, OutIntervalS)
	WHERE OutIntervalS <= 0 AND @IgnoreTimeOut_ShiftDetector = 0 AND AttEnd2 IS NOT NULL

	--select * from  #tblShiftDetector_NeedUpdate order by EmployeeId, ScheduleDate return
	IF (OBJECT_ID('sp_ShiftDetector_beginUpdateLongShiftDeduct') IS NULL)
		EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_beginUpdateLongShiftDeduct ( @StopUpdate bit output ,@LoginID int ,@FromDate datetime ,@ToDate datetime ) as begin SET NOCOUNT ON; end')

	SET @StopUpdate = 0

	-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
	IF @StopUpdate = 0
	BEGIN
		UPDATE ta1
		SET RatioMatch -= abs(OutInterval) / 30 * 50
		FROM #tblShiftDetector_NeedUpdate ta1
		WHERE StdWorkingTimeMi > 600 AND AttEnd IS NOT NULL AND @IgnoreTimeOut_ShiftDetector = 0 --and OutInterval >= 30

		UPDATE ta1
		SET RatioMatch -= abs(InInterval) / 30 * 50
		FROM #tblShiftDetector_NeedUpdate ta1
		WHERE StdWorkingTimeMi > 600 AND Attstart IS NOT NULL AND @IgnoreTimeOut_ShiftDetector = 0 --and InInterval >= 30
	END

	-- hành chính hiếm khi tang ca truoc
	-- hanh chinh hiem khi tang ca truoc
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = CASE 
			WHEN RatioMatch IS NULL
				THEN 550 - (ABS(InInterval) + ABS(OutInterval)) -- neu chua cho diem
			ELSE RatioMatch
				-- nếu là ca hành chính và vào som thì trừ điểm
				- CASE 
					WHEN isOfficalShift = 1 AND InIntervalS IS NOT NULL AND InInterval > 30
						THEN 50 * InInterval / 30
					ELSE 0
					END + CASE 
					WHEN OutInterval > (0 - @SHIFTDETECTOR_EARLY_PERMIT) AND AttEndMi - AttStartMi < 660
						THEN CASE 
								WHEN InInterval BETWEEN (0 - @SHIFTDETECTOR_LATE_PERMIT) AND 11
									THEN 200
								WHEN InInterval BETWEEN 11 AND 20
									THEN 100
								ELSE 0
								END
					ELSE 0
					END -- Neu khop gio ra thi cong diem tuong ung, nếu khớp giờ ra thì cộng điểm tương ứng
				+ isnull(WorkingTimeMi, 0) -- uu tien ca dai(cang dai cang suong), uu tiên ca dài (ca càng dài điểm càng cao)
				--+ CASE WHEN (WorkingTimeMi + @SHIFTDETECTOR_LATE_PERMIT) >= StdWorkingTimeMi THEN 270 ELSE 0 END
			END --- (ABS(InInterval)+ABS(OutInterval))

	-- gặp ca dài (12h) mà đi làm không đủ thì phạt để quy về ca 8h
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch - StdWorkingTimeMi
	WHERE StdWorkingTimeMi >= 720 AND WorkingTimeMi < StdWorkingTimeMi - 15

	-- Ca dêm (ca 3) thường sẽ ra dúng giờ, nên uu tiên ca dêm ra dúng giờ (chỉ uu tiên khi có dủ giờ vào, giờ ra)
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + (- 91.18357565 * log(OutInterval) + 591.0074141)
	WHERE OutInterval BETWEEN 1 AND 10 AND AttStart IS NOT NULL AND AttEnd IS NOT NULL AND WorkEndMi > 1440 AND (InInterval < 60 OR (WorkEndMi - WorkStartMi < 500 AND WorkStartMi - AttStartMi < 270 AND InInterval < 270)) AND @IgnoreTimeOut_ShiftDetector = 0 AND ShiftCodeYesterday = ShiftCode

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + RatioMatch / 2
	WHERE OutInterval = 0 AND InInterval BETWEEN - 5 AND 10 AND WorkEndMi > 1440 AND @IgnoreTimeOut_ShiftDetector = 0

	--ca dài mà di sớm, về muộn thì bị trừ điểm đim uu tiên cho ca ngắn
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch - isnull(WorkingTimeMi, 0)
	FROM #tblShiftDetector_NeedUpdate a --inner join #tblWSchedule ws on a.EmployeeId = ws.EmployeeID and a.ScheduleDate = ws.ScheduleDate
	WHERE a.WorkingTimeMi > 500 AND InIntervalS > 45 AND OutIntervalS > 45

	-- ca 3 mà thieu dau ra hoac dau vao thi coi nhu bo :)
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = CASE 
			WHEN RatioMatch > 400
				THEN 400
			ELSE RatioMatch - 300
			END
	WHERE isNightShift = 1 AND (AttEnd IS NULL OR AttStart IS NULL) AND TIMEOUTAFTER < @getdate

	-- ca 3 ngay chu nhat thieu dau vao thi bo vi co the la ca 1 cua ngay hom sau
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = - 10000
	WHERE isNightShift = 1 AND HolidayStatus > 0 AND AttStart IS NULL AND TIMEOUTAFTER < @getdate

	-- thieu cong thi bi phat ty le
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch - 300
	WHERE (InInterval < 0 OR OutInterval < 0) AND StdWorkingTimeMi - WorkingTimeMi > 5 AND StdWorkingTimeMi > 420

	/*print 'x--------------------------------------------------------x27'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	IF (OBJECT_ID('sp_ShiftDetector_WrongShiftProcess') IS NULL)
		EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_WrongShiftProcess ( @StopUpdate bit output ,@LoginID int ,@FromDate datetime ,@ToDate datetime ) as begin SET NOCOUNT ON; end')

	SET @StopUpdate = 0

	-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
	EXEC sp_ShiftDetector_WrongShiftProcess @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

	IF @StopUpdate = 0 AND (@WrongShiftProcess_ShiftDetector = 1 OR @ProcessOrderByDate_ShiftDetector = 1)
	BEGIN
		-- phat nang loi lam mat du lieu
		UPDATE d
		SET RatioMatch = d.RatioMatch * 0.1 - 500, isWrongShift = 1
		FROM #tblShiftDetector_NeedUpdate d
		INNER JOIN #tblShiftDetectorMatched m ON d.employeeId = m.EmployeeID AND d.ScheduleDate = m.ScheduleDate - 1
		WHERE EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE m.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN d.TimeOutAfter AND m.TIMEINBEFORE
				)

		UPDATE d
		SET RatioMatch -= 200, isWrongShift = 1
		FROM #tblShiftDetector_NeedUpdate d
		INNER JOIN (
			SELECT m.EmployeeId, ScheduleDate + 1 AS ScheduleDate, max(AttEnd) AttEnd
			FROM #tblShiftDetector_NeedUpdate m
			GROUP BY EmployeeId, ScheduleDate
			) ta1 ON d.EmployeeId = ta1.EmployeeId AND d.ScheduleDate = ta1.ScheduleDate
		WHERE EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE d.EmployeeId = t.EmployeeID AND t.AttTime > ta1.AttEnd AND t.AttTime < d.AttStart
				)

		UPDATE d
		SET RatioMatch = d.RatioMatch * 0.5 - 500, isWrongShift = 1
		FROM #tblShiftDetector_NeedUpdate d
		WHERE EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE d.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN DATEADD(mi, 60, d.AttEndYesterday) AND dateadd(mi, - 60, d.AttStart)
				)

		UPDATE d
		SET RatioMatch = d.RatioMatch * 0.1 - 500, isWrongShift = 1
		FROM #tblShiftDetector_NeedUpdate d
		INNER JOIN #tblShiftDetectorMatched m ON d.employeeId = m.EmployeeID AND d.ScheduleDate = m.ScheduleDate + 1
		WHERE EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE m.EmployeeId = t.EmployeeID AND t.AttTime > m.AttEnd AND t.AttTime BETWEEN CASE 
								WHEN d.ShiftCode = m.ShiftCode
									THEN dateadd(SECOND, 1, m.TIMEOUTAFTER)
								ELSE dateadd(MINUTE, 240, isnull(m.AttEnd, m.WorkEnd))
								END AND dateadd(mi, - 60, isnull(d.AttStart, d.WorkStart))
				)

		-- ngay hom truoc nghi ca ngay ma hom sau bi mat gio cham cong do nhan sai ca
		UPDATE d
		SET RatioMatch = d.RatioMatch * 0.1 - 500, isWrongShift = 1
		FROM #tblShiftDetector_NeedUpdate d
		WHERE (
				EXISTS (
					SELECT 1
					FROM #tblLvHistory lv
					WHERE lv.LeaveCategory = 1 AND d.EmployeeId = lv.EmployeeID AND lv.LeaveStatus = 3 AND lv.LeaveDate = d.ScheduleDate - 1
					) OR EXISTS (
					SELECT 1
					FROM (
						SELECT *
						FROM #tblShiftDetector_NeedUpdate
						
						UNION ALL
						
						SELECT *
						FROM #tblShiftDetectorMatched
						) l
					WHERE d.EmployeeId = l.EmployeeID AND l.HolidayStatus > 0 AND l.AttStart IS NULL AND l.AttEnd IS NULL AND l.ScheduleDate = d.ScheduleDate - 1
					)
				) AND NOT EXISTS (
				SELECT 1
				FROM #tblPrevMatch l
				WHERE d.EmployeeId = l.EmployeeID AND d.ScheduleDate = l.ScheduleDate AND l.HolidayStatus > 0 AND l.AttStart IS NOT NULL AND l.AttEnd IS NOT NULL
				) AND NOT EXISTS (
				SELECT 1
				FROM #tblLvHistory lv
				WHERE lv.LeaveCategory = 1 AND d.EmployeeId = lv.EmployeeID AND lv.LeaveStatus = 3 AND lv.LeaveDate = d.ScheduleDate
				) AND EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE d.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN d.ScheduleDate AND dateadd(mi, - 60, d.AttStart)
				)
	END

	-- ngay hom truoc nghi cuoi tuan, nghi le ma hom sau bi mat gio cham cong do nhan sai ca
	UPDATE d
	SET RatioMatch = RatioMatch * 0.1 - 500, isWrongShift = 1
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblHasTA_Fixed f ON f.EmployeeID = d.EmployeeId AND d.ScheduleDate = f.Attdate + 1
	INNER JOIN #tblWSchedule ws ON f.EmployeeID = ws.EmployeeID AND f.Attdate = ws.ScheduleDate AND ws.HolidayStatus > 0 AND f.AttStart IS NULL AND f.AttEnd IS NULL AND EXISTS (
			SELECT 1
			FROM #tblTmpAttend t
			WHERE d.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN d.ScheduleDate AND dateadd(mi, - 60, d.AttStart)
			)

	UPDATE d
	SET RatioMatch = RatioMatch * 0.1 - 500, isWrongShift = 1
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblHasTA m ON d.employeeId = m.EmployeeID AND d.ScheduleDate = m.Attdate + 1
	WHERE isWrongShift IS NULL AND EXISTS (
			SELECT 1
			FROM #tblTmpAttend t
			WHERE m.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN dateadd(mi, 60, isnull(ISNULL(m.AttEnd, m.AttStart), d.ScheduleDate)) AND dateadd(mi, - 60, d.AttStart)
			)

	UPDATE d
	SET RatioMatch = RatioMatch * 0.1 - 500, isWrongShift = 1
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblHasTA_Fixed m ON d.employeeId = m.EmployeeID AND d.ScheduleDate = m.Attdate + 1
	WHERE EXISTS (
			SELECT 1
			FROM #tblTmpAttend t
			WHERE m.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN dateadd(mi, 60, m.AttEnd) AND dateadd(mi, - 60, d.AttStart)
			)

	-- moi vao lam ma bi mat gio cong do nhan sai ca
	UPDATE d
	SET RatioMatch = RatioMatch * 0.1 - 500, isWrongShift = 1
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblEmployeeList m ON d.employeeId = m.EmployeeID AND d.ScheduleDate = m.hiredate
	WHERE EXISTS (
			SELECT 1
			FROM #tblTmpAttend t
			WHERE m.EmployeeId = t.EmployeeID AND t.AttTime BETWEEN m.HireDate AND dateadd(mi, - 60, d.AttStart)
			)

	-- phat hien co ca bi sai thi nang cac ca con lai len de cho len tau truoc
	UPDATE d
	SET RatioMatch = RatioMatch + 300
	FROM #tblShiftDetector_NeedUpdate d
	WHERE EXISTS (
			SELECT 1
			FROM (
				SELECT EmployeeId, ScheduleDate, ShiftCode
				FROM #tblShiftDetector_NeedUpdate
				WHERE isWrongShift = 1
				) t
			WHERE d.EmployeeId = t.EmployeeId AND d.ScheduleDate = t.ScheduleDate AND d.ShiftCode <> t.ShiftCode
			) AND d.RatioMatch > - 500

	--t.AttTime between dateadd(mi,60, D.AttEnd) and dateadd(mi,-60, m.AttStart))
	--if(@RepeatTime= 4)
	--select @RepeatTime,* from #tblShiftDetector_NeedUpdate order by ScheduleDate
	/*print 'x--------------------------------------------------------x32'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
	-- Ch?m di?m ph?
	-- Giong ca hôm qua, thêm 100 diem, (nhung ca dêm giong hôm truoc mà thieu gio vào hoac ra thì ko dc công diem, vì có the hôm dó xoay ca)
	EXEC sp_ShiftDetector_beginUpdateLongShiftDeduct @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

	EXEC sp_ShiftDetector_beginUpdateLongShiftDeduct @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 100
	WHERE ShiftCodeYesterday IS NOT NULL AND ShiftCode = ShiftCodeYesterday AND (isNightShift = 0 OR (isNightShift = 1 AND AttStart IS NOT NULL AND AttEnd IS NOT NULL)) AND InInterval > - 5

	-- ca dem thieu gio vao hoac ra ma hom sau la ngay cuoi tuan thi van dc uu tien nhan
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 100
	FROM #tblShiftDetector_NeedUpdate u
	WHERE u.ShiftCode = u.ShiftCodeYesterday AND ((u.AttStart IS NULL AND u.AttEnd IS NOT NULL) OR (u.AttEnd IS NULL AND u.AttStart IS NOT NULL)) AND u.isNightShift = 1 AND EXISTS (
			SELECT 1
			FROM #tblWSchedule m
			WHERE u.EmployeeId = m.EmployeeId AND u.ScheduleDate = m.ScheduleDate - 1 AND m.HolidayStatus = 1
			)

	-- neu khong co ca hom qua thi uu tien giong ca hom sau, chi nhung truong hop thieu gio vao hoac gio ra
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 100
	FROM #tblShiftDetector_NeedUpdate u
	WHERE u.ShiftCodeYesterday IS NULL AND ((u.AttStart IS NULL AND u.AttEnd IS NOT NULL) OR (u.AttStart IS NOT NULL AND u.AttEnd IS NULL)) AND EXISTS (
			SELECT 1
			FROM #tblShiftDetectorMatched m
			WHERE u.EmployeeId = m.EmployeeId AND u.ShiftCode = m.ShiftCode AND u.ScheduleDate = m.ScheduleDate - 1
			)

	-- hom do la ngay nghi thi uu tien la ca giong ca ho qua
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 100
	WHERE ShiftCodeYesterday IS NOT NULL AND ShiftCode = ShiftCodeYesterday AND IsLeaveStatus3 = 1

	-- neu tat ca cac ca diem dieu thap thi uu tien ca hom qua nhieu hon
	--update #tblShiftDetector_NeedUpdate set RatioMatch = RatioMatch + 100 where RatioMatch<=0 and ShiftCodeYesterday is not null and ShiftCode = ShiftCodeYesterday
	--hom truoc di ca 3 mà có giờ vào, ra để tránh nhận ngày tiếp theo là di ca 1 thì tang điểm ca giống ca hôm trước nhiều lên cho những record có di?m s? < 500 , isNightShiftYesterday chi =1 khi ngay hom truoc la ca dem va co du gio vao, ra
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch + 200
	WHERE RatioMatch < 500 AND isNightShiftYesterday = 1 AND ShiftCodeYesterday IS NOT NULL AND ShiftCode = ShiftCodeYesterday AND (AttStart IS NOT NULL AND AttEnd IS NOT NULL)

	-- Hoa thom toa huong xa
	UPDATE d
	SET RatioMatch += 100
	FROM #tblShiftDetector_NeedUpdate d
	WHERE EXISTS (
			SELECT 1
			FROM #tblBloomFlavour b
			WHERE d.EmployeeId = b.EmployeeId AND d.ShiftCode = b.ShiftCode AND d.ScheduleDate BETWEEN b.FromDate AND b.ToDate
			) AND @ProcessOrderByDate_ShiftDetector = 0

	-- đi trễ về sớm trừ 5% điểm
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch - abs(RatioMatch * 0.05)
	WHERE (InInterval < 0 OR OutInterval < 0)

	--đi trễ và về sớm trừ 50% điểm
	UPDATE #tblShiftDetector_NeedUpdate
	SET RatioMatch = RatioMatch - abs(RatioMatch * 0.5)
	WHERE (InInterval < 0 AND OutInterval < 0)

	-- Đối tượng nghỉ t7 thì ca HC được thêm 20 điểm
	UPDATE d
	SET RatioMatch = RatioMatch + 20
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblEmployeeList e ON d.EmployeeId = e.EmployeeID
	INNER JOIN tblEmployeeType t ON e.EmployeeTypeID = t.EmployeeTypeID AND t.SaturdayOff = 1
	WHERE d.isOfficalShift = 1

	-- trong tuan ty le ca di cao se dc công 330 diem -- @StatisticShiftPerweek_ShiftDetector
	IF @StatisticShiftPerweek_ShiftDetector > 0
	BEGIN
		/*
 select ta.EmployeeId, datepart(wk,ta.ScheduleDate) WeekNumber,ss.ShiftCode, count(1) as ShiftCount
 into #tblwschedule_ShiftCount from tblwschedule ta inner join tblHasTA ha on ta.EmployeeID = ha.EmployeeID and ta.ScheduleDate = ha.AttDate
 inner join tblShiftSetting ss on ta.shiftID = ss.ShiftID
 where exists (select 1 from #tblPendingImportAttend m where ta.EmployeeID = m.EmployeeId and datepart(wk,ta.scheduleDate) = datepart(wk,m.Date) and ta.ScheduleDate between @FromDate and @ToDate )
 and ha.AttStart is not null
 and ha.AttEnd is not null
 group by ta.EmployeeID,datepart(wk,ta.ScheduleDate),ss.ShiftCode having COUNT(1) > 2
 */
		SET DATEFIRST 1

		SELECT m.EmployeeId, datepart(wk, m.ScheduleDate) WeekNumber, m.ShiftCode, count(1) AS ShiftCount
		INTO #tblwschedule_ShiftCount
		FROM #tblShiftDetectorMatched m
		WHERE m.AttStart IS NOT NULL AND m.AttEnd IS NOT NULL
		GROUP BY m.EmployeeID, datepart(wk, m.ScheduleDate), m.ShiftCode
		HAVING COUNT(1) > 1

		DELETE s
		FROM #tblwschedule_ShiftCount s
		WHERE NOT EXISTS (
				SELECT 1
				FROM (
					SELECT t.EmployeeID, t.WeekNumber, max(t.ShiftCount) ShiftCount
					FROM #tblwschedule_ShiftCount t
					GROUP BY t.EmployeeID, t.WeekNumber
					) t
				WHERE s.EmployeeID = t.EmployeeID AND s.WeekNumber = t.WeekNumber AND s.ShiftCount = t.ShiftCount
				)

		UPDATE #tblShiftDetector_NeedUpdate
		SET RatioMatch = RatioMatch + @StatisticShiftPerweek_ShiftDetector
		FROM #tblShiftDetector_NeedUpdate m
		INNER JOIN #tblwschedule_ShiftCount sc ON m.EmployeeId = sc.EmployeeID AND datepart(wk, ScheduleDate) = sc.WeekNumber AND m.ShiftCode = sc.ShiftCode

		DROP TABLE #tblwschedule_ShiftCount

		SET DATEFIRST 7
	END

	-- Thống kê ca qua Lịch sử tỉ lệ làm ca lớn nhất dc 25 điểm
	-- chua làm
	--Nếu có phân biệt vào ra mà trạng thái vào ra, chính xác ca 2 được cộng 500d
	IF @IN_OUT_TA_SEPARATE = 1
	BEGIN
		UPDATE s
		SET RatioMatch = RatioMatch + (WorkEndMi - WorkStartMi)
		FROM #tblShiftDetector_NeedUpdate s
		WHERE StateIn = 1 AND StateOut = 2

		-- bam thieu 1 dau, nhung dung vao hoac ra
		UPDATE s
		SET RatioMatch = RatioMatch + 100
		FROM #tblShiftDetector_NeedUpdate s
		WHERE ((StateIn = 1 AND StateOut IS NULL) OR (StateIn IS NULL AND StateOut = 2))

		-- phan biet vao ra ma bam sai thi bi tru
		UPDATE s
		SET RatioMatch = RatioMatch - (WorkEndMi - WorkStartMi)
		FROM #tblShiftDetector_NeedUpdate s
		WHERE (StateIn <> 1 OR StateOut <> 2)

		-- exists (select 1 from #tblTmpAttend t where s.EmployeeId = t.EmployeeID and s.AttStart = t.AttTime and t.AttState = 1) -- khớp vào
		--and exists (select 1 from #tblTmpAttend t where s.EmployeeId = t.EmployeeID and s.AttEnd = t.AttTime and t.AttState = 2) -- khớp ra
		-- neu thieu vao ra ma lai lech in out thi bo
		UPDATE s
		SET RatioMatch = RatioMatch - 500
		FROM #tblShiftDetector_NeedUpdate s
		WHERE AttEnd IS NULL AND AttStart IS NOT NULL AND EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE s.EmployeeId = t.EmployeeID AND s.AttStart = t.AttTime AND t.AttState IN (0, 2)
				)

		UPDATE s
		SET RatioMatch = RatioMatch - 500
		FROM #tblShiftDetector_NeedUpdate s
		WHERE AttStart IS NULL AND AttEnd IS NOT NULL AND EXISTS (
				SELECT 1
				FROM #tblTmpAttend t
				WHERE s.EmployeeId = t.EmployeeID AND s.AttEnd = t.AttTime AND t.AttState IN (0, 1)
				)
	END

	UPDATE u
	SET RatioMatch = - 6000
	FROM #tblShiftDetector_NeedUpdate u
	WHERE isNightShift = 1 AND StdWorkingTimeMi > 569 AND abs(OutInterval) < 15 AND InInterval > 90

	-- ca dem bam vao sai, hoac khong bao vao, ma hom truoc khong di ca dem
	UPDATE u
	SET RatioMatch = - 6000
	FROM #tblShiftDetector_NeedUpdate u
	WHERE isNightShift = 1 AND abs(InInterval) > 300 AND ShiftCode <> ShiftCodeYesterday

	-- sai ca qua troi sai
	UPDATE u
	SET RatioMatch = - 6000
	FROM #tblShiftDetector_NeedUpdate u
	WHERE AttStart IS NOT NULL AND AttEnd IS NOT NULL AND ((abs(InInterval) > 90 AND (abs(OutInterval) > 420) AND @IgnoreTimeOut_ShiftDetector = 0) OR (abs(OutInterval) > 90 AND abs(InInterval) > 420))

	-- cùng điểm ưu tiên trường hợp có giờ vào ra hơn
	UPDATE d
	SET RatioMatch = d.RatioMatch + 10
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN (
		SELECT EmployeeId, ScheduleDate, RatioMatch
		FROM #tblShiftDetector_NeedUpdate ta1
		GROUP BY EmployeeId, ScheduleDate, RatioMatch
		) ta1 ON d.EmployeeId = ta1.EmployeeId AND d.ScheduleDate = ta1.ScheduleDate
	WHERE d.RatioMatch > 499 AND d.AttStart IS NOT NULL AND d.AttEnd IS NOT NULL

	-- Nếu cùng điểm thì ưu tiên ca dài trước, nhung d? sau đợi các ca khác lên điểm rồi tính toán lại ca hôm trước,
	IF (@RepeatTime > 50)
		UPDATE d
		SET RatioMatch = RatioMatch + 10 * s.ShiftHours
		FROM #tblShiftDetector_NeedUpdate d
		INNER JOIN #tblShiftSetting s ON d.ShiftCode = s.ShiftCode
		WHERE EXISTS (
				SELECT 1
				FROM (
					SELECT d1.EmployeeId, d1.ScheduleDate
					FROM #tblShiftDetector_NeedUpdate d1
					INNER JOIN #tblShiftDetector_NeedUpdate d2 ON d1.EmployeeId = d2.EmployeeId AND d1.ScheduleDate = d2.ScheduleDate AND d1.RatioMatch = d2.RatioMatch AND d1.ShiftCode <> d2.ShiftCode
					) tmp
				WHERE tmp.EmployeeId = d.EmployeeId AND tmp.ScheduleDate = d.ScheduleDate
				)

	--xử lý t/h người dùng nhập 2 ca khác code mà giờ vào, giờ ra, giờ nghỉ giống hệt nhau
	UPDATE d
	SET RatioMatch = RatioMatch + s.STT
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblShiftSetting s ON d.ShiftCode = s.ShiftCode
	WHERE EXISTS (
			SELECT 1
			FROM (
				SELECT d1.EmployeeId, d1.ScheduleDate
				FROM #tblShiftDetector_NeedUpdate d1
				INNER JOIN #tblShiftDetector_NeedUpdate d2 ON d1.EmployeeId = d2.EmployeeId AND d1.ScheduleDate = d2.ScheduleDate AND d1.RatioMatch = d2.RatioMatch AND d1.ShiftCode <> d2.ShiftCode AND d1.WorkStart = d2.WorkStart AND d1.WorkEnd = d2.WorkEnd AND d1.AttStart = d2.AttStart AND d1.AttEnd = d2.AttEnd
				) tmp
			WHERE tmp.EmployeeId = d.EmployeeId AND tmp.ScheduleDate = d.ScheduleDate
			)

	UPDATE d
	SET RatioMatch = RatioMatch + s.STT
	FROM #tblShiftDetector_NeedUpdate d
	INNER JOIN #tblShiftSetting s ON d.ShiftCode = s.ShiftCode
	WHERE d.RatioMatch < 1000

	IF (OBJECT_ID('sp_ShiftDetector_BloomFlavour') IS NULL)
	BEGIN
		EXEC (
				'CREATE PROCEDURE dbo.sp_ShiftDetector_BloomFlavour
(
 @StopUpdate bit output
 ,@LoginID int
 ,@FromDate datetime
 ,@ToDate datetime
)
as
begin
SET NOCOUNT ON;
end'
				)
	END

	SET @StopUpdate = 0

	-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
	EXEC sp_ShiftDetector_BloomFlavour @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

	IF @StopUpdate = 0
	BEGIN
		-- hoa toa huong lan nua
		TRUNCATE TABLE #tblBloomFlavour

		INSERT INTO #tblBloomFlavour (EmployeeId, ScheduleDate, RatioMatch, STT)
		SELECT d.EmployeeId, d.ScheduleDate, max(RatioMatch) RatioMatch, ROW_NUMBER() OVER (
				PARTITION BY EmployeeID ORDER BY EmployeeId, ScheduleDate
				) STT
		FROM (
			SELECT *
			FROM #tblShiftDetector
			WHERE AttEndMi - AttStartMi > 660 AND StdWorkingTimeMi > 500
			
			UNION ALL
			
			SELECT *
			FROM #tblShiftDetector_NeedUpdate
			WHERE AttEndMi - AttStartMi > 660 AND StdWorkingTimeMi > 500
			) d
		GROUP BY d.EmployeeId, d.ScheduleDate

		--LongKa: hôm qua ko có giờ công, hôm nay có đầy đủ thì cung dua vào luôn
		INSERT INTO #tblBloomFlavour (EmployeeId, ScheduleDate, RatioMatch, STT)
		SELECT n.EmployeeId, n.ScheduleDate, (max(n.RatioMatch) + 500) RatioMatch, 100
		FROM #tblShiftDetector_NeedUpdate n
		INNER JOIN #tblWSchedule ws ON n.EmployeeId = ws.EmployeeID AND n.ScheduleDate = ws.ScheduleDate
		WHERE NOT EXISTS (
				SELECT 1
				FROM #tblShiftDetector_NeedUpdate y
				WHERE ws.EmployeeID = y.EmployeeId AND y.ScheduleDate = ws.PrevDate AND y.AttStart IS NOT NULL AND y.AttEnd IS NOT NULL
				) AND NOT EXISTS (
				SELECT 1
				FROM #tblBloomFlavour b
				WHERE n.EmployeeId = b.EmployeeId AND n.ScheduleDate = b.ScheduleDate
				) AND AttEndMi - AttStartMi > 480
		GROUP BY n.EmployeeId, n.ScheduleDate

		UPDATE ta1
		SET ToDate = (
				SELECT min(ScheduleDate)
				FROM (
					SELECT EmployeeId, ScheduleDate
					FROM #tblBloomFlavour ta1
					WHERE NOT EXISTS (
							SELECT 1
							FROM #tblBloomFlavour ta2
							WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate = ta2.ScheduleDate - 1
							)
					) ta2
				WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate <= ta2.ScheduleDate
				), FromDate = (
				SELECT max(ScheduleDate)
				FROM (
					SELECT EmployeeId, ScheduleDate
					FROM #tblBloomFlavour ta1
					WHERE NOT EXISTS (
							SELECT 1
							FROM #tblBloomFlavour ta2
							WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate = ta2.ScheduleDate + 1
							)
					) ta2
				WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate >= ta2.ScheduleDate
				)
		FROM #tblBloomFlavour ta1

		UPDATE d
		SET RatioMatch = RatioMatch - 200
		FROM #tblShiftDetector_NeedUpdate d
		WHERE EXISTS (
				SELECT 1
				FROM #tblBloomFlavour b
				WHERE b.ScheduleDate > b.FromDate AND b.ScheduleDate <= b.ToDate AND b.EmployeeId = d.EmployeeId AND b.ScheduleDate = d.ScheduleDate
				)
	END

	IF @ProcessOrderByDate_ShiftDetector = 0
	BEGIN
		-- khong co gio vao , gio ra thi nhan ca do sau cung
		UPDATE u
		SET RatioMatch = tmp.RatioMatch
		FROM #tblShiftDetector_NeedUpdate u
		INNER JOIN (
			SELECT EmployeeId, ScheduleDate, MIN(RatioMatch) - 200 RatioMatch
			FROM #tblShiftDetector_NeedUpdate m
			WHERE m.AttStart IS NOT NULL OR m.AttEnd IS NOT NULL
			GROUP BY EmployeeId, ScheduleDate
			) tmp ON u.EmployeeId = tmp.EmployeeId AND u.ScheduleDate = tmp.ScheduleDate
		WHERE u.AttStart IS NULL AND u.AttEnd IS NULL AND u.HolidayStatus = 0 AND DATEDIFF(day, u.ScheduleDate, @getdate) > 1
	END

	----------------------- Hot hui thoi nao-------------------------------
	--Select * from #tblShiftDetector_NeedUpdate order by ScheduleDate
	--Select 123,AttStartTomorrow,AttEndYesterday,* from #tblShiftDetector_NeedUpdate order by ScheduleDate return
	--delete from #tblShiftDetector_NeedUpdate where AttEnd is null and AttStart is null and @ProcessOrderByDate_ShiftDetector = 1
	TRUNCATE TABLE #tblPrevMatch

	TRUNCATE TABLE #tblPrevRemove

	INSERT INTO #tblShiftDetector
	SELECT *
	FROM #tblShiftDetector_NeedUpdate

	IF @ProcessOrderByDate_ShiftDetector = 0
	BEGIN
		INSERT INTO #tblPrevMatch (EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3)
		SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3
		FROM (
			INSERT INTO #tblShiftDetectorMatched
			OUTPUT inserted.EmployeeId, inserted.ShiftCode, inserted.ScheduleDate, inserted.AttStart, inserted.AttEnd, inserted.isNightShift, inserted.HolidayStatus, inserted.IsLeaveStatus3
			SELECT m.*
			FROM #tblShiftDetector m
			INNER JOIN (
				SELECT sd.employeeID, sd.ScheduleDate, max(sd.RatioMatch) AS MaxRatioMatch
				FROM #tblShiftDetector sd
				INNER JOIN (
					SELECT EmployeeId, max(RatioMatch) MaxRatioMatch
					FROM #tblShiftDetector
					GROUP BY EmployeeId
					) ratMax ON sd.EmployeeId = ratmax.EmployeeId AND (sd.RatioMatch = ratMax.MaxRatioMatch)
				GROUP BY sd.EmployeeId, sd.ScheduleDate
				) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.RatioMatch = tmp.MaxRatioMatch
			) tmp
	END
	ELSE
	BEGIN
		INSERT INTO #tblPrevMatch (EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3)
		SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3
		FROM (
			INSERT INTO #tblShiftDetectorMatched
			OUTPUT inserted.EmployeeId, inserted.ShiftCode, inserted.ScheduleDate, inserted.AttStart, inserted.AttEnd, inserted.isNightShift, inserted.HolidayStatus, inserted.IsLeaveStatus3
			SELECT m.*
			FROM #tblShiftDetector m
			INNER JOIN (
				SELECT sd.employeeID, sd.ScheduleDate, max(sd.RatioMatch) AS MaxRatioMatch
				FROM #tblShiftDetector sd
				INNER JOIN (
					SELECT EmployeeId, min(ScheduleDate) ScheduleDate
					FROM #tblShiftDetector
					GROUP BY EmployeeId
					) ratMax ON sd.EmployeeId = ratmax.EmployeeId AND (sd.ScheduleDate = ratMax.ScheduleDate)
				GROUP BY sd.EmployeeId, sd.ScheduleDate
				) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.RatioMatch = tmp.MaxRatioMatch
			) tmp
	END

	-- Lặp nhìu lần
	IF ROWCOUNT_BIG() > 0
	BEGIN
		/*print 'x--------------------------------------------------------x38'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		INSERT INTO #tblPrevRemove (EmployeeId, ScheduleDate, ShiftCode)
		SELECT *
		FROM (
			DELETE ta1
			OUTPUT deleted.EmployeeId, deleted.ScheduleDate, deleted.ShiftCode
			FROM #tblShiftDetectorMatched ta1
			WHERE ta1.RatioMatch = 0 AND EXISTS (
					SELECT 1
					FROM #tblShiftDetectorMatched ta2
					WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate = ta2.ScheduleDate AND ta2.ShiftCode > ta1.ShiftCode
					)
			) tmp

		-- loại những nhân viên lấy giờ  ra hôm trước làm giờ vào hôm nay
		INSERT INTO #tblPrevRemove (EmployeeId, ScheduleDate)
		SELECT EmployeeId, ScheduleDate
		FROM (
			DELETE m2
			OUTPUT deleted.EmployeeId, deleted.ScheduleDate
			FROM #tblShiftDetectorMatched m1
			INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1 AND m1.AttEnd = m2.AttStart AND isnull(m1.StateOut, 1) = 2
			) tmp

		/*print 'x--------------------------------------------------------x39'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		DELETE ta1
		FROM #tblPrevMatch ta1
		INNER JOIN #tblPrevRemove ta2 ON ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate = ta2.ScheduleDate AND ta1.ShiftCode = ta2.ShiftCode

		TRUNCATE TABLE #tblPrevRemove

		DELETE D
		FROM #tblShiftDetector D
		WHERE EXISTS (
				SELECT 1
				FROM #tblPrevMatch M
				WHERE M.EmployeeId = D.EmployeeId AND M.ScheduleDate = D.ScheduleDate
				)

		UPDATE #tblPrevMatch
		SET PrevDate = dateadd(day, - 1, ScheduleDate), NextDate = dateadd(day, 1, ScheduleDate)

		-- tính toán lại nhìu lần
		TRUNCATE TABLE #tblShiftDetector_NeedUpdate

		INSERT INTO #tblShiftDetector_NeedUpdate
		SELECT *
		FROM (
			DELETE ta1
			OUTPUT deleted.*
			FROM #tblShiftDetector ta1
			WHERE EXISTS (
					SELECT 1
					FROM #tblPrevMatch ta2
					WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate IN (PrevDate, NextDate)
					)
			) tmp

		/*print 'x--------------------------------------------------------x40'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		UPDATE #tblShiftDetectorMatched
		SET AttStart = NULL, AttEnd = NULL
		WHERE @LEAVEFULLDAYSTILLHASATTTIME = 0 AND IsLeaveStatus3 = 1 AND HolidayStatus = 0

		UPDATE ta1
		SET RatioMatch = 0, AttStart = CASE 
				WHEN FixedAtt = 1
					THEN AttStart
				ELSE NULL
				END, AttEnd = CASE 
				WHEN FixedAtt = 1
					THEN AttEnd
				ELSE NULL
				END, AttStartTomorrow = CASE 
				WHEN AttStartTomorrowFixedTblHasta = 1
					THEN AttStartTomorrow
				ELSE NULL
				END, AttEndYesterday = CASE 
				WHEN AttEndYesterdayFixedTblHasta = 1
					THEN AttEndYesterday
				ELSE NULL
				END, InInterval = NULL, OutInterval = NULL, WorkingTimeMi = NULL, AttStartMi = NULL, AttEndMi = NULL
		FROM #tblShiftDetector_NeedUpdate ta1

		INSERT INTO #tblPrevMatch (EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, Prevdate, NextDate)
		SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, dateadd(day, - 1, ScheduleDate), dateadd(day, 1, ScheduleDate)
		FROM #tblShiftDetectorMatched prev
		WHERE --not exists(select 1 from #tblShiftDetector ta2 where NeedUpdate = 1 and ta2.EmployeeId = prev.EmployeeId) and
			EmployeeId IN (
				SELECT EmployeeId
				FROM #tblShiftDetector
				
				EXCEPT
				
				SELECT EmployeeId
				FROM #tblShiftDetector_NeedUpdate ta2
				)

		INSERT INTO #tblShiftDetector_NeedUpdate
		SELECT *
		FROM (
			DELETE ta1
			OUTPUT deleted.*
			FROM #tblShiftDetector ta1
			WHERE EmployeeId IN (
					SELECT EmployeeId
					FROM #tblShiftDetector
					
					EXCEPT
					
					SELECT EmployeeId
					FROM #tblShiftDetector_NeedUpdate ta2
					)
			) tmp

		UPDATE ta1
		SET RatioMatch = 0, AttStart = CASE 
				WHEN FixedAtt = 1
					THEN AttStart
				ELSE NULL
				END, AttEnd = CASE 
				WHEN FixedAtt = 1
					THEN AttEnd
				ELSE NULL
				END, AttStartTomorrow = CASE 
				WHEN AttStartTomorrowFixedTblHasta = 1
					THEN AttStartTomorrow
				ELSE NULL
				END, AttEndYesterday = CASE 
				WHEN AttEndYesterdayFixedTblHasta = 1
					THEN AttEndYesterday
				ELSE NULL
				END, InInterval = NULL, OutInterval = NULL, isWrongShift = NULL --,NeedUpdate = 1
		FROM #tblShiftDetector_NeedUpdate ta1

		/*print 'x--------------------------------------------------------x41'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())

print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		TRUNCATE TABLE #tblPrevMatch

		INSERT INTO #tblPrevMatch (EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, Prevdate, NextDate)
		SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, dateadd(day, - 1, ScheduleDate), dateadd(day, 1, ScheduleDate)
		FROM #tblShiftDetectorMatched ta1
		WHERE EXISTS (
				SELECT 1
				FROM #tblShiftDetector_NeedUpdate ta2
				WHERE ta1.EmployeeId = ta2.EmployeeId AND ta1.ScheduleDate IN (dateadd(day, 1, ta2.ScheduleDate), dateadd(day, - 1, ta2.ScheduleDate))
				)

		/*print 'x--------------------------------------------------------x42'
set @count =DATEdiff(MILLISECOND,@sysDatetime,SYSDATETIME())
print @count set @sysDatetime = SYSDATETIME()
print 'z--------------------------------------------------------z'*/
		SET @RepeatTime += 1

		GOTO StartRepeat
	END

	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, dateadd(HOUR, - 10, m1.WorkStart))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate + 1
	WHERE m2.AttEnd IS NOT NULL

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
	WHERE m2.AttStart IS NOT NULL AND m2.AttEnd IS NOT NULL

	UPDATE #tblShiftDetectorMatched
	SET FixedAtt = 0
	WHERE FixedAtt IS NULL

	UPDATE m1
	SET AttEndYesterday = dateadd(hour, - 16, m1.WorkStart)
	FROM #tblShiftDetectorMatched m1
	WHERE m1.AttEndYesterdayFixed = 1 AND m1.AttEndYesterday < dateadd(hour, - 16, m1.WorkStart)

	UPDATE m1
	SET AttStartTomorrow = dateadd(hour, 16, m1.WorkEnd)
	FROM #tblShiftDetectorMatched m1
	WHERE m1.AttStartTomorrowFixed = 1 AND m1.AttStartTomorrow > dateadd(hour, 16, m1.WorkEnd)

	-- chinh ly lai gio vao ra sau khi da nhan ca chinh xac
	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, MIN(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE FixedAtt = 0 AND (ForceState = 0 OR AttState = 1)
			--and Approved is null tri:bo nay di vi duyet ca thi k lien quan gi ts viec sua vao - ra
			AND (t.AttTime < dateadd(mi, - 1 * m.INOUT_MINIMUM, m.AttEnd) OR m.AttEnd IS NULL) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TimeinBefore AND m.TIMEOUTAFTER
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE FixedAtt = 0 AND (ForceState = 0 OR AttState = 2)
			--and Approved is null
			AND t.AttTime > isnull(m.AttEnd, m.AttStart) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.TimeinBefore AND m.TIMEOUTAFTER AND (datediff(mi, m.AttStart, t.AttTime) >= m.INOUT_MINIMUM OR m.AttStart IS NULL)
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	-- xử lý lại những ca nhận với độ chính xác cao nhung nếu nhận ca đó sẽ làm mất dữ liệu chấm công --> ca dó không dúng
	-- Re_Process
	UPDATE m1
	SET AttEndYesterday = isnull(m2.AttEnd, dateadd(HOUR, - 10, m1.WorkStart))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate + 1
	WHERE m2.AttEnd IS NOT NULL

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
	WHERE m2.AttStart IS NOT NULL AND m1.AttEnd <> m2.AttStart

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, DATEADD(hour, 16, m1.WorkEnd))
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblHasTA m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.Attdate - 1
	WHERE m1.AttStartTomorrow IS NULL

	UPDATE #tblShiftDetectorMatched
	SET FixedAtt = 0
	WHERE FixedAtt IS NULL

	UPDATE m1
	SET AttEndYesterday = dateadd(hour, - 16, m1.WorkStart)
	FROM #tblShiftDetectorMatched m1
	WHERE m1.AttEndYesterdayFixed = 1 AND m1.AttEndYesterday < dateadd(hour, - 16, m1.WorkStart)

	UPDATE m1
	SET AttStartTomorrow = dateadd(hour, 16, m1.WorkEnd)
	FROM #tblShiftDetectorMatched m1
	WHERE m1.AttStartTomorrowFixed = 1 AND m1.AttStartTomorrow > dateadd(hour, 16, m1.WorkEnd)

	IF @IN_OUT_TA_SEPARATE = 1
		SET @Re_Process = 4

	IF (OBJECT_ID('sp_ShiftDetector_Re_Process') IS NULL)
		EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_Re_Process ( @StopUpdate bit output ,@LoginID int ,@FromDate datetime ,@ToDate datetime ) as begin SET NOCOUNT ON; end')

	SET @StopUpdate = 0

	-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
	EXEC sp_ShiftDetector_Re_Process @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

	SET @StopUpdate = 1

	IF @Re_Process < 2 AND @StopUpdate = 0
	BEGIN
		SET @Re_Process = @Re_Process + 1

		-- xu ly lai
		-- xac dinh nhung dong can xu ly lai ca
		-- xác d?nh nh?ng dòng c?n x? lý l?i ca
		-- EmployeeId,ScheduleDate,HolidayStatus,ShiftCode,ShiftCodeWrong
		TRUNCATE TABLE #tblShiftDetectorReprocess

		INSERT INTO #tblShiftDetectorReprocess (STT, EmployeeId, ScheduleDate, ShiftCode)
		SELECT ROW_NUMBER() OVER (
				PARTITION BY m1.EmployeeId ORDER BY m1.EmployeeId, m1.ScheduleDate
				) Ord, m1.EmployeeId, m1.ScheduleDate, m1.ShiftCode
		FROM #tblShiftDetectorMatched m1
		INNER JOIN #tblShiftDetectorMatched m2 ON m1.employeeId = m2.EmployeeID AND m1.ScheduleDate = m2.ScheduleDate - 1
		WHERE (
				EXISTS (
					SELECT 1
					FROM #tblTmpAttend t
					WHERE m2.EmployeeId = t.EmployeeID AND m1.EmployeeId = t.EmployeeID AND t.AttTime < dateadd(hour, 12, m1.WorkEnd) AND t.AttTime BETWEEN dateadd(mi, 60, isnull(m1.AttEnd, m1.WorkEnd)) AND dateadd(mi, - 60, isnull(m2.AttStart, m2.WorkEnd))
					) AND isnull(m1.Approved, 0) = 0 AND isnull(m2.Approved, 0) = 0
				) OR (
				EXISTS (
					SELECT 1
					FROM #tblShiftDetectorMatched n
					WHERE m1.EmployeeId = n.EmployeeId AND m1.ScheduleDate = n.ScheduleDate - 1 AND n.HolidayStatus > 0 AND n.AttStart IS NULL AND n.AttEnd IS NULL
					) AND EXISTS (
					SELECT 1
					FROM #tblTmpAttend t
					WHERE t.EmployeeID = m1.EmployeeId AND t.AttTime BETWEEN DATEADD(mi, 60, isnull(m1.AttEnd, m1.WorkEnd)) AND DATEADD(HH, 22, m1.AttEnd)
					)
				)

		INSERT INTO #tblShiftDetectorReprocess (STT, EmployeeId, ScheduleDate, ShiftCode)
		SELECT ROW_NUMBER() OVER (
				PARTITION BY m1.EmployeeId ORDER BY m1.EmployeeId, m1.ScheduleDate
				) Ord, m1.EmployeeId, m2.ScheduleDate, m2.ShiftCode
		FROM #tblShiftDetectorMatched m1
		INNER JOIN #tblShiftDetectorMatched m2 ON m1.employeeId = m2.EmployeeID AND m1.ScheduleDate = m2.ScheduleDate - 1
		WHERE (
				EXISTS (
					SELECT 1
					FROM #tblTmpAttend t
					WHERE m2.EmployeeId = t.EmployeeID AND m1.EmployeeId = t.EmployeeID AND t.AttTime >= dateadd(hour, 12, m1.WorkEnd) AND t.AttTime BETWEEN dateadd(mi, 60, isnull(m1.AttEnd, m1.WorkEnd)) AND dateadd(mi, - 60, isnull(m2.AttStart, m2.WorkEnd))
					) AND isnull(m1.Approved, 0) = 0 AND isnull(m2.Approved, 0) = 0
				)

		--update p2 set AttEndYesterday = p1.ScheduleDate from #tblShiftDetectorReprocess p1 inner join #tblShiftDetectorReprocess p2 on p1.employeeID = p2.EmployeeID and p1.Stt = p2.Stt-1
		--update #tblShiftDetectorReprocess set AttEndYesterday = dateadd(day,-20,Scheduledate) where AttEndYesterday is null
		UPDATE p
		SET WorkStart = tmp.WorkStart
		FROM #tblShiftDetectorReprocess p
		INNER JOIN (
			SELECT max(m.ScheduleDate) WorkStart, p.EmployeeId, p.ScheduleDate
			FROM #tblShiftDetectorReprocess p
			INNER JOIN #tblShiftDetectorMatched m ON p.EmployeeId = m.EmployeeId AND m.ScheduleDate < p.ScheduleDate AND m.ScheduleDate > DATEADD(day, - 7, p.ScheduleDate) AND (m.AttStart IS NULL AND AttEnd IS NOT NULL) -- and m.AttEnd is not null
			GROUP BY p.EmployeeId, p.ScheduleDate
			) tmp ON p.EmployeeId = tmp.EmployeeId AND p.ScheduleDate = tmp.ScheduleDate

		UPDATE p
		SET WorkStart = tmp.WorkStart
		FROM #tblShiftDetectorReprocess p
		INNER JOIN (
			SELECT max(m.ScheduleDate) WorkStart, p.EmployeeId, p.ScheduleDate
			FROM #tblShiftDetectorReprocess p
			INNER JOIN #tblShiftDetectorMatched m ON p.EmployeeId = m.EmployeeId AND m.ScheduleDate < p.ScheduleDate AND m.ScheduleDate > DATEADD(day, - 7, p.ScheduleDate) AND (m.AttEnd IS NULL) AND m.AttStart IS NOT NULL
			GROUP BY p.EmployeeId, p.ScheduleDate
			) tmp ON p.EmployeeId = tmp.EmployeeId AND p.ScheduleDate = tmp.ScheduleDate AND p.WorkStart IS NULL

		UPDATE p
		SET WorkEnd = tmp.WorkEnd
		FROM #tblShiftDetectorReprocess p
		INNER JOIN (
			SELECT min(m.ScheduleDate) WorkEnd, p.EmployeeId, p.ScheduleDate
			FROM #tblShiftDetectorReprocess p
			INNER JOIN #tblShiftDetectorMatched m ON p.EmployeeId = m.EmployeeId AND m.ScheduleDate > p.ScheduleDate AND m.ScheduleDate < DATEADD(day, 7, p.ScheduleDate) AND (m.AttEnd IS NULL) --m.AttStart is not null and
			GROUP BY p.EmployeeId, p.ScheduleDate
			) tmp ON p.EmployeeId = tmp.EmployeeId AND p.ScheduleDate = tmp.ScheduleDate

		UPDATE p
		SET WorkEnd = tmp.WorkEnd
		FROM #tblShiftDetectorReprocess p
		INNER JOIN (
			SELECT min(m.ScheduleDate) WorkEnd, p.EmployeeId, p.ScheduleDate
			FROM #tblShiftDetectorReprocess p
			INNER JOIN #tblShiftDetectorMatched m ON p.EmployeeId = m.EmployeeId AND m.ScheduleDate > p.ScheduleDate AND m.ScheduleDate < DATEADD(day, 7, p.ScheduleDate) AND (m.AttStart IS NULL) -- and m.AttEnd is not null
			GROUP BY p.EmployeeId, p.ScheduleDate
			) tmp ON p.EmployeeId = tmp.EmployeeId AND p.ScheduleDate = tmp.ScheduleDate AND p.WorkEnd IS NULL

		---- do?n này dang x? lý sai
		--update #tblShiftDetectorReprocess set WorkStart = tmp.ScheduleDateM from #tblShiftDetectorReprocess p inner join (
		--select m.EmployeeID,p.ScheduleDate, max(m.ScheduleDate) ScheduleDateM
		--from #tblShiftDetectorReprocess p inner join #tblShiftDetectorMatched m on p.EmployeeId = m.EmployeeId and m.ScheduleDate between p.AttEndYesterday and p.ScheduleDate
		--where (m.AttStart is null and m.AttEnd is not null) or (m.AttStart is not null and m.AttEnd is null)
		--group by m.EmployeeID,p.ScheduleDate
		--) tmp on p.EmployeeId = tmp.EmployeeId and p.ScheduleDate = tmp.ScheduleDate
		UPDATE #tblShiftDetectorReprocess
		SET WorkStart = DATEADD(day, 1, ScheduleDate)
		WHERE WorkStart IS NULL AND WorkEnd IS NOT NULL

		UPDATE #tblShiftDetectorReprocess
		SET WorkEnd = ScheduleDate
		WHERE WorkEnd IS NULL AND WorkStart IS NOT NULL

		UPDATE #tblShiftDetectorReprocess
		SET WorkStart = ScheduleDate, WorkEnd = ScheduleDate
		WHERE WorkEnd IS NULL AND WorkStart IS NULL

		IF EXISTS (
				SELECT 1
				FROM #tblShiftDetectorReprocess
				)
		BEGIN
			INSERT INTO #tblShiftDetector (EmployeeId, ScheduleDate, HolidayStatus, ShiftCode, RatioMatch, EmployeeStatusID)
			SELECT m1.EmployeeId, m1.ScheduleDate, m1.HolidayStatus, sg.ShiftCode, 0, m1.EmployeeStatusID
			FROM #tblShiftDetectorMatched m1
			INNER JOIN #tblShiftGroupCode c ON m1.EmployeeId = c.EmployeeID
			FULL OUTER JOIN #tblShiftGroup_Shift sg ON c.ShiftGroupCode = sg.ShiftGroupID
			WHERE EXISTS (
					SELECT 1
					FROM #tblShiftDetectorReprocess p
					WHERE p.EmployeeId = m1.EmployeeId AND m1.ScheduleDate BETWEEN p.WorkStart AND p.WorkEnd
					) AND sg.ShiftCode IS NOT NULL AND m1.EmployeeId IS NOT NULL AND m1.ScheduleDate BETWEEN c.FromDate AND c.ToDate

			INSERT INTO #tblShiftDetector (EmployeeId, ScheduleDate, HolidayStatus, ShiftCode, RatioMatch, EmployeeStatusID)
			SELECT m1.EmployeeId, m1.ScheduleDate, m1.HolidayStatus, sg.ShiftCode, 0, m1.EmployeeStatusID
			FROM #tblShiftDetectorMatched m1
			CROSS JOIN (
				SELECT ShiftCode
				FROM #tblShiftSetting
				GROUP BY ShiftCode
				) sg
			WHERE EXISTS (
					SELECT 1
					FROM #tblShiftDetectorReprocess p
					WHERE p.EmployeeId = m1.EmployeeId AND m1.ScheduleDate BETWEEN p.WorkStart AND p.WorkEnd
					) AND NOT EXISTS (
					SELECT 1
					FROM #tblShiftDetector t
					WHERE m1.EmployeeID = t.EmployeeID AND m1.ScheduleDate = t.ScheduleDate
					)

			-- bo het ca bi sai di
			DELETE m
			FROM #tblShiftDetector m
			WHERE EXISTS (
					SELECT 1
					FROM #tblShiftDetectorMatched d
					WHERE d.employeeID = m.employeeID AND m.ScheduleDate = d.ScheduleDate AND m.shiftCode = d.ShiftCode
					)

			DELETE m
			FROM #tblShiftDetectorMatched m
			WHERE EXISTS (
					SELECT 1
					FROM #tblShiftDetector d
					WHERE d.employeeID = m.employeeID AND d.ScheduleDate = m.ScheduleDate
					)

			-- select * from #tblShiftDetector order by ScheduleDate
			--select * from #tblShiftDetectorMatched order by ScheduleDate
			--select * from #tblShiftDetectorReprocess order by ScheduleDate
			SET @RepeatTime = 0

			TRUNCATE TABLE #tblPrevMatch

			INSERT INTO #tblPrevMatch (EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, Prevdate, NextDate)
			SELECT EmployeeId, ShiftCode, ScheduleDate, AttStart, AttEnd, isNightShift, HolidayStatus, IsLeaveStatus3, DATEADD(day, - 1, ScheduleDate), DATEADD(day, 1, ScheduleDate)
			FROM #tblShiftDetectorMatched

			--set @MaxRatioMatch = null
			GOTO StartShiftDetector
		END
	END
END

-- ket thuc nhan dang ca
UPDATE d
SET ShiftID = s.ShiftID
--,s.WorkstartMi,s.WorkendMi,s.AttStartMi,s.AttEndMi,s.BreakEndMi,s.BreakStartMi
FROM #tblShiftDetectorMatched d
INNER JOIN tblShiftSetting s ON d.ShiftCode = s.ShiftCode AND DATEPART(dw, d.ScheduleDate) = s.WeekDays
WHERE DATEPART(hh, s.WorkStart) <> DATEPART(hh, s.WorkEnd)

-- xu ly tinh chinh nhung ca khac gio vao, gio ra (vi du T7 lam nua ngay)
--update d set ShiftID = s.ShiftID
--,s.WorkstartMi,s.WorkendMi,s.AttStartMi,s.AttEndMi,s.BreakEndMi,s.BreakStartMi
UPDATE d
SET d.WorkstartMi = DATEPART(hh, s.WorkStart) * 60 + DATEPART(mi, s.WorkStart), d.WorkendMi = CASE 
		WHEN DATEPART(hh, s.WorkStart) > DATEPART(hh, s.WorkEnd)
			THEN 1440
		ELSE 0
		END + DATEPART(hh, s.WorkEnd) * 60 + DATEPART(mi, s.WorkEnd), d.BreakEndMi = CASE 
		WHEN DATEPART(hh, s.WorkStart) > DATEPART(hh, s.BreakEnd)
			THEN 1440
		ELSE 0
		END + DATEPART(hh, s.BreakEnd) * 60 + DATEPART(mi, s.BreakEnd), d.BreakStartMi = CASE 
		WHEN DATEPART(hh, s.WorkStart) > DATEPART(hh, s.BreakStart)
			THEN 1440
		ELSE 0
		END + DATEPART(hh, s.BreakStart) * 60 + DATEPART(mi, s.BreakStart)
FROM #tblShiftDetectorMatched d
INNER JOIN tblShiftSetting s ON d.ShiftID = s.ShiftID
WHERE (DATEPART(hh, s.WorkStart) <> DATEPART(hh, d.WorkStart) OR DATEPART(hh, s.WorkEnd) <> DATEPART(hh, d.WorkEnd))

UPDATE d
SET ShiftID = s.ShiftID
FROM #tblShiftDetectorMatched d
INNER JOIN #tblShiftSetting s ON d.ShiftCode = s.ShiftCode
WHERE d.ShiftID IS NULL -- and s.ShiftID is not null

-- process duplicate shift code
-- uu tien ca hom qua giong hom nay, sau roi den do dai cua ca, roi de thu tu cua ca
-- Set priority for the same ShiftCode as Yesterday code, then for the long of working shift, final is Shift order number
-- khong hieu doian nay dung de lam gi,khi ma viec nhan dang ca da xong roi
--select m.EmployeeID, m.ScheduleDate, max(Case when ShiftCode = ShiftCodeYesterday then 1000 else 0 end + isnull(StdWorkingTimeMi,0) + ISNULL(ShiftID,0)) as Max
UPDATE m
SET RatioMatch = 100001 + CASE 
		WHEN ShiftCode = ShiftCodeYesterday
			THEN 1000
		ELSE 0
		END + isnull(StdWorkingTimeMi, 0) + ISNULL(ShiftID, 0)
FROM #tblShiftDetectorMatched m
WHERE EXISTS (
		SELECT 1
		FROM #tblShiftDetectorMatched d
		WHERE m.EmployeeId = d.EmployeeId AND m.ScheduleDate = d.ScheduleDate
		GROUP BY d.EmployeeId, d.ScheduleDate
		HAVING COUNT(1) > 1
		)

DELETE m
FROM #tblShiftDetectorMatched m
WHERE EXISTS (
		SELECT 1
		FROM #tblShiftDetectorMatched d
		WHERE d.RatioMatch > 100000 AND m.EmployeeId = d.EmployeeId AND m.ScheduleDate = d.ScheduleDate AND d.RatioMatch > m.RatioMatch
		)

UPDATE tblWSchedule
SET HolidayStatus = b.HolidayStatus
FROM tblWSchedule a
INNER JOIN #tblShiftDetectorMatched b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.ScheduleDate
WHERE NOT EXISTS (
		SELECT 1
		FROM #tblWSchedule c
		WHERE a.EmployeeID = c.EmployeeID AND a.ScheduleDate = c.ScheduleDate AND c.ApprovedHolidayStatus = 1
		) AND a.HolidayStatus <> b.HolidayStatus

UPDATE #tblWSchedule
SET HolidayStatus = b.HolidayStatus
FROM #tblWSchedule a
INNER JOIN #tblShiftDetectorMatched b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.ScheduleDate
WHERE a.HolidayStatus <> b.HolidayStatus AND ISNULL(a.ApprovedHolidayStatus, 0) = 0

INSERT INTO #tblWschedule (EmployeeID, ScheduleDate, ShiftID, HolidayStatus, DateStatus, Approved)
SELECT *
FROM (
	INSERT INTO tblWSchedule (EmployeeID, ScheduleDate, ShiftID, HolidayStatus, DateStatus, Approved)
	OUTPUT inserted.EmployeeID, inserted.ScheduleDate, inserted.ShiftID, inserted.HolidayStatus, inserted.DateStatus, inserted.Approved
	SELECT EmployeeID, ScheduleDate, ShiftID, HolidayStatus, 1, 0
	FROM #tblShiftDetectorMatched a
	WHERE a.ScheduleDate BETWEEN @FromDate AND @ToDate AND NOT EXISTS (
			SELECT 1
			FROM tblWSchedule b
			WHERE a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.ScheduleDate
			) AND NOT EXISTS (
			SELECT 1
			FROM #tblWSchedule b
			WHERE a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.ScheduleDate
			)
	GROUP BY EmployeeID, ScheduleDate, ShiftID, HolidayStatus
	) t

-- xoa nhung record lo vao roi ma ket ko ra dc
DELETE tblWschedule
FROM tblWschedule ws
WHERE ws.ScheduleDate BETWEEN @FromDate AND @ToDate AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE ws.EmployeeID = te.EmployeeID
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblWschedule tmp
		WHERE ws.EmployeeID = tmp.EmployeeID AND ws.ScheduleDate = tmp.ScheduleDate
		) AND (ISNULL(ws.Approved, 0) = 0 AND ws.DateStatus <> 3)

UPDATE #tblShiftDetectorMatched
SET AttEnd = NULL, AttEndMi = NULL, WorkingTimeMi = 0
WHERE AttEndMi - AttStartMi < INOUT_MINIMUM AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

IF (object_id('sp_ShiftDetector_BeforeUpdatetblWSchedule') IS NULL)
BEGIN
	EXEC (
			'CREATE PROCEDURE dbo.sp_ShiftDetector_BeforeUpdatetblWSchedule(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime)
as begin
    SET NOCOUNT ON;
end'
			)
END

SET @StopUpdate = 0

-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
EXEC sp_ShiftDetector_BeforeUpdatetblWSchedule @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

UPDATE tblWSchedule
SET ShiftID = isnull(m.ShiftID, 0), HolidayStatus = m.HolidayStatus
FROM tblWSchedule ws
INNER JOIN #tblShiftDetectorMatched m ON ws.EmployeeID = m.EmployeeId AND ws.ScheduleDate = m.ScheduleDate
WHERE (ws.Approved IS NULL OR ws.Approved = 0)

UPDATE ws
SET ShiftID2 = ss.ShiftID
FROM tblWSchedule ws
INNER JOIN #tblWorking2ShiftADay_Detect s ON ws.EmployeeID = s.EmployeeID AND ws.ScheduleDate = s.ScheduleDate AND s.AttEnd2 IS NOT NULL
INNER JOIN #tblShiftSetting ss ON s.ShiftCode2 = ss.ShiftCode

--TRIPOD: Xử lý chọn shift cho staff, swapp shift
EXEC sp_processShiftChange @LoginID = @LoginID, @FromDate = @FromDate, @ToDate = @ToDate

-- Nguoi dung da confirm
-- ngay hom do co nghi
-- thai san
IF COL_LENGTH('tempdb..#tblShiftDetectorMatched', 'NotTASaturday') IS NULL
	ALTER TABLE #tblShiftDetectorMatched ADD NotTASaturday INT

UPDATE #tblShiftDetectorMatched
SET NotTASaturday = 1
FROM #tblShiftDetectorMatched s
INNER JOIN #tblEmployeeList e ON s.EmployeeId = e.EmployeeID
WHERE e.TAOptionID = 4 AND DATENAME(dw, s.ScheduleDate) = 'Saturday'

UPDATE #tblShiftDetectorMatched
SET AttStart = NULL, AttEnd = NULL, FixedAtt = 0
FROM #tblShiftDetectorMatched m
INNER JOIN (
	SELECT EmployeeId, LeaveDate, Max(LeaveStatus) LeaveStatus, sum(lvAmount) lvAmount
	FROM #tblLvHistory
	WHERE LeaveCategory = 1
	GROUP BY EmployeeID, LeaveDate
	) lv ON m.EmployeeId = lv.EmployeeID AND m.ScheduleDate = lv.LeaveDate
WHERE ISNULL(m.NotTASaturday, 0) = 0 AND lv.LvAmount >= 8 AND m.HolidayStatus = 0 AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE te.NotCheckTA = 1 AND m.EmployeeID = te.EmployeeID
		) AND m.AttStartMi = m.WorkStartMi AND m.AttEndMi = m.WorkEndMi

UPDATE #tblShiftDetectorMatched
SET AttStart = CASE 
		WHEN AttStart IS NULL OR AttStartMi > WorkStartMi
			THEN DATEADD(mi, CASE 
						WHEN lv.lvAmount > 0 AND lv.LeaveStatus IN (1, 4)
							THEN WorkStartMi + (lv.lvAmount * 60)
						ELSE WorkStartMi
						END, ScheduleDate)
		ELSE AttStart
		END, AttEnd = CASE 
		WHEN AttEnd IS NULL OR AttEndMi < WorkEndMi
			THEN DATEADD(mi, CASE 
						WHEN lv.lvAmount > 0 AND lv.LeaveStatus IN (2, 5)
							THEN WorkEndMi - (lv.lvAmount * 60)
						ELSE WorkEndMi
						END, ScheduleDate)
		ELSE AttEnd
		END
--,StdWorkingTimeMi = BreakStartMi - WorkStartMi + (WorkEndMi-BreakEndMi)
FROM #tblShiftDetectorMatched m
LEFT JOIN (
	SELECT EmployeeId, LeaveDate, Max(LeaveStatus) LeaveStatus, sum(lvAmount) lvAmount
	FROM #tblLvHistory
	WHERE LeaveCategory = 1
	GROUP BY EmployeeID, LeaveDate
	) lv ON m.EmployeeId = lv.EmployeeID AND m.ScheduleDate = lv.LeaveDate
WHERE ISNULL(m.NotTASaturday, 0) = 0 AND HolidayStatus = 0 AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE te.NotCheckTA = 1 AND m.EmployeeID = te.EmployeeID
		) AND (lv.EmployeeID IS NULL OR lv.lvAmount < 8)

UPDATE m1
SET AttEnd = NULL
FROM #tblShiftDetectorMatched m1
INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate + 1 = m2.ScheduleDate
WHERE m1.AttStart IS NULL AND m1.AttEnd = m2.AttStart

-- hom sau thieu du lieu cong ma gio vao trung voi gio ra hom truoc
UPDATE m2
SET AttStart = NULL
FROM #tblShiftDetectorMatched m1
INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate - 1
WHERE m1.AttStart IS NOT NULL AND m2.AttEnd IS NULL AND m1.AttEnd = m2.AttStart

----------- dua vao bang tblhasTA-------------------------
SET @RepeatTime = 0

SELECT ta.*, s.AttEndYesterday AS MinTimeIn, s.AttEndYesterday AS MaxTimeIn, s.AttEndYesterday AS MinTimeOut, s.AttEndYesterday AS MaxTimeOut, s.AttEndYesterday, s.AttStartTomorrow, s.TIMEINBEFORE, s.TIMEOUTAFTER, s.INOUT_MINIMUM, s.StdWorkingTimeMi, s.StdWorkingTimeMi AS STDWorkingTime_SS, s.WorkstartMi, s.WorkendMi, s.AttStartMi, s.AttEndMi, s.BreakEndMi, s.BreakStartMi, s.Early_Permit, s.Late_Permit, s.ShiftID, cast(NULL AS INT) AS SwipeOptionID, cast(NULL AS FLOAT) CARE_LEAVEAMOUNT, cast(NULL AS FLOAT) ACCUMMULATE_CARE_LEAVEAMOUNT, cast(NULL AS FLOAT) COMPARE_WORKINGTIME, cast(NULL AS FLOAT) DEDUCT_WORKINGTIME
INTO #tblHasTA_insert
FROM #tblHasTA ta
INNER JOIN #tblShiftDetectorMatched s ON ta.EmployeeID = s.EmployeeId AND ta.AttDate = s.ScheduleDate
WHERE 1 = 0

CREATE CLUSTERED INDEX IX_tblHasTA_insert_Emp_Att ON #tblHasTA_insert (EmployeeID, AttDate)

-- Option 0: xóa giờ ra nếu có nghỉ cả ngày
-- Option 1: xóa nghỉ cả ngày nếu có giờ vào ra
-- Option 2: Xóa giờ vào ra nếu nghỉ cả ngày và workingtimeMi < 120
-- Option 3: Xóa nghỉ cả ngày nếu có vào ra và WorkingTimeMi > 240
UPDATE m
SET AttEnd = NULL, AttStart = NULL, WorkingTimeMi = 0
FROM #tblShiftDetectorMatched m
WHERE m.HolidayStatus = 0 AND @LEAVEFULLDAYSTILLHASATTTIME = 0 AND IsLeaveStatus3 = 1

UPDATE m
SET AttEnd = NULL, AttStart = NULL, WorkingTimeMi = 0
FROM #tblShiftDetectorMatched m
WHERE m.HolidayStatus = 0 AND @LEAVEFULLDAYSTILLHASATTTIME = 2 AND IsLeaveStatus3 = 1 AND WorkingTimeMi < 120

DELETE tblLvHistory
FROM tblLvHistory lv
INNER JOIN #tblShiftDetectorMatched m ON lv.EmployeeID = m.EmployeeId AND lv.LeaveDate = m.ScheduleDate AND lv.LeaveStatus = 3 AND m.IsLeaveStatus3 = 1
WHERE m.HolidayStatus = 0 AND @LEAVEFULLDAYSTILLHASATTTIME = 1 AND m.AttStart IS NOT NULL AND m.AttEnd IS NOT NULL

DELETE tblLvHistory
FROM tblLvHistory lv
INNER JOIN #tblShiftDetectorMatched m ON lv.EmployeeID = m.EmployeeId AND lv.LeaveDate = m.ScheduleDate AND lv.LeaveStatus = 3 AND m.IsLeaveStatus3 = 1
WHERE m.HolidayStatus = 0 AND @LEAVEFULLDAYSTILLHASATTTIME = 1 AND m.AttStart IS NOT NULL AND m.AttEnd IS NOT NULL AND m.WorkingTimeMi > 240

SELECT @TA_IO_SWIPE_OPTION = CAST(Value AS FLOAT)
FROM tblParameter
WHERE Code = 'TA_IO_SWIPE_OPTION'

/*
0 Bấm tự do
1 Vào làm bấm công, về bấm công
2 Bấm giờ công 2 lần đầu ca cuối ca, tang ca bấm riêng
3 Sáng bấm, trưa bấm , chiều bấm, tăng ca bấm công
*/
/*

update ta1 set TIMEOUTAFTER = DATEADD(hh,@Max_WorkingHour_PerDay,ta1.WorkStart)
from #tblShiftDetectorMatched ta1

inner join #tblShiftDetectorMatched ta2 on ta1.EmployeeId = ta2.EmployeeId and ta1.ScheduleDate= ta2.ScheduleDate -1
where ta2.AttStart is not null and ta2.AttEnd is not null
*/
UPDATE #tblShiftDetectorMatched
SET TIMEOUTAFTER = DATEADD(HOUR, @Max_WorkingHour_PerDay, WorkStart)
WHERE TIMEOUTAFTER <= WorkStart

DELETE m
FROM #tblShiftDetectorMatched m
WHERE EXISTS (
		SELECT 1
		FROM #tblWorking2ShiftADay_Detect s
		WHERE m.EmployeeId = s.EmployeeID AND m.ScheduleDate = s.ScheduleDate AND s.AttEnd2 IS NOT NULL
		)

--update rule option nếu null update về rule 4
UPDATE sdm
SET sdm.SwipeOptionID = isnull(ss.SwipeOptionID, 4)
FROM #tblShiftDetectorMatched sdm
LEFT JOIN #tblShiftSetting ss ON sdm.ShiftCode = ss.ShiftCode

----lichien: cap nhat option [vao bam cong - ve bam cong] if date < 2024-03-16
--if exists (select top 1 1 from #tblShiftDetectorMatched where ScheduleDate < '2024-03-16')
-- update #tblShiftDetectorMatched set SwipeOptionID = 1 where ScheduleDate < '2024-03-16'
SET @TA_IO_SWIPE_OPTION = ISNULL(@TA_IO_SWIPE_OPTION, 1)

IF @TA_IO_SWIPE_OPTION = 0
BEGIN
	UPDATE #tblShiftDetectorMatched
	SET AttEndYesterday = dateadd(mi, - 20, AttStart)
	WHERE AttEndYesterday IS NULL AND AttStart IS NOT NULL

	UPDATE #tblShiftDetectorMatched
	SET AttStartTomorrow = dateadd(mi, 20, AttEnd)
	WHERE AttStartTomorrow IS NULL AND AttEnd IS NOT NULL

	UPDATE #tblShiftDetectorMatched
	SET AttEndYesterday = dateadd(mi, 10, AttEndYesterday), AttStartTomorrow = dateadd(mi, - 10, AttStartTomorrow)
	WHERE @IN_OUT_TA_SEPARATE = 0

	RepeatInsertHasTAOption0:

	INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkingTime, StdWorkingTimeMi, BreakStartMi, BreakEndMi, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow)
	SELECT EmployeeID, ScheduleDate, @RepeatTime, 0, WorkingTimeMi / 60.0, StdWorkingTimeMi, BreakStartMi, BreakEndMi, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	--
	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 2 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 1 AND a.AttDate BETWEEN @FromDate AND @ToDate

	-- AttStart
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert ta
	INNER JOIN (
		SELECT ta.EmployeeID, ta.AttDate, min(att.AttTime) AttTime
		FROM #tblHasTA_insert ta
		INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate
		INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND att.AttTime > m.AttEndYesterday AND att.AttTime < m.AttStartTomorrow AND (ta.Period > 0 OR (att.AttTime < m.AttEnd OR m.AttEnd IS NULL))
		WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (2, 0) AND (m.AttStart IS NOT NULL OR m.AttEnd IS NOT NULL) AND att.AttTime >= CASE 
				WHEN @RepeatTime = 0
					THEN ISNULL(m.AttStart, AttTime)
				ELSE m.AttStart
				END AND datediff(mi, m.WorkStart, att.AttTime) < 1320
		GROUP BY ta.EmployeeID, ta.AttDate
		) tmp ON ta.EmployeeID = tmp.EmployeeID AND ta.AttDate = tmp.AttDate AND ta.Period = @RepeatTime AND ta.TAStatus IN (2, 0)

	-- sửa lại cho những người giờ nằm trong giờ nghỉ trưa
	--update ta set AttStart = att.AttTime
	UPDATE #tblHasTA_insert
	SET AttStart = t.AttTime
	FROM #tblHasTA_insert ta
	INNER JOIN (
		SELECT ta.EmployeeID, ta.Attdate, ta.Period, max(att.AttTime) AttTime
		FROM #tblHasTA_insert ta
		INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND att.AttTime > ta.AttStart AND att.AttTime < DATEADD(mi, ta.BreakEndMi + 15, ta.Attdate)
		WHERE ta.Period = @RepeatTime AND DATEPART(hh, ta.AttStart) * 60 + DATEPART(mi, ta.Attstart) BETWEEN ta.BreakStartMi AND ta.BreakEndMi
		GROUP BY ta.EmployeeID, ta.Attdate, ta.Period
		) t ON ta.EmployeeID = t.EmployeeID AND ta.Attdate = t.Attdate AND ta.Period = t.Period

	-- sửa lại những người vào quá sớm nhưng k có tăng ca trước
	DELETE att
	FROM #tblTmpAttend att
	WHERE EXISTS (
			SELECT 1
			FROM #tblHasTA_insert ta
			WHERE ta.Period = @RepeatTime AND att.EmployeeID = ta.EmployeeID AND att.AttTime = ta.AttStart
			)

	-- AttEnd
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert ta
	INNER JOIN (
		SELECT ta.EmployeeID, ta.AttDate, min(att.AttTime) AttTime
		FROM #tblHasTA_insert ta
		INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate
		INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND ta.AttStart < att.AttTime AND (datediff(mi, ta.AttStart, att.AttTime) >= isnull(m.INOUT_MINIMUM, 1) OR (ta.AttStart IS NULL AND att.AttTime > m.AttEndYesterday)) AND att.AttTime < m.AttStartTomorrow AND NOT EXISTS (
				SELECT 1
				FROM #tblTmpAttend att1
				WHERE ta.EmployeeID = att1.EmployeeID AND att.AttState = att1.AttState AND att1.Atttime > dateadd(mi, 5, att.AttTime) AND att1.AttTime < att.AttTime
				)
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (1, 0) AND att.AttTime < isnull(m.TIMEOUTAFTER, m.AttEnd) AND att.AttTime > m.WorkStart AND datediff(mi, isnull(ta.AttStart, m.WorkStart), att.AttTime) >= isnull(m.INOUT_MINIMUM, 0)
		GROUP BY ta.EmployeeID, ta.AttDate
		) tmp ON ta.EmployeeID = tmp.EmployeeID AND ta.AttDate = tmp.AttDate AND ta.Period = @RepeatTime AND ta.TAStatus IN (1, 0)

	-- nếu k lấy được giờ ca thì lấy giờ ra cuối ngày
	UPDATE #tblHasTA_insert
	SET AttEnd = m.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate
	WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (1, 0) AND ta.AttEnd IS NULL AND (ta.AttStart < m.AttEnd OR (ta.AttStart IS NULL AND ta.Period = 0))

	-- period 0 ko lay dc gio vao thi lay trong #tblShiftDetectorMatched
	UPDATE #tblHasTA_insert
	SET AttStart = m.AttStart
	FROM #tblHasTA_insert ta
	INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate
	WHERE ta.Period = 0 AND ta.TAStatus IN (0, 2) AND ta.AttStart IS NULL AND (ta.AttEnd > m.AttStart OR ta.AttEnd IS NULL)

	/* -- nghỉ cả ngày mà bấm thiéu đàu thì bỏ
 update m set AttStart = null, AttEnd = null from #tblHasTA_insert m where ((m.AttStart is not null and m.AttEnd is null ) or (m.AttStart is null and m.AttEnd is not null))
 and exists (select 1 from #tblLvHistory lv where lv.LeaveCategory = 1 and lv.EmployeeID = m.EmployeeId and m.AttDate = lv.LeaveDate and lv.LeaveStatus = 3)
 */
	-- loại những records đã xử lý xong
	DELETE m
	FROM #tblShiftDetectorMatched m
	WHERE EXISTS (
			SELECT 1
			FROM #tblHasTA_insert ta
			WHERE ta.Period = @RepeatTime AND ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND (ta.AttEnd >= m.AttEnd OR (ta.AttStart = m.AttStart AND m.AttEnd IS NULL))
			) OR (m.AttStart IS NULL AND m.AttEnd IS NULL)

	DELETE m
	FROM #tblShiftDetectorMatched m
	WHERE EXISTS (
			SELECT 1
			FROM #tblHasTA_insert ta
			WHERE ta.Period = @RepeatTime AND ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND (ta.AttStart >= m.AttEnd)
			)

	IF EXISTS (
			SELECT 1
			FROM #tblShiftDetectorMatched
			) AND @RepeatTime < 7
	BEGIN
		UPDATE m
		SET AttEndYesterday = ta.AttEnd
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblHasTA_insert ta ON m.EmployeeId = ta.EmployeeID AND m.ScheduleDate = ta.AttDate
		WHERE ta.Period = @RepeatTime

		SET @RepeatTime += 1

		GOTO RepeatInsertHasTAOption0
	END
END

DELETE
FROM #tblHasTA_insert
WHERE AttStart IS NULL AND AttEnd IS NULL AND Period > 0

IF @TA_IO_SWIPE_OPTION = 1 -- Ngày bấm 2 lần vào bấm công về bấm công
BEGIN
	-- vao thì lấy sớm nhất, ra thì lấy trễ nhất
	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
		WHERE ((t.AttTime > m.AttEnd AND t.AttTime < m.TIMEOUTAFTER)) AND t.AttTime < m.AttStartTomorrow AND t.AttTime > m.AttEndYesterday AND (t.AttTime > m.AttStart OR m.AttStart IS NULL) AND t.AttTime < m.TIMEOUTAFTER AND (t.AttTime >= dateadd(mi, @TA_INOUT_MINIMUM, m.AttStart))
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE m1
	SET AttEndYesterday = m2.AttEnd
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate = m2.ScheduleDate + 1
	WHERE m2.AttEnd IS NOT NULL

	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, min(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
		WHERE ((t.AttTime < m.AttStart OR AttStart IS NULL) AND t.AttTime > m.TIMEINBEFORE) AND t.AttTime > dateadd(second, @RemoveDuplicateAttTime_Interval, m.AttEndYesterday) AND t.atttime < dateadd(mi, - 30, m.AttStartTomorrow) AND t.AttTime < dateadd(mi, - 1 * m.INOUT_MINIMUM, m.AttEnd)
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	DELETE ta
	FROM tblHasTA TA
	WHERE TA.Period > 0 AND EXISTS (
			SELECT 1
			FROM #tblShiftDetectorMatched M
			WHERE TA.EmployeeID = M.EmployeeId AND ta.AttDate = m.ScheduleDate AND M.ScheduleDate BETWEEN @FromDate AND @ToDate
			)

	INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkingTime, StdWorkingTimeMi)
	SELECT EmployeeID, ScheduleDate, @RepeatTime, 0, CASE 
			WHEN HolidayStatus = 0
				THEN WorkingTimeMi / 60.0
			ELSE (AttEndMi - AttStartMi) / 60.0
			END, StdWorkingTimeMi
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	-- dữ liệu đã đc xử lý
	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET AttStart = m.AttStart, AttEnd = m.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate
	WHERE ta.Period = @RepeatTime AND ta.TAStatus = 0
		/*
 -- nghỉ cả ngày mà bấm thiếu đàu thì bỏ
 update m set AttStart = null, AttEnd = null from #tblHasTA_insert m where ((m.AttStart is not null and m.AttEnd is null ) or (m.AttStart is null and m.AttEnd is not null))
 and exists (select 1 from #tblLvHistory lv where lv.LeaveCategory = 1 and lv.EmployeeID = m.EmployeeId and m.AttDate = lv.LeaveDate and lv.LeaveStatus = 3 and @LEAVEFULLDAYSTILLHASATTTIME = 2)
 */
END

IF @TA_IO_SWIPE_OPTION = 2 --Bấm giờ công 2 lần đầu ca cuối ca, tăng ca bấm riêng,
BEGIN
	-- cap nhat lai OTAfter neu chua co
	UPDATE m
	SET OTAfterStart = DATEADD(mi, ss.OTAfterStartMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTAfterStart IS NULL

	UPDATE m
	SET OTAfterEnd = DATEADD(mi, ss.OTAfterEndMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTAfterEnd IS NULL

	UPDATE m
	SET OTBeforeStart = DATEADD(mi, ss.OTBeforeStartMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTBeforeStart IS NULL

	UPDATE m
	SET OTBeforeEnd = DATEADD(mi, ss.OTBeforeEndMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTBeforeEnd IS NULL

	-- buoi sang
	INSERT INTO #tblHasTA_insert (EmployeeID, Attdate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut, WorkingTime, StdWorkingTimeMi)
	SELECT EmployeeId, ScheduleDate, 0, 0, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(MI, - @TA_TIMEINBEFORE / 2, WorkStart), dateadd(mi, - 120, WorkEnd), --,dateadd(MI,-@TA_TIMEINBEFORE,WorkStart),dateadd(mi,-120,WorkEnd)
		dateadd(hour, @TA_TIMEOUTAFTER, WorkStart), CASE 
			WHEN HolidayStatus = 0
				THEN WorkingTimeMi / 60.0
			ELSE (AttEndMi - AttStartMi) / 60.0
			END, StdWorkingTimeMi
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET MinTimeOut = dateadd(MI, @TA_INOUT_MINIMUM, WorkStart)

	--gio vao
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND t.AttTime < m.WorkEnd AND t.AttTime > dateadd(mi, @TA_INOUT_MINIMUM, m.AttEndYesterday) AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttStart AND t.AttTime < m.MaxTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- gio ra
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.WorkEnd
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime < m.AttEnd AND t.AttTime > m.MinTimeIn
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- tang ca sau
	INSERT INTO #tblHasTA_insert (EmployeeID, Attdate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut)
	SELECT EmployeeId, ScheduleDate, 1, 0, OTAfterStart, OTAfterEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(hour, - 1, OTAfterStart), dateadd(mi, - datediff(mi, OTAfterStart, OTAfterEnd) / 2, OTAfterEnd), --,dateadd(HOUR,@TA_TIMEOUTAFTER,WorkStart)
		TIMEOUTAFTER
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET MinTimeOut = DATEADD(SECOND, 1, MaxTimeIn)
	WHERE MinTimeOut IS NULL

	UPDATE m1
	SET AttEndYesterday = m2.AttEnd
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1 --where (m2.AttEnd is not null )
		AND m1.Period = 1

	--update m1 set AttStartTomorrow = isnull(m2.AttStart,m2.workStart) from #tblHasTA_insert m1 inner join #tblHasTA_insert m2 on m1.EmployeeId = m2.EmployeeId and m1.AttDate = m2.AttDate and m1.Period = m2.Period-1
	-- where m1.Period = 1
	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, m2.workStart)
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = DateADD(Day, - 1, m2.AttDate) AND m2.Period = 0
	WHERE m1.Period = 1

	--Giờ AttStartTomorow nên lấy của ngày hôm sau
	-- gio vao
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime < m.WorkEnd AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime < m.WorkEnd AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND m.AttEndYesterday IS NULL AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- gio ra
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.WorkEnd
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttStart AND t.AttTime < m.MaxTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime < m.AttEnd AND t.AttTime > m.MinTimeIn
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- liet ke ra nhung record bao vao cua period sau lay nham sang bam ra cua period truoc
	UPDATE t
	SET AttEnd = s.AttStart
	FROM #tblHasTA_insert t
	INNER JOIN #tblHasTA_insert s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.AttDate AND t.Period = s.Period - 1
	WHERE t.AttEnd IS NULL AND t.AttStart IS NOT NULL AND t.Period <= 1 AND s.AttEnd IS NOT NULL AND s.AttStart IS NOT NULL AND EXISTS (
			SELECT 1
			FROM #tblTmpAttend_Org att
			WHERE att.EmployeeID = t.EmployeeID AND att.AttTime > s.AttStart AND att.AttTime < s.AttEnd
			)

	UPDATE t
	SET AttEnd = s.AttStart
	FROM #tblHasTA_insert t
	INNER JOIN #tblHasTA_insert s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.AttDate AND t.Period = s.Period - 1
	WHERE t.AttEnd IS NULL AND t.AttStart IS NOT NULL AND t.Period <= 1 AND s.AttEnd IS NOT NULL AND s.AttStart IS NOT NULL AND EXISTS (
			SELECT 1
			FROM #tblTmpAttend_Org att
			WHERE att.EmployeeID = t.EmployeeID AND att.AttTime > s.AttStart AND att.AttTime < s.AttEnd
			)

	UPDATE m1
	SET AttEndYesterday = m2.AttEnd
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1 --where (m2.AttEnd is not null)

	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
		WHERE m.TAStatus = 0 AND m.Period > 0 AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime < m.AttEnd AND t.AttTime > m.MinTimeIn
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period
	WHERE m.AttEndYesterday = m.AttStart

	-- k đụng vào những ngày người dùng modified
	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate

	--- co gang la gio ra cho buoi chieu
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert i
	INNER JOIN (
		SELECT i.EmployeeID, i.AttDate, i.Period, MIN(att.AttTime) AttTime
		FROM #tblHasTA_insert i
		INNER JOIN #tblHasTA_insert t ON i.employeeId = t.EmployeeId AND i.AttDate = t.AttDate AND t.Period = 1 AND i.Period = 0
		INNER JOIN #tblTmpAttend_Org att ON i.employeeId = att.EmployeeId AND att.AttTime < t.AttStart AND att.AttTime > i.MinTimeOut
		WHERE i.Period = 1 AND i.AttEnd IS NULL AND t.AttStart IS NOT NULL
		GROUP BY i.EmployeeID, i.AttDate, i.Period
		) tmp ON i.EmployeeId = tmp.EmployeeId AND i.AttDate = tmp.AttDate AND i.Period = tmp.Period

	-- lam dep lai du lieu
	UPDATE i1
	SET AttEnd = i2.AttStart
	FROM #tblHasTA_insert i1
	INNER JOIN #tblHasTA_insert i2 ON i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate
	WHERE i1.Period = i2.Period - 1 AND i1.AttEnd IS NULL AND i2.AttStart IS NOT NULL AND i2.AttEnd IS NULL

	UPDATE i2
	SET AttStart = NULL
	FROM #tblHasTA_insert i1
	INNER JOIN #tblHasTA_insert i2 ON i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate
	WHERE i1.Period = i2.Period - 1 AND i1.AttEnd = i2.AttStart AND i2.AttEnd IS NULL

	UPDATE j
	SET AttStart = i.AttEnd
	FROM #tblHasTA_insert i
	INNER JOIN #tblHasTA_insert j ON i.EmployeeId = j.EmployeeId AND i.AttDate = j.AttDate AND i.Period = j.Period - 1
	WHERE i.AttStart IS NULL AND i.AttEnd IS NOT NULL AND j.AttStart IS NULL AND j.AttEnd IS NOT NULL AND j.AttEnd > dateadd(hour, - 1, j.WorkEnd)

	UPDATE i
	SET AttEnd = NULL
	FROM #tblHasTA_insert i
	INNER JOIN #tblHasTA_insert j ON i.EmployeeId = j.EmployeeId AND i.AttDate = j.AttDate AND i.Period = j.Period - 1
	WHERE i.AttStart IS NULL AND i.AttEnd = j.AttStart AND j.AttEnd IS NOT NULL AND j.AttEnd > dateadd(hour, - 1, j.WorkEnd)

	--- co gang la gio vao cho buoi chieu
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert i
	INNER JOIN (
		SELECT i.EmployeeID, i.AttDate, i.Period, min(att.AttTime) AttTime
		FROM #tblHasTA_insert i
		INNER JOIN #tblHasTA_insert t ON i.employeeId = t.EmployeeId AND i.AttDate = t.AttDate AND t.Period = 0 AND i.Period = 1
		INNER JOIN #tblTmpAttend_Org att ON i.employeeId = att.EmployeeId AND att.AttTime > isnull(t.AttStart, t.MinTimeOut) -- and att.AttTime < i.AttEnd
		WHERE i.Period = 0 AND i.AttStart IS NULL AND i.AttEnd IS NOT NULL
		GROUP BY i.EmployeeID, i.AttDate, i.Period
		) tmp ON i.EmployeeId = tmp.EmployeeId AND i.AttDate = tmp.AttDate AND i.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttStart = NULL
	WHERE period = 1 AND AttStart = AttEnd AND AttStart > MaxTimeIn

	-- khong co tang ca thi bo di
	DELETE #tblHasTA_insert
	WHERE Period = 1 AND AttStart IS NULL AND AttEnd IS NULL
END

IF @TA_IO_SWIPE_OPTION = 3 --Sáng bấm, trưa bấm, chiều bấm và tăng ca bấm công
BEGIN
	-- cap nhat lai OTAfter neu chua co
	UPDATE m
	SET OTAfterStart = DATEADD(mi, ss.OTAfterStartMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTAfterStart IS NULL

	UPDATE m
	SET OTAfterEnd = DATEADD(mi, ss.OTAfterEndMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTAfterEnd IS NULL

	UPDATE m
	SET OTBeforeStart = DATEADD(mi, ss.OTBeforeStartMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTBeforeStart IS NULL

	UPDATE m
	SET OTBeforeEnd = DATEADD(mi, ss.OTBeforeEndMi, m.ScheduleDate)
	FROM #tblShiftDetectorMatched m
	INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
	WHERE OTBeforeEnd IS NULL

	-- buoi sang
	INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut, WorkingTime, StdWorkingTimeMi)
	SELECT EmployeeID, ScheduleDate, 0, 0, WorkStart, BreakStart, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(MI, - @TA_TIMEINBEFORE, WorkStart), dateadd(mi, - datediff(mi, WorkStart, BreakStart) / 2, BreakStart), dateadd(mi, datediff(mi, BreakStart, BreakEnd) / 2, BreakEnd) --maxtime out
		, CASE 
			WHEN HolidayStatus = 0
				THEN WorkingTimeMi / 60.0
			ELSE (AttEndMi - AttStartMi) / 60.0
			END, StdWorkingTimeMi
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET MinTimeOut = DATEADD(SECOND, 1, MaxTimeIn)

	-- gio vao
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND t.AttTime < m.WorkEnd AND t.AttTime > dateadd(mi, @TA_INOUT_MINIMUM, m.AttEndYesterday) AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- doi di lam ăn xa
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND t.AttTime BETWEEN m.MinTimeIn AND m.WorkEnd AND t.AttTime > dateadd(mi, @TA_INOUT_MINIMUM, m.AttEndYesterday)
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- gio ra
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > isnull(m.AttStart, m.WorkStart) AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.WorkEnd
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttStart AND t.AttTime < m.MaxTimeOut AND t.AttTime > m.MinTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- buoi chieu
	INSERT INTO #tblHasTA_insert (EmployeeID, Attdate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut, WorkingTime, StdWorkingTimeMi)
	SELECT EmployeeId, ScheduleDate, 1, 0, BreakEnd, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(mi, - @TA_TIMEINBEFORE, BreakEnd), dateadd(mi, - datediff(mi, BreakEnd, WorkEnd) / 2, WorkEnd), --,dateadd(mi,case when datediff(mi,WorkEnd,OTAfterStart)/2 < 30 then 30 else datediff(mi,WorkEnd,OTAfterStart)/2 end,WorkEnd) -- tối thiểu 30 phút kể từ giờ ra
		dateadd(mi, CASE 
				WHEN datediff(mi, WorkEnd, OTAfterStart) / 2 < 60
					THEN 60
				ELSE datediff(mi, WorkEnd, OTAfterStart) / 2
				END, WorkEnd), -- max time out tối thiểu 60 phút kể từ giờ ra
		CASE 
			WHEN HolidayStatus = 0
				THEN WorkingTimeMi / 60.0
			ELSE (AttEndMi - AttStartMi) / 60.0
			END, StdWorkingTimeMi
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET MinTimeOut = dateadd(second, 1, MaxTimeIn)
	WHERE MinTimeOut IS NULL

	UPDATE m1
	SET AttEndYesterday = DATEADD(MI, @TA_OUTIN_MINIMUM, DATEADD(S, 1, m2.AttEnd))
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1

	--where (m2.AttEnd is not null)
	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, m2.workStart)
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period - 1

	UPDATE m1
	SET AttEndYesterday = DATEADD(S, 1, m2.MinTimeOut)
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1
	WHERE m1.AttEndYesterday IS NULL

	-- gio vao
	-- ga que an quan coi xay
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY m.EmployeeID, m.AttDate ORDER BY AttTime ASC
				) AS STT, m.EmployeeId, m.AttDate, m.Period, AttTime, AttState
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.AttStartTomorrow AND (ForceState = 0 OR AttState = 1)
		WHERE m.AttStart IS NULL AND abs(DATEDIFF(mi, m.WorkStart, t.AttTime)) <= 30
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND STT = 1

	-- doi thi ra khoi bat ca nho
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND t.AttTime < m.WorkEnd AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- gio ra
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		--SELECT m.EmployeeId, m.AttDate,m.Period, max(t.AttTime) AttTime
		SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut AND m.Period = 1
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.WorkEnd AND m.Period = 1
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttStart AND t.AttTime < m.MaxTimeOut AND t.AttTime > MinTimeOut AND m.Period = 1
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- tang ca sau
	INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut)
	SELECT EmployeeID, ScheduleDate, 2, 0, OTAfterStart, OTAfterEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(hour, - 1, OTAfterStart), dateadd(mi, - datediff(mi, OTAfterStart, OTAfterEnd) / 2, OTAfterEnd), TIMEOUTAFTER
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET MinTimeOut = DATEADD(SECOND, 1, MaxTimeIn)
	WHERE MinTimeOut IS NULL AND Period = 2

	UPDATE m1
	SET AttEndYesterday = DATEADD(MI, @TA_OUTIN_MINIMUM, DATEADD(S, 1, m2.AttEnd))
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1 AND m1.Period = 2

	--where (m2.AttEnd is not null)
	UPDATE m1
	SET AttEndYesterday = DATEADD(S, 1, m2.MinTimeOut)
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1
	WHERE m1.AttEndYesterday IS NULL AND m1.Period = 2

	UPDATE m1
	SET AttStartTomorrow = isnull(m2.AttStart, m2.workStart)
	FROM #tblHasTA_insert m1
	INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period - 1
	WHERE m1.Period = 2

	--không tăng ca vẫn tính 6 mốc nới max time in ra
	UPDATE m1
	SET MaxTimeIn = DATEADD(mi, 60, s.OTAfterStart)
	FROM #tblHasTA_insert m1
	INNER JOIN #tblShiftDetectorMatched s ON m1.EmployeeID = s.EmployeeId AND m1.Attdate = s.ScheduleDate
	WHERE m1.Period = 2 AND DATEDIFF(M, m1.MaxTimeIn, m1.WorkStart) < 60

	-- gio vao
	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 2
			--and t.AttTime < m.WorkEnd
			AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttStart = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 2 AND t.AttTime < m.WorkEnd AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND m.AttEndYesterday IS NULL AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	-- gio ra
	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 2 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (t.AttTime > m.AttStart OR m.AttStart IS NULL) AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	UPDATE #tblHasTA_insert
	SET AttEnd = tmp.AttTime
	FROM #tblHasTA_insert m
	INNER JOIN (
		SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
		FROM #tblHasTA_insert m
		INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
		WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 2 AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND (t.AttTime > m.AttStart OR m.AttStart IS NULL) AND t.AttTime BETWEEN WorkStart AND m.WorkEnd
		GROUP BY m.EmployeeId, m.AttDate, m.Period
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period

	--Xử lý nghỉ nữa buổi đầu do có thể giờ ra ca đầu lấy nhầm giờ vào ca sau
	UPDATE c
	SET c.AttStart = s.AttEnd
	FROM #tblHasTA_insert c
	INNER JOIN #tblHasTA_insert s ON c.EmployeeID = s.EmployeeID AND c.Attdate = s.Attdate AND c.Period - 1 = s.Period AND s.AttEnd IS NOT NULL AND s.AttEnd > c.MinTimeIn
	WHERE c.Period = 1 AND c.AttStart IS NULL AND EXISTS (
			SELECT TOP 1 1
			FROM tblLvHistory
			WHERE LeaveDate = c.Attdate AND LeaveStatus = 1 AND EmployeeID = c.EmployeeID
			)

	UPDATE s
	SET s.AttEnd = NULL
	FROM #tblHasTA_insert s
	INNER JOIN #tblHasTA_insert c ON c.EmployeeID = s.EmployeeID AND c.Attdate = s.Attdate AND c.Period - 1 = s.Period AND s.AttEnd IS NOT NULL AND s.AttEnd = c.AttStart
	WHERE s.Period = 0 AND s.AttEnd IS NOT NULL AND EXISTS (
			SELECT TOP 1 1
			FROM tblLvHistory
			WHERE LeaveDate = s.Attdate AND LeaveStatus = 1 AND EmployeeID = c.EmployeeID
			)

	-- dồn giờ công lên do ko ra chấm tăng ca, ngồi tại chỗ làm việc luôn
	UPDATE f
	SET AttEnd = c.AttEnd
	FROM #tblHasTA_insert f
	INNER JOIN #tblHasTA_insert c ON f.EmployeeID = c.EmployeeID AND f.Attdate = c.Attdate AND f.Period + 1 = c.Period
	WHERE f.Period = 1 AND c.Period = 2 AND f.AttEnd IS NULL AND c.AttStart IS NULL AND c.AttEnd IS NOT NULL

	UPDATE c
	SET AttEnd = NULL
	FROM #tblHasTA_insert f
	INNER JOIN #tblHasTA_insert c ON f.EmployeeID = c.EmployeeID AND f.Attdate = c.Attdate AND f.Period + 1 = c.Period
	WHERE f.Period = 1 AND c.Period = 2 AND f.AttEnd = c.AttEnd AND c.AttStart IS NULL

	UPDATE f
	SET AttEnd = c.AttStart
	FROM #tblHasTA_insert f
	INNER JOIN #tblHasTA_insert c ON f.EmployeeID = c.EmployeeID AND f.Attdate = c.Attdate AND f.Period + 1 = c.Period
	WHERE f.Period = 1 AND c.Period = 2 AND f.AttEnd IS NULL AND c.AttStart IS NOT NULL AND c.AttEnd IS NULL

	UPDATE c
	SET AttStart = NULL
	FROM #tblHasTA_insert f
	INNER JOIN #tblHasTA_insert c ON f.EmployeeID = c.EmployeeID AND f.Attdate = c.Attdate AND f.Period + 1 = c.Period
	WHERE f.Period = 1 AND c.Period = 2 AND f.AttEnd = c.AttStart AND c.AttEnd IS NULL

	-- k đụng vào những ngày người dùng modified
	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 2 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 1 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET AttStart = NULL
	WHERE period = 1 AND AttStart = AttEnd AND AttStart > MaxTimeIn

	-- khong co tang ca thi bo di
	DELETE #tblHasTA_insert
	WHERE Period = 2 AND AttStart IS NULL AND AttEnd IS NULL

	-- xử lý giờ gần nhau tăng ca 45s và không có giờ ra định nghĩa không có tăng ca
	DELETE tc
	FROM #tblHasTA_insert tc
	INNER JOIN #tblHasTA_insert bc ON tc.EmployeeID = bc.EmployeeID AND tc.Attdate = bc.Attdate AND tc.Period = bc.Period + 1 AND tc.Period = 2 AND DATEDIFF(S, bc.AttEnd, tc.AttStart) <= 45 AND tc.AttEnd IS NULL
END

IF @TA_IO_SWIPE_OPTION = 4 -- Vao bam, nghi giua ca bam, ve bam
BEGIN
	UPDATE #tblShiftDetectorMatched
	SET AttEnd = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE ((t.AttTime > m.AttEnd AND t.AttTime < m.TIMEOUTAFTER) OR m.AttEnd IS NULL) AND t.AttTime < dateadd(mi, - 5, m.AttStartTomorrow) AND t.AttTime > m.AttEndYesterday AND t.AttTime < m.TIMEOUTAFTER AND (t.AttTime > m.AttStart OR m.AttStart IS NULL) AND (t.AttTime >= dateadd(mi, @TA_INOUT_MINIMUM, m.AttStart))
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	UPDATE #tblShiftDetectorMatched
	SET AttStart = tmp.AttTime
	FROM #tblShiftDetectorMatched m
	INNER JOIN (
		SELECT m.EmployeeId, m.ScheduleDate, min(t.AttTime) AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblTmpAttend t ON m.EmployeeId = t.EmployeeID
		WHERE ((t.AttTime < m.AttStart AND t.AttTime > m.TIMEINBEFORE) OR AttStart IS NULL)
			--and t.AttTime > m.AttEndYesterday and t.atttime < dateadd(mi,-30,m.AttStartTomorrow)
			AND t.AttTime > m.AttEndYesterday AND t.atttime < m.AttStartTomorrow --thanh123
			AND t.AttTime < m.AttEnd
		GROUP BY m.EmployeeId, m.ScheduleDate
		) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate

	--hôm trước thiếu dữ liệu công mà giờ về trùng giờ giờ vào hôm sau
	UPDATE m1
	SET AttEnd = NULL
	FROM #tblShiftDetectorMatched m1
	INNER JOIN #tblShiftDetectorMatched m2 ON m1.EmployeeId = m2.EmployeeId AND m1.ScheduleDate + 1 = m2.ScheduleDate
	WHERE m1.AttStart IS NULL AND m1.AttEnd = m2.AttStart

	DELETE tblHasTA
	FROM tblHasTA TA
	WHERE TA.Period > 0 AND EXISTS (
			SELECT 1
			FROM #tblShiftDetectorMatched M
			WHERE TA.EmployeeID = M.EmployeeId AND ta.AttDate = m.ScheduleDate AND M.ScheduleDate BETWEEN @FromDate AND @ToDate
			)

	INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkingTime, StdWorkingTimeMi, BreakStartMi, BreakEndMi)
	SELECT EmployeeID, ScheduleDate, @RepeatTime, 0, CASE 
			WHEN HolidayStatus = 0
				THEN WorkingTimeMi / 60.0
			ELSE (AttEndMi - AttStartMi) / 60.0
			END, StdWorkingTimeMi, BreakStartMi, BreakEndMi
	FROM #tblShiftDetectorMatched
	WHERE ScheduleDate BETWEEN @FromDate AND @ToDate

	-- k đụng vào những dữ liệu người dùng modified
	UPDATE #tblHasTA_insert
	SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
	WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate

	UPDATE #tblHasTA_insert
	SET AttStart = m.AttStart, AttEnd = m.AttEnd
	FROM #tblHasTA_insert ta
	INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate
	WHERE ta.Period = @RepeatTime AND ta.TAStatus = 0

	/*
 --nghỉ cả ngày mà thiếu đầu thì bỏ
 update m set AttStart = null, AttEnd = null from #tblHasTA_insert m where ((m.AttStart is not null and m.AttEnd is null ) or (m.AttStart is null and m.AttEnd is not null))

 and exists (select 1 from #tblLvHistory lv where lv.LeaveCategory = 1 and lv.EmployeeID = m.EmployeeId and m.AttDate = lv.LeaveDate and lv.LeaveStatus = 3)
 */
	UPDATE #tblHasTA_insert
	SET AttMiddle = tmp.AttTime
	FROM #tblHasTA_insert t
	INNER JOIN (
		SELECT min(att.AttTime) AttTime, ta.EmployeeID, ta.Attdate
		FROM #tblHasTA_insert ta
		INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND att.AttTime > ta.AttStart AND att.AttTime < ta.AttEnd AND DATEPART(HOUR, att.AttTime) * 60 + DATEPART(MINUTE, att.AttTime) BETWEEN ta.BreakStartMi AND ta.BreakEndMi
		GROUP BY ta.EmployeeID, ta.Attdate
		) tmp ON t.EmployeeID = tmp.EmployeeID AND t.Attdate = tmp.Attdate

	UPDATE #tblHasTA_insert
	SET AttMiddle = tmp.AttTime
	FROM #tblHasTA_insert t
	INNER JOIN (
		SELECT min(att.AttTime) AttTime, ta.EmployeeID, ta.Attdate
		FROM #tblHasTA_insert ta
		INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND att.AttTime > ta.AttStart AND att.AttTime < ta.AttEnd AND ta.AttMiddle IS NULL
		GROUP BY ta.EmployeeID, ta.Attdate
		) tmp ON t.EmployeeID = tmp.EmployeeID AND t.Attdate = tmp.Attdate

	-- nghi nua ngay
	UPDATE #tblHasTA_insert
	SET AttMiddle = tmp.AttTime
	FROM #tblHasTA_insert t
	INNER JOIN (
		SELECT min(att.AttTime) AttTime, ta.EmployeeID, ta.Attdate
		FROM #tblHasTA_insert ta
		INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND DATEPART(HOUR, att.AttTime) * 60 + DATEPART(MINUTE, att.AttTime) BETWEEN ta.BreakStartMi AND ta.BreakEndMi
		GROUP BY ta.EmployeeID, ta.Attdate
		) tmp ON t.EmployeeID = tmp.EmployeeID AND t.Attdate = tmp.Attdate
	WHERE AttMiddle IS NULL AND EXISTS (
			SELECT 1
			FROM #tblLvHistory lv
			WHERE t.EmployeeID = lv.EmployeeID AND t.Attdate = lv.LeaveDate AND lv.LeaveStatus <> 3
			)

	UPDATE #tblHasTA_insert
	SET AttMiddle = NULL
	FROM #tblHasTA_insert t
	WHERE (DATEDIFF(MI, Attstart, AttMiddle) < 60 OR DATEDIFF(MI, AttMiddle, AttEnd) < 60) AND NOT EXISTS (
			SELECT 1
			FROM #tblLvHistory lv
			WHERE t.EmployeeID = lv.EmployeeID AND t.Attdate = lv.LeaveDate AND lv.LeaveStatus <> 3
			)

	UPDATE #tblHasTA_insert
	SET AttMiddle = NULL
	FROM #tblHasTA_insert t
	WHERE (DATEDIFF(MI, AttDate, AttMiddle) - AttStartMi < 60 OR AttEndMi - DATEDIFF(MI, AttDate, AttMiddle) < 60) AND NOT EXISTS (
			SELECT 1
			FROM #tblLvHistory lv
			WHERE t.EmployeeID = lv.EmployeeID AND t.Attdate = lv.LeaveDate AND lv.LeaveStatus <> 3
			)
END

IF @TA_IO_SWIPE_OPTION = 5 -- theo tung ca cu the
BEGIN
	--VŨ Custom riêng cho LICHIEN
	ALTER TABLE #tblShiftDetectorMatched ADD ShiftMeal INT, IsOTAfter BIT

	--ShiftMeal = 1 ăn cơm bth
	--ShiftMeal = 2 là nghỉ buổi sáng
	--ShiftMeal = 3 là nghi buổi chiều
	IF EXISTS (
			SELECT TOP 1 1
			FROM #tblShiftDetectorMatched
			WHERE SwipeOptionID = 0
			) --Bấm tự do
	BEGIN
		UPDATE #tblShiftDetectorMatched
		SET AttEndYesterday = dateadd(mi, - 20, AttStart)
		WHERE AttEndYesterday IS NULL AND AttStart IS NOT NULL AND SwipeOptionID = 0

		UPDATE #tblShiftDetectorMatched
		SET AttStartTomorrow = dateadd(mi, 20, AttEnd)
		WHERE AttStartTomorrow IS NULL AND AttEnd IS NOT NULL AND SwipeOptionID = 0

		UPDATE #tblShiftDetectorMatched
		SET AttEndYesterday = dateadd(mi, 10, AttEndYesterday), AttStartTomorrow = dateadd(mi, - 10, AttStartTomorrow)
		WHERE @IN_OUT_TA_SEPARATE = 0 AND SwipeOptionID = 0

		RepeatInsertHasTAOption5:

		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkingTime, StdWorkingTimeMi, BreakStartMi, BreakEndMi, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, @RepeatTime, 0, WorkingTimeMi / 60.0, StdWorkingTimeMi, BreakStartMi, BreakEndMi, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 0

		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 0

		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttEnd = a.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus = 2 AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 0

		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttStart = a.AttStart
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus = 1 AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 0

		-- AttStart
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert ta
		INNER JOIN (
			SELECT ta.EmployeeID, ta.AttDate, min(att.AttTime) AttTime
			FROM #tblHasTA_insert ta
			INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND m.SwipeOptionID = 0
			INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND att.AttTime > m.AttEndYesterday AND att.AttTime < m.AttStartTomorrow AND (ta.Period > 0 OR (att.AttTime < m.AttEnd OR m.AttEnd IS NULL))
			WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (2, 0) AND (m.AttStart IS NOT NULL OR m.AttEnd IS NOT NULL) AND att.AttTime >= CASE 
					WHEN @RepeatTime = 0
						THEN ISNULL(m.AttStart, AttTime)
					ELSE m.AttStart
					END AND datediff(mi, m.WorkStart, att.AttTime) < 1320
			GROUP BY ta.EmployeeID, ta.AttDate
			) tmp ON ta.EmployeeID = tmp.EmployeeID AND ta.AttDate = tmp.AttDate AND ta.Period = @RepeatTime AND ta.TAStatus IN (2, 0) AND ta.SwipeOptionID = 0

		-- sửa lại cho những người giờ nằm trong giờ nghỉ trưa
		--update ta set AttStart = att.AttTime
		UPDATE #tblHasTA_insert
		SET AttStart = t.AttTime
		FROM #tblHasTA_insert ta
		INNER JOIN (
			SELECT ta.EmployeeID, ta.Attdate, ta.Period, max(att.AttTime) AttTime
			FROM #tblHasTA_insert ta
			INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND att.AttTime > ta.AttStart AND att.AttTime < DATEADD(mi, ta.BreakEndMi + 15, ta.Attdate)
			WHERE ta.Period = @RepeatTime AND DATEPART(hh, ta.AttStart) * 60 + DATEPART(mi, ta.Attstart) BETWEEN ta.BreakStartMi AND ta.BreakEndMi
			GROUP BY ta.EmployeeID, ta.Attdate, ta.Period
			) t ON ta.EmployeeID = t.EmployeeID AND ta.Attdate = t.Attdate AND ta.Period = t.Period AND ta.SwipeOptionID = 0

		-- sửa lại những người vào quá sớm nhưng k có tăng ca trước
		DELETE att
		FROM #tblTmpAttend att
		WHERE EXISTS (
				SELECT 1
				FROM #tblHasTA_insert ta
				WHERE ta.Period = @RepeatTime AND att.EmployeeID = ta.EmployeeID AND att.AttTime = ta.AttStart AND ta.SwipeOptionID = 0
				)

		-- AttEnd
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert ta
		INNER JOIN (
			SELECT ta.EmployeeID, ta.AttDate, min(att.AttTime) AttTime
			FROM #tblHasTA_insert ta
			INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND m.SwipeOptionID = 0
			INNER JOIN #tblTmpAttend att ON ta.EmployeeID = att.EmployeeID AND ta.AttStart < att.AttTime AND (datediff(mi, ta.AttStart, att.AttTime) >= isnull(m.INOUT_MINIMUM, 1) OR (ta.AttStart IS NULL AND att.AttTime > m.AttEndYesterday)) AND att.AttTime < m.AttStartTomorrow AND NOT EXISTS (
					SELECT 1
					FROM #tblTmpAttend att1
					WHERE ta.EmployeeID = att1.EmployeeID AND att.AttState = att1.AttState AND att1.Atttime > dateadd(mi, 5, att.AttTime) AND att1.AttTime < att.AttTime
					)
			INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
			WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (1, 0) AND att.AttTime < isnull(m.TIMEOUTAFTER, m.AttEnd) AND att.AttTime > m.WorkStart AND datediff(mi, isnull(ta.AttStart, m.WorkStart), att.AttTime) >= isnull(m.INOUT_MINIMUM, 0)
			GROUP BY ta.EmployeeID, ta.AttDate
			) tmp ON ta.EmployeeID = tmp.EmployeeID AND ta.AttDate = tmp.AttDate AND ta.Period = @RepeatTime AND ta.TAStatus IN (1, 0) AND ta.SwipeOptionID = 0

		-- nếu k lấy được giờ ca thì lấy giờ ra cuối ngày
		UPDATE #tblHasTA_insert
		SET AttEnd = m.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate AND m.SwipeOptionID = 0
		WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (1, 0) AND ta.AttEnd IS NULL AND (ta.AttStart < m.AttEnd OR (ta.AttStart IS NULL AND ta.Period = 0)) AND ta.SwipeOptionID = 0

		-- period 0 ko lay dc gio vao thi lay trong #tblShiftDetectorMatched
		UPDATE #tblHasTA_insert
		SET AttStart = m.AttStart
		FROM #tblHasTA_insert ta
		INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate AND m.SwipeOptionID = 0
		WHERE ta.Period = 0 AND ta.TAStatus IN (0, 2) AND ta.AttStart IS NULL AND (ta.AttEnd > m.AttStart OR ta.AttEnd IS NULL) AND ta.SwipeOptionID = 0

		/*
 -- nghỉ cả ngày mà bấm thiéu đàu thì bỏ
 update m set AttStart = null, AttEnd = null from #tblHasTA_insert m where ((m.AttStart is not null and m.AttEnd is null ) or (m.AttStart is null and m.AttEnd is not null))
 and exists (select 1 from #tblLvHistory lv where lv.LeaveCategory = 1 and lv.EmployeeID = m.EmployeeId and m.AttDate = lv.LeaveDate and lv.LeaveStatus = 3)  and m.SwipeOptionID=0
 */
		-- loại những records đã xử lý xong
		DELETE m
		FROM #tblShiftDetectorMatched m
		WHERE EXISTS (
				SELECT 1
				FROM #tblHasTA_insert ta
				WHERE ta.Period = @RepeatTime AND ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND (ta.AttEnd >= m.AttEnd OR (ta.AttStart = m.AttStart AND m.AttEnd IS NULL)) AND ta.SwipeOptionID = 0
				) OR (m.AttStart IS NULL AND m.AttEnd IS NULL) AND m.SwipeOptionID = 0

		DELETE m
		FROM #tblShiftDetectorMatched m
		WHERE EXISTS (
				SELECT 1
				FROM #tblHasTA_insert ta
				WHERE ta.Period = @RepeatTime AND ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND (ta.AttStart >= m.AttEnd) AND ta.SwipeOptionID = 0
				) AND m.SwipeOptionID = 0

		IF EXISTS (
				SELECT 1
				FROM #tblShiftDetectorMatched
				WHERE SwipeOptionID = 0
				) AND @RepeatTime < 5
		BEGIN
			UPDATE m
			SET AttEndYesterday = ta.AttEnd
			FROM #tblShiftDetectorMatched m
			INNER JOIN #tblHasTA_insert ta ON m.EmployeeId = ta.EmployeeID AND m.ScheduleDate = ta.AttDate
			WHERE ta.Period = @RepeatTime AND ta.SwipeOptionID = 0

			SET @RepeatTime += 1

			GOTO RepeatInsertHasTAOption5
		END
	END

	SET @RepeatTime = 0

	IF EXISTS (
			SELECT TOP 1 *
			FROM #tblShiftDetectorMatched
			WHERE SwipeOptionID = 1
			) --Ngày bấm 2 lần vào bấm công về bấm công
	BEGIN
		--HPSF
		-- vao thì lấy sớm nhất, ra thì lấy trễ nhất
		UPDATE #tblShiftDetectorMatched
		SET AttEnd = tmp.AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN (
			SELECT m.EmployeeId, m.ScheduleDate, max(t.AttTime) AttTime
			FROM #tblShiftDetectorMatched m
			INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
			WHERE ((t.AttTime > m.AttEnd AND t.AttTime < m.TIMEOUTAFTER) OR m.AttEnd IS NULL) AND t.AttTime < m.AttStartTomorrow AND t.AttTime > m.AttEndYesterday AND (t.AttTime > m.AttStart OR m.AttStart IS NULL) AND t.AttTime < m.TIMEOUTAFTER AND (t.AttTime >= dateadd(mi, @TA_INOUT_MINIMUM, m.AttStart)) AND (t.AttState IN (0, 2))
			GROUP BY m.EmployeeId, m.ScheduleDate
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.SwipeOptionID = 1

		-- --Giao ca quá sát nhau nhận nhầm giờ ra của người hôm trước thành giờ vào của ngày hôm nay
		--  UPDATE m SET AttStart = NULL
		--  FROM #tblShiftDetectorMatched m
		--  INNER JOIN #tblShiftDetectorMatched n ON n.EmployeeId = m.EmployeeId AND DATEADD(DAY, -1, m.ScheduleDate) = n.ScheduleDate
		--  WHERE m.AttEnd IS NULL AND m.ShiftCode NOT LIKE '%Đ%' AND n.ShiftCode LIKE '%Đ%' AND m.AttStart = n.AttEnd
		UPDATE #tblShiftDetectorMatched
		SET AttStart = tmp.AttTime
		FROM #tblShiftDetectorMatched m
		INNER JOIN (
			SELECT m.EmployeeId, m.ScheduleDate, min(t.AttTime) AttTime
			FROM #tblShiftDetectorMatched m
			INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
			WHERE ((t.AttTime < m.AttStart OR AttStart IS NULL) AND t.AttTime > m.TIMEINBEFORE) AND t.AttTime > m.AttEndYesterday AND t.atttime < dateadd(mi, - 30, m.AttStartTomorrow) AND t.AttTime < dateadd(mi, - 1 * m.INOUT_MINIMUM, m.AttEnd)
			GROUP BY m.EmployeeId, m.ScheduleDate
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.ScheduleDate = tmp.ScheduleDate AND m.SwipeOptionID = 1

		DELETE ta
		FROM tblHasTA TA
		WHERE TA.Period > 0 AND EXISTS (
				SELECT 1
				FROM #tblShiftDetectorMatched M
				WHERE TA.EmployeeID = M.EmployeeId AND ta.AttDate = m.ScheduleDate AND M.ScheduleDate BETWEEN @FromDate AND @ToDate AND m.SwipeOptionID = 1
				)

		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkingTime, StdWorkingTimeMi, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, @RepeatTime, 0
			--,case when HolidayStatus = 0 then WorkingTimeMi/60.0 else (AttEndMi - AttStartMi)/60.0 end , StdWorkingTimeMi,SwipeOptionID from #tblShiftDetectorMatched m where ScheduleDate between @FromDate and @ToDate and m.SwipeOptionID = 1
			, CASE 
				WHEN HolidayStatus = 0
					THEN WorkingTimeMi / 60.0
				ELSE NULL
				END, StdWorkingTimeMi, SwipeOptionID
		FROM #tblShiftDetectorMatched m
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND m.SwipeOptionID = 1

		UPDATE #tblHasTA_insert
		SET AttStart = m.AttStart, AttEnd = m.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblShiftDetectorMatched m ON ta.EmployeeId = m.EmployeeID AND ta.AttDate = m.ScheduleDate AND m.SwipeOptionID = 1
		WHERE ta.Period = @RepeatTime AND ta.TAStatus IN (0, 1, 2) AND ta.SwipeOptionID = 1

		-- dữ liệu đã đc xử lý
		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttStart = CASE 
				WHEN a.TAStatus IN (1, 3)
					THEN a.AttStart
				ELSE ta.AttStart
				END, AttEnd = CASE 
				WHEN a.TAStatus IN (2, 3)
					THEN a.AttEnd
				ELSE ta.AttEnd
				END
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus IN (1, 2, 3) AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 1

		/*
 -- nghỉ cả ngày mà bấm thiếu đàu thì bỏ
 update m set AttStart = null, AttEnd = null from #tblHasTA_insert m where ((m.AttStart is not null and m.AttEnd is null ) or (m.AttStart is null and m.AttEnd is not null))
 and exists (select 1 from #tblLvHistory lv where lv.LeaveCategory = 1 and lv.EmployeeID = m.EmployeeId and m.AttDate = lv.LeaveDate and lv.LeaveStatus = 3 and @LEAVEFULLDAYSTILLHASATTTIME = 2) and m.SwipeOptionID = 1
 */
		-- loại những records đã xử lý xong
		DELETE m
		FROM #tblShiftDetectorMatched m
		WHERE EXISTS (
				SELECT 1
				FROM #tblHasTA_insert ta
				WHERE ta.Period = @RepeatTime AND ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND (ta.AttEnd >= m.AttEnd OR (ta.AttStart = m.AttStart AND m.AttEnd IS NULL)) AND ta.SwipeOptionID = 1
				) OR (m.AttStart IS NULL AND m.AttEnd IS NULL) AND m.SwipeOptionID = 1

		DELETE m
		FROM #tblShiftDetectorMatched m
		WHERE EXISTS (
				SELECT 1
				FROM #tblHasTA_insert ta
				WHERE ta.Period = @RepeatTime AND ta.EmployeeID = m.EmployeeId AND ta.AttDate = m.ScheduleDate AND (ta.AttStart >= m.AttEnd) AND ta.SwipeOptionID = 1
				) AND m.SwipeOptionID = 1
	END

	SET @RepeatTime = 0

	IF EXISTS (
			SELECT TOP 1 *
			FROM #tblShiftDetectorMatched
			WHERE SwipeOptionID = 2
			) --Sang bam bam, chieu bam, tang ca bam rieng
	BEGIN
		-- cap nhat lai OTAfter neu chua co
		UPDATE m
		SET OTAfterStart = DATEADD(mi, ss.OTAfterStartMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTAfterStart IS NULL AND m.SwipeOptionID = 2

		UPDATE m
		SET OTAfterEnd = DATEADD(mi, ss.OTAfterEndMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTAfterEnd IS NULL AND m.SwipeOptionID = 2

		UPDATE m
		SET OTBeforeStart = DATEADD(mi, ss.OTBeforeStartMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTBeforeStart IS NULL AND m.SwipeOptionID = 2

		UPDATE m
		SET OTBeforeEnd = DATEADD(mi, ss.OTBeforeEndMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTBeforeEnd IS NULL AND m.SwipeOptionID = 2

		-- buoi sang
		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut, WorkingTime, StdWorkingTimeMi, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, 0, 0, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(MI, - @TA_TIMEINBEFORE / 2, WorkStart), dateadd(mi, - 120, WorkEnd)
			--,dateadd(MI,-@TA_TIMEINBEFORE,WorkStart),dateadd(mi,-120,WorkEnd)
			--,dateadd(HOUR,@TA_TIMEOUTAFTER,WorkStart)
			, dateadd(mi, datediff(mi, BreakEnd, WorkEnd) / 2, WorkEnd), CASE 
				WHEN HolidayStatus = 0
					THEN WorkingTimeMi / 60.0
				ELSE (AttEndMi - AttStartMi) / 60.0
				END, StdWorkingTimeMi, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET MinTimeOut = DATEADD(MI, @TA_INOUT_MINIMUM, WorkStart)

		--gio vao
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND t.AttTime < m.WorkEnd AND t.AttTime > m.AttEndYesterday AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		-- gio ra
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.WorkEnd AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		--select MinTimeIn,WorkEnd,MinTimeOut,MaxTimeIn,MaxTimeOut,* from #tblHasTA_insert where Attdate='20200912' return
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime < m.AttEnd AND t.AttTime > m.MinTimeIn AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND t.AttTime > m.WorkStart AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttStart AND t.AttTime < m.MaxTimeOut AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		-- tang ca sau
		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, 1, 0, OTAfterStart, OTAfterEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(hour, - 1, OTAfterStart), dateadd(mi, - datediff(mi, OTAfterStart, OTAfterEnd) / 2, OTAfterEnd)
			--,dateadd(HOUR,@TA_TIMEOUTAFTER,WorkStart)
			, TIMEOUTAFTER, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET MinTimeOut = DATEADD(SECOND, 1, MaxTimeIn)
		WHERE MinTimeOut IS NULL AND SwipeOptionID = 2

		--update #tblHasTA_insert set MinTimeOut = DATEADD(MI,@TA_INOUT_MINIMUM,WorkStart)  where SwipeOptionID = 2
		UPDATE m1
		SET AttEndYesterday = isnull(m2.AttEnd, m2.MinTimeOut)
		FROM #tblHasTA_insert m1
		INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1 --where (m2.AttEnd is not null )
			AND m1.Period = 1 AND m1.SwipeOptionID = 2 AND m2.SwipeOptionID = 2

		--update m1 set AttStartTomorrow = isnull(m2.AttStart,m2.workStart) from #tblHasTA_insert m1 inner join #tblHasTA_insert m2 on m1.EmployeeId = m2.EmployeeId and m1.AttDate = m2.AttDate and m1.Period = m2.Period-1
		-- where m1.Period = 1
		UPDATE m1
		SET AttStartTomorrow = isnull(m2.AttStart, m2.workStart)
		FROM #tblHasTA_insert m1
		INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = DateADD(Day, - 1, m2.AttDate) AND m2.Period = 0
		WHERE m1.Period = 1 AND m1.SwipeOptionID = 2 AND m2.SwipeOptionID = 2

		--Giờ AttStartTomorow nên lấy của ngày hôm sau
		-- gio vao
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime < m.WorkEnd AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime < m.WorkEnd AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND m.AttEndYesterday IS NULL AND T.AttTime < m.AttStartTomorrow AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		-- gio ra ưu tiên lấy giờ trước giờ ra về xong mới đến sau giờ ra về
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.WorkEnd AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.WorkEnd AND m.MaxTimeOut AND t.AttTime >= m.MinTimeOut --thanh123
				AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttEnd IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND t.AttTime > m.WorkStart AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime > m.AttStart AND t.AttTime < m.MaxTimeOut AND t.AttTime >= m.AttStart AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.AttStart IS NULL AND m.TAStatus = 0 AND m.Period = 1 AND (T.AttTime > m.AttEndYesterday OR m.AttEndYesterday IS NULL) AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime < m.AttEnd AND t.AttTime BETWEEN m.MinTimeIn AND m.MinTimeOut AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 2

		-- liet ke ra nhung record bao vao cua period sau lay nham sang bam ra cua period truoc
		UPDATE t
		SET AttEnd = s.AttStart
		FROM #tblHasTA_insert t
		INNER JOIN #tblHasTA_insert s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.AttDate AND s.SwipeOptionID = 2 AND t.Period = s.Period - 1
		WHERE t.AttEnd IS NULL AND t.AttStart IS NOT NULL AND t.Period <= 1 AND s.AttEnd IS NOT NULL AND s.AttStart IS NOT NULL AND EXISTS (
				SELECT 1
				FROM #tblTmpAttend_Org att
				WHERE att.EmployeeID = t.EmployeeID AND att.AttTime > s.AttStart AND att.AttTime < s.AttEnd
				) AND t.SwipeOptionID = 2

		UPDATE t
		SET AttEnd = s.AttStart
		FROM #tblHasTA_insert t
		INNER JOIN #tblHasTA_insert s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.AttDate AND s.SwipeOptionID = 2 AND t.Period = s.Period - 1
		WHERE t.AttEnd IS NULL AND t.AttStart IS NOT NULL AND t.Period <= 1 AND s.AttEnd IS NOT NULL AND s.AttStart IS NOT NULL AND EXISTS (
				SELECT 1
				FROM #tblTmpAttend_Org att
				WHERE att.EmployeeID = t.EmployeeID AND att.AttTime > s.AttStart AND att.AttTime < s.AttEnd
				) AND t.SwipeOptionID = 2

		UPDATE m1
		SET AttEndYesterday = m2.AttEnd
		FROM #tblHasTA_insert m1
		INNER JOIN #tblHasTA_insert m2 ON m1.EmployeeId = m2.EmployeeId AND m1.AttDate = m2.AttDate AND m1.Period = m2.Period + 1 --where (m2.AttEnd is not null)
			AND m1.SwipeOptionID = 2 AND m2.SwipeOptionID = 2

		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, min(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_Org t ON m.EmployeeId = t.EmployeeID
			WHERE m.TAStatus = 0 AND m.Period > 0 AND T.AttTime > m.AttEndYesterday AND T.AttTime < m.AttStartTomorrow AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime < m.AttEnd AND t.AttTime > m.MinTimeIn AND m.SwipeOptionID = 2
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period
		WHERE m.AttEndYesterday = m.AttStart AND m.SwipeOptionID = 2

		-- k đụng vào những ngày người dùng modified
		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 2

		--- co gang la gio ra cho buoi chieu
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert i
		INNER JOIN (
			SELECT i.EmployeeID, i.AttDate, i.Period, MIN(att.AttTime) AttTime
			FROM #tblHasTA_insert i
			INNER JOIN #tblHasTA_insert t ON i.employeeId = t.EmployeeId AND i.AttDate = t.AttDate AND t.Period = 1 AND i.Period = 0 AND t.SwipeOptionID = 2
			INNER JOIN #tblTmpAttend_Org att ON i.employeeId = att.EmployeeId AND att.AttTime < t.AttStart AND att.AttTime > i.MinTimeOut
			WHERE i.Period = 1 AND i.AttEnd IS NULL AND i.SwipeOptionID = 2 AND t.AttStart IS NOT NULL
			GROUP BY i.EmployeeID, i.AttDate, i.Period
			) tmp ON i.EmployeeId = tmp.EmployeeId AND i.AttDate = tmp.AttDate AND i.Period = tmp.Period

		-- lam dep lai du lieu
		UPDATE i1
		SET AttEnd = i2.AttStart
		FROM #tblHasTA_insert i1
		INNER JOIN #tblHasTA_insert i2 ON i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate AND i2.SwipeOptionID = 2
		WHERE i1.Period = i2.Period - 1 AND i1.AttEnd IS NULL AND i2.AttStart IS NOT NULL AND i2.AttEnd IS NULL AND i1.SwipeOptionID = 2

		UPDATE i2
		SET AttStart = NULL
		FROM #tblHasTA_insert i1
		INNER JOIN #tblHasTA_insert i2 ON i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate AND i2.SwipeOptionID = 2
		WHERE i1.Period = i2.Period - 1 AND i1.AttEnd = i2.AttStart AND i2.AttEnd IS NULL AND i1.SwipeOptionID = 2

		UPDATE j
		SET AttStart = i.AttEnd
		FROM #tblHasTA_insert i
		INNER JOIN #tblHasTA_insert j ON i.EmployeeId = j.EmployeeId AND i.AttDate = j.AttDate AND i.Period = j.Period - 1 AND j.SwipeOptionID = 2
		WHERE i.AttStart IS NULL AND i.AttEnd IS NOT NULL AND j.AttStart IS NULL AND j.AttEnd IS NOT NULL AND j.AttEnd > dateadd(hour, - 1, j.WorkEnd) AND i.SwipeOptionID = 2

		UPDATE i
		SET AttEnd = NULL
		FROM #tblHasTA_insert i
		INNER JOIN #tblHasTA_insert j ON i.EmployeeId = j.EmployeeId AND i.AttDate = j.AttDate AND i.Period = j.Period - 1 AND j.SwipeOptionID = 2
		WHERE i.AttStart IS NULL AND i.AttEnd = j.AttStart AND j.AttEnd IS NOT NULL AND j.AttEnd > dateadd(hour, - 1, j.WorkEnd) AND i.SwipeOptionID = 2

		--- co gang la gio vao cho buoi chieu
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert i
		INNER JOIN (
			SELECT i.EmployeeID, i.AttDate, i.Period, min(att.AttTime) AttTime
			FROM #tblHasTA_insert i
			INNER JOIN #tblHasTA_insert t ON i.employeeId = t.EmployeeId AND i.AttDate = t.AttDate AND t.Period = 0 AND i.Period = 1 AND t.SwipeOptionID = 2
			INNER JOIN #tblTmpAttend_Org att ON i.employeeId = att.EmployeeId AND att.AttTime > isnull(t.AttStart, t.MinTimeOut) -- and att.AttTime < i.AttEnd
			WHERE i.Period = 0 AND i.AttStart IS NULL AND i.AttEnd IS NOT NULL AND i.SwipeOptionID = 2
			GROUP BY i.EmployeeID, i.AttDate, i.Period
			) tmp ON i.EmployeeId = tmp.EmployeeId AND i.AttDate = tmp.AttDate AND i.Period = tmp.Period

		UPDATE #tblHasTA_insert
		SET AttStart = NULL
		WHERE period = 1 AND AttStart = AttEnd AND AttStart > MaxTimeIn AND SwipeOptionID = 2

		-- khong co tang ca thi bo di
		DELETE #tblHasTA_insert
		WHERE Period = 1 AND AttStart IS NULL AND AttEnd IS NULL AND SwipeOptionID = 2
	END

	SET @RepeatTime = 0

	IF EXISTS (
			SELECT TOP 1 1
			FROM #tblShiftDetectorMatched
			WHERE SwipeOptionID = 3
			) --Sáng bấm, trưa bấm, chiều bấm và/hoặc tăng ca bấm công
	BEGIN
		-- cap nhat lai OTAfter neu chua co
		UPDATE m
		SET OTAfterStart = DATEADD(mi, ss.OTAfterStartMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTAfterStart IS NULL AND m.SwipeOptionID = 3

		UPDATE m
		SET OTAfterEnd = DATEADD(mi, ss.OTAfterEndMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTAfterEnd IS NULL AND m.SwipeOptionID = 3

		UPDATE m
		SET OTBeforeStart = DATEADD(mi, ss.OTBeforeStartMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTBeforeStart IS NULL AND m.SwipeOptionID = 3

		UPDATE m
		SET OTBeforeEnd = DATEADD(mi, ss.OTBeforeEndMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTBeforeEnd IS NULL AND m.SwipeOptionID = 3

		--ShiftMeal = 1 ăn cơm bth
		--ShiftMeal = 2 là nghỉ buổi sáng
		--ShiftMeal = 3 là nghi buổi chiều
		UPDATE d
		SET ShiftMeal = 1
		FROM #tblShiftDetectorMatched d
		WHERE d.AttStart <= dateadd(mi, 30, d.BreakStart) AND d.AttEnd >= dateadd(mi, - 15, d.BreakEnd)

		UPDATE d
		SET ShiftMeal = 2
		FROM #tblShiftDetectorMatched d
		WHERE ShiftMeal IS NULL AND ISNULL(d.AttStart, d.BreakEnd) > BreakStart AND ISNULL(d.AttEnd, d.BreakEnd) > BreakStart AND ISNULL(AttStart, AttEnd) IS NOT NULL

		UPDATE d
		SET ShiftMeal = 3
		FROM #tblShiftDetectorMatched d
		WHERE ShiftMeal IS NULL AND ISNULL(d.AttStart, d.BreakStart) < BreakEnd AND ISNULL(d.AttEnd, d.BreakStart) < BreakEnd AND ISNULL(AttStart, AttEnd) IS NOT NULL

		UPDATE #tblShiftDetectorMatched
		SET IsOTAfter = 1
		WHERE AttEnd >= dateadd(mi, 30, OTAfterStart)

		-- buoi sang
		INSERT INTO #tblHasTA_insert (EmployeeID, Attdate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MinTimeOut, MaxTimeOut, WorkingTime, StdWorkingTimeMi, SwipeOptionID)
		SELECT EmployeeId, ScheduleDate, 0, 0, WorkStart, BreakStart, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(MI, - @TA_TIMEINBEFORE, WorkStart), CASE 
				WHEN ShiftMeal = 3
					THEN dateadd(mi, - datediff(mi, WorkStart, BreakStart) / 2, BreakStart)
				ELSE dateadd(ss, - 1, dateadd(mi, BreakStartMi, ScheduleDate))
				END, CASE 
				WHEN ShiftMeal = 3
					THEN dateadd(ss, 1, dateadd(mi, - datediff(mi, WorkStart, BreakStart) / 2, BreakStart))
				ELSE dateadd(mi, BreakStartMi, ScheduleDate)
				END, CASE 
				WHEN ShiftMeal = 3
					THEN BreakEnd
				ELSE dateadd(mi, BreakStartMi + 30, ScheduleDate)
				END, CASE 
				WHEN HolidayStatus = 0
					THEN WorkingTimeMi / 60.0
				ELSE (AttEndMi - AttStartMi) / 60.0
				END, StdWorkingTimeMi, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 3 AND isnull(ShiftMeal, 0) <> 2

		-- gio vao 1
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 3
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 3

		--gio ra 1
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.MaxTimeOut AND m.SwipeOptionID = 3
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 3

		-- buoi chieu
		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MinTimeOut, MaxTimeOut, WorkingTime, StdWorkingTimeMi, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, 1, 0, BreakEnd, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, CASE 
				WHEN ShiftMeal = 2
					THEN BreakStart
				ELSE DATEADD(MI, - 15, BreakEnd)
				END, CASE 
				WHEN ShiftMeal = 2
					THEN dateadd(mi, datediff(mi, BreakEnd, WorkEnd) / 2, BreakEnd)
				ELSE BreakEnd
				END, CASE 
				WHEN ShiftMeal = 2
					THEN DATEADD(SS, 1, dateadd(mi, datediff(mi, BreakEnd, WorkEnd) / 2, BreakEnd))
				ELSE DATEADD(SS, 1, BreakEnd)
				END, CASE 
				WHEN IsOTAfter = 1
					THEN dateadd(mi, datediff(mi, WorkEnd, OTAfterStart) / 2, WorkEnd)
				ELSE OTAfterStart
				END, CASE 
				WHEN HolidayStatus = 0
					THEN WorkingTimeMi / 60.0
				ELSE (AttEndMi - AttStartMi) / 60.0
				END, StdWorkingTimeMi, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 3 AND isnull(ShiftMeal, 0) <> 3

		-- gio vao 2
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.Period = 1 AND m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 3
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 3

		--gio ra 2
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.Period = 1 AND m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.MaxTimeOut AND m.SwipeOptionID = 3
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 3

		-- tang ca sau
		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MaxTimeOut, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, 2, 0, OTAfterStart, OTAfterEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(ss, 1, dateadd(mi, datediff(mi, WorkEnd, OTAfterStart) / 2, WorkEnd)), dateadd(hh, 1, dateadd(mi, datediff(mi, WorkEnd, OTAfterStart) / 2, WorkEnd)), TIMEOUTAFTER, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 3 AND IsOTAfter = 1

		UPDATE #tblHasTA_insert
		SET MinTimeOut = DATEADD(SECOND, 1, MaxTimeIn)
		WHERE MinTimeOut IS NULL AND SwipeOptionID = 3 AND Period = 2

		-- gio vao 3
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.Period = 2 AND m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 3
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 3

		--gio ra 3
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.Period = 2 AND m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.MaxTimeOut AND m.SwipeOptionID = 3
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 3

		-- k đụng vào những ngày người dùng modified
		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 3
	END

	SET @RepeatTime = 0

	IF EXISTS (
			SELECT TOP 1 1
			FROM #tblShiftDetectorMatched
			WHERE SwipeOptionID = 4
			) -- Vao bam, nghi giua ca bam, ve bam
	BEGIN
		-- cap nhat lai OTAfter neu chua co
		UPDATE m
		SET OTAfterStart = DATEADD(mi, ss.OTAfterStartMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTAfterStart IS NULL AND m.SwipeOptionID = 4

		UPDATE m
		SET OTAfterEnd = DATEADD(mi, ss.OTAfterEndMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTAfterEnd IS NULL AND m.SwipeOptionID = 4

		UPDATE m
		SET OTBeforeStart = DATEADD(mi, ss.OTBeforeStartMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTBeforeStart IS NULL AND m.SwipeOptionID = 4

		UPDATE m
		SET OTBeforeEnd = DATEADD(mi, ss.OTBeforeEndMi, m.ScheduleDate)
		FROM #tblShiftDetectorMatched m
		INNER JOIN #tblShiftSetting ss ON m.ShiftCode = ss.ShiftCode
		WHERE OTBeforeEnd IS NULL AND m.SwipeOptionID = 4

		--ShiftMeal = 1 ăn cơm bth
		--ShiftMeal = 2 là nghỉ buổi sáng
		--ShiftMeal = 3 là nghi buổi chiều
		UPDATE d
		SET ShiftMeal = 1
		FROM #tblShiftDetectorMatched d
		WHERE d.AttStart <= dateadd(mi, 30, d.BreakStart) AND d.AttEnd >= dateadd(mi, - 15, d.BreakEnd)

		UPDATE d
		SET ShiftMeal = 2
		FROM #tblShiftDetectorMatched d
		WHERE ShiftMeal IS NULL AND ISNULL(d.AttStart, d.BreakEnd) > BreakStart AND ISNULL(d.AttEnd, d.BreakEnd) > BreakStart AND ISNULL(AttStart, AttEnd) IS NOT NULL

		UPDATE d
		SET ShiftMeal = 3
		FROM #tblShiftDetectorMatched d
		WHERE ShiftMeal IS NULL AND ISNULL(d.AttStart, d.BreakStart) < BreakEnd AND ISNULL(d.AttEnd, d.BreakStart) < BreakEnd AND ISNULL(AttStart, AttEnd) IS NOT NULL

		--ALTER TABLE #tblHasTA_insert ADD ShiftMeal INT
		-- buoi sang
		--12:30 --- 13:30, ShiftMeal = 1 định nghĩa những người có ăn trưa và phải chấm công đúng quy định
		--Nếu ShiftMeal = 0 thì chấm công có thể giãn ra (nghỉ giữa buổi có thể chấm công vào buổi chiều sớm hơn giờ quy định)
		--VŨ: có ăn trưa check out trong khoảng 12h30 đến 13h00 (-30p thời gian checkout theo quy định)
		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MinTimeOut, MaxTimeOut, WorkingTime, StdWorkingTimeMi, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, 0, 0, WorkStart, BreakStart, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, dateadd(MI, - @TA_TIMEINBEFORE, WorkStart), CASE 
				WHEN ShiftMeal = 3
					THEN dateadd(mi, - datediff(mi, WorkStart, BreakStart) / 2, BreakStart)
				ELSE dateadd(ss, - 1, dateadd(mi, BreakStartMi, ScheduleDate))
				END, CASE 
				WHEN ShiftMeal = 3
					THEN dateadd(ss, 1, dateadd(mi, - datediff(mi, WorkStart, BreakStart) / 2, BreakStart))
				ELSE dateadd(mi, BreakStartMi, ScheduleDate)
				END, CASE 
				WHEN ShiftMeal = 3
					THEN BreakEnd
				ELSE dateadd(mi, BreakStartMi + 30, ScheduleDate)
				END, CASE 
				WHEN HolidayStatus = 0
					THEN WorkingTimeMi / 60.0
				ELSE (AttEndMi - AttStartMi) / 60.0
				END, StdWorkingTimeMi, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 4 AND ISNULL(ShiftMeal, 0) <> 2 --Nghỉ buổi sáng
			--update #tblHasTA_insert set MinTimeOut = DATEADD(SECOND,1,MaxTimeIn)

		-- gio vao 1
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 4
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 4

		--gio ra 1
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.MaxTimeOut AND m.SwipeOptionID = 4
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 4

		--thanh123
		-- buoi chieu hoac tang ca sau
		INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, Period, TAStatus, WorkStart, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM, MinTimeIn, MaxTimeIn, MinTimeOut, MaxTimeOut, WorkingTime, StdWorkingTimeMi, SwipeOptionID)
		SELECT EmployeeID, ScheduleDate, 1, 0, BreakEnd, WorkEnd, AttEndYesterday, AttStartTomorrow, TIMEINBEFORE, TIMEOUTAFTER, INOUT_MINIMUM
			--,dateadd(mi,-@TA_TIMEINBEFORE,BreakEnd)
			, CASE 
				WHEN ShiftMeal = 2
					THEN BreakStart
				ELSE DATEADD(MI, - 15, BreakEnd)
				END, CASE 
				WHEN ShiftMeal = 2
					THEN dateadd(mi, datediff(mi, BreakEnd, WorkEnd) / 2, BreakEnd)
				ELSE BreakEnd
				END, CASE 
				WHEN ShiftMeal = 2
					THEN DATEADD(SS, 1, dateadd(mi, datediff(mi, BreakEnd, WorkEnd) / 2, BreakEnd))
				ELSE DATEADD(SS, 1, BreakEnd)
				END, TIMEOUTAFTER, CASE 
				WHEN HolidayStatus = 0
					THEN WorkingTimeMi / 60.0
				ELSE (AttEndMi - AttStartMi) / 60.0
				END, StdWorkingTimeMi, SwipeOptionID
		FROM #tblShiftDetectorMatched
		WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND SwipeOptionID = 4 AND ISNULL(ShiftMeal, 0) <> 3 --3 là nghỉ buổi chiều đã xét ở trên

		-- gio vao 2
		UPDATE #tblHasTA_insert
		SET AttStart = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, MIN(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.Period = 1 AND m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeIn AND m.maxtimein AND m.SwipeOptionID = 4
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 4

		--gio ra 2
		UPDATE #tblHasTA_insert
		SET AttEnd = tmp.AttTime
		FROM #tblHasTA_insert m
		INNER JOIN (
			SELECT m.EmployeeId, m.AttDate, m.Period, max(t.AttTime) AttTime
			FROM #tblHasTA_insert m
			INNER JOIN #tblTmpAttend_org t ON m.EmployeeId = t.EmployeeID
			WHERE m.Period = 1 AND m.TAStatus = 0 AND T.AttTime BETWEEN m.TIMEINBEFORE AND m.TIMEOUTAFTER AND t.AttTime BETWEEN m.MinTimeOut AND m.MaxTimeOut AND m.SwipeOptionID = 4
			GROUP BY m.EmployeeId, m.AttDate, m.Period
			) tmp ON m.EmployeeId = tmp.EmployeeId AND m.AttDate = tmp.AttDate AND m.Period = tmp.Period AND m.SwipeOptionID = 4

		-- k đụng vào những ngày người dùng modified
		UPDATE #tblHasTA_insert
		SET TAStatus = a.TAStatus, AttStart = a.AttStart, AttEnd = a.AttEnd
		FROM #tblHasTA_insert ta
		INNER JOIN #tblHasTA a ON ta.EmployeeID = a.EmployeeID AND ta.AttDate = a.AttDate AND ta.Period = a.Period
		WHERE a.TAStatus = 3 AND a.AttDate BETWEEN @FromDate AND @ToDate AND ta.SwipeOptionID = 4

		-- khong co tang ca thi bo di
		DELETE #tblHasTA_insert
		WHERE Period = 2 AND AttStart IS NULL AND AttEnd IS NULL AND SwipeOptionID = 4
	END
END

----VŨ: nếu là ngày vào làm thì hệ thống mặc định chấm công vào
--UPDATE #tblHasTA_insert SET AttStart = h.WorkStart
--FROM #tblHasTA_insert h
--INNER JOIN #tblEmployeeList e ON e.EmployeeID = h.EmployeeID
--LEFT JOIN #tblShiftDetectorMatched s ON s.EmployeeId = h.EmployeeID AND s.ScheduleDate = h.Attdate
--WHERE h.Attdate = e.HireDate AND h.TAStatus = 0 AND h.Period = 0 AND  s.HolidayStatus = 0 AND (h.AttStart IS NULL OR h.AttStart > h.WorkStart)
--  AND NOT EXISTS(SELECT 1 FROM tblLvHistory lv WHERE lv.EmployeeID = h.EmployeeID AND lv.LeaveDate = h.Attdate AND lv.LeaveStatus IN(1, 3))
-- nhung nguoi di lam 2 ca 1 ngay
INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, AttStart, AttEnd, Period, TAStatus, StdWorkingTimeMi)
SELECT EmployeeID, ScheduleDate, AttStart1, AttEnd1, 0, 0, WorkEndMi1 - WorkStartMi1
FROM #tblWorking2ShiftADay_Detect

INSERT INTO #tblHasTA_insert (EmployeeID, AttDate, AttStart, AttEnd, Period, TAStatus, StdWorkingTimeMi)
SELECT EmployeeID, ScheduleDate, AttStart2, AttEnd2, 1, 0, WorkEndMi2 - WorkStartMi2
FROM #tblWorking2ShiftADay_Detect

-- nhung nguoi ko can cham cong
IF COL_LENGTH('tempdb..#tblHasTA_insert', 'NotTASaturday') IS NULL
	ALTER TABLE #tblHasTA_insert ADD NotTASaturday INT

UPDATE #tblHasTA_insert
SET NotTASaturday = 1
FROM #tblHasTA_insert s
INNER JOIN #tblEmployeeList e ON s.EmployeeId = e.EmployeeID
WHERE e.TAOptionID = 4 AND DATENAME(dw, s.Attdate) = 'Saturday'

UPDATE ta
SET AttStart = WorkStart
FROM #tblHasTA_insert ta
WHERE isnull(ta.NotTASaturday, 0) = 0 AND (ta.AttStart IS NULL OR ta.AttStart > ta.WorkStart) AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE ta.EmployeeID = te.EmployeeID AND te.NotCheckTA = 1
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblWSchedule m
		WHERE ta.EmployeeID = m.EmployeeId AND ta.Attdate = m.ScheduleDate AND m.HolidayStatus > 0
		) AND TAStatus NOT IN (1, 3)

UPDATE ta
SET AttEnd = WorkEnd
FROM #tblHasTA_insert ta
WHERE isnull(ta.NotTASaturday, 0) = 0 AND (ta.AttEnd IS NULL OR ta.AttEnd < ta.WorkEnd) AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList te
		WHERE ta.EmployeeID = te.EmployeeID AND te.NotCheckTA = 1
		) AND NOT EXISTS (
		SELECT 1
		FROM #tblWSchedule m
		WHERE ta.EmployeeID = m.EmployeeId AND ta.Attdate = m.ScheduleDate AND m.HolidayStatus > 0
		) AND TAStatus NOT IN (2, 3)

-- bo nhung du lieu ko hop le
DELETE I2
FROM #tblHasTA_insert i1
INNER JOIN #tblHasTA_insert i2 ON i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate
WHERE i1.Period = i2.Period - 1 AND i1.AttEnd >= i2.AttStart

-- sua lai PeriodID cho nhung record đã fix
UPDATE ta
SET Period = f.Period
FROM #tblHasTA_insert ta
INNER JOIN #tblHasTA_Fixed f ON ta.EmployeeID = f.EmployeeID AND ta.Attdate = f.Attdate AND ta.AttStart = f.AttStart AND ta.Period <> f.Period

ALTER TABLE #tblHasta_insert ADD WorkingTimeMi INT, IsLeaveStatus3 INT

UPDATE #tblHasTA_insert
SET IsLeaveStatus3 = 0

UPDATE ta1
SET IsLeaveStatus3 = CASE 
		WHEN lv.LeaveStatus = 3
			THEN 1
		ELSE 0
		END
FROM #tblHasTA_insert ta1
INNER JOIN tbllvhistory lv ON ta1.EmployeeID = lv.EmployeeID AND ta1.Attdate = lv.LeaveDate

IF (object_id('sp_ShiftDetector_UpdateHasTA_ChangeAttTime') IS NULL)
	EXEC ('CREATE PROCEDURE sp_ShiftDetector_UpdateHasTA_ChangeAttTime(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime) as')

SET @StopUpdate = 0

EXEC sp_ShiftDetector_UpdateHasTA_ChangeAttTime @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

IF @StopUpdate = 0
BEGIN
	UPDATE ta1
	SET AttEndMi = datepart(hour, AttEnd) * 60 + datepart(mi, AttEnd), AttStartMi = datepart(hour, AttStart) * 60 + datepart(mi, AttStart), WorkStartMi = datepart(hour, isnull(ta1.WorkStart, ss.WorkStart)) * 60 + datepart(mi, isnull(ta1.WorkStart, ss.WorkStart)), WorkEndMi = datepart(hour, isnull(ta1.WorkEnd, ss.WorkEnd)) * 60 + datepart(mi, isnull(ta1.WorkEnd, ss.WorkEnd)), BreakStartMi = datepart(hour, ss.BreakStart) * 60 + datepart(mi, ss.BreakStart), BreakEndMi = datepart(hour, ss.BreakEnd) * 60 + datepart(mi, ss.BreakEnd), ShiftCode = ss.ShiftCode
	FROM #tblHasTA_insert ta1
	INNER JOIN tblWSchedule ws ON ta1.EmployeeID = ws.EmployeeID AND ta1.Attdate = ws.ScheduleDate
	INNER JOIN tblShiftSetting ss ON ws.ShiftID = ss.ShiftID

	UPDATE ta1
	SET AttEndMi = datepart(hour, AttEnd) * 60 + datepart(mi, AttEnd), AttStartMi = datepart(hour, AttStart) * 60 + datepart(mi, AttStart), WorkStartMi = datepart(hour, isnull(ta1.WorkStart, ss.WorkStart)) * 60 + datepart(mi, isnull(ta1.WorkStart, ss.WorkStart)), WorkEndMi = datepart(hour, isnull(ta1.WorkEnd, ss.WorkEnd)) * 60 + datepart(mi, isnull(ta1.WorkEnd, ss.WorkEnd)), BreakStartMi = datepart(hour, ss.BreakStart) * 60 + datepart(mi, ss.BreakStart), BreakEndMi = datepart(hour, ss.BreakEnd) * 60 + datepart(mi, ss.BreakEnd), ShiftCode = ss.ShiftCode
	FROM #tblHasTA_insert ta1
	INNER JOIN #tblWorking2ShiftADay_Detect ws ON ta1.EmployeeID = ws.EmployeeID AND ta1.Attdate = ws.ScheduleDate
	INNER JOIN #tblShiftSetting tss ON ws.ShiftCode2 = tss.ShiftCode
	INNER JOIN tblShiftSetting ss ON tss.ShiftID = ss.ShiftID
	WHERE ta1.Period = 1
END

UPDATE #tblHasTA_insert
SET BreakStartMi = 1440 + BreakStartMi
WHERE BreakStartMi < WorkStartMi AND WorkStartMi > WorkEndMi

UPDATE #tblHasTA_insert
SET BreakEndMi = 1440 + BreakEndMi
WHERE BreakEndMi < WorkStartMi AND WorkStartMi > WorkEndMi

UPDATE #tblHasTA_insert
SET WorkEndMi += 1440
WHERE WorkEndMi < WorkStartMi

UPDATE #tblHasTA_insert
SET BreakEndMi += 1440
WHERE BreakEndMi < BreakStartMi

UPDATE #tblHasTA_insert
SET AttStartMi += 1440
WHERE AttStartMi < WorkStartMi AND DATEDIFF(day, AttDate, AttStart) > 0

UPDATE #tblHasTA_insert
SET AttEndMi += 1440
WHERE AttEndMi < AttStartMi

UPDATE #tblHasTA_insert
SET BreakStartMi = WorkEndMi, BreakEndMi = WorkEndMi
FROM #tblHasTA_insert
WHERE abs(BreakStartMi - BreakEndMi) > 240

--làm viec  xuyên màn dêm
UPDATE #tblHasTA_insert
SET AttEndMi += 1440
WHERE AttEndMi - AttStartMi < 300 AND DATEDIFF(day, AttStart, AttEnd) > 0 AND AttEndMi < 1440

IF @MATERNITY_LATE_EARLY_OPTION = 1
	UPDATE ta1
	SET AttStartMi = CASE 
			WHEN AttStartMi > WorkStartMi
				THEN CASE 
						WHEN AttStartMi - WorkStartMi <= 30
							THEN WorkStartMi
						ELSE AttStartMi - @MATERNITY_MUNITE
						END
			ELSE AttStartMi
			END
	FROM #tblHasTA_insert ta1
	WHERE AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL AND ta1.Period = 0 AND EXISTS (
			SELECT 1
			FROM #tblPendingImportAttend p
			WHERE ta1.EmployeeID = p.EmployeeID AND ta1.AttDate = p.DATE AND p.EmployeeStatusID IN (10, 11)
			)
ELSE IF @MATERNITY_LATE_EARLY_OPTION = 2
	UPDATE ta1
	SET AttEndMi = CASE 
			WHEN AttEndMi < WorkEndMi
				THEN CASE 
						WHEN WorkEndMi - AttStartMi <= 30
							THEN WorkEndMi
						ELSE AttEndMi + @MATERNITY_MUNITE
						END
			ELSE AttEndMi
			END
	FROM #tblHasTA_insert ta1
	WHERE AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL AND ta1.Period = 0 AND EXISTS (
			SELECT 1
			FROM #tblPendingImportAttend p
			WHERE ta1.EmployeeID = p.EmployeeID AND ta1.AttDate = p.DATE AND p.EmployeeStatusID IN (10, 11)
			)
ELSE IF @MATERNITY_LATE_EARLY_OPTION = 3
	UPDATE ta1
	SET AttEndMi = CASE 
			WHEN WorkEndMi - AttEndMi >= AttStartMi - WorkStartMi AND AttEndMi < WorkEndMi
				THEN CASE 
						WHEN WorkEndMi - AttStartMi <= 30
							THEN WorkEndMi
						ELSE AttEndMi + @MATERNITY_MUNITE
						END
			ELSE AttEndMi
			END, AttStartMi = CASE 
			WHEN WorkEndMi - AttEndMi < AttStartMi - WorkStartMi AND AttStartMi > WorkStartMi
				THEN CASE 
						WHEN AttStartMi - WorkStartMi <= 30
							THEN WorkStartMi
						ELSE AttStartMi - @MATERNITY_MUNITE
						END
			ELSE AttStartMi
			END
	FROM #tblHasTA_insert ta1
	WHERE AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL AND ta1.Period = 0 AND EXISTS (
			SELECT 1
			FROM #tblPendingImportAttend p
			WHERE ta1.EmployeeID = p.EmployeeID AND ta1.AttDate = p.DATE AND p.EmployeeStatusID IN (10, 11)
			)

-- UPDATE LATE_PERMIT AND EARLY_PERMIT
-- update LATE_PERMIT,EARLY_PERMIT của bảng #tblHasTA_insert , Lần lượt trả về kết quả nếu tồn tại theo thứ tự Position,Section,Department,Division
UPDATE sd
SET sd.Late_Permit = COALESCE(p.LATE_PERMIT, sc.LATE_PERMIT, dp.LATE_PERMIT, d.LATE_PERMIT), sd.Early_Permit = COALESCE(p.Early_Permit, sc.Early_Permit, dp.Early_Permit, d.Early_Permit)
FROM #tblHasTA_insert sd
LEFT JOIN #tblEmployeeList s ON s.EmployeeID = sd.EmployeeId
LEFT JOIN tblDivision d ON d.DivisionID = s.DivisionID
LEFT JOIN tblDepartment dp ON dp.DepartmentID = s.DepartmentID
LEFT JOIN tblSection sc ON sc.SectionID = s.SectionID
LEFT JOIN tblPosition p ON p.PositionID = s.PositionID

-- Update #tblHasTA_insert
UPDATE hi
-- Dành tất cả cho AttStartMi .
SET AttStartMi =
	-- Nếu là ca 1
	CASE 
		WHEN AttStartMi + Late_Permit <= BreakEndMi
			THEN
				-- DÙng WorkStartMi so sánh cho AttStartMi
				-- Nếu AttStartMi <= WorkStartMi + Late_Permit -> Trả về WorkStartMi ngược lại trả về AttStartMi
				CASE 
					WHEN AttStartMi BETWEEN WorkStartMi AND WorkStartMi + Late_Permit
						THEN WorkStartMi
					ELSE AttStartMi
					END
		ELSE
			-- Dùng BreakEndMi so sánh cho AttStartMi
			-- Nếu AttStartMi <= WorkStartMi + Late_Permit -> Trả về WorkStartMi ngược lại trả về AttStartMi
			CASE 
				WHEN AttStartMi BETWEEN BreakEndMi AND BreakEndMi + Late_Permit
					THEN BreakEndMi
				ELSE AttStartMi
				END
		END,
	-- Dành tất cả cho AttEndMi
	AttEndMi =
	-- Nếu là ca 1
	CASE 
		WHEN AttEndMi + Early_Permit <= BreakEndMi
			THEN
				-- DÙng BreakStartMi so sánh cho AttEndMi ( Bởi hiện tại BreakStartMi đại diện cho giờ kết thúc ca 1 )
				-- Nếu AttEndtMi <= BreakStartMi - Early_Permit -> Trả về BreakStartMi ngược lại trả về AttEndMi
				CASE 
					WHEN AttEndMi BETWEEN BreakStartMi - Early_Permit AND BreakStartMi
						THEN BreakStartMi
					ELSE AttEndMi
					END
		ELSE
			-- DÙng BreakStartMi so sánh cho AttEndMi ( Bởi hiện tại BreakStartMi đại diện cho giờ kết thúc ca 1 )
			-- Nếu AttEndtMi <= BreakStartMi - Early_Permit -> Trả về BreakStartMi ngược lại trả về AttEndMi
			CASE 
				WHEN AttEndMi BETWEEN WorkEndMi - Early_Permit AND WorkEndMi
					THEN CASE 
							WHEN AttEndMi < WorkEndMi
								THEN WorkEndMi
							ELSE AttEndMi
							END
				ELSE AttEndMi
				END
		END
FROM #tblHasTA_insert hi

--VŨ: LICHIEN làm tròn working time, sớm/trễ dưới 15 phút - bù công, tính đi trễ về sớm
--UPDATE #tblHasTA_insert SET AttStartMi = WorkStartMi
--WHERE AttStartMi BETWEEN WorkStartMi AND WorkStartMi + 14
--UPDATE #tblHasTA_insert SET AttEndMi = WorkEndMi
--WHERE AttEndMi BETWEEN WorkEndMi - 14 AND WorkEndMi
--Giờ RA: round AttStartMi to nearest 15 minutes when it's later than WorkStartMi + 15
-- Using integer arithmetic: ((AttStartMi + 7) / 15) * 15 rounds to nearest 15 minutes
UPDATE #tblHasTA_insert
SET AttStartMi = ((AttStartMi + 7) / 15) * 15
WHERE AttStartMi > WorkStartMi + 15

--Giờ RA: round AttEndMi to nearest 15 minutes when the employee leaves early (AttEndMi < WorkEndMi - 15)
-- Using integer arithmetic: ((AttEndMi + 7) / 15) * 15 rounds to nearest 15 minutes
UPDATE #tblHasTA_insert
SET AttEndMi = ((AttEndMi + 7) / 15) * 15
WHERE AttEndMi < WorkEndMi - 15

--TRIPOD:
UPDATE #tblHasTA_insert
SET WorkingTimeMi = CASE 
		WHEN AttEndMi >= WorkEndMi
			THEN WorkEndMi
		WHEN AttEndMi >= BreakEndMi
			THEN AttEndMi
		WHEN AttEndMi >= BreakStartMi
			THEN BreakStartMi
		WHEN AttEndMi >= WorkStartMi
			THEN AttEndMi
		ELSE WorkStartMi
		END - CASE 
		WHEN AttStartMi <= WorkStartMi
			THEN WorkStartMi
		WHEN AttStartMi <= BreakStartMi
			THEN AttStartMi
		WHEN AttStartMi <= BreakEndMi
			THEN BreakEndMi
		WHEN AttStartMi <= WorkEndMi
			THEN AttStartMi
		ELSE WorkEndMi
		END, StdWorkingTimeMi = WorkEndMi - WorkStartMi - (BreakEndMi - BreakStartMi)
WHERE AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

UPDATE #tblHasTA_insert
SET StdWorkingTimeMi = 480
WHERE SwipeOptionID IN (3, 4) AND StdWorkingTimeMi < 480

UPDATE #tblHasTA_insert
SET StdWorkingTimeMi = 480
WHERE isnull(StdWorkingTimeMi, 0) <= 0

UPDATE #tblHasTA_insert
SET WorkingTimeMi = WorkingTimeMi - (BreakEndMi - BreakStartMi)
WHERE BreakStartMi < BreakEndMi AND AttStartMi <= BreakStartMi AND AttEndMi >= BreakEndMi AND AttStartMi IS NOT NULL AND AttEndMi IS NOT NULL

UPDATE #tblHasTA_insert
SET STDWorkingTime_SS = StdWorkingTimeMi

----lichien: period 2 mean overtime, not calculate working time
--if exists(select 1 from #tblHasTA_insert where Period = 2 and  WorkingTimeMi > 0)
-- update #tblHasTA_insert set WorkingTimeMi = 0 where Period = 2
-- cập nhật lại STDWorkingTime_SS
UPDATE #tblHasTA_insert
SET STDWorkingTime_SS = ss.Std_Hour_PerDays * 60
FROM #tblHasTA_insert ta
INNER JOIN tblShiftSetting ss ON ta.ShiftCode = ss.ShiftCode AND datepart(DW, ta.Attdate) = ss.WeekDays
WHERE ta.STDWorkingTime_SS <> ss.Std_Hour_PerDays * 60 AND ta.SwipeOptionID IN (1, 2)

IF @MATERNITY_LATE_EARLY_OPTION = 0
BEGIN
	UPDATE att
	SET WorkingTimeMi = att.WorkingTimeMi + t.MATERNITY_MUNITE
	FROM #tblHasTA_insert att
	INNER JOIN (
		SELECT t.EmployeeID, t.Attdate, tmp.MATERNITY_MUNITE, max(t.Period) Period
		FROM #tblHasTA_insert t
		INNER JOIN (
			SELECT d.EmployeeID, d.Attdate, min(WorkingTimeMi) WorkingTimeMi, CASE 
					WHEN max(StdWorkingTimeMi) - sum(WorkingTimeMi) > @MATERNITY_MUNITE
						THEN @MATERNITY_MUNITE
					ELSE max(StdWorkingTimeMi) - sum(WorkingTimeMi)
					END MATERNITY_MUNITE
			FROM #tblHasTA_insert d
			WHERE
				--exists (select 1 from #tblHasTA_insert t where d.employeeID = t.EmployeeID and d.AttDate = t.AttDate group by t.EmployeeID, t.AttDate having sum (t.WorkingTimeMi) >= @MATERNITY_ADD_ATLEAST) and
				EXISTS (
					SELECT 1
					FROM #tblPendingImportAttend p
					WHERE d.EmployeeID = p.EmployeeID AND d.Attdate = p.DATE AND p.EmployeeStatusID IN (10, 11)
					)
			GROUP BY d.EmployeeID, d.Attdate
			HAVING sum(d.WorkingTimeMi) >= @MATERNITY_ADD_ATLEAST
			) tmp ON t.EmployeeID = tmp.EmployeeID AND t.Attdate = tmp.Attdate AND t.WorkingTimeMi = tmp.WorkingTimeMi
		GROUP BY t.EmployeeID, t.Attdate, tmp.MATERNITY_MUNITE
		) t ON att.EmployeeID = t.EmployeeID AND att.Attdate = t.Attdate AND att.Period = t.Period
END

-- chinh lai STD_WT khi nguoi dung nhap trong ban thiet lap ca -- ca tu do thi ko tinh ty le nay
UPDATE ta
SET WorkingTimeMi = ta.WorkingTimeMi * ta.STDWorkingTime_SS / ta.StdWorkingTimeMi, StdWorkingTimeMi = ta.STDWorkingTime_SS
FROM #tblHasTA_insert ta
WHERE (ta.STDWorkingTime_SS < 841 AND ta.StdWorkingTimeMi < 841) AND ta.STDWorkingTime_SS <> ta.StdWorkingTimeMi

-- truong hop di lam nua ngay ma vao som 5 hoăc 10 phut thi van tinh cong nua ngay
--UPDATE #tblHasTA_insert set WorkingTimeMi = 240 WHERE WorkingTimeMi BETWEEN 241 AND 249 --TN bỏ
IF (object_id('sp_ShiftDetector_ProcessWorkingTime') IS NULL)
	EXEC ('CREATE PROCEDURE sp_ShiftDetector_ProcessWorkingTime(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime)as')

SET @StopUpdate = 0

-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
EXEC sp_ShiftDetector_ProcessWorkingTime @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

/*
--System automatically insert leave
--select *
update lv
set LvAmount=LvAmount-case when tmp.WorkingTimeMi>tmp.StdWorkingTimeMi then tmp.StdWorkingTimeMi else tmp.WorkingTimeMi end / 60.0, LeaveStatus=2
from tblLvHistory lv
     inner join(select EmployeeID, Attdate, sum(WorkingTimeMi) WorkingTimeMi, max(StdWorkingTimeMi) StdWorkingTimeMi
                from #tblHasTA_insert ta
                where exists (select 1 from tblLvHistory lv where ta.EmployeeID=lv.EmployeeID and ta.Attdate=lv.LeaveDate and lv.Reason=N'System automatically insert leave')and ta.WorkingTimeMi>0
                group by EmployeeID, Attdate) tmp on lv.EmployeeID=tmp.EmployeeID and lv.LeaveDate=tmp.Attdate

where lv.Reason=N'System automatically insert leave'
*/
IF NOT EXISTS (
		SELECT 1
		FROM tblParameter
		WHERE Code = 'WORKINGTIME_DONOT_CARE_LEAVEAMOUNT' AND Value = '1'
		)
BEGIN
	UPDATE #tblHasTA_insert
	SET CARE_LEAVEAMOUNT = (isnull(t1.s_WorkingTimeMi, 0) + isnull(lv.SumLvAmount, 0)) - ta.StdWorkingTimeMi
	FROM #tblHasTA_insert ta
	INNER JOIN (
		SELECT EmployeeID, AttDate, sum(WorkingTimeMi) s_WorkingTimeMi
		FROM #tblHasTA_insert
		GROUP BY EmployeeID, AttDate
		) t1 ON ta.EmployeeID = t1.EmployeeID AND ta.Attdate = t1.Attdate
	INNER JOIN (
		SELECT EmployeeID, LeaveDate, sum(LvAmount) * 60 AS SumLvAmount
		FROM #tblLvHistory lv
		WHERE lv.LeaveCategory = 1 AND isnull(lv.Reason, '') <> N'System automatically insert leave'
		GROUP BY EmployeeID, LeaveDate
		) lv ON ta.EmployeeID = lv.EmployeeID AND lv.LeaveDate = ta.Attdate
	WHERE isnull(t1.s_WorkingTimeMi, 0) + isnull(lv.SumLvAmount, 0) > StdWorkingTimeMi

	UPDATE ta
	SET ACCUMMULATE_CARE_LEAVEAMOUNT = t1.s_WorkingTimeMi
	FROM #tblHasTA_insert ta
	CROSS APPLY (
		SELECT sum(t1.WorkingTimeMi) s_WorkingTimeMi
		FROM #tblHasTA_insert t1
		WHERE ta.EmployeeID = t1.EmployeeID AND ta.Attdate = t1.Attdate AND ta.Period >= t1.Period
		) t1
	WHERE ta.CARE_LEAVEAMOUNT > 0

	UPDATE #tblHasTA_insert
	SET COMPARE_WORKINGTIME = CARE_LEAVEAMOUNT - ACCUMMULATE_CARE_LEAVEAMOUNT
	WHERE CARE_LEAVEAMOUNT > 0

	UPDATE #tblHasTA_insert
	SET DEDUCT_WORKINGTIME = WorkingTimeMi
	WHERE COMPARE_WORKINGTIME >= 0 AND CARE_LEAVEAMOUNT > 0

	UPDATE #tblHasTA_insert
	SET DEDUCT_WORKINGTIME = ta.WorkingTimeMi + ta.COMPARE_WORKINGTIME
	FROM #tblHasTA_insert ta
	CROSS APPLY (
		SELECT min(t1.Period) m_Period
		FROM #tblHasTA_insert t1
		WHERE ta.EmployeeID = t1.EmployeeID AND ta.Attdate = t1.Attdate AND t1.COMPARE_WORKINGTIME < 0
		) t1
	WHERE ta.CARE_LEAVEAMOUNT > 0 AND t1.m_Period = ta.Period

	UPDATE #tblHasTA_insert
	SET WorkingTimeMi = WorkingTimeMi - DEDUCT_WORKINGTIME
	WHERE DEDUCT_WORKINGTIME IS NOT NULL
		/*

    update #tblHasTA_insert
    set WorkingTimeMi = StdWorkingTimeMi-isnull(SumLvAmount, 0)
    from #tblHasTA_insert d
         inner join #tblPendingImportAttend p on d.EmployeeID=p.EmployeeID and d.Attdate=p.Date
        inner join(select EmployeeID, LeaveDate, sum(LvAmount)* 60 as SumLvAmount
                    from #tblLvHistory lv
    where lv.LeaveCategory=1 and isnull(lv.Reason, '')<>N'System automatically insert leave'
                    group by EmployeeID, LeaveDate) lv on d.EmployeeID=lv.EmployeeID and d.Attdate=lv.LeaveDate
    where AttStartMi is not null and AttEndMi is not null and isnull(WorkingTimeMi, 0)+isnull(lv.SumLvAmount, 0)>StdWorkingTimeMi
 */
END

IF NOT EXISTS (
		SELECT 1
		FROM tblParameter
		WHERE Code = 'DONOT_USE_WORKINGTIME_RATE' AND Value = '1'
		)
	UPDATE ta1
	SET WorkingTimeMi = CASE 
			WHEN (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0)) <= 0
				THEN 0
			WHEN cast(CASE 
						WHEN ta1.WorkingTimeMi > (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0))
							THEN (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0))
						ELSE ta1.WorkingTimeMi
						END AS FLOAT) / (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0)) * (isnull(ta2.Std_Hour_PerDays, 8) * 60 - isnull(lv.LvAmount * 60, 0)) >= (isnull(ta2.Std_Hour_PerDays, 8) * 60 - isnull(lv.LvAmount * 60, 0))
				THEN (isnull(ta2.Std_Hour_PerDays, 8) * 60 - isnull(lv.LvAmount * 60, 0))
			ELSE cast(CASE 
						WHEN WorkingTimeMi > (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0))
							THEN (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0))
						ELSE ta1.WorkingTimeMi
						END AS FLOAT) / (ta1.StdWorkingTimeMi - isnull(lv.LvAmount * 60, 0)) * (isnull(ta2.Std_Hour_PerDays, 8) * 60 - isnull(lv.LvAmount * 60, 0))
			END
	FROM #tblHasTA_insert ta1
	INNER JOIN tblShiftSetting ta2 ON ta1.ShiftID = ta2.ShiftID
	INNER JOIN tblLvHistory lv ON ta1.EmployeeID = lv.EmployeeID AND ta1.Attdate = lv.LeaveDate
	WHERE ta1.Workingtimemi > 0 AND EXISTS (
			SELECT 1
			FROM tblLeaveType lt
			WHERE lt.LeaveCategory = 1 AND lv.LeaveCode = lt.LeaveCode
			) -- xử lý trường hợp ngày phía trước hoặc phía sau dã duyệt vào ra, thì ngày hiện tại không đc sát với giờ vao ra cua nhung ngay

-- truong hop khong co ca
UPDATE ta
SET AttStart = NULL, WorkingTime = NULL, WorkingTimeMi = NULL
FROM #tblHasTA_insert ta
INNER JOIN #tblHasTA_insert ta1 ON ta.EmployeeID = ta1.EmployeeID AND ta.Attdate = ta1.Attdate + 1
WHERE ta.TAStatus = 0 AND ta1.TAStatus IN (2, 3) AND datediff(mi, ta1.AttEnd, ta.AttStart) < 61 -- giờ vào phải lớn 60 phút so với giờ ra hôm trước

--TRIPOD: refresh
SELECT s.EmployeeID, ss.ShiftCode, isnull(ss.ShiftID, s.ShiftID) ShiftID, s.ScheduleDate, s.HolidayStatus, s.DateStatus, isnull(s.Approved, 0) AS Approved, dateadd(day, 1, ScheduleDate) AS NextDate, dateadd(day, - 1, ScheduleDate) AS PrevDate, ApprovedHolidayStatus
INTO #tblWSchedule2
FROM tblWSchedule s WITH (NOLOCK)
LEFT JOIN tblShiftSetting ss WITH (NOLOCK) ON s.ShiftID = ss.ShiftID
WHERE s.ScheduleDate BETWEEN @FromDate3 AND @ToDate3 AND EXISTS (
		SELECT EmployeeID
		FROM #tblEmployeeList te
		WHERE s.EmployeeID = te.EmployeeID
		)

--VŨ: với các ngày holidayStatus <> 0 thì ủi WorkingTime đi
UPDATE h
SET WorkingTimeMi = NULL
FROM #tblHasTA_insert h
INNER JOIN #tblWSchedule2 s ON s.EmployeeId = h.EmployeeID AND s.ScheduleDate = h.Attdate
WHERE s.HolidayStatus <> 0

UPDATE ta
SET AttEnd = NULL, WorkingTime = NULL, WorkingTimeMi = NULL
FROM #tblHasTA_insert ta
INNER JOIN #tblHasTA_insert ta1 ON ta.EmployeeID = ta1.EmployeeID AND ta.Attdate = ta1.Attdate - 1
WHERE ta.TAStatus = 0 AND ta1.TAStatus IN (1, 3) AND datediff(mi, ta.AttEnd, ta1.AttStart) < 61 -- giờ vào phải lớn 60 phút so với giờ ra hôm trước

ALTER TABLE #tblShiftSetting ADD isFreeShift BIT

IF (object_id('sp_ShiftDetector_UpdateHasTA') IS NULL)
	EXEC ('create proc sp_ShiftDetector_UpdateHasTA(@StopUpdate bit output, @LoginID int, @FromDate datetime, @ToDate datetime) as')

SET @StopUpdate = 0

-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
EXEC sp_ShiftDetector_UpdateHasTA @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate

IF @StopUpdate = 0
BEGIN
	--xu ly goi lam viec cho ca tu do
	UPDATE #tblShiftSetting
	SET isFreeShift = 1
	WHERE WorkEndMi - WorkStartMi > 810

	UPDATE #tblShiftSetting
	SET STDWorkingTime_SS = (
			CASE 
				WHEN isnumeric(ss.Std_Hour_PerDays) = 1
					THEN ss.Std_Hour_PerDays
				ELSE @WORK_HOURS
				END
			) * 60
	FROM #tblShiftSetting ts
	INNER JOIN tblShiftSetting ss ON ss.ShiftID = ts.ShiftID AND isnull(ts.isFreeShift, 0) = 1

	--lichien: period 2 mean overtime, not calculate working time
	--update #tblHasTA_insert set WorkingTimeMi = 0 where Period = 2
	--  update #tblHasTA_insert set WorkingTime = WorkingTimeMi / 60.0
	UPDATE #tblHasTA_insert
	SET IsNightShift = s.isNightShift
	FROM #tblHasTA_insert ta
	INNER JOIN #tblShiftSetting s ON ta.ShiftCode = s.ShiftCode
END

UPDATE #tblHasTA_insert
SET WorkingTime = (((WorkingTimeMi + 7) / 15) * 15) / 60.0
FROM #tblHasTA_insert

SELECT i1.*, CAST(0 AS BIT) AS isChange
INTO #tblHasTA_ForUpdate
FROM tblHasTA i1
INNER JOIN #tblPendingImportAttend te ON i1.AttDate = te.DATE AND i1.EmployeeID = te.EmployeeID

DELETE #tblHasTA_ForUpdate
FROM #tblHasTA_ForUpdate a
WHERE AttDate NOT BETWEEN @FromDate AND @ToDate

UPDATE #tblHasTA_ForUpdate
SET isChange = 1
FROM #tblHasTA_ForUpdate i1
LEFT JOIN #tblHasTA_insert t0 ON i1.EmployeeID = t0.EmployeeID AND i1.AttDate = t0.Attdate AND i1.Period = t0.Period
WHERE t0.Period IS NULL AND NOT EXISTS (
		SELECT 1
		FROM #tblWSchedule c
		WHERE i1.EmployeeID = c.EmployeeID AND i1.AttDate = c.ScheduleDate AND c.DateStatus = 3
		) AND i1.TAStatus <> 3

UPDATE #tblHasTA_ForUpdate
SET isChange = 1
FROM #tblHasTA_ForUpdate i1
LEFT JOIN #tblWSchedule ws ON i1.EmployeeID = ws.EmployeeID AND i1.AttDate = ws.ScheduleDate AND ws.DateStatus = 3
WHERE ws.EmployeeID IS NULL AND EXISTS (
		SELECT 1
		FROM tblHasTA i2 WITH (NOLOCK)
		WHERE i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate - 1 AND isnull(i1.AttEnd, i1.AttStart) >= ISNULL(i2.AttStart, I2.AttEnd)
		)

UPDATE #tblHasTA_ForUpdate
SET isChange = 1
FROM tblHasTA i1 WITH (NOLOCK)
LEFT JOIN #tblWSchedule ws ON i1.EmployeeID = ws.EmployeeID AND i1.AttDate = ws.ScheduleDate AND ws.DateStatus = 3
INNER JOIN #tblHasTA_ForUpdate i2 ON i1.employeeID = i2.EmployeeID AND i1.AttDate = i2.AttDate
WHERE ws.EmployeeID IS NULL AND i1.Period = i2.Period - 1 AND isnull(i1.AttEnd, i1.AttStart) >= ISNULL(i2.AttStart, I2.AttEnd)

IF EXISTS (
		SELECT 1
		FROM #tblHasTA_ForUpdate
		WHERE isChange = 1
		)
	DELETE a
	FROM tblHasTA a WITH (NOLOCK)
	INNER JOIN #tblHasTA_ForUpdate b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
	WHERE b.isChange = 1

--refresh
UPDATE #tblHasTA_ForUpdate
SET isChange = 0

DECLARE @DateNUll DATE = '3000-12-31'

UPDATE #tblHasTA_ForUpdate
SET AttStart = b.AttStart, AttEnd = b.AttEnd, isChange = 1
FROM #tblHasTA_ForUpdate a
INNER JOIN #tblHasTA_insert b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
LEFT JOIN #tblWSchedule ws ON a.EmployeeID = ws.EmployeeID AND a.AttDate = ws.ScheduleDate AND ws.DateStatus = 3
WHERE ws.EmployeeID IS NULL AND a.TAStatus <> 3 AND (ISNULL(a.AttStart, @DateNUll) <> ISNULL(b.AttStart, @DateNUll) OR ISNULL(a.AttEnd, @DateNUll) <> ISNULL(b.AttEnd, @DateNUll))

UPDATE #tblHasTA_ForUpdate
SET AttStart = b.AttStart, isChange = 1
FROM #tblHasTA_ForUpdate a
INNER JOIN #tblHasTA b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
LEFT JOIN #tblAtt_Lock l ON a.EmployeeID = l.EmployeeID AND a.AttDate = l.DATE
WHERE l.EmployeeID IS NULL AND b.TAStatus = 1 AND b.AttStart IS NOT NULL

UPDATE #tblHasTA_ForUpdate
SET AttEnd = b.AttEnd, isChange = 1
FROM #tblHasTA_ForUpdate a
INNER JOIN #tblHasTA b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
LEFT JOIN #tblAtt_Lock l ON a.EmployeeID = l.EmployeeID AND a.AttDate = l.DATE
WHERE l.EmployeeID IS NULL AND b.TAStatus = 2 AND b.AttEnd IS NOT NULL

IF EXISTS (
		SELECT 1
		FROM #tblHasTA_ForUpdate
		WHERE isChange = 1
		)
	UPDATE tblHasTA
	SET AttStart = b.AttStart, AttEnd = b.AttEnd
	FROM tblHasTA a
	INNER JOIN #tblHasTA_ForUpdate b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
	WHERE b.isChange = 1

UPDATE #tblHasTA_ForUpdate
SET isChange = 0

IF EXISTS (
		SELECT 1
		FROM #tblHasTA_insert a
		WHERE NOT EXISTS (
				SELECT 1
				FROM tblHasTA b WITH (NOLOCK)
				WHERE a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
				)
		)
	INSERT INTO #tblHasTA_ForUpdate (EmployeeID, AttDate, Period, AttStart, AttMiddle, AttEnd, Approve, WorkingTime, TAStatus, isChange)
	SELECT *
	FROM (
		INSERT INTO tblHasTA (EmployeeID, AttDate, Period, AttStart, AttMiddle, AttEnd, Approve, WorkingTime, TAStatus)
		OUTPUT inserted.EmployeeID, inserted.AttDate, inserted.Period, inserted.AttStart, inserted.AttMiddle, inserted.AttEnd, inserted.Approve, inserted.WorkingTime, inserted.TAStatus, 0 AS isChange
		SELECT a.EmployeeID, a.AttDate, a.Period, a.AttStart, a.AttMiddle, a.AttEnd, 0, a.WorkingTime, 0
		FROM #tblHasTA_insert a
		WHERE NOT EXISTS (
				SELECT 1
				FROM tblHasTA b WITH (NOLOCK)
				WHERE a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
				)
		GROUP BY a.EmployeeID, a.AttDate, a.Period, a.AttStart, a.AttMiddle, a.AttEnd, a.WorkingTime
		) t

UPDATE #tblHasTA_ForUpdate
SET WorkingTime = round(b.WorkingTime, 2), isChange = 1
FROM #tblHasTA_ForUpdate a
INNER JOIN #tblHasTA_insert b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
WHERE isnull(a.WorkingTimeApproved, 0) = 0 AND ISNULL(a.WorkingTime, - 1) <> ISNULL(round(b.WorkingTime, 2), - 1)

UPDATE #tblHasTA_ForUpdate
SET WorkingTime = NULL, isChange = 1
WHERE round(WorkingTime, 2) <= 0

IF EXISTS (
		SELECT 1
		FROM #tblHasTA_ForUpdate
		WHERE isChange = 1
		)
	UPDATE a
	SET WorkingTime = b.WorkingTime
	FROM tblHasTA a
	INNER JOIN #tblHasTA_ForUpdate b ON a.EmployeeID = b.EmployeeID AND a.AttDate = b.AttDate AND a.Period = b.Period
	WHERE b.isChange = 1

--HPSF: đánh dấu ngày công các ngày thực hiện xác nhận công trên app mobile
--  UPDATE h SET TimeReason = N'Đã xác nhận công trên app mobile'
--  FROM tblHasTA h
--  WHERE EXISTS(SELECT 1 FROM #InsertListTime l WHERE l.EmployeeID = h.EmployeeID  AND l.AttDate = h.AttDate)
IF (object_id('sp_ShiftDetector_FinishUpdateHasTA') IS NULL)
	EXEC ('CREATE PROCEDURE dbo.sp_ShiftDetector_FinishUpdateHasTA ( @StopUpdate bit output ,@LoginID int ,@FromDate datetime ,@ToDate datetime ,@EmployeeID varchar(20) = ''-1'' ) as ')

SET @StopUpdate = 0

-- Goi thu thu thuc customize import de ap dung cho tung khach hang rieng biet
EXEC sp_ShiftDetector_FinishUpdateHasTA @StopUpdate OUTPUT, @LoginID, @FromDate, @ToDate, @EmployeeID = @EmployeeID

FinishedShiftDetector: /*
update ws
set ShiftID=0
from tblWSchedule ws
 left join #tblEmployeeList e on ws.EmployeeID=e.EmployeeID
     left join(select EmployeeID from dbo.tblShiftGroupByEmployee group by EmployeeID) i on i.EmployeeID=ws.EmployeeID
     left join(select EmployeeID from #tblShiftGroupCode sgc group by EmployeeID having count(1)=1) n on n.EmployeeID=ws.EmployeeID
     left join dbo.tblAtt_Lock al on ws.EmployeeID=al.EmployeeID and ws.ScheduleDate=al.Date
     left join dbo.tblHasTA ta on ws.EmployeeID=ta.EmployeeID and ws.ScheduleDate=ta.AttDate and(ta.AttStart is not null or ta.AttEnd is not null or isnull(ta.WorkingTime, 0)=8)
where isnull(ws.Approved, 0)=0 and ws.ScheduleDate between @FromDate and @ToDate and i.EmployeeID is not null and ws.HolidayStatus>0 and al.EmployeeID is null and ta.EmployeeID is null and e.EmployeeID is not null and n.EmployeeID is null
*/

ClearPendingRunning:

DELETE tblRunningImportAttend
WHERE LoginID = @LoginID

DELETE tblPendingImportAttend
FROM tblPendingImportAttend p
WHERE p.DATE BETWEEN @FromDate AND @ToDate AND EXISTS (
		SELECT 1
		FROM #tblEmployeeList e
		WHERE p.EmployeeID = e.EmployeeID
		)

--TRIPOD: Summary công
--TRIPOD
EXEC sp_processSummaryAttendance @LoginID = @LoginID, @Year = @Year, @Month = @Month, @ViewType = 0, @Payroll = 0

PRINT 'eof'
	--delete d from tblPendingImportAttend d
	--where exists(select 1 from #tblPendingImportAttend att where d.employeeID = att.EmployeeID and d.Date = att.Date)
	--or exists(select 1 from #tblHasTA_insert att where d.employeeID = att.EmployeeID and d.Date = att.attdate)
	--update tblParameter set Value = '0' where Code = 'StopRuning_NoneStopProc'
	--EXEC sp_ReCalculate_TAData @LoginID=3, @Fromdate='2025-08-01', @ToDate='2025-08-31', @EmployeeID_Pram='-1', @RunShiftDetector=1, @RunTA_Precess_Main=0
GO


