$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
function Get-Block([string]$source, [string]$marker) {
    $start = $source.IndexOf($marker)
    if ($start -lt 0) { throw "Missing production block $marker" }
    $end = $source.IndexOf('{', $start) + 1; $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    if ($depth) { throw "Unclosed block $marker" }
    $source.Substring($start, $end-$start)
}
$unit = Get-Content "$root/src/server/game/Entities/Unit/Unit.cpp" -Raw
$player = Get-Content "$root/src/server/game/Entities/Player/Player.cpp" -Raw
$aura = Get-Content "$root/src/server/game/Spells/Auras/SpellAuras.cpp" -Raw
$shaman = Get-Block (Get-Content "$root/src/server/scripts/Spells/spell_shaman.cpp" -Raw) 'class spell_sha_maelstrom_weapon_visual :'
if ($shaman -notmatch 'OnEffectApply[^;]+AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK') { throw 'Maelstrom visual must handle initial/restored applications as well as new stacks' }
$fixture = Get-Content "$PSScriptRoot/power_visual_regression.cpp" -Raw
$fixture = $fixture.Replace('// UPDATE_WARLOCK', (Get-Block $unit 'void SpellPowerVisuals::UpdateWarlock('))
$fixture = $fixture.Replace('// UPDATE_PALADIN', (Get-Block $player 'void SpellPowerVisuals::UpdatePaladin('))
$fixture = $fixture.Replace('// SHAMAN_APPLY', (Get-Block $shaman 'void HandleApply('))
$fixture = $fixture.Replace('// SHAMAN_REMOVE', (Get-Block $shaman 'void HandleRemove('))
$power = Get-Block $unit 'void Unit::SetPower('
$fixture = $fixture.Replace('// SHADOW_VISUALS', (Get-Block $power 'if (power == POWER_SHADOW_ORBS)'))
$pattern = 'data << uint8\((aura->GetSpellInfo\(\)->StackAmount[^;]+)\);'
$snapshot = [regex]::Match((Get-Block $player 'void Player::SendAurasForTarget('), $pattern)
$incremental = [regex]::Match((Get-Block $aura 'void AuraApplication::ClientUpdate('), $pattern)
if (!$snapshot.Success -or !$incremental.Success) { throw 'Aura charge serialization expression missing' }
$fixture = $fixture.Replace('/* SNAPSHOT_CHARGES */', $snapshot.Groups[1].Value)
$fixture = $fixture.Replace('/* INCREMENTAL_CHARGES */', $incremental.Groups[1].Value)
$fixture = $fixture.Replace('../../src/server/game/Spells/SpellPowerVisuals.h', "$root/src/server/game/Spells/SpellPowerVisuals.h".Replace('\','/'))
$directory = Join-Path $root 'Build/spell-visual-regression'
New-Item -ItemType Directory -Force $directory | Out-Null
[IO.File]::WriteAllText("$directory/test.cpp", $fixture)
& cl.exe /nologo /EHsc /std:c++17 "$directory/test.cpp" "/Fo:$directory/test.obj" "/Fe:$directory/test.exe"
if ($LASTEXITCODE) { throw 'Visual regression compilation failed' }
& "$directory/test.exe"
if ($LASTEXITCODE) { throw 'Visual regression failed' }
