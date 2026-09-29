-- Quest 29919 "Great Minds Drink Alike" (英雄所喝略同): escort must start via gossip option
--
-- User-tested design: accept quest from Chen 56133 -> TALK to Chen -> select gossip option -> escort starts.
--
-- Root cause of "no option in dialog":
--   The only existing option (MenuID=56133, OptionID=0) is condition-gated to CONDITION_QUESTTAKEN(30078)
--   (another quest's teleport flow), so while on 29919 the menu renders with zero options.
--   Additionally gossip_menu has no text row for NPC 56133.
--
-- Previous fix (SQL 06) auto-started the escort on quest ACCEPT; retail flow requires the option,
-- so this script rewires the trigger chain to GOSSIP_SELECT(62) and drives Li Li via Script9
-- (her old ACCEPTED_QUEST row could never fire anyway - the event is only delivered to the giver).
--
-- Chain (Chen 56133 entry-level):
--   GOSSIP_SELECT(menu 56133, option 1) -> SET_RUN -> MOVE_TO_POS(Mudmug side)
--   -> CLOSE_GOSSIP(invoker) -> MOVEMENTINFORM(2991901) -> CALL_KILLEDMONSTER(56571, invoker)
--   -> timed 4s -> MOVE_TO_POS(back home)
--   and CALL_TIMED_ACTIONLIST(2991905) on Li Li 56138 (Script9: set run -> walk to Mudmug -> walk home)

-- ============ Gossip: menu text + option gated to quest 29919 taken ============
DELETE FROM gossip_menu WHERE MenuID=56133;
INSERT INTO gossip_menu (MenuID, TextID, VerifiedBuild) VALUES (56133, 56133, 0);

DELETE FROM npc_text WHERE ID=56133;
INSERT INTO npc_text (ID, text0_0, text0_1, BroadcastTextID0, lang0, Probability0) VALUES
(56133, '走吧，丽丽！我们去找泥盏，正好尝尝新酿的酒。', '', 0, 0, 1);

DELETE FROM gossip_menu_option WHERE MenuID=56133 AND OptionID=1;
INSERT INTO gossip_menu_option (MenuID, OptionID, OptionIcon, OptionText, OptionBroadcastTextID, OptionType, OptionNpcflag, ActionMenuID, ActionPoiID, BoxCoded, BoxMoney, BoxText, BoxBroadcastTextID, VerifiedBuild) VALUES
(56133, 1, 0, '我们走吧，去泥盏那儿！', 0, 1, 1, 0, 0, 0, 0, NULL, 0, 0);

DELETE FROM conditions WHERE SourceTypeOrReferenceId=15 AND SourceGroup=56133 AND SourceEntry=1;
INSERT INTO conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorType, ErrorTextId, ScriptName, Comment) VALUES
(15, 56133, 1, 0, 0, 9, 0, 29919, 0, 0, 0, 0, 0, '', '29919 escort option - show while quest taken');

-- ============ Chen 56133: rewire accept-trigger -> gossip-select trigger ============
-- id6 was ACCEPTED_QUEST(29919); becomes GOSSIP_SELECT(menu 56133 option 1). link chain kept.
UPDATE smart_scripts SET event_type=62, event_param1=56133, event_param2=1,
  comment='Chen - Gossip Select Option 1 (29919) - Set Run'
WHERE source_type=0 AND entryorguid=56133 AND id=6;

-- id7 (LINK -> MOVE_TO_POS Mudmug side) now chains to close-gossip row
UPDATE smart_scripts SET link=11,
  comment='Chen - Link - Walk To Mudmug (escort)'
WHERE source_type=0 AND entryorguid=56133 AND id=7;

-- id11: close the gossip window on option click (target = invoker player)
DELETE FROM smart_scripts WHERE source_type=0 AND entryorguid=56133 AND id=11;
INSERT INTO smart_scripts (entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_x, target_y, target_z, target_o, comment) VALUES
(56133, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Chen - Link - Close Gossip');

-- id8 (MOVEMENTINFORM -> credit), id9 (timed 4s), id10 (walk home) unchanged from SQL 06.

-- ============ Li Li 56138: replace dead accept-trigger rows with Script9 ============
DELETE FROM smart_scripts WHERE source_type=0 AND entryorguid=56138 AND id BETWEEN 0 AND 3;
DELETE FROM smart_scripts WHERE source_type=9 AND entryorguid=2991905;
INSERT INTO smart_scripts (entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_x, target_y, target_z, target_o, comment) VALUES
(2991905, 9, 0, 0, 0, 0, 100, 0, 500, 500, 0, 0, 59, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Li Li Script9 - Set Run'),
(2991905, 9, 1, 0, 0, 0, 100, 0, 500, 500, 0, 0, 69, 2991901, 0, 0, 0, 0, 0, 0, 0, 0, 0, -698.0, 1269.0, 136.0, 0, 'Li Li Script9 - Walk To Mudmug'),
(2991905, 9, 2, 0, 0, 0, 100, 0, 10000, 10000, 0, 0, 69, 2991902, 0, 0, 0, 0, 0, 0, 0, 0, 0, -695.818, 1253.36, 136.024, 0, 'Li Li Script9 - Walk Back Home');
