-- Restore valid quest emote sequences from the newer TDB source.
-- The old 5.4.8 dump contains invalid emote 9 and shifted follow-up emotes.

UPDATE `quest_details`
SET `Emote3` = 0
WHERE `ID` = 1242
  AND `Emote1` = 1
  AND `Emote2` = 1
  AND `Emote3` = 9
  AND `Emote4` = 0
  AND `EmoteDelay1` = 0
  AND `EmoteDelay2` = 0
  AND `EmoteDelay3` = 0
  AND `EmoteDelay4` = 0;

UPDATE `quest_offer_reward`
SET `Emote2` = 11,
    `Emote3` = 0,
    `Emote4` = 0
WHERE `ID` = 1242
  AND `Emote1` = 6
  AND `Emote2` = 9
  AND `Emote3` = 6
  AND `Emote4` = 11
  AND `EmoteDelay1` = 0
  AND `EmoteDelay2` = 0
  AND `EmoteDelay3` = 0
  AND `EmoteDelay4` = 0;

UPDATE `quest_offer_reward`
SET `Emote2` = 1,
    `Emote3` = 0
WHERE `ID` = 1244
  AND `Emote1` = 1
  AND `Emote2` = 9
  AND `Emote3` = 1
  AND `Emote4` = 0
  AND `EmoteDelay1` = 0
  AND `EmoteDelay2` = 0
  AND `EmoteDelay3` = 0
  AND `EmoteDelay4` = 0;
