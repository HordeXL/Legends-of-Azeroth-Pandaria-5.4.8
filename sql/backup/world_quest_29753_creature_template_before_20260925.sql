mysqldump: [Warning] Using a password on the command line interface can be insecure.
-- MySQL dump 10.13  Distrib 5.7.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: world
-- ------------------------------------------------------
-- Server version	5.7.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `creature_template`
--

DROP TABLE IF EXISTS `creature_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `creature_template` (
  `entry` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `difficulty_entry_1` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `difficulty_entry_2` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `difficulty_entry_3` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `difficulty_entry_4` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `difficulty_entry_5` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `KillCredit1` int(10) unsigned NOT NULL DEFAULT '0',
  `KillCredit2` int(10) unsigned NOT NULL DEFAULT '0',
  `name` char(100) CHARACTER SET utf8 NOT NULL DEFAULT '0',
  `femaleName` char(100) CHARACTER SET utf8 NOT NULL DEFAULT '0',
  `subname` char(100) CHARACTER SET utf8 DEFAULT NULL,
  `IconName` char(100) CHARACTER SET utf8 DEFAULT NULL,
  `gossip_menu_id` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `minlevel` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `maxlevel` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `exp` smallint(6) NOT NULL DEFAULT '0',
  `exp_unk` smallint(6) NOT NULL DEFAULT '0',
  `faction` smallint(5) unsigned NOT NULL DEFAULT '0',
  `npcflag` bigint(20) unsigned NOT NULL DEFAULT '0',
  `npcflag2` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_walk` float NOT NULL DEFAULT '1' COMMENT 'Result of 2.5/2.5, most common value',
  `speed_run` float NOT NULL DEFAULT '1.14286' COMMENT 'Result of 8.0/7.0, most common value',
  `scale` float NOT NULL DEFAULT '1',
  `rank` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `mindmg` float NOT NULL DEFAULT '0',
  `maxdmg` float NOT NULL DEFAULT '0',
  `dmgschool` tinyint(4) NOT NULL DEFAULT '0',
  `attackpower` int(10) unsigned NOT NULL DEFAULT '0',
  `dmg_multiplier` float NOT NULL DEFAULT '1',
  `BaseAttackTime` int(10) unsigned NOT NULL DEFAULT '0',
  `RangeAttackTime` int(10) unsigned NOT NULL DEFAULT '0',
  `unit_class` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `unit_flags` int(10) unsigned NOT NULL DEFAULT '0',
  `unit_flags2` int(10) unsigned NOT NULL DEFAULT '0',
  `dynamicflags` int(10) unsigned NOT NULL DEFAULT '0',
  `family` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `trainer_type` tinyint(4) NOT NULL DEFAULT '0',
  `trainer_class` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `trainer_race` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `minrangedmg` float NOT NULL DEFAULT '0',
  `maxrangedmg` float NOT NULL DEFAULT '0',
  `rangedattackpower` smallint(5) unsigned NOT NULL DEFAULT '0',
  `type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `type_flags` int(10) unsigned NOT NULL DEFAULT '0',
  `type_flags2` int(10) unsigned NOT NULL DEFAULT '0',
  `lootid` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `pickpocketloot` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `skinloot` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `resistance1` smallint(6) NOT NULL DEFAULT '0',
  `resistance2` smallint(6) NOT NULL DEFAULT '0',
  `resistance3` smallint(6) NOT NULL DEFAULT '0',
  `resistance4` smallint(6) NOT NULL DEFAULT '0',
  `resistance5` smallint(6) NOT NULL DEFAULT '0',
  `resistance6` smallint(6) NOT NULL DEFAULT '0',
  `spell1` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell2` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell3` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell4` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell5` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell6` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell7` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `spell8` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `PetSpellDataId` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `VehicleId` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `mingold` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `maxgold` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `AIName` char(64) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `MovementType` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `HoverHeight` float NOT NULL DEFAULT '1',
  `Health_mod` float NOT NULL DEFAULT '1',
  `Mana_mod` float NOT NULL DEFAULT '1',
  `Mana_mod_extra` float NOT NULL DEFAULT '1',
  `Armor_mod` float NOT NULL DEFAULT '1',
  `RacialLeader` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `questItem1` int(10) unsigned NOT NULL DEFAULT '0',
  `questItem2` int(10) unsigned NOT NULL DEFAULT '0',
  `questItem3` int(10) unsigned NOT NULL DEFAULT '0',
  `questItem4` int(10) unsigned NOT NULL DEFAULT '0',
  `questItem5` int(10) unsigned NOT NULL DEFAULT '0',
  `questItem6` int(10) unsigned NOT NULL DEFAULT '0',
  `movementId` int(10) unsigned NOT NULL DEFAULT '0',
  `RegenHealth` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `VignetteID` int(10) unsigned NOT NULL DEFAULT '0',
  `TrackingQuestID` int(10) unsigned NOT NULL DEFAULT '0',
  `mechanic_immune_mask` int(10) unsigned NOT NULL DEFAULT '0',
  `flags_extra` int(10) unsigned NOT NULL DEFAULT '0',
  `ScriptName` char(64) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `VerifiedBuild` smallint(6) DEFAULT '18414',
  PRIMARY KEY (`entry`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='Creature System';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `creature_template`
--
-- WHERE:  entry IN (55787,55790)

LOCK TABLES `creature_template` WRITE;
/*!40000 ALTER TABLE `creature_template` DISABLE KEYS */;
INSERT INTO `creature_template` VALUES (55787,0,0,0,0,0,0,0,'Peaceful Beast Spirit','0',NULL,NULL,0,85,85,4,0,35,0,0,1,1.14286,1,0,4328,7359,0,43,1,2000,2000,1,0,0,0,0,0,0,0,0,0,43,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,'',18414),(55790,0,0,0,0,0,0,0,'Raging Beast Spirit','0',NULL,NULL,0,85,85,4,0,14,0,0,1,1.14286,1,0,4328,7359,0,20753,1,2000,2000,1,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,115549,0,0,0,0,0,0,0,0,0,0,0,'SmartAI',1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,'',18414);
/*!40000 ALTER TABLE `creature_template` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-25  0:37:24
