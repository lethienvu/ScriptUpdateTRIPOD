
--UPDATE tblParameter SET [Value] = 1 WHERE [Code] = 'IN_OUT_TA_SEPARATE'
IF OBJECT_ID('[dbo].[fn_vEmployeeStatus_ByDate]') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn_vEmployeeStatus_ByDate]() RETURNS TABLE AS RETURN (SELECT 1 as Test)')
GO

ALTER FUNCTION [dbo].[fn_vEmployeeStatus_ByDate] (
    @viewdate DATE, 
    @EmployeeID NVARCHAR(MAX), 
    @LoginID INT
)
--Optimized by LE THIEN VU - 2025-09-30
RETURNS TABLE
AS
RETURN
(
    WITH EmployeeFilter AS (
        SELECT LTRIM(RTRIM(Items)) AS EmployeeID
        FROM dbo.SplitString(REPLACE(REPLACE(@EmployeeID, ';', ','), ' ', ''), ',')
    )
    SELECT 
        tesh.EmployeeID,
        tesh.EmployeeStatusID,
        tesh.ChangedDate,
        tes.EmployeeStatus,
        tesh.StatusEndDate
    FROM (
        SELECT DISTINCT esh.EmployeeID
        FROM dbo.tblEmployeeStatusHistory esh
    ) e
    CROSS APPLY (
        SELECT TOP 1 esh.EmployeeID, esh.EmployeeStatusID, esh.ChangedDate, esh.StatusEndDate
        FROM dbo.tblEmployeeStatusHistory esh
        WHERE esh.EmployeeID = e.EmployeeID
          AND esh.ChangedDate <= @viewdate
        ORDER BY esh.ChangedDate DESC
    ) tesh
    INNER JOIN dbo.tblEmployeeStatus tes ON tesh.EmployeeStatusID = tes.EmployeeStatusID
    LEFT JOIN EmployeeFilter ef ON ef.EmployeeID = tesh.EmployeeID
    LEFT JOIN tmpEmployeeTree tr ON tr.LoginID = @LoginID AND tr.EmployeeID = tesh.EmployeeID
    WHERE 
        (
            ISNULL(@EmployeeID, '') IN ('-1','') 
            AND (tr.EmployeeID IS NOT NULL OR @LoginID IS NULL)
        )
        OR ef.EmployeeID IS NOT NULL
)
GO

-- Xóa index thừa ở tblDivDepSecPos
DROP INDEX NIX_tblDivDepSecPos_ChangedDate ON tblDivDepSecPos;
DROP INDEX NIX_tblDivDepSecPos_ChangedDate2 ON tblDivDepSecPos;
DROP INDEX Auto_IXNC_tblDivDepSecPos_ChangedDate_EmployeeID_DivisionID_DepartmentID_SectionID_GroupID_EmployeeTypeID ON tblDivDepSecPos;

-- Xóa index thừa ở tblEmployeeStatusHistory
DROP INDEX ix_tblEmployeeStatusHistory_ChangedDate ON tblEmployeeStatusHistory;
DROP INDEX IX_tblEmployeeStatusHistory_ID_DAte_End_incEmpID ON tblEmployeeStatusHistory;

-- Xóa index thừa ở tblEmployeeTypeHistory
DROP INDEX Auto_IXNC_tblEmployeeTypeHistory_EffectiveDate_EmployeeID_EmployeeTypeID ON tblEmployeeTypeHistory;




IF OBJECT_ID('[dbo].[fn_vtblEmployeeList_Simple_ByDate]') IS NULL
    EXEC('CREATE FUNCTION [dbo].[fn_vtblEmployeeList_Simple_ByDate]() RETURNS TABLE AS RETURN (SELECT 1 as Test)')
GO

ALTER FUNCTION [dbo].[fn_vtblEmployeeList_Simple_ByDate] (
    @ViewDate DATE, 
    @EmployeeID NVARCHAR(MAX), 
    @LoginID INT
)
--Optimized by LE THIEN VU
RETURNS TABLE
AS
RETURN
(
    SELECT 
        te.EmployeeID,
        te.FullName,
        te.HireDate,
        te.ProbationEndDate,
        TerminateDate = CAST(CASE WHEN stat.EmployeeStatusID = 20 THEN stat.ChangedDate ELSE NULL END AS DATE),
        div.DivisionID,
        div.DepartmentID,
        div.SectionID,
        div.GroupID,
        stat.EmployeeStatusID,
        pos.PositionID,
        et.EmployeeTypeID,
        te.Sex,
        te.Birthday,
        te.TAOptionID,
        CASE WHEN ISNULL(te.NationID, 0) <> 234 THEN 1 ELSE 0 END AS IsForeign,
        LastWorkingDate = ISNULL(
            DATEADD(DAY, -1, CAST(CASE WHEN stat.EmployeeStatusID = 20 THEN stat.ChangedDate ELSE NULL END AS DATE)), 
            '9999-12-31'
        )
    FROM tblEmployee te
    INNER JOIN dbo.fn_vEmployeeStatus_ByDate(@ViewDate, @EmployeeID, @LoginID) stat 
        ON te.EmployeeID = stat.EmployeeID

    OUTER APPLY (
        SELECT TOP 1 DivisionID, DepartmentID, SectionID, GroupID
        FROM dbo.tblDivDepSecPos d
        WHERE d.EmployeeID = te.EmployeeID
          AND d.ChangedDate <= @ViewDate
        ORDER BY d.ChangedDate DESC
    ) div

    OUTER APPLY (
        SELECT TOP 1 PositionID
        FROM dbo.tblPositionHistory p
        WHERE p.EmployeeID = te.EmployeeID
          AND p.EffectiveDate <= @ViewDate
        ORDER BY p.EffectiveDate DESC
    ) pos

    OUTER APPLY (
        SELECT TOP 1 EmployeeTypeID
        FROM dbo.tblEmployeeTypeHistory et
        WHERE et.EmployeeID = te.EmployeeID
          AND et.EffectiveDate <= @ViewDate
        ORDER BY et.EffectiveDate DESC
    ) et
)
GO


ALTER FUNCTION [dbo].[fn_EmployeeStatusRange] (@NoTAOnly BIT = 0)
RETURNS TABLE
AS
--Performance optimized by LE THIEN VU
RETURN
(
    WITH Hist AS (
        SELECT 
            h.EmployeeID,
            h.EmployeeStatusID,
            h.ChangedDate,
            h.StatusEndDate,
            LEAD(h.ChangedDate) OVER (PARTITION BY h.EmployeeID ORDER BY h.ChangedDate) AS NextChangedDate
        FROM tblEmployeeStatusHistory h
    ),
    Rng AS (
        SELECT 
            EmployeeID,
            EmployeeStatusID,
            ChangedDate,
            ISNULL(
                CASE 
                    WHEN EmployeeStatusID = 20 AND NextChangedDate IS NULL THEN NULL
                    WHEN StatusEndDate IS NOT NULL AND NextChangedDate IS NOT NULL AND StatusEndDate >= NextChangedDate
                        THEN DATEADD(DAY, -1, NextChangedDate)
                    ELSE StatusEndDate
                END,
                DATEADD(YEAR, 1000, ChangedDate)
            ) AS StatusEndDate
        FROM Hist
    )
    SELECT EmployeeID, EmployeeStatusID, ChangedDate,
           DATEADD(SECOND, -1, DATEADD(DAY, 1, dbo.Truncate_Date(StatusEndDate))) AS StatusEndDate
    FROM Rng r
    WHERE @NoTAOnly = 0 OR EXISTS (
        SELECT 1 FROM tblEmployeeStatus es WHERE es.CutSI = 1 AND es.EmployeeStatusID = r.EmployeeStatusID
    )
)
GO


ALTER FUNCTION dbo.fn_ShiftGroupCodeHistory (@sender VARCHAR(20))
RETURNS @ShiftGroupCodeRange TABLE (ID VARCHAR(20), ShiftGroupCode INT, FromDate DATE, Todate DATE)
AS
BEGIN
    IF @sender = 'emp'
    BEGIN
        INSERT INTO @ShiftGroupCodeRange (ID, ShiftGroupCode, FromDate, Todate)
        SELECT EmployeeID,
               ShiftGroupCode,
               EffectiveDate,
               ISNULL(DATEADD(DAY, -1, LEAD(EffectiveDate) OVER(PARTITION BY EmployeeID ORDER BY EffectiveDate)),
                      ISNULL(EndDate, '9999-12-31'))
        FROM tblShiftGroupByEmployee;
    END

    IF @sender = 'div'
    BEGIN
        INSERT INTO @ShiftGroupCodeRange (ID, ShiftGroupCode, FromDate, Todate)
        SELECT DivisionID,
               ShiftGroupCode,
               EffectiveDate,
               ISNULL(DATEADD(DAY, -1, LEAD(EffectiveDate) OVER(PARTITION BY DivisionID ORDER BY EffectiveDate)),
                      ISNULL(EndDate, '9999-12-31'))
        FROM tblShiftGroupByDivision;
    END

    IF @sender = 'dep'
    BEGIN
        INSERT INTO @ShiftGroupCodeRange (ID, ShiftGroupCode, FromDate, Todate)
        SELECT DepartmentID,
               ShiftGroupCode,
               EffectiveDate,
               ISNULL(DATEADD(DAY, -1, LEAD(EffectiveDate) OVER(PARTITION BY DepartmentID ORDER BY EffectiveDate)),
                      ISNULL(EndDate, '9999-12-31'))
        FROM tblShiftGroupByDepartment;
    END

    IF @sender = 'sec'
    BEGIN
        INSERT INTO @ShiftGroupCodeRange (ID, ShiftGroupCode, FromDate, Todate)
        SELECT SectionID,
               ShiftGroupCode,
               EffectiveDate,
               ISNULL(DATEADD(DAY, -1, LEAD(EffectiveDate) OVER(PARTITION BY SectionID ORDER BY EffectiveDate)),
                      ISNULL(EndDate, '9999-12-31'))
        FROM tblShiftGroupBySection;
    END

    IF @sender = 'gro'
    BEGIN
        INSERT INTO @ShiftGroupCodeRange (ID, ShiftGroupCode, FromDate, Todate)
        SELECT GroupID,
               ShiftGroupCode,
               EffectiveDate,
               ISNULL(DATEADD(DAY, -1, LEAD(EffectiveDate) OVER(PARTITION BY GroupID ORDER BY EffectiveDate)),
                      ISNULL(EndDate, '9999-12-31'))
        FROM tblShiftGroupByGroup;
    END

    RETURN;
END
GO



ALTER FUNCTION [dbo].[fn_DivDepSecPosHistory]
(
    @FromDate DATE,
    @ToDate DATE,
    @LoginID INT,
    @EmployeeID NVARCHAR(20) = '-1'
)
RETURNS TABLE
AS
RETURN
--VU
(
    -- 1. Tạo dãy số ngày nhanh
    WITH nums AS (
        SELECT TOP (DATEDIFF(DAY, @FromDate, @ToDate) + 1)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS num
        FROM master..spt_values
    ),
    -- 2. Lọc danh sách nhân viên cần xử lý
    EmployeeList AS (
        SELECT te.EmployeeID
        FROM tblEmployee te
        WHERE (@EmployeeID = '-1' OR te.EmployeeID = @EmployeeID)
          AND (te.EmployeeID IN (SELECT EmployeeID FROM tmpEmployeeTree WHERE LoginID = @LoginID)
               OR @LoginID IS NULL)
    )
    -- 3. Sinh ngày cho từng nhân viên và join với fn_DivDepSecPosRange
    SELECT 
        DATEADD(DAY, n.num, @FromDate) AS [DATE],
        e.EmployeeID,
        r.DivisionID,
        r.DepartmentID,
        r.SectionID,
        r.GroupID
    FROM nums n
    CROSS JOIN EmployeeList e
    INNER JOIN dbo.fn_DivDepSecPosRange(@LoginID) r
        ON e.EmployeeID = r.EmployeeID
       AND DATEADD(DAY, n.num, @FromDate) BETWEEN r.ChangedDate AND ISNULL(r.EndDate, '9999-01-01')
)
GO


ALTER FUNCTION [dbo].[fn_DivDepSecPosRange](@LoginID INT = 3)
RETURNS TABLE
AS
RETURN
--VU
(
    SELECT 
        EmployeeID,
        ChangedDate,
        ISNULL(DATEADD(DAY, -1, LEAD(ChangedDate) OVER (PARTITION BY EmployeeID ORDER BY ChangedDate)), '9999-12-31') AS EndDate,
        DivisionID,
        DepartmentID,
        SectionID,
        [GroupID]
    FROM tblDivDepSecPos
)
GO






