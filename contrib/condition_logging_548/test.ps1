param([string]$SourcePath)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$output = Join-Path $root 'Build/condition-logging-regression'
New-Item -ItemType Directory -Path $output -Force | Out-Null
if (!$SourcePath) { $SourcePath = "$root/src/server/game/Conditions/ConditionMgr.cpp" }
$source = Get-Content -LiteralPath $SourcePath -Raw
$header = Get-Content "$root/src/server/game/Conditions/ConditionMgr.h" -Raw
function Extract-Block([string]$text, [string]$signature, [bool]$semicolon) {
    $start = $text.IndexOf($signature)
    if ($start -lt 0) { throw "Missing production block: $signature" }
    $end = $text.IndexOf('{', $start) + 1
    $depth = 1
    while ($depth -gt 0 -and $end -lt $text.Length) {
        if ($text[$end] -eq '{') { $depth++ }
        if ($text[$end] -eq '}') { $depth-- }
        $end++
    }
    if ($depth) { throw "Unterminated block: $signature" }
    if ($semicolon) { $end = $text.IndexOf(';', $end) + 1 }
    return $text.Substring($start, $end - $start)
}
$enums = (Extract-Block $header 'enum ConditionTypes' $true) + "`n" +
    (Extract-Block $header 'enum ConditionSourceType' $true)
Set-Content "$output/enums.inc" $enums
$blocks = @(
    (Extract-Block $source 'char const* const ConditionMgr::StaticSourceTypeData' $true),
    (Extract-Block $source 'ConditionMgr::ConditionTypeInfo const ConditionMgr::StaticConditionTypeData' $true),
    (Extract-Block $source 'std::string Condition::ToString(' $false),
    (Extract-Block $source 'bool ConditionMgr::CanHaveSourceGroupSet(' $false),
    (Extract-Block $source 'bool ConditionMgr::CanHaveSourceIdSet(' $false)
)
Set-Content "$output/production.inc" ($blocks -join "`n")
if (!(Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    & "$vs/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null
}
& cl.exe /nologo /EHsc /std:c++17 "/I$output" "$PSScriptRoot/condition_logging_test.cpp" "/Fo$output/test.obj" "/Fe$output/test.exe"
if ($LASTEXITCODE -ne 0) { throw 'Condition logging test compilation failed' }
& "$output/test.exe"
if ($LASTEXITCODE -ne 0) { throw 'Condition logging regression failed' }
