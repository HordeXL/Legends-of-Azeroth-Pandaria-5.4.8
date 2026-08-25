/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "ShamanTriggers.h"

#include <algorithm>

#include "Playerbots.h"
#include "PlayerBotSpec.h"

bool GroupLowManaForManaTideTrigger::IsActive()
{
    if (!bot || !bot->IsAlive() || !bot->IsInCombat() || !bot->GetGroup() ||
        bot->GetSpecialization() != SPEC_SHAMAN_RESTORATION || !bot->HasSpell(16190))
    {
        return false;
    }

    uint32 manaUsers = 0;
    uint32 lowManaUsers = 0;
    bool shamanNeedsMana = false;
    bool criticalManaUser = false;
    bool criticalHealerMana = false;

    for (GroupReference* ref = bot->GetGroup()->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || !member->IsAlive() || member->GetMap() != bot->GetMap() ||
            bot->GetDistance(member) > 80.0f || member->GetMaxPower(POWER_MANA) == 0 ||
            PlayerBotSpec::IsTank(member, true) ||
            (!PlayerBotSpec::IsHeal(member, true) && !PlayerBotSpec::IsRanged(member, true)))
        {
            continue;
        }

        ++manaUsers;
        float manaPct = member->GetPowerPct(POWER_MANA);
        if (manaPct < sPlayerbotAIConfig->mediumMana)
            ++lowManaUsers;

        if (member == bot && manaPct < sPlayerbotAIConfig->mediumMana)
            shamanNeedsMana = true;
        if (manaPct < sPlayerbotAIConfig->lowMana)
            criticalManaUser = true;
        if (PlayerBotSpec::IsHeal(member, true) && manaPct < 25.0f)
            criticalHealerMana = true;
    }

    uint32 coordinatedThreshold = std::max<uint32>(2, (manaUsers + 3) / 4);
    return shamanNeedsMana || criticalManaUser || criticalHealerMana ||
           (manaUsers && lowManaUsers >= coordinatedThreshold);
}
