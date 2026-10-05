#!/usr/bin/env python3
"""Exercise Millhouse's production preparation and assist callbacks."""
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'src/server/scripts/Outland/TempestKeep/arcatraz/arcatraz.cpp').read_text()
def method(name):
 a=source.index('            void '+name+'(');b=source.index('{',a);depth=1;e=b+1
 while depth:depth+=(source[e]=='{')-(source[e]=='}');e+=1
 return source[a:e].replace(' override','')
enums=source[source.index('enum MillhouseSays'):source.index('class npc_millhouse_manastorm')]
harness=r'''
#include <cassert>
#include <list>
#include <map>
#include <vector>
#include <iostream>
using uint32=unsigned;
enum { UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_NPC=512, REACT_DEFENSIVE=1,
       TYPE_WARDEN_2=2, TYPE_HARBINGERSKYRISS=3, NOT_STARTED=0, IN_PROGRESS=1, DONE=2 };
ENUMS
struct Creature;
struct Unit {
 bool alive=true,combat=false,attackable=true,los=true;float distance=10;uint32 entry=0;
 virtual ~Unit()=default;
 bool IsAlive(){return alive;}bool IsInCombat(){return combat;}
 void SetInCombatWith(Unit*){combat=true;}
};
struct Motion { unsigned chases=0;void MoveChase(Unit*,float){++chases;} };
struct Creature : Unit {
 uint32 flags=576;Unit* victim=nullptr;Motion motion;std::vector<Creature*> nearby;
 void SetFlag(int,uint32 f){flags|=f;}void RemoveFlag(int,uint32 f){flags&=~f;}
 void SetReactState(int state){assert(state==REACT_DEFENSIVE);}
 bool CanCreatureAttack(Unit* who){return !(flags&UNIT_FLAG_IMMUNE_TO_NPC)&&who->alive&&who->attackable;}
 Unit* GetVictim(){return victim;}
 bool Attack(Unit* who,bool){victim=who;combat=true;return true;}
 void AddThreat(Unit*,float){}
 Motion* GetMotionMaster(){return &motion;}
 void GetCreatureListWithEntryInGridAppend(std::list<Creature*>& out,uint32 id,float range){
  for(auto c:nearby)if(c->entry==id && c->distance<=range)out.push_back(c);
 }
 bool IsWithinLOSInMap(Unit* who){return who->los;}
 float GetDistance(Unit* who){return who->distance;}
 bool IsNonMeleeSpellCasted(bool){return false;}
};
struct Instance {std::map<int,int> state;int GetData(int key){return state[key];}void SetData(int key,int value){state[key]=value;}};
struct AI {
 Creature* me;Instance* instance;
 uint32 EventProgress_Timer=0,Phase=0,Pyroblast_Timer=0,Fireball_Timer=0,Assist_Timer=0;
 bool Init=false,LowHp=false;unsigned attackSpells=0;
 void Talk(int){}void DoCast(Creature*,int){}
 void DoCastVictim(int){++attackSpells;}
 void DoMeleeAttackIfReady(){}
 bool HealthBelowPct(int){return false;}
 bool UpdateVictim(){return me->victim && me->victim->alive;}
METHODS
};
int main(){
 Creature millhouse,enemy,unrelated,idle,dead,blocked,closer;
 enemy.entry=20908;enemy.combat=true;enemy.distance=65;
 unrelated.entry=123;unrelated.combat=true;unrelated.distance=1;
 idle.entry=20912;idle.distance=1;
 dead.entry=20909;dead.combat=true;dead.alive=false;
 blocked.entry=20910;blocked.combat=true;blocked.los=false;
 closer.entry=20911;closer.combat=true;closer.distance=50;
 millhouse.nearby={&enemy,&unrelated,&idle,&dead,&blocked,&closer};
 Instance instance;instance.state[TYPE_HARBINGERSKYRISS]=IN_PROGRESS;
 AI ai;ai.me=&millhouse;ai.instance=&instance;ai.Reset();
 assert(!ai.Init && (millhouse.flags&512));
 ai.AttackStart(&enemy);assert(!millhouse.victim);
 for(int step=0;step<6;++step){ai.UpdateAI(20000);assert(!millhouse.victim && !ai.attackSpells);}
 ai.UpdateAI(20000);
 assert(ai.Init && !(millhouse.flags&512) && (millhouse.flags&64));
 assert(instance.GetData(TYPE_WARDEN_2)==DONE && millhouse.victim==&closer && ai.attackSpells);
 assert(millhouse.motion.chases==1);
 ai.AttackStart(&closer);assert(millhouse.motion.chases==1);
 closer.alive=false;millhouse.victim=nullptr;ai.UpdateAI(1000);
 assert(millhouse.victim==&enemy); // joins the next active enemy at 65 yards
 millhouse.victim=nullptr;enemy.combat=false;ai.AssistPlayers();assert(!millhouse.victim);
 enemy.combat=true;instance.state[TYPE_HARBINGERSKYRISS]=DONE;
 ai.AssistPlayers();ai.AttackStart(&enemy);assert(!millhouse.victim);
 // Reset after the intro restores readiness even if DB addon flags returned.
 millhouse.flags|=512;ai.Reset();assert(ai.Init && !(millhouse.flags&512));
 instance.state[TYPE_WARDEN_2]=NOT_STARTED;ai.Reset();assert(!ai.Init && (millhouse.flags&512));
 ai.instance=nullptr;ai.Reset();ai.AssistPlayers();assert(!millhouse.victim);
 std::cout<<"Millhouse preparation, NPC immunity, active-wave targeting and retarget checks passed\n";
}
'''.replace('ENUMS',enums).replace('METHODS','\n'.join(method(n) for n in ['Reset','AttackStart','AssistPlayers','UpdateAI']))
with tempfile.TemporaryDirectory(prefix='millhouse-test-') as d:
 d=Path(d);cpp=d/'test.cpp';cpp.write_text(harness);binary=d/'test'
 subprocess.run(['c++','-std=c++11','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
