
# Windows IT Automation Toolkit
# Module: Memory Monitoring
# Description: Monitors physical memory usage and generates
# a report with warnings when available memory is low.

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportDirectory = Join-Path $ProjectRoot "reports"
$LogDirectory = Join-Path $ProjectRoot "logs"

New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = Join-Path $ReportDirectory "MemoryReport_$Timestamp.txt"
$LogPath = Join-Path $LogDirectory "MemoryMonitoring.log"

# Alert thresholds
$WarningThreshold = 80
$CriticalThreshold = 90

try {
    Write-Host "Collecting memory information..." -ForegroundColor Cyan

    $OS = Get-CimInstance Win32_OperatingSystem

    # Convert memory values from KB to GB
    $TotalRAM = $OS.TotalVisibleMemorySize / 1MB
    $FreeRAM = $OS.FreePhysicalMemory / 1MB
    $UsedRAM = $TotalRAM - $FreeRAM

    # Calculate usage percentage
    $UsagePercentage = [math]::Round(
        ($UsedRAM / $TotalRAM) * 100, 2
    )

    $TotalRAM = [math]::Round($TotalRAM, 2)
    $FreeRAM = [math]::Round($FreeRAM, 2)
    $UsedRAM = [math]::Round($UsedRAM, 2)

    # Determine memory health
    if ($UsagePercentage -ge $CriticalThreshold) {
        $Status = "CRITICAL"
    }
    elseif ($UsagePercentage -ge $WarningThreshold) {
        $Status = "WARNING"
    }
    else {
        $Status = "HEALTHY"
    }

    $Report = @"
WINDOWS MEMORY MONITORING REPORT
================================

Generated: $(Get-Date)

MEMORY DETAILS
--------------
Total Physical RAM: $TotalRAM GB
Used RAM: $UsedRAM GB
Available RAM: $FreeRAM GB
Memory Usage: $UsagePercentage%

THRESHOLDS
----------
Warning Level: $WarningThreshold%
Critical Level: $CriticalThreshold%

MEMORY HEALTH
-------------
Status: $Status

================================
END OF REPORT
"@

    $Report | Out-File -FilePath $ReportPath -Encoding utf8

    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Memory usage: $UsagePercentage% - Status: $Status"

    Add-Content -Path $LogPath -Value $LogMessage

    if ($Status -eq "CRITICAL") {
        Write-Host "CRITICAL: Memory usage is $UsagePercentage%!" -ForegroundColor Red
    }
    elseif ($Status -eq "WARNING") {
        Write-Host "WARNING: Memory usage is $UsagePercentage%." -ForegroundColor Yellow
    }
    else {
        Write-Host "Memory status: HEALTHY ($UsagePercentage%)." -ForegroundColor Green
    }

    Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
}
catch {
    $ErrorMessage = "$(Get-Date): $($_.Exception.Message)"
    Add-Content -Path $LogPath -Value $ErrorMessage
    Write-Host "Memory monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
}
