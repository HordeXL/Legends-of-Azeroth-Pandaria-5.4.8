-- Preserve the original client's event objective ID for Scourge leader identified.
-- Supersedes migration 24's server-only objectId=4963; geometry still uses trigger 4963.
UPDATE quest_objective SET objectId=-1, amount=1,
 description='Scourge leader identified'
WHERE questId=11652 AND id=262375 AND type=10;

-- Associate the existing central-structure marker with the third objective.
UPDATE quest_poi SET ObjectiveIndex=2, QuestObjectiveId=262375
WHERE QuestID=11652 AND Idx1=3;
