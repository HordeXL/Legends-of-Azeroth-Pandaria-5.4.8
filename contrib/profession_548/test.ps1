$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
function Block([string]$source,[string]$marker) {
    $start=$source.IndexOf($marker);if($start -lt 0){throw "Missing $marker"}
    $end=$source.IndexOf('{',$start)+1;$depth=1
    while($depth -and $end -lt $source.Length){if($source[$end] -eq '{'){$depth++};if($source[$end] -eq '}'){$depth--};$end++}
    if($depth){throw "Unclosed $marker"};$source.Substring($start,$end-$start)
}
$player=Get-Content "$root/src/server/game/Entities/Player/Player.cpp" -Raw
$aura=Get-Content "$root/src/server/game/Spells/Auras/SpellAuraEffects.cpp" -Raw
$fixture=Get-Content "$PSScriptRoot/regression.cpp" -Raw
$fixture=$fixture.Replace('// MIXOLOGY',(Block $aura 'static float CalculateMixologyAmount('))
$fixture=$fixture.Replace('// ENCHANT_UPDATE',(Block $player 'void Player::UpdateSkillEnchantments('))
$fixture=$fixture.Replace('// SWORDGUARD',(Block $aura 'void AuraEffect::HandleProcTriggerSpellWithValueAuraProc('))
$use=(Block $player 'void Player::CastItemUseSpell(')
$use=$use.Substring($use.IndexOf('// Item enchantments spells casted at use'))
$fixture=$fixture.Replace('// ENCHANT_USE',(Block $use 'for (uint8 e_slot'))
$setSkill=Block $player 'void Player::SetSkill('
$add=$setSkill.Substring($setSkill.IndexOf('else if (newVal)'))
if($add.IndexOf('UpdateSkillEnchantments') -lt $add.IndexOf('mSkillStatus.insert')){throw 'Relearned skill not registered before enchant restoration'}
$dir="$root/Build/profession-audit/regression";New-Item -ItemType Directory -Force $dir | Out-Null
[IO.File]::WriteAllText("$dir/test.cpp",$fixture)
& cl.exe /nologo /EHsc /std:c++17 "$dir/test.cpp" "/Fo:$dir/test.obj" "/Fe:$dir/test.exe"
if($LASTEXITCODE){throw 'Compilation failed'}
& "$dir/test.exe"
if($LASTEXITCODE){throw 'Profession regression failed'}
