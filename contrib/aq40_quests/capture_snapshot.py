#!/usr/bin/env python3
"""Read-only AQ40 database snapshot. No player data is queried."""
import re,subprocess,os,csv,io,json
s=open('/usr/local/etc/worldserver.conf').read();v=re.search(r'^WorldDatabaseInfo\s*=\s*"([^"]+)"',s,re.M).group(1).split(';')
def query(sql):
 r=subprocess.run(['mysql','--batch','-h',v[0],'-P',v[1],'-u',v[2],v[4],'-e',sql],env=dict(os.environ,MYSQL_PWD=v[3]),capture_output=True,check=True)
 return list(csv.DictReader(io.StringIO(r.stdout.decode().replace(chr(13), chr(92)+'r')),delimiter=chr(9),quoting=csv.QUOTE_NONE))
npcs='15378,15379,15380,15502,15503,15504'
a=query('SELECT id,quest FROM creature_queststarter WHERE id IN ('+npcs+')');b=query('SELECT id,quest FROM creature_questender WHERE id IN ('+npcs+')')
ids=','.join(map(str,sorted({int(r['quest']) for r in a+b})))
d={}
for t,col in [('quest_template','ID'),('quest_template_addon','ID'),('quest_objective','questId'),('quest_request_items','ID'),('quest_offer_reward','ID'),('creature_queststarter','quest'),('creature_questender','quest')]:d[t]=query('SELECT * FROM '+t+' WHERE '+col+' IN ('+ids+')')
d['creature_template']=query('SELECT entry,name,npcflag,faction,ScriptName,lootid FROM creature_template WHERE entry IN ('+npcs+',15192)')
d['creature']=query('SELECT guid,id,map,spawnMask,phaseMask,npcflag FROM creature WHERE id IN ('+npcs+',15192)')
d['disables']=query('SELECT * FROM disables WHERE sourceType=1 AND entry IN ('+ids+')')
d['conditions']=query('SELECT * FROM conditions WHERE SourceTypeOrReferenceId IN (19,20) AND SourceEntry IN ('+ids+')')
items={int(o['objectId']) for o in d['quest_objective'] if o['type']=='1'}
for q in d['quest_template']:
 for k,value in q.items():
  if k=='StartItem' or re.fullmatch(r'RewardItem[1-4]|RewardChoiceItemID[1-6]',k):
   if int(value):items.add(int(value))
d['item_template']=query('SELECT entry,name,startquest,maxcount,stackable,AllowableClass,Flags,FlagsExtra FROM item_template WHERE entry IN ('+','.join(map(str,sorted(items)))+')')
creatures=query('SELECT DISTINCT c.id,t.lootid FROM creature c JOIN creature_template t ON t.entry=c.id WHERE c.map=531 AND t.lootid<>0')
d['loot_creatures']=creatures
lootids=','.join(sorted({c['lootid'] for c in creatures}))
d['creature_loot_template']=query('SELECT * FROM creature_loot_template WHERE entry IN ('+lootids+')')
d['gameobject']=query('SELECT g.guid,g.id,g.spawnMask,g.phaseMask,t.name,t.type,t.data0,t.data1 FROM gameobject g JOIN gameobject_template t ON t.entry=g.id WHERE g.map=531')
go_ids={g['data1'] for g in d['gameobject'] if g['type']=='3'}
d['gameobject_loot_template']=query('SELECT * FROM gameobject_loot_template WHERE entry IN ('+','.join(go_ids)+')') if go_ids else []
refs={-int(r['mincountOrRef']) for r in d['creature_loot_template']+d['gameobject_loot_template'] if int(r['mincountOrRef'])<0};seen=set();d['reference_loot_template']=[]
while refs-seen:
 current=refs-seen;seen|=current
 rows=query('SELECT * FROM reference_loot_template WHERE entry IN ('+','.join(map(str,current))+')');d['reference_loot_template']+=rows
 refs|={-int(r['mincountOrRef']) for r in rows if int(r['mincountOrRef'])<0}
# External crafting materials are deliberately audited separately from raid loot.
d['external_material_loot']=query('SELECT l.*,c.entry AS creature_entry,c.name FROM creature_loot_template l LEFT JOIN creature_template c ON c.lootid=l.entry WHERE l.item=18562 AND l.mincountOrRef>0')
from pathlib import Path
with Path(__file__).with_name('snapshot.json').open('w') as f:json.dump(d,f,indent=2,ensure_ascii=False)
print('Snapshot:',len(d['quest_template']),'quests;',len(d['quest_objective']),'objectives;',len(d['item_template']),'items')
