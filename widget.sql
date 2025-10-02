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
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    padding: 12px;
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
    width: 35%;
    padding-right: 12px;
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
    font-size: 12px;
    padding: 4px 8px;
    border-radius: 4px;
    background-color: #f1f5f9;
    color: #64748b;
    display: flex;
    align-items: center;
    gap: 4px;
}
.standard-days-icon {
    font-size: 12px;
    color: #64748b;
}
.widget-content {
    width: 65%;
    padding-left: 12px;
}
.widget-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    margin-bottom: 8px;
}
.stat-block {
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    padding: 8px;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    transition: all 0.2s ease;
}
.stat-block:hover {
    background: #f0f7ff;
    border-color: #cce5ff;
    transform: translateY(-1px);
}
.stat-label {
    font-size: 11px;
    color: #6c757d;
    margin-bottom: 2px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    width: 100%;
}
.stat-value {
    font-size: 16px;
    font-weight: 600;
    color: #0d6efd;
}
.stat-icon {
    font-size: 12px;
    margin-right: 3px;
    vertical-align: middle;
}
.high-value { color: #198754; }
.medium-value { color: #fd7e14; }
.low-value { color: #dc3545; }

.visual-gauge {
    width: 120px;
    height: 120px;
    position: relative;
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
    transition: stroke-dashoffset 0.8s ease;
    filter: drop-shadow(0 0 2px rgba(0,0,0,0.1));
}
.gauge-text {
    font-size: 20px;
    font-weight: bold;
    text-anchor: middle;
    dominant-baseline: middle;
}
.gauge-label {
    font-size: 12px;
    text-anchor: middle;
    dominant-baseline: middle;
    fill: #6c757d;
}
.lock-status {
    position: absolute;
    bottom: 0;
    font-size: 13px;
    padding: 4px 8px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    gap: 4px;
    font-weight: 500;
}
.locked-status {
    background-color: rgba(239, 68, 68, 0.1);
    color: #ef4444;
}
.unlocked-status {
    background-color: rgba(16, 185, 129, 0.1);
    color: #10b981;
}
.key-metrics {
    display: flex;
    gap: 8px;
    align-items: center;
}
.key-metric-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 6px 8px;
    background: #f8f9fa;
    border-radius: 6px;
    flex: 1;
}
.key-metric-value {
    font-size: 16px;
    font-weight: 600;
}
.key-metric-label {
    font-size: 10px;
    color: #6c757d;
}

@media (max-width: 500px) {
    .widget-card { 
        padding: 10px;
        flex-direction: column;
    }
    .widget-visual {
        width: 100%;
        border-right: none;
        border-bottom: 1px solid #eaeaea;
        padding: 0 0 10px 0;
        margin-bottom: 10px;
    }
    .widget-content {
        width: 100%;
        padding-left: 0;
    }
    .widget-stats { 
        gap: 6px; 
        grid-template-columns: repeat(2, 1fr);
    }
    .stat-block { padding: 6px; }
    .stat-value { font-size: 14px; }
    .stat-label { font-size: 10px; }
    .visual-gauge {
        width: 90px;
        height: 90px;
    }
    .standard-days {
        position: relative;
        margin-top: 8px;
    }
    .lock-status {
        position: relative;
        margin-top: 8px;
    }
}
</style>
'

    DECLARE @html NVARCHAR(MAX) = N'
<div class="widget-card">
    <div class="widget-visual">
        <div class="standard-days">
            <span class="standard-days-icon">📆</span>
            <span>{STANDARD_DAYS}</span>
        </div>
        <div class="visual-gauge">
            <svg width="100%" height="100%" viewBox="0 0 120 120">
                <circle class="gauge-circle" cx="60" cy="60" r="54"></circle>
                <circle class="gauge-progress" cx="60" cy="60" r="54" 
                    stroke="{EFFICIENCY_COLOR}" 
                    stroke-dasharray="339.292" 
                    stroke-dashoffset="{GAUGE_OFFSET}"></circle>
                <text class="gauge-text" x="60" y="55" fill="{EFFICIENCY_COLOR}">{EFFICIENCY}%</text>
                <text class="gauge-label" x="60" y="75">Hiệu suất</text>
            </svg>
        </div>
        <div class="lock-status {LOCK_STATUS_CLASS}">
            <span>{LOCK_ICON}</span>
            <span>{LOCK_STATUS_TEXT}</span>
        </div>
    </div>
    <div class="widget-content">
        <div class="widget-stats">
            <div class="stat-block">
                <span class="stat-label"><span class="stat-icon">👥</span>Nhân viên</span>
                <span class="stat-value">{TOTAL_EMPLOYEES}</span>
            </div>
            <div class="stat-block">
                <span class="stat-label"><span class="stat-icon">📅</span>Ngày làm</span>
                <span class="stat-value">{TOTAL_DAYS}</span>
            </div>
            <div class="stat-block">
                <span class="stat-label"><span class="stat-icon">⏱️</span>OT giờ</span>
                <span class="stat-value">{OT_HRS}</span>
            </div>
            <div class="stat-block">
                <span class="stat-label"><span class="stat-icon">⏰</span>Muộn/về sớm</span>
                <span class="stat-value {LATE_CLASS}">{LATE}</span>
            </div>
            <div class="stat-block">
                <span class="stat-label"><span class="stat-icon">❌</span>Thiếu công</span>
                <span class="stat-value {ABSENT_CLASS}">{ABSENT}</span>
            </div>
            <div class="stat-block">
                <span class="stat-label"><span class="stat-icon">🌟</span>Làm lễ</span>
                <span class="stat-value">{WORK_ON_HOLIDAY}</span>
            </div>
        </div>
        <div class="key-metrics">
            <div class="key-metric-item">
                <span class="key-metric-value">{CORRECT}</span>
                <span class="key-metric-label">Công đúng</span>
            </div>
            <div class="key-metric-item">
                <span class="key-metric-value">{ATTENDANCE_RATE}%</span>
                <span class="key-metric-label">Tỷ lệ chấm công</span>
            </div>
        </div>
    </div>
</div>
'

    DECLARE @js NVARCHAR(MAX) = N'
<script>
document.addEventListener("DOMContentLoaded", function() {
    const gaugeProgress = document.querySelector(".gauge-progress");
    if (gaugeProgress) {
        setTimeout(() => {
            gaugeProgress.style.transition = "stroke-dashoffset 1.2s ease-in-out";
            gaugeProgress.style.strokeDashoffset = "{GAUGE_OFFSET}";
        }, 200);
    }
});
</script>
'

    -- Xử lý điều kiện hiển thị màu sắc dựa trên giá trị
    DECLARE @efficiencyClass NVARCHAR(20) = 'high-value'
    DECLARE @efficiencyColor NVARCHAR(20) = '#198754'  -- Bootstrap success color
    DECLARE @lateClass NVARCHAR(20) = 'high-value'
    DECLARE @absentClass NVARCHAR(20) = 'high-value'
    
    IF @Efficiency < 95 
    BEGIN
        SET @efficiencyClass = 'medium-value'
        SET @efficiencyColor = '#fd7e14'  -- Bootstrap warning color
    END
    IF @Efficiency < 90 
    BEGIN
        SET @efficiencyClass = 'low-value'
        SET @efficiencyColor = '#dc3545'  -- Bootstrap danger color
    END
    
    IF @LateOrEarly > 0 SET @lateClass = 'medium-value'
    IF @LateOrEarly > 5 SET @lateClass = 'low-value'
    
    IF @MissingCheckInOut > 0 SET @absentClass = 'medium-value'
    IF @MissingCheckInOut > 3 SET @absentClass = 'low-value'

    -- Handle edge cases
    DECLARE @CorrectDays INT = @TotalDays - @LateOrEarly - @MissingCheckInOut
    IF @CorrectDays < 0
        SET @CorrectDays = 0
        
    -- Tính toán tỷ lệ chấm công
    DECLARE @AttendanceRate DECIMAL(5,2) = CASE 
        WHEN @TotalDays = 0 THEN 100
        ELSE CAST((@CorrectDays * 100.0) / @TotalDays AS DECIMAL(5,2))
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
    SET @html = REPLACE(@html, '{LATE}', CAST(@LateOrEarly AS NVARCHAR))
    SET @html = REPLACE(@html, '{ABSENT}', CAST(@MissingCheckInOut AS NVARCHAR))
    SET @html = REPLACE(@html, '{EFFICIENCY}', CAST(@Efficiency AS NVARCHAR))
    SET @html = REPLACE(@html, '{OT_HRS}', CAST(@OT_Hrs AS NVARCHAR))
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
    SET @js = REPLACE(@js, '{GAUGE_OFFSET}', CAST(@GaugeOffset AS NVARCHAR))

    -- Return results
    SELECT @html AS WidgetHtml, @css AS WidgetCss, @js AS WidgetJs
END