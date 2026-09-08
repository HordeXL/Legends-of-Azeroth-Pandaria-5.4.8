#include "../../modules/mod_playerbots/src/Factory/ManagedPveEquipmentPolicy.h"
#include <cstdio>
#include <cstdlib>
#include <map>
#include <string>
struct Group;
namespace GroupSlot { enum Slot { Instance }; }
enum { SPEC_MONK_WINDWALKER=269, POWER_CHI=12 };
struct Aura {
 int duration=10000, stacks=10;
 int GetDuration(){return duration;} int GetStackAmount(){return stacks;}
};
struct Unit {
 bool alive=true,world=true,combat=true; float hp=10; int map=1,guid=1;
 bool IsAlive(){return alive;} bool IsInWorld(){return world;} bool IsInCombat(){return combat;}
 float GetHealthPct(){return hp;} int GetMap(){return map;} int GetGUID(){return guid;}
};
struct Player : Unit {
 bool dps=true,healer=false,learned=true,cooldown=false;
 int spec=SPEC_MONK_WINDWALKER,chi=2; std::map<int,Aura> auras;
 Group* instance=nullptr; Group* normal=nullptr;
 Group* GetGroup(GroupSlot::Slot){return instance;} Group* GetGroup(){return normal;}
 int GetSpecialization(){return spec;} bool HasSpell(int){return learned;}
 bool HasSpellCooldown(int){return cooldown;} int GetPower(int){return chi;}
 Aura* GetAura(int id){auto i=auras.find(id);return i==auras.end()?nullptr:&i->second;}
 bool HasAura(int id){return GetAura(id)!=nullptr;}
};
struct GroupReference {Player* member; GroupReference* link=nullptr; Player* GetSource(){return member;} GroupReference* next(){return link;}};
struct Group {GroupReference* first; bool contains=true; bool IsMember(int){return contains;} GroupReference* GetFirstMember(){return first;}};
struct PlayerBotSpec {static bool IsDps(Player* p,bool){return p->dps;} static bool IsHeal(Player* p,bool){return p->healer;}};
struct SpellMgr {int GetSpellInfo(int){return 0;}} mgr;
SpellMgr* sSpellMgr=&mgr;
struct PlayerbotAI {
 Player* bot; bool pve=true,safe=true;
 bool IsGroupPveActivity(){return pve;} bool IsGroupPveAreaSpellSafe(int,Unit*){return safe;}
};
using Event=int;
struct CastSpellAction {
 PlayerbotAI* botAI; Player* bot; Unit* target; std::string spell; bool useful=true,executed=false;
 CastSpellAction(PlayerbotAI* ai,std::string s):botAI(ai),bot(ai->bot),target(ai->bot),spell(s){}
 Unit* GetTarget(){return target;} virtual bool isUseful(){return useful;} virtual bool Execute(Event){executed=true;return true;}
};
struct CastAuraSpellAction : CastSpellAction {using CastSpellAction::CastSpellAction; bool auraUseful=true; bool isUseful() override{return useful&&auraUseful;}};
struct CastMeleeSpellAction : CastSpellAction {using CastSpellAction::CastSpellAction;};
struct CastBuffSpellAction : CastAuraSpellAction {using CastAuraSpellAction::CastAuraSpellAction;};
struct CastHealingSpellAction : CastAuraSpellAction {
 using CastAuraSpellAction::CastAuraSpellAction;
 bool IsHealingRoleAllowed(); bool isUseful() override; bool Execute(Event event) override;
};
struct CastAoeHealSpellAction : CastHealingSpellAction {using CastHealingSpellAction::CastHealingSpellAction; bool isUseful() override;};
struct DebuffTrigger {
 PlayerbotAI* botAI; float needLifeTime; bool base=true;
 DebuffTrigger(PlayerbotAI* ai,const char*,int,bool,float life):botAI(ai),needLifeTime(life){}
 virtual bool IsActive(){return base;}
};
bool CastHealingSpellAction::IsHealingRoleAllowed()
{
    if (!botAI->IsGroupPveActivity() || !PlayerBotSpec::IsDps(bot, true))
        return true;

    // Expel Harm is also a Windwalker Chi generator, not a party-heal detour.
    if (spell == "expel harm" && GetTarget() == bot)
        return true;

    Unit* target = GetTarget();
    if (!target || !target->IsAlive() || !target->IsInWorld() ||
        !target->IsInCombat() || target->GetHealthPct() >= 20.0f ||
        target->GetMap() != bot->GetMap())
        return false;

    Group* group = bot->GetGroup(GroupSlot::Instance);
    if (!group) group = bot->GetGroup();
    if (!group || !group->IsMember(target->GetGUID()))
        return false;

    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (member && member->IsAlive() && member->IsInWorld() &&
            member->GetMap() == bot->GetMap() && PlayerBotSpec::IsHeal(member, true))
            return false;
    }
    return true;
}

bool CastHealingSpellAction::isUseful()
{
    // Check before form-changing prerequisites as well as at cast time.
    return IsHealingRoleAllowed() && CastAuraSpellAction::isUseful();
}

bool CastHealingSpellAction::Execute(Event event)
{
    return IsHealingRoleAllowed() && CastAuraSpellAction::Execute(event);
}

bool CastAoeHealSpellAction::isUseful()
{
    return IsHealingRoleAllowed() && CastSpellAction::isUseful();
}

class CastTigerPalmAction : public CastMeleeSpellAction
{
public:
    CastTigerPalmAction(PlayerbotAI* ai) : CastMeleeSpellAction(ai, "tiger palm") { }
    bool isUseful() override
    {
        if (botAI->IsGroupPveActivity() && bot->GetSpecialization() == SPEC_MONK_WINDWALKER)
        {
            Aura* power = bot->GetAura(125359); // Tiger Power, not the attack ID.
            if (power && power->GetDuration() > 4000 && !bot->HasAura(118864))
                return false; // Only refresh, or use a free Combo Breaker.
        }
        return CastMeleeSpellAction::isUseful();
    }
};

class CastBlackoutKickAction : public CastMeleeSpellAction
{
public:
    CastBlackoutKickAction(PlayerbotAI* ai) : CastMeleeSpellAction(ai, "blackout kick") { }
    bool isUseful() override
    {
        if (botAI->IsGroupPveActivity() && bot->GetSpecialization() == SPEC_MONK_WINDWALKER &&
            bot->HasSpell(113656) && !bot->HasSpellCooldown(113656) &&
            bot->GetPower(POWER_CHI) < 3 && !bot->HasAura(116768) &&
            botAI->IsGroupPveAreaSpellSafe(sSpellMgr->GetSpellInfo(113656), GetTarget()))
            return false; // Let Jab build 3 Chi instead of spending every 2.
        return CastMeleeSpellAction::isUseful();
    }
};

class CastTigereyeBrewAction : public CastBuffSpellAction
{
public:
    CastTigereyeBrewAction(PlayerbotAI* ai) : CastBuffSpellAction(ai, "tigereye brew") { }
    bool isUseful() override
    {
        if (!botAI->IsGroupPveActivity())
            return CastBuffSpellAction::isUseful();
        Aura* stacks = bot->GetAura(125195);
        // Saved stacks share the damage buff's name, but are not an active buff.
        return bot->IsInCombat() && stacks && stacks->GetStackAmount() >= 10 &&
            !bot->HasAura(116740) && CastSpellAction::isUseful();
    }
};

class CurseOfAgonyTrigger : public DebuffTrigger
{
public:
    CurseOfAgonyTrigger(PlayerbotAI* botAI) : DebuffTrigger(botAI, "agony", 1, true, 20.0f) {}
    bool IsActive() override
    {
        // The old 20-second requirement excluded normal raid trash even when
        // there was enough time for several ticks. Keep a short-lived-target
        // guard and the original PvP threshold; evaluate the mode dynamically.
        needLifeTime = botAI->IsGroupPveActivity() ? 8.0f : 20.0f;
        return DebuffTrigger::IsActive();
    }
};
int checks=0;
void check(bool ok,const char* label){++checks;if(!ok){std::fprintf(stderr,"FAIL: %s\n",label);std::exit(1);}}
int main(){
 using namespace ManagedPveEquipmentPolicy;
 check(WeaponFloor(496,90,true)==559,"LFR weapons floor");
 check(WeaponFloor(566,90,true)==559,"armor does not lower shared floor");
 check(WeaponFloor(610,90,true)==575,"higher reference retained");
 check(WeaponFloor(496,90,false)==461,"PvP unchanged");
 check(WeaponFloor(450,89,true)==415,"level 89 unchanged");
 check(WeaponFloor(20,10,true)==20,"no unsigned underflow");
 for(unsigned id:{126590u,126641u,138849u,138924u,146315u,146316u}) check(IsHealingProc(id),"healer proc");
 for(unsigned id:{0u,126579u,146051u,146059u,148904u,138894u}) check(!IsHealingProc(id),"damage or shared proc not healer-only");
 Player bot,healer; Unit target; healer.healer=true;
 PlayerbotAI ai{&bot}; GroupReference ref{&healer}; Group group{&ref};bot.instance=&group;
 CastHealingSpellAction heal(&ai,"renew");heal.target=&target;
 check(!heal.isUseful(),"DPS with healer does not queue form prerequisite");
 check(!heal.Execute(0)&&!heal.executed,"cast-time role recheck");
 healer.alive=false;check(heal.isUseful(),"critical emergency with dead healer");
 target.hp=20;check(!heal.isUseful(),"not critical at 20");target.hp=10;
 target.alive=false;check(!heal.isUseful(),"dead target");target.alive=true;
 target.world=false;check(!heal.isUseful(),"offline target");target.world=true;
 target.combat=false;check(!heal.isUseful(),"out of combat");target.combat=true;
 target.map=2;check(!heal.isUseful(),"wrong map");target.map=1;
 group.contains=false;check(!heal.isUseful(),"not a member");group.contains=true;
 heal.target=nullptr;check(!heal.isUseful(),"null target");heal.target=&target;
 bot.instance=nullptr;check(!heal.isUseful(),"no group");bot.normal=&group;check(heal.isUseful(),"normal group fallback");
 healer.alive=true;healer.map=2;check(heal.isUseful(),"healer other map");healer.map=1;
 healer.world=false;check(heal.isUseful(),"healer offline");healer.world=true;
 bot.dps=false;check(heal.isUseful(),"healer and tank unchanged");bot.dps=true;
 ai.pve=false;check(heal.isUseful(),"PvP and solo unchanged");ai.pve=true;
 heal.spell="expel harm";heal.target=&bot;check(heal.isUseful(),"Chi generator retained");
 heal.spell="renew";check(!heal.isUseful(),"DPS self Renew does not drop Shadowform");
 healer.alive=false;heal.useful=false;check(!heal.isUseful(),"base restrictions retained");heal.useful=true;
 CastAoeHealSpellAction aoe(&ai,"prayer of healing");aoe.target=&target;
 healer.alive=true;check(!aoe.isUseful(),"AoE cannot bypass guard");
 healer.alive=false;check(heal.Execute(0)&&heal.executed,"emergency executes");
 CastTigerPalmAction palm(&ai);CastBlackoutKickAction kick(&ai);CastTigereyeBrewAction brew(&ai);
 bot.auras[125359]={10000,1};
 check(!palm.isUseful(),"do not waste Chi on fresh Tiger Power");
 bot.auras[125359].duration=4000;check(palm.isUseful(),"refresh Tiger Power");bot.auras[125359].duration=10000;
 bot.auras[118864]={};check(palm.isUseful(),"free palm");bot.auras.erase(118864);
 check(!kick.isUseful(),"reserve Chi for FoF");
 bot.chi=3;check(kick.isUseful(),"3 Chi fallback");bot.chi=2;
 bot.cooldown=true;check(kick.isUseful(),"FoF cooldown permits spender");bot.cooldown=false;
 bot.learned=false;check(kick.isUseful(),"unlearned FoF does not reserve");bot.learned=true;
 bot.auras[116768]={};check(kick.isUseful(),"free kick");bot.auras.erase(116768);
 ai.safe=false;check(kick.isUseful(),"unsafe AoE does not starve single target");ai.safe=true;
 bot.spec=268;check(palm.isUseful()&&kick.isUseful(),"Brewmaster unchanged");bot.spec=269;
 ai.pve=false;check(palm.isUseful()&&kick.isUseful(),"PvP monk unchanged");ai.pve=true;
 check(!brew.isUseful(),"no stacks");
 bot.auras[125195]={10000,9};check(!brew.isUseful(),"save until 10 stacks");
 bot.auras[125195].stacks=10;brew.auraUseful=false;check(brew.isUseful(),"stack-name collision bypassed");
 bot.auras[116740]={};check(!brew.isUseful(),"no active buff overwrite");bot.auras.erase(116740);
 bot.combat=false;check(!brew.isUseful(),"no out of combat brew");bot.combat=true;
 brew.useful=false;check(!brew.isUseful(),"brew retains generic safety");brew.useful=true;
 ai.pve=false;check(!brew.isUseful(),"PvP retains old aura check");ai.pve=true;
 CurseOfAgonyTrigger agony(&ai);check(agony.IsActive()&&agony.needLifeTime==8,"PvE Agony threshold");
 ai.pve=false;check(agony.IsActive()&&agony.needLifeTime==20,"PvP Agony threshold restored dynamically");
 agony.base=false;check(!agony.IsActive(),"Agony retains base checks");
 std::printf("%d loadout and rotation checks passed\n",checks);
}
