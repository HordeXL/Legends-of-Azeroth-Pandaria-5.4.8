-- Keep persisted corpse primary keys stable across map-local runtime corpse GUIDs.
-- The core regenerates corpse runtime GUIDs when loading from DB, so the owner
-- GUID is the safest persistent key for the single saved corpse each character
-- can have.
UPDATE `corpse`
SET `corpseGuid` = `guid`
WHERE `corpseGuid` <> `guid`;
