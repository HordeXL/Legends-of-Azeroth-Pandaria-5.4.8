-- Expose the account wardrobe at ordinary, otherwise unscripted transmogrifiers.
UPDATE creature_template SET ScriptName='npc_transmogrifier', npcflag=npcflag | 1
WHERE (npcflag & 268435456) <> 0 AND ScriptName='' AND AIName='';
