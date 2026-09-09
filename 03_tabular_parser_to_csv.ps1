<#
  TABULAR PARSER — reads .xel files from ProdFESE_Monitor session,
  correlates QueryEnd + VertiPaqSEQueryEnd via ActivityID,
  computes FE/SE breakdown, writes ONE CSV PER DAY (grouped by event date)
  into $OutputDir. No DB insert.

  File naming: tabular_fese_log_yyyy-MM-dd.csv
  If the file for that date already exists (e.g. from an earlier run the
  same day), new rows are appended to it. A new date automatically starts
  a new file.

  Requires Microsoft.SqlServer.XEvent.Linq.dll — adjust $XeventDllPath.
#>

param(
    [string]$XelPath        = "D:\OLAP\Log\ProdFESE_Monitor*.xel",
    [string]$OutputDir      = "D:\OLAP\Log\Output",
    [string]$StateFile      = "D:\OLAP\Log\Output\_tabular_lastrun.txt",
    [string]$XeventDllPath  = "C:\Program Files (x86)\Microsoft SQL Server\160\Shared\Microsoft.SqlServer.XEvent.Linq.dll"
)

Add-Type -Path $XeventDllPath

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$lastRun = if (Test-Path $StateFile) { [datetime](Get-Content $StateFile -Raw) } else { [datetime]"2000-01-01" }
$maxTimestampSeen = $lastRun

Write-Host "Reading events after $lastRun ..."

$events = New-Object Microsoft.SqlServer.XEvent.Linq.QueryableXEventData($XelPath)

$queryEnds   = @{}   # ActivityID -> query info
$seDurations = @{}   # ActivityID -> summed SE duration
$seCounts    = @{}   # ActivityID -> count of SE queries

foreach ($e in $events) {

    if ($e.Timestamp -le $lastRun) { continue }
    if ($e.Timestamp -gt $maxTimestampSeen) { $maxTimestampSeen = $e.Timestamp }

    switch ($e.Name) {

        "QueryEnd" {
            $activityId = $null
            try { $activityId = $e.Fields["ActivityID"].Value } catch {}
            if (-not $activityId) { continue }

            $dbName = $null; try { $dbName = $e.Fields["DatabaseName"].Value } catch {}
            $dur    = 0;    try { $dur = $e.Fields["Duration"].Value } catch {}
            $cpu    = 0;    try { $cpu = $e.Fields["CpuTime"].Value } catch {}
            $user   = $null; try { $user = $e.Fields["NTUserName"].Value } catch {}
            $text   = $null; try { $text = $e.Fields["TextData"].Value } catch {}

            $queryEnds[[string]$activityId] = [PSCustomObject]@{
                ActivityID = $activityId
                Database   = $dbName
                EventTime  = $e.Timestamp
                TotalMs    = $dur
                CpuMs      = $cpu
                UserName   = $user
                QueryText  = $text
            }
        }

        "VertiPaqSEQueryEnd" {
            $activityId = $null
            try { $activityId = $e.Fields["ActivityID"].Value } catch {}
            if (-not $activityId) { continue }

            $dur = 0; try { $dur = $e.Fields["Duration"].Value } catch {}
            $key = [string]$activityId

            if (-not $seDurations.ContainsKey($key)) { $seDurations[$key] = 0; $seCounts[$key] = 0 }
            $seDurations[$key] += $dur
            $seCounts[$key]    += 1
        }
    }
}

# Build final rows
$results = foreach ($key in $queryEnds.Keys) {
    $q  = $queryEnds[$key]
    $se = if ($seDurations.ContainsKey($key)) { $seDurations[$key] } else { 0 }
    $seCnt = if ($seCounts.ContainsKey($key)) { $seCounts[$key] } else { 0 }
    $fe = $q.TotalMs - $se
    if ($fe -lt 0) { $fe = 0 }

    [PSCustomObject]@{
        ActivityID  = $q.ActivityID
        Database    = $q.Database
        EventDate   = $q.EventTime.ToString("yyyy-MM-dd")   # used for grouping into daily file
        EventTime   = $q.EventTime.ToString("o")
        TotalMs     = $q.TotalMs
        CpuMs       = $q.CpuMs
        SEms        = $se
        FEms        = $fe
        SERatioPct  = if ($q.TotalMs -gt 0) { [math]::Round(($se / $q.TotalMs) * 100, 1) } else { 0 }
        SEQueryCount= $seCnt
        UserName    = $q.UserName
        QueryText   = $q.QueryText
    }
}

if ($results.Count -eq 0) {
    Write-Host "No new events found since last run."
} else {
    # Group by event date, write/append one CSV per day
    $grouped = $results | Group-Object EventDate

    foreach ($grp in $grouped) {
        $dateStr    = $grp.Name
        $dailyCsv   = Join-Path $OutputDir "tabular_fese_log_$dateStr.csv"
        $writeHeader = -not (Test-Path $dailyCsv)

        # drop the helper EventDate column before writing, it's not needed in the file itself
        $rows = $grp.Group | Select-Object * -ExcludeProperty EventDate

        $rows | Export-Csv -Path $dailyCsv -NoTypeInformation -Append:(!$writeHeader) -Force
        Write-Host "Wrote $($rows.Count) rows to $dailyCsv"
    }
}

$maxTimestampSeen.ToString("o") | Set-Content -Path $StateFile

Write-Host "Done. Last processed timestamp: $($maxTimestampSeen.ToString('o'))"
