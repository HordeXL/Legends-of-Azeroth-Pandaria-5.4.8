$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$stagedDirectory = Join-Path $root 'Build/affliction-glyphs'
$serverDirectory = Join-Path $root 'Build/bin/RelWithDebInfo'
$serverExe = Join-Path $serverDirectory 'worldserver.exe'
$stagedExe = Join-Path $stagedDirectory 'worldserver.exe'
if (!(Test-Path -LiteralPath $stagedExe)) { throw 'Build/affliction-glyphs/worldserver.exe is missing. Build the staged server first.' }
foreach ($process in @(Get-Process worldserver -ErrorAction SilentlyContinue)) {
    if (!$process.Path -or $process.Path -eq $serverExe) {
        throw 'The target worldserver is running. Stop it normally before installing; this script will not stop it.'
    }
}
$backupDirectory = Join-Path $root ('Build/server-before-glyphs-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backupDirectory | Out-Null
foreach ($fileName in @('worldserver.exe', 'worldserver.pdb')) {
    $stagedFile = Join-Path $stagedDirectory $fileName
    $serverFile = Join-Path $serverDirectory $fileName
    if (!(Test-Path -LiteralPath $stagedFile)) { continue }
    if (Test-Path -LiteralPath $serverFile) {
        Copy-Item -LiteralPath $serverFile -Destination (Join-Path $backupDirectory $fileName)
    }
    Copy-Item -LiteralPath $stagedFile -Destination $serverFile
    if ((Get-FileHash -LiteralPath $stagedFile).Hash -ne (Get-FileHash -LiteralPath $serverFile).Hash) {
        throw "Checksum mismatch after copying $fileName. Previous files are in $backupDirectory."
    }
}
Write-Output "Glyph-aware server installed. Backup: $backupDirectory"
Write-Output 'Start worldserver normally, then /reload the client and use .combatassist status.'
