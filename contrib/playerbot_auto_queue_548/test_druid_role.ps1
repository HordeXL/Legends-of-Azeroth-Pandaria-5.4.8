$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$test = (Get-Content "$PSScriptRoot/druid_role_regression.cpp" -Raw).Replace("`r`n", "`n")
$functions = @(
    @('DruidActions.cpp', 'bool DruidPartyHealAction::IsRoleAllowed()'),
    @('DruidActions.cpp', 'bool DruidPartyHealAction::isUseful()'),
    @('DruidActions.cpp', 'bool DruidPartyHealAction::Execute(Event event)'),
    @('DruidTriggers.cpp', 'bool PveMoonkinFormTrigger::IsActive()')
)
foreach ($pair in $functions) {
    $source = Get-Content "$root/modules/mod_playerbots/src/strategy/Classes/druid/$($pair[0])" -Raw
    $start = $source.IndexOf($pair[1])
    if ($start -lt 0) { throw "Missing production function: $($pair[1])" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    if (!$test.Contains($source.Substring($start, $end-$start).Replace("`r`n", "`n"))) {
        throw "Stale production body: $($pair[1])"
    }
}
$header = Get-Content "$root/modules/mod_playerbots/src/strategy/Classes/druid/DruidActions.h" -Raw
foreach ($name in @('CastRejuvenationOnPartyAction', 'CastRegrowthOnPartyAction', 'CastHealingTouchOnPartyAction',
    'CastLifebloomOnPartyAction', 'CastWildGrowthOnPartyAction', 'CastPartySwiftmendAction',
    'CastPartyNourishAction', 'CastRejuvenationOnNotFullAction')) {
    if (!$header.Contains("class $name : public DruidPartyHealAction")) { throw "Missing role guard: $name" }
}
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/druid_role_regression.cpp" /Fo:Build/druid_role_regression.obj /Fe:Build/druid_role_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Druid role test compilation failed' }
    & ./Build/druid_role_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Druid role regression failed' }
} finally { Pop-Location }
