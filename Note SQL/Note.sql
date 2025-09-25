USE Paradise_TRIPOD_20250921
GO
if object_id('[dbo].[sp_PrintLaborContractBlock]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_PrintLaborContractBlock] as select 1')
GO
-- exec sp_printlaborcontractblock @CallFromLabourContract=1,@MenuID='MnuHRS169',@ContractID=94,@loginID=3
ALTER PROCEDURE [dbo].[sp_PrintLaborContractBlock]
(
	@loginID INT,
	@MenuID varchar(20),
	@ContractID bigint = null
)
as
begin
CREATE TABLE #tmpPrintData(
	EmployeeID varchar(20),
	ContractNo nvarchar(500),
	ContractStartDay datetime,
	ContractEndDay datetime,
	LBIssueDate datetime,
	ContractCode varchar(5),
	SalaryHistoryID bigint,
	CommitmentKind varchar(30),
	ContractTemplateName nvarchar(500)
)
declare @printDate datetime = getdate()
if @MenuID = 'MnuHRS169' --lich su ky hd
begin
	insert into #tmpPrintData(EmployeeID, ContractNo, ContractStartDay, ContractEndDay, LBIssueDate, ContractCode, SalaryHistoryID,CommitmentKind,ContractTemplateName)
	select EmployeeID, ContractNo, ContractStartDay, ContractEndDay, LBIssueDate, ContractCode, SalaryHistoryID,lb.CommitmentKind,ContractTemplateName
	from tblLabourContract lb where ContractID = @ContractID
	select @PrintDate = lb.ContractStartDay from tblLabourContract lb where lb.ContractID = @ContractID
end
else
begin
	insert into #tmpPrintData(EmployeeID, ContractNo, ContractStartDay, ContractEndDay, LBIssueDate, ContractCode, SalaryHistoryID,CommitmentKind,ContractTemplateName)
	select EmployeeID, ContractNo, ContractStartDay, ContractEndDay, LBIssueDate, lb.ContractCode, SalaryHistoryID,rep.CommitmentKind, ct.ContractTemplateList
	from tmpLabourContractForPrint lb left join tblRepresentativeSetting rep on lb.CommitmentKind = rep.CommitmentKind
	inner join tblMST_ContractType ct on lb.ContractCode = ct.ContractCode
	where lb.[Check] = 1 -- and lb.LoginID = @loginID
	and lb.EmployeeID in (select EmployeeID from tmpEmployeeTree tr where tr.LoginID = @loginID)
end

-- khởi tạo quỹ nghỉ
declare @FiscalYear int
set @FiscalYear = dbo.fn_Get_FiscalYear(@printDate)
--EXEC HR_LeaveBudget_Initialization @LoginID = @LoginID,@CalendarYear = @FiscalYear,@LeaveCode='AL', @EmployeeID = @EmployeeID_AL
DECLARE @FakeLogin int
SET @FakeLogin = @LoginID + 1000
delete tmpEmployeeTree where LoginID = @FakeLogin
insert into tmpEmployeeTree(EmployeeID, LoginID)
select distinct EmployeeID, @FakeLogin from #tmpPrintData

--thông tin cơ bản
select distinct
lb.ContractNo N'Số hợp đồng',
--thông tin hợp đồng
ct.ContractName N'Tên hợp đồng',
ct.ContractNameEN N'Tên hợp đồng(Tiếng anh)',
char(39)+CONVERT(varchar,lb.ContractStartDay,120) N'Ngày bắt đầu HĐ',
char(39)+CONVERT(varchar,lb.ContractEndDay,120) N'Ngày kết thúc HĐ',
REPLACE(CONVERT(varchar(60), (CAST(case when st.SalCalRuleID = 3 then 26 else 1 end *  St.Salary AS money)), 1), '.00', '') N'Lương cơ bản'
,st.*
--, st.CurrencyCode N'Đơn vị tiền tệ', st.[Date] N'Ngày hiệu lực lương', st.InsSalary N'Lương đóng bảo hiểm',
,lb.LBIssueDate N'Ngày ký HĐ'
--một số thông tin liên quan
,dbo.fn_Get_FiscalYear(lb.ContractStartDay) N'Năm tài chính'
,dbo.fn_Get_FiscalYear(lb.ContractStartDay) +1 N'Năm tài chính kế tiếp'
,dbo.fn_Get_FiscalYear(lb.ContractStartDay) +2 N'Năm tài chính + 2'

,printInfo.*, @printDate as N'Ngày in'
,lb.ContractTemplateName as ExportName
from #tmpPrintData lb
inner join tblMST_ContractType ct on lb.ContractCode = ct.ContractCode
left join tblSalaryHistory st on lb.SalaryHistoryID = st.SalaryHistoryID
cross apply (select * from dbo.fn_CommontEmployeeInfoUsedForPrintDoc(@FakeLogin,lb.ContractStartDay) printInfo where lb.EmployeeID = printinfo.EmployeeID)  printInfo

delete tmpEmployeeTree where LoginID = @FakeLogin
end
GO
exec sp_printlaborcontractblock @loginID=3,@MenuID='MnuHRS169',@ContractID=1659


SELECT * FROM tblAllowanceSetting