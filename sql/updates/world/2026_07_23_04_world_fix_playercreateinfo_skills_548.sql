-- This table was imported from Trinity 4.3.4 in project commit 1012ca1d.
-- Build-18414 SkillLine.dbc no longer contains the 30 old specialization
-- SkillLines or Thrown (176), and uses different general class SkillLines for
-- Warrior, Warlock, Mage, Rogue and Shaman. It also contains Monk (829).

CREATE TABLE IF NOT EXISTS
`_backup_playercreateinfo_skills_invalid_20260723`
LIKE `playercreateinfo_skills`;

INSERT IGNORE INTO `_backup_playercreateinfo_skills_invalid_20260723`
SELECT *
FROM `playercreateinfo_skills`
WHERE (`raceMask`, `classMask`, `skill`, `rank`) IN
      ((0, 128, 6, 0),
       (0, 128, 8, 0),
       (0, 1, 26, 0),
       (0, 8, 38, 0),
       (0, 8, 39, 0),
       (0, 4, 50, 0),
       (0, 4, 51, 0),
       (0, 16, 56, 0),
       (0, 16, 78, 0),
       (0, 1024, 134, 0),
       (0, 4, 163, 0),
       (0, 9, 176, 0),
       (0, 2, 184, 0),
       (0, 128, 237, 0),
       (0, 8, 253, 0),
       (0, 1, 256, 0),
       (0, 1, 257, 0),
       (0, 2, 267, 0),
       (0, 256, 354, 0),
       (0, 256, 355, 0),
       (0, 64, 373, 0),
       (0, 64, 374, 0),
       (0, 64, 375, 0),
       (0, 1024, 573, 0),
       (0, 1024, 574, 0),
       (0, 256, 593, 0),
       (0, 2, 594, 0),
       (0, 16, 613, 0),
       (0, 32, 770, 0),
       (0, 32, 771, 0),
       (0, 32, 772, 0),
       (0, 8, 797, 0),
       (0, 128, 799, 0),
       (0, 64, 801, 0),
       (0, 256, 802, 0),
       (0, 1, 803, 0));

DELETE `pci`
FROM `playercreateinfo_skills` AS `pci`
INNER JOIN `_backup_playercreateinfo_skills_invalid_20260723` AS `backup`
  ON `backup`.`raceMask` = `pci`.`raceMask`
 AND `backup`.`classMask` = `pci`.`classMask`
 AND `backup`.`skill` = `pci`.`skill`;

INSERT IGNORE INTO `playercreateinfo_skills`
(`raceMask`, `classMask`, `skill`, `rank`, `comment`)
VALUES
(0, 1, 840, 0, 'Warrior - General'),
(0, 8, 921, 0, 'Rogue - General'),
(0, 64, 924, 0, 'Shaman - General'),
(0, 128, 904, 0, 'Mage - General'),
(0, 256, 849, 0, 'Warlock - General'),
(0, 512, 829, 0, 'Monk - General');
