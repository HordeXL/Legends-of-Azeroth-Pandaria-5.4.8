$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/scarlet-monastery-fuel-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
function Read-Block([string]$source, [string]$signature) {
    $start = $source.IndexOf($signature)
    if ($start -lt 0) { throw "Missing production block: $signature" }
    $end = $source.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $source.Length) {
        if ($source[$end] -eq '{') { $depth++ }
        if ($source[$end] -eq '}') { $depth-- }
        $end++
    }
    $source.Substring($start, $end - $start) + ';'
}
$source = Get-Content "$root/src/server/scripts/EasternKingdoms/ScarletMonastery/scarlet_monastery.cpp" -Raw
$source = $source.Substring($source.IndexOf('class npc_scm_fuel_tank :'))
@(
    (Read-Block $source 'enum eSpells'),
    (Read-Block $source 'struct npc_scm_fuel_tankAI')
) | Set-Content "$output/fuel_tank.inc"
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/fuel_tank_regression.cpp" "/Fo$output/fuel_tank.obj" "/Fe$output/fuel_tank.exe"
if ($LASTEXITCODE) { throw 'Fuel Tank regression compilation failed' }
& "$output/fuel_tank.exe"
if ($LASTEXITCODE) { throw 'Fuel Tank regression failed' }
