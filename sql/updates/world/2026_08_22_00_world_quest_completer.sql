-- 任务完成卷轴 (Quest Completer Scroll)
-- 右键点击列出所有可完成的任务，选择后自动完成并发放奖励
-- 同时创建任务完成记录表用于记录每次使用的任务信息

-- =============================================
-- 任务完成记录表 - 记录每次使用任务完成器完成的任务（同任务不重复记录）
-- =============================================
DROP TABLE IF EXISTS `任务完成记录`;

CREATE TABLE `任务完成记录` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `quest_id` INT UNSIGNED NOT NULL COMMENT '任务ID',
    `quest_name` VARCHAR(255) NOT NULL COMMENT '任务名称',
    `quest_giver_npc` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '任务领取NPC ID',
    `quest_objectives` TEXT COMMENT '任务目标描述',
    `quest_turnin_npc` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '交任务NPC ID',
    `player_name` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '玩家名称',
    `faction` VARCHAR(10) NOT NULL DEFAULT '' COMMENT '阵营',
    `completed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '完成时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='任务完成器使用记录';

-- =============================================
-- 任务完成卷轴物品定义 (Item Entry 200000)
-- 质量5 (传说品质), 显示ID 44462 (卷轴)
-- 物品脚本名: item_quest_completer
-- =============================================
DELETE FROM `item_template` WHERE `entry` = 200000;
DELETE FROM `item_script_names` WHERE `Id` = 200000;

INSERT INTO `item_template` (`entry`, `class`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `Material`, `ArmorDamageModifier`, `spellid_1`, `spelltrigger_1`)
VALUES (200000, 0, '任务完成卷轴', 56317, 5, 0, 1, 0, 0, 0, -1, -1, 1, 1, 0, 1, 0, 0, 12883, 0);

INSERT INTO `item_script_names` (`Id`, `ScriptName`)
VALUES (200000, 'item_quest_completer');
