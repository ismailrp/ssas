<#
.SYNOPSIS
    Parses copied SSAS Tabular and Multidimensional .xel files offline.

.DESCRIPTION
    Windows PowerShell 4.0 compatible. Defaults are resolved relative to this
    script, so it can be invoked from any working directory. No server
    connection, processing, cache clear, or XEvent session mutation occurs.
#>

[CmdletBinding()]
param(
    [string]$TabularXelPath = "",
    [string]$MultidimensionalXelPath = "",
    [string]$OutputRoot = "",
    [string]$RunId = "",
    [string]$XEventDllPath = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$minimumPowerShell = New-Object Version 4,0
if ($PSVersionTable.PSVersion -lt $minimumPowerShell) {
    throw ("PowerShell 4.0 atau lebih baru diperlukan. Versi aktif: " + $PSVersionTable.PSVersion)
}

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = ""
if ($scriptPath) { $scriptDirectory = Split-Path -Parent $scriptPath }
if (-not $scriptDirectory) { $scriptDirectory = (Get-Location).Path }

if (-not $TabularXelPath) { $TabularXelPath = Join-Path $scriptDirectory "XEvents\Tabular" }
if (-not $MultidimensionalXelPath) { $MultidimensionalXelPath = Join-Path $scriptDirectory "XEvents\Multidimensional" }
if (-not $OutputRoot) { $OutputRoot = Join-Path $scriptDirectory "results\XEvents" }
if (-not [System.IO.Path]::IsPathRooted($TabularXelPath)) { $TabularXelPath = Join-Path $scriptDirectory $TabularXelPath }
if (-not [System.IO.Path]::IsPathRooted($MultidimensionalXelPath)) { $MultidimensionalXelPath = Join-Path $scriptDirectory $MultidimensionalXelPath }
if (-not [System.IO.Path]::IsPathRooted($OutputRoot)) { $OutputRoot = Join-Path $scriptDirectory $OutputRoot }
if ($XEventDllPath -and (-not [System.IO.Path]::IsPathRooted($XEventDllPath))) { $XEventDllPath = Join-Path $scriptDirectory $XEventDllPath }
if (-not $RunId) { $RunId = "RUN-" + (Get-Date -Format "yyyyMMdd-HHmmss") }
if ($RunId -match '[\\/:*?"<>|]') { throw "RunId mengandung karakter path yang tidak valid." }

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Find-XEventDll([string]$RequestedPath) {
    if ($RequestedPath) {
        return (Resolve-Path -LiteralPath $RequestedPath -ErrorAction Stop).Path
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if (-not $root) { continue }
        foreach ($version in @("170","160","150","140","130","120","110")) {
            $candidates.Add((Join-Path $root ("Microsoft SQL Server\" + $version + "\Shared\Microsoft.SqlServer.XEvent.Linq.dll")))
            $candidates.Add((Join-Path $root ("Microsoft SQL Server\" + $version + "\Tools\Binn\ManagementStudio\Microsoft.SqlServer.XEvent.Linq.dll")))
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    throw "Microsoft.SqlServer.XEvent.Linq.dll tidak ditemukan. Gunakan -XEventDllPath dengan path DLL dari instalasi SSMS."
}

function Get-XelFiles([string]$InputPath) {
    if (-not (Test-Path -LiteralPath $InputPath)) { return @() }
    $item = Get-Item -LiteralPath $InputPath
    if ($item.PSIsContainer) {
        return @(Get-ChildItem -LiteralPath $item.FullName -Filter "*.xel" -File | Sort-Object FullName)
    }
    if ($item.Extension -ieq ".xel") { return @($item) }
    return @()
}

function Get-EventValue($Event, [string[]]$Names) {
    foreach ($name in $Names) {
        try {
            $field = $Event.Fields[$name]
            if ($null -ne $field) { return $field.Value }
        }
        catch {}
        try {
            $action = $Event.Actions[$name]
            if ($null -ne $action) { return $action.Value }
        }
        catch {}
    }
    return $null
}

function Get-TextHash([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $sha = New-Object System.Security.Cryptography.SHA256Managed
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "")
    }
    finally { $sha.Dispose() }
}

function New-EventRow($Event, [string]$EngineType, [string]$SourceFile) {
    $activityId = Get-EventValue $Event @("ActivityID","ActivityId","activity_id")
    $requestId = Get-EventValue $Event @("RequestID","RequestId","request_id")
    $sessionId = Get-EventValue $Event @("SessionID","SessionId","session_id")
    $requestProperties = [string](Get-EventValue $Event @("RequestProperties","request_properties"))
    if ((-not $activityId) -and $requestProperties -match '<DbpropMsmdActivityID>([^<]+)</DbpropMsmdActivityID>') {
        $activityId = $matches[1]
    }
    $connectionId = Get-EventValue $Event @("ConnectionID","ConnectionId","connection_id")
    $spid = Get-EventValue $Event @("SPID","Spid","spid")
    $duration = Get-EventValue $Event @("Duration","duration")
    $cpu = Get-EventValue $Event @("CpuTime","CPUTime","cpu_time")
    $database = Get-EventValue $Event @("DatabaseName","Database","database_name")
    $userName = Get-EventValue $Event @("NTUserName","NTUsername","Username","nt_username")
    $textData = Get-EventValue $Event @("TextData","QueryText","text_data")
    $eventSubclass = Get-EventValue $Event @("EventSubclass","event_subclass")

    return New-Object PSObject -Property @{
        EngineType = $EngineType
        SourceFile = $SourceFile
        EventName = [string]$Event.Name
        Timestamp = $Event.Timestamp.ToString("o")
        ActivityID = [string]$activityId
        RequestID = [string]$requestId
        SessionID = [string]$sessionId
        ConnectionID = [string]$connectionId
        SPID = [string]$spid
        DatabaseName = [string]$database
        DurationMs = $duration
        CpuTimeMs = $cpu
        NTUserName = [string]$userName
        TextData = [string]$textData
        TextHashSHA256 = Get-TextHash ([string]$textData)
        EventSubclass = [string]$eventSubclass
    }
}

function Resolve-TabularActivityIds([object[]]$Events) {
    $byRequest = @{}
    foreach ($event in $Events) {
        if ($event.RequestID -and $event.ActivityID) {
            $byRequest[[string]$event.RequestID] = [string]$event.ActivityID
        }
    }
    foreach ($event in $Events) {
        if ((-not $event.ActivityID) -and $event.RequestID -and $byRequest.ContainsKey([string]$event.RequestID)) {
            $event.ActivityID = $byRequest[[string]$event.RequestID]
        }
    }
}

function Read-XEvents([System.IO.FileInfo[]]$Files, [string]$EngineType) {
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in $Files) {
        Write-Host ("Reading " + $file.FullName)
        $events = $null
        try {
            $events = New-Object Microsoft.SqlServer.XEvent.Linq.QueryableXEventData($file.FullName)
            foreach ($event in $events) {
                $rows.Add((New-EventRow $event $EngineType $file.Name))
            }
        }
        finally {
            if ($null -ne $events -and $events -is [IDisposable]) {
                try { $events.Dispose() } catch {}
            }
        }
    }
    return $rows
}

function Correlate-Tabular([object[]]$Events) {
    $queryEnds = @{}
    $storageEvents = @{}

    foreach ($event in $Events) {
        $key = [string]$event.RequestID
        if (-not $key) { $key = [string]$event.ActivityID }
        if (-not $key) { continue }
        if ($event.EventName -ieq "QueryEnd") {
            $queryEnds[$key] = $event
        }
        elseif ($event.EventName -match '(?i)VertiPaqSEQueryEnd|DirectQueryEnd') {
            if (-not $storageEvents.ContainsKey($key)) {
                $storageEvents[$key] = New-Object System.Collections.Generic.List[object]
            }
            $storageEvents[$key].Add($event)
        }
    }

    $result = New-Object System.Collections.Generic.List[object]
    foreach ($key in $queryEnds.Keys) {
        $query = $queryEnds[$key]
        $children = @()
        if ($storageEvents.ContainsKey($key)) {
            $children = @($storageEvents[$key] | ForEach-Object { $_ })
        }
        $seMs = 0.0
        foreach ($child in $children) {
            if ($null -ne $child.DurationMs -and [string]$child.DurationMs) { $seMs += [double]$child.DurationMs }
        }
        $totalMs = 0.0
        if ($null -ne $query.DurationMs -and [string]$query.DurationMs) { $totalMs = [double]$query.DurationMs }
        $feMs = $totalMs - $seMs
        if ($feMs -lt 0) { $feMs = 0 }
        $quality = "MATCHED_BY_REQUEST_ID_WITH_ACTIVITY_ID"
        if (-not $query.RequestID) { $quality = "MATCHED_BY_ACTIVITY_ID" }
        if ($children.Count -eq 0) { $quality = "QUERY_ONLY_NO_SE_EVENT" }
        if ($seMs -gt $totalMs -and $totalMs -gt 0) { $quality = "MATCHED_SE_SUM_EXCEEDS_TOTAL" }

        $result.Add((New-Object PSObject -Property @{
            ActivityID = $query.ActivityID
            RequestID = $query.RequestID
            DatabaseName = $query.DatabaseName
            QueryEndTimestamp = $query.Timestamp
            TotalMs = $totalMs
            CpuTimeMs = $query.CpuTimeMs
            SEMs = $seMs
            FEMsDerived = $feMs
            SEQueryCount = $children.Count
            SERatioPct = if ($totalMs -gt 0) { [Math]::Round(($seMs / $totalMs) * 100, 2) } else { 0 }
            NTUserName = $query.NTUserName
            QueryText = $query.TextData
            QueryHashSHA256 = $query.TextHashSHA256
            CorrelationQuality = $quality
        }))
    }
    return $result
}

function Correlate-Multidimensional([object[]]$Events) {
    $groups = @($Events | Group-Object ConnectionID,SPID)
    $result = New-Object System.Collections.Generic.List[object]

    foreach ($group in $groups) {
        $ordered = @($group.Group | Sort-Object Timestamp)
        $pending = New-Object System.Collections.Generic.List[object]
        $windows = New-Object System.Collections.Generic.List[object]

        foreach ($event in $ordered) {
            if ($event.EventName -ieq "QueryBegin") {
                $pending.Add($event)
            }
            elseif ($event.EventName -ieq "QueryEnd" -and $pending.Count -gt 0) {
                $beginIndex = $pending.Count - 1
                $begin = $pending[$beginIndex]
                $pending.RemoveAt($beginIndex)
                $windows.Add((New-Object PSObject -Property @{ Begin=$begin; End=$event }))
            }
        }

        foreach ($window in $windows) {
            $start = [DateTime]$window.Begin.Timestamp
            $end = [DateTime]$window.End.Timestamp
            $subEvents = @($ordered | Where-Object {
                $timestamp = [DateTime]$_.Timestamp
                $timestamp -ge $start -and $timestamp -le $end -and $_.EventName -ine "QueryBegin" -and $_.EventName -ine "QueryEnd"
            })
            $overlapCount = @($windows | Where-Object {
                ([DateTime]$_.Begin.Timestamp) -lt $end -and ([DateTime]$_.End.Timestamp) -gt $start
            }).Count

            $subcubeMs = 0.0
            $calcMs = 0.0
            $serializeMs = 0.0
            foreach ($subEvent in $subEvents) {
                $duration = 0.0
                if ($null -ne $subEvent.DurationMs -and [string]$subEvent.DurationMs) { $duration = [double]$subEvent.DurationMs }
                if ($subEvent.EventName -ieq "QuerySubcubeEnd") { $subcubeMs += $duration }
                elseif ($subEvent.EventName -ieq "CalculateNonEmptyEnd") { $calcMs += $duration }
                elseif ($subEvent.EventName -ieq "SerializeResultsEnd") { $serializeMs += $duration }
            }

            $quality = "MATCHED_BY_CONNECTION_SPID_WINDOW"
            if ($overlapCount -gt 1) { $quality = "AMBIGUOUS_OVERLAPPING_WINDOW" }
            $endEvent = $window.End
            $result.Add((New-Object PSObject -Property @{
                ConnectionID = $endEvent.ConnectionID
                SPID = $endEvent.SPID
                DatabaseName = $endEvent.DatabaseName
                QueryBeginTimestamp = $window.Begin.Timestamp
                QueryEndTimestamp = $endEvent.Timestamp
                TotalMs = $endEvent.DurationMs
                CpuTimeMs = $endEvent.CpuTimeMs
                SubcubeMs = $subcubeMs
                SubcubeCount = @($subEvents | Where-Object { $_.EventName -ieq "QuerySubcubeEnd" }).Count
                AggregationHits = @($subEvents | Where-Object { $_.EventName -ieq "GetDataFromAggregation" }).Count
                CacheHits = @($subEvents | Where-Object { $_.EventName -ieq "GetDataFromCache" }).Count
                CalculateNonEmptyMs = $calcMs
                SerializeResultsMs = $serializeMs
                NTUserName = $endEvent.NTUserName
                QueryText = if ($endEvent.TextData) { $endEvent.TextData } else { $window.Begin.TextData }
                QueryHashSHA256 = Get-TextHash $(if ($endEvent.TextData) { $endEvent.TextData } else { $window.Begin.TextData })
                CorrelationQuality = $quality
            }))
        }
    }
    return $result
}

function Export-Rows([object[]]$Rows, [string]$Path, [string[]]$Columns) {
    if ((Test-Path -LiteralPath $Path) -and (-not $Force)) {
        throw ("Output sudah ada: " + $Path + ". Gunakan RunId baru atau -Force.")
    }
    if ($Rows.Count -gt 0) {
        $Rows | Select-Object $Columns | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8
    }
    else {
        (($Columns | ForEach-Object { '"' + $_.Replace('"','""') + '"' }) -join ',') | Set-Content -LiteralPath $Path -Encoding UTF8
    }
}

$dll = Find-XEventDll $XEventDllPath
Add-Type -LiteralPath $dll

$tabularFiles = @(Get-XelFiles $TabularXelPath)
$multidimensionalFiles = @(Get-XelFiles $MultidimensionalXelPath)
if ($tabularFiles.Count -eq 0 -and $multidimensionalFiles.Count -eq 0) {
    throw "Tidak ada file .xel pada folder input Tabular maupun Multidimensional."
}

$runRoot = Join-Path $OutputRoot $RunId
$tabularOutput = Join-Path $runRoot "Tabular"
$multidimensionalOutput = Join-Path $runRoot "Multidimensional"
Ensure-Directory $tabularOutput
Ensure-Directory $multidimensionalOutput

$eventColumns = @("EngineType","SourceFile","EventName","Timestamp","ActivityID","RequestID","SessionID","ConnectionID","SPID","DatabaseName","DurationMs","CpuTimeMs","NTUserName","TextData","TextHashSHA256","EventSubclass")
$tabularQueryColumns = @("ActivityID","RequestID","DatabaseName","QueryEndTimestamp","TotalMs","CpuTimeMs","SEMs","FEMsDerived","SEQueryCount","SERatioPct","NTUserName","QueryText","QueryHashSHA256","CorrelationQuality")
$mdQueryColumns = @("ConnectionID","SPID","DatabaseName","QueryBeginTimestamp","QueryEndTimestamp","TotalMs","CpuTimeMs","SubcubeMs","SubcubeCount","AggregationHits","CacheHits","CalculateNonEmptyMs","SerializeResultsMs","NTUserName","QueryText","QueryHashSHA256","CorrelationQuality")

$tabularEvents = @(Read-XEvents $tabularFiles "TABULAR")
$mdEvents = @(Read-XEvents $multidimensionalFiles "MULTIDIMENSIONAL")
Resolve-TabularActivityIds $tabularEvents
$tabularQueries = @(Correlate-Tabular $tabularEvents)
$mdQueries = @(Correlate-Multidimensional $mdEvents)

Export-Rows $tabularEvents (Join-Path $tabularOutput "events.csv") $eventColumns
Export-Rows $tabularQueries (Join-Path $tabularOutput "queries.csv") $tabularQueryColumns
Export-Rows $mdEvents (Join-Path $multidimensionalOutput "events.csv") $eventColumns
Export-Rows $mdQueries (Join-Path $multidimensionalOutput "queries.csv") $mdQueryColumns

$manifest = @(
    New-Object PSObject -Property @{ EngineType="TABULAR"; InputFolder=$TabularXelPath; XelFileCount=$tabularFiles.Count; EventCount=$tabularEvents.Count; CorrelatedQueryCount=$tabularQueries.Count; EventsPath=(Join-Path $tabularOutput "events.csv"); QueriesPath=(Join-Path $tabularOutput "queries.csv") }
    New-Object PSObject -Property @{ EngineType="MULTIDIMENSIONAL"; InputFolder=$MultidimensionalXelPath; XelFileCount=$multidimensionalFiles.Count; EventCount=$mdEvents.Count; CorrelatedQueryCount=$mdQueries.Count; EventsPath=(Join-Path $multidimensionalOutput "events.csv"); QueriesPath=(Join-Path $multidimensionalOutput "queries.csv") }
)
$manifest | Select-Object EngineType,InputFolder,XelFileCount,EventCount,CorrelatedQueryCount,EventsPath,QueriesPath |
    Export-Csv -LiteralPath (Join-Path $runRoot "parser_manifest.csv") -NoTypeInformation -Encoding UTF8

$summary = New-Object PSObject -Property @{
    run_id = $RunId
    parsed_at_utc = [DateTime]::UtcNow.ToString("o")
    powershell_version = $PSVersionTable.PSVersion.ToString()
    xevent_dll = $dll
    tabular_xel_files = $tabularFiles.Count
    tabular_events = $tabularEvents.Count
    tabular_correlated_queries = $tabularQueries.Count
    multidimensional_xel_files = $multidimensionalFiles.Count
    multidimensional_events = $mdEvents.Count
    multidimensional_correlated_queries = $mdQueries.Count
}
$summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runRoot "summary.json") -Encoding UTF8

Write-Host "XEvent parsing selesai."
Write-Host ("Output: " + $runRoot)
Write-Host ("Tabular: files=" + $tabularFiles.Count + ", events=" + $tabularEvents.Count + ", queries=" + $tabularQueries.Count)
Write-Host ("Multidimensional: files=" + $multidimensionalFiles.Count + ", events=" + $mdEvents.Count + ", queries=" + $mdQueries.Count)
