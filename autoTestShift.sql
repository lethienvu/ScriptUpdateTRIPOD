
ALTER PROCEDURE sp_Test_ShiftDetector_Regression
    @LoginID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @EmployeeID VARCHAR(20) = '-1' -- '-1' là tất cả nhân viên
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Chuẩn bị danh sách nhân viên test
    SELECT EmployeeID
    INTO #EmployeeList
    FROM dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, @EmployeeID, @LoginID);

    /******************** ĐO THỜI GIAN VÀ LẤY KẾT QUẢ PHIÊN BẢN CŨ ********************/
    DECLARE @OldStart DATETIME = GETDATE(), @OldEnd DATETIME, @DurationOld INT;
    EXEC sp_ReCalculate_TAData 
        @LoginID = @LoginID, 
        @Fromdate = @FromDate, 
        @ToDate = @ToDate, 
        @EmployeeID_Pram = @EmployeeID, 
        @RunShiftDetector = 1, -- Version cũ
        @RunTA_Precess_Main = 0;
    SET @OldEnd = GETDATE();
    SET @DurationOld = DATEDIFF(MILLISECOND, @OldStart, @OldEnd);

    -- Lưu kết quả đầu ra version cũ
    SELECT * INTO #Result_Old FROM tblHasTA WHERE AttDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (SELECT EmployeeID FROM #EmployeeList);
    SELECT * INTO #WSchedule_Old FROM tblWSchedule WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (SELECT EmployeeID FROM #EmployeeList);
    SELECT * INTO #LvHistory_Old FROM tblLvHistory WHERE LeaveDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (SELECT EmployeeID FROM #EmployeeList);

    /******************** ĐO THỜI GIAN VÀ LẤY KẾT QUẢ PHIÊN BẢN MỚI ********************/
    DECLARE @NewStart DATETIME = GETDATE(), @NewEnd DATETIME, @DurationNew INT;
    EXEC sp_ReCalculate_TAData 
        @LoginID = @LoginID, 
        @Fromdate = @FromDate, 
        @ToDate = @ToDate, 
        @EmployeeID_Pram = @EmployeeID, 
        @RunShiftDetector = 2, -- Version mới
        @RunTA_Precess_Main = 0;
    SET @NewEnd = GETDATE();
    SET @DurationNew = DATEDIFF(MILLISECOND, @NewStart, @NewEnd);

    -- Lưu kết quả đầu ra version mới
    SELECT * INTO #Result_New FROM tblHasTA WHERE AttDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (SELECT EmployeeID FROM #EmployeeList);
    SELECT * INTO #WSchedule_New FROM tblWSchedule WHERE ScheduleDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (SELECT EmployeeID FROM #EmployeeList);
    SELECT * INTO #LvHistory_New FROM tblLvHistory WHERE LeaveDate BETWEEN @FromDate AND @ToDate AND EmployeeID IN (SELECT EmployeeID FROM #EmployeeList);

    /******************** TÍNH % CẢI THIỆN THỜI GIAN ********************/
    DECLARE @ImprovePercent FLOAT;
    IF @DurationOld > 0
        SET @ImprovePercent = 100.0 * (@DurationOld - @DurationNew) / @DurationOld;
    ELSE
        SET @ImprovePercent = NULL;

    /******************** SO SÁNH tblHasTA ********************/
    SELECT 
        o.EmployeeID, o.AttDate, o.Period,
        o.AttStart AS Old_AttStart, n.AttStart AS New_AttStart,
        o.AttEnd AS Old_AttEnd, n.AttEnd AS New_AttEnd,
        o.WorkingTime AS Old_WorkingTime, n.WorkingTime AS New_WorkingTime,
        CASE 
            WHEN ISNULL(o.AttStart, '') <> ISNULL(n.AttStart, '') THEN 'Diff_AttStart'
            WHEN ISNULL(o.AttEnd, '') <> ISNULL(n.AttEnd, '') THEN 'Diff_AttEnd'
            WHEN ISNULL(o.WorkingTime, 0) <> ISNULL(n.WorkingTime, 0) THEN 'Diff_WorkingTime'
            ELSE 'OK'
        END AS CompareResult
    INTO #CompareResult
    FROM #Result_Old o
    FULL JOIN #Result_New n
        ON o.EmployeeID = n.EmployeeID AND o.AttDate = n.AttDate AND o.Period = n.Period;

    -- Xuất chi tiết các trường hợp khác biệt tblHasTA
    SELECT * FROM #CompareResult WHERE CompareResult <> 'OK';

    -- Thống kê số lượng trường hợp giống/khác biệt tblHasTA
    SELECT CompareResult, COUNT(*) AS SoLuong FROM #CompareResult GROUP BY CompareResult;

    /******************** SO SÁNH tblWSchedule ********************/
    -- Có ở Old mà không có ở New
    SELECT 'WSchedule_Old_NOT_IN_New' AS DiffType, w.*
    FROM #WSchedule_Old w
    WHERE NOT EXISTS (
        SELECT 1 FROM #WSchedule_New wn
        WHERE w.EmployeeID = wn.EmployeeID
        AND w.ScheduleDate = wn.ScheduleDate
        AND w.ShiftID = wn.ShiftID
    );
    -- Có ở New mà không có ở Old
    SELECT 'WSchedule_New_NOT_IN_Old' AS DiffType, wn.*
    FROM #WSchedule_New wn
    WHERE NOT EXISTS (
        SELECT 1 FROM #WSchedule_Old w
        WHERE wn.EmployeeID = w.EmployeeID
        AND wn.ScheduleDate = w.ScheduleDate
        AND wn.ShiftID = w.ShiftID
    );

    /******************** SO SÁNH tblLvHistory ********************/
    -- Có ở Old mà không có ở New
    SELECT 'LvHistory_Old_NOT_IN_New' AS DiffType, l.*
    FROM #LvHistory_Old l
    WHERE NOT EXISTS (
        SELECT 1 FROM #LvHistory_New ln
        WHERE l.EmployeeID = ln.EmployeeID
        AND l.LeaveDate = ln.LeaveDate
        AND l.LeaveCode = ln.LeaveCode
    );
    -- Có ở New mà không có ở Old
    SELECT 'LvHistory_New_NOT_IN_Old' AS DiffType, ln.*
    FROM #LvHistory_New ln
    WHERE NOT EXISTS (
        SELECT 1 FROM #LvHistory_Old l
        WHERE ln.EmployeeID = l.EmployeeID
        AND ln.LeaveDate = l.LeaveDate
        AND ln.LeaveCode = l.LeaveCode
    );

    /******************** XUẤT THỜI GIAN CHẠY VÀ % CẢI THIỆN ********************/
    SELECT 
        @DurationOld AS OldVersion_Milliseconds,
        @DurationNew AS NewVersion_Milliseconds,
        @ImprovePercent AS Improve_Percent;

    /******************** DỌN DẸP DỮ LIỆU TẠM ********************/
    DROP TABLE IF EXISTS #EmployeeList, #Result_Old, #Result_New, #CompareResult;
    DROP TABLE IF EXISTS #WSchedule_Old, #WSchedule_New;
    DROP TABLE IF EXISTS #LvHistory_Old, #LvHistory_New;
END
GO
exec sp_Test_ShiftDetector_Regression 3,'2025-07-01','2025-07-31','-1'