#include "../../modules/mod_playerbots/src/strategy/Classes/shaman/ShamanTotemSupport.h"
#include <cstdio>
#include <cstdlib>
#include <map>
#include <string>
#include <cstdint>
using uint8=std::uint8_t; using uint32=std::uint32_t;
enum { SUMMON_SLOT_TOTEM_FIRE=1, SUMMON_SLOT_TOTEM_EARTH=2, SUMMON_SLOT_TOTEM_WATER=3,
 SUMMON_SLOT_TOTEM_AIR=4, SUMMON_SLOT_TOTEM_EXTRA=5, UNIT_FIELD_CREATED_BY_SPELL=1 };
namespace GroupSlot {enum Slot {Instance};}
struct Creature {
 bool alive=true,totem=true,combat=false; int owner=1; uint32 spell=5394; float distance=10;
 bool IsAlive(){return alive;} bool IsTotem(){return totem;} bool IsInCombat(){return combat;}
 int GetOwnerGUID(){return owner;} uint32 GetUInt32Value(int){return spell;}
};
struct Map {
 std::map<int,Creature*> creatures;
 Creature* GetCreature(int guid){auto i=creatures.find(guid);return i==creatures.end()?nullptr:i->second;}
};
struct Group;
class Player {
public:
 bool alive=true,world=true,combat=false,learned=true; float health=100,distance=5; int guid=1;
 Map* map=nullptr; Group* instance=nullptr; Group* normal=nullptr; int m_SummonSlot[7]={};
 bool IsAlive(){return alive;} bool IsInWorld(){return world;} bool IsInCombat(){return combat;}
 bool HasSpell(int id){return id==36936&&learned;} Map* GetMap(){return map;}
 int GetGUID(){return guid;} float GetDistance(Creature* c){return c->distance;}
 float GetDistance(Player* p){return p->distance;} float GetHealthPct(){return health;}
 Group* GetGroup(GroupSlot::Slot){return instance;} Group* GetGroup(){return normal;}
};
struct GroupReference {Player* source; GroupReference* link=nullptr; Player* GetSource(){return source;} GroupReference* next(){return link;}};
struct Group {GroupReference* first; GroupReference* GetFirstMember(){return first;}};
class PlayerbotAI { public: bool pve=true; bool IsGroupPveActivity(){return pve;} };
using Event=int;
struct CastSpellAction {bool useful=true,executed=false; bool isUseful(){return useful;} bool Execute(Event){executed=true;return true;}};
struct CastBuffSpellAction : CastSpellAction {};
struct CastTotemicRecallAction : CastBuffSpellAction {PlayerbotAI* botAI;Player* bot;bool isUseful();bool Execute(Event event);};
struct CastTotemAction : CastBuffSpellAction {
 PlayerbotAI* botAI;Player* bot;std::string action="healing stream totem";
 bool isUseful(){return useful&&ShamanTotemSupport::CanPlaceWaterTotem(bot,action);}bool Execute(Event event);
};
Creature* GetOwnedActiveTotem(Player* bot, uint8 slot)
{
    if (!bot || !bot->IsInWorld() || !bot->GetMap() || !bot->m_SummonSlot[slot])
        return nullptr;
    Creature* totem = bot->GetMap()->GetCreature(bot->m_SummonSlot[slot]);
    return totem && totem->IsTotem() && totem->IsAlive() &&
        totem->GetOwnerGUID() == bot->GetGUID() ? totem : nullptr;
}

Group* GetTotemCoordinationGroup(Player* bot)
{
    if (!bot)
        return nullptr;

    Group* group = bot->GetGroup(GroupSlot::Instance);
    return group ? group : bot->GetGroup();
}

bool ShamanTotemSupport::IsWaterAction(std::string const& action)
{
    return action == "healing stream totem" || action == "mana spring totem" ||
        action == "cleansing totem" || action == "mana tide totem" ||
        action == "healing tide totem";
}

bool ShamanTotemSupport::HasProtectedWaterTotem(Player* bot)
{
    // Totemic Persistence can move a water totem into the extra slot. Range
    // must not make a still-running healing/mana cooldown replaceable.
    for (uint8 slot : {SUMMON_SLOT_TOTEM_WATER, SUMMON_SLOT_TOTEM_EXTRA})
        if (Creature* totem = GetOwnedActiveTotem(bot, slot))
        {
            uint32 spellId = totem->GetUInt32Value(UNIT_FIELD_CREATED_BY_SPELL);
            if (spellId == 16190 || spellId == 108280)
                return true;
        }
    return false;
}

bool ShamanTotemSupport::CanPlaceWaterTotem(Player* bot, std::string const& action)
{
    if (!IsWaterAction(action))
        return true;
    if (HasProtectedWaterTotem(bot))
        return false;
    // Emergency cooldowns may replace a regular stream/spring, never each other.
    if (action == "mana tide totem" || action == "healing tide totem")
        return true;
    Creature* water = GetOwnedActiveTotem(bot, SUMMON_SLOT_TOTEM_WATER);
    return !water || bot->GetDistance(water) > 30.0f;
}

bool ShamanTotemSupport::NeedsWaterTotem(PlayerbotAI* ai, Player* bot)
{
    return ai->IsGroupPveActivity() && bot->IsAlive() && bot->IsInWorld() &&
        bot->IsInCombat() && CanPlaceWaterTotem(bot, "healing stream totem");
}

bool ShamanTotemSupport::CanRecallTotems(PlayerbotAI* ai, Player* bot)
{
    if (!ai->IsGroupPveActivity() || !bot->IsAlive() || !bot->IsInWorld() ||
        bot->IsInCombat() || !bot->HasSpell(36936) || HasProtectedWaterTotem(bot))
        return false;
    Group* group = GetTotemCoordinationGroup(bot);
    if (!group)
        return false;
    bool injured = false;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || !member->IsAlive() || !member->IsInWorld() ||
            member->GetMap() != bot->GetMap())
            continue;
        if (member->IsInCombat())
            return false; // No recalling between boss phases or during another member's pull.
        if (member->GetHealthPct() < 95.0f && bot->GetDistance(member) <= 40.0f)
            injured = true;
    }
    bool found = false;
    for (uint8 slot : {SUMMON_SLOT_TOTEM_FIRE, SUMMON_SLOT_TOTEM_EARTH,
                       SUMMON_SLOT_TOTEM_WATER, SUMMON_SLOT_TOTEM_AIR,
                       SUMMON_SLOT_TOTEM_EXTRA})
        if (Creature* totem = GetOwnedActiveTotem(bot, slot))
        {
            if (totem->IsInCombat())
                return false;
            uint32 spellId = totem->GetUInt32Value(UNIT_FIELD_CREATED_BY_SPELL);
            if (injured && (spellId == 5394 || spellId == 98008))
                return false; // Let Healing Stream/Spirit Link finish recovery.
            found = true;
        }
    return found;
}

bool CastTotemicRecallAction::isUseful()
{
    return ShamanTotemSupport::CanRecallTotems(botAI, bot) && CastSpellAction::isUseful();
}

bool CastTotemicRecallAction::Execute(Event event)
{
    return isUseful() && CastBuffSpellAction::Execute(event);
}

bool CastTotemAction::Execute(Event event)
{
    // Recheck immediately before casting: a queued regular water totem must
    // not destroy a Mana Tide that appeared after action selection.
    return (!botAI->IsGroupPveActivity() || isUseful()) && CastBuffSpellAction::Execute(event);
}
int checks=0;
void check(bool ok,const char* label){++checks;if(!ok){std::fprintf(stderr,"FAIL %s\n",label);std::exit(1);}}
int main(){
 using namespace ShamanTotemSupport;
 Map map,otherMap;Player bot,member;PlayerbotAI ai;bot.map=member.map=&map;
 GroupReference ref{&member};Group group{&ref};bot.instance=&group;
 Creature water,fire,extra;fire.spell=3599;extra.spell=16190;
 map.creatures={{10,&water},{11,&fire},{12,&extra}};
 check(!CanRecallTotems(&ai,&bot),"no totems no recall");
 check(!NeedsWaterTotem(&ai,&bot),"no water casting while idle");
 bot.combat=true;check(NeedsWaterTotem(&ai,&bot),"combat missing water");
 bot.m_SummonSlot[3]=10;check(!NeedsWaterTotem(&ai,&bot),"do not replace working stream");
 check(CanPlaceWaterTotem(&bot,"mana tide totem"),"Mana Tide may replace stream");
 check(CanPlaceWaterTotem(&bot,"healing tide totem"),"Healing Tide may replace stream");
 water.distance=31;check(NeedsWaterTotem(&ai,&bot),"distant ordinary totem relocates");
 water.spell=16190;check(!NeedsWaterTotem(&ai,&bot),"distant Mana Tide protected");
 check(!CanPlaceWaterTotem(&bot,"healing tide totem"),"do not interrupt Mana Tide with Healing Tide");
 water.spell=108280;check(!CanPlaceWaterTotem(&bot,"mana tide totem"),"do not interrupt Healing Tide with Mana Tide");
 check(!CanPlaceWaterTotem(&bot,"cleansing totem"),"cleansing cannot interrupt cooldown");
 check(CanPlaceWaterTotem(&bot,"searing totem"),"fire slot independent");
 water.alive=false;check(NeedsWaterTotem(&ai,&bot),"destroyed totem is absent");water.alive=true;
 bot.m_SummonSlot[3]=0;bot.m_SummonSlot[5]=12;
 check(!NeedsWaterTotem(&ai,&bot),"Persistence extra Mana Tide protected");
 extra.spell=108280;check(!NeedsWaterTotem(&ai,&bot),"extra Healing Tide protected");
 extra.alive=false;check(NeedsWaterTotem(&ai,&bot),"expired extra cooldown permits water");extra.alive=true;
 bot.combat=false;check(!CanRecallTotems(&ai,&bot),"recall preserves cooldown after combat");
 bot.m_SummonSlot[5]=0;bot.m_SummonSlot[1]=11;
 check(CanRecallTotems(&ai,&bot),"completed combat recalls ordinary totem");
 bot.combat=true;check(!CanRecallTotems(&ai,&bot),"own combat blocks recall");bot.combat=false;
 member.combat=true;check(!CanRecallTotems(&ai,&bot),"group combat blocks recall");
 member.map=&otherMap;check(CanRecallTotems(&ai,&bot),"other map combat ignored");member.map=&map;
 member.alive=false;check(CanRecallTotems(&ai,&bot),"dead group member ignored");member.alive=true;
 member.world=false;check(CanRecallTotems(&ai,&bot),"offline group member ignored");member.world=true;member.combat=false;
 fire.combat=true;check(!CanRecallTotems(&ai,&bot),"owned totem fighting blocks recall");fire.combat=false;
 water.spell=5394;water.distance=10;bot.m_SummonSlot[3]=10;member.health=60;
 check(!CanRecallTotems(&ai,&bot),"stream retained for recovery");
 member.health=95;check(CanRecallTotems(&ai,&bot),"recovered group allows recall");
 member.health=60;water.spell=98008;check(!CanRecallTotems(&ai,&bot),"spirit link retained for recovery");
 member.distance=50;check(CanRecallTotems(&ai,&bot),"distant injury does not retain useless totem");member.distance=5;member.health=100;
 bot.learned=false;check(!CanRecallTotems(&ai,&bot),"must learn recall");bot.learned=true;
 bot.alive=false;check(!CanRecallTotems(&ai,&bot),"dead shaman");bot.alive=true;
 bot.world=false;check(!CanRecallTotems(&ai,&bot),"offline shaman");bot.world=true;
 bot.instance=nullptr;check(!CanRecallTotems(&ai,&bot),"requires group");bot.normal=&group;
 check(CanRecallTotems(&ai,&bot),"normal group fallback");
 ai.pve=false;check(!CanRecallTotems(&ai,&bot),"PvP and solo no recall");
 bot.combat=true;check(!NeedsWaterTotem(&ai,&bot),"PvP water behavior unchanged");
 ai.pve=true;bot.combat=false;
 water.owner=2;check(GetOwnedActiveTotem(&bot,3)==nullptr,"foreign owner rejected");water.owner=1;
 water.totem=false;check(GetOwnedActiveTotem(&bot,3)==nullptr,"non-totem summon rejected");water.totem=true;
 bot.m_SummonSlot[3]=99;check(GetOwnedActiveTotem(&bot,3)==nullptr,"stale GUID rejected");
 bot.map=nullptr;check(GetOwnedActiveTotem(&bot,1)==nullptr,"missing map safe");bot.map=&map;
 CastTotemicRecallAction recall;recall.botAI=&ai;recall.bot=&bot;
 check(recall.isUseful(),"recall selected");
 member.combat=true;check(!recall.Execute(0)&&!recall.executed,"recall execution rechecks new combat");member.combat=false;
 check(recall.Execute(0)&&recall.executed,"recall uses spell execution");
 CastTotemAction cast;cast.botAI=&ai;cast.bot=&bot;
 bot.m_SummonSlot[3]=0;check(cast.isUseful(),"regular water selected");
 bot.m_SummonSlot[5]=12;check(!cast.Execute(0)&&!cast.executed,"queued water cannot replace new Mana Tide");
 bot.m_SummonSlot[5]=0;check(cast.Execute(0)&&cast.executed,"water restored after cooldown ends");
 cast.executed=false;cast.useful=false;check(!cast.Execute(0),"other action conditions retained");
 ai.pve=false;check(cast.Execute(0),"PvP execution path unchanged");
 std::printf("%d shaman totem lifecycle checks passed\n",checks);
}

