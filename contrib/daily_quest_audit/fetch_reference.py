#!/usr/bin/env python3
"""Cache public MoP quest reference pages; never edits the database."""
import concurrent.futures,csv,json,re,time,urllib.request
from pathlib import Path
root=Path(__file__).resolve().parent
cache=Path('/tmp/daily-quest-references');cache.mkdir(exist_ok=True)
rows=list(csv.DictReader((root/'triage.tsv').open(),delimiter='\t'))
ids=[int(r['quest']) for r in rows if r['status'] not in ('pet_battle_work_required','internal_tracking','placeholder_or_obsolete','implemented')]
def fetch(id):
 p=cache/(str(id)+'.html')
 try:
  if not p.exists():
   req=urllib.request.Request('https://mop-shoot.tauri.hu/?quest='+str(id),headers={'User-Agent':'Mozilla/5.0'})
   with urllib.request.urlopen(req,timeout=20) as r:p.write_bytes(r.read())
   time.sleep(.15)
  s=p.read_text(errors='replace');result={'id':id,'url':'https://mop-shoot.tauri.hu/?quest='+str(id),'exists':'<title>Error' not in s}
  for kind in ('start','end'):
   m=re.search('quest_'+kind+r'\.gif.*?</li>',s,re.S)
   result[kind]=[{'type':typ,'id':int(n)} for typ,n in re.findall(r'href="\?(npc|object|item)=(\d+)"',m[0])] if m else []
  result['seealso']=[int(x) for x in re.findall(r"id:'(\d+)'",s[s.find("id:'see-also'"):])]
  return result
 except Exception as e:return {'id':id,'error':str(e)}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
 results=list(pool.map(fetch,ids))
(root/'reference.json').write_text(json.dumps(results,indent=2)+'\n')
print('Fetched:',len(results),'Errors:',sum('error' in r for r in results),'with relations:',sum(bool(r.get('start') or r.get('end')) for r in results))
for r in results:
 if r.get('start') or r.get('end'):print(r)
