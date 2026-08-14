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
MELEE_ACTION(CastTigerPalmAction, "tiger palm");
MELEE_ACTION(CastBlackoutKickAction, "blackout kick");
MELEE_ACTION(CastRisingSunKickAction, "rising sun kick");
MELEE_ACTION(CastFistsOfFuryAction, "fists of fury");
MELEE_ACTION(CastSpearHandStrikeAction, "spear hand strike");
SPELL_ACTION(CastSpinningCraneKickAction, "spinning crane kick");
BUFF_ACTION(CastFortifyingBrewAction, "fortifying brew");
BUFF_ACTION(CastEnergizingBrewAction, "energizing brew");
BUFF_ACTION(CastTigereyeBrewAction, "tigereye brew");
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
