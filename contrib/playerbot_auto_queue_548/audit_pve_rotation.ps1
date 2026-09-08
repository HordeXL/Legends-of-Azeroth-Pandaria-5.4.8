# Read-only source inventory. Missing registrations require manual review:
# this includes PvP/legacy branches and is not a combat simulation.
param([switch]$CheckDbc)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$strategy = Join-Path $root 'modules/mod_playerbots/src/strategy'
function Remove-CodeComments([string]$code) {
    [regex]::Replace($code, '"(?:\\.|[^"\\])*"|/\*[\s\S]*?\*/|//[^\n]*',
        [System.Text.RegularExpressions.MatchEvaluator]{ param($m)
            if ($m.Value.StartsWith('"')) { return $m.Value }; return '' })
}
function Get-Registrations([string]$code, [string]$kind) {
    foreach ($m in [regex]::Matches($code, ('class\s+\w+[^;{]*:\s*public\s+NamedObjectContext<' + $kind + '>[^\{]*\{'))) {
        $depth = 1; $end = $m.Index + $m.Length
        while ($depth -gt 0 -and $end -lt $code.Length) {
            if ($code[$end] -eq '{') { $depth++ }
            if ($code[$end] -eq '}') { $depth-- }
            $end++
        }
        foreach ($creator in [regex]::Matches($code.Substring($m.Index, $end - $m.Index), 'creators\["([^"]+)"\]')) {
            $creator.Groups[1].Value
        }
    }
}
$sources = @{}
Get-ChildItem $strategy -Recurse -File | Where-Object { $_.Extension -in @('.cpp', '.h') } | ForEach-Object {
    $sources[$_.FullName] = Remove-CodeComments (Get-Content $_.FullName -Raw)
}
$generic = @{ Action = @(); Trigger = @() }
foreach ($path in $sources.Keys) {
    if ($path -notmatch '[\\/]Classes[\\/]') {
        foreach ($kind in @('Action', 'Trigger')) { $generic[$kind] += @(Get-Registrations $sources[$path] $kind) }
    }
}
$report = [ordered]@{}
foreach ($directory in Get-ChildItem "$strategy/Classes" -Directory | Sort-Object Name) {
    $available = @{ Action = @($generic.Action); Trigger = @($generic.Trigger) }
    $used = @{ Action = @(); Trigger = @() }
    foreach ($path in $sources.Keys) {
        if (!$path.StartsWith($directory.FullName + '\')) { continue }
        $code = $sources[$path]
        foreach ($kind in @('Action', 'Trigger')) { $available[$kind] += @(Get-Registrations $code $kind) }
        if ([IO.Path]::GetFileName($path) -match 'Strateg') {
            foreach ($m in [regex]::Matches($code, 'new TriggerNode\(\s*"([^"]+)"')) { $used.Trigger += $m.Groups[1].Value }
            foreach ($m in [regex]::Matches($code, 'new NextAction\(\s*"([^"]+)"')) { $used.Action += $m.Groups[1].Value }
        }
    }
    $report[$directory.Name] = [ordered]@{
        missing_triggers = @($used.Trigger | Sort-Object -Unique | Where-Object { $_ -notin $available.Trigger })
        missing_actions = @($used.Action | Sort-Object -Unique | Where-Object { $_ -notin $available.Action })
        used_triggers = @($used.Trigger | Sort-Object -Unique).Count
        used_actions = @($used.Action | Sort-Object -Unique).Count
    }
}
$report | ConvertTo-Json -Depth 5

if ($CheckDbc) {
    function Read-Dbc([string]$name) {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $root "Build/bin/RelWithDebInfo/dbc/$name"))
        if ([Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'WDBC') { throw "Not WDBC: $name" }
        @{ Bytes = $bytes; Count = [BitConverter]::ToUInt32($bytes, 4); Size = [BitConverter]::ToUInt32($bytes, 12) }
    }
    $spellDbc = Read-Dbc 'Spell.dbc'
    $strings = 20 + $spellDbc.Count * $spellDbc.Size
    $spellIds = @{}; $spellNames = @{}; $spellShapes = @{}
    for ($i = 0; $i -lt $spellDbc.Count; $i++) {
        $offset = 20 + $i * $spellDbc.Size
        $id = [BitConverter]::ToUInt32($spellDbc.Bytes, $offset)
        $start = $strings + [BitConverter]::ToUInt32($spellDbc.Bytes, $offset + 4)
        $end = $start
        while ($spellDbc.Bytes[$end] -ne 0) { $end++ }
        $name = [Text.Encoding]::UTF8.GetString($spellDbc.Bytes, $start, $end - $start)
        $spellIds[$id] = $name; $spellNames[$name] = $true
        $spellShapes[$id] = [BitConverter]::ToUInt32($spellDbc.Bytes, $offset + 80)
    }
    $glyphDbc = Read-Dbc 'GlyphProperties.dbc'; $majorSpells = @{}
    for ($i = 0; $i -lt $glyphDbc.Count; $i++) {
        $offset = 20 + $i * $glyphDbc.Size
        if ([BitConverter]::ToUInt32($glyphDbc.Bytes, $offset + 8) -eq 0) {
            $majorSpells[[BitConverter]::ToUInt32($glyphDbc.Bytes, $offset + 4)] = $true
        }
    }
    $factory = Get-Content "$root/modules/mod_playerbots/src/Factory/BotFactory.cpp" -Raw
    $start = $factory.IndexOf('std::array<uint32, 3> GetManagedPveMajorGlyphSpells')
    $end = $factory.IndexOf('int32 GetPlayerbotTalentScore', $start)
    $majorIds = [regex]::Matches($factory.Substring($start, $end - $start), '\b\d{4,}\b') |
        ForEach-Object { [uint32]$_.Value } | Sort-Object -Unique
    foreach ($id in $majorIds) { if (!$majorSpells.ContainsKey($id)) { throw "Unknown MoP major glyph effect $id" } }

    $states = Get-Content "$strategy/triggers/PveRotationTriggerContext.h" -Raw
    $stateIds = [regex]::Matches($states, 'new Pve(?:SpellState|ShamanShield)Trigger\(ai, (\d+)') |
        ForEach-Object { [uint32]$_.Groups[1].Value } | Sort-Object -Unique
    foreach ($id in $stateIds) { if (!$spellIds.ContainsKey($id)) { throw "Unknown MoP rotation spell $id" } }

    $aliases = Get-Content "$strategy/value/SpellIdValue.cpp" -Raw
    $start = $aliases.IndexOf('mopSpellNames = {'); $end = $aliases.IndexOf('};', $start)
    $targets = [regex]::Matches($aliases.Substring($start, $end - $start), '\{"[^"]+", "([^"]+)"\}')
    foreach ($target in $targets) {
        if (!$spellNames.ContainsKey($target.Groups[1].Value)) { throw "Unknown MoP spell alias target: $($target.Groups[1].Value)" }
    }
    $shapeDbc = Read-Dbc 'SpellShapeshift.dbc'; $shapeMasks = @{}
    for ($i = 0; $i -lt $shapeDbc.Count; $i++) {
        $offset = 20 + $i * $shapeDbc.Size
        # DBCfmt "nixixx": field 1 -> StancesNot, field 3 -> Stances.
        $shapeMasks[[BitConverter]::ToUInt32($shapeDbc.Bytes, $offset)] =
            [BitConverter]::ToUInt32($shapeDbc.Bytes, $offset + 12)
    }
    $formCases = @(@(33876,1), @(33878,16), @(77758,16), @(106830,1), @(779,16), @(62078,1))
    foreach ($case in $formCases) {
        if ($shapeMasks[$spellShapes[[uint32]$case[0]]] -ne $case[1]) {
            throw "Unexpected MoP druid form mask for spell $($case[0])"
        }
    }
    "DBC PASS: $($majorIds.Count) major glyph effects, $($stateIds.Count) rotation spell IDs, $($targets.Count) spell aliases, $($formCases.Count) druid form masks."
}
