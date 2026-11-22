
# Windows IT Automation Toolkit
# Module: Windows Maintenance Checks
# Description: Checks important Windows services, Defender,
# system drive capacity and pending restart indicators.

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportDirectory = Join-Path $ProjectRoot "reports"
$LogDirectory = Join-Path $ProjectRoot "logs"

New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = Join-Path $ReportDirectory "MaintenanceReport_$Timestamp.txt"
$LogPath = Join-Path $LogDirectory "WindowsMaintenance.log"

$Results = @()

function Add-Check {
    param(
        [string]$Check,
        [string]$Details,
        [string]$Status
    )

    $script:Results += [PSCustomObject]@{
        Check = $Check
        Details = $Details
        Status = $Status
    }
}

try {
    Write-Host "Starting Windows maintenance checks..." -ForegroundColor Cyan

    # 1. Check Windows Update service
    foreach ($ServiceName in @("wuauserv", "BITS")) {
        try {
            $Service = Get-Service -Name $ServiceName -ErrorAction Stop

            if ($Service.Status -eq "Running") {
                Add-Check $ServiceName "Service is running" "PASS"
            }
            else {
                Add-Check $ServiceName "Service is $($Service.Status)" "INFO"
            }
        }
        catch {
            Add-Check $ServiceName "Service could not be inspected: $($_.Exception.Message)" "REVIEW"
        }
    }

    # 2. Check Microsoft Defender
    try {
        $Defender = Get-MpComputerStatus -ErrorAction Stop

        if ($Defender.RealTimeProtectionEnabled) {
            Add-Check "Defender Real-Time Protection" "Protection is enabled" "PASS"
        }
        else {
            Add-Check "Defender Real-Time Protection" "Protection is disabled" "WARNING"
        }

        if ($Defender.AntivirusEnabled) {
            Add-Check "Defender Antivirus" "Antivirus is enabled" "PASS"
        }
        else {
            Add-Check "Defender Antivirus" "Antivirus is disabled or inactive" "WARNING"
        }
    }
    catch {
        Add-Check "Microsoft Defender" "Status unavailable: $($_.Exception.Message)" "REVIEW"
    }

    # 3. Check system drive capacity
    try {
        $SystemDrive = $env:SystemDrive

        $Disk = Get-CimInstance Win32_LogicalDisk `
            -Filter "DeviceID='$SystemDrive'" `
            -ErrorAction Stop

        if (-not $Disk -or $Disk.Size -le 0) {
            throw "System drive capacity could not be retrieved."
        }

        $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
        $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
        $FreePercentage = [math]::Round(
            ($Disk.FreeSpace / $Disk.Size) * 100, 2
        )

        if ($FreePercentage -le 10) {
            $DiskStatus = "WARNING"
        }
        else {
            $DiskStatus = "PASS"
        }

        $DiskDetails = "$SystemDrive Free: $FreeGB GB of $TotalGB GB ($FreePercentage% available)"

        Add-Check "System Drive Capacity" $DiskDetails $DiskStatus
    }
    catch {
        Add-Check "System Drive Capacity" $_.Exception.Message "REVIEW"
    }

    # 4. Check common pending restart indicators
    $RestartLocations = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )

    $RestartRequired = $false

    foreach ($Location in $RestartLocations) {
        if (Test-Path $Location) {
            $RestartRequired = $true
        }
    }

    # Check for pending file rename operations
    try {
        $RenameOperations = Get-ItemProperty `
            -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
            -Name PendingFileRenameOperations `
            -ErrorAction SilentlyContinue

        if ($RenameOperations.PendingFileRenameOperations) {
            $RestartRequired = $true
        }
    }
    catch {
        # Registry value may not exist.
    }

    if ($RestartRequired) {
        Add-Check "Pending Restart" "A restart indicator was detected" "WARNING"
    }
    else {
        Add-Check "Pending Restart" "No common pending restart indicators detected" "PASS"
    }

    # 5. Generate report
    $Report = @"
WINDOWS MAINTENANCE CHECK REPORT
================================

Computer: $env:COMPUTERNAME
Generated: $(Get-Date)

MAINTENANCE RESULTS
------------------
"@

    $Report += $Results | Format-Table -AutoSize | Out-String

    $Report += @"

================================
END OF REPORT
"@

    $Report | Out-File -FilePath $ReportPath -Encoding utf8

    # 6. Log results
    foreach ($Result in $Results) {
        $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($Result.Check): $($Result.Details) [$($Result.Status)]"
        Add-Content -Path $LogPath -Value $LogEntry
    }

    Write-Host "`nMaintenance checks completed." -ForegroundColor Green

    $Results | Format-Table -AutoSize

    Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
}
catch {
    $ErrorMessage = "$(Get-Date): $($_.Exception.Message)"
    Add-Content -Path $LogPath -Value $ErrorMessage

    Write-Host "Maintenance checks failed: $($_.Exception.Message)" -ForegroundColor Red

    throw
}
