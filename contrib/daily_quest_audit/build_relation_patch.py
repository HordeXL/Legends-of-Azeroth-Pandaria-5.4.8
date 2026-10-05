#!/usr/bin/env python3
"""Generate insert-only relation repairs from the reviewed MoP reference snapshot."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[2];folder=Path(__file__).resolve().parent
refs=json.loads((folder/'reference.json').read_text());out=['-- Restore documented questgiver/turn-in relations for non-pet daily quests.', '-- Reference URLs and review evidence: contrib/daily_quest_audit/reference.json.', '-- No existing relations, spawns or player records are deleted.']
givers=set();ids=[]
for q in refs:
 if not q.get('start'):continue
 ids.append(q['id'])
 for kind,table in [('start','creature_queststarter'),('end','creature_questender')]:
  for giver in q[kind]:
   assert giver['type']=='npc'
   id=giver['id'];givers.add(id)
   out.append(f'INSERT IGNORE INTO `{table}` (`id`,`quest`) VALUES ({id},{q["id"]});')
out.append('-- Enable questgiver menus while preserving trainer/vendor/gossip flags.')
out.append('UPDATE `creature_template` SET `npcflag`=`npcflag`|2 WHERE `entry` IN ('+','.join(map(str,sorted(givers)))+');')
out.append('-- Preserve explicit spawn flag overrides while enabling the same quest menus.')
out.append('UPDATE `creature` SET `npcflag`=`npcflag`|2 WHERE `npcflag`<>0 AND `id` IN ('+','.join(map(str,sorted(givers)))+');')
(root/'sql/patches/world/2026_09_26_05_world_daily_relations.sql').write_text('\n'.join(out)+'\n')
(folder/'relation_repair_ids.json').write_text(json.dumps(ids)+'\n')
print(len(ids),'quests;',len(givers),'giver templates')
