$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$test = (Get-Content "$PSScriptRoot/shaman_totem_regression.cpp" -Raw).Replace("`r`n", "`n")
$source = Get-Content "$root/modules/mod_playerbots/src/strategy/Classes/shaman/ShamanActions.cpp" -Raw
foreach ($signature in @('Creature* GetOwnedActiveTotem(', 'Group* GetTotemCoordinationGroup(',
    'bool ShamanTotemSupport::IsWaterAction(', 'bool ShamanTotemSupport::HasProtectedWaterTotem(',
    'bool ShamanTotemSupport::CanPlaceWaterTotem(', 'bool ShamanTotemSupport::NeedsWaterTotem(',
    'bool ShamanTotemSupport::CanRecallTotems(', 'bool CastTotemicRecallAction::isUseful()',
    'bool CastTotemicRecallAction::Execute(', 'bool CastTotemAction::Execute(')) {
    $start = $source.IndexOf($signature)
    if ($start -lt 0) { throw "Missing body: $signature" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    if (!$test.Contains($source.Substring($start, $end-$start).Replace("`r`n", "`n"))) {
        throw "Stale production body: $signature"
    }
}
$context = Get-Content "$root/modules/mod_playerbots/src/strategy/Classes/shaman/ShamanAiObjectContext.cpp" -Raw
foreach ($registration in @('creators["no water totem"]', 'creators["totemic recall"]')) {
    if (!$context.Contains($registration)) { throw "Missing registration: $registration" }
}
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/shaman_totem_regression.cpp" /Fo:Build/shaman_totem_regression.obj /Fe:Build/shaman_totem_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Totem test compilation failed' }
    & ./Build/shaman_totem_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Totem regression failed' }
} finally { Pop-Location }
