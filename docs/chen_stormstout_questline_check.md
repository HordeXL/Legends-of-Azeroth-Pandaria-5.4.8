# 四风谷 陈·风暴烈酒任务线检查报告

> 检查日期：2026-09-28 | 数据库：本机 world 库（root/root）| 核心源码已核对
> **2026-09-28 更新：已对照官方 5.4.8 参考库（world_548_20240722.sql → 临时库 official_ref）逐项核对，并实施修复（见文末"五、官方对比与修复实施"）。**

## 五、官方对比与修复实施（2026-09-28）

### 官方对比结论（official_ref vs world）
| 表 | 结论 |
|----|------|
| quest_template_addon | 官方与本地逐字段一致（8 个任务缺行是**官方原样**；本地仅多 29877←29907，为 09-27 有意补充）→ **P3 不修** |
| quest_objective | 官方=本地（29919/29947/29950/29952/30172 的 credit 目标官方就如此） |
| smart_scripts | 官方仅 5 行相关（56133×3 + 64946×2）；29919/29947/29950/29952/30172 的 credit **官方 DB 亦无任何触发机制** |
| conditions | 官方仅 127141 一行；官方无 105836 定位条件（本服补充的，有效） |
| spell_area / quest_objective_effects | 无相关条目（effects 表只是视觉特效，官方=本地） |

### 澄清（原报告误判项）
- **29947/29950 机制完整，不修**：StartItem（76370 橙染芜菁 / 76350 丽丽的许愿石）+ addon.ProvidedItemCount=1 → 接任务发物品（核心 ObjectMgr.cpp:4599 确认 StartItem+ProvidedItemCount=接取发放），使用时由客户端 DBC 法术（106263/106276）发 credit——DB 侧看不到是正常的。
- **29945 机制完整，不修**：Meadow Marigold=GO 209907（loot 40521→76334，42 刷新点）；Vial of Animal Blood=野兽 56523/56524/56526/56531/56532 掉落（131 刷新）。
- 随从陈/丽丽 56343/56344 零刷新属正常（法术召唤物不入 creature 表）。

### 已实施修复（2026_09_28_00_world_chen_stormstout_questline_fixes.sql，已应用）
1. **30032**：GO 210052「守望崖淡啤大麦」（洞穴口唯一刷新）补 100% 任务拾取 → 77034「窖藏大麦」（官方 dump 同样缺失此拾取源）。
2. **29919**：泥盏 56474 开 SmartAI，OOC_LOS(25 码, 冷却 15-30s) + 条件（任务 29919 进行中）→ 发 credit 56571 + 台词（"总算把你们盼来了！…"）。
3. **29952**：接任务 → 陈开讲风暴烈酒家故事（定时台词脚本 5613302，3 句，清/恢复 npcflag）→ credit 56680；entry 56133 与 GUID -512655 双份（GUID 非叠加）。
4. **30172**：带任务接近陈 → OOC_LOS 发 credit 58341 + 收尾台词；entry/GUID 双份 + 条件门控。
5. **顺带修正 29932**：09-26 的条件行键映射写反（SourceGroup/SourceEntry 颠倒导致从未生效），按正确映射重写（值不变）。

### 重要机制纠正（覆盖 2026-09-26 笔记）
SMART_EVENT 条件键映射（ConditionMgr.cpp:1390 存储键=(SourceEntry,SourceId)，1113 查找键=(entryOrGuid,sourceType)+SourceGroup=行id+1）：
- **SourceEntry = entryorguid（可负）**
- **SourceGroup = smart_scripts.id + 1**
- **SourceId = source_type**
（09-26 笔记"SourceGroup=entryorguid、SourceEntry=id+1"系误读——29932 的条件行因此一直未生效。）

### 生效方式
`AIName` 变更（泥盏 56474）需**重启 worldserver**（或 .reload creature_template 后重刷泥盏）；smart_scripts/creature_text/conditions/loot 可用对应 .reload 命令热加载。


## 一、任务线全景（共 26 个任务）

### 主线（酿酒线）
| # | 任务 | 接取 | 上交 | 目标 | 状态 |
|---|------|------|------|------|------|
| 1 | 32018 His Name Was... Stormstout | 56774（翡翠林） | 陈 56133 | 无目标，接即完成 | ✅ |
| 1' | 32019 They Call Him... Stormstout | 56782 | 陈 56133 | 与 32018 互斥 | ✅ |
| 2 | 29907 Chen and Li Li | 陈 56133 | 庞·酒母 56204 | 跟随随从陈 56343（至庞家农场） | ✅（2026-09-27 已修复，法术召唤机制） |
| 3 | 29919 Great Minds Drink Alike | 陈 56133 | 泥盏 56474 | 护送 credit 56571 | ❌ 无机制 |
| 4 | 30049 Doesn't Hold Water | 陈 56133 | 泥盏 56474 | - | ⚠️ 无前置门控 |
| 5 | 30032 The Quest for Better Barley | 57211 | - | GO 210039（×1 存在）+ 物品 77034×1 | ⚠️ 物品来源缺失 |
| 6 | 30047 The Chen Taste Test | 李立 56138 | 陈 56133 | - | ✅（与 30172 互斥） |
| 7 | 30073 The Emperor | 陈 56133 | 陈 56133 | SAI 定时脚本 5613300：5 段台词 → credit 57477 | ✅ |
| 8 | 30074 Knocking on the Door | 陈 56133 | 陈 56133 | - | ✅ |
| 9 | 30075 Clear the Way | 陈 56133 | 陈 56133 | 杀 57672 ×10（刷 23 只） | ⚠️ 无前置门控 |
| 10 | 30078 Cleaning House | 陈 56133 | 陈 56133 | 访 58014/58015/58017（均存在） | ✅ |
| 11 | 30085 Into the Brewery | 陈 56133 | 59704（酒坊副本内陈） | 无目标=接即完成 | ✅ |

### 陈/丽丽农场支线
| 任务 | 链路 | 状态 |
|------|------|------|
| 29944 Leaders Among Breeders → 29946 The Warren-Mother → 29949 Legacy → 29950 Li Li's Day Off | prev 链完整；29944 自身无前置 | ⚠️/❌ |
| 29945 Yellow and Red Make Orange → 29947 Crouching Carrot, Hidden Turnip | prev/next 完整 | ⚠️/❌ |

### 其余散任务
- 30053 Hop Hunting → 30055 Stormstout's Hops：✅（3 个对话 NPC 均存在）
- 30031 Taste Test（4 个 GO 210021-24，刷 5/5/5/4）→ 30048 Li Li and the Grain：✅
- 30077 Barrels, Man（救 57662 ×7，刷 10 只）：⚠️ 无前置门控
- 30046 Chen's Resolution：无目标、无 addon 行，接即完成（非每日）
- 29952 Broken Dreams：❌ credit 56680 无机制
- 30172 Barreling Along：❌ credit 58341 无机制

## 二、关键问题（按严重度）

### ✅ P1（更正）：29907「陈与丽丽」护送链路——已由 2026-09-27 的修复接通
> **更正**：本节最初被误判为断裂。原因是误用了 TC master 的 action 语义（85=SUMMON_CREATURE_GROUP）；
> 本核心 `SmartScriptMgr.h` 中 **action 85 = SMART_ACTION_INVOKER_CAST（由玩家施法）**。

实际机制（全部已就位，接任务时由玩家施放）：
- **法术 105835**：效果 0 召唤随从陈 56343，效果 2 触发法术 105836；
- **法术 105836**：效果 0 召唤随从丽丽 56344，依赖 `conditions` 表隐式目标条件（type 31，附近存在陈 56343）定位召唤点（该行已存在）；
- **DBC 补丁**：105835/105836 时长改永久（`contrib/patch_spell_105835_summon_duration.py`），随从常驻；
- 随从陈 56343 自带完整护送 SAI：8 个路点全部用 **action 69 (MOVE_TO_POS) 行内坐标**（不依赖 waypoints 表），WP5 发 credit 56343，随后 5s→13s→19s→24s 与庞·酒母对话演出，最后走向农舍坐下常驻；丽丽 56344 延迟 500ms 跟随陈；
- GUID 脚本（-512655）与 entry 脚本均含接任务召唤行（commit 61845db2 为避免 GUID 非叠加而原样复制）。

**修复来源（历史提交）**：
- commit `3e822f20`（2026-09-27 18:46）：`contrib/patch_spell_105835_summon_duration.py` + `sql/updates/world/2026_09_27_00_world_consolidated_updates.sql` PART 4「任务 29907《陈和丽丽》护送演出（最终状态）」；
- commit `61845db2`（2026-09-27 20:37）：陈/丽丽循环对话与丽丽巡逻脚本，GUID 化时保留接任务召唤行。

### ⚠️ P2：5 个任务的 credit 目标在 DB 内无任何触发机制（待运行时验证）
以下 credit NPC 在 `creature` 表零刷新、无 SAI、无召唤组、无 conditions 引用、quest_template_addon 无 SourceSpellID：
- 29919 护送 credit 56571（Chen Stormstout 随从模板，无 AI）
- 29947 橙色芜菁 credit 56544（Orange Turnip Credit）
- 29950 三地造访 credit 56546/56547/56548（丝纱工坊/水村/瀑布）
- 29952 credit 56680（Uncle Gao 模板）
- 30172 credit 58341（Mudmug 模板）

> 注意：随从陈 56343 同样零刷新但经法术召唤正常工作——**零刷新本身不能证明坏**；召唤类机制可存在于客户端 DBC（DB 不可见）。但与 29907 不同，这些任务在 DB 侧既无接任务施法（SourceSpellID=0 / 无 addon 行）也无任何 SAI 触发，无法完成的可能性大，建议实测。

### ⚠️ P3：8 个任务缺 `quest_template_addon` 行（无前置门控）
29907、29919、29944、29952、30046、30073、30075、30077。
影响：链路可跳接。如 30075（清路）不要求先完成 30074；29919/29944 不要求先完成 29907；30049 与 29919 之间无 prev/next 约束（30049 仅与 30029 互斥）。其中靠上游 next 指针衔接的部分（32018→29907、30032→30047→30073、30078→30085 等）仍然有效。

### ⚠️ P4：30032 物品 77034（悬崖吊具）无来源
目标要求携带/使用 77034×1，但任务 StartItem=0、addon 无 ProvidedItemCount、无接任务施法/发物品的 SAI。需核实（可能应改用 objective type=2 直接用 GO）。

### ℹ️ 备注
- 56133 SAI id2 是死行（GOSSIP_SELECT 事件但 NPC 无 gossip menu），无实际影响。
- 李立 56138 模板 AIName=SmartAI 但无任何 SAI 行——无害。
- 陈/李立各 4 个常驻刷新点（半山、庞家农场、酒坊、酒坊外），相位复用正常。
- 30073 The Emperor 的演出文本（56133 文本组 0-4）已配置齐全，中文可读。

## 三、修复建议（未实施）
1. ~~P1~~ 已由 2026-09-27 修复（法术召唤 + DBC 永久时长 + 行内坐标路径）；
2. **P2**：实测 29919/29947/29950/29952/30172 是否可完成；若坏，为其补触发（SAI 区域触发 CALL_KILLEDMONSTER 或法术召唤 credit，参照 29907 方案）；
3. **P3**：补 8 行 quest_template_addon（PrevQuestID 按官方顺序；29877←29907 已在 09_27_00 中补）；
4. 修复后需 `.reload smart_scripts` + 重启（waypoints/summon_groups 无 reload）。

## 四、核对过的源码点
- **`SmartScriptMgr.h` 本核心 action 语义与 TC master 不同：85=INVOKER_CAST（玩家施法）、69=MOVE_TO_POS(PointId+行内xyz)、80=CALL_TIMED_ACTIONLIST** —— 分析 SAI 时必须以本核心枚举为准
- `SmartScript.cpp` SMART_ACTION_SUMMON_CREATURE_GROUP（本核心为其他编号）：组缺失 → 空列表静默返回（29907 不走此路径，无影响）
- `Player.cpp CanCompleteQuest`：无 objectives 的任务（32018/32019/30046/30085）接取即 INCOMPLETE+全目标空 → 可直接完成
- QuestDef.h Flags/FlagsEx：262152=DISPLAY_COMPLETION_TEXT+HAS_CONDITION+SHARABLE；30046 FlagsEx 6=抑制交/接 gossip

---

## 五、修复后复核（2026-09-28 13:25，全量重跑）

对 26 个任务重新核对 quest_template/addon/objective/SAI/conditions/loot，并与 official_ref 官方库逐字段比对。

### 修复点验证（全部生效 ✅）
| 修复 | 库内状态 |
|------|----------|
| ① 30032 物品 77034 | GO 210052「守望崖淡啤大麦」loot 100%→77034 已生效；与悬崖吊具 GO 210039 相距 3.7 码同点刷新（绳索下崖→拾大麦，流程成立）；77034 是 30032 目标物品，核心自动限制仅做任务者可拾 |
| ② 29919 credit 56571 | 泥盏 56474 已开 SmartAI，OOC_LOS 25 码 + 条件（22,1,56474：29919 进行中）→ action 33 发 credit + 台词，键映射正确（SourceGroup=行id+1=1） |
| ③ 29952 credit 56680 | 接任务 SAI（entry 56133 与 GUID -512655 双份）→ 定时脚本 5613302：清 npcflag→3 句家族故事（文本组 20/21/22 中文齐）→ 发 credit→恢复 npcflag；条件 (22,5,entryorguid: 30172 进行中) 挂在 LOS 行上正确 |
| ④ 30172 credit 58341 | 陈 56133/-512655 各一行 OOC_LOS 25 码 + 条件（30172 进行中）→ action 33 发 credit |
| ⑤ 29932 条件 | 正确行 (22,1,57242) 在位，旧反写行 0 残留 |

### 官方一致性
- `quest_template_addon` 26 个任务：官方=本地，**零差异**（8 个"缺 addon 行"确认官方原样，不修）。
- `quest_objective` 26 个任务：官方=本地，**零差异**。
- 30049→30032→30047 的 prev=0 但由上游 next 指针衔接，官方同构，链路正常。

### 遗留事项
- **重启 worldserver**：泥盏 56474 的 AIName 变更仍需重启才生效（smart_scripts/conditions/loot 可热 reload）。
- 29950 三地造访 credit（56546/47/48）：维持官方同构结论——由接任务物品 76350（丽丽的许愿石，DBC 法术）发 credit，DB 侧不可见属正常；建议运行时实测一次。
- 29947（12 只橙色芜菁 credit 56544）：同上，由物品 76370 的 DBC 法术发 credit。

### 附：半山枢纽"陈同时挂多个任务"的先后顺序核查（2026-09-28 13:50，游戏内截图 7 个任务）

映射（客户端标题→ID）：英雄所喝略同=29919、擒兔先擒首=29944、破碎的梦想=29952、陈的失意=30046（库内 LogTitle 为"陈的决意"，客户端 DBC 标题与库内 locale 不同源）、扛不动水=30049、寻找啤酒花=30053、扫清道路=30075。

**结论：同时开放是官方数据原样。** 官方 `quest_template_addon` 中 29919/29944/29952/30046/30075 五个任务既无自身行、也无任何反向 prev/next 指向，唯一共同门槛是 MinLevel=86。MoP 半山本来就是"批量发任务"的枢纽设计。

完成后的下游解锁（DB 实际存在的门控）：
- 擒兔先擒首 29944 →（prev）密径主母 29946 → 遗产 29949 → 丽丽的假日 29950
- 扛不动水 30049 →（next）寻找更好的大麦 30032 → 陈的口味 30047 → 帝王酒 30073 →（主线推进）
- 寻找啤酒花 30053 → 风暴烈酒的啤酒花 30055（prev/next 双向衔接）
- 扫清道路 30075 →（prev）忍无可忍 30078 → 进入酒坊 30085
- 英雄所喝略同 29919、破碎的梦想 29952、陈的决意 30046：DB 无后续门控，单发
- 互斥：30049 与 30029（玩个小把戏）同 ExclusiveGroup=30029，二选一

若要强制"先过 29907 再开这批"的剧情顺序，需自行补 addon 行（偏离官方原样，属自服定制）。

### 附2：外部数据源交叉验证（2026-09-28 14:05）——零售官方确实有前置链

数据源：① Tauri（mop-shoot/legion-shoot，5.4.8 同源核心数据库，带 Requires 字段）；② Wowpedia（零售维基，Previous/Next）；③ db.damijing.com（中文 5.0.1 数据库，任务线顺序）；④ Twinstar mop-twinhead；⑤ Wowhead 搜索摘要。

**关键发现：MoP 零售的任务前置存在客户端 DB2（QuestLine/prevQuestId），world DB dump 中没有**——这就是为什么官方 dump 与本地一致却"全同时开放"，而零售实际有顺序。

截图 7 任务在零售/其他核心中的前置（多源一致）：
| 任务 | 零售前置 | 证据源 |
|------|----------|--------|
| 29919 英雄所喝略同 | 29918 英勇的一课 | Tauri "Requires A Lesson in Bravery" |
| 29944 擒兔先擒首 | 29919 英雄所喝略同 | Tauri "Requires Great Minds Drink Alike" |
| 29952 破碎的梦想 | 29950 丽丽的假日 | Tauri "Requires Li Li's Day Off" |
| 30046 陈的决意 | 29952 破碎的梦想 | Wowpedia "Previous: Broken Dreams" |
| 30049 扛不动水 | 30046 陈的决意 | Tauri "Requires Chen's Resolution" |
| 30053 寻找啤酒花 | 30046 陈的决意 | Tauri "Requires Chen's Resolution" |
| 30075 扫清道路 | 30074 敲门 | Wowpedia "Previous: Knocking on the Door" |

零售结构（Wowpedia 陈的决意 Progression）：30046 之后并行开三支——啤酒花线(30053→30055)、粮食线(30048→30031→30032→30047)、水线(30049→30051→30172)，汇合于 30073 帝王酒 → 30074 → 30075 → 30078 → 30085。

**本地 DB 偏差点**：本地 30049.next=30032（指向粮食线），零售水线应为 30049→30051→30172；本地 30051（寻找活水）无入链。

### 附3：前置门控修复实施（2026-09-28 14:15，用户确认后）

`sql/updates/world/2026_09_28_01_world_chen_hub_quest_gating.sql` 已应用并回读校验：

- **补 6 行 addon**：29919←29918、29944←29919、29952←29950、30046←29952、30075←30074、30172←30051
- **30049**：prev=30046、next 30032→30051（回归零售水线）
- **环修复**：30048.prev 30031→30046（Wowpedia：陈的决意三支并发，丽丽和谷物是粮食线起点）；30031.next 30048→30032；30032.prev=30031；30047.prev=30032
- **30051**：prev=30049、next 30047→30172（水线经"一起走"再汇合帝王酒）
- **30053**：prev=30046

修复后链路（prev/next 双向一致，无环）：
- 主线：29918→29919→29944→29946→29949→29950→29952→30046 →（三支并行）→ 30047→30073→30074→30075→30078→30085
- 水线：30049→30051→30172；粮食线：30048→30031→30032→30047；啤酒花线：30053→30055
- 互斥保持：30049↔30029（ExclusiveGroup 30029）

注意：quest_template_addon 在启动时缓存，**需重启 worldserver 生效**（或确认核心支持 .reload quest_template）。另发现存量数据 30029（玩个小把戏）.next=30032 指向粮食线（Den Mudclaw 支线），与本次修复无冲突，暂保留原样。

---

## 六、前置门控修复后全链复核（2026-09-28 14:45，附1/附3 修复之后）

对陈任务链做双向指针一致性、环检测、入口可达性、扇入、互斥组五项自动校验，并逐任务回溯根路径。

### 复核发现并修复的三个缺口（2026_09_28_02 / _03 号 SQL，已应用回读）

1. **链根悬空**：`29918 英勇的一课.prev=0`，导致英勇的一课可跳过前序直接接。
   零售依据（Tauri 29918 页）：`Requires Piercing Talons and Slavering Jaws (29916)`，29918 属雷蹄牧场支线（Start/End=Shang Thunderfoot 56312），29916 发放者 56208、无前置。
   修复：`29918.prev=29916, next=29919`。
2. **帝王酒 30073 无多前置**：零售要求 **30047 陈的口味 + 30055 风暴烈酒的啤酒花 + 30172 一起走 全部完成**（Twinstar/Tauri/Wowpedia 三方一致）。
   本核心机制（Player.cpp:17019 `CanTakeQuest = SatisfyQuestPreviousQuest && SatisfyQuestDependentPreviousQuests`；ObjectMgr.cpp:4967 `NextQuestID` 同样给下游累积 DependentPreviousQuests；负数 ExclusiveGroup=each-from-all，`<=0` 不互斥）。
   修复：`30047/30055/30172` 同置 `ExclusiveGroup=-30073`；`30172.next=30073`（恢复官方值，作为 DependentPreviousQuests 入口，另一入口 30047.next=30073 官方已有）。
   官方库自证同模式：29913/29914 已用 `-29913` each-from-all（邻居的义务需两任务全完成）。
3. **遗留正数互斥组与三支结构冲突（官方原样但会导致死任务）**：
   - `30032{30032,30051}`：做完大麦锁死活水 → 水线不可达 → 30073 永远无法满足；
   - `30029{30029,30049}`：玩个小把戏（Twinstar 系列证实属粮食线并列进料 30029→30032）锁死扛不动水；
   - 官方还有 `30172.ExclusiveGroup=30047`（粮/水终点互斥，更早的"二选一"遗留），已随 -30073 覆盖。
   修复：`30032/30051/30049` ExclusiveGroup 置 0（30029 自组无害保留）。

### 复核后最终链路（全链 prev/next 双向一致、无环、全任务有发放者）

```
29907 陈和丽丽(开放) ─ 支线网 ─ 29916 穿透獠牙(开放,牧场) → 29918 英勇的一课 → 29919 英雄所喝略同
→ 29944 擒兔先擒首 → 29946 密径主母 → 29949 遗产 → 29950 丽丽的假日 → 29952 破碎的梦想
→ 30046 陈的决意 ─┬─ 啤酒花线 30053 → 30055
                  ├─ 粮食线   30048 → 30031 ─┬→ 30032（30029 玩个小把戏 并列进料）
                  │                          └→ 30047
                  └─ 水线     30049 → 30051 → 30172
三支终点 30047+30055+30172 全完成 → 30073 帝王酒 → 30074 敲门 → 30075 扫清道路 → 30078 忍无可忍 → 30085 进入酒坊
```

- 存量项（官方原样，不动）：29800-30200 区间大量单向 next/缺 addon 行；29967/29968、30072/32035、30182/30183 互指环；30029.prev=0 开放接取。
- 生效：quest_template_addon 启动缓存，需重启 worldserver。

---

## 七、丽丽任务链核查（2026-09-28 14:55，游戏内截图：丽丽挂「黄配红变橙色」「看那些木桶，伙计」）

发放者确认：两任务均由丽丽 56138（半山静态 NPC）发放；随从丽丽 56344 零刷新（法术召唤物，正常）。

### 零售结构（Twinstar/Tauri/Wowpedia）
```
29919 英雄所喝略同 ─┬─ 29944 擒兔先擒首(Leaders Among Breeders) → 29946 密径主母 ─┐
                    └─ 29945 黄配红变橙色(Yellow and Red Make Orange) → 29947 真假胡萝卜 ┤
                        29948 窃贼本性(Thieves to the Core) ← Requires 29944 ────────────┘
→ 29949 遗产(Legacy，主线脊=29946) → 29950 丽丽的假日 → 29952 破碎的梦想
29949 后并行开：29951 浑水(Muddy Water，泥盏发放)
酒坊：30074 敲门 → 30077 看那些木桶，伙计(Barrels, Man) ‖ 30075 扫清道路 → 30078 清理门户
```

### 发现的缺口与修复（2026_09_28_04_world_lili_chain_gating.sql，已应用回读）
| 任务 | 修复前 | 零售依据 | 修复 |
|------|--------|----------|------|
| 29945 黄配红变橙色 | 无前置 | Twinstar：Requires Great Minds Drink Alike (29919)；系列 1→2 真假胡萝卜 | prev=29919 |
| 29948 窃贼本性 | **无 addon 行**（官方/本地都没有，完全开放） | Tauri：Requires Leaders Among Breeders (29944)，Start/End 泥盏 56474（starter 已在库） | INSERT 行 prev=29944 |
| 30077 看那些木桶，伙计 | **无 addon 行**（完全开放） | Tauri：Requires Knocking on the Door (30074)，Start/End 丽丽 56138 | INSERT 行 prev=30074 |
| 29951 浑水 | addon 行全零（无门控） | Wowpedia：Legacy → Li Li's Day Off & Muddy Water；Twinstar 29949 Open Quests 含 Muddy Water | prev=29949 |

设计说明：
- 29948 的 next 置 0，**不指向 29949**——next 会以 OR 语义进入 29949 的 DependentPreviousQuests，会削弱"遗产"的主线脊门控（29949.prev=29946，Twinstar 无多前置行，维持官方原样）。
- 截图中两个任务同时挂着且无门槛，正是缺门控的表现；重启 worldserver 后：黄配红需先过英雄所喝略同，木桶需先过敲门。

### 已核对无需修复
- 29947 真假胡萝卜 prev=29945 ✓（与 Twinstar 系列一致）；29949/29950/29952 脊门控完整 ✓；29951/29948/30077 发放者都在库 ✓。

---

## 八、四风谷全区任务链扫描（2026-09-28 15:20，QuestSortID=5805，共 181 个任务）

### A. starter 指向零刷新 entry（3 处，无影响）
30172→58785、30319→59594、30326→59517 均为同名 NPC 的冗余 entry（Mudmug/Haohan Mudclaw/Fish Fellreed），而正常刷新体 **56474/57402/58705 已有这三个任务的 starter 行**——任务都能接，死行属官方原样冗余，可不处理。

### B. 指针断链（4 处，全部正常）
30078→30085、30241→30174、30360→30445、30376→30273 均为跨 zone 衔接（酒坊副本/砥石镇/卡桑琅），非断链。

### C. 击杀/credit 目标零刷新甄别（核心结论：无需修复）
- 全区 133 个击杀/credit 目标 NPC 中 66 个本地零刷新且无本地 SAI credit。
- **官方 creature 表精确比对（抽出官方 creature 段 34MB 导入 official_creature 表核对）：66 个官方同样零刷新，零差异。**
- 此前粗 grep 得出的 11 个"官方有刷新"全部是 creature_loot_template 等表的巧合匹配（如 55375 是掉落物品非 NPC）。
- 结论：这批零刷新目标机制全在召唤/DBC 法术/事件/物品使用里（与 29947/29950、花 GO 同模式），DB 侧不存在也不需要修复。
- 已有本地自服增强的（29919/29952/30172 的 LOS credit、30073 定时脚本）维持不变。

### 总结论
**四风谷没有其他需要修复的任务链。** 陈/丽丽链的 5 项修复（门控+multi-gate+互斥清理）覆盖了全区唯一真问题。可选优化：清理 3 条冗余 starter 死行、以及半山日常（30319/30326 等）在零售中由解锁链开启的顺序问题——属日常解锁深水区，如需要另行专项核查。

### 附：SQL 更新文件合并（2026-09-28 15:12）
原 5 个分散更新（2026_09_28_00～04）已合并为单文件 `sql/updates/world/2026_09_28_00_world_chen_lili_questline_consolidated.sql`（PART 1~5 保留各原文件全部注释与机制备忘；PART 5 两处纯 INSERT 补了前置 DELETE 使整文件幂等）。合并文件已重放校验（54 条语句零失败、终态一致）并登记进 `updates` 表（RELEASED，SHA1 7F4EFBF6…），核心启动时不会重复执行；原 5 个文件已删除。下文各节提到的旧文件名均指向本合并文件对应 PART。
