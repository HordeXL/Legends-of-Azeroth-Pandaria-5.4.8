-- 5.4.8 instance reward difficulty audit. JournalEncounterItem supplies item variants.
-- Keep existing chances, groups and quantities. Remove wrong-mode duplicates rather than creating extra drops.
START TRANSACTION;
CREATE TEMPORARY TABLE instance_reward_modes (entry INT UNSIGNED, item INT UNSIGNED, old_mask INT UNSIGNED, new_mask INT UNSIGNED, PRIMARY KEY(entry,item,old_mask));
INSERT INTO instance_reward_modes VALUES
(22930,31554,0,4), -- Yor
(22930,31562,0,4), -- Yor
(22930,31570,0,4), -- Yor
(22930,31578,0,4), -- Yor
(22930,31919,0,4), -- Yor
(22930,31920,0,4), -- Yor
(22930,31921,0,4), -- Yor
(22930,31922,0,4), -- Yor
(22930,31923,0,4), -- Yor
(22930,31924,0,4), -- Yor
(23035,32769,0,4), -- Anzu
(23035,32778,0,4), -- Anzu
(23035,32779,0,4), -- Anzu
(23035,32780,0,4), -- Anzu
(23035,32781,0,4), -- Anzu
(24664,34625,4,2), -- Kael'thas Sunstrider
(24664,34793,4,2), -- Kael'thas Sunstrider
(24664,34794,4,2), -- Kael'thas Sunstrider
(24664,34795,4,2), -- Kael'thas Sunstrider
(24664,34796,4,2), -- Kael'thas Sunstrider
(24664,34807,4,2), -- Kael'thas Sunstrider
(24664,34808,4,2), -- Kael'thas Sunstrider
(24664,34810,4,2), -- Kael'thas Sunstrider
(24723,34697,4,2), -- Selin Fireheart
(24723,34698,4,2), -- Selin Fireheart
(24723,34700,4,2), -- Selin Fireheart
(24723,34701,4,2), -- Selin Fireheart
(24723,34702,4,2), -- Selin Fireheart
(26693,44151,2,4), -- Skadi the Ruthless
(26796,37728,2,4), -- Commander Stoutbeard
(26796,37729,2,4), -- Commander Stoutbeard
(26796,37730,2,4), -- Commander Stoutbeard
(26796,37731,2,4), -- Commander Stoutbeard
(26798,37728,2,4), -- Commander Kolurg
(26798,37729,2,4), -- Commander Kolurg
(26798,37730,2,4), -- Commander Kolurg
(26798,37731,2,4), -- Commander Kolurg
(29120,37238,2,4), -- Anub'arak
(29304,37626,2,4), -- Slad'ran
(29304,37627,2,4), -- Slad'ran
(29304,37628,2,4), -- Slad'ran
(29304,37629,2,4), -- Slad'ran
(29932,43310,0,4), -- Eck the Ferocious
(29932,43311,0,4), -- Eck the Ferocious
(29932,43312,0,4), -- Eck the Ferocious
(29932,43313,0,4), -- Eck the Ferocious
(30258,43284,2,4), -- Amanitar
(30258,43285,2,4), -- Amanitar
(30258,43286,2,4), -- Amanitar
(30258,43287,2,4), -- Amanitar
(3586,5443,0,2), -- [UNUSED 4.x ]Miner Johnson
(3586,5444,0,2), -- [UNUSED 4.x ]Miner Johnson
(3872,6641,0,2), -- Deathsworn Captain
(3872,6642,0,2), -- Deathsworn Captain
(49045,56389,0,4), -- Augh
(49045,56390,0,4), -- Augh
(49045,56391,0,4), -- Augh
(49045,56392,0,4), -- Augh
(49045,56393,0,4), -- Augh
(49541,63478,0,4), -- Vanessa VanCleef
(49541,63479,0,4), -- Vanessa VanCleef
(49541,63482,0,4), -- Vanessa VanCleef
(49541,63483,0,4), -- Vanessa VanCleef
(49541,63484,0,4), -- Vanessa VanCleef
(49541,63485,0,4), -- Vanessa VanCleef
(49541,63486,0,4), -- Vanessa VanCleef
(49541,65178,0,4), -- Vanessa VanCleef
(56541,80911,0,2), -- Master Snowdrift
(56541,80912,0,2), -- Master Snowdrift
(56541,80937,0,2), -- Master Snowdrift
(56541,81087,0,4), -- Master Snowdrift
(56541,81101,0,4), -- Master Snowdrift
(56541,81108,0,4), -- Master Snowdrift
(56541,81181,0,4), -- Master Snowdrift
(56541,81182,0,4), -- Master Snowdrift
(56884,80916,0,2), -- Taran Zhu
(56884,80917,0,2), -- Taran Zhu
(56884,80918,0,2), -- Taran Zhu
(56884,80919,0,2), -- Taran Zhu
(56884,80935,0,2), -- Taran Zhu
(56884,80936,0,2), -- Taran Zhu
(56884,81093,0,4), -- Taran Zhu
(56884,81096,0,4), -- Taran Zhu
(56884,81099,0,4), -- Taran Zhu
(56884,81103,0,4), -- Taran Zhu
(56884,81107,0,4), -- Taran Zhu
(56884,81114,0,4), -- Taran Zhu
(56884,81186,0,4), -- Taran Zhu
(56884,81187,0,4), -- Taran Zhu
(56884,81188,0,4), -- Taran Zhu
(56884,81189,0,4), -- Taran Zhu
(56884,87543,0,4), -- Taran Zhu
(58633,88335,4,2), -- Instructor Chillheart
(58633,88336,4,2), -- Instructor Chillheart
(58633,88337,4,2), -- Instructor Chillheart
(58633,88338,4,2), -- Instructor Chillheart
(58633,88339,4,2), -- Instructor Chillheart
(61421,86047,0,24), -- Zian of the Endless Shadow
(61421,86071,0,24), -- Zian of the Endless Shadow
(61421,86075,0,24), -- Zian of the Endless Shadow
(61421,86076,0,24), -- Zian of the Endless Shadow
(61421,86080,0,24), -- Zian of the Endless Shadow
(61421,86081,0,24), -- Zian of the Endless Shadow
(61421,86082,0,24), -- Zian of the Endless Shadow
(61421,86083,0,24), -- Zian of the Endless Shadow
(61421,86084,0,24), -- Zian of the Endless Shadow
(61421,86086,0,24), -- Zian of the Endless Shadow
(61421,86127,0,24), -- Zian of the Endless Shadow
(61421,86128,0,24), -- Zian of the Endless Shadow
(61421,86129,0,24), -- Zian of the Endless Shadow
(61421,86776,0,128), -- Zian of the Endless Shadow
(61421,86777,0,128), -- Zian of the Endless Shadow
(61421,86778,0,128), -- Zian of the Endless Shadow
(61421,86779,0,128), -- Zian of the Endless Shadow
(61421,86780,0,128), -- Zian of the Endless Shadow
(61421,86781,0,128), -- Zian of the Endless Shadow
(61421,86782,0,128), -- Zian of the Endless Shadow
(61421,86783,0,128), -- Zian of the Endless Shadow
(61421,86784,0,128), -- Zian of the Endless Shadow
(61421,86785,0,128), -- Zian of the Endless Shadow
(61421,86786,0,128), -- Zian of the Endless Shadow
(61421,86787,0,128), -- Zian of the Endless Shadow
(61421,86788,0,128), -- Zian of the Endless Shadow
(61421,87044,0,96), -- Zian of the Endless Shadow
(61421,87045,0,96), -- Zian of the Endless Shadow
(61421,87046,0,96), -- Zian of the Endless Shadow
(61421,87047,0,96), -- Zian of the Endless Shadow
(61421,87048,0,96), -- Zian of the Endless Shadow
(61421,87049,0,96), -- Zian of the Endless Shadow
(61421,87050,0,96), -- Zian of the Endless Shadow
(61421,87051,0,96), -- Zian of the Endless Shadow
(61421,87052,0,96), -- Zian of the Endless Shadow
(61421,87053,0,96), -- Zian of the Endless Shadow
(61421,87054,0,96), -- Zian of the Endless Shadow
(61421,87055,0,96), -- Zian of the Endless Shadow
(61421,87056,0,96), -- Zian of the Endless Shadow
(61421,89818,0,24), -- Zian of the Endless Shadow
(61421,89819,0,24), -- Zian of the Endless Shadow
(61421,89935,0,96), -- Zian of the Endless Shadow
(61421,89936,0,96), -- Zian of the Endless Shadow
(61421,89970,0,128), -- Zian of the Endless Shadow
(61421,89971,0,128), -- Zian of the Endless Shadow
(61423,86047,0,24), -- Qiang the Merciless
(61423,86071,0,24), -- Qiang the Merciless
(61423,86075,0,24), -- Qiang the Merciless
(61423,86076,0,24), -- Qiang the Merciless
(61423,86080,0,24), -- Qiang the Merciless
(61423,86081,0,24), -- Qiang the Merciless
(61423,86082,0,24), -- Qiang the Merciless
(61423,86083,0,24), -- Qiang the Merciless
(61423,86084,0,24), -- Qiang the Merciless
(61423,86086,0,24), -- Qiang the Merciless
(61423,86127,0,24), -- Qiang the Merciless
(61423,86128,0,24), -- Qiang the Merciless
(61423,86129,0,24), -- Qiang the Merciless
(61423,86776,0,128), -- Qiang the Merciless
(61423,86777,0,128), -- Qiang the Merciless
(61423,86778,0,128), -- Qiang the Merciless
(61423,86779,0,128), -- Qiang the Merciless
(61423,86780,0,128), -- Qiang the Merciless
(61423,86781,0,128), -- Qiang the Merciless
(61423,86782,0,128), -- Qiang the Merciless
(61423,86783,0,128), -- Qiang the Merciless
(61423,86784,0,128), -- Qiang the Merciless
(61423,86785,0,128), -- Qiang the Merciless
(61423,86786,0,128), -- Qiang the Merciless
(61423,86787,0,128), -- Qiang the Merciless
(61423,86788,0,128), -- Qiang the Merciless
(61423,87044,0,96), -- Qiang the Merciless
(61423,87045,0,96), -- Qiang the Merciless
(61423,87046,0,96), -- Qiang the Merciless
(61423,87047,0,96), -- Qiang the Merciless
(61423,87048,0,96), -- Qiang the Merciless
(61423,87049,0,96), -- Qiang the Merciless
(61423,87050,0,96), -- Qiang the Merciless
(61423,87051,0,96), -- Qiang the Merciless
(61423,87052,0,96), -- Qiang the Merciless
(61423,87053,0,96), -- Qiang the Merciless
(61423,87054,0,96), -- Qiang the Merciless
(61423,87055,0,96), -- Qiang the Merciless
(61423,87056,0,96), -- Qiang the Merciless
(61423,89818,0,24), -- Qiang the Merciless
(61423,89819,0,24), -- Qiang the Merciless
(61423,89935,0,96), -- Qiang the Merciless
(61423,89936,0,96), -- Qiang the Merciless
(61423,89970,0,128), -- Qiang the Merciless
(61423,89971,0,128), -- Qiang the Merciless
(61427,86047,0,24), -- Subetai the Swift
(61427,86071,0,24), -- Subetai the Swift
(61427,86075,0,24), -- Subetai the Swift
(61427,86076,0,24), -- Subetai the Swift
(61427,86080,0,24), -- Subetai the Swift
(61427,86081,0,24), -- Subetai the Swift
(61427,86082,0,24), -- Subetai the Swift
(61427,86083,0,24), -- Subetai the Swift
(61427,86084,0,24), -- Subetai the Swift
(61427,86086,0,24), -- Subetai the Swift
(61427,86127,0,24), -- Subetai the Swift
(61427,86128,0,24), -- Subetai the Swift
(61427,86129,0,24), -- Subetai the Swift
(61427,86776,0,128), -- Subetai the Swift
(61427,86777,0,128), -- Subetai the Swift
(61427,86778,0,128), -- Subetai the Swift
(61427,86779,0,128), -- Subetai the Swift
(61427,86780,0,128), -- Subetai the Swift
(61427,86781,0,128), -- Subetai the Swift
(61427,86782,0,128), -- Subetai the Swift
(61427,86783,0,128), -- Subetai the Swift
(61427,86784,0,128), -- Subetai the Swift
(61427,86785,0,128), -- Subetai the Swift
(61427,86786,0,128), -- Subetai the Swift
(61427,86787,0,128), -- Subetai the Swift
(61427,86788,0,128), -- Subetai the Swift
(61427,87044,0,96), -- Subetai the Swift
(61427,87045,0,96), -- Subetai the Swift
(61427,87046,0,96), -- Subetai the Swift
(61427,87047,0,96), -- Subetai the Swift
(61427,87048,0,96), -- Subetai the Swift
(61427,87049,0,96), -- Subetai the Swift
(61427,87050,0,96), -- Subetai the Swift
(61427,87051,0,96), -- Subetai the Swift
(61427,87052,0,96), -- Subetai the Swift
(61427,87053,0,96), -- Subetai the Swift
(61427,87054,0,96), -- Subetai the Swift
(61427,87055,0,96), -- Subetai the Swift
(61427,87056,0,96), -- Subetai the Swift
(61427,89818,0,24), -- Subetai the Swift
(61427,89819,0,24), -- Subetai the Swift
(61427,89935,0,96), -- Subetai the Swift
(61427,89936,0,96), -- Subetai the Swift
(61427,89970,0,128), -- Subetai the Swift
(61427,89971,0,128), -- Subetai the Swift
(61444,81237,0,4), -- Ming the Cunning
(61444,81238,0,4), -- Ming the Cunning
(61444,81239,0,4), -- Ming the Cunning
(61444,81240,0,4), -- Ming the Cunning
(61444,81241,0,4), -- Ming the Cunning
(61444,85175,0,2), -- Ming the Cunning
(61444,85176,0,2), -- Ming the Cunning
(61444,85177,0,2), -- Ming the Cunning
(61444,85178,0,2), -- Ming the Cunning
(61444,85179,0,2), -- Ming the Cunning
(61445,81237,0,4), -- Haiyan the Unstoppable
(61445,81238,0,4), -- Haiyan the Unstoppable
(61445,81239,0,4), -- Haiyan the Unstoppable
(61445,81240,0,4), -- Haiyan the Unstoppable
(61445,81241,0,4), -- Haiyan the Unstoppable
(61445,85175,0,2), -- Haiyan the Unstoppable
(61445,85176,0,2), -- Haiyan the Unstoppable
(61445,85177,0,2), -- Haiyan the Unstoppable
(61445,85178,0,2), -- Haiyan the Unstoppable
(61445,85179,0,2), -- Haiyan the Unstoppable
(62442,86321,0,24), -- Tsulong
(62442,86322,0,24), -- Tsulong
(62442,86323,0,24), -- Tsulong
(62442,86324,0,24), -- Tsulong
(62442,86325,0,24), -- Tsulong
(62442,86326,0,24), -- Tsulong
(62442,86327,0,24), -- Tsulong
(62442,86328,0,24), -- Tsulong
(62442,86329,0,24), -- Tsulong
(62442,86330,0,24), -- Tsulong
(62442,86337,0,24), -- Tsulong
(62442,86338,0,24), -- Tsulong
(62442,86339,0,24), -- Tsulong
(62442,86340,0,24), -- Tsulong
(62442,86341,0,24), -- Tsulong
(62442,86342,0,24), -- Tsulong
(62442,86343,0,24), -- Tsulong
(62442,86383,0,24), -- Tsulong
(62442,86384,0,24), -- Tsulong
(62442,86385,0,24), -- Tsulong
(62442,86879,0,128), -- Tsulong
(62442,86880,0,128), -- Tsulong
(62442,86881,0,128), -- Tsulong
(62442,86882,0,128), -- Tsulong
(62442,86883,0,128), -- Tsulong
(62442,86884,0,128), -- Tsulong
(62442,86885,0,128), -- Tsulong
(62442,86886,0,128), -- Tsulong
(62442,86887,0,128), -- Tsulong
(62442,86888,0,128), -- Tsulong
(62442,86895,0,128), -- Tsulong
(62442,86896,0,128), -- Tsulong
(62442,86897,0,128), -- Tsulong
(62442,86898,0,128), -- Tsulong
(62442,86899,0,128), -- Tsulong
(62442,86900,0,128), -- Tsulong
(62442,86901,0,128), -- Tsulong
(62442,86902,0,128), -- Tsulong
(62442,86903,0,128), -- Tsulong
(62442,86904,0,128), -- Tsulong
(62442,87156,0,96), -- Tsulong
(62442,87157,0,96), -- Tsulong
(62442,87158,0,96), -- Tsulong
(62442,87159,0,96), -- Tsulong
(62442,87160,0,96), -- Tsulong
(62442,87161,0,96), -- Tsulong
(62442,87162,0,96), -- Tsulong
(62442,87163,0,96), -- Tsulong
(62442,87164,0,96), -- Tsulong
(62442,87165,0,96), -- Tsulong
(62442,87177,0,96), -- Tsulong
(62442,87178,0,96), -- Tsulong
(62442,87179,0,96), -- Tsulong
(62442,87180,0,96), -- Tsulong
(62442,87181,0,96), -- Tsulong
(62442,87182,0,96), -- Tsulong
(62442,87183,0,96), -- Tsulong
(62442,87184,0,96), -- Tsulong
(62442,87185,0,96), -- Tsulong
(62442,87186,0,96), -- Tsulong
(62442,89843,0,24), -- Tsulong
(62442,89980,0,128), -- Tsulong
(62442,89981,0,128), -- Tsulong
(62442,89982,0,128), -- Tsulong
(62442,89983,0,128), -- Tsulong
(62983,86331,0,24), -- Lei Shi
(62983,86332,0,24), -- Lei Shi
(62983,86333,0,24), -- Lei Shi
(62983,86334,0,24), -- Lei Shi
(62983,86335,0,24), -- Lei Shi
(62983,86336,0,24), -- Lei Shi
(62983,86337,0,24), -- Lei Shi
(62983,86338,0,24), -- Lei Shi
(62983,86339,0,24), -- Lei Shi
(62983,86340,0,24), -- Lei Shi
(62983,86341,0,24), -- Lei Shi
(62983,86342,0,24), -- Lei Shi
(62983,86343,0,24), -- Lei Shi
(62983,86383,0,24), -- Lei Shi
(62983,86384,0,24), -- Lei Shi
(62983,86385,0,24), -- Lei Shi
(62983,86391,0,24), -- Lei Shi
(62983,86889,0,128), -- Lei Shi
(62983,86890,0,128), -- Lei Shi
(62983,86891,0,128), -- Lei Shi
(62983,86892,0,128), -- Lei Shi
(62983,86893,0,128), -- Lei Shi
(62983,86894,0,128), -- Lei Shi
(62983,86895,0,128), -- Lei Shi
(62983,86896,0,128), -- Lei Shi
(62983,86897,0,128), -- Lei Shi
(62983,86898,0,128), -- Lei Shi
(62983,86899,0,128), -- Lei Shi
(62983,86900,0,128), -- Lei Shi
(62983,86901,0,128), -- Lei Shi
(62983,86902,0,128), -- Lei Shi
(62983,86903,0,128), -- Lei Shi
(62983,86904,0,128), -- Lei Shi
(62983,86910,0,128), -- Lei Shi
(62983,87166,0,96), -- Lei Shi
(62983,87167,0,96), -- Lei Shi
(62983,87168,0,96), -- Lei Shi
(62983,87169,0,96), -- Lei Shi
(62983,87170,0,96), -- Lei Shi
(62983,87171,0,96), -- Lei Shi
(62983,87172,0,96), -- Lei Shi
(62983,87177,0,96), -- Lei Shi
(62983,87178,0,96), -- Lei Shi
(62983,87179,0,96), -- Lei Shi
(62983,87180,0,96), -- Lei Shi
(62983,87181,0,96), -- Lei Shi
(62983,87182,0,96), -- Lei Shi
(62983,87183,0,96), -- Lei Shi
(62983,87184,0,96), -- Lei Shi
(62983,87185,0,96), -- Lei Shi
(62983,87186,0,96), -- Lei Shi
(62983,89246,0,24), -- Lei Shi
(62983,89247,0,24), -- Lei Shi
(62983,89248,0,24), -- Lei Shi
(62983,89261,0,96), -- Lei Shi
(62983,89262,0,96), -- Lei Shi
(62983,89263,0,96), -- Lei Shi
(62983,89276,0,128), -- Lei Shi
(62983,89277,0,128), -- Lei Shi
(62983,89278,0,128), -- Lei Shi
(645,5197,0,2), -- Cookie
(645,5198,0,2), -- Cookie
(65501,86200,0,24), -- Wind Lord Mel'jarak
(65501,86201,0,24), -- Wind Lord Mel'jarak
(65501,86202,0,24), -- Wind Lord Mel'jarak
(65501,86204,0,24), -- Wind Lord Mel'jarak
(65501,86205,0,24), -- Wind Lord Mel'jarak
(65501,86513,0,24), -- Wind Lord Mel'jarak
(65501,86514,0,24), -- Wind Lord Mel'jarak
(65501,86851,0,128), -- Wind Lord Mel'jarak
(65501,86852,0,128), -- Wind Lord Mel'jarak
(65501,86853,0,128), -- Wind Lord Mel'jarak
(65501,86855,0,128), -- Wind Lord Mel'jarak
(65501,86856,0,128), -- Wind Lord Mel'jarak
(65501,86911,0,128), -- Wind Lord Mel'jarak
(65501,86912,0,128), -- Wind Lord Mel'jarak
(65501,86974,0,96), -- Wind Lord Mel'jarak
(65501,86975,0,96), -- Wind Lord Mel'jarak
(65501,86976,0,96), -- Wind Lord Mel'jarak
(65501,86977,0,96), -- Wind Lord Mel'jarak
(65501,86978,0,96), -- Wind Lord Mel'jarak
(65501,86979,0,96), -- Wind Lord Mel'jarak
(65501,86980,0,96), -- Wind Lord Mel'jarak
(65501,89240,0,24), -- Wind Lord Mel'jarak
(65501,89241,0,24), -- Wind Lord Mel'jarak
(65501,89242,0,24), -- Wind Lord Mel'jarak
(65501,89255,0,96), -- Wind Lord Mel'jarak
(65501,89256,0,96), -- Wind Lord Mel'jarak
(65501,89257,0,96), -- Wind Lord Mel'jarak
(65501,89270,0,128), -- Wind Lord Mel'jarak
(65501,89271,0,128), -- Wind Lord Mel'jarak
(65501,89272,0,128), -- Wind Lord Mel'jarak
(71543,102293,0,24), -- Immerseus
(71543,103726,0,24), -- Immerseus
(71543,103727,0,24), -- Immerseus
(71543,103728,0,24), -- Immerseus
(71543,103730,0,24), -- Immerseus
(71543,103733,0,24), -- Immerseus
(71543,103736,0,24), -- Immerseus
(71543,103738,0,24), -- Immerseus
(71543,103741,0,24), -- Immerseus
(71543,103744,0,24), -- Immerseus
(71543,103747,0,24), -- Immerseus
(71543,103749,0,24), -- Immerseus
(71543,103751,0,24), -- Immerseus
(71543,103752,0,24), -- Immerseus
(71543,103755,0,24), -- Immerseus
(71543,103757,0,24), -- Immerseus
(71543,103760,0,24), -- Immerseus
(71543,103763,0,24), -- Immerseus
(71543,103766,0,24), -- Immerseus
(71543,103771,0,24), -- Immerseus
(71543,103966,0,24); -- Immerseus
DELETE bad FROM creature_loot_template bad
JOIN instance_reward_modes fix ON fix.entry=bad.entry AND fix.item=bad.item AND fix.old_mask=bad.lootmode+0
JOIN creature_loot_template good ON good.entry=bad.entry AND good.item=bad.item AND good.lootmode+0=fix.new_mask
WHERE bad.mincountOrRef>=0;
UPDATE creature_loot_template loot JOIN instance_reward_modes fix
ON fix.entry=loot.entry AND fix.item=loot.item AND fix.old_mask=loot.lootmode+0
SET loot.lootmode=fix.new_mask WHERE loot.mincountOrRef>=0;
DROP TEMPORARY TABLE instance_reward_modes;
-- Normal reward chests were incorrectly spawned only in Heroic.
UPDATE gameobject SET spawnMask=2 WHERE id IN (185168,190586,191349,195323,195374,195709) AND spawnMask=4;
-- Dragon Soul: the three 25-player Heroic reward chests were spawned in 10-player Normal.
UPDATE gameobject SET spawnMask=64 WHERE map=967 AND id IN (210163,209897,210220) AND spawnMask=8;
-- Paletress's normal chest contained an additional Heroic-only weapon.
DELETE FROM gameobject_loot_template WHERE entry=195323 AND item=47514 AND lootmode+0=0 AND groupid=0;
-- Missing equippable items listed for these bosses in the 5.4.8 Dungeon Journal.
-- Join their existing equal-chance group; this does not add an extra loot roll.
INSERT INTO creature_loot_template (entry,item,ChanceOrQuestChance,lootmode,groupid,mincountOrRef,maxcount)
SELECT missing.entry,missing.item,0,missing.mode,1,1,1
FROM (SELECT 3887 entry,5254 item,2 mode UNION ALL SELECT 3887,5943,2
      UNION ALL SELECT 3887,6319,2 UNION ALL SELECT 27977,37649,4) missing
WHERE NOT EXISTS (SELECT 1 FROM creature_loot_template l WHERE l.entry=missing.entry AND l.item=missing.item AND l.lootmode+0=missing.mode);
COMMIT;
