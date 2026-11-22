# Windows IT Automation Toolkit — Usage Guide

This guide explains how to execute the toolkit's scripts, interpret their outputs, and manage automated reporting.

## 1. Running Individual Scripts

Open PowerShell in the project root directory.

Run the scripts using their relative paths:

```powershell
.\scripts\Get-SystemInformation.ps1
.\scripts\Get-DiskSpace.ps1
.\scripts\Get-MemoryUsage.ps1
.\scripts\Test-NetworkConnectivity.ps1
.\scripts\Test-WindowsMaintenance.ps1
```

Each script performs its own diagnostic checks and generates its corresponding report.

## 2. Generating a Consolidated Report

To execute all diagnostic modules and collect their results, run:

```powershell
.\scripts\Invoke-ToolkitReport.ps1
```

The toolkit generates a timestamped consolidated report in the `reports` directory.

Check the most recently generated report:

```powershell
Get-ChildItem .\reports\FullSystemReport_*.txt |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
```

## 3. Monitoring Logs

Monitoring and execution logs are stored in the `logs` directory.

List available logs:

```powershell
Get-ChildItem .\logs\
```

Read a log:

```powershell
Get-Content .\logs\DiskMonitoring.log
```

Replace the filename with the relevant log when inspecting another module.

## 4. Scheduling Automated Reports

Register a daily scheduled task:

```powershell
.\scripts\Register-ToolkitTask.ps1 -Time "08:00"
```

Change the time using the 24-hour format.

Check scheduled task information:

```powershell
.\scripts\Get-ToolkitTaskStatus.ps1
```

Run the task manually for testing:

```powershell
Start-ScheduledTask -TaskName "Windows IT Automation Toolkit - Daily Report"
```

Remove the scheduled task:

```powershell
.\scripts\Unregister-ToolkitTask.ps1
```

The removal script requests confirmation before deleting the scheduled task.

## 5. Troubleshooting

### Script execution is blocked

If PowerShell blocks script execution, temporarily change the policy for the current PowerShell process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### A network test fails

Check:
- Network adapter configuration.
- Default gateway availability.
- DNS resolution.
- Firewall restrictions.
- Internet connectivity.

A failed ping does not necessarily mean that all network connectivity is unavailable.

### A scheduled task does not execute

Check:
- Whether the task exists.
- Whether the Windows account is logged in.
- The task's last execution result.
- Whether the reporting script exists at the configured path.
- Task Scheduler history for additional details.

## 6. Important Notes

- Run scripts from the project root unless otherwise specified.
- Reports and logs are generated locally.
- The toolkit performs diagnostic checks and does not automatically repair detected problems.
- Avoid committing generated reports or logs containing personal or sensitive system information to a public repository.