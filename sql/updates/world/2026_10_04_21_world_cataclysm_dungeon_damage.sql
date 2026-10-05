-- Normalize excessive Cataclysm dungeon melee damage against Firelands 4.3.4 data.
-- Only values more than 10% above the reference are lowered; this is idempotent
-- and intentionally leaves spell damage and incomplete Hour of Twilight data alone.

DROP TEMPORARY TABLE IF EXISTS `_cata_dungeon_damage_fix`;
CREATE TEMPORARY TABLE `_cata_dungeon_damage_fix` (
    `target` VARCHAR(16) NOT NULL,
    `entry` MEDIUMINT UNSIGNED NOT NULL,
    `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `damage_mod` FLOAT NOT NULL,
    PRIMARY KEY (`target`, `entry`, `difficulty`)
);

INSERT INTO `_cata_dungeon_damage_fix` (`target`, `entry`, `difficulty`, `damage_mod`) VALUES
('difficulty', 3864, 2, 55.0), -- map 33: Fel Steed
('difficulty', 3875, 2, 55.0), -- map 33: Haunted Servitor
('template', 36272, 0, 7.5), -- map 33: Apothecary Frye
('template', 36296, 0, 7.5), -- map 33: Apothecary Hummel
('template', 36565, 0, 7.5), -- map 33: Apothecary Baxter
('difficulty', 48278, 2, 10.0), -- map 36: Mining Monkey
('difficulty', 48440, 2, 10.0), -- map 36: Mining Monkey
('difficulty', 48441, 2, 10.0), -- map 36: Mining Monkey
('template', 23542, 0, 7.5), -- map 568: Amani'shi Axe Thrower
('template', 23577, 0, 35.0), -- map 568: Halazzi
('template', 23580, 0, 7.5), -- map 568: Amani'shi Warbringer
('template', 23581, 0, 7.5), -- map 568: Amani'shi Medicine Man
('template', 23582, 0, 7.5), -- map 568: Amani'shi Tribesman
('template', 23584, 0, 7.5), -- map 568: Amani Bear
('template', 23587, 0, 7.5), -- map 568: Amani'shi Reinforcement
('template', 23596, 0, 7.5), -- map 568: Amani'shi Flame Caster
('template', 23597, 0, 7.5), -- map 568: Amani'shi Guardian
('template', 23774, 0, 7.5), -- map 568: Amani'shi Trainer
('template', 23834, 0, 7.5), -- map 568: Amani Dragonhawk
('template', 23863, 0, 35.0), -- map 568: Daakara
('template', 24043, 0, 7.5), -- map 568: Amani Lynx
('template', 24059, 0, 7.5), -- map 568: Amani'shi Beast Tamer
('template', 24065, 0, 7.5), -- map 568: Amani'shi Handler
('template', 24138, 0, 7.5), -- map 568: Tamed Amani Crocolisk
('template', 24175, 0, 7.5), -- map 568: Amani'shi Lookout
('template', 24179, 0, 7.5), -- map 568: Amani'shi Wind Walker
('template', 24180, 0, 7.5), -- map 568: Amani'shi Protector
('template', 24217, 0, 7.5), -- map 568: Amani Bear Mount
('template', 24374, 0, 7.5), -- map 568: Amani'shi Berserker
('template', 24530, 0, 7.5), -- map 568: Amani Elder Lynx
('template', 24549, 0, 7.5), -- map 568: Amani'shi Tempest
('difficulty', 40579, 2, 8.0), -- map 643: Deep Murloc Hunter
('template', 39616, 0, 8.0), -- map 643: Naz'jar Invader
('template', 40579, 0, 4.0), -- map 643: Deep Murloc Hunter
('template', 40586, 0, 30.0), -- map 643: Lady Naz'jar
('template', 40634, 0, 25.0), -- map 643: Naz'jar Tempest Witch
('template', 40765, 0, 30.0), -- map 643: Commander Ulthok
('template', 40925, 0, 8.0), -- map 643: Tainted Sentry
('template', 40935, 0, 8.0), -- map 643: Gilgoblin Hunter
('template', 40936, 0, 30.0), -- map 643: Faceless Watcher
('template', 41096, 0, 8.0), -- map 643: Naz'jar Spiritmender
('template', 41139, 0, 8.0), -- map 643: Naz'jar Spiritmender
('difficulty', 39731, 2, 90.0), -- map 644: Ammunae
('difficulty', 39804, 2, 10.0), -- map 644: Stone Trogg Pillager
('difficulty', 40251, 2, 10.0), -- map 644: Stone Trogg Brute
('difficulty', 40252, 2, 10.0), -- map 644: Stone Trogg Rock Flinger
('template', 39366, 0, 25.0), -- map 644: Sun-Touched Servant
('template', 39373, 0, 25.0), -- map 644: Sun-Touched Speaker
('template', 39378, 0, 60.0), -- map 644: Rajh
('template', 39425, 0, 60.0), -- map 644: Temple Guardian Anhuur
('template', 39428, 0, 60.0), -- map 644: Earthrager Ptah
('template', 39587, 0, 60.0), -- map 644: Isiset
('template', 39731, 0, 60.0), -- map 644: Ammunae
('template', 39732, 0, 60.0), -- map 644: Setesh
('template', 39788, 0, 60.0), -- map 644: Anraphet
('template', 39804, 0, 5.0), -- map 644: Stone Trogg Pillager
('template', 40033, 0, 25.0), -- map 644: Flux Animator
('template', 40170, 0, 25.0), -- map 644: Spatial Anomaly
('template', 40251, 0, 5.0), -- map 644: Stone Trogg Brute
('template', 40252, 0, 5.0), -- map 644: Stone Trogg Rock Flinger
('template', 40311, 0, 25.0), -- map 644: Dustbone Tormentor
('template', 40715, 0, 25.0), -- map 644: Lifewarden Nymph
('template', 40787, 0, 25.0), -- map 644: Dustbone Horror
('template', 41364, 0, 25.0), -- map 644: Void Lord
('template', 41374, 0, 5.0), -- map 644: Void Wurm
('template', 48139, 0, 25.0), -- map 644: Temple Swiftstalker
('template', 48140, 0, 20.0), -- map 644: Temple Runecaster
('template', 48141, 0, 25.0), -- map 644: Temple Shadowlancer
('template', 48143, 0, 25.0), -- map 644: Temple Fireshaper
('difficulty', 39665, 2, 90.0), -- map 645: Rom'ogg Bonecrusher
('difficulty', 40008, 2, 25.0), -- map 645: Lucky
('difficulty', 40011, 2, 25.0), -- map 645: Spot
('difficulty', 40013, 2, 25.0), -- map 645: Buster
('difficulty', 40084, 2, 6.0), -- map 645: Bellows Slave
('template', 39665, 0, 30.0), -- map 645: Rom'ogg Bonecrusher
('template', 39698, 0, 30.0), -- map 645: Karsh Steelbender
('template', 39700, 0, 30.0), -- map 645: Beauty
('template', 39705, 0, 30.0), -- map 645: Ascendant Lord Obsidius
('template', 39708, 0, 8.0), -- map 645: Twilight Flame Caller
('template', 39978, 0, 8.0), -- map 645: Twilight Torturer
('template', 39980, 0, 8.0), -- map 645: Twilight Sadist
('template', 39982, 0, 8.0), -- map 645: Crazed Mage
('template', 39985, 0, 8.0), -- map 645: Mad Prisoner
('template', 39987, 0, 30.0), -- map 645: Evolved Twilight Zealot
('template', 39990, 0, 8.0), -- map 645: Twilight Zealot
('template', 39994, 0, 8.0), -- map 645: Conflagration
('template', 40008, 0, 12.0), -- map 645: Lucky
('template', 40011, 0, 12.0), -- map 645: Spot
('template', 40013, 0, 12.0), -- map 645: Buster
('template', 40017, 0, 8.0), -- map 645: Twilight Element Warden
('template', 40019, 0, 8.0), -- map 645: Twilight Obsidian Borer
('template', 40021, 0, 8.0), -- map 645: Incendiary Spark
('template', 40023, 0, 8.0), -- map 645: Defiled Earth Rager
('template', 40084, 0, 3.0), -- map 645: Bellows Slave
('template', 43873, 0, 60.0), -- map 657: Altairus
('template', 43875, 0, 60.0), -- map 657: Asaad
('template', 43878, 0, 60.0), -- map 657: Grand Vizier Ertan
('template', 45477, 0, 25.0), -- map 657: Gust Soldier
('template', 45704, 0, 25.0), -- map 657: Lurking Tempest
('template', 45912, 0, 25.0), -- map 657: Wild Vortex
('template', 45915, 0, 25.0), -- map 657: Armored Mistral
('template', 45917, 0, 25.0), -- map 657: Cloud Prince
('template', 45919, 0, 25.0), -- map 657: Young Storm Dragon
('template', 45922, 0, 25.0), -- map 657: Empyrean Assassin
('template', 45924, 0, 25.0), -- map 657: Turbulent Squall
('template', 45926, 0, 25.0), -- map 657: Servant of Asaad
('template', 45928, 0, 25.0), -- map 657: Executor of the Caliph
('template', 45930, 0, 25.0), -- map 657: Minister of Air
('template', 45935, 0, 25.0), -- map 657: Temple Adept
('difficulty', 42428, 2, 6.0), -- map 725: Devout Follower
('difficulty', 42695, 2, 6.0), -- map 725: Stonecore Sentry
('difficulty', 42845, 2, 6.0), -- map 725: Rock Borer
('difficulty', 43662, 2, 6.0), -- map 725: Unbound Earth Rager
('template', 42188, 0, 60.0), -- map 725: Ozruk
('template', 42333, 0, 60.0), -- map 725: High Priestess Azil
('template', 42428, 0, 3.0), -- map 725: Devout Follower
('template', 42691, 0, 30.0), -- map 725: Stonecore Rift Conjurer
('template', 42695, 0, 3.0), -- map 725: Stonecore Sentry
('template', 42696, 0, 30.0), -- map 725: Stonecore Warbringer
('template', 42789, 0, 30.0), -- map 725: Stonecore Magmalord
('template', 42808, 0, 30.0), -- map 725: Stonecore Flayer
('template', 42845, 0, 3.0), -- map 725: Rock Borer
('template', 43214, 0, 60.0), -- map 725: Slabhide
('template', 43430, 0, 20.0), -- map 725: Stonecore Berserker
('template', 43438, 0, 60.0), -- map 725: Corborus
('template', 43537, 0, 30.0), -- map 725: Stonecore Earthshaper
('template', 43662, 0, 3.0), -- map 725: Unbound Earth Rager
('template', 43612, 0, 60.0), -- map 755: High Prophet Barim
('template', 43614, 0, 60.0), -- map 755: Lockmaw
('template', 44577, 0, 60.0), -- map 755: General Husam
('template', 44819, 0, 60.0), -- map 755: Siamat
('template', 44896, 0, 25.0), -- map 755: Pygmy Brute
('template', 44898, 0, 25.0), -- map 755: Pygmy Firebreather
('template', 44922, 0, 25.0), -- map 755: Oathsworn Axemaster
('template', 44924, 0, 25.0), -- map 755: Oathsworn Myrmidon
('template', 44926, 0, 25.0), -- map 755: Oathsworn Wanderer
('template', 44932, 0, 25.0), -- map 755: Oathsworn Pathfinder
('template', 44976, 0, 25.0), -- map 755: Neferset Plaguebringer
('template', 44977, 0, 20.0), -- map 755: Neferset Torturer
('template', 44980, 0, 25.0), -- map 755: Neferset Theurgist
('template', 44981, 0, 20.0), -- map 755: Oathsworn Skinner
('template', 44982, 0, 25.0), -- map 755: Neferset Darkcaster
('template', 45007, 0, 4.0), -- map 755: Enslaved Bandit
('template', 45062, 0, 20.0), -- map 755: Oathsworn Scorpid Keeper
('template', 49045, 0, 55.0), -- map 755: Augh
('template', 52089, 0, 5.0), -- map 859: Gurubashi Worker
('template', 52402, 0, 5.0); -- map 859: Venomtooth

UPDATE `creature_template` AS `ct`
INNER JOIN `_cata_dungeon_damage_fix` AS `fix`
    ON `fix`.`target` = 'template'
   AND `fix`.`entry` = `ct`.`entry`
SET `ct`.`dmg_multiplier` = `fix`.`damage_mod`
WHERE `ct`.`dmg_multiplier` > `fix`.`damage_mod` * 1.10;

UPDATE `creature_difficulty` AS `cd`
INNER JOIN `_cata_dungeon_damage_fix` AS `fix`
    ON `fix`.`target` = 'difficulty'
   AND `fix`.`entry` = `cd`.`id`
   AND `fix`.`difficulty` = `cd`.`difficulty`
SET `cd`.`damage_mod` = `fix`.`damage_mod`
WHERE `cd`.`damage_mod` > `fix`.`damage_mod` * 1.10;

DROP TEMPORARY TABLE `_cata_dungeon_damage_fix`;
