$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/class_ownership_regression.cpp" /Fo:Build/class_ownership_regression.obj /Fe:Build/class_ownership_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Class ownership test compilation failed' }
    & ./Build/class_ownership_regression.exe Build/bin/RelWithDebInfo/dbc
    if ($LASTEXITCODE -ne 0) { throw 'Class ownership regression failed' }
} finally { Pop-Location }
