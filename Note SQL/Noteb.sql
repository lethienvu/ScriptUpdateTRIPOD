USE Paradise_TRIPOD
GO

IF object_id('[dbo].[sp_getMonthlyPayrollCheckList]') IS NULL
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
			END ActualMonth, PeriodID
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
				SELECT m.*, e.FullName, e.DepartmentID
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
				SELECT m.*, e.FullName, e.DepartmentID
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

EXEC sp_getMonthlyPayrollCheckList @LoginID = 3, @Month = 8, @Year = 2025, @NotSelect = 0, @OptionView = 1, @ViewAllPeriod = 1
