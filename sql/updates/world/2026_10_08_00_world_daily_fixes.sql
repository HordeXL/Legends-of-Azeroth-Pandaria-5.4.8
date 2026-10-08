-- ============================================================================
--  2026-10-08 world 库合并更新
--  包含三个独立修复，合并为单文件便于版本管理（均可单独执行、幂等）
--
--  【A】任务 29524「The Lesson of Stifled Pride」计数永远 0/6
--  【B】新建角色自动按职业发放传家宝（武器 + 饰品 + 盾牌）
--  【C】新建角色自动按职业发放传家宝护甲（头/肩/胸/腿/披风）
--
--  生效方式：脚本本身立即生效；【B】【C】需重启 worldserver
--           （playercreateinfo_item 在启动时载入）
--  ============================================================================


-- ###########################################################################
-- 【A】任务 29524 计数修复
--
-- 目标：击败 6 名火金派弟子(54586)或土水派弟子(54587)
--
-- 根因（SAI 数据层）：
--   1) 这四个 entry（54586/54587/65470/65471）的 SAI 链条在
--      「血量 0-1%」时通过 LINK 链调用 CALL_KILLEDMONSTER(33)，
--      而该行的 target_type=7 (SMART_TARGET_ACTION_INVOKER)。
--      这条链由 SMART_EVENT_HEALTH_PCT 触发，属于 Update tick
--      里的 timed event，ProcessTimedAction() 不带 unit 参数，
--      因此 GetTargets() 里 invoker==NULL，只能回退到
--      GetLastInvoker()；而 mLastInvoker 只在 ProcessAction(unit非空)
--      或 AGGRO 时写入，0-1% 触发时靠的是 CombatStop 后的链，
--      此时 mLastInvoker 往往已被 OnReset() 清空。
--      → ACTION_INVOKER 解析不到玩家，GetTargets 返回空表，
--        KilledMonsterCredit 永不执行。
--
--   2) event_phase_mask 在 LINK 行上不一致：
--      54586 的 id6~10 是 phase_mask=0，而 54587 的 id8~12 是
--      phase_mask=1。虽然链路起点在 phase 1，但一旦中途有任何
--      阶段切换（SetPhase），phase_mask=0/1 的差异会让
--      ProcessEvent() 开头的 IsInPhase() 判断把整条后半链丢掉。
--
-- 修复方案（纯数据层，不动核心）：
--   a) 计数行target_type 7(ACTION_INVOKER) → 0(SELF)。
--      target_type=0 时 CALL_KILLEDMONSTER 走 LootRecipient 分支
--      （SmartScript.cpp 约第 864 行），用 me->GetLootRecipient()
--      拿玩家——战斗开始时 SetLootRecipient 已由攻击者写入，
--      引用稳定，且随组队自动 RewardPlayerAndGroupAtEvent 分给队友。
--   b) 统一 LINK 行 event_phase_mask（全部 0），
--      消除 54586 / 54587 / 65470 / 65471 之间的不一致。
--   c) 目标条目只认 54586，故 65470/65471（土水/火金另一对同名
--      entry）也统一改，避免玩家打到它们时不计数。
--
-- 说明：54587/65471（土水）与 54586/65470（火金）两组 entry
--   名字相同、出生点交错在同一区域（都是 map 860），SAI 里
--   都写 action_param1=54586，即两组都只给 54586 计数，
--   与 quest_objective.objectId=54586 一致，无需改动。
--
-- 注意：这三个 NPC 是"训练假人"设计——阵营 2101 friendlyMask=0x1
--   对玩家友好(不还手)、SAI 设 Invincibility Hp 1(打不死)、
--   RegenHealth=1(脱战回满血)。请勿"修复"这三项，否则任务无法完成。
--   计数依靠血量压到 0~1% 触发 SMART_EVENT_HEALTH_PCT，不是靠杀死。
-- ###########################################################################

-- A-1) 备份（幂等：仅首次执行时写入）
CREATE TABLE IF NOT EXISTS `backup_smart_scripts_29524` (
  `entryorguid` int(11) NOT NULL DEFAULT '0',
  `source_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `link` smallint(5) unsigned NOT NULL DEFAULT '0',
  `event_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `event_phase_mask` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `event_chance` tinyint(3) unsigned NOT NULL DEFAULT '100',
  `event_flags` int(10) unsigned NOT NULL DEFAULT '0',
  `event_param1` int(10) unsigned NOT NULL DEFAULT '0',
  `event_param2` int(10) unsigned NOT NULL DEFAULT '0',
  `event_param3` int(10) unsigned NOT NULL DEFAULT '0',
  `event_param4` int(10) unsigned NOT NULL DEFAULT '0',
  `event_param5` int(10) unsigned NOT NULL DEFAULT '0',
  `action_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `action_param1` int(10) unsigned NOT NULL DEFAULT '0',
  `action_param2` int(10) unsigned NOT NULL DEFAULT '0',
  `action_param3` int(10) unsigned NOT NULL DEFAULT '0',
  `action_param4` int(10) unsigned NOT NULL DEFAULT '0',
  `action_param5` int(10) unsigned NOT NULL DEFAULT '0',
  `action_param6` int(10) unsigned NOT NULL DEFAULT '0',
  `target_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `target_param1` int(10) unsigned NOT NULL DEFAULT '0',
  `target_param2` int(10) unsigned NOT NULL DEFAULT '0',
  `target_param3` int(10) unsigned NOT NULL DEFAULT '0',
  `target_param4` int(10) unsigned NOT NULL DEFAULT '0',
  `target_x` float NOT NULL DEFAULT '0',
  `target_y` float NOT NULL DEFAULT '0',
  `target_z` float NOT NULL DEFAULT '0',
  `target_o` float NOT NULL DEFAULT '0',
  `comment` text NOT NULL,
  PRIMARY KEY (`entryorguid`,`source_type`,`id`,`link`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `backup_smart_scripts_29524`
SELECT * FROM `smart_scripts`
WHERE `source_type`=0
  AND `entryorguid` IN (54586,54587,65470,65471);

-- A-2) 核心修复：CALL_KILLEDMONSTER(33) 的 target_type
--      7 (ACTION_INVOKER) → 0 (SELF，走 LootRecipient 分支)
--      仅改 action_type=33 的行，不动其它 action。
UPDATE `smart_scripts`
SET `target_type` = 0,
    `comment`     = CONCAT(`comment`, ' [Q29524fix target 7->0]')
WHERE `source_type`   = 0
  AND `entryorguid`   IN (54586,54587,65470,65471)
  AND `action_type`   = 33
  AND `action_param1` = 54586
  AND `target_type`   = 7;

-- A-3) 统一 LINK 行 event_phase_mask
--      （LINK 内部行不需要相位门控，相位只由链路起点控制）
UPDATE `smart_scripts`
SET `event_phase_mask` = 0,
    `comment`          = CONCAT(`comment`, ' [Q29524fix phase_mask->0]')
WHERE `source_type`     = 0
  AND `entryorguid`     IN (54586,54587,65470,65471)
  AND `event_type`      = 61
  AND `event_phase_mask` <> 0;


-- ###########################################################################
-- 【B + C】新建角色自动发放传家宝套装（武器/饰品/盾 + 护甲）
--
-- 【实现方式】纯数据层，走核心原生表 `world`.`playercreateinfo_item`，
--   **不需要改核心、不需要重编译、不需要手动改背包**。
--   核心在 Player::Create() 里消费这张表：
--     Player.cpp:719  for (info->item...) StoreNewItemInBestSlots(...)
--   → 自动分配背包槽位，且第二趟循环会自动把能装备的装上
--     (Player.cpp:722-746 CanEquipItem/EquipItem)。
--   → 且随 Create() 之后的 SaveToDB(true) 一起落库。
--   加载逻辑见 ObjectMgr.cpp:3634 "Loading Player Create Items Data..."
--
-- 【关键语义】race=0 表示"所有种族"，class=0 表示"所有职业"
--   (ObjectMgr.cpp:3676-3687：任一为 0 就会展开成全组合)
--   → 所以"通用饰品"只写一行 class=0 即可，不必按11 个职业各写一遍。
--
-- 【传家宝识别】item_template.Quality = 7 = ITEM_QUALITY_HEIRLOOM
--   定义在 SharedDefines.h:307。本库共 162 件传家宝。
--   传家宝是"成长型"装备：核心按 ITEM_QUALITY_RARE 计算伤害/护甲
--   (Item.cpp GetScalingDamageValue / GetArmor)，随等级自动变强。
--   本脚本只发基础版(venerable/battleworn/stained/polished)，
--   保留日后用 938xx/939xx 升级版升级的意义。
--
-- 【护甲识别】item_template.class = 4 (ITEM_CLASS_ARMOR)
--   子类（ItemPrototype.h:426-429）：
--     1=布(CLOTH) 2=皮(LEATHER) 3=锁(MAIL) 4=板(PLATE) 6=盾(SHIELD)
--   排除测试物：Scaling Stat Test* / Test Tattered* /
--             "Family" Shoulderpads / Apron / Rolling Pin /
--             Book of Crafting Secrets 等。
--
-- 【职业-甲型映射（5.4）】
--   布甲：牧师5 / 法师8 / 术士9
--   皮甲：猎人3 / 盗贼4 / 德鲁伊11
--   锁甲：萨满7
--   板甲：战士1 / 圣骑士2 / 死亡骑士6
--   武僧10：官方设定可穿布/皮/锁/板（唯一四甲全穿职业），
--           本脚本按偏好发皮甲(Shadowcraft)。
--   注：服务端**不校验**职业-甲型穿戴（全库无 EQUIP_ERR_WRONG_CLASS，
--       CanEquipItem 无 class 判定），限制由客户端物品描述符强制。
--
-- 【自动装备规律】Player::Create() 第二趟循环（Player.cpp:722-746）
--   注释写明只处理 "offhand weapon/shield"，因此：
--     - 空装备槽（头/肩/胸/腿/披风/饰品/盾）→ 自动穿上
--     - 主手武器若已被初始物品占用 → **不替换**，会留在背包
--
-- 【关于 item_instance】起始物品由 StoreNewItem 走内存流程，
--   SaveToDB 时会照常为每件物品写 item_instance 行。
--   注意：characters.character_inventory.item 存的是
--   **item_instance.guid（实例 GUID）而非 item_template.Entry**，
--   查背包必须 JOIN item_instance 才能拿到真实物品。
--
-- 【生效方式】需重启 worldserver。只影响之后新建的角色，
--   已存在的角色不受影响。
-- ###########################################################################

-- BC-1) 备份（幂等：仅首次写入）
CREATE TABLE IF NOT EXISTS `backup_playercreateinfo_item_20261008` LIKE `playercreateinfo_item`;
INSERT IGNORE INTO `backup_playercreateinfo_item_20261008` (race, class, itemid, amount)
SELECT race, class, itemid, amount FROM `playercreateinfo_item`;

-- BC-2) 通用饰品（race=0, class=0 → 所有种族所有职业）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 0, 42991, 1),   -- Swift Hand of Justice
  (0, 0, 42992, 1);   -- Discerning Eye of the Beast

-- BC-3) 主手武器（按职业，各 1 件基础版）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  -- 战士 Warrior(1)：双手剑
  (0, 1, 44092, 1),   -- Reforged Truesilver Champion
  -- 圣骑士 Paladin(2)：单手剑
  (0, 2, 42945, 1),   -- Venerable Dal'Rend's Sacred Charge
  -- 猎人 Hunter(3)：弓
  (0, 3, 42946, 1),   -- Charmed Ancient Bone Bow
  -- 盗贼 Rogue(4)：单手剑
  (0, 4, 42945, 1),   -- Venerable Dal'Rend's Sacred Charge
  -- 牧师 Priest(5)：法杖
  (0, 5, 42947, 1),   -- Dignified Headmaster's Charge
  -- 死亡骑士 DK(6)：单手剑
  (0, 6, 42945, 1),   -- Venerable Dal'Rend's Sacred Charge
  -- 萨满 Shaman(7)：单手锤
  (0, 7, 42948, 1),   -- Devout Aurastone Hammer
  -- 法师 Mage(8)：法杖
  (0, 8, 44095, 1),   -- Grand Staff of Jordan
  -- 术士 Warlock(9)：法杖
  (0, 9, 44095, 1),   -- Grand Staff of Jordan
  -- 武僧 Monk(10)：拳套
  (0, 10, 92948, 1),  -- Brawler's Razor Claws
  -- 德鲁伊 Druid(11)：法杖
  (0, 11, 44095, 1);  -- Grand Staff of Jordan

-- BC-4) 副手 / 盾牌 / 弹药
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  -- 圣骑士：盾牌
  (0, 2, 93903, 1),   -- Weathered Observer's Shield
  -- 猎人：火枪
  (0, 3, 44093, 1),   -- Upgraded Dwarven Hand Cannon
  -- 盗贼：副手匕首
  (0, 4, 42944, 1),   -- Balanced Heartseeker
  -- 死亡骑士：盾牌
  (0, 6, 93903, 1),   -- Weathered Observer's Shield
  -- 萨满：盾牌
  (0, 7, 93903, 1),   -- Weathered Observer's Shield
  -- 武僧：法杖（远程专精用）
  (0, 10, 79131, 1),  -- Burnished Warden Staff
  -- 德鲁伊：弓（远程专精用）
  (0, 11, 42946, 1);  -- Charmed Ancient Bone Bow

-- BC-5) 布甲套 Tattered Dreadmist（牧师5 / 法师8 / 术士9）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 5, 61958, 1),   -- Tattered Dreadmist Mask      头部
  (0, 5, 42985, 1),   -- Tattered Dreadmist Mantle    肩
  (0, 5, 48691, 1),   -- Tattered Dreadmist Robe      胸
  (0, 5, 62029, 1),   -- Tattered Dreadmist Leggings  腿
  (0, 5, 62040, 1),   -- Ancient Bloodmoon Cloak      披风
  (0, 8, 61958, 1),
  (0, 8, 42985, 1),
  (0, 8, 48691, 1),
  (0, 8, 62029, 1),
  (0, 8, 62040, 1),
  (0, 9, 61958, 1),
  (0, 9, 42985, 1),
  (0, 9, 48691, 1),
  (0, 9, 62029, 1),
  (0, 9, 62040, 1);

-- BC-6) 皮甲套 Stained Shadowcraft（盗贼4 / 猎人3）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 4, 61937, 1),   -- Stained Shadowcraft Cap       头部
  (0, 4, 42952, 1),   -- Stained Shadowcraft Spaulders 肩
  (0, 4, 48689, 1),   -- Stained Shadowcraft Tunic     胸
  (0, 4, 62026, 1),   -- Stained Shadowcraft Pants     腿
  (0, 4, 62040, 1),   -- Ancient Bloodmoon Cloak       披风
  (0, 3, 61937, 1),
  (0, 3, 42952, 1),
  (0, 3, 48689, 1),
  (0, 3, 62026, 1),
  (0, 3, 62040, 1);

-- BC-7) 锁甲套（萨满7）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 7, 61935, 1),   -- Tarnished Raging Berserker's Helm 头部
  (0, 7, 42950, 1),   -- Champion Herod's Shoulder         肩
  (0, 7, 48677, 1),   -- Champion's Deathdealer Breastplate 胸
  (0, 7, 62024, 1),   -- Tarnished Leggings of Destruction  腿
  (0, 7, 62040, 1);   -- Ancient Bloodmoon Cloak            披风

-- BC-8) 板甲套 Polished Valor（战士1 / 圣骑士2 / 死亡骑士6）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 1, 61931, 1),   -- Polished Helm of Valor        头部
  (0, 1, 42949, 1),   -- Polished Spaulders of Valor   肩
  (0, 1, 48685, 1),   -- Polished Breastplate of Valor 胸
  (0, 1, 62023, 1),   -- Polished Legplates of Valor   腿
  (0, 1, 62040, 1),   -- Ancient Bloodmoon Cloak       披风
  (0, 2, 61931, 1),
  (0, 2, 42949, 1),
  (0, 2, 48685, 1),
  (0, 2, 62023, 1),
  (0, 2, 62040, 1),
  (0, 6, 61931, 1),
  (0, 6, 42949, 1),
  (0, 6, 48685, 1),
  (0, 6, 62023, 1),
  (0, 6, 62040, 1);

-- BC-9) 德鲁伊(11)：皮甲（守护专精向）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 11, 61937, 1),
  (0, 11, 42952, 1),
  (0, 11, 48689, 1),
  (0, 11, 62026, 1),
  (0, 11, 62040, 1);

-- BC-10) 武僧(10)：皮甲（按偏好，非官方"四甲全穿"默认）
INSERT IGNORE INTO `playercreateinfo_item` (race, class, itemid, amount) VALUES
  (0, 10, 61937, 1),  -- Stained Shadowcraft Cap       头部
  (0, 10, 42952, 1),  -- Stained Shadowcraft Spaulders 肩
  (0, 10, 48689, 1),  -- Stained Shadowcraft Tunic     胸
  (0, 10, 62026, 1),  -- Stained Shadowcraft Pants     腿
  (0, 10, 62040, 1);  -- Ancient Bloodmoon Cloak       披风


-- ###########################################################################
-- 校验
-- ###########################################################################

SELECT '===[A] 29524 计数行 target_type 应全为 0 ===' AS `check`;
SELECT entryorguid, id, link, event_type, event_phase_mask,
       action_type, action_param1, target_type
FROM `smart_scripts`
WHERE source_type = 0
  AND entryorguid IN (54586,54587,65470,65471)
  AND action_type = 33
ORDER BY entryorguid, id;

SELECT '=== [A] 断链检查(link 指向的行必须存在且为 LINK 类型=61) ===' AS `check`;
SELECT s.entryorguid, s.id, s.link,
       (SELECT COUNT(*) FROM smart_scripts t
         WHERE t.source_type = s.source_type AND t.entryorguid = s.entryorguid
           AND t.id = s.link AND t.event_type = 61) AS link_ok
FROM smart_scripts s
WHERE s.source_type = 0
  AND s.entryorguid IN (54586,54587,65470,65471)
  AND s.link <> 0 AND s.event_type <> 61;

SELECT '=== [BC] 各职业传家宝件数统计 ===' AS `check`;
SELECT `class`, COUNT(*) AS items
FROM `playercreateinfo_item`
GROUP BY `class` ORDER BY `class`;

SELECT '=== [BC] 测试物品检查(应为空) ===' AS `check`;
SELECT * FROM `playercreateinfo_item`
WHERE itemid IN (69814, 38391, 38392, 38394, 38385, 38395, 38316,
                 39705, 39677, 44090, 59526, 38694, 45084, 86468, 86558);

SELECT '=== [BC] 本次新增传家宝须全部存在且 Quality=7(应为空) ===' AS `check`;
-- 只校验本次新增的传家宝 ID；表内还有官方原始数据
-- （DK 的 Scourgestone 40582、熊猫人初始装备 732xx等），不属于传家宝，不在此列
SELECT p.race, p.class, p.itemid
FROM `playercreateinfo_item` p
LEFT JOIN `item_template` t ON t.Entry = p.itemid
WHERE p.itemid IN (
  -- 饰品
  42991, 42992,
  -- 武器
  44092, 42945, 42946, 42947, 42948, 44095, 92948, 79131, 44093, 42944,
  -- 盾
  93903,
  -- 布甲
  61958, 42985, 48691, 62029,
  -- 皮甲
  61937, 42952, 48689, 62026,
  -- 锁甲
  61935, 42950, 48677, 62024,
  -- 板甲
  61931, 42949, 48685, 62023,
  -- 披风
  62040
)
AND (t.Entry IS NULL OR t.Quality <> 7);