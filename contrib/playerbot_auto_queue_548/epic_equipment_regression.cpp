#include "modules/mod_playerbots/src/Factory/ManagedPveEquipmentPolicy.h"
#include <cassert>
#include <cstdint>
#include <map>
#include <string>
#include <vector>
using uint8=uint8_t; using uint16=uint16_t; using uint32=uint32_t;
enum EquipmentSlots { EQUIPMENT_SLOT_START=0,EQUIPMENT_SLOT_HEAD=0,EQUIPMENT_SLOT_BODY=3,EQUIPMENT_SLOT_MAINHAND=15,EQUIPMENT_SLOT_OFFHAND=16,EQUIPMENT_SLOT_RANGED=17,EQUIPMENT_SLOT_TABARD=18,EQUIPMENT_SLOT_END=19 };
enum { ITEM_QUALITY_NORMAL=1,ITEM_QUALITY_EPIC=4,BIND_QUEST=4,EQUIP_ERR_OK=0,INVENTORY_SLOT_BAG_0=255,INVENTORY_SLOT_BAG_START=19,INVENTORY_SLOT_BAG_END=23,INVENTORY_SLOT_ITEM_START=23,INVENTORY_SLOT_ITEM_END=39 };
template<class... Args> void IgnoreLog(Args const&...) {}
#define TC_LOG_INFO(...) IgnoreLog(__VA_ARGS__)
struct ItemTemplate { uint32 ItemId,Quality,ItemLevel,RequiredLevel; uint32 Duration=0,Bonding=0,AllowableClass=1,AllowableRace=1; bool custom=false,test=false,pvp=false,valid=true,usable=true; };
using ItemTemplateContainer=std::map<uint32,ItemTemplate>;
struct Item { ItemTemplate const* proto; uint16 pos; ItemTemplate const* GetTemplate(){return proto;} uint32 GetEntry(){return proto->ItemId;} uint16 GetPos(){return pos;} };
struct Bag { uint32 GetBagSize(){return 0;} Item* GetItemByPos(uint32){return nullptr;} };
struct ObjectMgr { ItemTemplateContainer templates; ItemTemplateContainer const* GetItemTemplateStore(){return &templates;} } objects;
auto sObjectMgr=&objects;
struct RandomMgr { bool NeedsOffhandForSpec(void*){return false;} bool IsCustomServerItem(uint32 id){return objects.templates.at(id).custom;} bool IsTestItem(uint32 id){return objects.templates.at(id).test;} bool IsItemValidForEquipmentSlot(void*,EquipmentSlots slot,ItemTemplate const* p){return slot==EQUIPMENT_SLOT_HEAD && p->valid;} } randomMgr;
auto sRandomItemMgr=&randomMgr;
bool IsManagedPvpItem(ItemTemplate const* p){return p->pvp;}
struct Player {
 std::map<uint16,Item*> inventory; bool full=false,failEquip=false; unsigned generated=0;
 uint32 GetClassMask(){return 1;} uint32 GetRaceMask(){return 1;}
 Item* GetItemByPos(uint8,uint8 pos){return inventory[pos];} Bag* GetBagByPos(uint8){return nullptr;}
 uint32 GetItemLevel(Item* p){return p->proto->ItemLevel;}
 int CanEquipItem(uint8 slot,uint16& dest,Item* p,bool){dest=slot;return p->proto->usable?0:1;}
 void SwapItem(uint16 from,uint16 to){std::swap(inventory[from],inventory[to]);if(inventory[from])inventory[from]->pos=from;if(inventory[to])inventory[to]->pos=to;}
 Item* EquipNewItem(uint16 dest,uint32 id,bool){if(failEquip)return nullptr;++generated;auto p=new Item{&objects.templates.at(id),dest};inventory[dest]=p;return p;}
 void AutoUnequipOffhandIfNeed(){} std::string GetName(){return "Level67";}
};
struct BotFactory {
 Player* bot; uint32 level=67;
 bool CanEquipItem(ItemTemplate const*){return true;}
 bool CanEquipUnseenItem(uint8 slot,uint16& dest,uint32 id){dest=slot;return objects.templates.at(id).usable;}
 bool MoveEquippedItemToBag(uint8 slot){if(bot->full)return false;for(uint16 p=23;p<39;++p)if(!bot->inventory[p]){bot->SwapItem(slot,p);return true;}return false;}
 void UpgradePveEquipment();
};
// PRODUCTION
ItemTemplate& add(uint32 id,uint32 q,uint32 ilvl,uint32 req) { ItemTemplate p; p.ItemId=id;p.Quality=q;p.ItemLevel=ilvl;p.RequiredLevel=req;return objects.templates.emplace(id,p).first->second; }
int main(){
 add(1,2,52,40); add(2,4,90,60); add(3,4,95,67);
 add(4,4,120,70); add(5,4,600,1); add(6,4,120,67).valid=false;
 add(7,4,120,67).custom=true; add(8,4,120,67).pvp=true;
 add(9,4,120,67).Duration=10; add(10,4,120,67).usable=false;
 add(11,4,120,67).test=true; add(12,4,120,67).AllowableClass=2;
 add(13,4,120,67).AllowableRace=2; add(14,4,120,67).Bonding=BIND_QUEST;
 add(15,5,120,67); add(16,3,106,67);
 Player p; Item green{&objects.templates.at(1),0};p.inventory[0]=&green;BotFactory f{&p};
 f.UpgradePveEquipment();assert(p.inventory[0]->GetEntry()==3);assert(p.inventory[23]==&green);
 unsigned count=p.generated;f.UpgradePveEquipment();assert(p.generated==count);
 // Missing epic candidates use strongest legal rare, not old green.
 objects.templates.at(2).valid=false;objects.templates.at(3).valid=false;
 Player fallback;Item g2{&objects.templates.at(1),0};fallback.inventory[0]=&g2;BotFactory ff{&fallback};ff.UpgradePveEquipment();assert(fallback.inventory[0]->GetEntry()==16);
 objects.templates.at(2).valid=true;objects.templates.at(3).valid=true;
 // Reuse carried gear without generating a duplicate.
 Player reuse;Item g3{&objects.templates.at(1),0},epic{&objects.templates.at(3),23};reuse.inventory[0]=&g3;reuse.inventory[23]=&epic;BotFactory fr{&reuse};fr.UpgradePveEquipment();assert(reuse.inventory[0]==&epic && reuse.generated==0);
 // Failed upgrades retain the existing working item.
 Player full;Item g4{&objects.templates.at(1),0};full.inventory[0]=&g4;full.full=true;BotFactory fb{&full};fb.UpgradePveEquipment();assert(full.inventory[0]==&g4);
 full.full=false;full.failEquip=true;fb.UpgradePveEquipment();assert(full.inventory[0]==&g4);
}
