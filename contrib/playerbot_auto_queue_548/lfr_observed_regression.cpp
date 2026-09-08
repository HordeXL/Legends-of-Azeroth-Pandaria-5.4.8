// Exact production function bodies, with small mocks; not a server integration test.
#include <vector>
#include <string>
#include <iostream>
#include <cstdlib>
using uint32=unsigned;
struct Unit; struct Player; struct Group; struct AI;
struct WorldObject {virtual Unit* ToUnit(){return nullptr;}};
struct Unit:WorldObject {
 bool alive=true,inWorld=true,isPlayer=false,attackable=true,melee=false;
 int map=1; float distance=30; Unit* victim=nullptr;
 Unit* ToUnit() override {return this;}
 Player* ToPlayer();
 bool IsAlive() const{return alive;} bool IsInWorld() const{return inWorld;}
 bool IsPlayer() const{return isPlayer;} int GetMap() const{return map;}
 Unit* GetVictim() const{return victim;}
 bool IsWithinMeleeRange(Unit*) const{return melee;}
 float GetDistance(Unit*) const{return distance;}
 bool IsValidAttackTarget(Unit* target) const{return target->attackable;}
};
using Pet=Unit;
struct Player:Unit {
 unsigned id=0; bool tank=false,pvp=false; Group* group=nullptr; AI* ai=nullptr; Pet* pet=nullptr;
 Player(){isPlayer=true;}
 unsigned GetGUID() const{return id;}
 bool InBattleground()const{return pvp;} bool InArena()const{return false;}
 Group* GetGroup(int=0)const{return group;} Pet* GetPet()const{return pet;}
};
Player* Unit::ToPlayer(){return isPlayer?static_cast<Player*>(this):nullptr;}
struct GroupReference {
 Player* player=nullptr; GroupReference* following=nullptr;
 Player* GetSource(){return player;} GroupReference* next(){return following;}
};
struct Group {
 std::vector<GroupReference> refs; Player* marked=nullptr; unsigned leader=0;
 Group(std::initializer_list<Player*> members){
  for(auto* member:members) refs.push_back({member,nullptr});
  for(size_t i=0;i+1<refs.size();++i)refs[i].following=&refs[i+1];
 }
 bool IsMember(unsigned guid)const{for(auto const& r:refs)if(r.player->id==guid)return true;return false;}
 GroupReference* GetFirstMember(){return refs.empty()?nullptr:&refs[0];}
 unsigned GetLeaderGUID()const{return leader;}
};
enum GroupSlot { Instance=1 };
struct AI {
 bool pve=true,allowed=true,controlled=true,real=false,petReady=true; Player* master=nullptr;
 bool IsGroupPveActivity(){return pve;} bool CanLfgAutoQueueEngage(Unit*){return allowed;}
 bool IsLfgAutoQueueControlled(){return controlled;} Player* GetMaster(){return master;}
 bool IsRealPlayer(){return real;} bool CanPetEngageTarget(Unit*){return petReady;}
};
#define GET_PLAYERBOT_AI(player) ((player)->ai)
using PlayerbotAI=AI;
Group* GetActiveGroup(Player* p){return p?p->group:nullptr;}
struct PlayerBotSpec {
 static bool IsTank(Player* p,bool=true){return p && p->tank;}
 static Player* GetDiamondMarkedTank(Player* p){return p->group?p->group->marked:nullptr;}
 static Player* GetGroupPvePullTank(Player*);
};
struct GroupPveCombat {
 static bool NeedsRescue(Player*,Unit* u){return u->victim && u->victim->ToPlayer() && !u->victim->ToPlayer()->tank;}
 static bool IsCollected(Player* p,Unit* u){for(auto& r:p->group->refs)if(r.player->alive && r.player->tank && r.player->map==p->map && (r.player->melee || r.player->distance<=8))return true;return false;}
};
struct MovementAction { AI* botAI; Player* bot; bool WaitForTankPull(WorldObject*); };
struct CastSpellAction {bool base=true;bool isUseful(){return base;}};
struct CastAuraSpellAction:CastSpellAction {};
struct CastKillCommandAction:CastAuraSpellAction {
 AI* botAI;Player* bot;Unit* target;Unit* GetTarget(){return target;}bool isUseful();
};
Player* PlayerBotSpec::GetGroupPvePullTank(Player* player)
{
    Group* group = GetActiveGroup(player);
    if (!group || player->InBattleground() || player->InArena()) return nullptr;
    // Keep a dead designated tank as the anchor: callers allow emergency
    // takeover, then restore ownership when that player is resurrected.
    if (Player* marked = GetDiamondMarkedTank(player)) return marked;
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(player))
        if (Player* master = ai->GetMaster())
            if (group->IsMember(master->GetGUID()) && master->IsInWorld() &&
                master->GetMap() == player->GetMap() && IsTank(master, true) &&
                (!GET_PLAYERBOT_AI(master) || GET_PLAYERBOT_AI(master)->IsRealPlayer()))
                return master;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->GetGUID() == group->GetLeaderGUID() && member->IsInWorld() &&
                member->GetMap() == player->GetMap() && IsTank(member, true))
                return member;
    Player* fallback = nullptr;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->IsAlive() && member->IsInWorld() && member->GetMap() == player->GetMap() &&
                IsTank(member, true) && (!fallback || member->GetGUID() < fallback->GetGUID()))
                fallback = member;
    return fallback;
}
bool MovementAction::WaitForTankPull(WorldObject* object)
{
    // Being on the tank's threat list is not the same as having reached the
    // tank. Do not meet a ranged pull halfway and body-pull the next pack.
    // Friendly healing/resurrection movement and PvP remain independent.
    // Only the designated pull tank may meet a ranged pull halfway.
    if (!object || !botAI->IsGroupPveActivity())
        return false;

    Unit* target = object->ToUnit();
    if (!target || !target->IsInWorld() || !target->IsAlive() ||
        target->GetMap() != bot->GetMap() || target->IsPlayer() ||
        !bot->IsValidAttackTarget(target))
        return false;

    // Block the pre-pull case too, including tank bots: selecting/marking an
    // idle enemy is not permission to walk into its aggro radius.
    if (!botAI->CanLfgAutoQueueEngage(target))
        return true;
    if (PlayerBotSpec::IsTank(bot, true))
    {
        Player* mainTank = PlayerBotSpec::GetGroupPvePullTank(bot);
        if (!mainTank || mainTank == bot || !mainTank->IsAlive()) return false;
        // Local self-defence is allowed, but does not authorize a chase.
        if (target->GetVictim() == bot && bot->IsWithinMeleeRange(target)) return false;
        if (GroupPveCombat::NeedsRescue(bot, target)) return false;
        return !GroupPveCombat::IsCollected(bot, target);
    }

    Unit* victim = target->GetVictim();
    Player* tank = victim ? victim->ToPlayer() : nullptr;
    Group* group = bot->GetGroup(GroupSlot::Instance);
    if (!group)
        group = bot->GetGroup();
    // Defending a ranged party member must not turn into a long chase into
    // the next pack. Let the tank collect it; still allow local self-defence
    // and targets explicitly being attacked by the real requester.
    if (botAI->IsLfgAutoQueueControlled() && group &&
        !bot->IsWithinMeleeRange(target) &&
        (!botAI->GetMaster() || botAI->GetMaster()->GetVictim() != target))
    {
        bool hasTank = false;
        bool nearTank = false;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* member = ref->GetSource())
                if (member->IsAlive() && member->IsInWorld() && member->GetMap() == bot->GetMap() &&
                    PlayerBotSpec::IsTank(member, true))
                {
                    hasTank = true;
                    if (member->GetDistance(target) <= 8.0f)
                        nearTank = true;
                }
        if (hasTank && !nearTank)
            return true;
    }
    if (!tank || !tank->IsInWorld() || !tank->IsAlive() ||
        tank->GetMap() != bot->GetMap() || !group ||
        !group->IsMember(tank->GetGUID()) ||
        !PlayerBotSpec::IsTank(tank, true) ||
        tank->IsWithinMeleeRange(target))
        return false;

    // Refuse offensive approach actions, not all movement. In particular,
    // do not clear the motion generator here: it can belong to healing,
    // following the moving tank, or escaping a ground effect.
    return true;
}
bool CastKillCommandAction::isUseful()
{
    if (!botAI->IsGroupPveActivity()) return CastAuraSpellAction::isUseful();
    Unit* target = GetTarget();
    Pet* pet = bot->GetPet();
    // Kill Command can make the pet charge. Only use it after the delayed
    // pet order has reached this enemy; never use it to launch a ranged pull.
    return target && pet && pet->IsAlive() && pet->GetVictim() == target &&
        pet->IsWithinMeleeRange(target) && botAI->CanPetEngageTarget(target) &&
        CastSpellAction::isUseful();
}

int checks=0;
void check(bool value,const char* label){++checks;if(!value){std::cerr<<"FAIL "<<label<<"\n";std::exit(1);}}
int main(){
 Player main,off,other; main.id=1;off.id=2;other.id=3;main.tank=off.tank=true;
 AI ai;ai.master=&main;off.ai=&ai;
 Group group{&main,&off,&other};main.group=off.group=other.group=&group;group.leader=main.id;
 Unit enemy;MovementAction move{&ai,&off};
 check(PlayerBotSpec::GetGroupPvePullTank(&off)==&main,"real tank master is fallback");
 check(move.WaitForTankPull(&enemy),"offtank waits for ranged pull");
 main.melee=true;check(!move.WaitForTankPull(&enemy),"offtank joins collected target");main.melee=false;
 main.alive=false;check(!move.WaitForTankPull(&enemy),"offtank may take over dead main");main.alive=true;
 enemy.victim=&off;off.melee=true;check(!move.WaitForTankPull(&enemy),"local self defence");
 off.melee=false;check(move.WaitForTankPull(&enemy),"self threat does not permit chase");enemy.victim=nullptr;
 enemy.victim=&other;check(!move.WaitForTankPull(&enemy),"DPS pull lets off-tank rescue immediately");enemy.victim=nullptr;
 group.marked=&off;check(PlayerBotSpec::GetGroupPvePullTank(&off)==&off,"diamond overrides real tank");
 check(!move.WaitForTankPull(&enemy),"designated tank may approach");
 group.marked=&main;ai.allowed=false;check(move.WaitForTankPull(&enemy),"even tank needs pull permission");ai.allowed=true;
 group.marked=nullptr;ai.master=nullptr;check(PlayerBotSpec::GetGroupPvePullTank(&off)==&main,"leader fallback");
 main.alive=false;check(PlayerBotSpec::GetGroupPvePullTank(&off)==&main,"dead anchor retained");main.alive=true;
 main.map=2;check(PlayerBotSpec::GetGroupPvePullTank(&off)==&off,"wrong-map tank rejected; local tank fallback");main.map=1;
 group.leader=other.id;check(PlayerBotSpec::GetGroupPvePullTank(&off)==&main,"DPS leader gets stable bot tank fallback");group.leader=main.id;
 ai.pve=false;check(!move.WaitForTankPull(&enemy),"PvP movement unchanged");ai.pve=true;
 off.pvp=true;check(PlayerBotSpec::GetGroupPvePullTank(&off)==nullptr,"PvP anchor disabled");off.pvp=false;
 check(!move.WaitForTankPull(nullptr),"null movement object");
 enemy.alive=false;check(!move.WaitForTankPull(&enemy),"dead movement target");enemy.alive=true;
 Pet pet;off.pet=&pet;CastKillCommandAction kill;kill.botAI=&ai;kill.bot=&off;kill.target=&enemy;
 check(!kill.isUseful(),"Kill Command cannot launch idle pet");
 pet.victim=&enemy;check(!kill.isUseful(),"Kill Command waits until pet reaches enemy");
 pet.melee=true;check(kill.isUseful(),"Kill Command uses engaged melee pet");
 ai.petReady=false;check(!kill.isUseful(),"Kill Command preserves shared three-second pull gate");ai.petReady=true;
 pet.alive=false;check(!kill.isUseful(),"dead pet");pet.alive=true;
 kill.base=false;check(!kill.isUseful(),"base safety guard");kill.base=true;
 kill.target=nullptr;check(!kill.isUseful(),"no enemy");
 ai.pve=false;check(kill.isUseful(),"PvP path retains original aura-action behavior");
 std::cout<<"PASS "<<checks<<" checks; pull-tank selection, movement and Kill Command guards\n";
}
