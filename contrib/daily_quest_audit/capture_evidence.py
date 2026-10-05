#!/usr/bin/env python3
"""Read-only world evidence for the original audit candidate set."""
import argparse,csv,io,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--defaults-file',required=True);a=p.parse_args()
root=Path(__file__).resolve().parent
ids=','.join(str(r['ID']) for r in json.loads((root/'candidates.json').read_text()))
def query(sql):
 r=subprocess.run(['mariadb','--defaults-extra-file='+a.defaults_file,'--batch','-e',sql],capture_output=True,text=True,check=True)
 return list(csv.DictReader(io.StringIO(r.stdout),delimiter='\t',quoting=csv.QUOTE_NONE))
r={}
r['variants']=query('SELECT DISTINCT q.ID,q.LogTitle,q.Flags,q.QuestType,q.MinLevel,q.QuestSortID,(SELECT GROUP_CONCAT(id ORDER BY id) FROM creature_queststarter s WHERE s.quest=q.ID) starters,(SELECT GROUP_CONCAT(id ORDER BY id) FROM creature_questender s WHERE s.quest=q.ID) enders,(SELECT GROUP_CONCAT(id ORDER BY id) FROM gameobject_queststarter s WHERE s.quest=q.ID) go_starters,(SELECT GROUP_CONCAT(id ORDER BY id) FROM gameobject_questender s WHERE s.quest=q.ID) go_enders,(SELECT GROUP_CONCAT(entry ORDER BY entry) FROM item_template s WHERE s.startquest=q.ID) items FROM quest_template c JOIN quest_template q ON q.LogTitle=c.LogTitle WHERE c.ID IN ('+ids+') ORDER BY q.ID')
r['objectives']=query('SELECT * FROM quest_objective WHERE questId IN ('+ids+') ORDER BY questId,`index`')
r['addons']=query('SELECT * FROM quest_template_addon WHERE ID IN ('+ids+')')
r['conditions']=query('SELECT * FROM conditions WHERE SourceTypeOrReferenceId IN (19,20,23) AND SourceEntry IN ('+ids+')')
r['pools']=query('SELECT * FROM pool_quest WHERE entry IN ('+ids+')')
(root/'evidence.json').write_text(json.dumps(r,indent=2)+'\n')
print({key:len(value) for key,value in r.items()})
