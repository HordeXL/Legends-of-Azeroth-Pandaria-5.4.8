# Run from x64 Visual Studio Developer PowerShell; no server/database writes.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$source = Get-Content "$root/modules/mod_playerbots/src/Manager/RandomPlayerbotMgr.cpp" -Raw
$start = $source.IndexOf('std::string GetAutoQueueAccountSqlList()')
if ($start -lt 0) { throw 'Missing production account-selection function' }
$end = $source.IndexOf('{', $start) + 1
$depth = 1
while ($depth -gt 0 -and $end -lt $source.Length) {
    if ($source[$end] -eq '{') { $depth++ }
    if ($source[$end] -eq '}') { $depth-- }
    $end++
}
if ($depth -ne 0) { throw 'Unclosed production function' }
$out = "$root/Build/autoqueue-account-pool-test"
New-Item -ItemType Directory -Force $out | Out-Null
[IO.File]::WriteAllText("$out/account_pool_function.h", $source.Substring($start, $end-$start))
& cl.exe /nologo /EHsc /std:c++17 "/I$out" "$PSScriptRoot/account_pool_regression.cpp" "/Fo:$out/account_pool.obj" "/Fe:$out/account_pool.exe"
if ($LASTEXITCODE -ne 0) { throw 'Account-pool regression compilation failed' }
& "$out/account_pool.exe"
if ($LASTEXITCODE -ne 0) { throw 'Account-pool regression failed' }
