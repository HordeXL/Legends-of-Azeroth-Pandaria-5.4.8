/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "WarlockActions.h"

#include "Event.h"
#include "Playerbots.h"
#include "DynamicObject.h"

bool AfflictionRotationAction::isUseful()
{
    Unit* target = GetTarget();
    return UsesAfflictionBotRotation(botAI) && bot->IsAlive() && target && target->IsAlive() &&
        target->IsInWorld() && target->GetMap() == bot->GetMap();
}

bool AfflictionRotationAction::Execute(Event /*event*/)
{
    bool const result = RunAfflictionBotRotation(botAI, GetTarget(), runtime);
    // Revisit channels often enough to observe the same post-tick window as
    // the player's button. Normal GCD/cast checks still throttle actual casts.
    botAI->SetNextCheckDelay(100);
    return result;
}

bool CastRainOfFireAction::isUseful()
{
    if (botAI->IsGroupPveActivity())
    {
        Unit* target = GetTarget();
        if (!target) return false;
        std::list<DynamicObject*> areas;
        bot->GetDynObjectList(areas, 5740);
        bot->GetDynObjectList(areas, 104232);
        for (DynamicObject* area : areas)
            if (area && area->IsWithinDistInMap(target, 8.0f))
                return false;
    }
    return CastSpellAction::isUseful();
}

namespace
{
bool IsPvPControlTarget(PlayerbotAI* botAI, Unit* target)
{
    return botAI && target && botAI->IsPvpActivity() &&
        target->GetCharmerOrOwnerPlayerOrPlayerItself();
}

bool IsGroupPveTrash(PlayerbotAI* botAI, Unit* target)
{
    if (!botAI || !botAI->IsGroupPveActivity())
        return false;

    Creature* creature = target ? target->ToCreature() : nullptr;
    return !creature || (!creature->IsDungeonBoss() && !creature->isWorldBoss());
}
}

bool CastDarkSoulMiseryAction::isUseful()
{
    return !IsGroupPveTrash(botAI, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastDarkSoulKnowledgeAction::isUseful()
{
    return !IsGroupPveTrash(botAI, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastDarkSoulInstabilityAction::isUseful()
{
    return !IsGroupPveTrash(botAI, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastDrainSoulAction::isUseful()
{
    // Affliction already schedules Drain Soul only through the execute-health
    // trigger.  A random 40% gate made otherwise identical bots alternate
    // between a proper execute and idle/filler casts, producing unstable DPS.
    return CastSpellAction::isUseful();
}

Value<Unit*>* CastBanishAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", "banish"); }

bool CastBanishAction::Execute(Event event) { return botAI->CastSpell("banish", GetTarget()); }

Value<Unit*>* CastFearOnCcAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", "fear"); }

bool CastFearOnCcAction::Execute(Event event) { return botAI->CastSpell("fear", GetTarget()); }

bool CastFearOnCcAction::isPossible()
{
    return IsPvPControlTarget(botAI, GetTarget()) &&
        CastBuffSpellAction::isPossible();
}

bool CastFearOnCcAction::isUseful()
{
    return IsPvPControlTarget(botAI, GetTarget()) &&
        CastBuffSpellAction::isUseful();
}

bool CastFearAction::isUseful()
{
    return IsPvPControlTarget(botAI, GetTarget()) &&
        CastDebuffSpellAction::isUseful();
}

bool CastMortalCoilAction::isUseful()
{
    return IsPvPControlTarget(botAI, GetTarget()) &&
        CastSpellAction::isUseful();
}

bool CastBloodHorrorAction::isUseful()
{
    return IsPvPControlTarget(botAI, GetTarget()) &&
        CastSpellAction::isUseful();
}

bool CastLifeTapAction::isUseful() { return AI_VALUE2(uint8, "health", "self target") > sPlayerbotAIConfig->lowHealth; }

bool CastHandOfGuldanAction::Execute(Event event)
{
	return botAI->CastSpell(105174, GetTarget());
}

bool CastChaosBoltAction::isUseful()
{
	if (botAI->IsGroupPveActivity())
		return !bot->HasAura(108683) && bot->GetPower(POWER_BURNING_EMBERS) >= 10 &&
			CastSpellAction::isUseful();
	return botAI->HasAura("fire and brimstone", bot) || bot->GetPower(Powers::POWER_BURNING_EMBERS) >= 10;
}
bool CastIncinerateAction::Execute(Event event)
{
	if (!isUseful() || !isPossible())
		return false;

	if (botAI->HasAura("fire and brimstone", bot))
		botAI->CastSpell(114654, GetTarget());
	else
		botAI->CastSpell(spell, GetTarget());

	return true;
}
bool CastImmolateAction::Execute(Event event)
{
	if (!isUseful() || !isPossible())
		return false;

	if (botAI->HasAura("fire and brimstone", bot))
		botAI->CastSpell(108686, GetTarget());
	else
		botAI->CastSpell(spell, GetTarget());

	return true;
}
bool CastConflagrateAction::Execute(Event event)
{
	if (!isUseful() || !isPossible())
		return false;

	if (botAI->HasAura("fire and brimstone", bot))
		botAI->CastSpell(108685, GetTarget());
	else
		botAI->CastSpell(spell, GetTarget());

	return true;
}
