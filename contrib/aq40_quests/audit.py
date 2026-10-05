#!/usr/bin/env python3
"""Read-only consistency audit of an AQ40 quest/loot snapshot."""
import argparse
from collections import defaultdict
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('snapshot', type=Path)
args = parser.parse_args()
data = json.loads(args.snapshot.read_text())
errors = []

def check(condition, message):
    if not condition:
        errors.append(message)

quests = {int(q['ID']): q for q in data['quest_template']}
addons = {int(a['ID']): a for a in data['quest_template_addon']}
items = {int(i['entry']): i for i in data['item_template']}
npcs = {int(n['entry']): n for n in data['creature_template']}
objectives = defaultdict(list)
for objective in data['quest_objective']:
    objectives[int(objective['questId'])].append(objective)
starters, enders = defaultdict(set), defaultdict(set)
for r in data['creature_queststarter']:
    starters[int(r['quest'])].add(int(r['id']))
for r in data['creature_questender']:
    enders[int(r['quest'])].add(int(r['id']))

# Traverse reference chains from actual AQ40 creature/chest loot roots.
references = defaultdict(list)
for row in data['reference_loot_template']:
    references[int(row['entry'])].append(row)
available = set()

def walk(rows, path=(), group=0):
    for row in rows:
        if group and int(row['groupid']) != group:
            continue
        ref = int(row['mincountOrRef'])
        if ref < 0:
            check(-ref not in path, f'Loot reference cycle: {path}, {-ref}')
            check(-ref in references, f'Missing loot reference {-ref}')
            if -ref not in path:
                walk(references[-ref], path + (-ref,), int(row['groupid']))
        else:
            available.add(int(row['item']))

walk(data['creature_loot_template'] + data['gameobject_loot_template'])
external = {int(r['item']) for r in data['external_material_loot']}
objective_ids = set()
armor_count = 0
for qid, quest in quests.items():
    label = f'{qid} {quest["LogTitle"]}'
    check(bool(enders[qid]), f'{label}: no turn-in NPC')
    item_starts = any(int(i['startquest']) == qid for i in items.values())
    check(bool(starters[qid]) or item_starts, f'{label}: no quest starter')
    check(bool(objectives[qid]), f'{label}: no objectives')
    for npc in starters[qid] | enders[qid]:
        check(npc in npcs, f'{label}: missing NPC {npc}')
        if npc in npcs:
            check(int(npcs[npc]['npcflag']) & 2, f'{label}: NPC {npc} is not a questgiver')
        check(any(int(c['id']) == npc and int(c['phaseMask']) & 1 and
                  ((int(c['map']) == 531 and int(c['spawnMask']) & 512) or
                   (npc == 15192 and int(c['map']) == 1)) for c in data['creature']),
              f'{label}: NPC {npc} has no usable spawn')
    for objective in objectives[qid]:
        oid = int(objective['id'])
        check(oid not in objective_ids, f'Duplicate objective ID {oid}')
        objective_ids.add(oid)
        kind, item = int(objective['type']), int(objective['objectId'])
        check(kind in (1, 6), f'{label}: unreviewed objective type {kind}')
        if kind == 1:
            check(item in items, f'{label}: missing item {item}')
            check(item in available or item in external, f'{label}: no item source for {item}')
            check(int(objective['amount']) > 0, f'{label}: invalid required quantity')
            check(0 <= int(objective['index']) < 4, f'{label}: invalid item objective index')
        elif kind == 6:
            check(item == 910, f'{label}: unexpected reputation faction')
            check(int(objective['amount']) in (0, 3000, 9000), f'{label}: unexpected reputation threshold')
    if any(int(o['type']) == 6 for o in objectives[qid]):
        armor_count += 1
        check(int(addons.get(qid, {}).get('AllowableClasses', 0)) > 0, f'{label}: missing class restriction')
    for number in range(1, 7):
        item = int(quest[f'RewardChoiceItemID{number}'])
        if item:
            check(item in items, f'{label}: missing choice reward {item}')
            check(int(quest[f'RewardChoiceItemQuantity{number}']) > 0, f'{label}: empty reward quantity')
    for number in range(1, 5):
        item = int(quest[f'RewardItem{number}'])
        if item:
            check(item in items, f'{label}: missing guaranteed reward {item}')
    source_item = int(quest['StartItem'])
    if source_item:
        check(source_item in items, f'{label}: missing source item')
        check(int(addons.get(qid, {}).get('ProvidedItemCount', 0)) == 1, f'{label}: source item not provided')

for qid in (8595, 8784, 8789, 8790):
    check(int(addons.get(qid, {}).get('SpecialFlags', 0)) & 1, f'{qid}: missing repeatable flag')
check(int(addons[8595]['PrevQuestID']) == 8579, 'Mortal Champions prerequisite is broken')
check(int(addons[8802]['PrevQuestID']) == 8801, 'C\'Thun follow-up prerequisite is broken')
check(int(quests[8801]['RewardNextQuest']) == 8802, 'C\'Thun follow-up link is broken')
check(enders[8802] == {15192}, 'The Savior of Kalimdor must end at Anachronos')
check(not data['disables'], 'Quest disable entries require review')
check(not data['conditions'], 'Extra acceptance conditions require review')
print(f'Audited {len(quests)} quests, {armor_count} class armor quests, '
      f'{len(objective_ids)} objectives and {len(items)} item templates.')
print('External required material: Elementium Ingot (18562), Blackwing Technician.')
if errors:
    print('\n'.join('FAIL: ' + error for error in errors))
    raise SystemExit(1)
print('All audited database consistency checks passed. In-game end-to-end testing is still required.')
