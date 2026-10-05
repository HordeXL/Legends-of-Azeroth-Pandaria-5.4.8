-- At the Yak Wash (30491): process ridden yaks at the wash entrance.
UPDATE creature_template
SET AIName = '',
    ScriptName = 'npc_escaped_yak'
WHERE entry IN (59319, 61874);
