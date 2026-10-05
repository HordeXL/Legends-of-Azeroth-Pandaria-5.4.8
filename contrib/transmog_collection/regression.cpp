#include <algorithm>
#include <cassert>
#include <cstdarg>
#include <cstdio>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>
using ObjectGuid = void*;
using uint32 = unsigned;
using uint8 = unsigned char;
using int64 = long long;
enum { ITEM_CLASS_ARMOR, ITEM_CLASS_WEAPON, ITEM_CLASS_OTHER };
enum { INVTYPE_NON_EQUIP, INVTYPE_BAG, INVTYPE_FINGER, INVTYPE_TRINKET,
       INVTYPE_AMMO, INVTYPE_QUIVER, INVTYPE_RELIC, INVTYPE_CHEST };
enum { UNIT_NPC_FLAG_GOSSIP=1, PLAYER_FIELD_VISIBLE_ITEMS=1000 };
enum { EQUIPMENT_SLOT_END=19, INVENTORY_SLOT_BAG_0=255, ITEM_CHANGED=1 };
enum { GOSSIP_ICON_MONEY_BAG, GOSSIP_ICON_CHAT, DEFAULT_GOSSIP_MESSAGE };
enum TransmogTrinityStrings { LANG_ERR_TRANSMOG_OK, LANG_ERR_TRANSMOG_INVALID_SLOT,
    LANG_ERR_TRANSMOG_MISSING_SRC_ITEM, LANG_ERR_TRANSMOG_MISSING_DEST_ITEM,
    LANG_ERR_TRANSMOG_INVALID_ITEMS, LANG_ERR_TRANSMOG_NOT_ENOUGH_MONEY,
    LANG_ERR_TRANSMOG_NOT_ENOUGH_TOKENS };
struct ItemTemplate { uint32 DisplayInfoID=1, Class=ITEM_CLASS_ARMOR, InventoryType=INVTYPE_CHEST; };
struct ObjectMgr {
    std::map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 id) {
        auto it=items.find(id);return it==items.end()?nullptr:&it->second;
    }
} objectMgr;
auto sObjectMgr=&objectMgr;
struct Field { uint32 value; uint32 GetUInt32() const { return value; } };
struct Result {
    std::vector<Field> rows; size_t index=0;
    Field const& operator[](unsigned) const { return rows[index]; }
    bool NextRow() { return ++index < rows.size(); }
};
using QueryResult=std::shared_ptr<Result>;
struct Transaction {
    std::vector<std::pair<uint32,uint32>> inserts;
    void PAppend(char const*, uint32 account, uint32 entry) { inserts.emplace_back(account,entry); }
};
using CharacterDatabaseTransaction=std::shared_ptr<Transaction>;
struct Database {
    std::map<uint32,std::set<uint32>> saved, owned;
    unsigned writes=0;
    QueryResult PQuery(char const* sql, uint32 account, ...) {
        auto const& values=std::string(sql).find("SELECT itemEntry FROM account_")==0?saved[account]:owned[account];
        if(values.empty())return {};
        auto result=std::make_shared<Result>();
        for(uint32 v:values)result->rows.push_back({v});
        return result;
    }
    void PExecute(char const*,uint32 account,uint32 entry) { saved[account].insert(entry);++writes; }
    CharacterDatabaseTransaction BeginTransaction(){return std::make_shared<Transaction>();}
    void CommitTransaction(CharacterDatabaseTransaction t){for(auto p:t->inserts)PExecute("",p.first,p.second);}
} CharacterDatabase;
struct Session { std::vector<std::string> messages; uint32 account=1; bool bot=false; std::string address="127.0.0.1"; std::string const& GetRemoteAddress(){return address;} bool IsBot(){return bot;} uint32 GetAccountId(){return account;} };
struct ChatHandler {
    Session* session;
    explicit ChatHandler(Session* s):session(s){}
    void SendSysMessage(char const* text){session->messages.emplace_back(text);}
};
struct Player;
using WorldSession=Session;
struct Creature { ObjectGuid GetGUID(){return this;} };
struct Item {
    ItemTemplate proto; uint32 appearance=0; bool bound=false, refundable=true, tradeable=true, changed=false;
    ObjectGuid GetGUID(){return this;}
    uint32 baseEntry=100;
    uint32 GetEntry(){return baseEntry;}
    uint32 GetVisibleEntry(){return appearance ? appearance : baseEntry;}
    ItemTemplate const* GetTemplate(){return &proto;}
    void SetBinding(bool b){bound=b;}
    void UpdatePlayedTime(Player*){}
    void SetNotRefundable(Player*){refundable=false;}
    void ClearSoulboundTradeable(Player*){tradeable=false;}
    void SetState(unsigned,Player*){changed=true;}
};
struct Player {
    struct Option {std::string label;uint32 sender,action;};
    std::vector<Option> menu;
    bool world=true;
    bool IsInWorld(){return world;}
    Session session; Item* equipped=nullptr; int64 money=1000; uint32 tokens=10;
    bool alive=true, combat=false, nearby=true;
    Creature* npc=nullptr;
    std::map<uint8,Item*> slots;
    std::map<uint32,uint32> visible;
    ObjectGuid GetGUID(){return this;}
    bool IsAlive(){return alive;}
    bool IsInCombat(){return combat;}
    Creature* GetNPCIfCanInteractWith(ObjectGuid guid,uint32){return nearby && npc && npc->GetGUID()==guid ? npc : nullptr;}
    uint32 GetUInt32Value(uint32 field){return visible[field];}
    void SetUInt32Value(uint32 field,uint32 value){visible[field]=value;}
    void SetVisibleItemSlot(uint8 slot,Item* item){visible[PLAYER_FIELD_VISIBLE_ITEMS+slot*2]=item?item->GetVisibleEntry():0;}
    Session* GetSession(){return &session;}
    Item* GetItemByPos(uint8,uint8 slot){return slots.empty()?equipped:slots[slot];}
    bool HasEnoughMoney(int64 cost){return money>=cost;}
    bool HasItemCount(uint32,uint32 count){return tokens>=count;}
    void DestroyItemCount(uint32,uint32 count,bool){tokens-=count;}
    void ModifyMoney(int64 value){money+=value;}
    void ADD_GOSSIP_ITEM(unsigned,std::string label,uint32 sender,uint32 action){menu.push_back({label,sender,action});}
    void ADD_GOSSIP_ITEM_EXTENDED(unsigned icon,std::string label,uint32 sender,uint32 action,std::string,uint32,bool)
    {ADD_GOSSIP_ITEM(icon,label,sender,action);}
    void SEND_GOSSIP_MENU(unsigned,ObjectGuid){}
};
class Transmogrification {
    std::mutex collectionMutex;
    std::unordered_map<uint32,std::set<uint32>> collections;
    void LoadCollection(uint32);
    struct PreviewItem
    {
        ObjectGuid item;
        uint32 originalEntry;
        uint32 entry;
    };
    struct PreviewSession
    {
        ObjectGuid npc;
        uint32 remaining = 300000;
        std::map<uint8, PreviewItem> items;
    };
    std::mutex previewMutex;
    std::unordered_map<ObjectGuid, PreviewSession> previews;

public:
    bool RequireToken=false, compatible=true;
    uint32 TokenEntry=1, TokenAmount=3;
    float ScaledCostModifier=1; int64 CopperCost=0;
    void LearnAppearance(Player*,uint32,bool notify=true);
    std::vector<uint32> GetCollection(Player*);
    bool HasAppearance(Player*,uint32);
    TransmogTrinityStrings TransmogrifyAppearance(Player*,uint32,uint8);
    TransmogTrinityStrings PreviewAppearance(Player*,Creature*,uint32,uint8);
    TransmogTrinityStrings AcceptPreview(Player*,Creature*);
    void CancelPreview(Player*);
    void UpdatePreview(Player*,uint32);
    uint32 GetPreviewEntry(Player*,uint8);
    bool HasPreview(Player*);
    uint32 GetVisibleEntryForSave(Player*,uint8);
    void DeleteFakeEntry(Player* p,uint8 slot,Item* item){item->appearance=0;p->SetVisibleItemSlot(slot,item);}
    bool CanTransmogrifyItemWithItem(Player*,ItemTemplate const*,ItemTemplate const* source,bool){return source&&compatible;}
    uint32 GetSpecialPrice(ItemTemplate const*){return 100;}
    void SetFakeEntry(Player* p,uint32 entry,uint8 slot,Item* target){target->appearance=entry;p->SetVisibleItemSlot(slot,target);}
    float GetScaledCostModifier(){return ScaledCostModifier;}
    int64 GetCopperCost(){return CopperCost;}
    bool GetRequireToken(){return RequireToken;}
    uint32 GetTokenAmount(){return TokenAmount;}
    uint32 GetTokenEntry(){return TokenEntry;}
    std::string GetItemLink(uint32 entry,Session*){return std::to_string(entry);}
    std::string GetItemIcon(uint32,unsigned,unsigned,int,int){return "";}
    uint32 GetFakeEntry(ObjectGuid item){return static_cast<Item*>(item)->appearance;}
    const char* GetSlotName(uint8,Session*){return "Head";}
};
#include "collection-under-test.inc"
Transmogrification* sT;
#include "menu-under-test.inc"
int main() {
    objectMgr.items[100]={};objectMgr.items[200]={};objectMgr.items[300]={};
    objectMgr.items[400]={1,ITEM_CLASS_OTHER,INVTYPE_NON_EQUIP};
    objectMgr.items[500]={1,ITEM_CLASS_ARMOR,INVTYPE_FINGER};
    Player main,alt,stranger;alt.session.account=1;stranger.session.account=2;
    CharacterDatabase.owned[1]={100,400,500,999};
    {
        Transmogrification wardrobe;
        assert(wardrobe.GetCollection(&main)==std::vector<uint32>{100});
        assert(wardrobe.HasAppearance(&alt,100));
        assert(!wardrobe.HasAppearance(&stranger,100));
        wardrobe.LearnAppearance(&main,200);
        unsigned writes=CharacterDatabase.writes;
        wardrobe.LearnAppearance(&main,200);
        assert(CharacterDatabase.writes==writes);
        assert(wardrobe.HasAppearance(&alt,200));
        main.session.bot=true;wardrobe.LearnAppearance(&main,300);main.session.bot=false;
        assert(!wardrobe.HasAppearance(&main,300));
    }
    // Simulate every source item being sold and the worldserver restarting.
    CharacterDatabase.owned.clear();
    Transmogrification restarted;
    assert(restarted.GetCollection(&alt)==(std::vector<uint32>{100,200}));
    assert(!restarted.HasAppearance(&stranger,200));
    Item target;alt.equipped=&target;stranger.equipped=&target;
    auto before=alt.money;
    assert(restarted.TransmogrifyAppearance(&alt,300,0)==LANG_ERR_TRANSMOG_MISSING_SRC_ITEM);
    assert(alt.money==before && !target.appearance);
    assert(restarted.TransmogrifyAppearance(&stranger,100,0)==LANG_ERR_TRANSMOG_MISSING_SRC_ITEM);
    assert(restarted.TransmogrifyAppearance(&alt,100,19)==LANG_ERR_TRANSMOG_INVALID_SLOT);
    alt.equipped=nullptr;
    assert(restarted.TransmogrifyAppearance(&alt,100,0)==LANG_ERR_TRANSMOG_MISSING_DEST_ITEM);
    alt.equipped=&target;restarted.compatible=false;
    assert(restarted.TransmogrifyAppearance(&alt,100,0)==LANG_ERR_TRANSMOG_INVALID_ITEMS);
    restarted.compatible=true;restarted.RequireToken=true;alt.money=99;
    assert(restarted.TransmogrifyAppearance(&alt,100,0)==LANG_ERR_TRANSMOG_NOT_ENOUGH_MONEY);
    assert(alt.tokens==10 && !target.appearance);
    alt.money=1000;alt.tokens=2;
    assert(restarted.TransmogrifyAppearance(&alt,100,0)==LANG_ERR_TRANSMOG_NOT_ENOUGH_TOKENS);
    assert(alt.money==1000 && !target.appearance);
    alt.tokens=10;
    assert(restarted.TransmogrifyAppearance(&alt,100,0)==LANG_ERR_TRANSMOG_OK);
    assert(target.appearance==100 && target.bound && target.changed && !target.refundable && !target.tradeable);
    assert(alt.money==900 && alt.tokens==7);
    restarted.ScaledCostModifier=0;
    restarted.CopperCost=0;
    restarted.RequireToken=false;
    alt.money=0;alt.tokens=0;
    assert(restarted.TransmogrifyAppearance(&alt,200,0)==LANG_ERR_TRANSMOG_OK);
    assert(target.appearance==200 && alt.money==0 && alt.tokens==0);
    assert(restarted.HasAppearance(&alt,100));
    main.session.address.clear();restarted.LearnAppearance(&main,300);
    main.session.address="127.0.0.1";
    assert(!restarted.HasAppearance(&main,300)); // socketless bot with an incorrect IsBot flag
    Player collector;collector.session.account=3;collector.equipped=&target;
    for(uint32 entry=600;entry<666;++entry)
    {
        objectMgr.items[entry]={entry,ITEM_CLASS_ARMOR,INVTYPE_CHEST};
        CharacterDatabase.owned[3].insert(entry);
    }
    objectMgr.items[665].DisplayInfoID=600; // duplicate visual should not consume another slot
    sT=&restarted;Creature npc;Menu menu;
    std::set<uint32> shown;
    for(uint32 page=0;page<4;++page)
    {
        collector.menu.clear();menu.ShowTransmogItems(&collector,&npc,0,page);
        assert(collector.menu.size()<=25);
        for(auto const& option:collector.menu)
            if(option.sender==0)assert(shown.insert(option.action).second);
    }
    assert(shown.size()==65 && !shown.count(665));
    collector.menu.clear();menu.ShowTransmogItems(&collector,&npc,0,~uint32(0));
    assert(collector.menu.front().label.find("Page 4/4")!=std::string::npos);
    assert(collector.menu[1].action==654); // out-of-range page clamps safely to last
    collector.menu.clear();menu.ShowTransmogItems(&collector,&npc,0,0,643);
    assert(collector.menu.front().label.find("Page 3/4")!=std::string::npos);
    target.appearance=643;
    collector.menu.clear();menu.ShowTransmogItems(&collector,&npc,0,0,643);
    auto active=std::find_if(collector.menu.begin(),collector.menu.end(),[](auto const& option){
        return option.label.find("[Current]")!=std::string::npos;
    });
    assert(active!=collector.menu.end() && active->sender==0 && active->action==643);
    assert(collector.menu.size()<=25);
    // Deduplicated visual still shows as active when another source item was applied.
    target.appearance=665;
    collector.menu.clear();menu.ShowTransmogItems(&collector,&npc,0,0);
    assert(collector.menu[1].label.find("[Current]")!=std::string::npos);
    collector.menu.clear();menu.ShowTransmogItems(&collector,&npc,19,0);
    assert(collector.menu.empty());
    collector.equipped=nullptr;menu.ShowTransmogItems(&collector,&npc,0,0);
    assert(collector.menu[1].label=="Equip an item in this slot to choose an appearance.");
    Player looter;looter.session.account=4;
    for(uint32 entry=700;entry<=704;++entry)objectMgr.items[entry]={entry,ITEM_CLASS_ARMOR,INVTYPE_CHEST};
    objectMgr.items[701].DisplayInfoID=700;
    restarted.LearnAppearance(&looter,700);
    assert(looter.session.messages==std::vector<std::string>{"700 has been added to your appearance collection."});
    restarted.LearnAppearance(&looter,700);
    restarted.LearnAppearance(&looter,701); // same appearance on another item
    restarted.LearnAppearance(&looter,702,false); // silent inventory import
    looter.world=false;restarted.LearnAppearance(&looter,703);looter.world=true;
    restarted.LearnAppearance(&looter,400); // nonvisual item
    assert(looter.session.messages.size()==1);
    assert(restarted.HasAppearance(&looter,701) && restarted.HasAppearance(&looter,702));
    Player sameAccount;sameAccount.session.account=4;
    restarted.LearnAppearance(&sameAccount,700);
    assert(sameAccount.session.messages.empty());
    restarted.LearnAppearance(&sameAccount,704);
    assert(sameAccount.session.messages.size()==1 && looter.session.messages.size()==1);
    Transmogrification afterRelog;
    afterRelog.LearnAppearance(&sameAccount,704);
    assert(sameAccount.session.messages.size()==1);
    // Actual server preview methods: multiple slots, no mutation before Accept.
    Player fitting;fitting.session.account=3;fitting.npc=&npc;
    Item head,shoulders;head.appearance=603;shoulders.baseEntry=200;
    fitting.slots={{0,&head},{2,&shoulders}};
    restarted.ScaledCostModifier=0;restarted.CopperCost=0;restarted.RequireToken=false;
    auto money=fitting.money;auto tokens=fitting.tokens;
    auto writes=CharacterDatabase.writes;
    assert(restarted.PreviewAppearance(&fitting,&npc,600,0)==LANG_ERR_TRANSMOG_OK);
    assert(restarted.PreviewAppearance(&fitting,&npc,601,2)==LANG_ERR_TRANSMOG_OK);
    assert(head.appearance==603 && shoulders.appearance==0);
    assert(!head.bound && !shoulders.bound && head.refundable && shoulders.tradeable);
    assert(fitting.visible[1000]==600 && fitting.visible[1004]==601);
    assert(restarted.GetVisibleEntryForSave(&fitting,0)==603);
    assert(restarted.GetVisibleEntryForSave(&fitting,2)==200);
    assert(fitting.money==money && fitting.tokens==tokens && CharacterDatabase.writes==writes);
    assert(restarted.GetPreviewEntry(&fitting,0)==600 && restarted.GetPreviewEntry(&fitting,2)==601);
    // Worst case: middle page with restore, Accept, Cancel and both page links.
    fitting.menu.clear();menu.ShowTransmogItems(&fitting,&npc,0,1);
    assert(fitting.menu.size()==25);
    restarted.CancelPreview(&fitting);
    assert(!restarted.HasPreview(&fitting) && fitting.visible[1000]==603 && fitting.visible[1004]==200);
    assert(restarted.PreviewAppearance(&fitting,&npc,600,0)==LANG_ERR_TRANSMOG_OK);
    assert(restarted.PreviewAppearance(&fitting,&npc,601,2)==LANG_ERR_TRANSMOG_OK);
    assert(restarted.AcceptPreview(&fitting,&npc)==LANG_ERR_TRANSMOG_OK);
    assert(head.appearance==600 && shoulders.appearance==601 && head.bound && shoulders.bound);
    assert(!head.refundable && !shoulders.tradeable && !restarted.HasPreview(&fitting));
    assert(fitting.money==money && fitting.tokens==tokens);
    // Restoring the original is also only committed on Accept.
    restarted.PreviewAppearance(&fitting,&npc,head.baseEntry,0);
    assert(head.appearance==600 && fitting.visible[1000]==100);
    restarted.CancelPreview(&fitting);assert(fitting.visible[1000]==600);
    restarted.PreviewAppearance(&fitting,&npc,head.baseEntry,0);
    assert(restarted.AcceptPreview(&fitting,&npc)==LANG_ERR_TRANSMOG_OK && head.appearance==0);
    // Selecting the saved appearance removes only that slot from the preview.
    restarted.PreviewAppearance(&fitting,&npc,602,0);
    restarted.PreviewAppearance(&fitting,&npc,603,2);
    restarted.PreviewAppearance(&fitting,&npc,head.baseEntry,0);
    assert(restarted.GetPreviewEntry(&fitting,0)==0 && restarted.GetPreviewEntry(&fitting,2)==603);
    restarted.CancelPreview(&fitting);
    // An equipment swap invalidates the entire pending outfit, never half applies.
    restarted.PreviewAppearance(&fitting,&npc,602,0);
    restarted.PreviewAppearance(&fitting,&npc,603,2);
    Item replacement;replacement.baseEntry=300;fitting.slots[2]=&replacement;
    assert(restarted.AcceptPreview(&fitting,&npc)!=LANG_ERR_TRANSMOG_OK);
    assert(head.appearance==0 && replacement.appearance==0 && fitting.visible[1004]==300);
    fitting.slots[2]=&shoulders;
    // Ownership/compatibility and interaction checks reject invalid requests.
    assert(restarted.PreviewAppearance(&fitting,&npc,999999,0)!=LANG_ERR_TRANSMOG_OK);
    assert(restarted.PreviewAppearance(&fitting,&npc,602,19)!=LANG_ERR_TRANSMOG_OK);
    restarted.compatible=false;
    assert(restarted.PreviewAppearance(&fitting,&npc,602,0)!=LANG_ERR_TRANSMOG_OK);
    restarted.compatible=true;
    for (int reason=0;reason<4;++reason) {
        assert(restarted.PreviewAppearance(&fitting,&npc,602,0)==LANG_ERR_TRANSMOG_OK);
        fitting.nearby=reason!=0;fitting.combat=reason==1;fitting.alive=reason!=2;
        restarted.UpdatePreview(&fitting,reason==3?300000:1);
        assert(!restarted.HasPreview(&fitting) && fitting.visible[1000]==head.GetVisibleEntry());
        fitting.nearby=true;fitting.combat=false;fitting.alive=true;
    }
    // Revalidation happens before any slot is applied.
    restarted.PreviewAppearance(&fitting,&npc,602,0);
    restarted.PreviewAppearance(&fitting,&npc,603,2);
    restarted.compatible=false;
    assert(restarted.AcceptPreview(&fitting,&npc)!=LANG_ERR_TRANSMOG_OK);
    assert(head.appearance==0 && shoulders.appearance==601 && !restarted.HasPreview(&fitting));
    restarted.compatible=true;
    std::cout<<"Collection, multi-slot preview, Accept/Cancel, autosave and pagination checks passed\n";
}
