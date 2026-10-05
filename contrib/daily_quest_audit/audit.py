#!/usr/bin/env python3
"""Read-only world database daily quest audit. No character/account queries."""
import argparse,csv,io,json,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--defaults-file',required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent

def query(sql):
 r=subprocess.run(['mariadb','--defaults-extra-file='+a.defaults_file,'--batch','-e',sql],check=True,capture_output=True,text=True)
 return list(csv.DictReader(io.StringIO(r.stdout),delimiter='\t',quoting=csv.QUOTE_NONE))
quests=query('SELECT q.ID,q.LogTitle,q.Flags,q.QuestSortID,q.MinLevel,q.QuestType,q.StartItem,COALESCE(a.PrevQuestID,0) PrevQuestID,COALESCE(a.RequiredMinRepFaction,0) MinFaction,COALESCE(a.RequiredMaxRepFaction,0) MaxFaction,COALESCE(a.RequiredMinRepValue,0) MinRep,COALESCE(a.RequiredMaxRepValue,0) MaxRep FROM quest_template q LEFT JOIN quest_template_addon a ON a.ID=q.ID WHERE q.Flags & 4096 ORDER BY q.ID')
active={int(q['ID']):q for q in quests if not int(q['Flags'])&16384}
findings=[]
automatic={int(r['id']) for r in query('SELECT firstQuestId id FROM lfg_dungeon_rewards UNION SELECT otherQuestId id FROM lfg_dungeon_rewards')}
placeholder={id for id,q in active.items() if re.search(r'NOT USED|UNUSED|TEST QUEST|NYI|\btest\b',q['LogTitle'],re.I)}
ai_overlaps=[]
def add(id,kind,confidence,detail):
 if int(id) in active: findings.append(dict(quest=int(id),title=active[int(id)]['LogTitle'],category=kind,confidence=confidence,detail=detail))
for r in query('SELECT questId,comment FROM broken_quests'):
 add(r['questId'],'marked_broken','recorded',r['comment'])
for r in query('SELECT entry,comment FROM disables WHERE sourceType=1'):
 add(r['entry'],'disabled','recorded',r['comment'])
for q in active.values():
 if q['MinFaction']!='0' and q['MinFaction']==q['MaxFaction'] and int(q['MinRep'])>=int(q['MaxRep']):add(q['ID'],'impossible_reputation','confirmed','Same faction minimum >= exclusive maximum')
 if int(q['PrevQuestID'])==int(q['ID']):add(q['ID'],'self_prerequisite','confirmed','Quest requires itself')
for r in query('SELECT a.ID,a.PrevQuestID FROM quest_template_addon a LEFT JOIN quest_template q ON q.ID=ABS(a.PrevQuestID) WHERE a.PrevQuestID<>0 AND q.ID IS NULL'):
 add(r['ID'],'missing_prerequisite','confirmed','Missing quest '+r['PrevQuestID'])
for r in query('SELECT a.ID,a.MaxLevel,q.MinLevel FROM quest_template_addon a JOIN quest_template q ON q.ID=a.ID WHERE a.MaxLevel<>0 AND a.MaxLevel<q.MinLevel'):
 add(r['ID'],'impossible_level','confirmed',str(r))
for kind,tables in [('starter',['creature_queststarter','gameobject_queststarter']),('ender',['creature_questender','gameobject_questender'])]:
 ids=set()
 for t in tables:ids|={int(r['quest']) for r in query('SELECT DISTINCT quest FROM '+t)}
 if kind=='starter':ids|={int(r['startquest']) for r in query('SELECT DISTINCT startquest FROM item_template WHERE startquest<>0')}
 for id,q in active.items():
  auto=int(q['Flags'])&(1024|65536|(524288|2097152 if kind=='starter' else 1048576))
  if id not in ids and id not in automatic and id not in placeholder and not auto and int(q['QuestType'])!=0:add(id,'missing_'+kind,'suspected','No static NPC/object'+('/item' if kind=='starter' else '')+' relation; script/automatic handling must be checked')
# Credit targets may be summoned or virtual credits: never classify absence of a spawn as confirmed.
for r in query('SELECT o.questId,o.id,o.type,o.objectId,o.description FROM quest_objective o JOIN quest_template q ON q.ID=o.questId LEFT JOIN creature_template c ON c.entry=o.objectId LEFT JOIN item_template i ON i.entry=o.objectId LEFT JOIN gameobject_template g ON g.entry=o.objectId WHERE q.Flags & 4096 AND ((o.type IN (0,3) AND c.entry IS NULL) OR (o.type=1 AND i.entry IS NULL) OR (o.type=2 AND g.entry IS NULL))'):
 add(r['questId'],'missing_objective_template','confirmed',str(r))
# Database script bindings absent from source are candidates, not proof of missing implementation.
source='\n'.join(f.read_text(errors='replace') for f in (root/'src').rglob('*.cpp'))
relations=query('SELECT r.quest,c.entry,c.name,c.ScriptName,c.AIName FROM creature_queststarter r JOIN creature_template c ON c.entry=r.id UNION SELECT r.quest,c.entry,c.name,c.ScriptName,c.AIName FROM creature_questender r JOIN creature_template c ON c.entry=r.id')
seen=set()
for r in relations:
 key=(r['quest'],r['entry']);script=r['ScriptName']
 if key in seen:continue
 seen.add(key)
 if script and script not in source:add(r['quest'],'missing_giver_script','suspected','NPC '+r['entry']+' '+r['name']+': '+script)
 if int(r['quest']) in active and script and r['AIName']=='SmartAI':ai_overlaps.append(r)
# Nonzero ceilings are often intentional progression gates; report separately for manual review.
ceilings=[q for q in active.values() if int(q['MaxFaction'])]
summary={'daily_total':len(quests),'deprecated_excluded':len(quests)-len(active),'non_deprecated':len(active),'unique_flagged':len({f['quest'] for f in findings}),'confirmed':len({f['quest'] for f in findings if f['confidence']=='confirmed'}),'recorded_disabled_or_broken':len({f['quest'] for f in findings if f['confidence']=='recorded'}),'suspected':len({f['quest'] for f in findings if f['confidence']=='suspected'}),'reputation_ceilings_for_review':len(ceilings),'automatic_lfg_dailies':len(set(active)&automatic),'placeholder_dailies':len(placeholder)}
for category in sorted({f['category'] for f in findings}):summary[category]=len({f['quest'] for f in findings if f['category']==category})
(out/'report.json').write_text(json.dumps(dict(summary=summary,findings=findings,reputation_ceilings=ceilings,ai_overlaps=ai_overlaps),indent=2,ensure_ascii=False)+'\n')
with (out/'findings.tsv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=['quest','title','category','confidence','detail'],delimiter='\t');w.writeheader();w.writerows(findings)
print(json.dumps(summary,indent=2))
