/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "ShamanActions.h"

#include "Playerbots.h"
#include "Totem.h"
#include "Timer.h"

bool CastTotemAction::isUseful()
{
    if (needLifeTime > 0.1f && AI_VALUE(uint8, "attacker count") < 3)
    {
        Unit* target = AI_VALUE(Unit*, "current target");
        if (!target)
        {
            return false;
        }
        float dps = AI_VALUE(float, "estimated group dps");
        if (target->GetHealth() / dps < needLifeTime)
        {
            return false;
        }
    }
    return CastBuffSpellAction::isUseful() && !AI_VALUE2(bool, "has totem", name) && !botAI->HasAura(buff, bot);
}

bool CastManaSpringTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "healing stream totem");
}

bool CastManaTideTotemAction::isUseful()
{
    if (!CastTotemAction::isUseful())
        return false;

    if (!announcementStartedAt)
        return true;

    uint32 elapsed = getMSTimeDiff(announcementStartedAt, getMSTime());
    if (elapsed > 10000)
    {
        // The need disappeared, the cast was blocked, or the encounter state
        // changed. Start a fresh warning instead of casting from stale state.
        announcementStartedAt = 0;
        return true;
    }

    return elapsed >= 5000;
}

bool CastManaTideTotemAction::Execute(Event event)
{
    uint32 now = getMSTime();
    if (!announcementStartedAt)
    {
        botAI->Say("Mana Tide Totem in 5 seconds!");
        announcementStartedAt = now;
        return true;
    }

    if (getMSTimeDiff(announcementStartedAt, now) < 5000)
        return false;

    bool cast = CastBuffSpellAction::Execute(event);
    if (cast)
        announcementStartedAt = 0;

    return cast;
}

bool CastFlametongueTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "magma totem") &&
           !botAI->HasAura("totem of wrath", bot);
}

bool CastSearingTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "flametongue totem");
}

bool CastMagmaTotemAction::isUseful() {
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !bot->IsWithinMeleeRange(target))
        return false;

    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", name); 
}

bool CastFireNovaAction::isUseful() {
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target)
        return false;
    Creature* fireTotem = bot->GetMap()->GetCreature(bot->m_SummonSlot[1]);
    if (!fireTotem)
        return false;
    
    if (target->GetDistance(fireTotem) > 8.0f)
        return false;
    
    return CastMeleeSpellAction::isUseful(); 
}

bool CastCleansingTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "mana tide totem");
}
