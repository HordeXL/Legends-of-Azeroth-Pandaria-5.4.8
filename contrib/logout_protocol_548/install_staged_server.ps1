$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$staged = Join-Path $root 'Build/logout-response-staged'
$server = Join-Path $root 'Build/bin/RelWithDebInfo'
$serverExe = Join-Path $server 'worldserver.exe'
foreach ($name in @('worldserver.exe', 'worldserver.pdb')) {
    if (!(Test-Path -LiteralPath (Join-Path $staged $name))) { throw "Missing staged file: $name" }
}
foreach ($process in @(Get-Process worldserver -ErrorAction SilentlyContinue)) {
    if (!$process.Path -or $process.Path -eq $serverExe) {
        throw 'Stop worldserver normally before installing the logout response build.'
    }
}
$backup = Join-Path $root ('Build/server-before-logout-response-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backup | Out-Null
foreach ($name in @('worldserver.exe', 'worldserver.pdb')) {
    $destination = Join-Path $server $name
    if (Test-Path -LiteralPath $destination) {
        Copy-Item -LiteralPath $destination -Destination (Join-Path $backup $name)
    }
}
foreach ($name in @('worldserver.exe', 'worldserver.pdb')) {
    $source = Join-Path $staged $name
    $destination = Join-Path $server $name
    Copy-Item -LiteralPath $source -Destination $destination
    if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw "Checksum mismatch: $name. Backup: $backup"
    }
}
Write-Output "Logout response build installed. Backup: $backup"
