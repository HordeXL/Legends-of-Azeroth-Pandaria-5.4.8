param([string]$DataDirectory = '', [string]$OutputDirectory = '')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
if (!$DataDirectory) { $DataDirectory = Join-Path $root 'Build/bin/RelWithDebInfo/dbc' }
if (!$OutputDirectory) { $OutputDirectory = Join-Path $root 'Build/spell-visual-audit' }
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
if (!('VisualAuditDbc' -as [type])) { Add-Type -Path "$PSScriptRoot/DbcTable.cs" }
$tables = @{}
foreach ($name in @('Spell','SpellMisc','SpellClassOptions','SkillLineAbility','Talent','SpellEffect','SpellVisual','SpellVisualKit','SpellVisualEffectName','SpellVisualKitModelAttach','SpellVisualMissile')) {
    $file = Join-Path $DataDirectory "$name.dbc"
    if (!(Test-Path $file) -or (Get-Item $file).Length -lt 20) { $file = Join-Path $DataDirectory "$name.db2" }
    $tables[$name] = [VisualAuditDbc]::new($file)
}
$classes = @{ 1='Warrior'; 2='Paladin'; 3='Hunter'; 4='Rogue'; 5='Priest'; 6='Death Knight'; 7='Shaman'; 8='Mage'; 9='Warlock'; 10='Monk'; 11='Druid' }
$families = @{ 4=1; 10=2; 9=3; 8=4; 6=5; 15=6; 11=7; 3=8; 5=9; 53=10; 7=11 }
$membership = @{}
function Add-ClassSpell([uint32]$spell, [int]$class) {
    if (!$membership.ContainsKey($spell)) { $membership[$spell] = [Collections.Generic.HashSet[int]]::new() }
    [void]$membership[$spell].Add($class)
}
foreach ($spell in $tables.Spell.Rows.Values) {
    $options = $tables.SpellClassOptions.Rows[$spell[14]]
    if ($options -and $families.ContainsKey([int]$options[6])) { Add-ClassSpell $spell[0] $families[[int]$options[6]] }
}
foreach ($ability in $tables.SkillLineAbility.Rows.Values) {
    foreach ($class in $classes.Keys) {
        if ($ability[4] -band (1 -shl ($class - 1))) { Add-ClassSpell $ability[2] $class }
    }
}
foreach ($talent in $tables.Talent.Rows.Values) { if ($classes.ContainsKey([int]$talent[8])) { Add-ClassSpell $talent[4] $talent[8] } }
# Include direct script casts, including generic-family cosmetic helper spells.
$classFiles = @{ 'dk'=6; 'druid'=11; 'hunter'=3; 'mage'=8; 'monk'=10; 'paladin'=2; 'priest'=5; 'rogue'=4; 'shaman'=7; 'warlock'=9; 'warrior'=1 }
foreach ($classFile in $classFiles.Keys) {
    $code = [IO.File]::ReadAllText("$root/src/server/scripts/Spells/spell_$classFile.cpp")
    $constants = @{}
    foreach ($match in [regex]::Matches($code, '\b(\w+)\s*=\s*(\d+)\s*[,;]')) { $constants[$match.Groups[1].Value] = [uint32]$match.Groups[2].Value }
    foreach ($match in [regex]::Matches($code, 'CastSpell\([^,\r\n]+,\s*(\w+)\s*[,)]')) {
        $token = $match.Groups[1].Value
        $id = if ($token -match '^\d+$') { [uint32]$token } elseif ($constants.ContainsKey($token)) { $constants[$token] } else { 0 }
        if ($id) { Add-ClassSpell $id $classFiles[$classFile] }
    }
}
foreach ($id in @(104756,104759,123171,123728,123730,123731,116855,116920,122738,131755)) { Add-ClassSpell $id 9 }
foreach ($id in @(77487,127850,124495)) { Add-ClassSpell $id 5 }
foreach ($id in @(115934,127755,127756)) { Add-ClassSpell $id 2 }
$effects = @{}
foreach ($effect in $tables.SpellEffect.Rows.Values) {
    if (!$effects.ContainsKey($effect[27])) { $effects[$effect[27]] = [Collections.Generic.List[object]]::new() }
    $effects[$effect[27]].Add($effect)
}
# Include data-triggered child spells, even when they use the generic family.
do {
    $changed = $false
    foreach ($id in @($membership.Keys)) {
        foreach ($effect in $effects[$id]) {
            if (!$effect[23] -or !$tables.Spell.Rows.ContainsKey($effect[23])) { continue }
            foreach ($class in @($membership[$id])) {
                if (!$membership.ContainsKey($effect[23]) -or !$membership[$effect[23]].Contains($class)) {
                    Add-ClassSpell $effect[23] $class
                    $changed = $true
                }
            }
        }
    }
} while ($changed)
$issues = [Collections.Generic.List[object]]::new()
$inventory = [Collections.Generic.List[object]]::new()
$visuals = [Collections.Generic.HashSet[uint32]]::new()
foreach ($id in $membership.Keys | Sort-Object) {
    $spell = $tables.Spell.Rows[$id]
    if (!$spell) { $issues.Add([pscustomobject]@{kind='missing_spell';id=$id}); continue }
    $misc = $tables.SpellMisc.Rows[$spell[24]]
    if (!$misc) { $issues.Add([pscustomobject]@{kind='missing_misc';id=$id}); continue }
    foreach ($visual in @($misc[21],$misc[22])) {
        if ($visual) {
            [void]$visuals.Add($visual)
            if (!$tables.SpellVisual.Rows.ContainsKey($visual)) { $issues.Add([pscustomobject]@{kind='missing_visual';id=$id;reference=$visual}) }
        }
    }
    $inventory.Add([pscustomobject]@{
        spell=$id; name=$tables.Spell.Text($spell[1]); classes=(@($membership[$id] | Sort-Object | ForEach-Object {$classes[$_]}) -join ',');
        visual0=$misc[21]; visual1=$misc[22]; passive=[bool]($misc[3] -band 0x40);
        effects=(@($effects[$id] | ForEach-Object { "$($_[2]):$($_[4])" }) -join ',')
    })
}
# Numeric scripted visual IDs supplement data-driven spell visuals.
foreach ($file in Get-ChildItem "$root/src/server/scripts/Spells" -Filter '*.cpp') {
    foreach ($match in [regex]::Matches([IO.File]::ReadAllText($file.FullName), 'SendPlaySpellVisual\(\s*(\d+)')) {
        $visual = [uint32]$match.Groups[1].Value
        [void]$visuals.Add($visual)
        if (!$tables.SpellVisual.Rows.ContainsKey($visual)) { $issues.Add([pscustomobject]@{kind='missing_script_visual';id=$file.Name;reference=$visual}) }
    }
}
$kits = [Collections.Generic.HashSet[uint32]]::new()
foreach ($id in $visuals) {
    $visual = $tables.SpellVisual.Rows[$id]
    if (!$visual) { continue }
    foreach ($column in @(2,3,4,5,6,7,11,12,15,16,17,18)) {
        $kit = $visual[$column]
        if ($kit -and $kit -ne [uint32]::MaxValue) {
            [void]$kits.Add($kit)
            if (!$tables.SpellVisualKit.Rows.ContainsKey($kit)) { $issues.Add([pscustomobject]@{kind='missing_kit';id=$id;reference=$kit}) }
        }
    }
}
$modelEffects = [Collections.Generic.HashSet[uint32]]::new()
foreach ($id in $kits) {
    $kit = $tables.SpellVisualKit.Rows[$id]
    if (!$kit) { continue }
    foreach ($column in 4..15) {
        $effect = $kit[$column]
        if ($effect -and $effect -ne [uint32]::MaxValue) { [void]$modelEffects.Add($effect) }
        if ($effect -and $effect -ne [uint32]::MaxValue -and !$tables.SpellVisualEffectName.Rows.ContainsKey($effect)) {
            $issues.Add([pscustomobject]@{kind='missing_effect_model_record';id=$id;reference=$effect})
        }
    }
}
$attachments = 0
foreach ($row in $tables.SpellVisualKitModelAttach.Rows.Values) {
    if ($kits.Contains($row[1])) {
        $attachments++
        if ($row[2]) { [void]$modelEffects.Add($row[2]) }
        if ($row[2] -and !$tables.SpellVisualEffectName.Rows.ContainsKey($row[2])) {
            $issues.Add([pscustomobject]@{kind='missing_attachment_model';id=$row[0];reference=$row[2]})
        }
    }
}
$missileSets = [Collections.Generic.HashSet[uint32]]::new()
foreach ($id in $visuals) {
    $row = $tables.SpellVisual.Rows[$id]
    if ($row -and $row[29]) { [void]$missileSets.Add($row[29]) }
}
$missiles = 0
foreach ($row in $tables.SpellVisualMissile.Rows.Values) {
    if ($missileSets.Contains($row[1])) {
        $missiles++
        if ($row[2]) { [void]$modelEffects.Add($row[2]) }
        if ($row[2] -and !$tables.SpellVisualEffectName.Rows.ContainsKey($row[2])) {
            $issues.Add([pscustomobject]@{kind='missing_missile_model';id=$row[0];reference=$row[2]})
        }
    }
}
$models = foreach ($id in $modelEffects) {
    $record = $tables.SpellVisualEffectName.Rows[$id]
    if ($record) {
        $path = $tables.SpellVisualEffectName.Text($record[1])
        if ($path -match '\.(m2|mdx)$') { $path -replace '\.mdx$', '.m2' }
    }
}
[IO.File]::WriteAllLines("$OutputDirectory/models.txt", [string[]]@($models | Sort-Object -Unique), [Text.UTF8Encoding]::new($false))
$inventory | Export-Csv "$OutputDirectory/spells.csv" -NoTypeInformation -Encoding UTF8
$issues.ToArray() | ConvertTo-Json -Depth 5 | Set-Content "$OutputDirectory/reference-issues.json"
$summary = [ordered]@{
    classes=11; spells=$inventory.Count; visuals=$visuals.Count; kits=$kits.Count; attachments=$attachments; missiles=$missiles;
    unresolved_spell_ids=@($issues | Where-Object {$_.kind -eq 'missing_spell'}).Count;
    broken_visual_references=@($issues | Where-Object {$_.kind -ne 'missing_spell'}).Count;
    per_class=@(foreach ($class in $classes.Values | Sort-Object) {
        $rows = @($inventory | Where-Object { $class -in ($_.classes -split ',') })
        [pscustomobject]@{class=$class;spells=$rows.Count;with_visual=@($rows | Where-Object {$_.visual0 -or $_.visual1}).Count}
    });
    scope='Spell families, class skills/talents, direct script casts and data-triggered children, including legacy/NPC variants. Reference integrity only: passive/helper spells may intentionally have no visual. Does not prove client model assets, gameplay activation or visual appearance.'
}
$summary | ConvertTo-Json -Depth 5 | Set-Content "$OutputDirectory/summary.json"
$summary | ConvertTo-Json -Depth 5
