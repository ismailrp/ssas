<#
  MULTIDIMENSIONAL PARSER — reads .xel files from ProdMD_Monitor session,
  correlates QueryBegin/QueryEnd with QuerySubcube*, GetDataFrom*,
  CalculateNonEmpty*, SerializeResults* events using ConnectionID + SPID +
  timestamp window (no ActivityID exists on this engine).
  Writes ONE CSV PER DAY (grouped by event date) into $OutputDir. No DB insert.

  File naming: md_query_log_yyyy-MM-dd.csv
  If the file for that date already exists (earlier run same day), new
  rows are appended. A new date automatically starts a new file.

  CAVEAT: correlation assumes no overlapping concurrent queries on the
  same ConnectionID+SPID. Fine for typical Excel/Power BI/SSRS traffic;
  treat sub-event counts as indicative under heavy concurrency.

  Requires Microsoft.SqlServer.XEvent.Linq.dll — adjust $XeventDllPath.
#>

param(
    [string]$XelPath        = "D:\OLAP\Log\ProdMD_Monitor*.xel",
    [string]$OutputDir      = "D:\OLAP\Log\Output",
    [string]$StateFile      = "D:\OLAP\Log\Output\_md_lastrun.txt",
    [string]$XeventDllPath  = "C:\Program Files (x86)\Microsoft SQL Server\160\Shared\Microsoft.SqlServer.XEvent.Linq.dll"
)

Add-Type -Path $XeventDllPath

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$lastRun = if (Test-Path $StateFile) { [datetime](Get-Content $StateFile -Raw) } else { [datetime]"2000-01-01" }
$maxTimestampSeen = $lastRun

Write-Host "Reading events after $lastRun ..."

$events = New-Object Microsoft.SqlServer.XEvent.Linq.QueryableXEventData($XelPath)

$byConn = @{}   # "connId_spid" -> List of events

function Get-Field($e, $name) {
    try { return $e.Fields[$name].Value } catch { return $null }
}

foreach ($e in $events) {
    if ($e.Timestamp -le $lastRun) { continue }
    if ($e.Timestamp -gt $maxTimestampSeen) { $maxTimestampSeen = $e.Timestamp }

    $connId = Get-Field $e "ConnectionID"
    $spid   = Get-Field $e "SPID"
    $key    = "$connId`_$spid"

    if (-not $byConn.ContainsKey($key)) { $byConn[$key] = New-Object System.Collections.Generic.List[Object] }

    $byConn[$key].Add([PSCustomObject]@{
        Name          = $e.Name
        Timestamp     = $e.Timestamp
        Duration      = Get-Field $e "Duration"
        DbName        = Get-Field $e "DatabaseName"
        UserName      = Get-Field $e "NTUserName"
        TextData      = Get-Field $e "TextData"
        EventSubclass = Get-Field $e "EventSubclass"
    })
}

$results = New-Object System.Collections.Generic.List[Object]

foreach ($key in $byConn.Keys) {
    $evts = $byConn[$key] | Sort-Object Timestamp
    $pendingBegin = $null

    for ($i = 0; $i -lt $evts.Count; $i++) {
        $ev = $evts[$i]

        if ($ev.Name -eq "QueryBegin") {
            $pendingBegin = $ev
            continue
        }

        if ($ev.Name -eq "QueryEnd" -and $pendingBegin) {
            $winStart = $pendingBegin.Timestamp
            $winEnd   = $ev.Timestamp

            $inWindow = $evts | Where-Object {
                $_.Timestamp -ge $winStart -and $_.Timestamp -le $winEnd -and $_.Name -ne "QueryBegin" -and $_.Name -ne "QueryEnd"
            }

            $subcubeMs = ($inWindow | Where-Object { $_.Name -eq "QuerySubcubeEnd" } | Measure-Object -Property Duration -Sum).Sum
            $calcMs    = ($inWindow | Where-Object { $_.Name -eq "CalculateNonEmptyEnd" } | Measure-Object -Property Duration -Sum).Sum
            $serMs     = ($inWindow | Where-Object { $_.Name -eq "SerializeResultsEnd" } | Measure-Object -Property Duration -Sum).Sum
            $aggHits   = ($inWindow | Where-Object { $_.Name -eq "GetDataFromAggregation" } | Measure-Object).Count
            $cacheHits = ($inWindow | Where-Object { $_.Name -eq "GetDataFromCache" } | Measure-Object).Count
            $subcubeCnt= ($inWindow | Where-Object { $_.Name -eq "QuerySubcubeEnd" } | Measure-Object).Count

            $results.Add([PSCustomObject]@{
                ConnKey        = $key
                Database       = $ev.DbName
                EventDate      = $ev.Timestamp.ToString("yyyy-MM-dd")   # used for grouping into daily file
                EventTime      = $ev.Timestamp.ToString("o")
                TotalMs        = $ev.Duration
                SubcubeMs      = $subcubeMs
                SubcubeCount   = $subcubeCnt
                AggregationHits= $aggHits
                CacheHits      = $cacheHits
                CalcMs         = $calcMs
                SerializeMs    = $serMs
                UserName       = $ev.UserName
                QueryText      = $ev.TextData
            })

            $pendingBegin = $null
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No new events found since last run."
} else {
    $grouped = $results | Group-Object EventDate

    foreach ($grp in $grouped) {
        $dateStr    = $grp.Name
        $dailyCsv   = Join-Path $OutputDir "md_query_log_$dateStr.csv"
        $writeHeader = -not (Test-Path $dailyCsv)

        $rows = $grp.Group | Select-Object * -ExcludeProperty EventDate

        $rows | Export-Csv -Path $dailyCsv -NoTypeInformation -Append:(!$writeHeader) -Force
        Write-Host "Wrote $($rows.Count) rows to $dailyCsv"
    }
}

$maxTimestampSeen.ToString("o") | Set-Content -Path $StateFile

Write-Host "Done. Last processed timestamp: $($maxTimestampSeen.ToString('o'))"
