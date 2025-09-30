USE Paradise_TRIPOD
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

SELECT * FROM dbo.fn_DivDepSecPosHistory('2025-07-01', '2025-07-31', 3, '-1')


