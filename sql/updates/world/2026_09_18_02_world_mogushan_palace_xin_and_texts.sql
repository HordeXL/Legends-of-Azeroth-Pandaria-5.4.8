-- Complete Xin the Weaponmaster's secret-defense achievement interaction and
-- restore the missing Mogu'shan Palace combat announcements.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 124527
  AND `ScriptName` = 'spell_secret_defense_mechanism';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(124527, 'spell_secret_defense_mechanism');

DELETE FROM `creature_text`
WHERE (`CreatureID` = 61445 AND `GroupID` IN (5, 6))
   OR (`CreatureID` = 61399 AND `GroupID` = 0);

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
 `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(61445, 5, 0,
 '|TInterface\\Icons\\spell_fire_fireball.blp:20|tHaiyan the Unstoppable begins casting |cFFFF0000|Hspell:120167|h[Conflagrate]|h|r!',
 41, 0, 100, 0, 0, 0, 0, 65545, 0, 'Haiyan the Unstoppable - Conflagrate warning'),
(61445, 6, 0,
 '|TInterface\\Icons\\spell_fire_meteorstorm.blp:20|tHaiyan the Unstoppable targets |cFFFF0000$n|r with a |cFFFF0000|Hspell:120195|h[Meteor]|h|r!',
 41, 0, 100, 0, 0, 0, 0, 65543, 0, 'Haiyan the Unstoppable - Meteor warning'),
(61399, 0, 0,
 'The Glintrok Scout shouts a warning!',
 41, 0, 100, 0, 0, 0, 0, 60810, 0, 'Glintrok Scout - warning emote');
