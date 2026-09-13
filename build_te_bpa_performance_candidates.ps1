[CmdletBinding()]
param(
    [string]$InputPath = "",
    [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $InputPath) { $InputPath = Join-Path $scriptDirectory "results\TE_CLI_BPA\bpa_findings.csv" }
if (-not $OutputRoot) { $OutputRoot = Join-Path $scriptDirectory "results\TE_CLI_BPA" }
if (-not (Test-Path -LiteralPath $InputPath)) { throw "BPA findings not found: $InputPath" }

$catalog = @{
    "RELATIONSHIP_COLUMNS_SAME_DATA_TYPE" = @("P1", "HIGH", "Relationship", "Mismatched relationship-key types can impair relationship correctness and efficiency.", "Align both sides to the smallest valid common type, preferably integer surrogate keys where source semantics permit.", "Validate relationship integrity, row counts, semantic results, processing duration, and representative query timings.")
    "AVOID_FLOATING_POINT_DATA_TYPES" = @("P1", "MEDIUM", "Storage", "Floating-point columns can reduce VertiPaq compression efficiency, especially on large fact tables.", "Prioritize large/high-cardinality fact columns; test integer scaling or fixed decimal without losing required precision.", "Compare distinct values, dictionary/column size, model size, refresh duration, and warm-query timings.")
    "FILTER_COLUMN_VALUES" = @("P1", "MEDIUM", "DAX", "Filtering an expanded table can create more Formula Engine work than a semantically equivalent column predicate.", "Review measured hotspot measures and replace broad table filters with narrow column predicates only when semantics remain identical.", "Run semantic regression and compare FE/SE duration, SE query count, rows, and median warm duration.")
    "CHECK_IF_BI-DIRECTIONAL_AND_MANY-TO-MANY_RELATIONSHIPS_ARE_VALID" = @("P1", "MEDIUM", "Relationship", "Bidirectional or many-to-many propagation can increase filter-path complexity.", "Review bridge design and change to single direction only when business semantics allow.", "Test affected measures, RLS, filter propagation, ambiguity, FE/SE timings, and result equality.")
    "AVOID_EXCESSIVE_BI-DIRECTIONAL_OR_MANY-TO-MANY_RELATIONSHIPS" = @("P1", "MEDIUM", "Relationship", "A high concentration of complex relationships can increase propagation and maintenance cost.", "Redesign only confirmed hotspots, favoring explicit bridge/star patterns and intentional filter direction.", "Validate all affected reports, RLS, relationship paths, and before/after runtime.")
    "REDUCE_USAGE_OF_CALCULATED_COLUMNS_THAT_USE_THE_RELATED_FUNCTION" = @("P1", "MEDIUM", "Storage/Refresh", "Calculated columns consume storage and RELATED dependencies add processing work.", "Assess moving stable logic upstream or replacing it with a measure where semantics permit.", "Compare refresh duration, model size, result equality, and query timings.")
    "SNOWFLAKE_SCHEMA_ARCHITECTURE" = @("P2", "MEDIUM", "Architecture", "Snowflake chains can add relationship propagation compared with a validated star schema.", "Evaluate flattening only the paths implicated by workload evidence.", "Prototype outside production and compare refresh, model size, FE/SE duration, and semantic results.")
    "REMOVE_REDUNDANT_COLUMNS_IN_RELATED_TABLES" = @("P2", "MEDIUM", "Storage", "Duplicated attributes can consume dictionary and segment storage.", "Prioritize large/high-cardinality duplicates after dependency and report-usage validation.", "Check report bindings, dependencies, RLS, sort-by, model size, refresh, and query regression.")
    "REDUCE_USAGE_OF_CALCULATED_TABLES" = @("P2", "MEDIUM", "Storage/Refresh", "Calculated tables add processing and storage, but can be appropriate for model semantics.", "Review large calculated tables and consider source materialization or a smaller design.", "Measure table size, processing duration, dependency behavior, and semantic equality.")
    "REDUCE_NUMBER_OF_CALCULATED_COLUMNS" = @("P2", "MEDIUM", "Storage/Refresh", "Calculated columns increase stored model size and refresh work.", "Rank calculated columns by size and usage; move or remove only validated candidates.", "Compare model size, refresh duration, query timings, and semantic results.")
    "FILTER_MEASURE_VALUES_BY_COLUMNS" = @("P2", "MEDIUM", "DAX", "Filtering over measure results may require expensive Formula Engine evaluation.", "Inspect Server Timings and seek a semantically equivalent base-column filter or reduced iterator input.", "Compare FE duration, callback behavior, SE query count, and result equality.")
    "INACTIVE_RELATIONSHIPS_THAT_ARE_NEVER_ACTIVATED" = @("P2", "LOW", "Relationship", "Unused relationships add metadata and processing overhead, though runtime benefit may be small.", "Confirm no DAX, report, RLS, or external client depends on the relationship before removal.", "Dependency scan, report inventory, refresh test, and semantic regression are mandatory.")
    "USE_THE_DIVIDE_FUNCTION_FOR_DIVISION" = @("P2", "LOW", "DAX", "DIVIDE safely handles zero/blank denominators and can simplify defensive DAX.", "Review divisions in measured hotspots; replace only when the intended alternate-result semantics match.", "Validate edge cases, result equality, and representative query timings.")
    "AVOID_USING_THE_IFERROR_FUNCTION" = @("P2", "LOW", "DAX", "IFERROR may force evaluation patterns that are avoidable with explicit safe operations.", "Replace with targeted logic such as DIVIDE only where error semantics are preserved.", "Test error/blank/zero cases, result equality, and runtime.")
    "MODEL_SHOULD_HAVE_A_DATE_TABLE" = @("P3", "LOW", "Model Design", "A proper date table improves time-intelligence correctness; direct speed benefit is workload-dependent.", "Add or designate a date dimension only after confirming time-intelligence requirements.", "Validate date coverage, uniqueness, relationships, time-intelligence results, and runtime.")
    "DATE/CALENDAR_TABLES_SHOULD_BE_MARKED_AS_A_DATE_TABLE" = @("P3", "LOW", "Model Design", "Date-table metadata supports correct time-intelligence behavior; it is not a general latency fix.", "Validate the date key and mark the correct table where required by model compatibility and DAX behavior.", "Run time-intelligence semantic regression and representative query timings.")
    "CHECK_IF_DYNAMIC_ROW_LEVEL_SECURITY_(RLS)_IS_NECESSARY" = @("P3", "LOW", "Security", "Dynamic RLS can add filter evaluation, but security requirements take precedence.", "Review only with the security owner; simplify expressions without weakening authorization.", "Test every role/persona, deny cases, result correctness, and role-specific runtime.")
    "UNPIVOT_PIVOTED_(MONTH)_DATA" = @("P3", "LOW", "Source Design", "Wide month columns can be less scalable than a normalized date/value design.", "Evaluate source-side unpivoting for the affected table during a controlled redesign.", "Compare source query, refresh duration, model size, usability, and query timings.")
}

$findings = @(Import-Csv -LiteralPath $InputPath)
$candidates = New-Object Collections.Generic.List[object]
foreach ($finding in $findings) {
    if (-not $catalog.ContainsKey($finding.RuleID)) { continue }
    $rule = $catalog[$finding.RuleID]
    $candidates.Add([pscustomobject]@{
        Priority = $rule[0]; Potential = $rule[1]; Database = $finding.Database
        RuleID = $finding.RuleID; Category = $rule[2]; ObjectType = $finding.ObjectType
        Object = $finding.Object; ObjectPath = $finding.ObjectPath
        Classification = "REQUIRES VALIDATION"; Confidence = $finding.Confidence
        WhyPotential = $rule[3]; Recommendation = $rule[4]; ValidationMethod = $rule[5]
        EvidenceFile = $finding.EvidenceFile
    })
}

$priorityOrder = @{ "P1" = 1; "P2" = 2; "P3" = 3 }
$sortedCandidates = @($candidates | Sort-Object @{Expression = { $priorityOrder[$_.Priority] }}, Database, RuleID, ObjectPath)
$sortedCandidates | Export-Csv -LiteralPath (Join-Path $OutputRoot "bpa_performance_candidates.csv") -NoTypeInformation -Encoding UTF8

$summary = @($sortedCandidates | Group-Object RuleID | ForEach-Object {
    $first = $_.Group[0]
    [pscustomobject]@{
        Priority = $first.Priority; Potential = $first.Potential; RuleID = $_.Name
        Findings = $_.Count; Databases = @($_.Group.Database | Select-Object -Unique).Count
        Category = $first.Category; WhyPotential = $first.WhyPotential
        Recommendation = $first.Recommendation; ValidationMethod = $first.ValidationMethod
    }
} | Sort-Object @{Expression = { $priorityOrder[$_.Priority] }}, @{Expression = { [int]$_.Findings }; Descending = $true})
$summary | Export-Csv -LiteralPath (Join-Path $OutputRoot "bpa_performance_rule_summary.csv") -NoTypeInformation -Encoding UTF8

Write-Output ("Performance candidate list generated: rules={0}, object findings={1}" -f $summary.Count, $sortedCandidates.Count)
