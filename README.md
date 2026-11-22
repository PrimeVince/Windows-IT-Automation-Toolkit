# Windows IT Automation Toolkit

A PowerShell-based toolkit for automating common Windows IT support, system monitoring, network diagnostics, maintenance checks, and reporting tasks.

## Project Overview

The Windows IT Automation Toolkit brings together practical scripts that help IT technicians collect system information, monitor resources, diagnose connectivity, check maintenance indicators, and generate consolidated reports.

It also supports automated daily reporting through Windows Task Scheduler.

## Features

### 1. System Information
- Retrieves computer and operating system information.
- Collects processor and memory details.
- Retrieves BIOS information and system uptime.
- Saves results to a timestamped report.

### 2. Disk Space Monitoring
- Detects local fixed drives.
- Calculates total, used, and available disk space.
- Identifies drives with critically low free space.
- Records monitoring results in a log.

### 3. Memory Monitoring
- Calculates physical memory usage.
- Converts memory measurements into GB.
- Identifies high and critical memory usage.
- Generates reports and monitoring logs.

### 4. Network Diagnostics
- Retrieves network adapter configuration.
- Tests connectivity to the default gateway.
- Tests external TCP connectivity.
- Performs DNS resolution checks.
- Generates a diagnostic report.

### 5. Windows Maintenance Checks
- Checks Windows Update and Background Intelligent Transfer Service (BITS).
- Checks Microsoft Defender status where available.
- Checks system drive free space.
- Checks common Windows registry indicators for a pending restart.

### 6. Automated Reporting
- Executes the toolkit's diagnostic scripts.
- Collects their latest reports.
- Generates a consolidated system report.
- Records execution results.

### 7. Task Scheduler Integration
- Registers a daily automated reporting task.
- Checks scheduled task status and execution history.
- Supports safe removal of the scheduled task.

## Project Structure

```text
Windows-IT-Automation-Toolkit/
│
├── scripts/
│   ├── Get-SystemInformation.ps1
│   ├── Get-DiskSpace.ps1
│   ├── Get-MemoryUsage.ps1
│   ├── Test-NetworkConnectivity.ps1
│   ├── Test-WindowsMaintenance.ps1
│   ├── Invoke-ToolkitReport.ps1
│   ├── Register-ToolkitTask.ps1
│   ├── Get-ToolkitTaskStatus.ps1
│   └── Unregister-ToolkitTask.ps1
│
├── reports/
├── logs/
├── docs/
└── README.md
```

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 or later.
- Appropriate permissions to run PowerShell scripts.
- Internet connectivity for external network and DNS tests.

Some Windows maintenance information may require additional permissions or Microsoft Defender availability.

## Getting Started

Clone the repository:

```powershell
git clone https://github.com/PrimeVince/Windows-IT-Automation-Toolkit.git
```

Navigate into the project:

```powershell
cd Windows-IT-Automation-Toolkit
```

If your execution policy prevents script execution, you can temporarily allow scripts in the current PowerShell process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Run an individual diagnostic:

```powershell
.\scripts\Get-SystemInformation.ps1
```

Generate a consolidated report:

```powershell
.\scripts\Invoke-ToolkitReport.ps1
```

## Automated Daily Reporting

Register a daily scheduled task:

```powershell
.\scripts\Register-ToolkitTask.ps1 -Time "08:00"
```

Check the task:

```powershell
.\scripts\Get-ToolkitTaskStatus.ps1
```

Remove the task:

```powershell
.\scripts\Unregister-ToolkitTask.ps1
```

The scheduled task runs under the current Windows account and requires that account to be logged in.

## Reports and Logs

Generated reports are saved in the `reports/` directory.

Execution and monitoring logs are saved in the `logs/` directory.

Timestamped filenames help distinguish individual executions and preserve report history.

## Testing

Each module was executed and tested during development.

Testing included:

- System information collection.
- Disk and memory calculations.
- Network connectivity and DNS checks.
- Windows maintenance checks.
- Consolidated report generation.
- Scheduled task registration and execution.
- Scheduled task status verification and removal cancellation.

## Limitations

- This toolkit primarily performs diagnostic checks; it does not automatically repair detected problems.
- Network tests depend on external connectivity and may be affected by firewalls or blocked protocols.
- Defender checks may not provide meaningful results when another antivirus product is installed.
- Pending restart detection checks common registry indicators and is not exhaustive.
- Scheduled reporting requires the configured Windows account to be logged in.

## Technologies

- PowerShell
- Windows Management Instrumentation (WMI/CIM)
- Windows Task Scheduler
- Windows networking utilities
- Git and GitHub

## Purpose

This project demonstrates practical Windows administration, IT support automation, system monitoring, troubleshooting, PowerShell scripting, and task scheduling.

Built as a hands-on IT automation portfolio project.# Windows-IT-Automation-Toolkit
PowerShell toolkit for Windows system monitoring, IT diagnostics and automated reporting.
