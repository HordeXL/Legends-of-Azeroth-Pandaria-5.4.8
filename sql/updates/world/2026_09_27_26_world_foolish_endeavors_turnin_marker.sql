-- Foolish Endeavors is turned in to Garrosh Hellscream (25237), not Getry.
-- Place the completion marker at his existing Warsong Hold spawn.
UPDATE quest_poi_points SET X=2838, Y=6187
WHERE QuestID=11705 AND Idx1=3 AND Idx2=0;
