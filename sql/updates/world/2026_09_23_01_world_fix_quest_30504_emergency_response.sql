-- Quest 30504 "Emergency Response" (紧急救援, Jade Forest 翡翠林)
--
-- Final behaviour: SELECT one of the four survivors and USE Cho's Fireworks
-- (86467) on it -> that objective is credited.
--
-- History / root cause:
--   * The item's original on-use spell 125700 is SPELL_EFFECT_SCRIPT_EFFECT (77)
--     with implicit target UNIT_CASTER (1).  SCRIPT_EFFECT spells need a spell
--     script; this core has no C++ implementation for 125700 and the DB side
--     (spell_scripts) was empty, so using the firework did nothing.
--   * Routing the item through spell 88797 (the Titanium Shackles rescue
--     spell) failed as well: 88797 carries conditions restricting its target to
--     the three Hillsbrad captives (2269/2270/2503, hp<=35%), so using it on
--     General Nazgrim and the others reported a "requires a battle survivor"
--     style target error.
--
-- Fix: the item now uses spell 80989 - a plain SPELL_EFFECT_DUMMY with implicit
-- target UNIT_TARGET_ANY (25) and NO conditions of any kind, so the client asks
-- for a selected target and the server lands the spell on it.  Each of the four
-- survivors credits its own 30504 objective when hit.
--
-- The original firework spell 125700 is removed from the item entirely: it is a
-- SPELL_EFFECT_SCRIPT_EFFECT spell that only works through a spell script this
-- core does not have, and while it sat in a second on-use slot the client still
-- validated its own target requirement and kept showing the "requires a battle
-- survivor" error next to the (successful) signal spell.
--
-- Note: the conditions on 88797 are deliberately left untouched, because that
-- spell is shared with the Titanium Shackles (63079) / Captured Human Proxy
-- rescue chain; 80989 has no restrictions at all, which gives the same effect
-- here without side effects elsewhere.
--
-- Apply notes: worldserver restart or ".reload item_template" +
-- ".reload smart_scripts".

-- 1) Cho's Fireworks: only the targeted signal spell remains on use.  The
--    original 125700 is dropped so its target requirement can no longer pop up.
UPDATE `item_template` SET
  `spellid_1` = 80989, `spelltrigger_1` = 0,
  `spellid_2` = 0,     `spelltrigger_2` = 0
WHERE `entry` = 86467;

-- 2) Drop the earlier "use it near the NPC" DB script - not needed any more.
DELETE FROM `spell_scripts` WHERE `id` = 125700;

-- 3) The four survivors credit their own objective when hit by the signal.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (64360, 64362, 64363, 64364) AND `source_type` = 0 AND `id` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(64360, 0, 1, 0, 8, 0, 100, 0, 80989, 0, 0, 0, 0, 33, 64360, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'On SpellHit firework - credit General Nazgrim rescue (30504)'),
(64362, 0, 1, 0, 8, 0, 100, 0, 80989, 0, 0, 0, 0, 33, 64362, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'On SpellHit firework - credit Shademaster Kiryn rescue (30504)'),
(64363, 0, 1, 0, 8, 0, 100, 0, 80989, 0, 0, 0, 0, 33, 64363, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'On SpellHit firework - credit Shokia rescue (30504)'),
(64364, 0, 1, 0, 8, 0, 100, 0, 80989, 0, 0, 0, 0, 33, 64364, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'On SpellHit firework - credit Rivett Clutchpop rescue (30504)');
