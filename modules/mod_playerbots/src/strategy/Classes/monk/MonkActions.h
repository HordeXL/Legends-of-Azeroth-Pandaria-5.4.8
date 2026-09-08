/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_MONKACTIONS_H
#define _PLAYERBOT_MONKACTIONS_H

#include "GenericSpellActions.h"
#include "MonkBuffs.h"
#include "Playerbots.h"

class PlayerbotAI;

// Shared and Windwalker actions.
BUFF_ACTION(CastStanceOfTheFierceTigerAction, "stance of the fierce tiger");
BUFF_ACTION(CastStanceOfTheSturdyOxAction, "stance of the sturdy ox");
BUFF_ACTION(CastStanceOfTheWiseSerpentAction, "stance of the wise serpent");
MELEE_ACTION(CastJabAction, "jab");
class CastTigerPalmAction : public CastMeleeSpellAction
{
public:
    CastTigerPalmAction(PlayerbotAI* ai) : CastMeleeSpellAction(ai, "tiger palm") { }
    bool isUseful() override
    {
        if (botAI->IsGroupPveActivity() && bot->GetSpecialization() == SPEC_MONK_WINDWALKER)
        {
            Aura* power = bot->GetAura(125359); // Tiger Power, not the attack ID.
            if (power && power->GetDuration() > 4000 && !bot->HasAura(118864))
                return false; // Only refresh, or use a free Combo Breaker.
        }
        return CastMeleeSpellAction::isUseful();
    }
};

class CastBlackoutKickAction : public CastMeleeSpellAction
{
public:
    CastBlackoutKickAction(PlayerbotAI* ai) : CastMeleeSpellAction(ai, "blackout kick") { }
    bool isUseful() override
    {
        if (botAI->IsGroupPveActivity() && bot->GetSpecialization() == SPEC_MONK_WINDWALKER &&
            bot->HasSpell(113656) && !bot->HasSpellCooldown(113656) &&
            bot->GetPower(POWER_CHI) < 3 && !bot->HasAura(116768) &&
            botAI->IsGroupPveAreaSpellSafe(sSpellMgr->GetSpellInfo(113656), GetTarget()))
            return false; // Let Jab build 3 Chi instead of spending every 2.
        return CastMeleeSpellAction::isUseful();
    }
};
MELEE_ACTION(CastRisingSunKickAction, "rising sun kick");
MELEE_ACTION(CastFistsOfFuryAction, "fists of fury");
MELEE_ACTION(CastSpearHandStrikeAction, "spear hand strike");
SPELL_ACTION(CastSpinningCraneKickAction, "spinning crane kick");
BUFF_ACTION(CastFortifyingBrewAction, "fortifying brew");
BUFF_ACTION(CastEnergizingBrewAction, "energizing brew");
class CastTigereyeBrewAction : public CastBuffSpellAction
{
public:
    CastTigereyeBrewAction(PlayerbotAI* ai) : CastBuffSpellAction(ai, "tigereye brew") { }
    bool isUseful() override
    {
        if (!botAI->IsGroupPveActivity())
            return CastBuffSpellAction::isUseful();
        Aura* stacks = bot->GetAura(125195);
        // Saved stacks share the damage buff's name, but are not an active buff.
        return bot->IsInCombat() && stacks && stacks->GetStackAmount() >= 10 &&
            !bot->HasAura(116740) && CastSpellAction::isUseful();
    }
};
HEAL_ACTION(CastExpelHarmAction, "expel harm");

// Brewmaster actions.
MELEE_ACTION(CastKegSmashAction, "keg smash");
SPELL_ACTION(CastDizzyingHazeAction, "dizzying haze");
SPELL_ACTION(CastProvokeAction, "provoke");
BUFF_ACTION(CastGuardAction, "guard");
BUFF_ACTION(CastElusiveBrewAction, "elusive brew");
BUFF_ACTION(CastPurifyingBrewAction, "purifying brew");

// Mistweaver actions. HealPartyMemberAction chooses the party member with the
// lowest useful health instead of requiring a player-selected target.
HEAL_PARTY_ACTION(CastSoothingMistOnPartyAction, "soothing mist", 20.0f, HealingManaEfficiency::VERY_HIGH);
HEAL_PARTY_ACTION(CastSurgingMistOnPartyAction, "surging mist", 35.0f, HealingManaEfficiency::LOW);
HEAL_PARTY_ACTION(CastEnvelopingMistOnPartyAction, "enveloping mist", 35.0f, HealingManaEfficiency::MEDIUM);
HEAL_PARTY_ACTION(CastRenewingMistOnPartyAction, "renewing mist", 15.0f, HealingManaEfficiency::VERY_HIGH);
HEAL_PARTY_ACTION(CastLifeCocoonOnPartyAction, "life cocoon", 45.0f, HealingManaEfficiency::HIGH);
BUFF_ACTION(CastUpliftAction, "uplift");
BUFF_ACTION(CastRevivalAction, "revival");
BUFF_ACTION(CastThunderFocusTeaAction, "thunder focus tea");
BUFF_ACTION(CastManaTeaAction, "mana tea");

// Utility shared by all Monk specializations (magic dispel only succeeds for
// Mistweaver, as dictated by the learned 5.4.8 Detox spell).
CURE_ACTION(CastDetoxAction, "detox");
CURE_PARTY_ACTION(CastDetoxPoisonOnPartyAction, "detox", DISPEL_POISON);
CURE_PARTY_ACTION(CastDetoxDiseaseOnPartyAction, "detox", DISPEL_DISEASE);
CURE_PARTY_ACTION(CastDetoxMagicOnPartyAction, "detox", DISPEL_MAGIC);
RESS_ACTION(CastResuscitateAction, "resuscitate");
BUFF_ACTION(CastLegacyOfTheEmperorAction, "legacy of the emperor");
BUFF_ACTION(CastLegacyOfTheWhiteTigerAction, "legacy of the white tiger");

class CastLegacyOfTheEmperorOnPartyAction : public BuffOnPartyAction
{
public:
    CastLegacyOfTheEmperorOnPartyAction(PlayerbotAI* botAI)
        : BuffOnPartyAction(botAI, "legacy of the emperor")
    {
    }

    Value<Unit*>* GetTargetValue() override
    {
        return context->GetValue<Unit*>("party member without aura", MonkBuffs::StatBuffs());
    }
};

class CastLegacyOfTheWhiteTigerOnPartyAction : public BuffOnPartyAction
{
public:
    CastLegacyOfTheWhiteTigerOnPartyAction(PlayerbotAI* botAI)
        : BuffOnPartyAction(botAI, "legacy of the white tiger")
    {
    }

    Value<Unit*>* GetTargetValue() override
    {
        return context->GetValue<Unit*>("party member without aura", MonkBuffs::CriticalStrikeBuffs());
    }
};

#endif
