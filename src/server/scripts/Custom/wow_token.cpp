/*
* This file is part of the Pandaria 5.4.8 Project. See THANKS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include "ScriptMgr.h"
#include "GridNotifiersImpl.h"
#include "DatabaseEnv.h"
#include "Chat.h"

enum BattlePayTokenTrinityStrings 
{
    BATTLEPAY_TOKEN_TRINITYSTRING_SUCCESS                             = 30007,    // Shop points voucher redeemed: %u points were added to your account.
    BATTLEPAY_TOKEN_TRINITYSTRING_ERR_NOTENOUGH                       = 30008,    // You do not have the necessary token.
    BATTLEPAY_TOKEN_TRINITYSTRING_ERR_INBATTLE                        = 30009,    // You may not use this token whilst you are in combat or present in an arena or battleground.
    BATTLEPAY_TOKEN_TRINITYSTRING_ERR_DISABLED                        = 30010,    // Coins disabled.
};

namespace BattlePay
{
    enum Type : uint32
    {
        Points_2                            = 2,
        Points_3                            = 3,
        Points_7                            = 7,
        Points_13                           = 13
    };
}

template<uint32 Points>
class battle_pay_token : public ItemScript
{
public:
    battle_pay_token(const char *ScriptName) : ItemScript(ScriptName) { }

    bool OnUse(Player *player, Item *item, const SpellCastTargets &)
    {
        if (player->IsInCombat() || player->InArena() || player->InBattleground())
        {
            ChatHandler(player->GetSession()).PSendSysMessage(player->GetSession()->GetTrinityString(BATTLEPAY_TOKEN_TRINITYSTRING_ERR_INBATTLE));  
        }
        else if (!sWorld->getBoolConfig(CONFIG_WOW_TOKEN))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(player->GetSession()->GetTrinityString(BATTLEPAY_TOKEN_TRINITYSTRING_ERR_DISABLED));
            player->CastSpell(player, 27880, true);
        }
        else
        {
            if (player->HasItemCount(item->GetEntry(), 1, true))
            {
                player->AddDonateTokenCount(uint64(Points) * 10000);
                player->DestroyItemCount(item->GetEntry(), 1, true);
                ChatHandler(player->GetSession()).PSendSysMessage(player->GetSession()->GetTrinityString(BATTLEPAY_TOKEN_TRINITYSTRING_SUCCESS), Points);
                player->SaveToDB();
            }
            else
            {
                ChatHandler(player->GetSession()).PSendSysMessage(player->GetSession()->GetTrinityString(BATTLEPAY_TOKEN_TRINITYSTRING_ERR_NOTENOUGH));
            }
        }
        return true;
    }
};

void AddSC_wow_token()
{
    new battle_pay_token<BattlePay::Points_2>("wow_token_1");
    new battle_pay_token<BattlePay::Points_3>("wow_token_2");
    new battle_pay_token<BattlePay::Points_7>("wow_token_5");
    new battle_pay_token<BattlePay::Points_13>("wow_token_10");
}
