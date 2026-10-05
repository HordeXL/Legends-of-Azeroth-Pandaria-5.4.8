# Runs production instance callbacks and Braun damage transitions with small engine doubles.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/scarlet-halls-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$sourceDir = Join-Path $root 'src/server/scripts/EasternKingdoms/ScarletHalls'
function Read-Function([string]$source, [string]$signature) {
    $start = $source.IndexOf($signature)
    if ($start -lt 0) { throw "Missing production function: $signature" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    $source.Substring($start, $end - $start)
}
foreach ($file in @('scarlet_halls.h', 'instance_scarlet_halls.cpp')) {
    $source = Get-Content (Join-Path $sourceDir $file) -Raw
    [regex]::Replace($source, '(?m)^#include[^\r\n]*', '') | Set-Content (Join-Path $output $file)
}
$braun = Get-Content (Join-Path $sourceDir 'boss_houndmaster_braun.cpp') -Raw
(Read-Function $braun 'Creature* SelectedObedientHound') | Set-Content (Join-Path $output 'select_hound.inc')
@(
    (Read-Function $braun 'void DamageTaken('),
    (Read-Function $braun 'void HandleSendActionOnHounds(')
) | Set-Content (Join-Path $output 'braun_damage.inc')
$hound = $braun.Substring($braun.IndexOf('struct npc_obediend_houndAI'))
@(
    (Read-Function $hound 'void DoAction('),
    (Read-Function $hound 'void MovementInform('),
    (Read-Function $hound 'void KillThemAll(')
) | Set-Content (Join-Path $output 'hound_outro.inc')
$trash = Get-Content (Join-Path $sourceDir 'scarlet_halls.cpp') -Raw
(Read-Function $trash 'struct npc_reinforced_archery_targetAI') + ';' | Set-Content (Join-Path $output 'archery_target.inc')
$player = Get-Content (Join-Path $root 'src/server/game/Entities/Player/Player.cpp') -Raw
(Read-Function $player 'bool Player::CanSeeSpellClickOn(') | Set-Content (Join-Path $output 'spellclick_visibility.inc')
@(
    (Read-Function $trash 'enum Spells') + ';',
    (Read-Function $trash 'enum Events') + ';',
    (Read-Function $trash 'enum ScarletHallsGuidTypes') + ';',
    (Read-Function $trash 'enum ScarletHallsFactions') + ';',
    (Read-Function $trash 'struct npc_starving_houndAI') + ';',
    (Read-Function $trash 'class EatenPredicate') + ';'
) | Set-Content (Join-Path $output 'starving_hound.inc')
$foodSpell = $trash.Substring($trash.IndexOf('class spell_scarlet_halls_dog_food_SpellScript'))
(Read-Function $foodSpell 'void HandleHitEffect(') | Set-Content (Join-Path $output 'dog_food_hit.inc')
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/progression_regression.cpp" "/Fo$output/progression.obj" "/Fe$output/progression.exe"
if ($LASTEXITCODE -ne 0) { throw 'Scarlet Halls regression compilation failed' }
& "$output/progression.exe"
if ($LASTEXITCODE -ne 0) { throw 'Scarlet Halls progression regression failed' }
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/dog_food_regression.cpp" "/Fo$output/dog_food.obj" "/Fe$output/dog_food.exe"
if ($LASTEXITCODE -ne 0) { throw 'Dog Food regression compilation failed' }
& "$output/dog_food.exe"
if ($LASTEXITCODE -ne 0) { throw 'Dog Food regression failed' }
# Creature-vs-creature targeting requires a hostile faction relationship.
# Verify the actual installed DBC, not just the engine doubles above.
$bytes = [IO.File]::ReadAllBytes((Join-Path $root 'Build/bin/RelWithDebInfo/dbc/FactionTemplate.dbc'))
$count = [BitConverter]::ToUInt32($bytes, 4)
$size = [BitConverter]::ToUInt32($bytes, 12)
$factions = @{}
for ($i = 0; $i -lt $count; $i++) {
    $offset = 20 + $i * $size
    $id = [int][BitConverter]::ToUInt32($bytes, $offset)
    if ($id -in @(16, 1665)) {
        $factions[$id] = @(for ($j = 0; $j -lt 14; $j++) { [BitConverter]::ToUInt32($bytes, $offset + $j * 4) })
    }
}
$houndFaction = $factions[1665]
$watchmanFaction = $factions[16]
if (!$houndFaction -or !$watchmanFaction -or !($houndFaction[4] -band 1) -or
    !(($houndFaction[5] -band $watchmanFaction[3]) -or ($houndFaction[6..9] -contains $watchmanFaction[1]))) {
    throw 'Feeding faction must be friendly to players and hostile to the watchman'
}
Write-Output 'PASS installed DBC: feeding hounds are friendly to players and hostile to the watchman'
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/archery_target_regression.cpp" "/Fo$output/archery_target.obj" "/Fe$output/archery_target.exe"
if ($LASTEXITCODE -ne 0) { throw 'Archery target regression compilation failed' }
& "$output/archery_target.exe"
if ($LASTEXITCODE -ne 0) { throw 'Archery target regression failed' }
