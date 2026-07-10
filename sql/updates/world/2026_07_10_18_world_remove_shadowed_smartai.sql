-- These templates are intentionally controlled by registered C++ scripts.
-- Their source_type 0 SmartAI rows are unreachable and produce loader warnings.
DELETE ss
FROM `smart_scripts` ss
JOIN `creature_template` ct ON ct.`entry`=ss.`entryorguid`
WHERE ss.`source_type`=0
  AND (ct.`entry`,ct.`ScriptName`) IN
  (
    (18166,'npc_khadgar'),
    (25967,'npc_zephyr'),
    (31848,'npc_zidormi_dalaran'),
    (64267,'npc_kraxik_tornado'),
    (64656,'celestial_experience_sha')
  );
