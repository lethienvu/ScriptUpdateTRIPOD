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
);