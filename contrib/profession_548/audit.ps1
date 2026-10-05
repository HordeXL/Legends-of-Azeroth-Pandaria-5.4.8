param([string]$DataDirectory='', [string]$OutputDirectory='')
$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
if(!$DataDirectory){$DataDirectory="$root/Build/bin/RelWithDebInfo/dbc"}
if(!$OutputDirectory){$OutputDirectory="$root/Build/profession-audit"}
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$cfg=Get-Content "$root/Build/bin/RelWithDebInfo/worldserver.conf" -Raw
$db=([regex]::Match($cfg,'(?m)^WorldDatabaseInfo\s*=\s*"([^"]+)"')).Groups[1].Value.Split(';')
$old=$env:MYSQL_PWD
try {
    $env:MYSQL_PWD=$db[3]
    & 'C:/wamp64/bin/mysql/mysql8.4.9/bin/mysql.exe' --host=$($db[0]) --port=$($db[1]) --user=$($db[2]) --database=$($db[4]) --batch --execute='SELECT entry,RequiredSkill,spellid_1,spellid_2,spellid_3,spellid_4,spellid_5 FROM item_template' | Set-Content "$OutputDirectory/items.tsv"
    if($LASTEXITCODE){throw 'Item spell export failed'}
} finally {$env:MYSQL_PWD=$old}
Add-Type -Path "$PSScriptRoot/../spell_visual_548/DbcTable.cs","$PSScriptRoot/Audit.cs"
[ProfessionAudit]::Run($DataDirectory,$OutputDirectory)
& "$PSScriptRoot/../spell_visual_548/audit.ps1" -DataDirectory $DataDirectory -OutputDirectory "$OutputDirectory/visuals" -RootSpellsFile "$OutputDirectory/spell-roots.txt"
