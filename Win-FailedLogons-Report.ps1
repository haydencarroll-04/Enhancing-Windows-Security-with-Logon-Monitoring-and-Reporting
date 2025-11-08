param(
    [int]$LookbackHours = 24,
    [string]$OutDir = 'C:\SecReports'
)

$ErrorActionPreference = 'Stop'

# Ensure output directory exists
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

# Calculate time window
$Since = (Get-Date).AddHours(-$LookbackHours)
$NowStamp = Get-Date -Format 'yyyyMMdd_HHmm'
$ReportPath = Join-Path $OutDir ("FailedLogons_Report_{0}.html" -f $NowStamp)
$LatestPath = Join-Path $OutDir "FailedLogons_Latest.html"

# Map logon type codes to human-readable names
$LogonTypeMap = @{
    '2'  = 'Interactive (Local console)'
    '3'  = 'Network (Remote share / SMB)'
    '4'  = 'Batch'
    '5'  = 'Service'
    '7'  = 'Unlock'
    '8'  = 'NetworkCleartext'
    '9'  = 'NewCredentials (RunAs)'
    '10' = 'RemoteInteractive (RDP)'
    '11' = 'CachedInteractive'
}

function Get-4625Events {
    # Use Get-WinEvent with a server-side filter for best performance
    Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        Id        = 4625
        StartTime = $Since
    } -ErrorAction SilentlyContinue
}

# Extract relevant fields from the XML payload of each event
$events = Get-4625Events | ForEach-Object {
    try {
        $xml = [xml]$_.ToXml()
        $data = @{} 
        foreach ($d in $xml.Event.EventData.Data) {
            $data[$d.Name] = $d.'#text'
        }
        [pscustomobject]@{
            TimeCreated     = $_.TimeCreated
            TargetUserName  = $data['TargetUserName']
            IpAddress       = if ($data['IpAddress']) { $data['IpAddress'] } else { $data['IpAddress'] }
            WorkstationName = $data['WorkstationName']
            LogonType       = $data['LogonType']
            LogonTypeName   = if ($LogonTypeMap.ContainsKey($data['LogonType'])) { $LogonTypeMap[$data['LogonType']] } else { $data['LogonType'] }
            FailureReason   = $data['FailureReason']
            Status          = $data['Status']
            SubStatus       = $data['SubStatus']
            ProcessName     = $data['ProcessName']
            SubjectUser     = $data['SubjectUserName']
        }
    } catch {
        # If parsing fails, still output minimal info
        [pscustomobject]@{
            TimeCreated     = $_.TimeCreated
            TargetUserName  = $null
            IpAddress       = $null
            WorkstationName = $null
            LogonType       = $null
            LogonTypeName   = $null
            FailureReason   = $null
            Status          = $null
            SubStatus       = $null
            ProcessName     = $null
            SubjectUser     = $null
        }
    }
} | Sort-Object TimeCreated -Descending

# Summaries
$CountTotal   = $events.Count
$ByUser       = $events | Where-Object { $_.TargetUserName } | Group-Object TargetUserName | Sort-Object Count -Descending
$ByIP         = $events | Where-Object { $_.IpAddress -and $_.IpAddress -ne '-' } | Group-Object IpAddress | Sort-Object Count -Descending
$ByReason     = $events | Where-Object { $_.FailureReason } | Group-Object FailureReason | Sort-Object Count -Descending
$ByLogonType  = $events | Where-Object { $_.LogonTypeName } | Group-Object LogonTypeName | Sort-Object Count -Descending

# Take top N for readability
$TopN = 10
$TopUsers   = $ByUser   | Select-Object Name, Count -First $TopN
$TopIPs     = $ByIP     | Select-Object Name, Count -First $TopN
$TopReasons = $ByReason | Select-Object Name, Count -First $TopN
$TopTypes   = $ByLogonType | Select-Object Name, Count -First $TopN

# Tabular sections
function TableHtml($data, $title, $properties) {
    if (-not $data -or $data.Count -eq 0) {
        return "<h2>$title</h2><p class='muted'>No data.</p>"
    }
    $frag = $data | Select-Object -Property $properties | ConvertTo-Html -Fragment
    return "<h2>$title</h2>$frag"
}

# Latest detail rows (cap to last 100 to keep page snappy)
$LatestRows = $events | Select-Object -First 100

# Basic style
$Style = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; color: #222; }
h1 { margin: 0 0 4px 0; }
h2 { margin-top: 24px; }
.muted { color: #666; }
.summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin: 12px 0 18px; }
.card { border: 1px solid #ddd; border-radius: 8px; padding: 12px; }
.card h3 { margin: 0 0 6px 0; font-size: 14px; }
.small { font-size: 12px; color: #555; }
table { border-collapse: collapse; width: 100%; margin-top: 8px; }
th, td { border: 1px solid #ddd; padding: 6px 8px; font-size: 12px; vertical-align: top; }
th { background: #f7f7f7; text-align: left; }
footer { margin-top: 24px; font-size: 11px; color: #666; }
.tip { background: #fff7d6; border: 1px solid #f0e1a1; padding: 10px; border-radius: 6px; }
</style>
"@

# Build summary cards
$SummaryHtml = @"
<div class='summary'>
  <div class='card'>
    <h3>Total Failed Logons</h3>
    <div style='font-size:24px;font-weight:bold;'>$CountTotal</div>
    <div class='small'>Lookback: last $LookbackHours hour(s)</div>
  </div>
  <div class='card'>
    <h3>Top Usernames</h3>
    <div class='small'>Top $TopN</div>
    <table><tr><th>User</th><th>Count</th></tr>
"@

foreach ($u in $TopUsers) {
    $SummaryHtml += "<tr><td>$($u.Name)</td><td>$($u.Count)</td></tr>"
}
$SummaryHtml += "</table></div>"

$SummaryHtml += @"
  <div class='card'>
    <h3>Top Source IPs</h3>
    <div class='small'>Top $TopN</div>
    <table><tr><th>Source IP</th><th>Count</th></tr>
"@
foreach ($ip in $TopIPs) {
    $SummaryHtml += "<tr><td>$($ip.Name)</td><td>$($ip.Count)</td></tr>"
}
$SummaryHtml += "</table></div>"

$SummaryHtml += @"
  <div class='card'>
    <h3>Top Failure Reasons</h3>
    <div class='small'>Top $TopN</div>
    <table><tr><th>Reason</th><th>Count</th></tr>
"@
foreach ($r in $TopReasons) {
    # HTML-escape basic chars
    $reasonEsc = [System.Net.WebUtility]::HtmlEncode([string]$r.Name)
    $SummaryHtml += "<tr><td>$reasonEsc</td><td>$($r.Count)</td></tr>"
}
$SummaryHtml += "</table></div></div>"

# Tables
$TopTypesHtml   = TableHtml $TopTypes   "Logon Types Observed" @('Name','Count')
$LatestHtml     = TableHtml $LatestRows "Most Recent Failed Logons (latest 100)" @('TimeCreated','TargetUserName','IpAddress','WorkstationName','LogonTypeName','FailureReason','Status','SubStatus','ProcessName')

# Optional analyst tip
$Tip = @"
<div class='tip'>
<strong>Analyst Tip:</strong> Repeated 4625s from the same IP followed by a 4624 (success) may indicate a successful brute-force. 
Correlate with 4624 around the same timestamps for the same TargetUserName or source IP.
</div>
"@

# Compose full HTML
$Header = "<h1>Failed Logons Report</h1><div class='small'>Generated: $(Get-Date) | Lookback: $LookbackHours hour(s)</div>"
$Body = $Header + $Tip + $SummaryHtml + $TopTypesHtml + $LatestHtml
$HtmlDoc = ConvertTo-Html -Head $Style -Body $Body -Title "Failed Logons Report"

# Write outputs
$HtmlDoc | Out-File -FilePath $ReportPath -Encoding UTF8
# Keep a stable filename for convenience
$HtmlDoc | Out-File -FilePath $LatestPath -Encoding UTF8

Write-Host "Report written to: $ReportPath"
Write-Host "Latest symlink (copy) written to: $LatestPath"

Start-Process $LatestPath

