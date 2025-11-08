# Generate some events
Start-Process -FilePath "cmd.exe" -ArgumentList "/c whoami"
powershell -NoProfile -Command "Get-Date | Out-Null; 'hello from PS' | Out-Null"

# Show the latest 4625/4624/4688
"--- Security 4625 (failed logon):"
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 3 | Format-Table TimeCreated, Id, RecordId -Auto

"--- Security 4624 (successful logon):"
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 3 | Format-Table TimeCreated, Id, RecordId -Auto

"--- Security 4688 (process creation):"
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 5 |
  ForEach-Object {
    $xml = [xml]$_.ToXml()
    [pscustomobject]@{
      Time = $_.TimeCreated
      Proc = ($xml.Event.EventData.Data | ? Name -eq 'NewProcessName').'#text'
      Cmd  = ($xml.Event.EventData.Data | ? Name -eq 'CommandLine').'#text'
    }
  } | Format-Table -Auto

"--- PowerShell Operational (latest):"
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-PowerShell/Operational'} -MaxEvents 5 |
  Select-Object TimeCreated, Id, Message | Format-List
