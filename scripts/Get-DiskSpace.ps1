
# Windows IT Automation Toolkit
# Module: Disk Space Monitoring
# Description: Checks local drive capacity and identifies
# drives with critically low free space.

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportDirectory = Join-Path $ProjectRoot "reports"
$LogDirectory = Join-Path $ProjectRoot "logs"

# Ensure output directories exist
New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = Join-Path $ReportDirectory "DiskReport_$Timestamp.txt"
$LogPath = Join-Path $LogDirectory "DiskMonitoring.log"

# Threshold for low disk space
$WarningThreshold = 15

try {
    Write-Host "Checking disk space..." -ForegroundColor Cyan

    $Drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"

    $Results = foreach ($Drive in $Drives) {

        $TotalGB = [math]::Round($Drive.Size / 1GB, 2)
        $FreeGB = [math]::Round($Drive.FreeSpace / 1GB, 2)
        $UsedGB = [math]::Round($TotalGB - $FreeGB, 2)

        $FreePercentage = [math]::Round(
            ($Drive.FreeSpace / $Drive.Size) * 100, 2
        )

        if ($FreePercentage -le $WarningThreshold) {
            $Status = "WARNING - LOW DISK SPACE"
        }
        else {
            $Status = "HEALTHY"
        }

        [PSCustomObject]@{
            Drive = $Drive.DeviceID
            Label = $Drive.VolumeName
            TotalGB = $TotalGB
            UsedGB = $UsedGB
            FreeGB = $FreeGB
            FreePercentage = $FreePercentage
            Status = $Status
        }
    }

    $Report = @"
WINDOWS DISK SPACE MONITORING REPORT
====================================
Generated: $(Get-Date)
Warning Threshold: $WarningThreshold% free space

"@

    $Report += $Results | Format-Table -AutoSize | Out-String

    $Report += @"

====================================
END OF REPORT
"@

    $Report | Out-File -FilePath $ReportPath -Encoding utf8

    $Results | ForEach-Object {
        $Message = "$($_.Drive): $($_.FreeGB) GB free ($($_.FreePercentage)% free) - $($_.Status)"
        Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"

        if ($_.Status -like "WARNING*") {
            Write-Warning $Message
        }
        else {
            Write-Host $Message -ForegroundColor Green
        }
    }

    Write-Host "`nDisk report saved to: $ReportPath" -ForegroundColor Cyan
}
catch {
    $ErrorMessage = "$(Get-Date): $($_.Exception.Message)"
    Add-Content -Path $LogPath -Value $ErrorMessage
    Write-Host "Disk monitoring failed: $($_.Exception.Message)" -ForegroundColor Red

    throw
}