$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$harness = (Get-Content "$PSScriptRoot/pve_loadout_observed_regression.cpp" -Raw).Replace("`r`n", "`n")
$sources = @(
    @('actions/GenericSpellActions.cpp', 'bool CastHealingSpellAction::IsHealingRoleAllowed()'),
    @('actions/GenericSpellActions.cpp', 'bool CastHealingSpellAction::isUseful()'),
    @('actions/GenericSpellActions.cpp', 'bool CastHealingSpellAction::Execute(Event event)'),
    @('actions/GenericSpellActions.cpp', 'bool CastAoeHealSpellAction::isUseful()'),
    @('Classes/monk/MonkActions.h', 'class CastTigerPalmAction'),
    @('Classes/monk/MonkActions.h', 'class CastBlackoutKickAction'),
    @('Classes/monk/MonkActions.h', 'class CastTigereyeBrewAction'),
    @('Classes/warlock/WarlockTriggers.h', 'class CurseOfAgonyTrigger')
)
foreach ($pair in $sources) {
    $source = Get-Content "$root/modules/mod_playerbots/src/strategy/$($pair[0])" -Raw
    $start = $source.IndexOf($pair[1])
    if ($start -lt 0) { throw "Missing production body: $($pair[1])" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    if (!$harness.Contains($source.Substring($start, $end-$start).Replace("`r`n", "`n"))) {
        throw "Stale test body: $($pair[1])"
    }
}
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/pve_loadout_observed_regression.cpp" /Fo:Build/pve_loadout_observed_regression.obj /Fe:Build/pve_loadout_observed_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Loadout regression compilation failed' }
    & ./Build/pve_loadout_observed_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Loadout regression failed' }
} finally { Pop-Location }
