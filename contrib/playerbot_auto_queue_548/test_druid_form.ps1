param([switch]$NegativeControl)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/druid-form-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$path = 'modules/mod_playerbots/src/strategy/Classes/druid/DruidShapeshiftActions.cpp'
$source = Get-Content "$root/$path" -Raw
$start = $source.IndexOf('bool CastMoonkinFormAction::Execute(Event event)')
if ($start -lt 0) { throw 'Missing Moonkin action' }
$end = $source.IndexOf("`n}", $start) + 2
$function = $source.Substring($start, $end - $start)
if ($NegativeControl) {
    $function = 'bool CastMoonkinFormAction::Execute(Event event) { return CastBuffSpellAction::Execute(event); }'
}
Set-Content "$output/moonkin.inc" $function
$source = Get-Content "$root/modules/mod_playerbots/src/AI/PlayerbotAI.cpp" -Raw
$start = $source.IndexOf('spell->prepare(&targets);', $source.IndexOf('bool PlayerbotAI::CastSpell(uint32 spellId, Unit*'))
$end = $source.IndexOf('_aiObjectContext->GetValue<LastSpellCast&>', $start)
if ($start -lt 0 -or $end -lt 0) { throw 'Missing cast-result handling' }
Set-Content "$output/cast_result.inc" $source.Substring($start, $end - $start)
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/druid_form_regression.cpp" "/Fo$output/test.obj" "/Fe$output/test.exe"
if ($LASTEXITCODE -ne 0) { throw 'Druid form test compilation failed' }
& "$output/test.exe"
if ($LASTEXITCODE -ne 0) { throw 'Druid form regression failed' }
