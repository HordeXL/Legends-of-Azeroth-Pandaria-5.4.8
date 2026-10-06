param(
    [string]$Config = "$PSScriptRoot/../../Build/bin/RelWithDebInfo/worldserver.conf",
    [string]$DbcPath = "$PSScriptRoot/../../Build/bin/RelWithDebInfo/dbc",
    [string]$MySql = 'mysql',
    [string]$Output = "$PSScriptRoot/../../Build/dungeon-quest-audit"
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $Output -Force | Out-Null
$configText = Get-Content -LiteralPath $Config -Raw
$match = [regex]::Match($configText, '(?m)^WorldDatabaseInfo\s*=\s*"([^"]+)"')
if (!$match.Success) { throw 'WorldDatabaseInfo missing' }
$db = $match.Groups[1].Value.Split(';')
function Query([string]$sql) {
    $previous = $env:MYSQL_PWD
    try {
        $env:MYSQL_PWD = $db[3]
        $lines = @(& $MySql --host=$($db[0]) --port=$($db[1]) --user=$($db[2]) --database=$($db[4]) --batch --execute=$sql)
        if ($LASTEXITCODE) { throw 'World database query failed' }
        $lines | ConvertFrom-Csv -Delimiter "`t"
    } finally { $env:MYSQL_PWD = $previous }
}
if (!('VisualAuditDbc' -as [type])) { Add-Type -Path "$PSScriptRoot/../spell_visual_548/DbcTable.cs" }
$maps = [VisualAuditDbc]::new((Resolve-Path "$DbcPath/Map.dbc").Path)
$mapIds = @($maps.Rows.Values | Where-Object { $_[2] -eq 1 } | ForEach-Object { $_[0] }) -join ','
$starters = @(Query @"
SELECT DISTINCT q.ID,q.LogTitle,q.QuestInfoID,q.QuestSortID,q.QuestLevel,q.MinLevel,
       'creature' giver_type,s.id giver,c.map,c.spawnMask
FROM quest_template q JOIN creature_queststarter s ON s.quest=q.ID JOIN creature c ON c.id=s.id
WHERE c.map IN ($mapIds)
UNION
SELECT DISTINCT q.ID,q.LogTitle,q.QuestInfoID,q.QuestSortID,q.QuestLevel,q.MinLevel,
       'gameobject',s.id,g.map,g.spawnMask
FROM quest_template q JOIN gameobject_queststarter s ON s.quest=q.ID JOIN gameobject g ON g.id=s.id
WHERE g.map IN ($mapIds)
ORDER BY map,ID,giver;
"@)
$starters | Export-Csv "$Output/quest-starters.csv" -NoTypeInformation
$activeIds = @($starters.ID | Sort-Object -Unique) -join ','
# Scan all quest templates for potential pairs, then identify which variants
# actually have spawned in-dungeon givers. Unused ZG prototypes are not Normal quests.
$pairs = @(Query @'
SELECT n.ID normal_id,h.ID heroic_id,n.LogTitle,n.QuestSortID
FROM quest_template n JOIN quest_template h
  ON n.LogTitle=h.LogTitle AND n.QuestSortID=h.QuestSortID
WHERE n.QuestInfoID=81 AND h.QuestInfoID=85 ORDER BY n.ID;
'@)
$pairs | Export-Csv "$Output/all-template-pairs.csv" -NoTypeInformation
$activePairs = @($pairs | Where-Object { $_.normal_id -in $starters.ID -and $_.heroic_id -in $starters.ID })
$conditions = @(Query "SELECT * FROM conditions WHERE SourceTypeOrReferenceId=19 AND SourceEntry IN ($activeIds);")
$conditions | Export-Csv "$Output/accept-conditions.csv" -NoTypeInformation
$failures = @()
foreach ($pair in $activePairs) {
    foreach ($mode in 1,2) {
        $quest = if ($mode -eq 1) { $pair.normal_id } else { $pair.heroic_id }
        $questConditions = @($conditions | Where-Object { $_.SourceEntry -eq $quest })
        # Every OR branch needs the difficulty restriction; an unrestricted
        # ElseGroup would let CanTakeQuest bypass the intended mode check.
        $branches = @($questConditions.ElseGroup | Sort-Object -Unique)
        if (!$branches.Count) { $failures += "Quest $quest has no difficulty condition" }
        foreach ($branch in $branches) {
            $gate = @($questConditions | Where-Object {
                $_.ElseGroup -eq $branch -and $_.ConditionTypeOrReference -eq '49' -and
                $_.ConditionTarget -eq '0' -and $_.ConditionValue1 -eq [string]$mode -and $_.NegativeCondition -eq '0'
            })
            if (!$gate.Count) { $failures += "Quest $quest ElseGroup $branch missing difficulty $mode" }
        }
    }
}
$duplicates = @(Query @"
SELECT a.ID,a.LogTitle,a.QuestLevel,a.QuestInfoID,b.ID other_id,b.QuestLevel other_level,b.QuestInfoID other_type
FROM quest_template a JOIN quest_template b ON a.LogTitle=b.LogTitle AND a.ID<b.ID
WHERE a.ID IN ($activeIds) AND b.ID IN ($activeIds)
  AND (a.QuestLevel<>b.QuestLevel OR a.QuestInfoID<>b.QuestInfoID) ORDER BY a.ID;
"@)
$duplicates | Export-Csv "$Output/active-title-duplicates.csv" -NoTypeInformation
$heroicText = @(Query "SELECT ID,LogTitle,QuestLevel,QuestInfoID FROM quest_template WHERE ID IN ($activeIds) AND QuestInfoID<>85 AND (LogDescription LIKE '%heroic%' OR QuestDescription LIKE '%heroic%');")
$heroicText | Export-Csv "$Output/heroic-text-review.csv" -NoTypeInformation
@(
    "Dungeon maps with spawned questgivers: $(@($starters.map | Sort-Object -Unique).Count)",
    "Distinct offered quests: $(@($starters.ID | Sort-Object -Unique).Count)",
    "NPC/GO starter and spawn-mask relations: $($starters.Count)",
    "Active Normal/Heroic pairs: $($activePairs.Count)",
    "Missing difficulty gates: $($failures.Count)",
    'Scope: database-spawned questgivers on DBC non-raid dungeon maps; template pairs also include unused/unspawned variants.',
    'QuestInfo 81 means Dungeon, not Normal-only. Shared quests remain valid in both modes.',
    'Review title duplicates and Heroic wording separately; neither implies a difficulty restriction by itself.'
) | Tee-Object "$Output/summary.txt"
$failures | Set-Content "$Output/missing-gates.txt"
if ($failures.Count) { $failures | Write-Output; throw 'Dungeon quest difficulty audit failed' }
