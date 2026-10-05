$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
function Read-Block([string]$path, [string]$marker) {
    $source = [IO.File]::ReadAllText((Join-Path $root $path)).Replace("`r`n", "`n")
    $start = $source.IndexOf($marker)
    if ($start -lt 0) { throw "Missing production block: $marker" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    if ($depth) { throw "Unclosed production block: $marker" }
    return $source.Substring($start, $end - $start)
}
$fixture = [IO.File]::ReadAllText("$PSScriptRoot/raid_target_regression.cpp")
$named = 'modules/mod_playerbots/src/strategy/NamedObjectContext.h'
$values = 'modules/mod_playerbots/src/strategy/value/ValueContext.h'
$blocks = @(
    @('// QUALIFIED', $named, 'class Qualified', ';'),
    @('// FACTORY', $named, "template <class T>`nclass NamedObjectFactory", ';'),
    @('// TARGET_CLASS', 'modules/mod_playerbots/src/strategy/value/TargetValue.h', 'class FindTargetValue', ';'),
    @('// TARGET_FACTORY', $values, 'static UntypedValue* find_target', ''),
    @('// TARGET_CALCULATE', 'modules/mod_playerbots/src/strategy/value/TargetValue.cpp', 'Unit* FindTargetValue::Calculate()', ''),
    @('// TRIGGER_CALCULATE', 'modules/mod_playerbots/src/strategy/raids/rubysanctum/RSTriggers.cpp', 'bool RsBaltharusAvoidFrontTrigger::IsActive()', '')
)
foreach ($block in $blocks) {
    $fixture = $fixture.Replace($block[0], ((Read-Block $block[1] $block[2]) + $block[3]))
}
$registration = Get-Content "$root/$values" | Where-Object { $_.Contains('creators["find target"]') } | Select-Object -First 1
$macro = Get-Content "$root/modules/mod_playerbots/src/Playerbots.h" | Where-Object { $_.StartsWith('#define AI_VALUE2(') } | Select-Object -First 1
$fixture = $fixture.Replace('// TARGET_REGISTRATION', $registration).Replace('// AI_VALUE_MACRO', $macro)
$directory = Join-Path $root 'Build/raid-target-regression'
New-Item -ItemType Directory -Force $directory | Out-Null
[IO.File]::WriteAllText("$directory/test.cpp", $fixture)
& cl.exe /nologo /EHsc /std:c++17 "$directory/test.cpp" "/Fo:$directory/test.obj" "/Fe:$directory/test.exe"
if ($LASTEXITCODE) { throw 'Raid target compilation failed' }
& "$directory/test.exe"
if ($LASTEXITCODE) { throw 'Raid target regression failed' }
