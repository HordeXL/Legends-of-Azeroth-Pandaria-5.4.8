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
            ChatHandler(player->GetSession()).SendSysMessage("Thanks for helping the WoW project, you just received 1000 honor points.");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("You do not have the necessary token.");
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
            ChatHandler(player->GetSession()).SendSysMessage("Thanks for helping the WoW project, you just received 1000 justice points.");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("You do not have the necessary token.");
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
            ChatHandler(player->GetSession()).SendSysMessage("Thanks for helping the WoW project, you just received 1000 valor points.");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("You do not have the necessary token.");
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
            ChatHandler(player->GetSession()).SendSysMessage("Thanks for helping the WoW project, you just received 1000 conquest points.");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("You do not have the necessary token.");
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
            ChatHandler(player->GetSession()).SendSysMessage("Maximum allowed gold limit exceeded.");
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
            ChatHandler(player->GetSession()).SendSysMessage("Your current character level is too high.");
        }
        else
        {
            player->GiveLevel(Level);
            player->DestroyItemCount(item->GetEntry(), 1, true);
            ChatHandler(player->GetSession()).SendSysMessage("Thanks for helping the Pandaria 5.4.8 project, you just leveled up your character to level 90.");
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
            ChatHandler(player->GetSession()).SendSysMessage("You have already activated a character service.");
        }
        else
        {
            player->SetAtLoginFlag(FlagAtLogin);
            player->DestroyItemCount(item->GetEntry(), 1, true);
            ChatHandler(player->GetSession()).SendSysMessage("The character service has been activated. Please log out and enter this character again.");
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
