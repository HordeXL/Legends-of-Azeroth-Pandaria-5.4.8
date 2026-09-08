$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$source = Get-Content "$root/modules/mod_playerbots/src/AI/PlayerbotSpec.cpp" -Raw
$bodies = foreach ($name in @('IsEngaged','IsCollected','AoeReady','DamageAllowed','NeedsRescue','TauntSpell','RescueTank')) {
    $signature = switch ($name) { 'TauntSpell' { 'unsigned' } 'RescueTank' { 'Player*' } default { 'bool' } }
    $start = $source.IndexOf("$signature GroupPveCombat::$name(")
    if ($start -lt 0) { throw "Missing production function $name" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    $source.Substring($start, $end - $start)
}
Set-Content "$root/Build/pull_support_bodies.inc" ($bodies -join "`n")
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/pull_coordination_regression.cpp" /Fo:Build/pull_coordination_regression.obj /Fe:Build/pull_coordination_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Pull coordination test compilation failed' }
    & ./Build/pull_coordination_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Pull coordination test failed' }
} finally { Pop-Location }
