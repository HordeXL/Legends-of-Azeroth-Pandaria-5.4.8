// Isolated regression: production bodies copied verbatim at test creation.
// Does not emulate the server scheduler or claim an in-game DPS result.
#include <array>
#include <vector>
#include <map>
#include <set>
#include <string>
#include <iostream>
#include <fstream>
#include <iterator>
#include <cstring>
#include <algorithm>
using uint8=unsigned char; using uint32=unsigned int;
enum { CLASS_WARRIOR=1, CLASS_PALADIN, CLASS_HUNTER, CLASS_ROGUE, CLASS_PRIEST,
 CLASS_DEATH_KNIGHT, CLASS_SHAMAN, CLASS_MAGE, CLASS_WARLOCK, CLASS_MONK, CLASS_DRUID };
enum { SPEC_DEATH_KNIGHT_UNHOLY=252, SPEC_MAGE_ARCANE=62, SPEC_MAGE_FIRE=63, SPEC_MAGE_FROST=64,
 SPEC_DRUID_FERAL=103, SPEC_DRUID_GUARDIAN=104 };
struct Aura { int duration=10000, stacks=1; int GetDuration(){return duration;} int GetStackAmount(){return stacks;} };
struct Unit {
 bool alive=true; std::map<uint32,Aura> auras;
 bool IsAlive(){return alive;}
 Aura* GetAura(uint32 id, int=0){auto i=auras.find(id);return i==auras.end()?nullptr:&i->second;}
 bool HasAura(uint32 id,int=0){return GetAura(id)!=nullptr;}
};
struct Player: Unit {
 uint32 cls=0,spec=0; bool heal=false,tank=false,combat=true,valid=true; uint8 points=0;
 Unit* combo=nullptr; std::set<uint32> spells;
 uint32 GetClass(){return cls;} uint32 GetSpecialization(){return spec;}
 bool HasSpell(uint32 id){return spells.count(id)!=0;} bool IsInCombat(){return combat;}
 bool IsValidAttackTarget(Unit*){return valid;} Unit* GetComboTarget(){return combo;}
 uint8 GetComboPoints(){return points;} int GetGUID(){return 1;}
};
namespace PlayerBotSpec {
 bool IsHeal(Player* p,bool){return p->heal;} bool IsTank(Player* p,bool){return p->tank;}
}
struct BotFactory { enum class ManagedLoadoutMode {Pve,Pvp}; };
struct PlayerbotAI {
 Player* p; Unit* target=nullptr; bool pve=true,engage=true,pack=false;
 bool IsGroupPveActivity(){return pve;} bool CanLfgAutoQueueEngage(Unit*){return engage;}
 void RemoveAura(std::string){p->auras.erase(13877);}
};
struct Trigger {
 PlayerbotAI* botAI; Player* bot;
 Trigger(PlayerbotAI* a,std::string,int):botAI(a),bot(a->p){} virtual bool IsActive(){return false;}
};
struct LightAoeTrigger { PlayerbotAI* ai; LightAoeTrigger(PlayerbotAI* a):ai(a){} bool IsActive(){return ai->pack;} };
#define AI_VALUE(type,key) botAI->target
uint8 GetManagedTalentProfileColumn(Player* bot, uint8 row,
    BotFactory::ManagedLoadoutMode mode)
{
    if (!bot || row >= 6)
        return 0;

    bool const pvp = mode == BotFactory::ManagedLoadoutMode::Pvp;
    bool const healer = PlayerBotSpec::IsHeal(bot, true);
    bool const tank = PlayerBotSpec::IsTank(bot, true);
    std::array<uint8, 6> profile{};

    // Zero-based MoP Talent.dbc columns. PvE profiles are authoritative:
    // prefer supported abilities/passives, not arbitrary effect-score totals.
    // Utility/control talents need not be spammed by the damage rotation.
    switch (bot->GetClass())
    {
        case CLASS_WARRIOR:
            profile = pvp ? std::array<uint8, 6>{ 2, 1, 1, 1, 1, 2 } :
                (tank ? std::array<uint8, 6>{ 1, 1, 2, 1, 2, 1 } :
                        std::array<uint8, 6>{ 1, 1, 2, 0, 2, 1 });
            break;
        case CLASS_PALADIN:
            profile = pvp ? std::array<uint8, 6>{ 0, 1, 2, 2, 1, 0 } :
                (healer ? std::array<uint8, 6>{ 2, 0, 1, 1, 1, 0 } :
                 tank ? std::array<uint8, 6>{ 2, 0, 2, 1, 2, 2 } :
                        std::array<uint8, 6>{ 2, 0, 2, 1, 2, 2 });
            break;
        case CLASS_HUNTER:
            profile = pvp ? std::array<uint8, 6>{ 1, 2, 0, 2, 1, 2 } :
                            std::array<uint8, 6>{ 2, 0, 1, 2, 0, 0 };
            break;
        case CLASS_ROGUE:
            profile = pvp ? std::array<uint8, 6>{ 1, 2, 0, 1, 0, 1 } :
                            std::array<uint8, 6>{ 2, 1, 0, 2, 0, 2 };
            // PvE: Shadow Focus, Nerve Strike, Cheat Death, Burst of Speed,
            // Prey on the Weak, Anticipation. No automatic opener teleport
            // from Cloak and Dagger, nor unused ranged Shuriken Toss.
            break;
        case CLASS_PRIEST:
            profile = pvp ? std::array<uint8, 6>{ 1, 2, 1, 1, 1, 1 } :
                (healer ? std::array<uint8, 6>{ 0, 0, 0, 2, 0, 0 } :
                          std::array<uint8, 6>{ 0, 0, 2, 2, 0, 0 });
            break;
        case CLASS_DEATH_KNIGHT:
            profile = pvp ? std::array<uint8, 6>{ 2, 1, 2, 1, 0, 2 } :
                (bot->GetSpecialization() == SPEC_DEATH_KNIGHT_UNHOLY ?
                    std::array<uint8, 6>{ 0, 2, 0, 0, 2, 1 } :
                    std::array<uint8, 6>{ 0, 2, 0, 0, 1, 1 });
            break;
        case CLASS_SHAMAN:
            profile = pvp ? std::array<uint8, 6>{ 2, 2, 2, 0, 1, 1 } :
                (healer ? std::array<uint8, 6>{ 0, 2, 1, 1, 0, 1 } :
                          std::array<uint8, 6>{ 0, 2, 1, 2, 0, 1 });
            break;
        case CLASS_MAGE:
            profile = pvp ? std::array<uint8, 6>{ 2, 2, 2, 0, 1, 2 } :
                            std::array<uint8, 6>{ 0, 1, 1, 1,
                                uint8(bot->GetSpecialization() == SPEC_MAGE_ARCANE ? 0 : 1), 1 };
            break;
        case CLASS_WARLOCK:
            profile = pvp ? std::array<uint8, 6>{ 2, 1, 2, 2, 1, 0 } :
                            std::array<uint8, 6>{ 1, 2, 0, 2, 0, 1 };
            break;
        case CLASS_MONK:
            profile = pvp ? std::array<uint8, 6>{ 1, 0, 2, 0, 2, 1 } :
                            std::array<uint8, 6>{ 0, 0, 1, 2, 0, 1 };
            break;
        case CLASS_DRUID:
            profile = pvp ? std::array<uint8, 6>{ 1, 1, 0, 2, 2, 0 } :
                            std::array<uint8, 6>{ 0, 0, 1, 0, 2, 0 };
            break;
        default:
            profile = { 0, 0, 0, 0, 0, 0 };
            break;
    }

    return profile[row];
}

std::array<uint32, 3> GetManagedPveMajorGlyphSpells(Player* bot)
{
    bool const healer = PlayerBotSpec::IsHeal(bot, true);
    switch (bot->GetClass())
    {
        case CLASS_WARRIOR: return {58098, 58382,
            uint32(PlayerBotSpec::IsTank(bot, true) ? 58388 : 58372)};
        case CLASS_PALADIN:
            if (healer) return {57955, 63218, 54939};
            if (PlayerBotSpec::IsTank(bot, true)) return {54924, 54936, 54939};
            return {54926, 54936, 63220};
        case CLASS_HUNTER: return {20895, 56850, 56844};
        case CLASS_ROGUE: return {56804, 63269, 56811};
        case CLASS_PRIEST: return healer ? std::array<uint32, 3>{14771, 89489, 55685} :
            std::array<uint32, 3>{14771, 55686, 120585};
        case CLASS_DEATH_KNIGHT: return {58623, 146648, 58673};
        case CLASS_SHAMAN: return healer ? std::array<uint32, 3>{55436, 55456, 55440} :
            std::array<uint32, 3>{55447, 55456, 55449};
        case CLASS_MAGE: return {56380, 115723, uint32(bot->GetSpecialization() == SPEC_MAGE_FROST ?
            63090 : bot->GetSpecialization() == SPEC_MAGE_FIRE ? 56368 : 62210)};
        case CLASS_WARLOCK: return {56218, 56224, 56231};
        case CLASS_MONK: return {120479, 120482, uint32(healer ? 123334 : 146953)};
        case CLASS_DRUID:
            if (healer) return {54733, 17076, 54825};
            if (bot->GetSpecialization() == SPEC_DRUID_FERAL) return {47180, 114300, 54733};
            if (bot->GetSpecialization() == SPEC_DRUID_GUARDIAN) return {54733, 114222, 114223};
            return {54733, 146655, 114222};
        default: return {};
    }
}


class PveSpellStateTrigger : public Trigger
{
public:
    enum State { MissingSelf, MissingDot, Proc, Ready, LunarFiller, SolarFiller,
        FeralBuild, FeralRip, FeralBite, FeralRoar, Combustion, Maelstrom, Stagger, CombatCleave };
    PveSpellStateTrigger(PlayerbotAI* ai, uint32 spell, State state, uint32 aura = 0)
        : Trigger(ai, "pve spell state", 1), spell(spell), state(state), aura(aura ? aura : spell) {}
    bool IsActive() override
    {
        if (!botAI->IsGroupPveActivity() || !bot->IsAlive() || !bot->HasSpell(spell))
            return false;
        if (state == MissingSelf)
            return (spell != 62606 || bot->IsInCombat()) && !bot->HasAura(aura);
        if (state == Stagger)
            return bot->HasAura(124274) || bot->HasAura(124273);
        if (state == CombatCleave)
        {
            LightAoeTrigger pack(botAI);
            if (!pack.IsActive())
            {
                botAI->RemoveAura("blade flurry");
                return false;
            }
            return !bot->HasAura(aura);
        }
        Unit* target = AI_VALUE(Unit*, "current target");
        if (!target || !target->IsAlive() || !bot->IsInCombat() ||
            !bot->IsValidAttackTarget(target) || !botAI->CanLfgAutoQueueEngage(target))
            return false;
        Aura* dot = target->GetAura(aura, bot->GetGUID());
        uint8 const points = bot->GetComboTarget() == target ? bot->GetComboPoints() : 0;
        switch (state)
        {
            case MissingDot: return !dot || (dot->GetDuration() >= 0 && dot->GetDuration() < 2000);
            case Proc: return bot->HasAura(aura);
            case Ready: return true; // Action still checks cooldown, resources and range.
            // Solar marker permits positive energy from Starfire; lunar marker
            // permits negative energy from Wrath (spell_druid.cpp).
            case LunarFiller: return bot->HasAura(67483);
            case SolarFiller: return !bot->HasAura(67483);
            case FeralBuild: return points < 5;
            case FeralRip: return points >= 5 && (!dot || dot->GetDuration() < 2000);
            case FeralBite: return points >= 5 && dot && dot->GetDuration() > 4000 && bot->HasAura(52610);
            case FeralRoar: return points > 0 && !bot->HasAura(52610);
            case Combustion: return target->HasAura(12654, bot->GetGUID()) &&
                target->HasAura(11366, bot->GetGUID()) && !dot;
            case Maelstrom:
                if (Aura* proc = bot->GetAura(53817)) return proc->GetStackAmount() >= 5;
                return false;
            default: return false;
        }
    }
private:
    uint32 spell;
    State state;
    uint32 aura;
};


enum { DISPEL_MAGIC=1, DISPEL_CURSE=2, DISPEL_DISEASE=3, DISPEL_POISON=4,
    SPEC_SHAMAN_ENHANCEMENT=263, SPEC_SHAMAN_RESTORATION=264 };
struct PveDispelSpell { uint32 id; char const* name; uint32 types; };
inline PveDispelSpell GetPveDispelSpell(Player* bot)
{
    bool heal = PlayerBotSpec::IsHeal(bot, true);
    uint32 magic = 1u << DISPEL_MAGIC, curse = 1u << DISPEL_CURSE;
    uint32 poison = 1u << DISPEL_POISON, disease = 1u << DISPEL_DISEASE;
    switch (bot->GetClass())
    {
        case CLASS_PALADIN: return {4987, "cleanse", poison | disease | (heal ? magic : 0)};
        case CLASS_PRIEST: return {527, "purify", heal ? magic | disease : 0};
        case CLASS_SHAMAN: return heal ? PveDispelSpell{77130, "purify spirit", magic | curse} :
            PveDispelSpell{51886, "cleanse spirit", curse};
        case CLASS_MAGE: return {475, "remove curse", curse};
        case CLASS_MONK: return {115450, "detox", poison | disease | (heal ? magic : 0)};
        case CLASS_DRUID: return heal ? PveDispelSpell{88423, "nature's cure", magic | curse | poison} :
            PveDispelSpell{2782, "remove corruption", curse | poison};
        default: return {0, "", 0};
    }
}
struct Dbc {
 std::vector<unsigned char> bytes; uint32 count=0,size=0;
 Dbc(std::string name){std::ifstream in("Build/bin/RelWithDebInfo/dbc/"+name,std::ios::binary);
 bytes.assign(std::istreambuf_iterator<char>(in),{}); if(bytes.size()<20) throw name;
 count=u(4);size=u(12);}
 uint32 u(size_t at)const{uint32 v;std::memcpy(&v,bytes.data()+at,4);return v;}
 uint32 field(uint32 i,uint32 j)const{return u(20+i*size+j*4);}
};
int tests=0;
void check(bool value,const char* name){++tests;if(!value){std::cerr<<"FAIL: "<<name<<"\n";std::exit(1);}}
int main(){
 Dbc talents("Talent.dbc"),glyphs("GlyphProperties.dbc"),spells("Spell.dbc");
 std::set<uint32> spellIds,major;
 for(uint32 i=0;i<spells.count;++i)spellIds.insert(spells.field(i,0));
 for(uint32 i=0;i<glyphs.count;++i)if(glyphs.field(i,2)==0)major.insert(glyphs.field(i,1));
 std::vector<std::array<uint32,4>> specs={
 {1,71,0,0},{1,72,0,0},{1,73,0,1},{2,65,1,0},{2,66,0,1},{2,70,0,0},
 {3,253,0,0},{3,254,0,0},{3,255,0,0},{4,259,0,0},{4,260,0,0},{4,261,0,0},
 {5,256,1,0},{5,257,1,0},{5,258,0,0},{6,250,0,1},{6,251,0,0},{6,252,0,0},
 {7,262,0,0},{7,263,0,0},{7,264,1,0},{8,62,0,0},{8,63,0,0},{8,64,0,0},
 {9,265,0,0},{9,266,0,0},{9,267,0,0},{10,268,0,1},{10,269,0,0},{10,270,1,0},
 {11,102,0,0},{11,103,0,0},{11,104,0,1},{11,105,1,0}};
 const std::array<std::array<uint8,6>,11> oldPvp={{
 {2,1,1,1,1,2},{0,1,2,2,1,0},{1,2,0,2,1,2},{1,2,0,1,0,1},{1,2,1,1,1,1},
 {2,1,2,1,0,2},{2,2,2,0,1,1},{2,2,2,0,1,2},{2,1,2,2,1,0},{1,0,2,0,2,1},{1,1,0,2,2,0}}};
 for(auto s:specs){
 Player p;p.cls=s[0];p.spec=s[1];p.heal=s[2]!=0;p.tank=s[3]!=0;
 for(uint8 row=0;row<6;++row){
 uint8 col=GetManagedTalentProfileColumn(&p,row,BotFactory::ManagedLoadoutMode::Pve);
 check(col<3,"valid talent column");int found=0;
 for(uint32 i=0;i<talents.count;++i)if(talents.field(i,8)==p.cls&&talents.field(i,2)==row&&talents.field(i,3)==col){
 ++found;check(spellIds.count(talents.field(i,4))!=0,"talent spell exists in 5.4.8");}
 check(found==1,"one class talent for each selected row");
 check(GetManagedTalentProfileColumn(&p,row,BotFactory::ManagedLoadoutMode::Pvp)==oldPvp[p.cls-1][row],"PvP columns unchanged");
 }
 auto g=GetManagedPveMajorGlyphSpells(&p);
 auto dispel=GetPveDispelSpell(&p);
 check(!dispel.id || spellIds.count(dispel.id)!=0,"dispel spell exists in 5.4.8");
 if (p.cls==CLASS_PALADIN || p.cls==CLASS_SHAMAN || p.cls==CLASS_MONK || p.cls==CLASS_DRUID)
     check(bool(dispel.types & (1u<<DISPEL_MAGIC))==p.heal,"friendly magic dispel requires healer specialization");
 if (p.cls==CLASS_SHAMAN)check(!(dispel.types & ((1u<<DISPEL_POISON)|(1u<<DISPEL_DISEASE))),"MoP shaman cannot cure poison/disease");
 check(std::set<uint32>(g.begin(),g.end()).size()==3,"three distinct major glyph effects");
 for(auto id:g) {if(!major.count(id))std::cerr<<"Missing major spell "<<id<<" spec "<<p.spec<<"\n";check(major.count(id)!=0,"major glyph exists in 5.4.8");}
 }
 Player p;Unit enemy;p.combo=&enemy;p.spells={1822,2912,5176,5221,1079,22568,52610,11129,403,119582,13877,49222};
 PlayerbotAI ai{&p,&enemy};
 auto active=[&](uint32 id,PveSpellStateTrigger::State state,uint32 aura=0){PveSpellStateTrigger t(&ai,id,state,aura);return t.IsActive();};
 using S=PveSpellStateTrigger;
 check(active(1822,S::MissingDot),"missing own DoT applies");
 enemy.auras[1822]={10000,1};check(!active(1822,S::MissingDot),"long own DoT not spammed");
 enemy.auras[1822].duration=1000;check(active(1822,S::MissingDot),"expiring DoT refresh");
 ai.engage=false;check(!active(1822,S::MissingDot),"unpulled target rejected");ai.engage=true;
 ai.pve=false;check(!active(1822,S::MissingDot),"PvP gated");ai.pve=true;
 p.spells.erase(1822);check(!active(1822,S::MissingDot),"unlearned spell rejected");
 check(active(5176,S::SolarFiller),"initial Wrath toward lunar");
 p.auras[67483]={};check(active(2912,S::LunarFiller),"solar marker Starfire toward solar");
 check(!active(5176,S::SolarFiller),"do not cast wrong eclipse filler");p.auras.clear();
 p.points=0;check(active(5221,S::FeralBuild),"build at zero combo points");
 check(!active(1079,S::FeralRip),"no zero point rip");
 p.points=5;check(active(1079,S::FeralRip),"five point missing rip");
 check(!active(5221,S::FeralBuild),"do not waste capped combo points");
 enemy.auras[1079]={10000,1};p.auras[52610]={};
 check(!active(1079,S::FeralRip),"do not overwrite long rip");
 check(active(22568,S::FeralBite,1079),"bite with rip and roar");
 p.combo=nullptr;check(!active(22568,S::FeralBite,1079),"combo points belong to current target");p.combo=&enemy;
 p.auras.clear();check(active(52610,S::FeralRoar),"restore own roar");
 p.auras[53817]={10000,4};check(!active(403,S::Maelstrom),"no hardcast at four Maelstrom");
 p.auras[53817].stacks=5;check(active(403,S::Maelstrom),"instant Maelstrom at five");
 check(!active(119582,S::Stagger),"do not purify without stagger");p.auras[124274]={};
 check(active(119582,S::Stagger),"purify moderate stagger before low health");
 ai.pack=true;check(active(13877,S::CombatCleave),"enable combat cleave for gathered pack");
 p.auras[13877]={};check(!active(13877,S::CombatCleave),"do not recast cleave");
 ai.pack=false;check(!active(13877,S::CombatCleave)&&!p.HasAura(13877),"disable cleave for single target");
 enemy.auras[12654]={};enemy.auras[11366]={};
 check(active(11129,S::Combustion),"combustion with ignite and pyro");
 enemy.auras.erase(12654);check(!active(11129,S::Combustion),"no combustion without ignite");
 std::cout<<"PASS "<<tests<<" checks; 34 specializations, PvP profiles, MoP DBC glyphs/talents, PvE spell-state guards\n";
}
