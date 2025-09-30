USE Paradise_TRIPOD
GO
if object_id('[dbo].[sp_syncBarcodeToTmpATT]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_syncBarcodeToTmpATT] as select 1')
GO
ALTER PROCEDURE [dbo].[sp_syncBarcodeToTmpATT](
    @LoginID INT,
    @FromDate DATETIME,
    @ToDate DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    INTO #tmpTripodAtt
    FROM tblTripodAttTmp
    WHERE CAST([Timestamp] AS DATE) BETWEEN @FromDate AND @ToDate

    DECLARE @sql NVARCHAR(MAX) = N''

    SELECT ui.SSN, t.[Timestamp], CASE WHEN t.[Status] = 'IN' THEN 1 ELSE 2 END [Status], m.MachineNumber
	INTO #tmpInsertData
    FROM #tmpTripodAtt t
    INNER JOIN dbo.fn_USERINFO() ui ON t.AttendanceCode = SUBSTRING(ui.BadgeNumber, 3, LEN(ui.BadgeNumber) - 2)
    LEFT JOIN Machines m ON t.IP = m.IP
	WHERE NOT EXISTS (
		SELECT 1
		FROM tbltmpAttend a
		WHERE a.EmployeeID = ui.SSN
		  AND a.AttTime = t.[Timestamp]
	)

    INSERT INTO tbltmpAttend (EmployeeID, AttTime, AttState, MachineNo)
    SELECT *
	FROM #tmpInsertData
END
GO
exec sp_syncBarcodeToTmpATT 3,'2025-07-01','2025-07-31'


SELECT * FROM tbltmpAttend WHERE cast(AttTime as date) = '2025-07-26'



