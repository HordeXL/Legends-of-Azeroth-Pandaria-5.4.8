-- Entry 149045 is a transport (GAMEOBJECT_TYPE_TRANSPORT). Transport objects
-- are client/map driven and cannot be instantiated from the gameobject table.
DELETE FROM `game_event_gameobject`
WHERE `guid` IN (5870, 5876, 5878, 5883, 26004, 66241, 187472);

DELETE FROM `gameobject`
WHERE `id` = 149045
  AND `guid` IN (5870, 5876, 5878, 5883, 26004, 66241, 187472);
