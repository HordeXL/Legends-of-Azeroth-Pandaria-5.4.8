// Minimal world doubles exercise the production planner, not a second copy.
#include "../../modules/mod_playerbots/src/AI/AhnQirajPolicy.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <list>
#include <map>
#include <vector>
struct Position
{
    float x=0,y=0,z=0,o=0;
    void Relocate(float a,float b,float c) {x=a;y=b;z=c;}
    float GetPositionX() const{return x;} float GetPositionY() const{return y;}
    float GetPositionZ() const{return z;} float GetOrientation() const{return o;}
    float GetExactDist2d(Position const* p) const{return std::hypot(x-p->x,y-p->y);}
    float GetExactDist2d(float a,float b) const{return std::hypot(x-a,y-b);}
    float GetAngle(Position const* p) const{return std::atan2(p->y-y,p->x-x);}
};
struct Aura {unsigned stacks=0; unsigned GetStackAmount(){return stacks;}};
struct Unit : Position
{
    unsigned entry=0,guid=0,map=531; bool alive=true,world=true,combat=true,hostile=true;
    Unit* victim=nullptr; std::map<unsigned,Aura> auras;
    bool IsAlive() const{return alive;} bool IsInWorld() const{return world;}
    bool IsInCombat() const{return combat;} unsigned GetMap() const{return map;}
    unsigned GetMapId() const{return map;} unsigned GetEntry() const{return entry;}
    unsigned GetGUID() const{return guid;} Unit* GetVictim(){return victim;}
    bool HasAura(unsigned id){return auras.count(id);}
    Aura* GetAura(unsigned id){auto it=auras.find(id);return it==auras.end()?nullptr:&it->second;}
};
using WorldObject=Unit;
struct Player;
struct ThreatManager {std::map<Player*,float> values;float getThreat(Player* p){return values[p];}};
struct Creature:Unit
{
    Position home;ThreatManager threat;
    Position const& GetHomePosition(){return home;}
    ThreatManager& GetThreatManager(){return threat;}
};
struct GroupReference
{
    Player* player=nullptr; GroupReference* following=nullptr;
    Player* GetSource(){return player;} GroupReference* next(){return following;}
};
struct Group
{
    std::vector<GroupReference> refs;
    GroupReference* GetFirstMember(){return refs.empty()?nullptr:&refs[0];}
};
enum class GroupSlot {Instance};
struct InstanceScript
{
    unsigned phase=0;
    unsigned GetData(unsigned){return phase;} unsigned GetGuidData(unsigned entry){return entry;}
};
std::vector<Creature*> creatures;
struct Player:Unit
{
    Group* group=nullptr;InstanceScript* instance=nullptr;unsigned role=3;bool ranged=false;float health=100;
    Player(){hostile=false;}
    Group* GetGroup(){return group;} Group* GetGroup(GroupSlot){return group;}
    InstanceScript* GetInstanceScript(){return instance;}
    bool IsValidAttackTarget(Unit const* u){return u && u->hostile;}
    float GetHealthPct(){return health;}
    bool IsWithinLOSInMap(Unit*){return true;}
    float GetMeleeRange(Unit*){return 6;}
    bool IsWithinCombatRange(Unit* u,float range)
    {return std::hypot(GetExactDist2d(u),z-u->z)<range+4;}
    Creature* FindNearestCreature(unsigned entry,float range,bool alive)
    {
        Creature* found=nullptr;
        for(auto* c:creatures)
        {
            float distance=std::hypot(GetExactDist2d(c),z-c->z);
            if(c->entry==entry && c->alive==alive && distance<range){found=c;range=distance;}
        }
        return found;
    }
    void GetCreatureListWithEntryInGrid(std::list<Creature*>& out,unsigned entry,float range)
    {for(auto* c:creatures)if(c->entry==entry && std::hypot(GetExactDist2d(c),z-c->z)<range)out.push_back(c);}
};
struct PlayerBotSpec
{
    static bool IsTank(Player* p,bool){return p->role==0;}
    static bool IsHeal(Player* p,bool){return p->role==1;}
    static bool IsCaster(Player* p,bool){return p->role==2;}
    static bool IsRanged(Player* p,bool){return p->ranged||p->role==1||p->role==2;}
};
namespace ObjectAccessor
{
Creature* GetCreature(Player&,unsigned id){for(auto* c:creatures)if(c->entry==id)return c;return nullptr;}
}
namespace AhnQirajStrategy
{
struct Plan {Unit* target=nullptr;Position destination;bool move=false,emergency=false;};
bool IsActive(Player*);
}
struct Config
{
    bool enabled=false;
    bool GetBoolDefault(char const*, bool fallback) { return enabled || fallback; }
} config;
auto sConfigMgr=&config;
#include "strategy-under-test.inc"
unsigned checks=0;
void Check(bool ok,char const* message)
{++checks;if(!ok){std::cerr<<"FAIL: "<<message<<'\n';std::exit(1);}}
int main()
{
    using namespace AhnQirajPolicy;
    using namespace AhnQirajStrategy;
    Group raid;InstanceScript instance;Player players[8];
    for(unsigned i=0;i<8;++i)
    {
        players[i].guid=i+1;players[i].role=i/2;players[i].group=&raid;players[i].instance=&instance;
        players[i].x=(i%2)*100;raid.refs.push_back({&players[i],nullptr});
    }
    for(unsigned i=0;i<7;++i)raid.refs[i].following=&raid.refs[i+1];
    Creature melee,caster,eye,body,flesh,add;
    melee.entry=Veknilash;caster.entry=Veklor;caster.x=100;caster.home.x=100;
    creatures={&melee,&caster};
    Check(BuildPlan(&players[0]).target==&melee,"first tank owns original melee side");
    Check(BuildPlan(&players[1]).target==nullptr,"opposite tank does not cross to melee boss");
    Check(BuildPlan(&players[4]).target==&caster,"first caster acquires Veklor on the magical platform");
    Check(BuildPlan(&players[4]).destination.x>60,"caster moves to magical platform regardless of starting position");
    Check(!BuildPlan(&players[5]).target,"other caster waits for ranged threat owner");
    players[4].x=88;caster.victim=&players[4];caster.threat.values[&players[4]]=100;
    Check(BuildPlan(&players[5]).target==&caster,"all casters attack Veklor after owner pickup");
    caster.threat.values[&players[5]]=85;
    Check(!BuildPlan(&players[5]).target,"caster throttles before overtaking threat owner");
    caster.threat.values[&players[5]]=0;
    Check(!AllowsTarget(&players[6],&caster),"physical DPS cannot assist the magic boss");
    Check(!BuildPlan(&players[6]).target,"physical DPS waits for its tank to own the boss");
    melee.victim=&players[0];
    Check(BuildPlan(&players[6]).target==&melee,"physical DPS starts after local tank pickup");
    Check(BuildPlan(&players[7]).target==&melee,"all physical DPS uses the melee platform");
    Check(BuildPlan(&players[7]).destination.x<40,"physical DPS crosses to its matching platform");
    players[4].alive=false;
    Check(BuildPlan(&players[5]).target==&caster,"next caster takes over after ranged owner dies");
    players[4].alive=true;
    Check(BuildPlan(&players[0]).destination.x<40,"first tank stays on first side");
    Check(BuildPlan(&players[1]).destination.x>60,"second tank stays on second side");
    players[0].alive=false;
    Check(BuildPlan(&players[1]).destination.x>60,"tank death does not reshuffle sides");
    players[0].alive=true;
    melee.combat=caster.combat=false;
    Check(!IsActive(&players[0]),"encounter reset releases the planner");

    eye.entry=Eye;eye.z=100;body.entry=Body;body.z=100;body.hostile=false;
    creatures={&eye,&body};instance.phase=1;
    Player* bot=&players[4];bot->Relocate(-28,0,100);
    for(unsigned phase=1;phase<=5;++phase)
    {
        instance.phase=phase;
        Check(!IsActive(bot),"Cthun planner disabled by default in every phase");
        auto disabled=BuildPlan(bot);
        Check(!disabled.move && !disabled.target && !disabled.emergency,"disabled planner performs no encounter actions");
        Check(AllowsTarget(bot,&eye),"disabled planner releases ordinary target selection");
    }
    config.enabled=true;instance.phase=1; // Legacy planner tests require explicit opt-in.
    Check(BuildPlan(bot).target==&eye,"green phase attacks eye");
    add.entry=15726;add.Relocate(-26,1,100);creatures.push_back(&add);
    Check(BuildPlan(bot).target==&add,"nearby eye tentacle takes priority");
    add.world=false;
    Check(BuildPlan(bot).target==&eye,"removed tentacle cannot remain an encounter target");
    add.world=true;
    instance.phase=2;bot->Relocate(25,0,100);eye.o=0;
    auto dodge=BuildPlan(bot);
    Check(dodge.move && dodge.emergency && !dodge.target,"dark glare preempts attacks with a dodge");
    bot->Relocate(-25,0,100);
    Check(!BuildPlan(bot).move,"safe bot can cast during glare without returning to its slot");
    instance.phase=3;
    Check(!BuildPlan(bot).target,"transition does not attack immune body");
    instance.phase=4;body.hostile=true;add.alive=false;
    Check(!BuildPlan(bot).target,"armoured body is not attacked");
    instance.phase=5;add.alive=true;
    Check(BuildPlan(bot).target==&body,"weakened body outranks adds");
    instance.phase=4;flesh.entry=Flesh;flesh.Relocate(-8571,1990,-98);creatures.push_back(&flesh);
    eye.Relocate(-8560,2000,100);body.Relocate(-8560,2000,100);
    bot->Relocate(-8562,2037,-98);
    Check(BuildPlan(bot).target==&flesh,"swallowed bot targets flesh tentacle");
    Check(!AllowsTarget(bot,&body),"stomach cannot target outside body");
    bot->auras[Acid].stacks=8;
    auto exit=BuildPlan(bot);
    Check(exit.emergency && !exit.target && exit.destination.x==-8545,"acid sends bot to real exit pad");
    bot->auras.clear();bot->health=30;
    Check(BuildPlan(bot).emergency,"low health leaves stomach");
    bot->health=100;flesh.alive=false;
    Check(BuildPlan(bot).emergency,"no flesh tentacles leaves stomach");
    instance.phase=6;
    Check(!IsActive(bot),"victory releases ordinary bot AI");
    instance.phase=1;bot->Relocate(0,0,100);
    Check(!IsActive(bot),"unrelated combat elsewhere in AQ40 is unaffected");
    bot->map=1;
    Check(!IsActive(bot) && AllowsTarget(bot,&eye),"other maps unaffected");
    // A full melee roster used to collapse onto the eye, despite the
    // nominal spread policy tests passing for ranged players alone.
    Group fullRaid;Player meleeRaid[40];
    instance.phase=1;eye.Relocate(0,0,100);body.Relocate(0,0,100);
    creatures={&eye,&body};
    for (unsigned i=0;i<40;++i)
    {
        auto slot=SpreadSlot(i);
        auto& p=meleeRaid[i];p.guid=100+i;p.role=0;p.group=&fullRaid;p.instance=&instance;
        p.Relocate(slot.radius*std::cos(slot.angle),slot.radius*std::sin(slot.angle),100);
        fullRaid.refs.push_back({&p,nullptr});
    }
    for(unsigned i=0;i<39;++i)fullRaid.refs[i].following=&fullRaid.refs[i+1];
    for(auto& p:meleeRaid)
    {
        auto plan=BuildPlan(&p);
        Check(!plan.target,"eye phase does not stack melee onto the boss");
        Check(!plan.move,"spread melee holds its own slot");
    }
    meleeRaid[0].x-=2;
    Check(BuildPlan(&meleeRaid[0]).move,"two-yard slot error is corrected to prevent beam chains");
    meleeRaid[0].x+=2;
    meleeRaid[0].role=1;
    meleeRaid[0].x+=0.4f;
    Check(!BuildPlan(&meleeRaid[0]).move,"healer with small arrival error stays still to heal");
    Check(!BuildPlan(&meleeRaid[0]).emergency,"arrival error does not interrupt healing");
    meleeRaid[0].x-=0.4f;
    meleeRaid[0].role=0;
    add.alive=true;add.Relocate(14,0,100);creatures.push_back(&add);
    unsigned responders=0;
    for(auto& p:meleeRaid)if(BuildPlan(&p).target==&add)++responders;
    Check(responders==1,"exactly one melee responder takes a nearby tentacle");
    auto approach=BuildPlan(&meleeRaid[0]);
    meleeRaid[1].Relocate(approach.destination.x,approach.destination.y,100);
    Check(!BuildPlan(&meleeRaid[0]).target,"crowded tentacle approach yields instead of chaining beam");
    // Reproduce a pull from a stacked entrance, not just an already formed raid.
    creatures={&eye,&body};
    for(auto& p:meleeRaid)p.Relocate(-55,0,100);
    for(auto& p:meleeRaid)
    {
        auto opening=BuildPlan(&p);
        Check(opening.move && opening.emergency,"stacked opening prioritizes spreading");
        Check(p.GetExactDist2d(&opening.destination) / 7.0f < 18.0f,
            "opening slot reachable before first beam with two seconds of reaction margin");
    }
    std::cout<<"AQ40 production planner: "<<checks<<" checks passed\n";
}
