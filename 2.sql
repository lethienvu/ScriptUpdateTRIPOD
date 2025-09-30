USE Paradise_TRIPOD
GO
if object_id('[dbo].[sp_TemplateImportLeaveHistory]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_TemplateImportLeaveHistory] as select 1')
GO
ALTER PROCEDURE [dbo].[sp_TemplateImportLeaveHistory]@LoginID INT = 3
AS
BEGIN
	SELECT l.EmployeeID, CAST(NULL AS NVARCHAR(100)) DepartmentName, CAST(NULL AS NVARCHAR(100)) PositionName, l.LeaveDate, CAST(NULL AS NVARCHAR(100)) TACode, l.LeaveStatus, l.LvAmount, l.Reason
	FROM tblLvHistory l
	INNER JOIN tblEmployee e ON e.EmployeeID = l.EmployeeID
	WHERE 1 = 0
END
GO