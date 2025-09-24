DELETE
FROM TaskSchedule

------------------------
SET IDENTITY_INSERT TaskSchedule ON

INSERT INTO TaskSchedule (IDTask, ProducerName, Param, HourStart, MinuteStart, IsActive, LastTryDay, ExceptIP, ExportName, SendMail, EmailTemplateName, RepeatDaily, RepeatMonthly, RepeatDays, RepeatMinutes, SkipRepeat, TaskType, NextRunDate, FunctionName, ClassName, TaskScheduleName, TaskScheduleNameEN)
SELECT IDTask, ProducerName, Param, HourStart, MinuteStart, IsActive, LastTryDay, ExceptIP, ExportName, SendMail, EmailTemplateName, RepeatDaily, RepeatMonthly, RepeatDays, RepeatMinutes, SkipRepeat, TaskType, NextRunDate, FunctionName, ClassName, TaskScheduleName, TaskScheduleNameEN
FROM (
	SELECT CAST(46 AS INT) IDTask, CAST(N'' AS VARCHAR(max)) ProducerName, CAST(NULL AS NVARCHAR(max)) Param, CAST(5.0 AS FLOAT) HourStart, CAST(0.0 AS FLOAT) MinuteStart, CAST(1 AS BIT) IsActive, CAST(N'2025-09-23 05:00:12' AS DATETIME) LastTryDay, CAST(NULL AS NVARCHAR(200)) ExceptIP, CAST(NULL AS VARCHAR(200)) ExportName, CAST(NULL AS BIT) SendMail, CAST(NULL AS NVARCHAR(4000)) EmailTemplateName, CAST(NULL AS BIT) RepeatDaily, CAST(NULL AS BIT) RepeatMonthly, CAST(NULL AS INT) RepeatDays, CAST(NULL AS INT) RepeatMinutes, CAST(1 AS BIT) SkipRepeat, CAST(2 AS INT) TaskType, CAST(N'2025-09-23 05:00:00' AS DATETIME) NextRunDate, CAST(N'BackupAndZipDatabase' AS NVARCHAR(200)) FunctionName, CAST(N'' AS NVARCHAR(200)) ClassName, CAST(NULL AS NVARCHAR(max)) TaskScheduleName, CAST(NULL AS NVARCHAR(max)) TaskScheduleNameEN
	
	UNION ALL
	
	SELECT 47, N'spMachineDOWNLOADLOGS', NULL, 1.0, 30.0, 0, N'2025-08-28 23:09:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-08-29 00:39:21', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 48, N'TA_ShiftDetector_task_NextMonth', NULL, 7.0, 50.0, 1, N'2025-09-23 15:26:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-09-23 15:26:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 49, N'sp_ShiftDetector_InOutStatistic', NULL, 11.0, NULL, 0, N'2018-03-03 11:53:24', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 4, N'2018-05-03 11:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 50, N'TA_ShiftDetector_task_LastMonth', NULL, 2.0, 30.0, 1, N'2025-09-23 02:30:07', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-09-23 02:30:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 51, N'TA_ShiftDetector_task_daily', NULL, 1.0, NULL, 1, N'2025-09-23 01:00:14', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-09-23 01:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 52, N'', NULL, 8.0, 0.0, 1, N'2024-09-22 15:56:01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-09-23 08:00:00', N'CheckUpdateParadise', N'HPA.Service.TaskThread', NULL, NULL
	
	UNION ALL
	
	SELECT 53, N'spMachineSYNCINFOR', NULL, 2.0, 0.0, 0, N'2017-09-07 12:05:19', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2017-09-12 02:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 54, N'spMachineDOWNLOADLOGS', NULL, 8.0, 45.0, 0, N'2025-08-28 23:09:15', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-08-29 08:45:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 55, N'sp_MachineDeleteUsersTerminate', NULL, 6.0, 0.0, 0, N'2018-01-29 08:53:38', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2018-02-03 06:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 56, N'sp_MachineDeleteLogs', NULL, 6.0, 0.0, 0, N'2018-01-22 12:34:51', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2018-01-25 06:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 57, N'', NULL, 0.0, 1.0, 0, N'2025-08-28 23:25:19', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-08-28 23:26:05', N'MachinesCommandPendingTaskTime', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 58, N'spMachineSYNCTIME', NULL, 8.0, 45.0, 0, N'2018-06-19 10:20:47', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2018-06-24 08:45:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 59, N'', NULL, 4.0, 1.0, 1, N'2025-09-23 04:01:05', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-09-23 04:01:00', N'ParadiseHub_Restart', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 60, N'', NULL, 0.0, 0.200000000000000, 1, N'2025-09-23 19:29:40', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-09-23 19:29:00', N'SendPendingEmail', N'HPA.Service.Common.EmailProcessing', NULL, NULL
	
	UNION ALL
	
	SELECT 62, N'', NULL, 8.0, 0.0, 0, N'2020-10-13 13:57:53', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2020-10-15 08:00:00', N'BackupAndCopyToNetworkDrive', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 63, N'sp_InOutLeaveTracking', NULL, 8.0, 0.0, 0, N'2019-10-02 07:00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2019-10-06 08:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 66, N'', NULL, 5.0, 1.0, 0, N'2023-06-28 05:01:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2023-06-29 05:01:00', N'RestartSQLServiceLocalMachine', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 69, N'sp_MachinesSYNCNeed', NULL, 4.0, 0.0, 0, N'2018-01-22 12:34:51', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2018-01-23 10:00:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 71, N'', NULL, 0.0, 30.0, 0, N'2020-10-13 13:58:12', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2020-10-13 14:57:00', N'ImportCheckInOutFromAccessFile', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 73, N'', NULL, 0.0, 30.0, 0, N'2025-08-28 23:09:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-08-28 23:39:01', N'ProcessFaceTempFromEmployeePhoto', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 74, N'spMachineRESTART', NULL, 9.0, 30.0, 0, N'2021-10-21 09:30:01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2021-10-22 09:30:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 75, N'', NULL, 12.0, 0.0, 1, N'2025-09-23 12:00:09', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-09-23 12:00:00', N'BackupAndZipDatabase', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 76, N'', NULL, 2.0, 0.0, 0, N'2021-11-05 14:01:01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2021-11-05 14:01:59', N'ZaloFollowerList_Update', N'HPA.Service.Common.ZaloOfficalAcount', NULL, NULL
	
	UNION ALL
	
	SELECT 77, N'', NULL, 6.0, 1.0, 0, N'2018-01-01 16:31:05', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, N'2018-01-22 06:01:00', N'RestartLocalMachine', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 78, N'sp_ZaloSendSMSPaySlipForEmployeeID', NULL, 0.0, 1.0, 0, N'2021-08-06 11:55:03', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2021-08-03 12:44:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 80, N'sp_tblParameterReloadConfig', NULL, 1.0, 0.0, 1, N'2025-09-23 18:56:07', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-09-23 18:56:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 81, N'sp_Machines_ProcessEmployeeToUploadDelete', NULL, 0.0, 30.0, 0, N'2023-06-28 09:22:22', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2023-06-28 09:52:22', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 83, N'ssSHRINKDATABASE', NULL, 4.0, 30.0, 1, N'2025-09-23 04:30:08', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, N'2025-09-23 04:30:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 84, N'sp_ClearPendingProcess', NULL, 2.0, 0.0, 1, N'2025-09-23 17:56:01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-09-23 17:56:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 85, N'TA_ShiftDetector_task', NULL, 1.0, NULL, 1, N'2025-09-23 19:23:10', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-09-23 19:23:00', N'', N'', NULL, NULL
	
	UNION ALL
	
	SELECT 86, N'', NULL, 1.0, 30.0, 1, N'2025-09-23 19:14:09', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, N'2025-09-23 19:14:00', N'ImportCheckInOutFromFolder', N'', NULL, NULL
	) tmpData

SET IDENTITY_INSERT TaskSchedule OFF
SET IDENTITY_INSERT tblProcedureName ON

INSERT INTO tblProcedureName (PROCID, ObjectID, ProcName, TemplateName, Descriptions, AutoGen, FixedParamter, StartRow, PreProcedureName, PostProcedureName, BlockImport, DontAlterMissingColumn, IsImportUsingEntireTable, FollowThreeStepImport, PostCommand, IsFollowThreeStepImport, AutoInsertUpdateToTable, ParamDefineRowPosition, TemplateBinary_FilenName, TemplateBinary_filename, ImportSheetName, DescriptionsEN, DescriptionsLA, IsImportAllSheet, FolderFilesCount, TypeImport, TypeImportRow)
SELECT PROCID, ObjectID, ProcName, TemplateName, Descriptions, AutoGen, FixedParamter, StartRow, PreProcedureName, PostProcedureName, BlockImport, DontAlterMissingColumn, IsImportUsingEntireTable, FollowThreeStepImport, PostCommand, IsFollowThreeStepImport, AutoInsertUpdateToTable, ParamDefineRowPosition, TemplateBinary_FilenName, TemplateBinary_filename, ImportSheetName, DescriptionsEN, DescriptionsLA, IsImportAllSheet, FolderFilesCount, TypeImport, TypeImportRow
FROM (
	SELECT CAST(184 AS INT) PROCID, CAST(8010 AS INT) ObjectID, CAST(N'ImportLogFile' AS NVARCHAR(200)) ProcName, CAST(N'ImportLogFile' AS NVARCHAR(200)) TemplateName, CAST(N'ImportLogFile' AS NVARCHAR(200)) Descriptions, CAST(NULL AS BIT) AutoGen, CAST(NULL AS NVARCHAR(max)) FixedParamter, CAST(NULL AS INT) StartRow, CAST(NULL AS NVARCHAR(200)) PreProcedureName, CAST(NULL AS NVARCHAR(200)) PostProcedureName, CAST(NULL AS BIT) BlockImport, CAST(NULL AS BIT) DontAlterMissingColumn, CAST(NULL AS BIT) IsImportUsingEntireTable, CAST(N'SchemaImportLogFile' AS NVARCHAR(500)) FollowThreeStepImport, CAST(NULL AS NVARCHAR(max)) PostCommand, CAST(1 AS BIT) IsFollowThreeStepImport, CAST(NULL AS NVARCHAR(200)) AutoInsertUpdateToTable, CAST(NULL AS INT) ParamDefineRowPosition, CAST(NULL AS NVARCHAR(300)) TemplateBinary_FilenName, CAST(NULL AS NVARCHAR(300)) TemplateBinary_filename, CAST(NULL AS NVARCHAR(500)) ImportSheetName, CAST(NULL AS NVARCHAR(1000)) DescriptionsEN, CAST(NULL AS NVARCHAR(1000)) DescriptionsLA, CAST(NULL AS BIT) IsImportAllSheet, CAST(NULL AS INT) FolderFilesCount, CAST(NULL AS 
			INT) TypeImport, CAST(NULL AS INT) TypeImportRow
	) tmpData

SET IDENTITY_INSERT tblProcedureName OFF

INSERT INTO tblParameter (Code, Value, Type, Category, Description, Visible, DescriptionEN)
SELECT Code, Value, Type, Category, Description, Visible, DescriptionEN
FROM (
	SELECT CAST(N'ImportLogFile_Location' AS VARCHAR(50)) Code, CAST(N'C:\Users\Vu.Le\Desktop\TVB_BarcodeLogsFile' AS VARCHAR(500)) Value, CAST(N'1' AS VARCHAR(10)) Type, CAST(N'TIME ATTENDANCE' AS VARCHAR(100)) Category, CAST(N'[TRIPOD] Đường dẫn tuyệt đối folder chứa file log chấm công txt' AS NVARCHAR(max)) Description, CAST(1 AS BIT) Visible, CAST(NULL AS NVARCHAR(max)) DescriptionEN
	
	UNION ALL
	
	SELECT N'ImportLogFile_Procedure', N'sp_ReadFile_Service', N'1', N'TIME ATTENDANCE', N'[TRIPOD] Thủ tục xử lý đọc file và đánh dấu file đã được đọc', 1, NULL
	
	UNION ALL
	
	SELECT N'ImportLogFile_TemplateName', N'ImportLogFile', N'1', N'TIME ATTENDANCE', N'[TRIPOD] Tên template cấu hình import', 1, NULL
	) tmpData

