/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "MageTriggers.h"

#include "MageActions.h"
#include "Playerbots.h"

bool ArcaneBrillianceTrigger::IsActive()
{
    return BuffTrigger::IsActive() && !botAI->HasAura("arcane brilliance", GetTarget());
}

bool RuneOfPowerTrigger::IsActive()
{
    return BuffTrigger::IsActive() && !botAI->HasAura("rune of power", GetTarget());
}

bool MageArmorTrigger::IsActive()
{
    return botAI->GetBot()->GetSpecialization() ==
        Specializations::SPEC_MAGE_ARCANE &&
        !botAI->HasAura("mage armor", bot);
}

bool ArcaneMissilesTrigger::IsActive()
{
    if (!botAI->IsGroupPveActivity()) return HasAuraStackTrigger::IsActive();
    Aura* missiles = bot->GetAura(79683);
    Aura* charge = bot->GetAura(36032);
    return missiles && (missiles->GetStackAmount() >= 2 || (charge && charge->GetStackAmount() >= 4));
}

bool ArcaneChargeTrigger::IsActive()
{
    if (!botAI->IsGroupPveActivity()) return HasAuraStackTrigger::IsActive();
    Aura* charge = bot->GetAura(36032);
    return charge && charge->GetStackAmount() >= 4;
}

bool FrostArmorTrigger::IsActive()
{
    return botAI->GetBot()->GetSpecialization() ==
        Specializations::SPEC_MAGE_FROST &&
        !botAI->HasAura("frost armor", bot);
}

bool MoltenArmorTrigger::IsActive()
{
    return (botAI->GetBot()->GetSpecialization() == Specializations::SPEC_MAGE_FIRE && !botAI->HasAura("molten armor", bot));
}

bool FrostNovaOnTargetTrigger::IsActive()
{
    Unit* target = GetTarget();
    if (!target || !target->IsAlive() || !target->IsInWorld())
    {
        return false;
    }
    return botAI->HasAura(spell, target);
}

bool IcyVeinsTrigger::IsActive()
{
    Unit* target = GetTarget();
    if (!target || !target->IsAlive() || !target->IsInWorld())
    {
        return false;
    }
    return !botAI->HasAura("icy veins", target);
}

bool FingersOfFrostSingleTrigger::IsActive()
{
    // The MoP Ice Lance/Deep Freeze scripts consume stacks of aura 44544,
    // not proc charges. Use the actual proc aura rather than its visuals.
    Aura* aura = bot->GetAura(44544);
    return aura && aura->GetStackAmount() == 1;
}

bool FingersOfFrostDoubleTrigger::IsActive()
{
    Aura* aura = bot->GetAura(44544);
    return aura && aura->GetStackAmount() >= 2;
}

bool FingersOfFrostPveTrigger::IsActive()
{
    // Evaluate the activity at runtime: bots may be prepared outside the
    // instance before the same strategy starts running inside it.
    Aura* aura = bot->GetAura(44544);
    return botAI->IsGroupPveActivity() && aura && aura->GetStackAmount() > 0;
}

bool SlowNotOnTargetTrigger::IsActive()
{
    Unit* target = GetTarget();
    if (!target || !target->IsAlive() || !target->IsInWorld())
    {
        return false;
    }
    return !botAI->HasAura(spell, target);
}

bool HeatingUpTrigger::IsActive()
{
    Aura* aura = botAI->GetAura("heating up", bot, false, false, -1);
    return aura != nullptr;
}
