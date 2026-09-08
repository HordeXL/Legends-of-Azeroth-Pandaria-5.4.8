$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
Push-Location $root
try {
    & cl.exe /nologo /EHsc /std:c++17 "$PSScriptRoot/affliction_regression.cpp" /Fo:Build/affliction_regression.obj /Fe:Build/affliction_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Affliction test compilation failed' }
    & ./Build/affliction_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Affliction regression failed' }
} finally { Pop-Location }
