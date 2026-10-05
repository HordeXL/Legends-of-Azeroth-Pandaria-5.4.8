$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/quest-visibility-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$source = Get-Content "$root/src/server/game/Entities/Player/Player.cpp" -Raw
$start = $source.IndexOf('void Player::UpdateForQuestWorldObjects()')
if ($start -lt 0) { throw 'Production quest visibility function not found' }
$end = $source.IndexOf('{', $start) + 1
$depth = 1
while ($depth -gt 0 -and $end -lt $source.Length) {
    if ($source[$end] -eq '{') { $depth++ }
    if ($source[$end] -eq '}') { $depth-- }
    $end++
}
if ($depth -ne 0) { throw 'Unterminated production function' }
$function = $source.Substring($start, $end - $start)
$include = Join-Path $output 'quest_visibility.inc'
Set-Content -LiteralPath $include -Value $function
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/quest_visibility_test.cpp" "/Fo$output/quest_visibility.obj" "/Fe$output/quest_visibility.exe"
if ($LASTEXITCODE -ne 0) { throw 'Quest visibility regression compilation failed' }
& "$output/quest_visibility.exe"
if ($LASTEXITCODE -ne 0) { throw 'Quest visibility regression failed' }
