
param(
    [string]$Time = "08:00"
)

$TaskName = "Windows IT Automation Toolkit - Daily Report"

# Validate the time format
try {
    $ScheduleTime = [datetime]::ParseExact(
        $Time,
        "HH:mm",
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}
catch {
    Write-Host "Invalid time format. Use HH:mm, for example 08:00." -ForegroundColor Red
    exit 1
}

# Locate the consolidated reporting script
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportScript = Join-Path $PSScriptRoot "Invoke-ToolkitReport.ps1"

if (-not (Test-Path $ReportScript)) {
    Write-Host "Reporting script not found: $ReportScript" -ForegroundColor Red
    exit 1
}

# Configure the scheduled action
$PowerShell = (Get-Command powershell.exe).Source
$Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ReportScript`""

$Action = New-ScheduledTaskAction `
    -Execute $PowerShell `
    -Argument $Arguments

# Configure a daily trigger
$Trigger = New-ScheduledTaskTrigger -Daily -At $ScheduleTime

# Run under the current Windows account, without storing a password
$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

# Register the task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Description "Runs the Windows IT Automation Toolkit daily." `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Host "Scheduled task registered successfully." -ForegroundColor Green
    Write-Host "Task name: $TaskName"
    Write-Host "Daily execution time: $Time"
    Write-Host "Runs only while your Windows account is logged on."
}
catch {
    Write-Host "Task registration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
