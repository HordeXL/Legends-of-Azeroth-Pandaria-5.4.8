$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/scarlet-monastery-loot-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$source = Get-Content "$root/src/server/game/Loot/LootMgr.cpp" -Raw
$start = $source.IndexOf('void LootTemplate::Process(')
if ($start -lt 0) { throw 'Missing production LootTemplate::Process' }
$end = $source.IndexOf('{', $start) + 1
$depth = 1
while ($depth -gt 0 -and $end -lt $source.Length) {
    if ($source[$end] -eq '{') { $depth++ }
    if ($source[$end] -eq '}') { $depth-- }
    $end++
}
$source.Substring($start, $end - $start) | Set-Content "$output/loot_process.inc"
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vs = & "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/loot_reference_regression.cpp" "/Fo$output/loot_reference.obj" "/Fe$output/loot_reference.exe"
if ($LASTEXITCODE) { throw 'Loot reference regression compilation failed' }
& "$output/loot_reference.exe"
if ($LASTEXITCODE) { throw 'Loot reference regression failed' }
