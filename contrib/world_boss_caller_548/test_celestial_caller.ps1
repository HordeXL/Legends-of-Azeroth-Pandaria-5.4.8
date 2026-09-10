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
$source = Get-Content "$root/modules/mod_playerbots/src/cs_playerbots.cpp" -Raw
$bodies = (Section $source 'enum WorldBossCallerActions' 'bool LoadWorldBossCallerConfig') +
    (Section $source 'Creature* FindConfiguredWorldBoss' 'char const* WorldBossStagedStateName()')
$menu = Section $source 'void ShowWorldBossCallerMenu' 'struct npc_world_boss_bot_caller'
Set-Content "$root/Build/celestial_caller_production.inc" $bodies
Set-Content "$root/Build/celestial_caller_menu.inc" $menu
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 /IBuild "$PSScriptRoot/celestial_caller_regression.cpp" /Fo:Build/celestial_caller_regression.obj /Fe:Build/celestial_caller_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Celestial caller test compilation failed' }
    & ./Build/celestial_caller_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Celestial caller regression failed' }
} finally { Pop-Location }
