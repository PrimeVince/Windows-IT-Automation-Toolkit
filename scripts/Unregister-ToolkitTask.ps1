
$TaskName = "Windows IT Automation Toolkit - Daily Report"

$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $Task) {
    Write-Host "Toolkit scheduled task was not found." -ForegroundColor Yellow
    exit 0
}

$Confirmation = Read-Host "Are you sure you want to remove the scheduled task? (Y/N)"

if ($Confirmation -match '^(Y|YES)$') {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop

        Write-Host "Scheduled task removed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove scheduled task: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Task removal cancelled." -ForegroundColor Cyan
}
