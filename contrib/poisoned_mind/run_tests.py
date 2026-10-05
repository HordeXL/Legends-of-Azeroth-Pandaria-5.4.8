#!/usr/bin/env python3
"""Compile the production vehicle callbacks with a deterministic world fixture."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
src = (root / 'src/server/scripts/Pandaria/quest_poisoned_mind.cpp').read_text()
code = src[src.index('namespace PoisonedMind'):src.index('class npc_xaril_poisoned_mind')].replace(' override', '').replace('ObjectGuid::Empty', '0')
fixture = r'''
#include <cassert>
#include <algorithm>
#include <vector>
#include <set>
using uint32=unsigned; using uint8=unsigned char; using int8=signed char; using int32=int;
using ObjectGuid=int;
enum { MINUTE=60, IN_MILLISECONDS=1000, QUEST_STATUS_INCOMPLETE=1, REACT_PASSIVE,
MOVE_FLIGHT, UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_NPC, UNIT_FIELD_NPC_FLAGS,
UNIT_NPC_FLAG_SPELLCLICK, TEMPSUMMON_MANUAL_DESPAWN, UNIT_FLAG_DISABLE_MOVE, POINT_MOTION_TYPE };
constexpr float INVALID_HEIGHT=-100000;
struct Position {
 float x,y,m_positionZ,o;
 float GetPositionX() const {return x;} float GetPositionY() const {return y;}
 float GetPositionZ() const {return m_positionZ;} float GetOrientation() const {return o;}
};
struct Player; struct Creature;
struct Unit { virtual Player* ToPlayer(){return nullptr;} virtual int GetGUID(){return 1;} virtual Player* GetCharmerOrOwnerPlayerOrPlayerItself(){return nullptr;} };
struct Player:Unit {
 Creature* vehicle=nullptr; int status=1, talk=0, teleports=0; bool alive=true, online=true;
 unsigned mantid=0,kunchong=0; int activeQuest=31211;
 unsigned GetQuestObjectiveCounter(unsigned id){assert(id==unsigned(activeQuest==31216?268422:268421)||id==unsigned(activeQuest==31216?268882:268881));return (id==268421||id==268422)?mantid:kunchong;}
 void KilledMonsterCredit(unsigned entry,int,unsigned count){if(entry==63613)mantid+=count;else kunchong+=count;}
 Position pos{10,20,30,0};
 Player* ToPlayer(){return this;} bool IsAlive(){return alive;}
 int GetQuestStatus(int id){return id==activeQuest?status:0;} int GetFaction(){return 1;}
 Position GetPosition(){return pos;} Creature* GetVehicleBase(){return vehicle;}
 void ExitVehicle(){vehicle=nullptr;}
 void NearTeleportTo(float x,float y,float z,float o){pos={x,y,z,o};++teleports;}
 void TalkedToCreature(int id,int){assert(id==62151);++talk;}
 void SetClientControl(Creature*,bool){}
};
struct Map { bool invalid=false; float GetHeight(int,float,float,float z,bool,float){assert(z>=1000);return invalid?INVALID_HEIGHT:72.0f;} };
struct Motion {
 int moves=0; uint32 last=0;
 Position destination{0,0,0,0};
 void MovePoint(uint32 id,Position pos,bool path){assert(!path);++moves;last=id;destination=pos;}
};
struct Creature:Unit {
 int guid=1,entry=63613; int GetGUID(){return guid;} int GetEntry(){return entry;}
 void SetLootRecipient(Player*){} unsigned GetMaxHealth(){return 100;} void LowerPlayerDamageReq(unsigned){}
 Map map; Motion motion; int despawns=0, spawned=0, mantids=0, kunchong=0, failAfter=-1;
 Position pos{10,20,30,0};
 void DespawnOrUnsummon(uint32=0){++despawns;}
 void SetFaction(int){} void SetReactState(int){} void SetCanFly(bool){}
 void SetDisableGravity(bool){} void SetWalk(bool){} void SetSpeed(int,float){} void SetFlag(int,int){}
 void RemoveFlag(int,int){} Motion* GetMotionMaster(){return &motion;}
 Map* GetMap(){return &map;} int GetPhaseMask(){return 1;} Position GetPosition(){return pos;}
 Creature* SummonCreature(uint32 entry,Position,int,int,int,int){
  if(spawned==failAfter)return nullptr;
  ++spawned; if(entry==63613)++mantids;else if(entry==63625)++kunchong;else assert(false);
  return this;
 }
};
struct SummonList {
 int cleanups=0; explicit SummonList(Creature*){}
 void Summon(Creature*){} void Despawn(Creature*){} void DespawnAll(){++cleanups;}
};
struct ScriptedAI {Creature* me; explicit ScriptedAI(Creature* c):me(c){} };
struct SpellInfo {uint32 Id;};
namespace ObjectAccessor {
 Player* player=nullptr;
 Player* GetPlayer(Creature&,int){return player&&player->online?player:nullptr;}
}
// CODE
void arrive(npc_poisoned_mind_flyer& ai) {
 ai.UpdateAI(1);
 if(ai.finished)return;
 assert(ai.me->motion.last==10 && ai.me->motion.destination.GetPositionZ()>=97 && ai.me->motion.destination.GetPositionZ()<130);
 ai.MovementInform(POINT_MOTION_TYPE,10);ai.UpdateAI(1);
 assert(ai.me->motion.last==11 && ai.me->motion.destination.GetPositionZ()>=97 && ai.me->motion.destination.GetPositionZ()<130);
 ai.MovementInform(POINT_MOTION_TYPE,11);ai.UpdateAI(1);
}
int main(){
 for(int questId : {31211,31216}){
 Creature c; Player p; p.activeQuest=questId; ObjectAccessor::player=&p;
 npc_poisoned_mind_flyer ai(&c); ai.IsSummonedBy(&p); p.vehicle=&c;
 ai.PassengerBoarded(&p,0,true); assert(p.talk==1&&c.motion.moves==0);
 arrive(ai); assert(c.mantids==240&&c.kunchong==3);
 assert(c.motion.last==1&&c.motion.destination.GetPositionZ()>=97 && c.motion.destination.GetPositionZ()<130);
 ai.MovementInform(POINT_MOTION_TYPE,1); ai.UpdateAI(20000);
 assert(c.motion.last==2&&ai.waypoint==1);
 assert(c.motion.destination.GetPositionZ()>=97 && c.motion.destination.GetPositionZ()<130);
 ai.MovementInform(POINT_MOTION_TYPE,2);ai.UpdateAI(20000);assert(ai.waypoint==2);
 ai.MovementInform(POINT_MOTION_TYPE,2);ai.UpdateAI(20000);assert(ai.waypoint==0);
 assert(p.mantid==0 && p.kunchong==0);
 Creature target; target.guid=10;
 ai.SummonedCreatureDies(&target,&c); assert(p.mantid==1);
 ai.SummonedCreatureDies(&target,&c); assert(p.mantid==1);
 target.guid=11; ++p.mantid; // core has already awarded the next kill
 ai.SummonedCreatureDies(&target,&c); assert(p.mantid==2);
 target.guid=12; target.entry=63625;
 ai.SummonedCreatureDies(&target,&c); assert(p.kunchong==1);
 Creature other;target.guid=13;
 ai.SummonedCreatureDies(&target,&other);assert(p.kunchong==1);
 p.status=2;ai.UpdateAI(1);assert(ai.finished&&p.teleports==1&&p.vehicle==nullptr);
 ai.Finish();assert(p.teleports==1&&ai.summons.cleanups==1);
 for(int failure=0;failure<7;++failure){
  Creature vehicle;Player rider;rider.activeQuest=questId;ObjectAccessor::player=&rider;
  npc_poisoned_mind_flyer ride(&vehicle);ride.IsSummonedBy(&rider);
  if(failure==0){ride.UpdateAI(10001);}
  else{
   rider.vehicle=&vehicle;ride.PassengerBoarded(&rider,0,true);
   if(failure==1){vehicle.map.invalid=true;arrive(ride);}
   if(failure==2){vehicle.failAfter=5;arrive(ride);}
   if(failure==3){rider.online=false;ride.UpdateAI(1);}
   if(failure==4){rider.vehicle=nullptr;ride.PassengerBoarded(&rider,0,false);ride.UpdateAI(1);}
   if(failure==5){rider.status=0;ride.UpdateAI(1);}
   if(failure==6){SpellInfo s{124206};ride.SpellHit(&rider,&s);}
  }
  assert(ride.finished&&ride.summons.cleanups==1&&rider.status!=2);
 }
 }
}

'''
with tempfile.TemporaryDirectory(prefix='poisoned-mind-') as directory:
    cpp = Path(directory) / 'test.cpp'
    binary = Path(directory) / 'test'
    cpp.write_text(fixture.replace('// CODE', code))
    subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
print('PASS: staged ascent, surface heights, 240+3 targets, death-only credit, no duplicates/core double credit, cleanup and failures')
