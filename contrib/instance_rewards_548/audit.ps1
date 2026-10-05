param(
    [string]$Config = 'Build/bin/RelWithDebInfo/worldserver.conf',
    [string]$Dbc = 'Build/bin/RelWithDebInfo/dbc',
    [string]$Output = 'Build/instance-rewards-audit',
    [string]$Database = '',
    [string]$Mysql = 'C:/wamp64/bin/mysql/mysql8.4.9/bin/mysql.exe'
)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Force $Output | Out-Null
$configText=Get-Content -LiteralPath $Config -Raw
$match=[regex]::Match($configText,'(?m)^WorldDatabaseInfo\s*=\s*"([^"]+)"')
if (!$match.Success) { throw 'WorldDatabaseInfo not found' }
$db=$match.Groups[1].Value.Split(';')
if (!$Database) { $Database=$db[4] }
$queries=[ordered]@{
    loot='SELECT CAST(entry AS SIGNED) entry,item,ChanceOrQuestChance,lootmode+0 mode,groupid,mincountOrRef,maxcount FROM creature_loot_template UNION ALL SELECT -CAST(entry AS SIGNED),item,ChanceOrQuestChance,lootmode+0,groupid,mincountOrRef,maxcount FROM gameobject_loot_template'
    references='SELECT entry,item,ChanceOrQuestChance,lootmode+0 mode,groupid,mincountOrRef,maxcount FROM reference_loot_template'
    encounters='SELECT entry,difficulty+0 difficulty,creditType,creditEntry,lastEncounterDungeon,comment FROM instance_encounters'
    sources='SELECT DISTINCT c.map,CAST(t.entry AS SIGNED) entry,CAST(t.lootid AS SIGNED) lootid,t.name FROM creature c JOIN creature_template t ON t.entry=c.id WHERE t.lootid<>0 UNION SELECT DISTINCT g.map,-CAST(t.entry AS SIGNED),-CAST(t.Data1 AS SIGNED),t.name FROM gameobject g JOIN gameobject_template t ON t.entry=g.id WHERE t.type=3'
    spawns='SELECT map,CAST(id AS SIGNED) entry,BIT_OR(spawnMask) mask FROM creature GROUP BY map,id UNION ALL SELECT map,-CAST(id AS SIGNED),BIT_OR(spawnMask) FROM gameobject GROUP BY map,id'
    creatures='SELECT entry,lootid,name,ScriptName FROM creature_template'
    chests='SELECT entry,Data1 lootid,name FROM gameobject_template WHERE type=3'
    'criteria-data'='SELECT * FROM achievement_criteria_data'
}
$old=$env:MYSQL_PWD
try {
    $env:MYSQL_PWD=$db[3]
    foreach($q in $queries.GetEnumerator()) {
        & $Mysql --host=$($db[0]) --port=$($db[1]) --user=$($db[2]) --database=$Database --batch --execute=$($q.Value) | Set-Content -Encoding UTF8 "$Output/$($q.Key).tsv"
        if($LASTEXITCODE) { throw "Export failed: $($q.Key)" }
    }
} finally { $env:MYSQL_PWD=$old }
Add-Type -Path "$PSScriptRoot/../spell_visual_548/DbcTable.cs","$PSScriptRoot/Audit.cs"
[InstanceRewardsAudit]::Run((Resolve-Path $Dbc),(Resolve-Path $Output))
