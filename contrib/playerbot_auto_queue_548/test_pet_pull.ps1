# Run from x64 Visual Studio Developer PowerShell. Does not start the server.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$source = Get-Content "$root/modules/mod_playerbots/src/strategy/Classes/deathknight/DKActions.cpp" -Raw
$test = Get-Content "$PSScriptRoot/pet_pull_regression.cpp" -Raw
$marker = 'bool CastPestilenceAction::isUseful()'
$start = $source.IndexOf($marker)
$end = $source.IndexOf('namespace', $start)
$body = $source.Substring($start, $end-$start).Replace("`r`n", "`n").Trim()
if (!$test.Replace("`r`n", "`n").Contains($body)) { throw 'Pestilence regression body is stale' }
$value = Get-Content "$root/modules/mod_playerbots/src/strategy/Value.h" -Raw
if ($value -notmatch 'class ObjectGuidListCalculatedValue\s*:\s*public CalculatedValue<GuidVector>') {
    throw 'Attackers value storage changed; review the typed regression'
}
Get-Command cl.exe -ErrorAction Stop | Out-Null
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/pet_pull_regression.cpp" /Fo:Build/pet_pull_regression.obj /Fe:Build/pet_pull_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Pet pull regression compilation failed' }
    & ./Build/pet_pull_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Pet pull regression failed' }
} finally { Pop-Location }
