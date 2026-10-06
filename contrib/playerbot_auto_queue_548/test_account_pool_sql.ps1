# MySQL read-only regression: derived fixtures replace the table names in the
# production queries. No real character/account rows are read or changed.
param(
    [string]$Config = "$PSScriptRoot/../../Build/bin/RelWithDebInfo/worldserver.conf",
    [string]$MySql = 'C:/wamp64/bin/mysql/mysql8.4.9/bin/mysql.exe'
)
$ErrorActionPreference = 'Stop'
$source = Get-Content "$PSScriptRoot/../../modules/mod_playerbots/src/Manager/RandomPlayerbotMgr.cpp" -Raw
$queries = [regex]::Matches($source, 'QueryResult candidates = CharacterDatabase.PQuery\(([\s\S]*?)poolAccounts.c_str\(\),')
if ($queries.Count -ne 2) { throw 'Expected the production LFG and BG candidate queries' }
$fixtures = @'
 SELECT 1 AS guid,'tank' AS name,1 AS race,1 AS class,'73 0' AS talentTree,
 0 AS activespec,10 AS account,90 AS level,0 AS online,0 AS instance_id
 UNION ALL SELECT 2,'healer',1,5,'257 0',0,12,90,0,0
 UNION ALL SELECT 3,'real-player-between-bot-accounts',1,1,'73 0',0,11,90,0,0
 UNION ALL SELECT 4,'low-level-random',1,1,'73 0',0,10,25,0,0
 UNION ALL SELECT 5,'low-level-dedicated',1,1,'73 0',0,500,1,0,0
 UNION ALL SELECT 6,'dedicated',1,5,'257 0',0,502,90,0,0
 UNION ALL SELECT 7,'online',1,1,'73 0',0,10,90,1,0
 UNION ALL SELECT 8,'guild-member',1,1,'73 0',0,10,90,0,0
 UNION ALL SELECT 9,'group-member',1,1,'73 0',0,10,90,0,0
 UNION ALL SELECT 10,'arena-backup',1,1,'73 0',0,10,90,0,0
 UNION ALL SELECT 11,'stranded-instance',1,1,'73 0',0,10,90,0,7
'@
$db = ([regex]::Match((Get-Content $Config -Raw), '(?m)^CharacterDatabaseInfo\s*=\s*"([^"]+)"')).Groups[1].Value.Split(';')
if ($db.Count -ne 5) { throw 'Cannot read character database connection' }
$previous = $env:MYSQL_PWD
$checks = 0
try {
    $env:MYSQL_PWD = $db[3]
    for ($i=0; $i -lt $queries.Count; $i++) {
        $sql = ([regex]::Matches($queries[$i].Groups[1].Value, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }) -join ''
        $randomExpected = if ($i -eq 0) { '1,2,11' } else { '1,2' }
        $cases = @(
            @('10,12', 0, 90, $randomExpected),
            @('10,12', 0, 25, '4'),
            @('500,502', 1, 90, '5,6'),
            @('500,502', 1, 25, '5,6')
        )
        foreach ($case in $cases) {
            $query = $sql.Replace('%s', $case[0]).Replace('%u=1', "$($case[1])=1").Replace('level=%u', "level=$($case[2])")
            $query = $query.Replace('FROM characters', "FROM ($fixtures) characters").
                Replace('FROM guild_member', 'FROM (SELECT 8 AS guid) guild_member').
                Replace('FROM group_member', 'FROM (SELECT 9 AS memberGuid) group_member').
                Replace('FROM solo_arena_loadout_backup', 'FROM (SELECT 10 AS owner_guid) solo_arena_loadout_backup')
            $query = "SELECT GROUP_CONCAT(guid ORDER BY guid) FROM ($query) candidates;"
            $result = & $MySql --host=$($db[0]) --port=$($db[1]) --user=$($db[2]) --database=$($db[4]) --batch --skip-column-names --execute=$query
            if ($LASTEXITCODE -ne 0 -or $result -ne $case[3]) {
                throw "Candidate query $i, pool=$($case[1]), level=$($case[2]): expected $($case[3]), got $result"
            }
            $checks++
        }
    }
} finally { $env:MYSQL_PWD = $previous }
Write-Output "$checks production SQL candidate checks passed (read-only fixtures)"
