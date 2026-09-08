#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <tuple>
#include <vector>
#include "../../modules/mod_playerbots/src/AI/PvePullState.h"
using uint32 = unsigned;
constexpr unsigned CLASS_WARRIOR=1, CLASS_PALADIN=2, CLASS_DRUID=11, CLASS_DEATH_KNIGHT=6, CLASS_MONK=10;
constexpr unsigned UNIT_STATE_LOST_CONTROL=1, TRIGGERED_NONE=0;
struct Player; struct Unit;
struct HostileReference { Unit* target=nullptr; Unit* getTarget(){return target;} };
struct ThreatManager { HostileReference* current=nullptr; float threat=0; float getThreat(Player*){return threat;} HostileReference* getCurrentVictim(){return current;} };
struct SpellInfo { unsigned NegativeEffectMask=1; };
struct AI { bool real=false; bool IsRealPlayer(){return real;} };
struct Unit {
 unsigned id=0; int map=1; bool alive=true,world=true,combat=true,attackable=true,cc=false,threatList=true,immune=false;
 Unit* victim=nullptr; Player* owner=nullptr; ThreatManager threat;
 bool IsAlive(){return alive;} bool IsInWorld(){return world;} bool IsInCombat(){return combat;} int GetMap(){return map;}
 Unit* GetVictim(){return victim;} Player* GetCharmerOrOwnerPlayerOrPlayerItself(){return owner;}
 bool CanHaveThreatList(){return threatList;} ThreatManager& GetThreatManager(){return threat;}
 unsigned GetGUID(){return id;} bool HasBreakableByDamageCrowdControlAura(){return cc;}
 bool IsImmunedToSpell(SpellInfo const*,unsigned){return immune;}
};
struct Ref { Player* p; Ref* nextRef=nullptr; Player* GetSource(){return p;} Ref* next(){return nextRef;} };
using GroupReference=Ref;
struct Group { std::vector<Ref> refs; bool IsMember(unsigned); Ref* GetFirstMember(){return refs.empty()?nullptr:&refs[0];} };
struct Player:Unit {
 Group* group=nullptr; bool tank=false,known=true,cooldown=false,lost=false,canCast=true; unsigned cls=CLASS_WARRIOR; float distance=5;
 AI* ai=nullptr;
 Player(){owner=this;attackable=false;}
 bool IsValidAttackTarget(Unit* u){return u && u->attackable;} float GetDistance(Unit*){return distance;}
 bool HasUnitState(unsigned){return lost;} unsigned GetClass(){return cls;}
 bool HasSpell(unsigned){return known;} bool HasSpellCooldown(unsigned){return cooldown;}
};
bool Group::IsMember(unsigned id){for(auto& r:refs)if(r.p->id==id)return true;return false;}
Group* GetActiveGroup(Player* p){return p?p->group:nullptr;}
#define GET_PLAYERBOT_AI(p) ((p)->ai)
using PlayerbotAI=AI;
struct PlayerBotSpec { static bool IsTank(Player* p,bool){return p->tank;} };
struct SpellManager { SpellInfo info; SpellInfo* GetSpellInfo(unsigned id){return id?&info:nullptr;} } manager;
SpellManager* sSpellMgr=&manager;
struct Spell { Player* p; Spell(Player* p,SpellInfo const*,unsigned):p(p){} bool CanAutoCast(Unit*){return p->canCast;} };
uint32 now=0; uint32 getMSTime(){return now;}
PvePullState<unsigned> state;
PvePullState<unsigned> ObserveGroupPull(Player*){return state;}
Unit* opening=nullptr;
struct GroupPveCombat {
 static bool IsEngaged(Player*,Unit*); static bool IsCollected(Player*,Unit*);
 static bool AoeReady(Player*,Unit*); static bool DamageAllowed(Player*,Unit*);
 static bool NeedsRescue(Player*,Unit*); static unsigned TauntSpell(Player*); static Player* RescueTank(Player*,Unit*);
 static Unit* OpeningTarget(Player*){return state.OpeningTarget(now)?opening:nullptr;}
};
// Runner extracts these seven bodies from production before compiling.
#include "../../Build/pull_support_bodies.inc"
unsigned checks=0;
void check(bool ok,char const* message){++checks;if(!ok){std::cerr<<"FAIL: "<<message<<'\n';std::exit(1);}}
int main()
{
 Player dps,healer,main,off; dps.id=10;healer.id=11;main.id=1;off.id=2;main.tank=off.tank=true;
 AI mainAi,offAi;main.ai=&mainAi;off.ai=&offAi;main.distance=6;off.distance=4;
 Group group;group.refs={{&dps},{&healer},{&main},{&off}};
 for(unsigned i=0;i+1<group.refs.size();++i)group.refs[i].nextRef=&group.refs[i+1];
 for(auto& r:group.refs)r.p->group=&group;
 Unit mob,add;mob.id=100;add.id=101;opening=&mob;
 mob.combat=false;check(!GroupPveCombat::IsEngaged(&dps,&mob),"merely selected idle mob is not a pull");
 mob.combat=true;check(!GroupPveCombat::IsEngaged(&dps,&mob),"zone combat alone is not engagement");
 mob.victim=&dps;check(GroupPveCombat::IsEngaged(&main,&mob),"DPS-initiated pull authorizes tanks");
 state.Observe(0,{100,101});now=0;
 check(GroupPveCombat::DamageAllowed(&dps,&mob),"opening single target permitted");
 add.victim=&dps;check(!GroupPveCombat::DamageAllowed(&dps,&add),"opening spread damage waits");
 check(GroupPveCombat::DamageAllowed(&main,&add),"tank rescue does not wait");
 check(!GroupPveCombat::AoeReady(&dps,&mob),"DPS AoE and pet gate initially closed");
 check(GroupPveCombat::AoeReady(&main,&mob),"tank collection AoE immediate");
 now=2999;check(!GroupPveCombat::AoeReady(&dps,&mob),"2999ms still waiting");
 now=3000;check(GroupPveCombat::AoeReady(&dps,&mob),"DPS aggro does not block collected pack after 3s");
 check(GroupPveCombat::DamageAllowed(&dps,&add),"spread damage allowed after opening");
 main.distance=off.distance=30;check(!GroupPveCombat::AoeReady(&dps,&mob),"3s alone does not permit distant pack");
 off.distance=4;check(GroupPveCombat::AoeReady(&dps,&mob),"either tank can collect");
 off.world=false;check(!GroupPveCombat::IsCollected(&dps,&mob),"unloaded tank cannot collect");off.world=true;
 check(GroupPveCombat::RescueTank(&main,&mob)==&off,"closest available bot tank rescues DPS");
 off.cooldown=true;check(GroupPveCombat::RescueTank(&main,&mob)==&main,"cooldown hands rescue to other tank");off.cooldown=false;
 off.canCast=false;check(GroupPveCombat::RescueTank(&main,&mob)==&main,"range/LOS/cast failure fallback");off.canCast=true;
 off.lost=true;check(GroupPveCombat::RescueTank(&main,&mob)==&main,"controlled tank cannot rescue");off.lost=false;
 off.map=2;check(GroupPveCombat::RescueTank(&main,&mob)==&main,"other instance tank excluded");off.map=1;
 HostileReference held{&main};mob.threat.current=&held;
 check(!GroupPveCombat::NeedsRescue(&off,&mob),"temporary DPS spell target does not steal tank threat victim");
    mob.victim=&main;check(GroupPveCombat::RescueTank(&off,&mob)==nullptr,"no taunt war");
    held.target=&dps;check(!GroupPveCombat::NeedsRescue(&off,&mob),"successful taunt protects against stale threat reference");
 held.target=&healer;mob.victim=&healer;check(GroupPveCombat::NeedsRescue(&off,&mob),"healer threat requires rescue");
 main.alive=false;check(GroupPveCombat::RescueTank(&off,&mob)==&off,"offtank rescues while main is dead");main.alive=true;
 mob.immune=true;check(GroupPveCombat::RescueTank(&off,&mob)==nullptr,"immune mob is not repeatedly taunted");mob.immune=false;
 mob.cc=true;check(!GroupPveCombat::NeedsRescue(&off,&mob),"breakable CC preserved");mob.cc=false;
 state.Observe(4000,{});now=4000;check(!GroupPveCombat::AoeReady(&dps,&mob),"finished pull does not leave gate open");
 state.Observe(5000,{101});now=5000;opening=&add;check(!GroupPveCombat::AoeReady(&dps,&add),"next pull waits independently");
 std::cout<<checks<<" pull coordination checks passed\n";
}
