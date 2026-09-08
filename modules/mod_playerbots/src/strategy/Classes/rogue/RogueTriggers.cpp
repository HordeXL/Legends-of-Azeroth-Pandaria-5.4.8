/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "RogueTriggers.h"

#include "GenericTriggers.h"
#include "Playerbots.h"
#include "ServerFacade.h"
#include "AiFactory.h"

bool RoguePveAoeTrigger::IsActive()
{
    return botAI->IsGroupPveActivity() && MediumAoeTrigger::IsActive();
}

bool RoguePveAbilityTrigger::IsActive()
{
    if (!botAI->IsGroupPveActivity() || !bot->IsAlive())
        return false;

    if (ability == RoguePveAbility::Poison)
    {
        if (!bot->HasSpell(2823))
            return false;
        Aura* poison = bot->GetAura(2823);
        // MoP poisons are self buffs, not temporary weapon enchants/items.
        // Reapply when missing; refresh early only between fights.
        return !poison || (!bot->IsInCombat() && poison->GetDuration() >= 0 &&
            poison->GetDuration() < 60000);
    }

    Unit* target = AI_VALUE(Unit*, "current target");
    if (ability == RoguePveAbility::OpenCombat)
        return target && target->IsAlive() && target->IsInCombat() && bot->HasAura(1784) &&
            bot->IsValidAttackTarget(target) && bot->IsWithinMeleeRange(target) &&
            botAI->CanLfgAutoQueueEngage(target);
    if (!target || !target->IsAlive() || !bot->IsInCombat() ||
        !bot->IsValidAttackTarget(target) || !botAI->CanLfgAutoQueueEngage(target))
        return false;

    if (ability == RoguePveAbility::BurstOfSpeed)
        return bot->HasSpell(108212) && !bot->IsWithinMeleeRange(target) &&
            !bot->HasAura(137573) && !bot->HasAura(2983) &&
            bot->GetPower(POWER_ENERGY) >= 80;

    if (bot->GetSpecialization() != SPEC_ROGUE_SUBTLETY ||
        !bot->IsWithinMeleeRange(target))
        return false;

    uint8 const points = bot->GetComboTarget() == target ? bot->GetComboPoints() : 0;
    bool const dance = bot->HasAura(51713);
    if (ability == RoguePveAbility::ShadowDance)
        return bot->HasSpell(51713) && !dance && points <= 2 &&
            bot->GetPower(POWER_ENERGY) >= 60 && bot->HasAura(5171) &&
            !target->HasInArc(float(M_PI), bot);
    if (ability == RoguePveAbility::Premeditation)
        return bot->HasSpell(14183) && points <= 2 && (dance || bot->HasAura(1784));
    return ability == RoguePveAbility::Ambush && dance && points < 4;
}

bool RogueComboPointsTrigger::IsActive()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !target->IsAlive() || target != bot->GetComboTarget())
        return false;

    return dyingTarget ? bot->GetComboPoints() > 0 && target->GetHealthPct() < 20.0f
        : bot->GetComboPoints() >= 4;
}

bool RogueSliceAndDiceTrigger::IsActive()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !target->IsAlive() || target != bot->GetComboTarget() || !bot->GetComboPoints())
        return false;

    Aura* aura = bot->GetAura(5171);
    // Establish the buff early, then refresh with a useful number of points.
    return !aura || (aura->GetDuration() <= 3000 && bot->GetComboPoints() >= 4);
}

bool RogueSubtletyBuilderTrigger::IsActive()
{
    return botAI->IsGroupPveActivity() &&
        AiFactory::GetPlayerSpecTab(bot) == Specializations::SPEC_ROGUE_SUBTLETY &&
        AI_VALUE2(uint8, "combo", "current target") < 4;
}
