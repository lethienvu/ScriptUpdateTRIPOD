
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
		PaidLeaveHrs_Total, SUM(PaidLeaveDays_Total) PaidLeaveDays_Total, SUM([A]) [A], SUM(Std_Hour_PerDays) Std_Hour_PerDays, SUM(STD_WorkingDays)
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

	SELECT ot.EmployeeID, ot.OverTimeID, SUM(ot.OTAmount) OTAmount, SUM(os.OTHours * (
				CASE
					WHEN ots.OvValue - 100 < 0
						THEN 0
					ELSE (ots.OvValue - 100)
					END
				) / 100) NoneTaxableOTAmount, SUM(os.OTHours) Amount
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
		Amount AS Bonus6Month_FullAttendance, sd.UnpaidLeaveAmount, ISNULL(sd.TotalIncome, 0) - ISNULL(sd.RegularAmt, 0) - ISNULL(sd.PaidLeaveAmt, 0) + ISNULL(sd.
			GrossSalary, 0) - ISNULL(sd.UnpaidLeaveAmount, 0) AS TotalEarning_ExcludeUnpaidLeave, s.CostCenterName, EmployeeClass, EmployeeType
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

		DROP COLUMN MonthYear, Workdays, UnpaidLeaveDays, EmployeeExemption, FamilyExemption, TotalDeduction, AnnualLeaveHrs, EmployeeTotal, PaidLeavePS,
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
	--USE Paradise_TRIPOD_20250921
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
		PaidLeaveHrs_Total, SUM(PaidLeaveDays_Total) PaidLeaveDays_Total, SUM([A]) [A], SUM(Std_Hour_PerDays) Std_Hour_PerDays, SUM(STD_WorkingDays)
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

	SELECT ot.EmployeeID, ot.OverTimeID, SUM(ot.OTAmount) OTAmount, SUM(os.OTHours * (
				CASE
					WHEN ots.OvValue - 100 < 0
						THEN 0
					ELSE (ots.OvValue - 100)
					END
				) / 100) NoneTaxableOTAmount, SUM(os.OTHours) Amount
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
		Amount AS Bonus6Month_FullAttendance, sd.UnpaidLeaveAmount, ISNULL(sd.TotalIncome, 0) - ISNULL(sd.RegularAmt, 0) - ISNULL(sd.PaidLeaveAmt, 0) + ISNULL(sd.
			GrossSalary, 0) - ISNULL(sd.UnpaidLeaveAmount, 0) AS TotalEarning_ExcludeUnpaidLeave, s.CostCenterName, EmployeeClass, EmployeeType
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

		DROP COLUMN MonthYear, Workdays, UnpaidLeaveDays, EmployeeExemption, FamilyExemption, TotalDeduction, AnnualLeaveHrs, EmployeeTotal, PaidLeavePS,
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
exec sp_CompanySalarySummary 3,8,2025,'-1',0