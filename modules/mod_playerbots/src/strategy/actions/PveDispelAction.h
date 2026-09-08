#ifndef _PLAYERBOT_PVE_DISPEL_ACTION_H
#define _PLAYERBOT_PVE_DISPEL_ACTION_H
#include "Playerbots.h"
#include "PlayerBotSpec.h"
#include "GenericSpellActions.h"

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

class PveDispelAction : public CurePartyMemberAction
{
public:
    PveDispelAction(PlayerbotAI* ai, uint32 type)
        : CurePartyMemberAction(ai, GetPveDispelSpell(ai->GetBot()).name, type), type(type) {}
    bool isPossible() override { return Refresh() && CurePartyMemberAction::isPossible(); }
    bool isUseful() override { return Refresh() && CurePartyMemberAction::isUseful(); }
private:
    bool Refresh()
    {
        auto info = GetPveDispelSpell(bot);
        spell = info.name; // Same class can switch from DPS to healer and back.
        return botAI->IsGroupPveActivity() && (info.types & (1u << type)) && bot->HasSpell(info.id);
    }
    uint32 type;
};
#endif
