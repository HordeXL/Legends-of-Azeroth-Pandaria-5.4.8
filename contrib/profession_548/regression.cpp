#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <vector>
using uint8=uint8_t; using uint16=uint16_t; using uint32=uint32_t; using int32=int32_t;
enum { EFFECT_0=0, EFFECT_1=1, EFFECT_3=3, INVENTORY_SLOT_BAG_END=20,
    MAX_ENCHANTMENT_SLOT=13, MAX_ITEM_ENCHANTMENT_EFFECTS=3, ITEM_ENCHANTMENT_TYPE_USE_SPELL=7 };
enum EnchantmentSlot { PERM_ENCHANTMENT_SLOT=0, SOCK_ENCHANTMENT_SLOT=2,
    SOCK_ENCHANTMENT_SLOT_2=3, SOCK_ENCHANTMENT_SLOT_3=4, PRISMATIC_ENCHANTMENT_SLOT=6,
    ENGINEERING_ENCHANTMENT_SLOT=7, PROP_ENCHANTMENT_SLOT_0=8 };
struct SpellItemEnchantmentEntry { uint32 ID=0,RequiredSkill=0,RequiredSkillValue=0,RequiredLevel=0,GemID=0; uint32 Type[3]{},SpellID[3]{}; };
struct ItemTemplate { uint32 RequiredSkill=0,RequiredSkillRank=0; struct {uint32 Color=1;} Socket[3]; };
template<class T> struct Store { std::map<uint32,T> rows; T const* LookupEntry(uint32 id) {auto p=rows.find(id);return p==rows.end()?nullptr:&p->second;} };
Store<SpellItemEnchantmentEntry> sSpellItemEnchantmentStore;
struct ObjectMgr { std::map<uint32,ItemTemplate> rows; ItemTemplate const* GetItemTemplate(uint32 id) {auto p=rows.find(id);return p==rows.end()?nullptr:&p->second;} } objects;
ObjectMgr* sObjectMgr=&objects;
struct Item { uint32 ench[MAX_ENCHANTMENT_SLOT]{}; ItemTemplate proto; bool equipped=true;
    uint32 GetEnchantmentId(EnchantmentSlot s) {return ench[s];} ItemTemplate const* GetTemplate(){return &proto;} };
struct Player { Item* m_items[INVENTORY_SLOT_BAG_END]{}; std::map<uint32,int32> skills,bonus;
    std::vector<std::pair<EnchantmentSlot,bool>> changes; uint32 level=90;
    uint32 GetSkillValue(uint32 s){return skills[s]?skills[s]+bonus[s]:0;}
    int32 GetSkillPermBonusValue(uint32 s){return bonus[s];} int32 GetSkillTempBonusValue(uint32){return 0;}
    uint32 GetLevel(){return level;}
    void ApplyEnchantment(Item* i,EnchantmentSlot s,bool a){if(i->equipped)changes.emplace_back(s,a);}
    void UpdateSkillEnchantments(uint16,uint16,uint16);
    void TestUse(Item* item);
};
struct SpellInfo { uint32 Id; struct {uint32 TriggerSpell=0;} Effects[3]; };
struct SpellMgr { std::map<uint32,SpellInfo> rows; SpellInfo const* GetSpellInfo(uint32 id){auto p=rows.find(id);return p==rows.end()?nullptr:&p->second;} } spells;
SpellMgr* sSpellMgr=&spells;
enum {TRIGGERED_NONE=0,TRIGGERED_FULL_MASK=1};
std::vector<uint32> used;
struct Spell { Item* m_CastItem; uint8 m_cast_count; uint32 m_glyphIndex; uint32 id;
    Spell(Player*,SpellInfo const* s,int):id(s->Id){} void prepare(int const*){used.push_back(id);delete this;} };
#define TC_LOG_ERROR(...) ((void)0)
#define TC_LOG_DEBUG(...) ((void)0)
// MIXOLOGY
// ENCHANT_UPDATE
void Player::TestUse(Item* item) { int count=0,targets=0; uint8 cast_count=0; uint32 glyphIndex=0;
// ENCHANT_USE
}
struct Unit { int32 bp0=0,bp1=-1; void CastCustomSpell(Unit*,uint32,int32* a,int32* b,void*,bool,void*,void*){bp0=*a;bp1=b?*b:-1;} };
struct AuraApplication {Unit* target;Unit* GetTarget(){return target;}};
struct ProcEventInfo {Unit* target;Unit* GetProcTarget(){return target;}};
struct AuraEffect { uint32 m_effIndex=0; SpellInfo info{}; int32 amount=4000;
    SpellInfo const* GetSpellInfo(){return &info;} int32 GetAmount(){return amount;} uint32 GetId(){return 125486;}
    void HandleProcTriggerSpellWithValueAuraProc(AuraApplication*,ProcEventInfo&);
};
// SWORDGUARD
int checks=0;
void Check(bool condition){++checks;if(!condition){std::cerr<<"Failed check "<<checks<<"\n";std::abort();}}
int main()
{
    for(uint32 id:{105689u,105691u,105696u}) Check(CalculateMixologyAmount(id,0,1000)==1320);
    Check(CalculateMixologyAmount(105693,0,1000)==1480);
    Check(CalculateMixologyAmount(105694,0,1500)==1980);
    Check(CalculateMixologyAmount(105681,0,2250)==2730);
    for(uint32 id=105682;id<=105688;++id) Check(CalculateMixologyAmount(id,0,750)==990);
    Check(CalculateMixologyAmount(79469,0,450)==570);
    for(uint32 id:{79470u,79471u,79472u,94160u}) Check(CalculateMixologyAmount(id,0,300)==380);
    Check(CalculateMixologyAmount(105681,1,100)==100);
    Check(CalculateMixologyAmount(105681,3,100)==100);
    Check(CalculateMixologyAmount(999999,0,100)==100);
    Check(CalculateMixologyAmount(673,0,100)==150);
    spells.rows[125489]={125489}; spells.rows[125487]={125487};
    Unit unit; AuraApplication app{&unit}; ProcEventInfo event{&unit}; AuraEffect effect;
    effect.info.Effects[0].TriggerSpell=125489; effect.HandleProcTriggerSpellWithValueAuraProc(&app,event);
    Check(unit.bp0==4000 && unit.bp1==4000);
    effect.info.Effects[0].TriggerSpell=125487;effect.amount=2000;effect.HandleProcTriggerSpellWithValueAuraProc(&app,event);
    Check(unit.bp0==2000 && unit.bp1==-1);
    Player p; Item item; p.m_items[0]=&item; item.ench[2]=1;
    sSpellItemEnchantmentStore.rows[1].GemID=100;
    objects.rows[100].RequiredSkill=755;objects.rows[100].RequiredSkillRank=550;
    p.skills[755]=550;
    p.UpdateSkillEnchantments(755,550,0); Check(p.changes.size()==1 && !p.changes.back().second);
    p.changes.clear();p.UpdateSkillEnchantments(755,0,550);Check(p.changes.size()==1 && p.changes.back().second);
    p.changes.clear();p.UpdateSkillEnchantments(755,550,551);Check(p.changes.empty());
    // Cogwheel requirements can exist only on the gem's ItemTemplate.
    objects.rows[100].RequiredSkill=202;p.skills[202]=550;
    p.UpdateSkillEnchantments(202,550,0);Check(p.changes.size()==1 && !p.changes.back().second);
    p.changes.clear();objects.rows[100].RequiredSkill=755;
    sSpellItemEnchantmentStore.rows[1].RequiredSkill=755;sSpellItemEnchantmentStore.rows[1].RequiredSkillValue=550;
    p.UpdateSkillEnchantments(755,550,0);Check(p.changes.size()==1); // two requirements, one removal
    p.changes.clear();item.proto.Socket[0].Color=0;item.ench[6]=2;
    sSpellItemEnchantmentStore.rows[2].RequiredSkill=164;sSpellItemEnchantmentStore.rows[2].RequiredSkillValue=400;
    p.skills[164]=400;p.skills[755]=0;
    p.UpdateSkillEnchantments(164,400,0);Check(p.changes.size()==1 && p.changes[0].first==PRISMATIC_ENCHANTMENT_SLOT);
    p.changes.clear();p.skills[755]=550;
    p.UpdateSkillEnchantments(164,400,0);Check(p.changes.size()==2); // socket and its active gem
    p.changes.clear();p.skills[164]=0;
    p.UpdateSkillEnchantments(755,550,0);Check(p.changes.empty()); // gem was already inactive
    item.proto.Socket[0].Color=1;item.ench[6]=0;
    p.bonus[755]=15;p.UpdateSkillEnchantments(755,534,535);Check(p.changes.size()==1 && p.changes[0].second);
    p.changes.clear();p.UpdateSkillEnchantments(755,535,550);Check(p.changes.empty());
    // An unknown enchant on another item must not stop the entire scan.
    Item invalid;invalid.ench[0]=999999;p.m_items[0]=&invalid;p.m_items[1]=&item;
    p.UpdateSkillEnchantments(755,550,0);Check(p.changes.size()==1);
    p.changes.clear();item.equipped=false;p.UpdateSkillEnchantments(755,550,0);Check(p.changes.empty());
    Item gloves; gloves.ench[7]=3;auto& tinker=sSpellItemEnchantmentStore.rows[3];
    tinker.RequiredSkill=202;tinker.RequiredSkillValue=550;tinker.RequiredLevel=80;tinker.Type[0]=7;tinker.SpellID[0]=126734;spells.rows[126734]={126734};
    p.skills[202]=0;p.TestUse(&gloves);Check(used.empty());
    p.skills[202]=549;p.TestUse(&gloves);Check(used.empty());
    p.skills[202]=550;p.level=79;p.TestUse(&gloves);Check(used.empty());
    p.level=90;p.TestUse(&gloves);Check(used.size()==1 && used[0]==126734);
    used.clear();p.skills[202]=0;tinker.RequiredSkill=0;p.TestUse(&gloves);Check(used.size()==1);
    std::cout<<checks<<" profession regression checks passed\n";
}
