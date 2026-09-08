# Run from x64 Visual Studio Developer PowerShell; no server/database writes.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$test = (Get-Content "$PSScriptRoot/lfr_observed_regression.cpp" -Raw).Replace("`r`n", "`n")
function Read-Function($path, $signature) {
    $source = Get-Content (Join-Path $root $path) -Raw
    $start = $source.IndexOf($signature)
    if ($start -lt 0) { throw "Missing production function: $signature" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    $source.Substring($start, $end-$start).Replace("`r`n", "`n")
}
$functions = @(
    @('modules/mod_playerbots/src/AI/PlayerbotSpec.cpp', 'Player* PlayerBotSpec::GetGroupPvePullTank'),
    @('modules/mod_playerbots/src/strategy/actions/MovementActions.cpp', 'bool MovementAction::WaitForTankPull'),
    @('modules/mod_playerbots/src/strategy/Classes/hunter/HunterActions.cpp', 'bool CastKillCommandAction::isUseful()')
)
foreach ($function in $functions) {
    if (!$test.Contains((Read-Function $function[0] $function[1]))) { throw "Stale regression body: $($function[1])" }
}
Get-Command cl.exe -ErrorAction Stop | Out-Null
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/lfr_observed_regression.cpp" /Fo:Build/lfr_observed_regression.obj /Fe:Build/lfr_observed_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Observed LFR regression compilation failed' }
    & ./Build/lfr_observed_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Observed LFR regression failed' }
} finally { Pop-Location }
