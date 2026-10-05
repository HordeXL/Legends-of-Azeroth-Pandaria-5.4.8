#!/usr/bin/env python3
"""Compile the production Bite script against a small interaction harness."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/scripts/Outland/CoilfangReservoir/TheSlavePens/boss_quagmirran.cpp').read_text()
script = source[source.index('enum eQuestMisc'):source.index('void AddSC_boss_quagmirran')]
harness = r'''
#include <cassert>
#include <map>
#include <memory>
#include <iostream>
using uint32 = unsigned;
using int32 = int;
enum { QUEST_STATUS_INCOMPLETE=1, QUEST_STATUS_COMPLETE=2,
       GOSSIP_SENDER_MAIN=1, GOSSIP_ACTION_INFO_DEF=1000, GO_STATE_ACTIVE=0 };
struct Position {};
struct GameObject { int openings=0; void SetGoState(int) { ++openings; } };
struct Motion { int moves=0; void MovePoint(int, Position const&) { ++moves; } };
struct CreatureAI {
 virtual ~CreatureAI() = default;
 virtual void Reset() {}
 virtual void DoAction(int32) {}
};
struct Creature {
 CreatureAI* ai=nullptr; GameObject cage; Motion motion; bool hasCage=true, walk=true;
 CreatureAI* AI() { return ai; }
 GameObject* FindNearestGameObject(uint32 entry,float) {
  assert(entry==182094); return hasCage ? &cage : nullptr;
 }
 Position GetNearPosition(float,float) { return {}; }
 void SetWalk(bool value) { walk=value; }
 Motion* GetMotionMaster() { return &motion; }
 bool IsQuestGiver() { return false; }
 uint32 GetGUID() { return 72406; }
 uint32 GetEntry() { return 17893; }
};
struct ScriptedAI : CreatureAI { Creature* me; ScriptedAI(Creature* c):me(c){} };
struct Menu { void ClearMenus() {} };
struct Player {
 Menu menu; Menu* PlayerTalkClass=&menu;
 std::map<uint32,int> quests; int credits=0, options=0;
 int GetQuestStatus(uint32 id) { return quests[id]; }
 void KilledMonsterCredit(uint32 id) { assert(id==17893); ++credits; }
 void PrepareQuestMenu(uint32) {}
 void CLOSE_GOSSIP_MENU() {}
 uint32 GetDefaultGossipMenuForSource(Creature*) { return 7520; }
 void ADD_GOSSIP_ITEM_DB(uint32,uint32,uint32,uint32) { ++options; }
 uint32 GetGossipTextId(Creature*) { return 9119; }
 void SEND_GOSSIP_MENU(uint32,uint32) {}
};
struct CreatureScript {
 CreatureScript(char const*) {}
 virtual ~CreatureScript()=default;
 virtual CreatureAI* GetAI(Creature*) const { return nullptr; }
 virtual bool OnGossipHello(Player*,Creature*) { return false; }
 virtual bool OnGossipSelect(Player*,Creature*,uint32,uint32) { return false; }
};
SCRIPT
int main() {
 npc_naturalist_bite script; Creature bite;
 std::unique_ptr<CreatureAI> ai(script.GetAI(&bite)); bite.ai=ai.get(); ai->Reset();
 Player current,legacy,none,completed;
 current.quests[29563]=QUEST_STATUS_INCOMPLETE;
 legacy.quests[9738]=QUEST_STATUS_INCOMPLETE;
 completed.quests[29563]=QUEST_STATUS_COMPLETE;
 script.OnGossipHello(&current,&bite); assert(current.credits==1);
 script.OnGossipSelect(&current,&bite,0,1001);
 script.OnGossipSelect(&current,&bite,1,1002);
 assert(bite.motion.moves==0 && bite.cage.openings==0);
 script.OnGossipSelect(&current,&bite,1,1001);
 assert(bite.motion.moves==1 && bite.cage.openings==1 && !bite.walk);
 // Another player's discovery remains available after the release.
 script.OnGossipHello(&legacy,&bite); assert(legacy.credits==1);
 script.OnGossipSelect(&legacy,&bite,1,1001);
 assert(bite.motion.moves==1 && bite.cage.openings==1);
 script.OnGossipHello(&none,&bite); script.OnGossipHello(&completed,&bite);
 assert(!none.credits && !completed.credits && none.options==1);
 // A missing cage must not block quest credit or crash release.
 ai->Reset(); bite.hasCage=false;
 script.OnGossipSelect(&none,&bite,1,1001); assert(bite.motion.moves==2);
 std::cout << "Bite: both quests, independent discovery, release, duplicate/invalid actions and missing cage passed\n";
}
'''.replace('SCRIPT', script)
with tempfile.TemporaryDirectory(prefix='bite-test-') as directory:
    directory = Path(directory)
    cpp = directory / 'test.cpp'
    cpp.write_text(harness)
    binary = directory / 'test'
    subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
