# Uses the configured x64 RelWithDebInfo build's real game/shared libraries.
param([string]$BuildDirectory = 'Build')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$build = (Resolve-Path (Join-Path $root $BuildDirectory)).Path
$output = Join-Path $build 'logout-protocol-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
[xml]$gameProject = Get-Content (Join-Path $build 'src/server/game/game.vcxproj')
$gameSettings = $gameProject.Project.ItemDefinitionGroup | Where-Object { $_.Condition -like '*RelWithDebInfo*' }
$includes = @($gameSettings.ClCompile.AdditionalIncludeDirectories -split ';' |
    Where-Object { $_ -and $_ -notlike '%(*' } | ForEach-Object { '/I"' + $_ + '"' })
[xml]$serverProject = Get-Content (Join-Path $build 'src/server/worldserver/worldserver.vcxproj')
$serverSettings = $serverProject.Project.ItemDefinitionGroup | Where-Object { $_.Condition -like '*RelWithDebInfo*' }
$libraries = @($serverSettings.Link.AdditionalDependencies -split ';' | ForEach-Object {
    if ($_ -like '..*') { '"' + [IO.Path]::GetFullPath((Join-Path "$build/src/server/worldserver" $_)) + '"' }
    else { '"' + $_ + '"' }
})
$argsFile = Join-Path $output 'compile.rsp'
$compileArgs = @('/nologo', '/EHsc', '/std:c++17', '/MD', '/O2', '/DBOOST_ALL_NO_LIB',
  '/D_SILENCE_CXX17_C_HEADER_DEPRECATION_WARNING',
  '/D_CRT_SECURE_NO_WARNINGS', '/DNOMINMAX', '/DWIN32_LEAN_AND_MEAN',
  $includes, ('"' + "$PSScriptRoot/logout_response_test.cpp" + '"'),
  ('/Fo"' + "$output/logout_response.obj" + '"'),
  ('/Fe"' + "$output/logout_response.exe" + '"'), '/link', '/OPT:REF', $libraries)
($compileArgs | ForEach-Object { $_ }) -join ' ' | Set-Content -LiteralPath $argsFile
& cl.exe "@$argsFile"
if ($LASTEXITCODE -ne 0) { throw 'Logout response test compilation failed' }
$previousPath = $env:PATH
try {
    $env:PATH = (Join-Path $build 'bin/RelWithDebInfo') + ';' + $env:PATH
    & "$output/logout_response.exe"
    if ($LASTEXITCODE -ne 0) { throw "Logout response regression or test runtime failure: $LASTEXITCODE" }
}
finally { $env:PATH = $previousPath }
