-- Locale rows cannot be loaded without their achievement_reward parent.
-- Guard the cleanup so translations are retained whenever a reward exists.
DELETE l
FROM `achievement_reward_locale` AS l
LEFT JOIN `achievement_reward` AS r ON r.`entry` = l.`ID`
WHERE r.`entry` IS NULL;
