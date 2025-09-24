DELETE
FROM tblAllowanceSetting

------------------------------
SET IDENTITY_INSERT tblAllowanceSetting ON

INSERT INTO tblAllowanceSetting (AllowanceID, AllowanceCode, AllowanceName, ForSalary, Customize, DefaultAmount, AllowanceRuleID, Visible, TaxfreeMaxAmount, IsHouseAllowance, isUniformAllowance, IncludedIns, Ord, IncludedSalOT, BasedOnSalaryScale, AllowanceNameEN, IsTaxable, IsGrossAllowance_InNetSal, IsMutilCurrencyCode, IsNotLabourCost, AllowanceSettingName, GroupAllowanceName_PRVN, StillHasTaxExemptionWhenTempContract, MonthlyCustomAmountColumnName, ViewTaxedAmountAsReceiveAmount, IsBounus, UserDisplayCode, AllowanceNameCN, RuleDescription, Parameter, AllowanceGrossSalary)
SELECT AllowanceID, AllowanceCode, AllowanceName, ForSalary, Customize, DefaultAmount, AllowanceRuleID, Visible, TaxfreeMaxAmount, IsHouseAllowance, isUniformAllowance, IncludedIns, Ord, IncludedSalOT, BasedOnSalaryScale, AllowanceNameEN, IsTaxable, IsGrossAllowance_InNetSal, IsMutilCurrencyCode, IsNotLabourCost, AllowanceSettingName, GroupAllowanceName_PRVN, StillHasTaxExemptionWhenTempContract, MonthlyCustomAmountColumnName, ViewTaxedAmountAsReceiveAmount, IsBounus, UserDisplayCode, AllowanceNameCN, RuleDescription, Parameter, AllowanceGrossSalary
FROM (
	SELECT CAST(1 AS INT) AllowanceID, CAST(N'1' AS VARCHAR(20)) AllowanceCode, CAST(N'Seniority allowance' AS NVARCHAR(200)) AllowanceName, CAST(1 AS BIT) ForSalary, CAST(NULL AS BIT) Customize, CAST(NULL AS MONEY) DefaultAmount, CAST(999 AS INT) AllowanceRuleID, CAST(1 AS BIT) Visible, CAST(NULL AS MONEY) TaxfreeMaxAmount, CAST(NULL AS BIT) IsHouseAllowance, CAST(NULL AS BIT) isUniformAllowance, CAST(NULL AS BIT) IncludedIns, CAST(1 AS INT) Ord, CAST(0 AS BIT) IncludedSalOT, CAST(NULL AS BIT) BasedOnSalaryScale, CAST(N'Seniority allowance (long term)' AS NVARCHAR(500)) AllowanceNameEN, CAST(1 AS BIT) IsTaxable, CAST(NULL AS BIT) IsGrossAllowance_InNetSal, CAST(NULL AS BIT) IsMutilCurrencyCode, CAST(NULL AS BIT) IsNotLabourCost, CAST(NULL AS NVARCHAR(255)) AllowanceSettingName, CAST(NULL AS NVARCHAR(50)) GroupAllowanceName_PRVN, CAST(NULL AS BIT) StillHasTaxExemptionWhenTempContract, CAST(NULL AS VARCHAR(100)) MonthlyCustomAmountColumnName, CAST(NULL AS BIT) ViewTaxedAmountAsReceiveAmount, CAST(NULL AS BIT) IsBounus, CAST(NULL AS VARCHAR(100)) UserDisplayCode, CAST(NULL AS NVARCHAR(255)) 
		AllowanceNameCN, CAST(N'Parameter Number of Working days must be >=  5  From 2nd year: 30k/month  From 3rd ~ 5th year: 40 ~ 60k/month  From 6th ~ 10th year: 90 ~ 130k/month  From 11th ~ 14th year: 160 ~ 190k/month  From 15th year and above: 200k/month' AS NVARCHAR(max)) RuleDescription, CAST(5 AS INT) Parameter, CAST(NULL AS BIT) AllowanceGrossSalary
	
	UNION ALL
	
	SELECT 2, N'2', N'Production bonus', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 2, 0, NULL, N'Production bonus', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'1. Number of Working days >= 15 2. Only applicable to department manager, supervisors, Group leaders, Leaders. 3. There are 2 levels: - Level 1: gross salary * 10% - Level 2: gross salary * 20%', 15, 1
	
	UNION ALL
	
	SELECT 3, N'3', N'Foreign language allowance', 1, NULL, 2000000, 999, 1, NULL, NULL, NULL, NULL, 3, 0, NULL, N'Foreign language allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'Number of Working days must be >=  15', 15, 1
	
	UNION ALL
	
	SELECT 4, N'4', N'Environmental allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 4, 0, NULL, N'Environmental allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
	
	UNION ALL
	
	SELECT 5, N'5', N'Shift allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 5, 0, NULL, N'Shift allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
	
	UNION ALL
	
	SELECT 6, N'6', N'Fuel allowance', 1, NULL, 500000, 999, 1, NULL, NULL, NULL, NULL, 6, NULL, NULL, N'Fuel allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'Number of Working days must be creater than 5, not applicable for probationary employees', 5, NULL
	
	UNION ALL
	
	SELECT 7, N'7', N'Professional allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 7, 0, NULL, N'Professional allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
	
	UNION ALL
	
	SELECT 8, N'8', N'Attendance allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 8, NULL, NULL, N'Attendance allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'Master data in position list', NULL, NULL
	
	UNION ALL
	
	SELECT 9, N'9', N'Meal allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 9, NULL, NULL, N'Meal allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	
	UNION ALL
	
	SELECT 10, N'10', N'Regional (area) allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 10, 0, NULL, N'Regional(area) allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
	
	UNION ALL
	
	SELECT 11, N'11', N'Incentive allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 11, NULL, NULL, N'Incentive allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	
	UNION ALL
	
	SELECT 12, N'12', N'Key process allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 12, NULL, NULL, N'Key process allowance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	
	UNION ALL
	
	SELECT 13, N'13', N'Bonus 6 month', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 13, NULL, NULL, N'Bonus 6 month', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	
	UNION ALL
	
	SELECT 14, N'14', N'Performance & Responsibility', 0, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, 14, NULL, NULL, N'Performance & Responsibility', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
	
	UNION ALL
	
	SELECT 15, N'15', N'Bonus 6 month full attendance', 1, NULL, 600000, 1, 1, NULL, NULL, NULL, NULL, 15, NULL, NULL, N'Bonus 6 month full attendance', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'Work for 6 months without being late or leaving early', NULL, NULL
	
	UNION ALL
	
	SELECT 16, N'16', N'[Foreign] Meal allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 16, NULL, NULL, N'[Foreign] Meal allowance', 0, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'Meal allowance for foreign', NULL, NULL
	
	UNION ALL
	
	SELECT 17, N'17', N'[Foreign] House allowance', 1, NULL, NULL, 999, 1, NULL, NULL, NULL, NULL, 17, NULL, NULL, N'[Foreign] House allowance', 0, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'House rent allowance for foreign', NULL, NULL
	) tmpData

SET IDENTITY_INSERT tblAllowanceSetting OFF

DELETE
FROM Machines

SET IDENTITY_INSERT Machines ON

INSERT INTO Machines (MachineAlias, ConnectType, IP, SerialPort, Port, Baudrate, MachineNumber, MachineType, IsHost, Enabled, CommPassword, UILanguage, DATEFORMAT, InOutRecordWarn, Idle, Voice, managercount, usercount, fingercount, SecretCount, FirmwareVersion, ProductType, LockControl, Purpose, ProduceKind, STATUS, sn, PhotoStamp, DeviceNetmask, DeviceGetway, IsIfChangeConfigServer2, CDKey, LicenseNumber, IsAndroid, MealMachine, ID, InOutStatus, FactoryIP, MachineStatus, FactoryID, LogsCount, FingerCapacity, UserCapacity, LogsCapacity, FaceCapacity, FaceCount, ZKFPVersion, ScreenType, ManagerCapacity, CardNoCount, ProductName, DownloadLogsLast, PlatformMachine, SDKVersion, DeviceInfo, DeviceMAC, Vendor, IDFR, MachineTimeZone, NotSyns, Priority, Visible, PalmCapacity, PalmCount, OrderDOWNLOADLOGS, NotDownloadUsers, NotSupportCloudSDK, NotDOWNLOADLOGS, NotUploadUsers, IDMachine)
SELECT MachineAlias, ConnectType, IP, SerialPort, Port, Baudrate, MachineNumber, MachineType, IsHost, Enabled, CommPassword, UILanguage, DATEFORMAT, InOutRecordWarn, Idle, Voice, managercount, usercount, fingercount, SecretCount, FirmwareVersion, ProductType, LockControl, Purpose, ProduceKind, STATUS, sn, PhotoStamp, DeviceNetmask, DeviceGetway, IsIfChangeConfigServer2, CDKey, LicenseNumber, IsAndroid, MealMachine, ID, InOutStatus, FactoryIP, MachineStatus, FactoryID, LogsCount, FingerCapacity, UserCapacity, LogsCapacity, FaceCapacity, FaceCount, ZKFPVersion, ScreenType, ManagerCapacity, CardNoCount, ProductName, DownloadLogsLast, PlatformMachine, SDKVersion, DeviceInfo, DeviceMAC, Vendor, IDFR, MachineTimeZone, NotSyns, Priority, Visible, PalmCapacity, PalmCount, OrderDOWNLOADLOGS, NotDownloadUsers, NotSupportCloudSDK, NotDOWNLOADLOGS, NotUploadUsers, IDMachine
FROM (
	SELECT CAST(N'GATE-144-1T' AS NVARCHAR(200)) MachineAlias, CAST(2 AS INT) ConnectType, CAST(N'10.12.18.201' AS VARCHAR(400)) IP, CAST(NULL AS INT) SerialPort, CAST(0 AS INT) Port, CAST(NULL AS INT) Baudrate, CAST(1 AS INT) MachineNumber, CAST(99 AS INT) MachineType, CAST(1 AS BIT) IsHost, CAST(1 AS BIT) Enabled, CAST(N'' AS NVARCHAR(255)) CommPassword, CAST(NULL AS INT) UILanguage, CAST(NULL AS INT) DATEFORMAT, CAST(NULL AS INT) InOutRecordWarn, CAST(NULL AS INT) Idle, CAST(NULL AS INT) Voice, CAST(- 1 AS INT) managercount, CAST(- 1 AS INT) usercount, CAST(- 1 AS INT) fingercount, CAST(- 1 AS INT) SecretCount, CAST(N'' AS NVARCHAR(50)) FirmwareVersion, CAST(NULL AS NVARCHAR(20)) ProductType, CAST(NULL AS INT) LockControl, CAST(NULL AS INT) Purpose, CAST(NULL AS INT) ProduceKind, CAST(NULL AS NVARCHAR(50)) STATUS, CAST(N'' AS NVARCHAR(64)) sn, CAST(NULL AS VARCHAR(20)) PhotoStamp, CAST(NULL AS VARCHAR(16)) DeviceNetmask, CAST(NULL AS VARCHAR(16)) DeviceGetway, CAST(0 AS INT) IsIfChangeConfigServer2, CAST(N'' AS VARCHAR(50)) CDKey, CAST(NULL AS INT) LicenseNumber, CAST(N'0' AS VARCHAR(1)) IsAndroid, CAST(NULL AS BIT) 
		MealMachine, CAST(77 AS INT) ID, CAST(0 AS INT) InOutStatus, CAST(N'27.64.18.119' AS VARCHAR(100)) FactoryIP, CAST(N'ERRORCONNECT' AS NVARCHAR(4000)) MachineStatus, CAST(N'a0ec5e1b-4686-409f-ae16-271d6a8f8289' AS VARCHAR(100)) FactoryID, CAST(0 AS INT) LogsCount, CAST(- 1 AS INT) FingerCapacity, CAST(- 1 AS INT) UserCapacity, CAST(- 1 AS INT) LogsCapacity, CAST(- 1 AS INT) FaceCapacity, CAST(- 1 AS INT) FaceCount, CAST(N'' AS VARCHAR(50)) ZKFPVersion, CAST(- 1 AS INT) ScreenType, CAST(- 1 AS INT) ManagerCapacity, CAST(- 1 AS INT) CardNoCount, CAST(N'' AS NVARCHAR(100)) ProductName, CAST(NULL AS DATETIME) DownloadLogsLast, CAST(N'' AS NVARCHAR(100)) PlatformMachine, CAST(N'' AS NVARCHAR(100)) SDKVersion, CAST(N'' AS NVARCHAR(100)) DeviceInfo, CAST(N'' AS NVARCHAR(100)) DeviceMAC, CAST(N'' AS NVARCHAR(100)) Vendor, CAST(N'' AS VARCHAR(50)) IDFR, CAST(N'+0700' AS VARCHAR(20)) MachineTimeZone, CAST(1 AS BIT) NotSyns, CAST(NULL AS INT) Priority, CAST(1 AS BIT) Visible, CAST(- 1 AS INT) PalmCapacity, CAST(- 1 AS INT) PalmCount, CAST(NULL AS INT) OrderDOWNLOADLOGS, CAST(0 AS BIT) NotDownloadUsers, CAST(0 AS BIT) 
		NotSupportCloudSDK, CAST(0 AS BIT) NotDOWNLOADLOGS, CAST(NULL AS BIT) NotUploadUsers, CAST(NULL AS VARCHAR(50)) IDMachine
	
	UNION ALL
	
	SELECT N'PORT_484_2T', 2, N'10.12.38.242', NULL, 0, NULL, 2, 99, 1, 1, N'', NULL, NULL, NULL, NULL, NULL, - 1, - 1, - 1, - 1, N'', NULL, NULL, NULL, NULL, NULL, N'', NULL, NULL, NULL, 0, N'', NULL, N'0', NULL, 79, 0, N'27.64.18.119', N'ERRORCONNECT', N'a0ec5e1b-4686-409f-ae16-271d6a8f8289', 0, - 1, - 1, - 1, - 1, - 1, N'', - 1, - 1, - 1, N'', NULL, N'', N'', N'', N'', N'', N'', N'+0700', 1, NULL, 1, - 1, - 1, NULL, 0, 0, 0, NULL, NULL
	
	UNION ALL
	
	SELECT N'PORT_180_2T', 2, N'10.12.38.243', NULL, 0, NULL, 3, 99, 1, 1, N'', NULL, NULL, NULL, NULL, NULL, - 1, - 1, - 1, - 1, N'', NULL, NULL, NULL, NULL, NULL, N'', NULL, NULL, NULL, 0, N'', NULL, N'0', NULL, 80, 0, N'27.64.18.119', N'ERRORCONNECT', N'a0ec5e1b-4686-409f-ae16-271d6a8f8289', 0, - 1, - 1, - 1, - 1, - 1, N'', - 1, - 1, - 1, N'', NULL, N'', N'', N'', N'', N'', N'', N'+0700', 1, NULL, 1, - 1, - 1, NULL, 0, 0, 0, NULL, NULL
	
	UNION ALL
	
	SELECT N'PORT_180_1T', 2, N'10.12.38.244', NULL, 0, NULL, 4, 99, 1, 1, N'', NULL, NULL, NULL, NULL, NULL, - 1, - 1, - 1, - 1, N'', NULL, NULL, NULL, NULL, NULL, N'', NULL, NULL, NULL, 0, N'', NULL, N'0', NULL, 81, 0, N'27.64.18.119', N'ERRORCONNECT', N'a0ec5e1b-4686-409f-ae16-271d6a8f8289', 0, - 1, - 1, - 1, - 1, - 1, N'', - 1, - 1, - 1, N'', NULL, N'', N'', N'', N'', N'', N'', N'+0700', 1, NULL, 1, - 1, - 1, NULL, 0, 0, 0, NULL, NULL
	
	UNION ALL
	
	SELECT N'GATE-144-2', 2, N'10.12.18.202', NULL, 0, NULL, 5, 99, 1, 1, N'', NULL, NULL, NULL, NULL, NULL, - 1, - 1, - 1, - 1, N'', NULL, NULL, NULL, NULL, NULL, N'', NULL, NULL, NULL, 0, N'', NULL, N'0', NULL, 82, 0, N'27.64.18.119', N'ERRORCONNECT', N'a0ec5e1b-4686-409f-ae16-271d6a8f8289', 0, - 1, - 1, - 1, - 1, - 1, N'', - 1, - 1, - 1, N'', NULL, N'', N'', N'', N'', N'', N'', N'+0700', 1, NULL, 1, - 1, - 1, NULL, 0, 0, 0, NULL, NULL
	) tmpData

SET IDENTITY_INSERT Machines OFF


delete from tblSalaryHistory where EmployeeID in ('62250007','62250008','62250009','62250010','62250011','62250012','62250013','62250029','62250030','62250031')

SET IDENTITY_INSERT tblSalaryHistory ON
insert into tblSalaryHistory(SalaryHistoryID,EmployeeID,Date,RetroDate,Salary,InsSalary,NETSalary,SalCalRuleID,Note,CurrencyCode,PositionID,BaseSalRegionalID,CDP_TAX_EE_AL_CurrencyCode,Trans_Tax_EE_AL_CurrencyCode,IsNet,PayrollTypeCode,WorkingHoursPerDay,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],PercentProbation,[15],[16],[17],ExchangeRate_Contract)
select SalaryHistoryID,EmployeeID,Date,RetroDate,Salary,InsSalary,NETSalary,SalCalRuleID,Note,CurrencyCode,PositionID,BaseSalRegionalID,CDP_TAX_EE_AL_CurrencyCode,Trans_Tax_EE_AL_CurrencyCode,IsNet,PayrollTypeCode,WorkingHoursPerDay,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],PercentProbation,[15],[16],[17],ExchangeRate_Contract from (	select CAST(1746 as int) SalaryHistoryID,CAST(N'62250007' as varchar(20)) EmployeeID,CAST(N'2025-07-07' as date) Date,CAST(NULL as datetime) RetroDate,CAST(1500 as money) Salary,CAST(1500 as money) InsSalary,CAST(1500 as money) NETSalary,CAST(1 as tinyint) SalCalRuleID,CAST(NULL as nvarchar(max)) Note,CAST(N'USD' as varchar(20)) CurrencyCode,CAST(40 as int) PositionID,CAST(2 as int) BaseSalRegionalID,CAST(NULL as nvarchar(20)) CDP_TAX_EE_AL_CurrencyCode,CAST(NULL as nvarchar(20)) Trans_Tax_EE_AL_CurrencyCode,CAST(1 as bit) IsNet,CAST(NULL as nvarchar(20)) PayrollTypeCode,CAST(NULL as float) WorkingHoursPerDay,CAST(NULL as money) [1],CAST(NULL as money) [2],CAST(NULL as money) [3],CAST(NULL as money) [4],CAST(NULL as money) [5],CAST(NULL as money) [6],CAST(NULL as money) [7],CAST(NULL as money) [8],CAST(NULL as money) [9],CAST(NULL as money) [10],CAST(NULL as money) [11],CAST(NULL as money) [12],CAST(NULL as money) [13],CAST(NULL as money) [14],CAST(NULL as float) PercentProbation,CAST(NULL as money) [15],CAST(NULL as money) [16],CAST(NULL as money) [17],CAST(25058.0 as float) ExchangeRate_Contract	union all select 1747,N'62250008',N'2025-07-16',NULL,1000,1000,1000,1,NULL,N'USD',42,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1748,N'62250009',N'2025-06-15',NULL,1500,1500,1500,1,NULL,N'USD',40,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1749,N'62250010',N'2025-06-20',NULL,1500,1500,1500,1,NULL,N'USD',40,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1750,N'62250011',N'2025-06-15',NULL,1500,1500,1500,1,NULL,N'USD',41,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1751,N'62250012',N'2025-06-15',NULL,1000,1000,1000,1,NULL,N'USD',39,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1752,N'62250013',N'2025-07-16',NULL,1000,1000,1000,1,NULL,N'USD',41,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1766,N'62250029',N'2025-07-07',NULL,600,600,600,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1767,N'62250030',N'2025-07-07',NULL,600,600,600,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0	union all select 1768,N'62250031',N'2025-07-07',NULL,600,600,600,1,NULL,N'USD',20,2,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25058.0) tmpData
SET IDENTITY_INSERT tblSalaryHistory OFF



DELETE from tblSal_Insurance where EmployeeID in ('62250007','62250008','62250009','62250010','62250011','62250012','62250013','62250029','62250030','62250031') AND Month = 7 AND Year = 2025



insert into tblSal_Insurance(EmployeeID,Year,Month,HIIncome,SIIncome,EmployeeHI,EmployeeSI,EmployeeTotal,CompanyHI,CompanySI,CompanyTotal,Total,SalaryHistoryID,UIIncome,EmployeeUI,CompanyUI,Approval,UnionFeeEmp,UnionFeeComp,Notes,InsPaymentStatus,EmployeeSM,CompanySM)  select EmployeeID,Year,Month,HIIncome,SIIncome,EmployeeHI,EmployeeSI,EmployeeTotal,CompanyHI,CompanySI,CompanyTotal,Total,SalaryHistoryID,UIIncome,EmployeeUI,CompanyUI,Approval,UnionFeeEmp,UnionFeeComp,Notes,InsPaymentStatus,EmployeeSM,CompanySM  from (   select CAST(N'62250007' as varchar(20)) EmployeeID,CAST(2025 as smallint) Year,CAST(7 as smallint) Month,CAST(37587000 as money) HIIncome,CAST(37587000 as money) SIIncome,CAST(563805 as money) EmployeeHI,CAST(3006960 as money) EmployeeSI,CAST(3570765 as money) EmployeeTotal,CAST(1127610 as money) CompanyHI,CAST(6577725 as money) CompanySI,CAST(7705335 as money) CompanyTotal,CAST(11276100 as money) Total,CAST(1746 as int) SalaryHistoryID,CAST(37587000 as money) UIIncome,CAST(0 as money) EmployeeUI,CAST(0 as money) CompanyUI,CAST(0 as bit) Approval,CAST(NULL as money) UnionFeeEmp,CAST(NULL as money) UnionFeeComp,CAST(N'Tăng mới' as nvarchar(max)) Notes,CAST(0 as int) InsPaymentStatus,CAST(NULL as money) EmployeeSM,CAST(NULL as money) CompanySM   union all select N'62250008',2025,7,0,0,0,0,0,0,0,0,0,NULL,0,0,0,0,NULL,NULL,N'Không có lương đóng BH',0,NULL,0   union all select N'62250009',2025,7,37587000,37587000,563805,3006960,3570765,1127610,6577725,7705335,11276100,1748,37587000,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL   union all select N'62250010',2025,7,37587000,37587000,563805,3006960,3570765,1127610,6577725,7705335,11276100,1749,37587000,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL   union all select N'62250011',2025,7,37587000,37587000,563805,3006960,3570765,1127610,6577725,7705335,11276100,1750,37587000,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL   union all select N'62250012',2025,7,25058000,25058000,375870,2004640,2380510,751740,4385150,5136890,7517400,1751,25058000,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL   union all select N'62250013',2025,7,0,0,0,0,0,0,0,0,0,NULL,0,0,0,0,NULL,NULL,N'Không có lương đóng BH',0,NULL,0   union all select N'62250029',2025,7,15034800,15034800,225522,1202784,1428306,451044,2631090,3082134,4510440,1766,15034800,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL   union all select N'62250030',2025,7,15034800,15034800,225522,1202784,1428306,451044,2631090,3082134,4510440,1767,15034800,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL   union all select N'62250031',2025,7,15034800,15034800,225522,1202784,1428306,451044,2631090,3082134,4510440,1768,15034800,0,0,0,NULL,NULL,N'Tăng mới',0,NULL,NULL  ) tmpData  