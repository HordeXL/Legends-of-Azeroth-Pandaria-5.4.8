-- Getting Permission (29920): use the lethal-safe Pandriarch duel scripts.
-- The SmartAI health-percent event runs after damage and cannot prevent a
-- modern player or bot from killing these level-85 spirits in one hit.
UPDATE creature_template
SET AIName = '',
    ScriptName = CASE entry
        WHEN 56206 THEN 'npc_pandriarch_windfur'
        WHEN 56209 THEN 'npc_pandriarch_bramblestaff'
        WHEN 56210 THEN 'npc_pandriarch_goldendraft'
    END
WHERE entry IN (56206, 56209, 56210);
