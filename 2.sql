ALTER PROCEDURE spWidgetAttendance
    @TotalEmployees INT,
    @TotalDays INT,
    @LateOrEarly INT,
    @MissingCheckInOut INT,
    @WorkOnHoliday INT,
    @Efficiency DECIMAL(5,2) = 98.5,
    @OT_Hrs DECIMAL(5,2) = 0,
    @Period NVARCHAR(50) = N'01-08-2025 đến 30-08-2025',
    @IsLocked BIT = 0,
    @StandardWorkingDays INT = 22
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @css NVARCHAR(MAX) = N'
<style>
.widget-card {
    background: white;
    border-radius: 8px;
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);
    padding: 10px;
    width: 100%;
    height: 100%;
    font-family: "Segoe UI", Arial, sans-serif;
    color: #333;
    margin: 0;
    overflow: hidden;
    box-sizing: border-box;
    display: flex;
    border: 1px solid #e0e0e0;
}
.widget-visual {
    width: 37%;
    padding-right: 10px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    border-right: 1px solid #eaeaea;
    position: relative;
}
.standard-days {
    position: absolute;
    top: 0;
    left: 0;
    font-size: 11px;
    padding: 2px 5px;
    border-radius: 4px;
    background-color: #f1f5f9;
    color: #64748b;
    display: flex;
    align-items: center;
    gap: 3px;
}
.standard-days-icon {
    font-size: 11px;
    color: #64748b;
}
.widget-content {
    width: 63%;
    padding-left: 10px;
}
.section-title {
    font-size: 10px;
    color: #64748b;
    font-weight: 500;
    margin-bottom: 3px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}
.widget-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 5px;
    margin-bottom: 8px;
}
.stat-block {
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    padding: 5px 5px 5px 5px;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    position: relative;
    cursor: pointer;
    transition: all 0.15s ease;
}
.stat-block:hover {
    background: #f0f7ff;
    border-color: #cce5ff;
}
.stat-label {
    font-size: 10px;
    color: #6c757d;
    margin-bottom: 1px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    width: 100%;
}
.stat-value {
    font-size: 16px;
    font-weight: 600;
    color: #0d6efd;
    line-height: 1;
}
.stat-icon {
    font-size: 10px;
    margin-right: 2px;
    vertical-align: middle;
}
.high-value { color: #198754; }
.medium-value { color: #fd7e14; }
.low-value { color: #dc3545; }

.visual-gauge {
    width: 100px;
    height: 100px;
    position: relative;
    cursor: pointer;
}
.gauge-circle {
    fill: none;
    stroke: #f1f1f1;
    stroke-width: 9;
}
.gauge-progress {
    fill: none;
    stroke-width: 9;
    stroke-linecap: round;
    transform: rotate(-90deg);
    transform-origin: center;
}
.gauge-text {
    font-size: 20px;
    font-weight: bold;
    text-anchor: middle;
    dominant-baseline: middle;
}
.gauge-label {
    font-size: 10px;
    text-anchor: middle;
    dominant-baseline: middle;
    fill: #6c757d;
}
.lock-status {
    position: absolute;
    bottom: 0;
    font-size: 10px;
    padding: 2px 5px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    gap: 3px;
    font-weight: 500;
    cursor: pointer;
}
.locked-status {
    background-color: rgba(239, 68, 68, 0.1);
    color: #ef4444;
}
.unlocked-status {
    background-color: rgba(16, 185, 129, 0.1);
    color: #10b981;
}
.metrics-summary {
    display: flex;
    flex-direction: column;
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    padding: 6px;
    position: relative;
    cursor: pointer;
}
.metrics-summary:hover {
    background: #f0f7ff;
    border-color: #cce5ff;
}
.metrics-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 1px;
    align-items: center;
}
.metrics-row:last-child {
    margin-bottom: 0;
}
.metric-label {
    font-size: 10px;
    color: #6c757d;
    display: flex;
    align-items: center;
    gap: 3px;
}
.metric-value {
    font-size: 13px;
    font-weight: 600;
}
.combined-progress {
    height: 5px;
    background: #e9ecef;
    border-radius: 3px;
    margin: 3px 0;
    overflow: hidden;
    position: relative;
}
.progress-segment {
    height: 100%;
    float: left;
}
.target-marker {
    position: absolute;
    top: -2px;
    height: 9px;
    width: 1px;
    background-color: rgba(0,0,0,0.3);
}
.target-marker:after {
    content: "";
    position: absolute;
    top: 0;
    left: -2px;
    width: 4px;
    height: 4px;
    background-color: rgba(0,0,0,0.3);
    border-radius: 50%;
}
.target-label {
    position: absolute;
    top: -12px;
    transform: translateX(-50%);
    font-size: 7px;
    color: rgba(0,0,0,0.5);
    white-space: nowrap;
}
.info-tooltip {
    font-size: 9px;
    color: #9ca3af;
}

/* CSS-only Tooltip/Popup styling */
.tooltip-container {
    position: relative;
    display: inline-block;
}

.tooltip-content {
    visibility: hidden;
    background-color: white;
    color: #333;
    text-align: left;
    padding: 8px;
    border-radius: 6px;
    border: 1px solid #e9ecef;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    font-size: 11px;
    
    /* Position the tooltip */
    position: absolute;
    z-index: 1;
    bottom: 125%;
    left: 50%;
    margin-left: -85px;
    width: 170px;
    
    /* Fade in tooltip */
    opacity: 0;
    transition: opacity 0.3s;
}

.tooltip-container:hover .tooltip-content {
    visibility: visible;
    opacity: 1;
}

.tooltip-content::after {
    content: "";
    position: absolute;
    top: 100%;
    left: 50%;
    margin-left: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: white transparent transparent transparent;
}

.tooltip-title {
    font-weight: 600;
    padding-bottom: 4px;
    margin-bottom: 4px;
    border-bottom: 1px solid #eaeaea;
    font-size: 12px;
}

.tooltip-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 2px;
}

.tooltip-label {
    color: #6c757d;
}

.tooltip-value {
    font-weight: 500;
}

@media (max-width: 500px) {
    .widget-card { 
        padding: 8px;
        flex-direction: column;
    }
    .widget-visual {
        width: 100%;
        border-right: none;
        border-bottom: 1px solid #eaeaea;
        padding: 0 0 6px 0;
        margin-bottom: 6px;
    }
    .widget-content {
        width: 100%;
        padding-left: 0;
    }
    .widget-stats { 
        gap: 4px; 
        grid-template-columns: repeat(3, 1fr);
        margin-bottom: 6px;
    }
    .stat-block { 
        padding: 4px; 
    }
    .stat-value { 
        font-size: 14px; 
    }
    .stat-label { 
        font-size: 9px;
    }
    .visual-gauge {
        width: 80px;
        height: 80px;
    }
    .gauge-text {
        font-size: 16px;
    }
    .standard-days {
        position: relative;
        margin-top: 4px;
    }
    .lock-status {
        position: relative;
        margin-top: 4px;
    }
    .section-title {
        font-size: 9px;
    }
}
</style>
'

    DECLARE @html NVARCHAR(MAX) = N'
<div class="widget-card">
    <div class="widget-visual">
        <div class="standard-days tooltip-container">
            <span class="standard-days-icon">📆</span>
            <span>{STANDARD_DAYS}</span>
            <div class="tooltip-content">
                <div class="tooltip-title">Thông tin ngày công</div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Ngày chuẩn:</span>
                    <span class="tooltip-value">{STANDARD_DAYS} ngày</span>
                </div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Ngày làm việc:</span>
                    <span class="tooltip-value">{TOTAL_DAYS} ngày</span>
                </div>
            </div>
        </div>
        <div class="visual-gauge tooltip-container">
            <svg width="100%" height="100%" viewBox="0 0 120 120">
                <circle class="gauge-circle" cx="60" cy="60" r="54"></circle>
                <circle class="gauge-progress" cx="60" cy="60" r="54" 
                    stroke="{EFFICIENCY_COLOR}" 
                    stroke-dasharray="339.292" 
                    stroke-dashoffset="{GAUGE_OFFSET}"></circle>
                <text class="gauge-text" x="60" y="55" fill="{EFFICIENCY_COLOR}">{EFFICIENCY}%</text>
                <text class="gauge-label" x="60" y="75">Hiệu suất</text>
            </svg>
            <div class="tooltip-content">
                <div class="tooltip-title">Chi tiết hiệu suất</div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Hiệu suất:</span>
                    <span class="tooltip-value">{EFFICIENCY}%</span>
                </div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Đánh giá:</span>
                    <span class="tooltip-value">{EFFICIENCY_RATING}</span>
                </div>
            </div>
        </div>
        <div class="lock-status {LOCK_STATUS_CLASS} tooltip-container">
            <span>{LOCK_ICON}</span>
            <span>{LOCK_STATUS_TEXT}</span>
            <div class="tooltip-content">
                <div class="tooltip-title">Trạng thái khoá công</div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Trạng thái:</span>
                    <span class="tooltip-value">{LOCK_STATUS_TEXT}</span>
                </div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Kỳ công:</span>
                    <span class="tooltip-value">{PERIOD}</span>
                </div>
            </div>
        </div>
    </div>
    <div class="widget-content">
        <div class="section-title">
            <span>Thống kê chấm công</span>
            <span class="info-tooltip tooltip-container">
                ⓘ
                <div class="tooltip-content">
                    <div class="tooltip-title">Thông tin chung</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Kỳ công:</span>
                        <span class="tooltip-value">{PERIOD}</span>
                    </div>
                </div>
            </span>
        </div>
        <div class="widget-stats">
            <div class="stat-block tooltip-container">
                <span class="stat-label"><span class="stat-icon">👥</span>Nhân viên</span>
                <span class="stat-value">{TOTAL_EMPLOYEES}</span>
                <div class="tooltip-content">
                    <div class="tooltip-title">Thông tin nhân viên</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Tổng nhân viên:</span>
                        <span class="tooltip-value">{TOTAL_EMPLOYEES}</span>
                    </div>
                </div>
            </div>
            <div class="stat-block tooltip-container">
                <span class="stat-label"><span class="stat-icon">📅</span>Ngày làm</span>
                <span class="stat-value">{TOTAL_DAYS}</span>
                <div class="tooltip-content">
                    <div class="tooltip-title">Chi tiết ngày làm việc</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Ngày làm việc:</span>
                        <span class="tooltip-value">{TOTAL_DAYS} ngày</span>
                    </div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Ngày chuẩn:</span>
                        <span class="tooltip-value">{STANDARD_DAYS} ngày</span>
                    </div>
                </div>
            </div>
            <div class="stat-block tooltip-container">
                <span class="stat-label"><span class="stat-icon">⏱️</span>OT</span>
                <span class="stat-value">{OT_HRS}</span>
                <div class="tooltip-content">
                    <div class="tooltip-title">Chi tiết giờ làm thêm</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Tổng giờ OT:</span>
                        <span class="tooltip-value">{OT_HRS} giờ</span>
                    </div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">TB/người:</span>
                        <span class="tooltip-value">{OT_PER_EMPLOYEE} giờ</span>
                    </div>
                </div>
            </div>
            <div class="stat-block tooltip-container">
                <span class="stat-label"><span class="stat-icon">⏰</span>Muộn/về sớm</span>
                <span class="stat-value {LATE_CLASS}">{LATE}</span>
                <div class="tooltip-content">
                    <div class="tooltip-title">Chi tiết muộn/về sớm</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Số ca:</span>
                        <span class="tooltip-value">{LATE} ca</span>
                    </div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Tỷ lệ:</span>
                        <span class="tooltip-value">{LATE_PERCENT}%</span>
                    </div>
                </div>
            </div>
            <div class="stat-block tooltip-container">
                <span class="stat-label"><span class="stat-icon">❌</span>Thiếu công</span>
                <span class="stat-value {ABSENT_CLASS}">{ABSENT}</span>
                <div class="tooltip-content">
                    <div class="tooltip-title">Chi tiết thiếu công</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Số ca:</span>
                        <span class="tooltip-value">{ABSENT} ca</span>
                    </div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Tỷ lệ:</span>
                        <span class="tooltip-value">{ABSENT_PERCENT}%</span>
                    </div>
                </div>
            </div>
            <div class="stat-block tooltip-container">
                <span class="stat-label"><span class="stat-icon">🌟</span>Làm lễ</span>
                <span class="stat-value">{WORK_ON_HOLIDAY}</span>
                <div class="tooltip-content">
                    <div class="tooltip-title">Chi tiết làm lễ</div>
                    <div class="tooltip-row">
                        <span class="tooltip-label">Số ca làm lễ:</span>
                        <span class="tooltip-value">{WORK_ON_HOLIDAY} ca</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="metrics-summary tooltip-container">
            <div class="metrics-row">
                <div class="metric-label">
                    <span>Công đúng:</span>
                </div>
                <div class="metric-value {CORRECT_CLASS}">{CORRECT}/{TOTAL_DAYS}</div>
            </div>
            <div class="combined-progress">
                <div class="progress-segment" style="width:{CORRECT_PERCENT}%; background-color:{CORRECT_COLOR};"></div>
                <div class="progress-segment" style="width:{LATE_PERCENT}%; background-color:#f97316;"></div>
                <div class="progress-segment" style="width:{ABSENT_PERCENT}%; background-color:#ef4444;"></div>
                <div class="target-marker" style="left:98%;"><span class="target-label">98%</span></div>
            </div>
            <div class="metrics-row">
                <div class="metric-label">
                    <span>Tỷ lệ chấm công:</span>
                </div>
                <div class="metric-value {ATTENDANCE_RATE_CLASS}">{ATTENDANCE_RATE}%</div>
            </div>
            <div class="tooltip-content">
                <div class="tooltip-title">Tổng hợp chấm công</div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Công đúng:</span>
                    <span class="tooltip-value">{CORRECT}/{TOTAL_DAYS}</span>
                </div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Muộn/về sớm:</span>
                    <span class="tooltip-value">{LATE} ({LATE_PERCENT}%)</span>
                </div>
                <div class="tooltip-row">
                    <span class="tooltip-label">Thiếu công:</span>
                    <span class="tooltip-value">{ABSENT} ({ABSENT_PERCENT}%)</span>
                </div>
            </div>
        </div>
    </div>
</div>
'

    -- Xử lý điều kiện hiển thị màu sắc dựa trên giá trị
    DECLARE @efficiencyClass NVARCHAR(20) = 'high-value'
    DECLARE @efficiencyColor NVARCHAR(20) = '#22c55e'  -- Green color
    DECLARE @efficiencyRating NVARCHAR(50) = N'Rất tốt'
    DECLARE @lateClass NVARCHAR(20) = 'high-value'
    DECLARE @absentClass NVARCHAR(20) = 'high-value'
    DECLARE @attendanceRateClass NVARCHAR(20) = 'high-value'
    DECLARE @correctClass NVARCHAR(20) = 'high-value'
    DECLARE @correctColor NVARCHAR(20) = '#22c55e' -- Green color
    
    IF @Efficiency < 95 
    BEGIN
        SET @efficiencyClass = 'medium-value'
        SET @efficiencyColor = '#f97316'  -- Orange color
        SET @efficiencyRating = N'Khá'
    END
    IF @Efficiency < 90 
    BEGIN
        SET @efficiencyClass = 'low-value'
        SET @efficiencyColor = '#ef4444'  -- Red color
        SET @efficiencyRating = N'Cần cải thiện'
    END
    
    IF @LateOrEarly > 0 SET @lateClass = 'medium-value'
    IF @LateOrEarly > 5 SET @lateClass = 'low-value'
    
    IF @MissingCheckInOut > 0 SET @absentClass = 'medium-value'
    IF @MissingCheckInOut > 3 SET @absentClass = 'low-value'

    -- Handle edge cases
    DECLARE @CorrectDays INT = @TotalDays - @LateOrEarly - @MissingCheckInOut
    IF @CorrectDays < 0
        SET @CorrectDays = 0
        
    -- Tính toán OT trung bình trên mỗi nhân viên
    DECLARE @OTPerEmployee DECIMAL(5,2) = CASE 
        WHEN @TotalEmployees = 0 THEN 0
        ELSE CAST((@OT_Hrs * 1.0) / @TotalEmployees AS DECIMAL(5,2))
    END
        
    -- Tính toán tỷ lệ công đúng (cho thanh tiến trình)
    DECLARE @CorrectPercent DECIMAL(5,2) = CASE 
        WHEN @TotalDays = 0 THEN 100
        ELSE CAST((@CorrectDays * 100.0) / @TotalDays AS DECIMAL(5,2))
    END
    
    -- Tính toán tỷ lệ muộn/về sớm
    DECLARE @LatePercent DECIMAL(5,2) = CASE 
        WHEN @TotalDays = 0 THEN 0
        ELSE CAST((@LateOrEarly * 100.0) / @TotalDays AS DECIMAL(5,2))
    END
    
    -- Tính toán tỷ lệ thiếu công
    DECLARE @AbsentPercent DECIMAL(5,2) = CASE 
        WHEN @TotalDays = 0 THEN 0
        ELSE CAST((@MissingCheckInOut * 100.0) / @TotalDays AS DECIMAL(5,2))
    END
        
    -- Tính toán tỷ lệ chấm công
    DECLARE @AttendanceRate DECIMAL(5,2) = CASE 
        WHEN @TotalDays = 0 THEN 100
        ELSE CAST((@CorrectDays * 100.0) / @TotalDays AS DECIMAL(5,2))
    END
    
    -- Thiết lập màu sắc cho thanh tỷ lệ chấm công
    IF @AttendanceRate < 95 
    BEGIN
        SET @attendanceRateClass = 'medium-value'
    END
    IF @AttendanceRate < 90 
    BEGIN
        SET @attendanceRateClass = 'low-value'
    END
    
    -- Thiết lập màu sắc cho công đúng
    IF @CorrectPercent < 95 
    BEGIN
        SET @correctClass = 'medium-value'
        SET @correctColor = '#f97316'  -- Orange color
    END
    IF @CorrectPercent < 90 
    BEGIN
        SET @correctClass = 'low-value'
        SET @correctColor = '#ef4444'  -- Red color
    END
        
    -- Tính toán giá trị cho gauge
    DECLARE @GaugeOffset DECIMAL(10,2) = 339.292 * (1 - (@Efficiency / 100))
    
    -- Xác định trạng thái khoá công
    DECLARE @LockStatusClass NVARCHAR(50) = CASE WHEN @IsLocked = 1 THEN 'locked-status' ELSE 'unlocked-status' END
    DECLARE @LockIcon NVARCHAR(20) = CASE WHEN @IsLocked = 1 THEN '🔒' ELSE '🔓' END
    DECLARE @LockStatusText NVARCHAR(50) = CASE WHEN @IsLocked = 1 THEN 'Đã khoá' ELSE 'Chưa khoá' END
        
    -- Thay thế các giá trị động
    SET @html = REPLACE(@html, '{TOTAL_EMPLOYEES}', CAST(@TotalEmployees AS NVARCHAR))
    SET @html = REPLACE(@html, '{TOTAL_DAYS}', CAST(@TotalDays AS NVARCHAR))
    SET @html = REPLACE(@html, '{CORRECT}', CAST(@CorrectDays AS NVARCHAR))
    SET @html = REPLACE(@html, '{CORRECT_PERCENT}', CAST(@CorrectPercent AS NVARCHAR))
    SET @html = REPLACE(@html, '{CORRECT_CLASS}', @correctClass)
    SET @html = REPLACE(@html, '{CORRECT_COLOR}', @correctColor)
    SET @html = REPLACE(@html, '{LATE}', CAST(@LateOrEarly AS NVARCHAR))
    SET @html = REPLACE(@html, '{LATE_PERCENT}', CAST(@LatePercent AS NVARCHAR))
    SET @html = REPLACE(@html, '{ABSENT}', CAST(@MissingCheckInOut AS NVARCHAR))
    SET @html = REPLACE(@html, '{ABSENT_PERCENT}', CAST(@AbsentPercent AS NVARCHAR))
    SET @html = REPLACE(@html, '{EFFICIENCY}', CAST(@Efficiency AS NVARCHAR))
    SET @html = REPLACE(@html, '{EFFICIENCY_RATING}', @efficiencyRating)
    SET @html = REPLACE(@html, '{OT_HRS}', CAST(@OT_Hrs AS NVARCHAR))
    SET @html = REPLACE(@html, '{OT_PER_EMPLOYEE}', CAST(@OTPerEmployee AS NVARCHAR))
    SET @html = REPLACE(@html, '{WORK_ON_HOLIDAY}', CAST(@WorkOnHoliday AS NVARCHAR))
    SET @html = REPLACE(@html, '{EFFICIENCY_CLASS}', @efficiencyClass)
    SET @html = REPLACE(@html, '{EFFICIENCY_COLOR}', @efficiencyColor)
    SET @html = REPLACE(@html, '{LATE_CLASS}', @lateClass)
    SET @html = REPLACE(@html, '{ABSENT_CLASS}', @absentClass)
    SET @html = REPLACE(@html, '{GAUGE_OFFSET}', CAST(@GaugeOffset AS NVARCHAR))
    SET @html = REPLACE(@html, '{LOCK_STATUS_CLASS}', @LockStatusClass)
    SET @html = REPLACE(@html, '{LOCK_ICON}', @LockIcon)
    SET @html = REPLACE(@html, '{LOCK_STATUS_TEXT}', @LockStatusText)
    SET @html = REPLACE(@html, '{STANDARD_DAYS}', CAST(@StandardWorkingDays AS NVARCHAR))
    SET @html = REPLACE(@html, '{ATTENDANCE_RATE}', CAST(@AttendanceRate AS NVARCHAR))
    SET @html = REPLACE(@html, '{ATTENDANCE_RATE_CLASS}', @attendanceRateClass)
    SET @html = REPLACE(@html, '{PERIOD}', @Period)

    -- Return results (JS removed as DOM events not needed)
    SELECT @html AS WidgetHtml, @css AS WidgetCss, '' AS WidgetJs
END