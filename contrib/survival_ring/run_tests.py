#!/usr/bin/env python3
"""Exercise production ring eligibility, per-aura timer and firework filtering."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'src/server/scripts/Pandaria/zone_vale_of_eternal_blossoms.cpp').read_text()
def block(marker,start=0):
 a=source.index(marker,start);b=source.index('{',a)+1;depth=1
 while depth:
  depth+=(source[b]=='{')-(source[b]=='}');b+=1
 return source[a:b]
fixture=r'''
#include <algorithm>
#include <cassert>
#include <cmath>
#include <list>
#include <iostream>
using uint32=unsigned;
struct AuraEffect {};using AuraEffectHandleModes=int;
enum { QUEST_STATUS_INCOMPLETE=1, QUEST_STATUS_COMPLETE=2, POWER_ALTERNATE_POWER };
struct Player;
struct WorldObject;
using Unit=WorldObject;
struct WorldObject {virtual void SetPower(unsigned,unsigned){} virtual ~WorldObject()=default;virtual Player* ToPlayer(){return nullptr;}};
struct Player:WorldObject {
 bool alive=true,mounted=false,flying=false,vehicle=false;
 unsigned map=870,flame=1,blades=1,power=0,credit=0,credits=0;
 float x=801.422f,y=2004.85f,z=318.5f;
 bool flameAura=true;
 Player* ToPlayer() override{return this;}
 bool IsAlive(){return alive;} unsigned GetMapId(){return map;}
 bool IsMounted(){return mounted;} bool IsFlying(){return flying;} bool GetVehicle(){return vehicle;}
 float GetExactDist2d(float a,float b){return std::hypot(x-a,y-b);}
 float GetPositionZ(){return z;}
 unsigned GetQuestStatus(unsigned q){return q==30240?flame:blades;}
 void SetPower(unsigned,unsigned n){power=n;}
 void KilledMonsterCredit(unsigned id){credit=id;++credits;(id==58967?flame:blades)=QUEST_STATUS_COMPLETE;}
 bool HasAura(unsigned){return flameAura;}
};
HELPERS
struct Progress {
 Player* target;unsigned id,elapsed=0;bool removed=false;int m_duration=60000;
 WorldObject* GetUnitOwner(){return target;}
 WorldObject* GetTarget() = delete; // No AuraApplication exists during OnAuraUpdate.
 unsigned GetId(){return id;}
 void Remove(){removed=true;if(target)target->power=0;}
UPDATE
 void SetMaxDuration(int){}
 void SetDuration(int duration){m_duration=duration;}
APPLY
 void CallScriptAuraUpdateHandlers(unsigned diff){OnUpdate(diff);}
 void CoreUpdate(unsigned diff) {
DISPATCH
 }
};
struct Firework {
FILTER
};
int main(){
 for(unsigned bar:{112836u,127386u}) {
  Player player;Progress timer{&player,bar};
  timer.CoreUpdate(59999);assert(!timer.removed && player.credits==0 && player.power==59);
  timer.CoreUpdate(1);assert(timer.removed && player.credits==1);
  assert(player.credit==(bar==112836?58967u:64895u));
  Player reset;Progress partial{&reset,bar};partial.OnUpdate(30000);
  reset.x+=30;partial.OnUpdate(30000);assert(partial.removed && reset.credits==0);
  reset.x-=30;Progress restarted{&reset,bar};restarted.OnUpdate(30000);assert(reset.credits==0);
  restarted.OnUpdate(30000);assert(reset.credits==1);
 }
 for(unsigned failure=0;failure<7;++failure){
  Player p;Progress timer{&p,112836};timer.OnUpdate(59000);
  switch(failure){case 0:p.alive=false;break;case 1:p.mounted=true;break;case 2:p.flying=true;break;
   case 3:p.vehicle=true;break;case 4:p.map=1;break;case 5:p.flame=0;break;case 6:p.z=330;break;}
  timer.OnUpdate(1000);assert(timer.removed && p.credits==0);
 }
 Player a,b;Progress first{&a,112836},second{&b,127386};
 first.OnUpdate(60000);second.OnUpdate(10000);assert(a.credits==1 && b.credits==0 && b.power==10);
 Player participant,spectator;WorldObject npc;spectator.flameAura=false;
 std::list<WorldObject*> targets{&participant,&spectator,&npc};Firework fire;fire.FilterTargets(targets);
 assert(targets.size()==1 && targets.front()==&participant);
 Progress noOwner{nullptr,112836};noOwner.OnUpdate(1000);assert(noOwner.removed);
 Player frozen;Progress infinite{&frozen,112836};infinite.m_duration=-1;
 infinite.CoreUpdate(60000);assert(frozen.credits==0 && infinite.elapsed==0);
 infinite.OnApply(nullptr,0);assert(infinite.m_duration==60000 && frozen.power==0);
 infinite.CoreUpdate(60000);assert(frozen.credits==1);
 assert(!SurvivalRing::Inside(nullptr));
 std::cout<<"Survival Ring: both credits at 60s, reset/eligibility, independent players and spectator filtering passed\n";
}
'''
helpers=block('namespace SurvivalRing')
update=block('void OnUpdate(uint32 diff)',source.index('class spell_survival_ring_progress'))
apply=block('void OnApply(AuraEffect const*',source.index('class spell_survival_ring_progress'))
filtering=block('void FilterTargets(',source.index('class spell_survival_ring_firework'))
aura_core=(root/'src/server/game/Spells/Auras/SpellAuras.cpp').read_text()
a=aura_core.index('    if (m_duration > 0)',aura_core.index('void Aura::Update(uint32 diff'))
b=aura_core.index('    // handle manaPerSecond',a)
dispatch=aura_core[a:b]
# Validate the production controller gives the aura the finite duration required by the core.
controller=source[source.index('struct npc_survival_ring_controller'):source.index('class spell_survival_ring_progress')]
assert 'aura->SetDuration(60000)' in controller and 'aura->SetMaxDuration(60000)' in controller
with tempfile.TemporaryDirectory(prefix='survival-ring-') as directory:
 cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test'
 cpp.write_text(fixture.replace('HELPERS',helpers).replace('UPDATE',update).replace('FILTER',filtering).replace('DISPATCH',dispatch).replace('APPLY',apply))
 subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
