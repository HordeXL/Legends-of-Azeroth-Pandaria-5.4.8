param(
    [string]$ConfigPath = "$PSScriptRoot/../../Build/bin/RelWithDebInfo/worldserver.conf",
    [string]$MysqlPath = 'C:/wamp64/bin/mysql/mysql8.4.9/bin/mysql.exe'
)
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw
$match = [regex]::Match($config, '(?m)^WorldDatabaseInfo\s*=\s*"([^"]+)"')
if (!$match.Success) { throw 'WorldDatabaseInfo not found' }
$dbParts = $match.Groups[1].Value.Split(';')
$migration = Get-Content -LiteralPath "$PSScriptRoot/../../sql/updates/world/2026_09_10_00_world_celestial_court_shared_bot_caller.sql" -Raw
# MySQL cannot INSERT/SELECT the same temporary table. Run the exact migration
# in a uniquely named disposable database; the live world tables are read only.
$testDatabase = 'codex_celestial_caller_test_' + [guid]::NewGuid().ToString('N').Substring(0,12)
$quotedSource = '`' + $dbParts[4].Replace('`','``') + '`'
$quotedTest = '`' + $testDatabase + '`'
$setup = "CREATE DATABASE $quotedTest; USE $quotedTest;" + "`n" +
    "CREATE TABLE creature LIKE $quotedSource.creature;" + "`n" +
    "CREATE TABLE playerbot_world_boss_caller LIKE $quotedSource.playerbot_world_boss_caller;" + "`n" +
    "CREATE TABLE creature_template LIKE $quotedSource.creature_template;" + "`n" +
    "INSERT INTO creature_template SELECT * FROM $quotedSource.creature_template WHERE entry=990912;"
$sql = $setup + "`n" + $migration + "`n" + @'
SELECT IF(COUNT(*)=1,'PASS placement','FAIL placement')
FROM creature c JOIN playerbot_world_boss_caller p USING(guid)
WHERE c.guid=4000118 AND c.id=990912 AND c.map=870
  AND c.phaseMask=4294967295 AND c.zoneId=6757 AND c.areaId=6830
  AND ABS(c.position_x+750.005)<0.001 AND ABS(c.position_y+5016.65)<0.001
  AND ABS(c.position_z+6.27724)<0.001 AND ABS(c.orientation-0.0679426)<0.00001
  AND p.boss_entry=0 AND p.boss_search_radius=250 AND p.raid_size_mask=3 AND p.strategy_ready=1
  AND ABS(p.rally_x-c.position_x)<0.001 AND ABS(p.rally_y-c.position_y)<0.001
  AND ABS(p.rally_z-c.position_z)<0.001 AND ABS(p.rally_o-c.orientation)<0.00001;
CREATE TEMPORARY TABLE caller_before_reapply AS SELECT * FROM creature;
'@ + "`n" + $migration + "`n" + @'
SELECT IF((SELECT COUNT(*) FROM creature)=1 AND
          (SELECT COUNT(*) FROM playerbot_world_boss_caller)=1,
          'PASS idempotent','FAIL idempotent');
SELECT IF(COUNT(*)=1,'PASS spawn preserved','FAIL spawn preserved')
FROM creature c JOIN caller_before_reapply b USING(guid)
WHERE c.position_x=b.position_x AND c.position_y=b.position_y
  AND c.position_z=b.position_z AND c.orientation=b.orientation AND c.id=b.id;
UPDATE creature SET id=1,position_x=123 WHERE guid=4000118;
UPDATE playerbot_world_boss_caller SET boss_entry=123,comment='unrelated fixture' WHERE guid=4000118;
'@ + "`n" + $migration + "`n" + @'
SELECT IF(COUNT(*)=1,'PASS collision preserved','FAIL collision preserved')
FROM creature c JOIN playerbot_world_boss_caller p USING(guid)
WHERE c.guid=4000118 AND c.id=1 AND c.position_x=123
  AND p.boss_entry=123 AND p.comment='unrelated fixture';
'@
$oldMysqlPassword = $env:MYSQL_PWD
try {
    $env:MYSQL_PWD = $dbParts[3]
    $result = & $MysqlPath --host=$($dbParts[0]) --port=$($dbParts[1]) --user=$($dbParts[2]) --database=$($dbParts[4]) --batch --skip-column-names --execute=$sql
    if ($LASTEXITCODE -ne 0) { throw 'Spawn migration SQL test failed' }
    $result
    if (($result | Where-Object { $_ -like 'FAIL*' }) -or
        @($result | Where-Object { $_ -like 'PASS*' }).Count -ne 4) {
        throw 'Spawn migration assertions failed'
    }
} finally {
    try {
        if ($testDatabase -notmatch '^codex_celestial_caller_test_[a-f0-9]{12}$') {
            throw 'Invalid disposable test database name; refusing cleanup'
        }
        & $MysqlPath --host=$($dbParts[0]) --port=$($dbParts[1]) --user=$($dbParts[2]) --batch --execute="DROP DATABASE IF EXISTS $quotedTest;"
        if ($LASTEXITCODE -ne 0) { throw 'Disposable test database cleanup failed' }
    } finally { $env:MYSQL_PWD = $oldMysqlPassword }
}
