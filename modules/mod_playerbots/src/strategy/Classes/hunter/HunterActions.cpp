/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "HunterActions.h"

#include "Event.h"
#include "GenericSpellActions.h"
#include "Playerbots.h"
#include "SpellHistory.h"

bool CastAspectOfTheHawkAction::isUseful()
{
    // SpellIdValue upgrades the old action label to Iron Hawk. A name-based
    // buff check still searches for plain Hawk and endlessly recasts the
    // already active replacement. Check the actual desired aura instead.
    uint32 const aspect = bot->HasSpell(109260) ? 109260 : 13165;
    return bot->HasSpell(aspect) && !bot->HasAura(aspect) && CastSpellAction::isUseful();
}

std::string const CastKillCommandAction::GetTargetName()
{
    return botAI->IsGroupPveActivity() ? "current target" : "pet target";
}

bool CastKillCommandAction::isUseful()
{
    if (!botAI->IsGroupPveActivity()) return CastAuraSpellAction::isUseful();
    Unit* target = GetTarget();
    Pet* pet = bot->GetPet();
    // Kill Command can make the pet charge. Only use it after the delayed
    // pet order has reached this enemy; never use it to launch a ranged pull.
    return target && pet && pet->IsAlive() && pet->GetVictim() == target &&
        pet->IsWithinMeleeRange(target) && botAI->CanPetEngageTarget(target) &&
        CastSpellAction::isUseful();
}

bool CastAncientHysteriaAction::isPossible()
{
    Pet* pet = bot->GetPet();
    return pet && pet->IsAlive() && pet->HasSpell(90355) &&
        pet->GetSpellHistory()->IsReady(90355);
}

bool CastAncientHysteriaAction::Execute([[maybe_unused]] Event event)
{
    Pet* pet = bot->GetPet();
    if (!pet || !pet->IsAlive() || !pet->HasSpell(90355) ||
        !pet->GetSpellHistory()->IsReady(90355))
        return false;

    pet->CastSpell(pet, 90355, false);
    return true;
}

bool CastHuntersMarkAction::isUseful() { return CastDebuffSpellAction::isUseful(); }

bool CastViperStingAction::isUseful()
{
    return AI_VALUE2(uint8, "mana", "self target") < 50 && AI_VALUE2(uint8, "mana", "current target") >= 30;
}

bool CastAspectOfTheCheetahAction::isUseful()
{
    return !botAI->HasAnyAuraOf(GetTarget(), "aspect of the cheetah", "aspect of the pack", nullptr);
}

Value<Unit*>* CastFreezingTrap::GetTargetValue() { return context->GetValue<Unit*>("cc target", "freezing trap"); }

bool CastAutoShotAction::isUseful()
{
    if (botAI->IsInVehicle() && !botAI->IsInVehicle(false, false, true))
        return false;

    if (AI_VALUE(Unit*, "current target") && bot->GetCurrentSpell(CURRENT_AUTOREPEAT_SPELL) &&
        bot->GetCurrentSpell(CURRENT_AUTOREPEAT_SPELL)->m_targets.GetUnitTargetGUID() ==
            AI_VALUE(Unit*, "current target")->GetGUID())
    {
        return false;
    }
    return AI_VALUE(uint32, "active spell") != AI_VALUE2(uint32, "spell id", getName());
}

Value<Unit*>* CastScareBeastCcAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", "scare beast"); }

bool CastScareBeastCcAction::Execute(Event event) { return botAI->CastSpell("scare beast", GetTarget()); }

bool CastWingClipAction::isUseful()
{
    if (botAI->IsGroupPveActivity())
        return false;

    return CastSpellAction::isUseful() && !botAI->HasAura(spell, GetTarget());
}

NextAction** CastWingClipAction::getPrerequisites() { return nullptr; }
