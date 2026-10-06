-- Rank and File (31490 / 31495): both quests require 50 kills of proxy 64964.
-- Scarlet Halls crusaders had neither this KillCredit nor a scripted award.
-- Use the native kill-reward path so eligible party members receive one credit
-- per kill, with the existing distance, quest-status and 50-kill cap checks.
-- These entries are shared by Normal and Heroic; difficulty scaling does not
-- change their template. Include the summoned cannoneers and Harlan defenders.
-- Dogs, cannon stalkers, friendly defenders, targets and questgivers are excluded.
UPDATE `creature_template`
SET `KillCredit1` = 64964
WHERE `entry` IN (
    58632, -- Armsmaster Harlan
    58676, -- Scarlet Defender (trash)
    58683, -- Scarlet Myrmidon
    58684, -- Scarlet Scourge Hewer
    58685, -- Scarlet Evangelist
    58756, -- Scarlet Evoker
    58898, -- Vigilant Watchman
    58998, -- Scarlet Defender (Harlan summon)
    59150, -- Flameweaver Koegler
    59175, -- Master Archer
    59191, -- Commander Lindon
    59240, -- Scarlet Hall Guardian
    59241, -- Scarlet Treasurer
    59293, -- Scarlet Cannoneer
    59299, -- Scarlet Guardian
    59302, -- Sergeant Verdone
    59303, -- Houndmaster Braun
    59372, -- Scarlet Scholar
    59373  -- Scarlet Pupil
)
AND `KillCredit1` = 0
AND `KillCredit2` <> 64964;
