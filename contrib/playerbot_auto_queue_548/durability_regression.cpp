#include <cassert>
#include <cstdint>
using int32=int32_t;
enum { ITEM_FIELD_MAX_DURABILITY, ITEM_FIELD_DURABILITY, ITEM_CHANGED };
struct Session { bool bot=false; bool IsBot(){return bot;} };
struct Map { bool challenge=false; bool IsChallengeDungeon(){return challenge;} };
struct Item {
 int32 durability=100,max=100;bool equipped=true;
 int32 GetUInt32Value(int field){return field==ITEM_FIELD_MAX_DURABILITY?max:durability;}
 void SetUInt32Value(int,int32 v){durability=v;}
 bool IsEquipped(){return equipped;}int GetSlot(){return 0;}void SetState(int,void*){}
};
struct Player {
 Session session; Map map; int applied=0,removed=0;
 Session* GetSession(){return &session;} Map* GetMap(){return &map;}
 void _ApplyItemMods(Item*,int,bool apply){apply?++applied:++removed;}
 void DurabilityPointsLoss(Item*,int32);
};
// PRODUCTION
int main(){
 Player bot;bot.session.bot=true;Item gear;
 bot.DurabilityPointsLoss(&gear,1);assert(gear.durability==100);
 bot.DurabilityPointsLoss(&gear,10);assert(gear.durability==100);
 gear.durability=0;bot.DurabilityPointsLoss(&gear,1);
 assert(gear.durability==100 && bot.applied==1 && bot.removed==0);
 bot.DurabilityPointsLoss(&gear,1);assert(bot.applied==1);
 Player human;human.DurabilityPointsLoss(&gear,10);assert(gear.durability==90);
 human.DurabilityPointsLoss(&gear,100);assert(gear.durability==0 && human.removed==1);
 human.DurabilityPointsLoss(&gear,-10);assert(gear.durability==10 && human.applied==1);
 human.map.challenge=true;human.DurabilityPointsLoss(&gear,10);assert(gear.durability==10);
}
