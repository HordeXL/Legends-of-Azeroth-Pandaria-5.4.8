# Run from an x64 Visual Studio Developer PowerShell with the local MoP DBCs installed.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$harness = Get-Content "$PSScriptRoot/pve_rotation_regression.cpp" -Raw
function Get-Section([string]$text, [string]$start, [string]$end) {
    $a = $text.IndexOf($start)
    if ($a -lt 0) { throw "Missing section: $start" }
    $b = $text.IndexOf($end, $a)
    if ($b -lt 0) { throw "Missing section end: $end" }
    $text.Substring($a, $b - $a).Replace("`r`n", "`n").Trim()
}
$factory = Get-Content "$root/modules/mod_playerbots/src/Factory/BotFactory.cpp" -Raw
$triggers = Get-Content "$root/modules/mod_playerbots/src/strategy/triggers/PveRotationTriggerContext.h" -Raw
$dispels = Get-Content "$root/modules/mod_playerbots/src/strategy/actions/PveDispelAction.h" -Raw
$sections = @(
    @($factory, 'uint8 GetManagedTalentProfileColumn', 'int32 GetPlayerbotTalentScore', 'class PveSpellStateTrigger'),
    @($triggers, 'class PveSpellStateTrigger', 'class PveRotationTriggerContext', 'enum { DISPEL_MAGIC'),
    @($dispels, 'struct PveDispelSpell', 'class PveDispelAction', 'struct Dbc')
)
foreach ($section in $sections) {
    if ((Get-Section $section[0] $section[1] $section[2]) -cne
        (Get-Section $harness $section[1] $section[3])) {
        throw "Regression harness is stale: $($section[1]). Update it from production before testing."
    }
}
Get-Command cl.exe -ErrorAction Stop | Out-Null
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/pve_rotation_regression.cpp" /Fo:Build/pve_rotation_regression.obj /Fe:Build/pve_rotation_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Regression harness compilation failed' }
    & ./Build/pve_rotation_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Regression checks failed' }
} finally { Pop-Location }
