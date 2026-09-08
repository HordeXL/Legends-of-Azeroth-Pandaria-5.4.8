// Isolated regression with the exact production Pestilence body (runner checks freshness).
#include <vector>
#include <list>
#include <map>
#include <string>
#include <iostream>
#include <cstdlib>
#include "../../modules/mod_playerbots/src/AI/PvePetPullGate.h"
using ObjectGuid = unsigned;
using GuidVector = std::vector<ObjectGuid>;
struct Unit {
 bool alive=true, near=true, frost=false, blood=false;
 bool HasAura(unsigned id, ObjectGuid) const { return id==55095 ? frost : blood; }
 ObjectGuid GetGUID() const {return 1;}
 bool IsAlive() const {return alive;}
 bool IsWithinDistInMap(Unit* other,float) const {return other->near;}
};
struct UntypedValue { virtual ~UntypedValue()=default; };
template<class T> struct Value: UntypedValue { T value{}; T Get(){return value;} };
struct Context {
 Value<GuidVector> attackers;
 template<class T> Value<T>* GetValue(std::string) {return dynamic_cast<Value<T>*>(&attackers);}
};
struct AI {
 bool pve=true; Context context; std::map<ObjectGuid,Unit*> units;
 bool IsGroupPveActivity() const {return pve;}
 Unit* GetUnit(ObjectGuid id){auto i=units.find(id);return i==units.end()?nullptr:i->second;}
};
struct CastSpellAction { bool baseUseful=true; bool isUseful(){return baseUseful;} };
struct CastPestilenceAction: CastSpellAction {
 AI* botAI; Unit* bot; Unit* target;
 CastPestilenceAction(AI* ai,Unit* b,Unit* t):botAI(ai),bot(b),target(t){}
 Unit* GetTarget(){return target;} bool isUseful();
};
#define AI_VALUE(type,name) botAI->context.GetValue<type>(name)->Get()
bool CastPestilenceAction::isUseful()
{
    if (!botAI->IsGroupPveActivity()) return CastSpellAction::isUseful();
    Unit* target = GetTarget();
    if (!target) return false;
    bool const frost = target->HasAura(55095, bot->GetGUID());
    bool const blood = target->HasAura(55078, bot->GetGUID());
    if (!frost && !blood) return false;
    // AttackersValue stores GuidVector, not std::list<ObjectGuid>. The typed
    // context lookup returns null for a mismatched type.
    for (ObjectGuid guid : AI_VALUE(GuidVector, "attackers"))
        if (Unit* other = botAI->GetUnit(guid))
            if (other != target && other->IsAlive() && target->IsWithinDistInMap(other, 10.0f) &&
                ((frost && !other->HasAura(55095, bot->GetGUID())) ||
                 (blood && !other->HasAura(55078, bot->GetGUID()))))
                return CastSpellAction::isUseful();
    return false;
}

int checks=0;
void check(bool ok,char const* text) {
 ++checks; if(!ok){std::cerr<<"FAIL "<<text<<"\n";std::exit(1);}
}
int main(){
 AI ai; Unit bot,target,other; CastPestilenceAction action(&ai,&bot,&target);
 check(ai.context.GetValue<GuidVector>("attackers")!=nullptr,"registered GuidVector resolves");
 check(ai.context.GetValue<std::list<ObjectGuid>>("attackers")==nullptr,"old list lookup reproduces null cause");
 check(!action.isUseful(),"no diseases");
 target.frost=true; check(!action.isUseful(),"empty vector safe");
 ai.context.attackers.value={1,2,3};ai.units={{1,&target},{2,&other}};
 check(action.isUseful(),"own frost spreads to nearby target without disease");
 other.frost=true;check(!action.isUseful(),"no repeated spread to already infected targets");
 target.blood=true;check(action.isUseful(),"missing own blood disease spreads");
 other.blood=true;check(!action.isUseful(),"both diseases present");
 other.frost=false;other.near=false;check(!action.isUseful(),"outside radius");
 other.near=true;other.alive=false;check(!action.isUseful(),"dead target");
 other.alive=true;action.baseUseful=false;check(!action.isUseful(),"base cast guard retained");
 action.baseUseful=true;action.target=nullptr;check(!action.isUseful(),"no current target");
 ai.pve=false;check(action.isUseful(),"PvP base behaviour retained");

 PvePetPullGate<unsigned> gate;
 check(!gate.Ready(0,1,10,false,true),"owner must engage");
 check(!gate.Ready(0,1,10,true,true),"no immediate pet attack");
 check(!gate.Ready(3999,1,10,true,true),"wait full 4 seconds");
 check(gate.Ready(4000,1,10,true,true),"release at 4 seconds when collected");
 check(!gate.Ready(6000,1,10,true,false),"elapsed delay not enough without tank");
 check(gate.Ready(6001,1,10,true,true),"release when tank collects");
 check(!gate.Ready(7000,2,10,true,true),"new target resets delay");
 check(!gate.Ready(10999,2,10,true,true),"new target still waiting");
 check(gate.Ready(11000,2,10,true,true),"new target release");
 check(!gate.Ready(12000,2,11,true,true),"new pet resets delay");
 check(!gate.Ready(16000,2,11,false,true),"owner disengagement resets");
 check(!gate.Ready(16001,2,11,true,true),"resume requires fresh delay");
 check(gate.Ready(20001,2,11,true,true),"resume after fresh delay");
 gate.Reset();check(!gate.Ready(25000,2,11,true,true),"explicit reset");
 gate.Reset();check(!gate.Ready(0xfffffff0u,3,12,true,true),"start before clock wrap");
 check(!gate.Ready(3983,3,12,true,true),"clock wrap 3999ms");
 check(gate.Ready(3984,3,12,true,true),"clock wrap 4000ms");
 std::cout<<"PASS "<<checks<<" checks; typed Pestilence lookup and pet pull delay\n";
}
