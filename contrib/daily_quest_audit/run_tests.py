#!/usr/bin/env python3
"""Exercise the production Isle of Thunder interactions, not a reimplementation."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
s=(root/'src/server/scripts/Pandaria/zone_isle_of_thunder.cpp').read_text()
code=s[s.index('namespace ThunderDaily'):s.index('class go_thunder_isle_altar')].replace(' override','')
fixture=r'''
#include <cassert>
#include <map>
using uint32=unsigned;
constexpr int QUEST_STATUS_INCOMPLETE=1;
constexpr float INTERACTION_DISTANCE=5;
struct Player {
 bool alive=true,bombs=true,incomplete=true;unsigned quest=0,credit=0,count=0;
 std::map<unsigned,unsigned> counters,credits;
 bool IsAlive(){return alive;}
 int GetQuestStatus(unsigned q){return q==quest&&incomplete?QUEST_STATUS_INCOMPLETE:0;}
 unsigned GetQuestObjectiveCounter(unsigned c){return counters[c];}
 bool HasItemCount(unsigned id,unsigned n){assert(id==94905&&n==1);return bombs;}
 void KilledMonsterCredit(unsigned c,int=0,unsigned n=1){credit=c;count+=n;credits[c]+=n;}
};
struct Quest {unsigned id;unsigned GetQuestId()const{return id;}};
struct ObjectGuid {static constexpr int Empty=0;};
struct PlayerScript {explicit PlayerScript(char const*){}};
struct Creature {bool present=true;void DespawnOrUnsummon(){assert(present);present=false;}};
struct GameObject {
 unsigned entry=0,map=1064,captiveEntry=0,anims=0;bool near=true;Creature captive;
 unsigned GetEntry(){return entry;}unsigned GetMapId(){return map;}
 bool IsWithinDistInMap(Player*,float d){assert(d==5);return near;}
 Creature* FindNearestCreature(unsigned e,float d,bool alive){assert(d==3&&alive);return captive.present&&e==captiveEntry?&captive:nullptr;}
 unsigned GetGoAnimProgress(){return 255;}
 void SendCustomAnim(unsigned p){assert(p==255);++anims;}
};
struct GameObjectScript {explicit GameObjectScript(char const*){}};
// CODE
int main(){
 player_thunder_daily_autocomplete automatic;
 unsigned const quests[]={32262,32636,32268,32628,999};
 for(unsigned id:quests){
  Quest q{id};Player p;p.quest=id;automatic.OnQuestAdded(&p,&q);
  unsigned expected=0;
  for(auto const& o:ThunderDaily::Objectives)if(o.quest==id){
   assert(p.credits[o.credit]==o.required);expected+=o.required;
  }
  assert(p.count==expected);
  Player complete;complete.quest=id;complete.incomplete=false;
  automatic.OnQuestAdded(&complete,&q);assert(!complete.count);
  Player unrelated;automatic.OnQuestAdded(&unrelated,&q);assert(!unrelated.count);
 }
 go_thunder_daily_objective script;
 for(auto const& o:ThunderDaily::Objectives){
  Player p;p.quest=o.quest;GameObject g;g.entry=o.object;g.captiveEntry=o.credit;
  script.OnGossipHello(&p,&g);assert(p.count==1&&p.credit==o.credit&&g.anims==1);
  p.counters[o.counter]=1;
  script.OnGossipHello(&p,&g);assert(p.count==1); // no duplicate captive/bomb credit
  if(o.required==5){ // another captive may advance, but stop at five
   g.captive.present=true;script.OnGossipHello(&p,&g);assert(p.count==2);
   g.captive.present=true;p.counters[o.counter]=5;script.OnGossipHello(&p,&g);assert(p.count==2&&g.captive.present);
  }
  for(int failure=0;failure<7;++failure){
   Player bad;bad.quest=o.quest;GameObject go;go.entry=o.object;go.captiveEntry=o.credit;
   if(failure==0)bad.alive=false;
   if(failure==1)go.map=870;
   if(failure==2)go.near=false;
   if(failure==3)bad.quest=0;
   if(failure==4)bad.counters[o.counter]=o.required;
   if(failure==5){if(o.required==5)go.captive.present=false;else bad.bombs=false;}
   if(failure==6)go.entry=999;
   script.OnGossipHello(&bad,&go);assert(!bad.count&&!go.anims);
  }
 }
 // Assert geographic mappings independently: bridge is at waterline, crystals on hill.
 assert(ThunderDaily::Objectives[6].credit==69607);
 assert(ThunderDaily::Objectives[7].credit==69605);
}
'''
with tempfile.TemporaryDirectory(prefix='thunder-dailies-') as d:
 p=Path(d);(p/'test.cpp').write_text(fixture.replace('// CODE',code))
 subprocess.run(['c++','-std=c++11','-Wall','-Wextra','-Werror','-fsanitize=undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True)
print('PASS: automatic credit for four quests, all eight object mappings, both factions, empty prisons, repeat clicks, objective caps, item/status/range/map/death guards')
