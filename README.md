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


<img width="320" height="208" alt="Screenshot 2025-11-08 at 3 21 58 PM Medium" src="https://github.com/user-attachments/assets/0136091f-e6a8-4716-990f-b09ff3ea4124" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 55 59 PM Medium" src="https://github.com/user-attachments/assets/7338c69b-4dac-4b4f-a352-cc99a96b7e6d" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 41 11 PM Medium" src="https://github.com/user-attachments/assets/54c1c5cc-881d-4d37-9536-ac3b1cf8c384" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 36 16 PM Medium" src="https://github.com/user-attachments/assets/c956ab99-e505-4e04-9c53-7a4831de423c" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 34 33 PM Medium" src="https://github.com/user-attachments/assets/3756d2b4-d7b6-4596-b574-6523c2270d9a" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 34 09 PM Medium" src="https://github.com/user-attachments/assets/db2d62e5-81cd-4f6e-91f6-13634a347c61" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 32 03 PM Medium" src="https://github.com/user-attachments/assets/e80de54e-f3c1-48d9-b238-f678d835343d" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 29 08 PM Medium" src="https://github.com/user-attachments/assets/11dfd13a-b1f3-47c3-b450-07305db0aa1c" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 28 58 PM Medium" src="https://github.com/user-attachments/assets/a7a7ac51-7d5f-4a57-80d3-bdfb3cdf63e7" />
<img width="640" height="416" alt="Screenshot 2025-11-08 at 2 28 53 PM Medium" src="https://github.com/user-attachments/assets/500a979d-cb04-4b1b-bcfe-8ac533a0f5aa" />
<img width="320" height="208" alt="Screenshot 2025-11-08 at 2 28 41 PM Medium" src="https://github.com/user-attachments/assets/28628d73-e23a-45bc-b369-f56cfc46eb4d" />
