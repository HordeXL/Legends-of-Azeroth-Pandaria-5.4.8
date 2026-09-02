-- Restore the retail 5.4.8 item-level requirements for every Pandaria LFR
-- wing.  These rows were previously raised to 600 as a crude way to disable
-- unfinished LFR content; that also makes AutoQueue reject every legitimate
-- filler loadout and leaves real players waiting forever.
UPDATE `lfg_dungeon_template`
SET `requiredItemLevel` = CASE `dungeonId`
    WHEN 527 THEN 460 -- Guardians of Mogu'shan
    WHEN 528 THEN 460 -- The Vault of Mysteries
    WHEN 529 THEN 470 -- The Dread Approach
    WHEN 530 THEN 470 -- Nightmare of Shek'zeer
    WHEN 526 THEN 470 -- Terrace of Endless Spring
    WHEN 610 THEN 480 -- Last Stand of the Zandalari
    WHEN 611 THEN 480 -- Forgotten Depths
    WHEN 612 THEN 480 -- Halls of Flesh-Shaping
    WHEN 613 THEN 480 -- Pinnacle of Storms
    WHEN 716 THEN 496 -- Vale of Eternal Sorrows
    WHEN 717 THEN 496 -- Gates of Retribution
    WHEN 724 THEN 496 -- The Underhold
    WHEN 725 THEN 496 -- Downfall
END
WHERE `dungeonId` IN (526, 527, 528, 529, 530, 610, 611, 612, 613,
                      716, 717, 724, 725);
