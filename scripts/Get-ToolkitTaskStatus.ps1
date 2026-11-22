
$TaskName = "Windows IT Automation Toolkit - Daily Report"

$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $Task) {
    Write-Host "Toolkit scheduled task was not found." -ForegroundColor Red
    exit 1
}

$TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName

Write-Host "`nWINDOWS IT AUTOMATION TOOLKIT - TASK STATUS" -ForegroundColor Cyan
Write-Host "-------------------------------------------"

[PSCustomObject]@{
    TaskName       = $Task.TaskName
    State          = $Task.State
    LastRunTime    = $TaskInfo.LastRunTime
    LastTaskResult = $TaskInfo.LastTaskResult
    NextRunTime    = $TaskInfo.NextRunTime
} | Format-List

if ($TaskInfo.LastTaskResult -eq 0) {
    Write-Host "Last execution completed successfully." -ForegroundColor Green
}
else {
    Write-Host "Last execution may have encountered an issue." -ForegroundColor Yellow
}
