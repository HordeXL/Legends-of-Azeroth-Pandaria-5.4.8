-- Quest 2742: Rin'ji is Trapped!
-- The restored npc_escortAI implementation consumes the existing authentic
-- 24-row script_waypoint path directly; do not delete or convert that path.
UPDATE `creature_template`
SET `AIName`='', `ScriptName`='npc_rinji'
WHERE `entry`=7780;
