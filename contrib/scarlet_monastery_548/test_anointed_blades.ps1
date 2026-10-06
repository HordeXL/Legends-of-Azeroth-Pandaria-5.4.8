$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/anointed-blades-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$source = Get-Content "$root/src/server/scripts/EasternKingdoms/ScarletMonastery/boss_high_inqusitior_whitemane.cpp" -Raw
$start = $source.IndexOf('class spell_sc_blades_of_the_anointed :')
if ($start -lt 0) { throw 'Missing production blades spell script' }
$end = $source.IndexOf('{', $start) + 1
$depth = 1
while ($depth -gt 0 -and $end -lt $source.Length) {
    if ($source[$end] -eq '{') { $depth++ }
    if ($source[$end] -eq '}') { $depth-- }
    $end++
}
($source.Substring($start, $end - $start) + ';') | Set-Content "$output/blades.inc"
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vs = & "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/anointed_blades_regression.cpp" "/Fo$output/blades.obj" "/Fe$output/blades.exe"
if ($LASTEXITCODE) { throw 'Blades regression compilation failed' }
& "$output/blades.exe"
if ($LASTEXITCODE) { throw 'Blades regression failed' }
