# Enhancing-Windows-Security-with-Logon-Monitoring-and-Reporting

This is a PowerShell utility that parses Windows Security logs for failed logon attempts (Event ID 4625) and generates a clean HTML report with summaries (top usernames, source IPs, failure reasons, logon types) and a recent-events table. This is useful to quickly spot brute-force attempts, password spraying, and misconfigurations by turning noisy 4625 events into easy-access data. This script is compatible with PowerShell 5.1 and 7+

---

## Requirements
For this to work, you must have:
- Windows (Pro/Enterprise/Education recommended)
- Audit policies enabled for Logon (Failure) 
- Permissions to read Security logs (run as Administrator)

---

## Setup
Enable:
- Security Policy -> Audit Process Creation → Success
- Security Policy -> Audit Logon → Success & Failure
- Edit Group Policy -> PowerShell: Module Logging, Script Block Logging, Transcription

See screenshots for examples.

---

## Usage

**1) Run once and open the report**
```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File ".\Win-FailedLogons-Report.ps1" -LookbackHours 24 -OutDir "C:\SecReports"

# Open latest
Start-Process "C:\SecReports\FailedLogons_Latest.html"
