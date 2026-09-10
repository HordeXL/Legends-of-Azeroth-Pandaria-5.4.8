/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "RogueActions.h"
#include "RogueFinishingActions.h"

#include "Event.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "Playerbots.h"

namespace
{
bool HasRogueFinisherPoints(Player* bot, Unit* target)
{
    return target && target->IsAlive() && target == bot->GetComboTarget() &&
        (bot->GetComboPoints() >= 4 || (bot->GetComboPoints() > 0 && target->GetHealthPct() < 20.0f));
}
}

bool CastEviscerateAction::isUseful()
{
    Unit* target = GetTarget();
    bool const revealingReady = bot->GetSpecialization() !=
        Specializations::SPEC_ROGUE_COMBAT ||
        (target && target->HasAura(84617, bot->GetGUID()));
    return revealingReady && HasRogueFinisherPoints(bot, target) &&
        CastMeleeSpellAction::isUseful();
}

bool CastRuptureAction::isUseful()
{
    Unit* target = GetTarget();
    bool const revealingReady = bot->GetSpecialization() !=
        Specializations::SPEC_ROGUE_COMBAT ||
        (target && target->HasAura(84617, bot->GetGUID()));
    return revealingReady && target && target == bot->GetComboTarget() &&
        bot->GetComboPoints() >= 4 &&
        CastDebuffSpellAction::isUseful();
}

bool CastRevealingStrikeAction::isUseful()
{
    if (bot->GetSpecialization() != Specializations::SPEC_ROGUE_COMBAT)
        return false;

    Unit* target = GetTarget();
    return target && !target->HasAura(84617, bot->GetGUID()) &&
        CastMeleeDebuffSpellAction::isUseful();
}

bool CastSliceAndDiceAction::isUseful()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    Aura* aura = bot->GetAura(5171);
    return target && target->IsAlive() && target == bot->GetComboTarget() && bot->GetComboPoints() > 0 &&
        (!aura || bot->GetComboPoints() >= 4) && CastBuffSpellAction::isUseful();
}

bool CastStealthAction::isPossible()
{
    // Entering Stealth as a ranged pull starts delayed the rogue's first hit.
    // Keep out-of-combat preparation, but never hide again during a live pull.
    if (botAI->IsGroupPveActivity())
        if (Unit* target = AI_VALUE(Unit*, "current target"))
            if (target->IsInCombat() && botAI->CanLfgAutoQueueEngage(target)) return false;
    // do not use with WSG flag or EYE flag
    return !botAI->HasAura(23333, bot) && !botAI->HasAura(23335, bot) && !botAI->HasAura(34976, bot);
}

bool UnstealthAction::Execute(Event event)
{
    botAI->RemoveAura("stealth");
    // botAI->ChangeStrategy("+dps,-stealthed", BOT_STATE_COMBAT);

    return true;
}

bool CheckStealthAction::Execute(Event event)
{
    if (!botAI->IsGroupPveActivity() && botAI->HasAura("stealth", bot))
    {
        botAI->ChangeStrategy("-dps,+stealthed", BOT_STATE_COMBAT);
    }
    else
    {
        botAI->ChangeStrategy("+dps,-stealthed", BOT_STATE_COMBAT);
    }

    return true;
}

bool PveRogueOpenCombatAction::Execute(Event event)
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!botAI->IsGroupPveActivity() || !bot->HasAura(1784) || !target ||
        !target->IsAlive() || !target->IsInCombat() || !bot->IsValidAttackTarget(target) ||
        !bot->IsWithinMeleeRange(target) || !botAI->CanLfgAutoQueueEngage(target)) return false;
    // Do not wait indefinitely for the target's back. Use a legal opener,
    // or leave ordinary Stealth so the normal builder/finisher rotation runs.
    for (uint32 spellId : {8676u, 703u})
        if (botAI->CanCastSpell(spellId, target) && botAI->CastSpell(spellId, target)) return true;
    bot->RemoveAurasDueToSpell(1784); // Not Vanish or Shadow Dance.
    return true;
}

bool CastVanishAction::isUseful()
{
    // do not use with WSG flag or EYE flag
    return !botAI->HasAura(23333, bot) && !botAI->HasAura(23335, bot) && !botAI->HasAura(34976, bot);
}

bool CastTricksOfTheTradeOnMainTankAction::isUseful()
{
    return CastSpellAction::isUseful() && AI_VALUE2(float, "distance", GetTargetName()) < 20.0f;
}
