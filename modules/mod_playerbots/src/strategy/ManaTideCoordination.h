/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_MANATIDECOORDINATION_H
#define _PLAYERBOT_MANATIDECOORDINATION_H

#include "Creature.h"
#include "Group.h"
#include "Map.h"
#include "Player.h"
#include "PlayerbotSpec.h"

namespace ManaTideCoordination
{
constexpr uint32 ManaTideTotemEntry = 10467;
constexpr float EffectRadius = 40.0f;
constexpr float MoveInsideRadius = 28.0f;
constexpr float SearchRadius = 80.0f;

inline bool IsManaBeneficiary(Player* player)
{
    if (!player || !player->IsInWorld() || !player->IsAlive() || !player->IsInCombat() ||
        !player->GetGroup() || player->GetMaxPower(POWER_MANA) == 0 ||
        PlayerBotSpec::IsTank(player, true))
    {
        return false;
    }

    // Keep melee characters in position. Holy paladins are deliberately kept
    // eligible even though the legacy ranged-spec helper classifies all
    // paladins as melee.
    return PlayerBotSpec::IsHeal(player, true) || PlayerBotSpec::IsRanged(player, true);
}

inline Creature* FindActiveGroupTotem(Player* player)
{
    Group* group = player ? player->GetGroup() : nullptr;
    if (!group || !player->GetMap())
        return nullptr;

    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || member->GetMap() != player->GetMap())
            continue;

        for (uint8 slot : {SUMMON_SLOT_TOTEM_FIRE, SUMMON_SLOT_TOTEM_EARTH,
                           SUMMON_SLOT_TOTEM_WATER, SUMMON_SLOT_TOTEM_AIR,
                           SUMMON_SLOT_TOTEM_EXTRA})
        {
            if (!member->m_SummonSlot[slot])
                continue;

            Creature* totem = member->GetMap()->GetCreature(member->m_SummonSlot[slot]);
            if (totem && totem->IsAlive() && totem->GetEntry() == ManaTideTotemEntry &&
                player->GetDistance(totem) <= SearchRadius)
            {
                return totem;
            }
        }
    }

    return nullptr;
}
}

#endif
