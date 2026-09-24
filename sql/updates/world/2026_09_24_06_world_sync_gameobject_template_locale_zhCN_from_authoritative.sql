-- Sync gameobject_template_locale zhCN names with authoritative translations
-- Date: 2026-09-24 | DB: world @127.0.0.1
-- Problem: 124 GO entries kept English/doodad-resource names in zhCN although the same
--          English name has an official zhCN in creature_template_locale (NPC),
--          item_template_locale or quest_template_locale (majority vote).
-- Policy: zhCN only; one name-value per entry list below.
--
UPDATE `gameobject_template_locale` SET `name` = '毒蛇结界' WHERE `locale`='zhCN' AND `entry` IN (2067); -- Serpent Ward
UPDATE `gameobject_template_locale` SET `name` = '拉文凯斯投石车' WHERE `locale`='zhCN' AND `entry` IN (2558); -- Test
UPDATE `gameobject_template_locale` SET `name` = '木材堆' WHERE `locale`='zhCN' AND `entry` IN (2888); -- Woodpile
UPDATE `gameobject_template_locale` SET `name` = '火盆' WHERE `locale`='zhCN' AND `entry` IN (175290,175291,175295,175296,175306,175528,175529,175530,175531,175532,175533); -- Brazier
UPDATE `gameobject_template_locale` SET `name` = '天灾建筑' WHERE `locale`='zhCN' AND `entry` IN (177674); -- Scourge Structure
UPDATE `gameobject_template_locale` SET `name` = '巫术聚焦器' WHERE `locale`='zhCN' AND `entry` IN (184300); -- Necromantic Focus
UPDATE `gameobject_template_locale` SET `name` = '灼热大地' WHERE `locale`='zhCN' AND `entry` IN (186392); -- Scorched Earth
UPDATE `gameobject_template_locale` SET `name` = '大炮' WHERE `locale`='zhCN' AND `entry` IN (187119); -- The Big Gun
UPDATE `gameobject_template_locale` SET `name` = '天灾囚犯' WHERE `locale`='zhCN' AND `entry` IN (187853); -- Scourge Prisoner
UPDATE `gameobject_template_locale` SET `name` = '井' WHERE `locale`='zhCN' AND `entry` IN (193904); -- Well
UPDATE `gameobject_template_locale` SET `name` = '虫洞' WHERE `locale`='zhCN' AND `entry` IN (195570); -- Wormhole
UPDATE `gameobject_template_locale` SET `name` = '447焰火' WHERE `locale`='zhCN' AND `entry` IN (201745); -- 447 Fire
UPDATE `gameobject_template_locale` SET `name` = '鹰风酋长的母亲' WHERE `locale`='zhCN' AND `entry` IN (202139); -- Greatmother Hawkwind
UPDATE `gameobject_template_locale` SET `name` = '新生豆荚' WHERE `locale`='zhCN' AND `entry` IN (202962); -- Seedling Pod
UPDATE `gameobject_template_locale` SET `name` = '绳子' WHERE `locale`='zhCN' AND `entry` IN (204427,214252,223282); -- Rope
UPDATE `gameobject_template_locale` SET `name` = '扎拉赞恩的尸体' WHERE `locale`='zhCN' AND `entry` IN (205066); -- Zalazane's Remains
UPDATE `gameobject_template_locale` SET `name` = '寻找并摧毁' WHERE `locale`='zhCN' AND `entry` IN (206046); -- Seek and Destroy
UPDATE `gameobject_template_locale` SET `name` = '司克诺兹轰炸机' WHERE `locale`='zhCN' AND `entry` IN (206507); -- Schnottz Bomber
UPDATE `gameobject_template_locale` SET `name` = '绳梯' WHERE `locale`='zhCN' AND `entry` IN (206985,216077,218416); -- Rope Ladder
UPDATE `gameobject_template_locale` SET `name` = '割裂' WHERE `locale`='zhCN' AND `entry` IN (207347); -- Rupture
UPDATE `gameobject_template_locale` SET `name` = '幽暗的营火' WHERE `locale`='zhCN' AND `entry` IN (207432,238758); -- Grim Campfire
UPDATE `gameobject_template_locale` SET `name` = '苦果炸弹' WHERE `locale`='zhCN' AND `entry` IN (208546); -- The Bitter Pill
UPDATE `gameobject_template_locale` SET `name` = '裴智之杖' WHERE `locale`='zhCN' AND `entry` IN (209629); -- Staff of Pei-Zhi
UPDATE `gameobject_template_locale` SET `name` = '智慧卷轴' WHERE `locale`='zhCN' AND `entry` IN (209657,209658,209659); -- Scroll of Wisdom
UPDATE `gameobject_template_locale` SET `name` = '玉琮' WHERE `locale`='zhCN' AND `entry` IN (209699); -- Jade Cong
UPDATE `gameobject_template_locale` SET `name` = '熊猫人盛宴' WHERE `locale`='zhCN' AND `entry` IN (209805); -- Great Pandaren Banquet
UPDATE `gameobject_template_locale` SET `name` = '禅心莲' WHERE `locale`='zhCN' AND `entry` IN (209827,209828,209829,209830); -- Zen Lotus
UPDATE `gameobject_template_locale` SET `name` = '鲜绿树枝' WHERE `locale`='zhCN' AND `entry` IN (209903); -- Green Branch
UPDATE `gameobject_template_locale` SET `name` = '翔龙蛋' WHERE `locale`='zhCN' AND `entry` IN (210238,210239,210240); -- Serpent Egg
UPDATE `gameobject_template_locale` SET `name` = '影光松露' WHERE `locale`='zhCN' AND `entry` IN (210810,210811,210812); -- Shadelight Truffle
UPDATE `gameobject_template_locale` SET `name` = '菜瓜' WHERE `locale`='zhCN' AND `entry` IN (210979,210980); -- Striped Melon
UPDATE `gameobject_template_locale` SET `name` = '金火兰' WHERE `locale`='zhCN' AND `entry` IN (211025); -- Goldenfire Orchid
UPDATE `gameobject_template_locale` SET `name` = '岩石' WHERE `locale`='zhCN' AND `entry` IN (211305,214361); -- Rocks
UPDATE `gameobject_template_locale` SET `name` = '龙头扳手' WHERE `locale`='zhCN' AND `entry` IN (211326); -- Tap Tool
UPDATE `gameobject_template_locale` SET `name` = '生锈的洒水壶' WHERE `locale`='zhCN' AND `entry` IN (211330); -- Rusty Watering Can
UPDATE `gameobject_template_locale` SET `name` = '日光爬行者' WHERE `locale`='zhCN' AND `entry` IN (211474); -- Suncrawler
UPDATE `gameobject_template_locale` SET `name` = '野牛人油桶' WHERE `locale`='zhCN' AND `entry` IN (212003); -- Yaungol Oil Barrel
UPDATE `gameobject_template_locale` SET `name` = '卓金路障' WHERE `locale`='zhCN' AND `entry` IN (212013); -- Zouchin Barricade
UPDATE `gameobject_template_locale` SET `name` = '影踪派弩箭束' WHERE `locale`='zhCN' AND `entry` IN (212134); -- Shado-Pan Crossbow Bolt Bundle
UPDATE `gameobject_template_locale` SET `name` = '影踪派火箭' WHERE `locale`='zhCN' AND `entry` IN (212135,212136); -- Shado-Pan Fire Arrows
UPDATE `gameobject_template_locale` SET `name` = '高家军路障' WHERE `locale`='zhCN' AND `entry` IN (212156); -- Gao-Ran Barricade
UPDATE `gameobject_template_locale` SET `name` = '影踪派绳索' WHERE `locale`='zhCN' AND `entry` IN (212229,215393); -- Shado-Pan Rope
UPDATE `gameobject_template_locale` SET `name` = '山泽石板' WHERE `locale`='zhCN' AND `entry` IN (212318,212319); -- Shan'ze Tablet
UPDATE `gameobject_template_locale` SET `name` = '预言之卷' WHERE `locale`='zhCN' AND `entry` IN (212388,212389); -- Scroll of Auspice
UPDATE `gameobject_template_locale` SET `name` = '魔古的黑心' WHERE `locale`='zhCN' AND `entry` IN (212529); -- The Dark Heart of the Mogu
UPDATE `gameobject_template_locale` SET `name` = '刘浪之歌' WHERE `locale`='zhCN' AND `entry` IN (212537); -- The Ballad of Liu Lang
UPDATE `gameobject_template_locale` SET `name` = '红宝石眼睛' WHERE `locale`='zhCN' AND `entry` IN (212759,212760,212761); -- Ruby Eye
UPDATE `gameobject_template_locale` SET `name` = '郭莱符文石' WHERE `locale`='zhCN' AND `entry` IN (213180); -- Guo-Lai Runestone
UPDATE `gameobject_template_locale` SET `name` = '疑虑之种' WHERE `locale`='zhCN' AND `entry` IN (213183); -- Seed of Doubt
UPDATE `gameobject_template_locale` SET `name` = '格萨尼石板' WHERE `locale`='zhCN' AND `entry` IN (213314); -- Gurthani Tablet
UPDATE `gameobject_template_locale` SET `name` = '蜥蜴人石板' WHERE `locale`='zhCN' AND `entry` IN (213750); -- Saurok Stone Tablet
UPDATE `gameobject_template_locale` SET `name` = '云壬的石板' WHERE `locale`='zhCN' AND `entry` IN (213765); -- Tablet of Ren Yun
UPDATE `gameobject_template_locale` SET `name` = '猢狲战士长矛' WHERE `locale`='zhCN' AND `entry` IN (213768); -- Hozen Warrior Spear
UPDATE `gameobject_template_locale` SET `name` = '陶俑头颅' WHERE `locale`='zhCN' AND `entry` IN (213782); -- Terracotta Head
UPDATE `gameobject_template_locale` SET `name` = '风暴烈酒秘方' WHERE `locale`='zhCN' AND `entry` IN (213795); -- Stormstout Secrets
UPDATE `gameobject_template_locale` SET `name` = '野牛人携火者' WHERE `locale`='zhCN' AND `entry` IN (213960); -- Yaungol Fire Carrier
UPDATE `gameobject_template_locale` SET `name` = '卡诺兹的虫群砍刀' WHERE `locale`='zhCN' AND `entry` IN (213968); -- Swarming Cleaver of Ka'roz
UPDATE `gameobject_template_locale` SET `name` = '虫群卫士奖章' WHERE `locale`='zhCN' AND `entry` IN (213971); -- Swarmkeeper's Medallion
UPDATE `gameobject_template_locale` SET `name` = '烧烤盛宴' WHERE `locale`='zhCN' AND `entry` IN (214241); -- Great Banquet of the Grill
UPDATE `gameobject_template_locale` SET `name` = '烹炒盛宴' WHERE `locale`='zhCN' AND `entry` IN (214243); -- Great Banquet of the Wok
UPDATE `gameobject_template_locale` SET `name` = '炖煮盛宴' WHERE `locale`='zhCN' AND `entry` IN (214245); -- Great Banquet of the Pot
UPDATE `gameobject_template_locale` SET `name` = '蒸烧盛宴' WHERE `locale`='zhCN' AND `entry` IN (214247); -- Great Banquet of the Steamer
UPDATE `gameobject_template_locale` SET `name` = '烘焙盛宴' WHERE `locale`='zhCN' AND `entry` IN (214249,215901); -- Great Banquet of the Oven
UPDATE `gameobject_template_locale` SET `name` = '酿造盛宴' WHERE `locale`='zhCN' AND `entry` IN (214251); -- Great Banquet of the Brew
UPDATE `gameobject_template_locale` SET `name` = '落日堡垒' WHERE `locale`='zhCN' AND `entry` IN (214358,214363,214376); -- Setting Sun Garrison
UPDATE `gameobject_template_locale` SET `name` = '染煞水晶' WHERE `locale`='zhCN' AND `entry` IN (214562); -- Sha-Haunted Crystal
UPDATE `gameobject_template_locale` SET `name` = '煞能腐蚀' WHERE `locale`='zhCN' AND `entry` IN (214643); -- Sha Corruption
UPDATE `gameobject_template_locale` SET `name` = '邪煞池' WHERE `locale`='zhCN' AND `entry` IN (214818); -- Sha Pool
UPDATE `gameobject_template_locale` SET `name` = '龙鳞菇' WHERE `locale`='zhCN' AND `entry` IN (214843,214844); -- Serpent's Scale
UPDATE `gameobject_template_locale` SET `name` = '禅之球' WHERE `locale`='zhCN' AND `entry` IN (214974); -- Zen Sphere
UPDATE `gameobject_template_locale` SET `name` = '张·泥皮' WHERE `locale`='zhCN' AND `entry` IN (215854); -- Zhang Marlfur
UPDATE `gameobject_template_locale` SET `name` = '夺日者监视结界' WHERE `locale`='zhCN' AND `entry` IN (217758); -- Sunreaver Perimeter Ward
UPDATE `gameobject_template_locale` SET `name` = '重生的古拉' WHERE `locale`='zhCN' AND `entry` IN (218081); -- Gura the Reclaimed
UPDATE `gameobject_template_locale` SET `name` = '工坊报告' WHERE `locale`='zhCN' AND `entry` IN (218084); -- Workshop Orders
UPDATE `gameobject_template_locale` SET `name` = '恐龙神像' WHERE `locale`='zhCN' AND `entry` IN (218372,218373); -- Saur Fetish
UPDATE `gameobject_template_locale` SET `name` = '战术魔法炸弹' WHERE `locale`='zhCN' AND `entry` IN (218731,218732,218733,218734,218735,218736); -- Tactical Mana Bomb
UPDATE `gameobject_template_locale` SET `name` = '罗曼斯的咒术之书' WHERE `locale`='zhCN' AND `entry` IN (218836); -- Rommath's Book of Incantations
UPDATE `gameobject_template_locale` SET `name` = '大块头4000型' WHERE `locale`='zhCN' AND `entry` IN (220201); -- The Big One 4000
UPDATE `gameobject_template_locale` SET `name` = '秘藏的潘达利亚战利品' WHERE `locale`='zhCN' AND `entry` IN (220823); -- Secured Stockpile of Pandaren Spoils
UPDATE `gameobject_template_locale` SET `name` = '水下宝藏' WHERE `locale`='zhCN' AND `entry` IN (220832); -- Sunken Treasure
UPDATE `gameobject_template_locale` SET `name` = '破烂的笔记' WHERE `locale`='zhCN' AND `entry` IN (222795); -- Tattered Note
UPDATE `gameobject_template_locale` SET `name` = '灰谷橡树' WHERE `locale`='zhCN' AND `entry` IN (301008); -- Ashenvale Oak
