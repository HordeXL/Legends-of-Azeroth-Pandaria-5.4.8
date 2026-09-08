#ifndef _PLAYERBOT_PVE_WEAPON_IMBUE_ACTION_H
#define _PLAYERBOT_PVE_WEAPON_IMBUE_ACTION_H
#include "Playerbots.h"

inline uint32 GetPveShamanImbueSpell(Player* bot, uint8 slot)
{
    if (slot == EQUIPMENT_SLOT_OFFHAND) return 8024; // Flametongue
    if (bot->GetSpecialization() == SPEC_SHAMAN_ENHANCEMENT) return 8232; // Windfury
    if (bot->GetSpecialization() == SPEC_SHAMAN_RESTORATION) return 51730; // Earthliving
    return 8024;
}

inline bool NeedsPveShamanImbue(PlayerbotAI* ai, uint8 slot)
{
    Player* bot = ai->GetBot();
    if (!ai->IsGroupPveActivity() || bot->GetClass() != CLASS_SHAMAN || bot->IsInCombat()) return false;
    Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item || item->GetTemplate()->Class != ITEM_CLASS_WEAPON) return false;
    uint32 id = GetPveShamanImbueSpell(bot, slot);
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    if (!info || !bot->HasSpell(id)) return false;
    for (auto const& effect : info->Effects)
        if (effect.Effect == SPELL_EFFECT_ENCHANT_ITEM_TEMPORARY && effect.MiscValue > 0)
            return item->GetEnchantmentId(TEMP_ENCHANTMENT_SLOT) != uint32(effect.MiscValue);
    return false;
}

class PveWeaponImbueAction : public Action
{
public:
    PveWeaponImbueAction(PlayerbotAI* ai, uint8 slot)
        : Action(ai, slot == EQUIPMENT_SLOT_MAINHAND ? "pve main hand imbue" : "pve off hand imbue"), slot(slot) {}
    bool isUseful() override { return NeedsPveShamanImbue(botAI, slot); }
    bool isPossible() override
    {
        return isUseful() && botAI->CanCastSpell(GetPveShamanImbueSpell(bot, slot), bot, true,
            bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    }
    bool Execute(Event) override
    {
        return isPossible() && botAI->CastSpell(GetPveShamanImbueSpell(bot, slot), bot,
            bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    }
private:
    uint8 slot;
};
#endif
