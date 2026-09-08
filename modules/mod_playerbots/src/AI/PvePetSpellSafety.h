#ifndef _PLAYERBOT_PVE_PET_SPELL_SAFETY_H
#define _PLAYERBOT_PVE_PET_SPELL_SAFETY_H
#include "SpellInfo.h"
#include "SpellAuraDefines.h"

inline bool IsPvePetRushSpell(SpellInfo const* info)
{
    if (!info || info->IsPassive()) return false;
    // DK's public Leap is a dummy wrapper; spell_dk_ghoul_ability selects
    // normal Leap or Dark Transformation's Shambling Rush in C++.
    if (info->Id == 47482 || info->Id == 91809 || info->Id == 91802)
        return true;
    for (SpellEffectInfo const& effect : info->Effects)
    {
        switch (effect.Effect)
        {
            case SPELL_EFFECT_CHARGE: case SPELL_EFFECT_CHARGE_DEST:
            case SPELL_EFFECT_JUMP: case SPELL_EFFECT_JUMP_DEST:
            case SPELL_EFFECT_JUMP_DEST_2:
            case SPELL_EFFECT_LEAP: case SPELL_EFFECT_LEAP_BACK:
                return true;
            default: break;
        }
        switch (effect.ApplyAuraName)
        {
            case SPELL_AURA_MOD_INCREASE_SPEED:
            case SPELL_AURA_MOD_SPEED_ALWAYS:
            case SPELL_AURA_MOD_SPEED_NOT_STACK:
            case SPELL_AURA_MOD_INCREASE_FLIGHT_SPEED:
                return true;
            default: break;
        }
    }
    return false;
}
#endif
