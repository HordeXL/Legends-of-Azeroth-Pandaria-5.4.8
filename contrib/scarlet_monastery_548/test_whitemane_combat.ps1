$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/whitemane-combat-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
function Read-Block([string]$source, [string]$signature) {
    $start = $source.IndexOf($signature)
    if ($start -lt 0) { throw "Missing production block: $signature" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    $source.Substring($start, $end - $start)
}
$source = Get-Content "$root/src/server/scripts/EasternKingdoms/ScarletMonastery/boss_high_inqusitior_whitemane.cpp" -Raw
$source = $source.Substring($source.IndexOf('struct boss_high_inqusitior_whitemaneAI'))
@('void InitializeAI()', 'void Reset()', 'void AttackStart(', 'void MovementInform(') |
    ForEach-Object { Read-Block $source $_ } | Set-Content "$output/whitemane_hooks.inc"
$core = Get-Content "$root/src/server/game/AI/CreatureAI.cpp" -Raw
Read-Block $core 'void CreatureAI::DoZoneInCombat(' | Set-Content "$output/zone_combat.inc"
$unitAI = Get-Content "$root/src/server/game/AI/CoreAI/UnitAI.h" -Raw
Read-Block $unitAI 'virtual void InitializeAI()' | Set-Content "$output/base_initialize.inc"
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vs = & "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/whitemane_combat_regression.cpp" "/Fo$output/whitemane_combat.obj" "/Fe$output/whitemane_combat.exe"
if ($LASTEXITCODE) { throw 'Whitemane combat regression compilation failed' }
& "$output/whitemane_combat.exe"
if ($LASTEXITCODE) { throw 'Whitemane combat regression failed' }
