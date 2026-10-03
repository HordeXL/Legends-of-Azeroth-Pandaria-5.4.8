$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$staged = Join-Path $root 'Build/scarlet-halls-staged'
$server = Join-Path $root 'Build/bin/RelWithDebInfo'
$serverExe = Join-Path $server 'worldserver.exe'
if (!(Test-Path -LiteralPath (Join-Path $staged 'worldserver.exe'))) {
    throw 'Build/scarlet-halls-staged/worldserver.exe is missing.'
}
foreach ($process in @(Get-Process worldserver -ErrorAction SilentlyContinue)) {
    if (!$process.Path -or $process.Path -eq $serverExe) {
        throw 'Stop worldserver normally before installing the Scarlet Halls build.'
    }
}
$backup = Join-Path $root ('Build/server-before-scarlet-halls-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backup | Out-Null
foreach ($name in @('worldserver.exe', 'worldserver.pdb')) {
    $source = Join-Path $staged $name
    $destination = Join-Path $server $name
    if (!(Test-Path -LiteralPath $source)) { throw "Missing staged file: $name" }
    if (Test-Path -LiteralPath $destination) {
        Copy-Item -LiteralPath $destination -Destination (Join-Path $backup $name)
    }
    Copy-Item -LiteralPath $source -Destination $destination
    if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw "Checksum mismatch: $name. Backup: $backup"
    }
}
Write-Output "Scarlet Halls server installed. Backup: $backup"
Write-Output 'Start worldserver normally. Existing completed Braun instances will clear the old gate NPCs when loaded.'
