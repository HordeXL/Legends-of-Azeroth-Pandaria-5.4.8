param([switch]$Deploy,[switch]$ExistingReview)
$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
$auditDir=Join-Path $root 'Build/instance-rewards-audit'
New-Item -ItemType Directory -Force $auditDir | Out-Null
$cfg=Get-Content "$root/Build/bin/RelWithDebInfo/worldserver.conf" -Raw
$db=([regex]::Match($cfg,'(?m)^WorldDatabaseInfo\s*=\s*"([^"]+)"')).Groups[1].Value.Split(';')
$old=$env:MYSQL_PWD; $oldEncoding=$OutputEncoding
$mysql='C:/wamp64/bin/mysql/mysql8.4.9/bin/mysql.exe'
$schema='world_instance_rewards_review_20261005'
$tables=@('creature_loot_template','gameobject_loot_template','reference_loot_template','instance_encounters','creature_template','creature','gameobject_template','gameobject','achievement_criteria_data','item_template')
function Sql([string]$query,[string]$database) {
    $result=@($query | & $mysql --host=$($db[0]) --port=$($db[1]) --user=$($db[2]) --database=$database --default-character-set=utf8mb4 --batch 2>&1)
    if($LASTEXITCODE){ $result | Set-Content "$auditDir/sql-error.log"; throw 'SQL failed; see private sql-error.log' }
    return $result
}
try {
    $env:MYSQL_PWD=$db[3]; $OutputEncoding=New-Object Text.UTF8Encoding($false)
    $migration=Get-Content "$root/sql/updates/world/2026_10_05_01_world_instance_reward_difficulties.sql" -Raw
    $migrationHash=(Get-FileHash "$root/sql/updates/world/2026_10_05_01_world_instance_reward_difficulties.sql" -Algorithm SHA256).Hash
    if(!$Deploy) {
        Sql "CREATE DATABASE IF NOT EXISTS $schema" $db[4] | Out-Null
        if(!$ExistingReview) {
            foreach($table in $tables) { Sql "CREATE TABLE $schema.$table LIKE $($db[4]).$table; INSERT INTO $schema.$table SELECT * FROM $($db[4]).$table" $db[4] | Out-Null }
            Sql 'CREATE TABLE creature_loot_before LIKE creature_loot_template; INSERT INTO creature_loot_before SELECT * FROM creature_loot_template;' $schema | Out-Null
        }
        Sql $migration $schema | Out-Null
        $first=Sql 'CHECKSUM TABLE creature_loot_template,gameobject_loot_template,gameobject;' $schema
        Sql $migration $schema | Out-Null
        $second=Sql 'CHECKSUM TABLE creature_loot_template,gameobject_loot_template,gameobject;' $schema
        if(($first -join "`n") -ne ($second -join "`n")){throw 'Migration is not idempotent'}
        $first | Set-Content "$auditDir/review-checksums.tsv"
        $tests=@'
SELECT 'wrong_difficulty_on_reviewed_gear' test, COUNT(*) failures
FROM creature_loot_template l JOIN expected_reward_modes f ON f.entry=l.entry AND f.item=l.item
WHERE l.mincountOrRef>=0 AND (l.lootmode+0=0 OR ((l.lootmode+0)&~f.new_mask)<>0)
UNION ALL
SELECT 'changed_chance_or_quantity',COUNT(*) FROM creature_loot_before b
JOIN expected_reward_modes f ON f.entry=b.entry AND f.item=b.item AND b.lootmode+0=f.old_mask
JOIN creature_loot_template a ON a.entry=b.entry AND a.item=b.item AND a.lootmode+0=f.new_mask
LEFT JOIN creature_loot_before already ON already.entry=b.entry AND already.item=b.item AND already.lootmode+0=f.new_mask
WHERE already.entry IS NULL AND (a.ChanceOrQuestChance<>b.ChanceOrQuestChance OR a.groupid<>b.groupid OR a.mincountOrRef<>b.mincountOrRef OR a.maxcount<>b.maxcount)
UNION ALL
SELECT 'normal_chest_masks',COUNT(*) FROM gameobject WHERE id IN (185168,190586,191349,195323,195374,195709) AND spawnMask<>2
UNION ALL
SELECT 'heroic_25_chest_masks',COUNT(*) FROM gameobject WHERE map=967 AND id IN (210163,209897,210220) AND spawnMask<>64
UNION ALL
SELECT 'missing_journal_items',COUNT(*) FROM
(SELECT 3887 entry,5254 item,2 mode UNION ALL SELECT 3887,5943,2 UNION ALL SELECT 3887,6319,2 UNION ALL SELECT 27977,37649,4) expected
LEFT JOIN creature_loot_template l ON l.entry=expected.entry AND l.item=expected.item AND l.lootmode+0=expected.mode
WHERE l.entry IS NULL OR l.ChanceOrQuestChance<>0 OR l.groupid<>1 OR l.mincountOrRef<>1 OR l.maxcount<>1;
'@
        $rows=Import-Csv "$root/contrib/instance_rewards_548/creature-mode-fixes.csv"
        $values=($rows | ForEach-Object {"($($_.entry),$($_.item),$($_.oldMask),$($_.newMask))"}) -join ','
        Sql "CREATE TABLE IF NOT EXISTS expected_reward_modes (entry INT,item INT,old_mask INT,new_mask INT, PRIMARY KEY(entry,item,old_mask)); TRUNCATE expected_reward_modes; INSERT INTO expected_reward_modes VALUES $values" $schema | Out-Null
        $result=Sql $tests $schema
        $result | Set-Content "$auditDir/validation.tsv"
        if($result | Select-Object -Skip 1 | Where-Object {($_ -split "`t")[-1] -ne '0'}) {throw 'Regression checks failed'}
        $migrationHash | Set-Content "$auditDir/validated-migration.sha256"
        $result
        'Migration idempotence: passed'
    } else {
        if(Get-Process worldserver -ErrorAction SilentlyContinue){throw 'worldserver must be stopped'}
        if(!(Test-Path "$auditDir/validation.tsv")){throw 'Validate before deployment'}
        if(!(Test-Path "$auditDir/validated-migration.sha256") -or (Get-Content "$auditDir/validated-migration.sha256").Trim() -ne $migrationHash){throw 'Validate this exact migration before deployment'}
        $file="$auditDir/world-before-rewards.sql"
        if(Test-Path $file){throw 'Backup already exists; refusing to overwrite'}
        & 'C:/wamp64/bin/mysql/mysql8.4.9/bin/mysqldump.exe' --host=$($db[0]) --port=$($db[1]) --user=$($db[2]) --single-transaction --quick --hex-blob --column-statistics=0 --set-gtid-purged=OFF --result-file=$file $db[4] creature_loot_template gameobject_loot_template gameobject 2> "$auditDir/backup-errors.log"
        if($LASTEXITCODE){throw 'Backup failed'}
        Sql $migration $db[4] | Out-Null
        'Reward difficulty SQL deployed; backup: '+$file
    }
} finally { $env:MYSQL_PWD=$old; $OutputEncoding=$oldEncoding }
