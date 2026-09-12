#include "ScriptMgr.h"
#include "Chat.h"
#include "ServiceMgr.h"

#pragma execution_character_set("UTF-8")

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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(392, 1000 * CURRENCY_PRECISION); // add 1000 honor points
            ChatHandler(player->GetSession()).SendSysMessage("感谢你帮助魔兽世界项目，你获得了1000点荣誉值。");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("你没有所需的代币。");
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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(CURRENCY_TYPE_JUSTICE_POINTS, 1000 * CURRENCY_PRECISION, true, true, true); // add 1000 justice points
            ChatHandler(player->GetSession()).SendSysMessage("感谢你帮助魔兽世界项目，你获得了1000点正义值。");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("你没有所需的代币。");
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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(CURRENCY_TYPE_VALOR_POINTS, 1000 * CURRENCY_PRECISION, true, true, true); // add 1000 valor points
            ChatHandler(player->GetSession()).SendSysMessage("感谢你帮助魔兽世界项目，你获得了1000点勇气值。");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("你没有所需的代币。");
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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if(player->HasItemCount(item->GetEntry(), 1, true)) //verify that the characters have the item
        {
            player->ModifyCurrency(390, 1000 * CURRENCY_PRECISION); // add 1000 conquest points
            ChatHandler(player->GetSession()).SendSysMessage("感谢你帮助魔兽世界项目，你获得了1000点征服值。");

            //Item is destroyed on useage.
            player->DestroyItemCount(item->GetEntry(), 1, true);

            //save pj
            player->SaveToDB();
        }
        else
        {
            ChatHandler(player->GetSession()).SendSysMessage("你没有所需的代币。");
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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if (player->GetMoney() > MAX_MONEY_AMOUNT - uint64(Gold))
        {
            ChatHandler(player->GetSession()).SendSysMessage("超过允许的金币上限。");
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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if (Level <= player->GetLevel())
        {
            ChatHandler(player->GetSession()).SendSysMessage("你的角色等级过高。");
        }
        else
        {
            player->GiveLevel(Level);
            player->DestroyItemCount(item->GetEntry(), 1, true);
            ChatHandler(player->GetSession()).SendSysMessage("感谢你帮助熊猫人之谜5.4.8项目，你的角色已升至90级。");
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
            player->GetSession()->SendNotification("你在战斗中或身处竞技场/战场时无法使用此代币。");
        }
        else if (player->HasAtLoginFlag(AtLoginFlags(0xFFFFFFFF)))
        {
            ChatHandler(player->GetSession()).SendSysMessage("你已经激活过一项角色服务。");
        }
        else
        {
            player->SetAtLoginFlag(FlagAtLogin);
            player->DestroyItemCount(item->GetEntry(), 1, true);
            ChatHandler(player->GetSession()).SendSysMessage("角色服务已激活。请退出游戏并重新登录该角色。");
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
