#include "ScriptMgr.h"
#include "Chat.h"
#include "ServiceMgr.h"

namespace BattlePay
{
    enum GoldAmount : int64
    {
        Gold_1K   = 10000000,
        Gold_5K   = 50000000,
        Gold_10K  = 100000000,
        Gold_30K  = 300000000,
        Gold_80K  = 800000000,
        Gold_150K = 1500000000
    };
}

class honor_1000 : public ItemScript
{
public:
    honor_1000() : ItemScript("battle_pay_currency_honor_1000") {}

    bool OnUse(Player *player, Item *item, const SpellCastTargets &) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground()) //Item is not usable in combat, arenas and battlegrounds. This can be modified to your taste.
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(392, 1000 * CURRENCY_PRECISION); // add 1000 honor points
            ChatHandler(player->GetSession()).SendSysMessage("\xe6\x84\x9f\xe8\xb0\xa2\xe4\xbd\xa0\xe5\xaf\xb9\x20\x57\x6f\x57\x20\xe9\xa1\xb9\xe7\x9b\xae\xe7\x9a\x84\xe6\x94\xaf\xe6\x8c\x81\xef\xbc\x8c\xe4\xbd\xa0\xe8\x8e\xb7\xe5\xbe\x97\xe4\xba\x86\x20\x31\x30\x30\x30\x20\xe7\x82\xb9\xe8\x8d\xa3\xe8\xaa\x89\xe7\x82\xb9\xe6\x95\xb0\xe3\x80\x82");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe4\xbd\xa0\xe6\xb2\xa1\xe6\x9c\x89\xe6\x89\x80\xe9\x9c\x80\xe7\x9a\x84\xe4\xbb\xa3\xe5\xb8\x81\xe3\x80\x82");
        }
        return true;
    }
};

class justice_1000 : public ItemScript
{
public:
    justice_1000() : ItemScript("battle_pay_currency_justice_1000") {}

    bool OnUse(Player *player, Item *item, const SpellCastTargets &) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground()) //Item is not usable in combat, arenas and battlegrounds. This can be modified to your taste.
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(CURRENCY_TYPE_JUSTICE_POINTS, 1000 * CURRENCY_PRECISION, true, true, true); // add 1000 justice points
            ChatHandler(player->GetSession()).SendSysMessage("\xe6\x84\x9f\xe8\xb0\xa2\xe4\xbd\xa0\xe5\xaf\xb9\x20\x57\x6f\x57\x20\xe9\xa1\xb9\xe7\x9b\xae\xe7\x9a\x84\xe6\x94\xaf\xe6\x8c\x81\xef\xbc\x8c\xe4\xbd\xa0\xe8\x8e\xb7\xe5\xbe\x97\xe4\xba\x86\x20\x31\x30\x30\x30\x20\xe7\x82\xb9\xe6\xad\xa3\xe4\xb9\x89\xe7\x82\xb9\xe6\x95\xb0\xe3\x80\x82");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe4\xbd\xa0\xe6\xb2\xa1\xe6\x9c\x89\xe6\x89\x80\xe9\x9c\x80\xe7\x9a\x84\xe4\xbb\xa3\xe5\xb8\x81\xe3\x80\x82");
        }
        return true;
    }
};

class valor_1000 : public ItemScript
{
public:
    valor_1000() : ItemScript("battle_pay_currency_valor_1000") {}

    bool OnUse(Player *player, Item *item, const SpellCastTargets &) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground()) //Item is not usable in combat, arenas and battlegrounds. This can be modified to your taste.
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(CURRENCY_TYPE_VALOR_POINTS, 1000 * CURRENCY_PRECISION, true, true, true); // add 1000 valor points
            ChatHandler(player->GetSession()).SendSysMessage("\xe6\x84\x9f\xe8\xb0\xa2\xe4\xbd\xa0\xe5\xaf\xb9\x20\x57\x6f\x57\x20\xe9\xa1\xb9\xe7\x9b\xae\xe7\x9a\x84\xe6\x94\xaf\xe6\x8c\x81\xef\xbc\x8c\xe4\xbd\xa0\xe8\x8e\xb7\xe5\xbe\x97\xe4\xba\x86\x20\x31\x30\x30\x30\x20\xe7\x82\xb9\xe5\x8b\x87\xe6\xb0\x94\xe7\x82\xb9\xe6\x95\xb0\xe3\x80\x82");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe4\xbd\xa0\xe6\xb2\xa1\xe6\x9c\x89\xe6\x89\x80\xe9\x9c\x80\xe7\x9a\x84\xe4\xbb\xa3\xe5\xb8\x81\xe3\x80\x82");
        }
        return true;
    }
};

class conquest_1000 : public ItemScript
{
public:
    conquest_1000() : ItemScript("battle_pay_currency_conquest_1000") {}

    bool OnUse(Player *player, Item *item, const SpellCastTargets &) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground()) //Item is not usable in combat, arenas and battlegrounds. This can be modified to your taste.
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(390, 1000 * CURRENCY_PRECISION); // add 1000 conquest points
            ChatHandler(player->GetSession()).SendSysMessage("\xe6\x84\x9f\xe8\xb0\xa2\xe4\xbd\xa0\xe5\xaf\xb9\x20\x57\x6f\x57\x20\xe9\xa1\xb9\xe7\x9b\xae\xe7\x9a\x84\xe6\x94\xaf\xe6\x8c\x81\xef\xbc\x8c\xe4\xbd\xa0\xe8\x8e\xb7\xe5\xbe\x97\xe4\xba\x86\x20\x31\x30\x30\x30\x20\xe7\x82\xb9\xe5\xbe\x81\xe6\x9c\x8d\xe7\x82\xb9\xe6\x95\xb0\xe3\x80\x82");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe4\xbd\xa0\xe6\xb2\xa1\xe6\x9c\x89\xe6\x89\x80\xe9\x9c\x80\xe7\x9a\x84\xe4\xbb\xa3\xe5\xb8\x81\xe3\x80\x82");
        }
        return true;
    }
};

template<int64 Gold>
class battle_pay_gold : public ItemScript
{
public:
    battle_pay_gold(char const* scriptName) : ItemScript(scriptName) { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground())
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if (player->GetMoney() > MAX_MONEY_AMOUNT - uint64(Gold))
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe5\xb7\xb2\xe8\xb6\x85\xe8\xbf\x87\xe5\x85\x81\xe8\xae\xb8\xe7\x9a\x84\xe9\x87\x91\xe5\xb8\x81\xe4\xb8\x8a\xe9\x99\x90\xe3\x80\x82");
        }
        else
        {
            player->ModifyMoney(Gold);
            player->DestroyItemCount(item->GetEntry(), 1, true);

            std::ostringstream message;
            message << "Thanks for helping the Pandaria 5.4.8 project, you just received " << Gold / 10000 << " gold.";
            ChatHandler(player->GetSession()).SendSysMessage(message.str().c_str());
            player->SaveToDB();
        }

        return true;
    }
};

template<uint32 Level>
class battle_pay_level : public ItemScript
{
public:
    battle_pay_level(char const* scriptName) : ItemScript(scriptName) { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground())
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if (Level <= player->GetLevel())
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe4\xbd\xa0\xe5\xbd\x93\xe5\x89\x8d\xe7\x9a\x84\xe8\xa7\x92\xe8\x89\xb2\xe7\xad\x89\xe7\xba\xa7\xe8\xbf\x87\xe9\xab\x98\xe3\x80\x82");
        }
        else
        {
            player->GiveLevel(Level);
            player->DestroyItemCount(item->GetEntry(), 1, true);
            ChatHandler(player->GetSession()).SendSysMessage("\xe6\x84\x9f\xe8\xb0\xa2\xe4\xbd\xa0\xe5\xaf\xb9\x20\x50\x61\x6e\x64\x61\x72\x69\x61\x20\x35\x2e\x34\x2e\x38\x20\xe9\xa1\xb9\xe7\x9b\xae\xe7\x9a\x84\xe6\x94\xaf\xe6\x8c\x81\xef\xbc\x8c\xe4\xbd\xa0\xe7\x9a\x84\xe8\xa7\x92\xe8\x89\xb2\xe5\xb7\xb2\xe6\x8f\x90\xe5\x8d\x87\xe8\x87\xb3\x20\x39\x30\x20\xe7\xba\xa7\xe3\x80\x82");
            player->SaveToDB();
        }

        return true;
    }
};

template<AtLoginFlags FlagAtLogin>
class battle_pay_service : public ItemScript
{
public:
    battle_pay_service(char const* scriptName) : ItemScript(scriptName) { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground())
        {
            player->GetSession()->SendNotification("You may not use this token whilst you are in combat or present in an arena or battleground.");
        }
        else if (player->HasAtLoginFlag(AtLoginFlags(0xFFFFFFFF)))
        {
            ChatHandler(player->GetSession()).SendSysMessage("\xe4\xbd\xa0\xe5\xb7\xb2\xe7\xbb\x8f\xe6\xbf\x80\xe6\xb4\xbb\xe8\xbf\x87\xe8\xa7\x92\xe8\x89\xb2\xe6\x9c\x8d\xe5\x8a\xa1\xe4\xba\x86\xe3\x80\x82");
        }
        else
        {
            player->SetAtLoginFlag(FlagAtLogin);
            player->DestroyItemCount(item->GetEntry(), 1, true);
            ChatHandler(player->GetSession()).SendSysMessage("\xe8\xa7\x92\xe8\x89\xb2\xe6\x9c\x8d\xe5\x8a\xa1\xe5\xb7\xb2\xe6\xbf\x80\xe6\xb4\xbb\xe3\x80\x82\xe8\xaf\xb7\xe7\x99\xbb\xe5\x87\xba\xe5\x90\x8e\xe9\x87\x8d\xe6\x96\xb0\xe8\xbf\x9b\xe5\x85\xa5\xe8\xaf\xa5\xe8\xa7\x92\xe8\x89\xb2\xe3\x80\x82");
            player->SaveToDB();
        }

        return true;
    }
};

void AddSC_custom_items()
{
    new honor_1000();
    new justice_1000();
    new valor_1000();
    new conquest_1000();
    new battle_pay_gold<BattlePay::Gold_1K>("battle_pay_gold_1k");
    new battle_pay_gold<BattlePay::Gold_5K>("battle_pay_gold_5k");
    new battle_pay_gold<BattlePay::Gold_10K>("battle_pay_gold_10k");
    new battle_pay_gold<BattlePay::Gold_30K>("battle_pay_gold_30k");
    new battle_pay_gold<BattlePay::Gold_80K>("battle_pay_gold_80k");
    new battle_pay_gold<BattlePay::Gold_150K>("battle_pay_gold_150k");
    new battle_pay_level<90>("battle_pay_service_level_90");
    new battle_pay_service<AT_LOGIN_RENAME>("battle_pay_service_rename");
    new battle_pay_service<AT_LOGIN_CHANGE_FACTION>("battle_pay_service_change_faction");
    new battle_pay_service<AT_LOGIN_CHANGE_RACE>("battle_pay_service_change_race");
    new battle_pay_service<AT_LOGIN_CUSTOMIZE>("battle_pay_service_customize");
}
