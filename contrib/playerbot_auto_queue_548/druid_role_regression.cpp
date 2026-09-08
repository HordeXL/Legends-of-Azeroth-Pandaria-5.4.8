// Isolated tests: production function bodies below are checked by test_druid_role.ps1.
#include <cstdio>
#include <cstdlib>
#include <vector>
enum { SPEC_DRUID_BALANCE=102, SPEC_DRUID_FERAL=103, SPEC_DRUID_GUARDIAN=104, SPEC_DRUID_RESTORATION=105 };
namespace GroupSlot { enum Slot { Instance }; }
struct Group;
struct Unit {
 bool alive=true,world=true,combat=true; float hp=10; int map=1,guid=1;
 bool IsAlive(){return alive;} bool IsInWorld(){return world;} bool IsInCombat(){return combat;}
 float GetHealthPct(){return hp;} int GetMap(){return map;} int GetGUID(){return guid;}
};
struct Player : Unit {
 int spec=SPEC_DRUID_BALANCE; bool healer=false,learned=true,aura=false,mounted=false,flight=false,teleport=false,swimming=false,casting=false;
 Group* instance=nullptr; Group* normal=nullptr;
 int GetSpecialization(){return spec;} Group* GetGroup(GroupSlot::Slot){return instance;} Group* GetGroup(){return normal;}
 bool HasSpell(int){return learned;} bool HasAura(int){return aura;} bool IsMounted(){return mounted;}
 bool IsInFlight(){return flight;} bool IsBeingTeleported(){return teleport;} bool isSwimming(){return swimming;}
 bool IsNonMeleeSpellCasted(bool){return casting;}
};
struct GroupReference {Player* member=nullptr; GroupReference* link=nullptr; Player* GetSource(){return member;} GroupReference* next(){return link;}};
struct Group {GroupReference* first=nullptr; bool contains=true; bool IsMember(int){return contains;} GroupReference* GetFirstMember(){return first;}};
struct PlayerBotSpec {static bool IsHeal(Player* p,bool){return p->healer;}};
struct AI {bool pve=true; bool IsGroupPveActivity(){return pve;}};
using Event=int;
struct HealPartyMemberAction {
 bool useful=true,executed=false; bool isUseful(){return useful;} bool Execute(Event){executed=true;return true;}
};
struct DruidPartyHealAction : HealPartyMemberAction {
 Player* bot; AI* botAI; Unit* target; Unit* GetTarget(){return target;}
 bool IsRoleAllowed(); bool isUseful(); bool Execute(Event event);
};
struct PveMoonkinFormTrigger {Player* bot; AI* botAI; bool IsActive();};
bool DruidPartyHealAction::IsRoleAllowed()
{
    if (!botAI->IsGroupPveActivity() ||
        (bot->GetSpecialization() != SPEC_DRUID_BALANCE &&
         bot->GetSpecialization() != SPEC_DRUID_FERAL))
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

    // A living healer in the active map retains responsibility for healing.
    // Only rescue a critically injured party member when no such healer exists.
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (member && member->IsAlive() && member->IsInWorld() &&
            member->GetMap() == bot->GetMap() && PlayerBotSpec::IsHeal(member, true))
            return false;
    }
    return true;
}

bool DruidPartyHealAction::isUseful()
{
    // Checked before caster-form prerequisites are queued by the engine.
    return IsRoleAllowed() && HealPartyMemberAction::isUseful();
}

bool DruidPartyHealAction::Execute(Event event)
{
    // Health, specialization and healer availability can change while queued.
    return IsRoleAllowed() && HealPartyMemberAction::Execute(event);
}

bool PveMoonkinFormTrigger::IsActive()
{
    return botAI->IsGroupPveActivity() && bot->IsAlive() && bot->IsInWorld() &&
        bot->GetSpecialization() == SPEC_DRUID_BALANCE && bot->HasSpell(24858) &&
        !bot->HasAura(24858) && !bot->IsMounted() && !bot->IsInFlight() &&
        !bot->IsBeingTeleported() && !bot->isSwimming() &&
        !bot->IsNonMeleeSpellCasted(false);
}
int checks=0;
void check(bool ok,const char* label){++checks;if(!ok){std::fprintf(stderr,"FAIL %s\n",label);std::exit(1);}}
int main(){
 Player bot,healer; Unit target; AI ai; healer.healer=true;
 GroupReference ref{&healer}; Group group{&ref}; bot.instance=&group;
 DruidPartyHealAction action; action.bot=&bot;action.botAI=&ai;action.target=&target;
 check(!action.isUseful(),"DPS with healer does not queue caster form");
 check(!action.Execute(0)&&!action.executed,"execution rechecks healer");
 healer.alive=false;check(action.isUseful(),"critical rescue when healer dead");
 target.hp=20;check(!action.isUseful(),"20 percent is not critical");
 target.hp=99;check(!action.isUseful(),"no topping up");
 target.hp=10;target.combat=false;check(!action.isUseful(),"no out of combat offheal");
 target.combat=true;target.alive=false;check(!action.isUseful(),"do not heal dead");
 target.alive=true;target.world=false;check(!action.isUseful(),"unloaded target");
 target.world=true;target.map=2;check(!action.isUseful(),"different map target");
 target.map=1;group.contains=false;check(!action.isUseful(),"not a group member");
 group.contains=true;action.target=nullptr;check(!action.isUseful(),"null target");
 action.target=&target;bot.instance=nullptr;check(!action.isUseful(),"no group");
 bot.normal=&group;check(action.isUseful(),"normal group fallback");
 healer.alive=true;healer.map=2;check(action.isUseful(),"healer in other map");
 healer.map=1;healer.world=false;check(action.isUseful(),"offline healer");
 healer.world=true;check(!action.isUseful(),"healer returned");
 ref.member=nullptr;check(action.isUseful(),"unloaded group reference");
 ref.member=&healer;bot.spec=SPEC_DRUID_FERAL;check(!action.isUseful(),"feral respects role");
 bot.spec=SPEC_DRUID_RESTORATION;check(action.isUseful(),"restoration unchanged");
 bot.spec=SPEC_DRUID_GUARDIAN;check(action.isUseful(),"guardian unchanged");
 bot.spec=SPEC_DRUID_BALANCE;ai.pve=false;check(action.isUseful(),"PvP and solo unchanged");
 ai.pve=true;healer.alive=false;action.useful=false;check(!action.isUseful(),"base restrictions retained");
 action.useful=true;check(action.Execute(0)&&action.executed,"rescue execution");
 GroupReference secondRef{&healer};Player otherHealer;otherHealer.healer=true;GroupReference firstRef{&otherHealer,&secondRef};group.first=&firstRef;
 check(!action.isUseful(),"one living healer is enough");
 group.first=&ref;
 PveMoonkinFormTrigger form{&bot,&ai};
 check(form.IsActive(),"restore balance form");
 bot.aura=true;check(!form.IsActive(),"no rebuff when form already active");bot.aura=false;
 bot.spec=SPEC_DRUID_RESTORATION;check(!form.IsActive(),"no moonkin for resto");bot.spec=SPEC_DRUID_BALANCE;
 ai.pve=false;check(!form.IsActive(),"no PvP form change");ai.pve=true;
 bot.learned=false;check(!form.IsActive(),"must know form");bot.learned=true;
 bot.alive=false;check(!form.IsActive(),"dead");bot.alive=true;
 bot.world=false;check(!form.IsActive(),"not in world");bot.world=true;
 bot.mounted=true;check(!form.IsActive(),"preserve mount");bot.mounted=false;
 bot.flight=true;check(!form.IsActive(),"preserve flight");bot.flight=false;
 bot.teleport=true;check(!form.IsActive(),"wait for teleport");bot.teleport=false;
 bot.swimming=true;check(!form.IsActive(),"preserve swimming");bot.swimming=false;
 bot.casting=true;check(!form.IsActive(),"do not interrupt rescue heal");bot.casting=false;
 check(form.IsActive(),"restore after heal");
 std::printf("PASS %d druid role checks\n",checks);
}
