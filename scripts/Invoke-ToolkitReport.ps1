
# Windows IT Automation Toolkit
# Module: Automated Reporting
# Description: Runs diagnostic modules and combines their
# reports into one consolidated IT health report.

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ScriptDirectory = Join-Path $ProjectRoot "scripts"
$ReportDirectory = Join-Path $ProjectRoot "reports"
$LogDirectory = Join-Path $ProjectRoot "logs"

New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ReportPath = Join-Path $ReportDirectory "FullSystemReport_$Timestamp.txt"
$LogPath = Join-Path $LogDirectory "AutomatedReporting.log"

# Define diagnostic modules
$Modules = @(
    @{
        Name = "System Information"
        Script = "Get-SystemInformation.ps1"
        Pattern = "SystemInfo_*.txt"
    },
    @{
        Name = "Disk Monitoring"
        Script = "Get-DiskSpace.ps1"
        Pattern = "DiskReport_*.txt"
    },
    @{
        Name = "Memory Monitoring"
        Script = "Get-MemoryUsage.ps1"
        Pattern = "MemoryReport_*.txt"
    },
    @{
        Name = "Network Diagnostics"
        Script = "Test-NetworkConnectivity.ps1"
        Pattern = "NetworkReport_*.txt"
    },
    @{
        Name = "Windows Maintenance"
        Script = "Test-WindowsMaintenance.ps1"
        Pattern = "MaintenanceReport_*.txt"
    }
)

$Results = @()

Write-Host "Starting automated system reporting..." -ForegroundColor Cyan

foreach ($Module in $Modules) {

    $ScriptPath = Join-Path $ScriptDirectory $Module.Script

    Write-Host "`nRunning $($Module.Name)..." -ForegroundColor Yellow

    $StartTime = Get-Date

    try {
        if (-not (Test-Path $ScriptPath)) {
            throw "Script not found: $ScriptPath"
        }

        # Execute diagnostic module
        & $ScriptPath

        # Find a report generated during this execution
        $GeneratedReport = Get-ChildItem `
            -Path $ReportDirectory `
            -Filter $Module.Pattern `
            -File |
            Where-Object { $_.LastWriteTime -ge $StartTime } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $GeneratedReport) {
            throw "No new report was generated."
        }

        $Results += [PSCustomObject]@{
            Module = $Module.Name
            Status = "SUCCESS"
            Report = $GeneratedReport.Name
            Path = $GeneratedReport.FullName
        }

        Write-Host "$($Module.Name): Report generated." -ForegroundColor Green
    }
    catch {
        $Results += [PSCustomObject]@{
            Module = $Module.Name
            Status = "FAILED"
            Report = $_.Exception.Message
            Path = ""
        }

        Write-Host "$($Module.Name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Calculate execution totals
$SuccessfulModules = @(
    $Results | Where-Object { $_.Status -eq "SUCCESS" }
).Count

$FailedModules = $Results.Count - $SuccessfulModules

# Build consolidated report
$Report = @"
WINDOWS IT AUTOMATION TOOLKIT
CONSOLIDATED SYSTEM HEALTH REPORT
=================================

Computer: $env:COMPUTERNAME
Generated: $(Get-Date)

MODULE EXECUTION SUMMARY
------------------------
"@

$Report += $Results |
    Select-Object Module, Status, Report |
    Format-Table -AutoSize |
    Out-String -Width 200

$Report += "`n`nINDIVIDUAL DIAGNOSTIC REPORTS`n"
$Report += "=================================`n"

foreach ($Result in $Results) {

    $Report += "`nMODULE: $($Result.Module)`n"
    $Report += "---------------------------------`n"

    if ($Result.Status -eq "SUCCESS") {
        try {
            $Report += Get-Content -Path $Result.Path -Raw
            $Report += "`n"
        }
        catch {
            $Report += "Unable to read report: $($_.Exception.Message)`n"
            $FailedModules++
        }
    }
    else {
        $Report += "No report available: $($Result.Report)`n"
    }
}

# Final report summary
$Report += @"

=================================
TOTAL MODULES: $($Results.Count)
SUCCESSFUL: $SuccessfulModules
FAILED: $FailedModules

END OF CONSOLIDATED REPORT
"@

# Save consolidated report
$Report | Out-File -FilePath $ReportPath -Encoding utf8

# Record execution summary
$LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Reporting completed. Successful: $SuccessfulModules; Failed: $FailedModules"

Add-Content -Path $LogPath -Value $LogEntry

# Display execution summary
Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "AUTOMATED REPORTING COMPLETED" -ForegroundColor Green
Write-Host "Successful modules: $SuccessfulModules"
Write-Host "Failed modules: $FailedModules"
Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan

# Return an error if any module failed
if ($FailedModules -gt 0) {
    throw "$FailedModules module(s) failed. Check the consolidated report for details."
}
