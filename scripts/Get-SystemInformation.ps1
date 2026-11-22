
# Windows IT Automation Toolkit
# Module: System Information Collector
# Description: Collects basic Windows system information
# and generates a timestamped report.

$ErrorActionPreference = "Stop"

# Locate the project directory
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportDirectory = Join-Path $ProjectRoot "reports"

# Create reports directory if it does not exist
if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

# Generate timestamp for report filename
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = Join-Path $ReportDirectory "SystemInfo_$Timestamp.txt"

try {
    Write-Host "Collecting system information..." -ForegroundColor Cyan

    # Retrieve system details
    $Computer = Get-CimInstance Win32_ComputerSystem
    $OperatingSystem = Get-CimInstance Win32_OperatingSystem
    $Processor = Get-CimInstance Win32_Processor | Select-Object -First 1
    $BIOS = Get-CimInstance Win32_BIOS

    # Convert memory from bytes to GB
    $TotalRAM = [math]::Round($Computer.TotalPhysicalMemory / 1GB, 2)

    # Calculate system uptime
    $LastBoot = $OperatingSystem.LastBootUpTime
    $Uptime = (Get-Date) - $LastBoot

    # Build report
    $Report = @"
WINDOWS SYSTEM INFORMATION REPORT
=================================

Report Generated: $(Get-Date)

COMPUTER DETAILS
----------------
Computer Name: $($Computer.Name)
Manufacturer: $($Computer.Manufacturer)
Model: $($Computer.Model)

OPERATING SYSTEM
----------------
OS Name: $($OperatingSystem.Caption)
Version: $($OperatingSystem.Version)
Build Number: $($OperatingSystem.BuildNumber)
Architecture: $($OperatingSystem.OSArchitecture)

PROCESSOR
---------
CPU: $($Processor.Name)
Cores: $($Processor.NumberOfCores)
Logical Processors: $($Processor.NumberOfLogicalProcessors)

MEMORY
------
Installed RAM: $TotalRAM GB

BIOS
----
BIOS Manufacturer: $($BIOS.Manufacturer)
BIOS Version: $($BIOS.SMBIOSBIOSVersion)

SYSTEM UPTIME
-------------
Last Boot: $LastBoot
Uptime: $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes

=================================
END OF REPORT
"@

    # Save report
    $Report | Out-File -FilePath $ReportPath -Encoding utf8

    Write-Host "`nSystem information collected successfully!" -ForegroundColor Green
    Write-Host "Report saved to: $ReportPath" -ForegroundColor Yellow
}
catch {
    Write-Host "An error occurred while collecting system information." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    throw
}