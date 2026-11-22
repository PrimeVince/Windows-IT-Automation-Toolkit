
# Windows IT Automation Toolkit
# Module: Network Diagnostics
# Description: Checks IP configuration, gateway connectivity,
# external connectivity and DNS resolution.

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportDirectory = Join-Path $ProjectRoot "reports"
$LogDirectory = Join-Path $ProjectRoot "logs"

New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = Join-Path $ReportDirectory "NetworkReport_$Timestamp.txt"
$LogPath = Join-Path $LogDirectory "NetworkDiagnostics.log"

$ExternalIP = "1.1.1.1"
$TestDomain = "example.com"

$Results = @()

function Add-DiagnosticResult {
    param(
        [string]$Test,
        [string]$Details,
        [string]$Status
    )

    $script:Results += [PSCustomObject]@{
        Test = $Test
        Details = $Details
        Status = $Status
    }
}

function Write-DiagnosticLog {
    param([string]$Message)

    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogPath -Value $LogEntry
}

try {
    Write-Host "Starting network diagnostics..." -ForegroundColor Cyan

    # 1. Retrieve network configuration
    $Configurations = Get-NetIPConfiguration |
        Where-Object { $_.IPv4Address -and $_.IPv4DefaultGateway }

    if (-not $Configurations) {
        throw "No active IPv4 network configuration with a default gateway was found."
    }

    $Configuration = $Configurations | Select-Object -First 1

    $IP = $Configuration.IPv4Address |
        Select-Object -First 1

    $Gateway = $Configuration.IPv4DefaultGateway.NextHop

    Add-DiagnosticResult `
        -Test "Network Adapter" `
        -Details $Configuration.InterfaceAlias `
        -Status "INFO"

    Add-DiagnosticResult `
        -Test "IPv4 Address" `
        -Details $IP.IPAddress `
        -Status "INFO"

    Add-DiagnosticResult `
        -Test "Subnet Prefix Length" `
        -Details "/$($IP.PrefixLength)" `
        -Status "INFO"

    Add-DiagnosticResult `
        -Test "Default Gateway" `
        -Details $Gateway `
        -Status "INFO"

    # 2. Test gateway connectivity
    $GatewayReachable = Test-Connection `
        -ComputerName $Gateway `
        -Count 2 `
        -Quiet `
        -ErrorAction SilentlyContinue

    if ($GatewayReachable) {
        Add-DiagnosticResult "Gateway Connectivity" "Gateway responded to ping" "PASS"
    }
    else {
        Add-DiagnosticResult "Gateway Connectivity" "Gateway did not respond to ping" "WARNING"
    }

    # 3. Test external connectivity using TCP port 443
    $InternetReachable = Test-NetConnection `
        -ComputerName $ExternalIP `
        -Port 443 `
        -InformationLevel Quiet `
        -WarningAction SilentlyContinue

    if ($InternetReachable) {
        Add-DiagnosticResult "External Connectivity" "TCP connection to $ExternalIP on port 443 succeeded" "PASS"
    }
    else {
        Add-DiagnosticResult "External Connectivity" "TCP connection to $ExternalIP on port 443 failed" "FAIL"
    }

    # 4. Test DNS resolution
    try {
        $DNSResult = Resolve-DnsName `
            -Name $TestDomain `
            -Type A `
            -ErrorAction Stop |
            Select-Object -First 1

        Add-DiagnosticResult `
            "DNS Resolution" `
            "$TestDomain resolved to $($DNSResult.IPAddress)" `
            "PASS"
    }
    catch {
        Add-DiagnosticResult `
            "DNS Resolution" `
            "Could not resolve $TestDomain" `
            "FAIL"
    }

    # 5. Generate report
    $Report = @"
WINDOWS NETWORK DIAGNOSTICS REPORT
==================================

Computer: $env:COMPUTERNAME
Generated: $(Get-Date)

NETWORK TEST RESULTS
--------------------
"@

    $Report += $Results | Format-Table -AutoSize | Out-String

    $Report += @"

==================================
END OF REPORT
"@

    $Report | Out-File -FilePath $ReportPath -Encoding utf8

    # 6. Log diagnostic results
    foreach ($Result in $Results) {
        Write-DiagnosticLog "$($Result.Test): $($Result.Details) [$($Result.Status)]"
    }

    Write-Host "`nNetwork diagnostics completed." -ForegroundColor Green
    $Results | Format-Table -AutoSize

    Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
}
catch {
    Write-DiagnosticLog "ERROR: $($_.Exception.Message)"

    Write-Host "Network diagnostics failed: $($_.Exception.Message)" -ForegroundColor Red

    throw
}
