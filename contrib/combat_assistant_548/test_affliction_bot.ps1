# Run from an x64 Visual Studio Developer PowerShell.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
function Section([string]$text, [string]$start, [string]$end) {
    $a = $text.IndexOf($start)
    if ($a -lt 0) { throw "Missing production section: $start" }
    $b = $text.IndexOf($end, $a)
    if ($b -lt 0) { throw "Missing production section end: $end" }
    $text.Substring($a, $b - $a)
}
$source = Get-Content "$root/modules/mod_playerbots/src/CombatAssistant.cpp" -Raw
$header = Get-Content "$root/modules/mod_playerbots/src/CombatAssistant.h" -Raw
$strategy = Get-Content "$root/modules/mod_playerbots/src/strategy/Classes/warlock/AffliWarlockStrategy.cpp" -Raw
# Compile the current production bodies with a controlled spell engine and AI.
# There is no hand-maintained copy of the adapter/cast guard to go stale.
$runtime = Section $header 'struct AfflictionRotationRuntime' 'bool UsesAfflictionBotRotation'
$bodies = (Section $source 'bool UsesAfflictionAssistant' 'bool IsAfflictionProtectedAlly') +
    (Section $source 'Spell* PrepareCheckedSpell' 'bool CanCast(') +
    (Section $source 'void UpdateRecentDamage' 'bool IsTakingBurstDamage') +
    (Section $source 'bool UsesAfflictionBotRotation' 'void AddSC_playerbots_combat_assistant') +
    (Section $strategy 'class AfflictionRotationMultiplier' 'class AffliWarlockStrategyActionNodeFactory')
Set-Content "$root/Build/affliction_bot_runtime.inc" $runtime
Set-Content "$root/Build/affliction_bot_production.inc" $bodies
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 /IBuild "$PSScriptRoot/affliction_bot_regression.cpp" /Fo:Build/affliction_bot_regression.obj /Fe:Build/affliction_bot_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Affliction bot test compilation failed' }
    & ./Build/affliction_bot_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Affliction bot regression failed' }
} finally { Pop-Location }
