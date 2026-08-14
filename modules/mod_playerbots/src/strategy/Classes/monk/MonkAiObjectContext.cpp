/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "MonkAiObjectContext.h"

#include "GenericTriggers.h"
#include "MonkActions.h"
#include "MonkStrategies.h"
#include "NamedObjectContext.h"
#include "Playerbots.h"

class MonkStrategyFactoryInternal : public NamedObjectContext<Strategy>
{
public:
    MonkStrategyFactoryInternal()
    {
        creators["nc"] = &MonkStrategyFactoryInternal::nc;
        creators["cure"] = &MonkStrategyFactoryInternal::cure;
    }

private:
    static Strategy* nc(PlayerbotAI* botAI) { return new MonkNonCombatStrategy(botAI); }
    static Strategy* cure(PlayerbotAI* botAI) { return new MonkCureStrategy(botAI); }
};

class MonkCombatStrategyFactoryInternal : public NamedObjectContext<Strategy>
{
public:
    MonkCombatStrategyFactoryInternal() : NamedObjectContext<Strategy>(false, true)
    {
        creators["brewmaster"] = &MonkCombatStrategyFactoryInternal::brewmaster;
        creators["mistweaver"] = &MonkCombatStrategyFactoryInternal::mistweaver;
        creators["windwalker"] = &MonkCombatStrategyFactoryInternal::windwalker;
    }

private:
    static Strategy* brewmaster(PlayerbotAI* botAI) { return new BrewmasterMonkStrategy(botAI); }
    static Strategy* mistweaver(PlayerbotAI* botAI) { return new MistweaverMonkStrategy(botAI); }
    static Strategy* windwalker(PlayerbotAI* botAI) { return new WindwalkerMonkStrategy(botAI); }
};

class MonkTriggerFactoryInternal : public NamedObjectContext<Trigger>
{
public:
    MonkTriggerFactoryInternal()
    {
        creators["spear hand strike"] = &MonkTriggerFactoryInternal::spear_hand_strike;
        creators["legacy of the emperor on party"] = &MonkTriggerFactoryInternal::legacy_emperor_party;
        creators["legacy of the white tiger on party"] = &MonkTriggerFactoryInternal::legacy_tiger_party;
    }

private:
    static Trigger* spear_hand_strike(PlayerbotAI* botAI)
    {
        return new InterruptSpellTrigger(botAI, "spear hand strike");
    }
    static Trigger* legacy_emperor_party(PlayerbotAI* botAI)
    {
        return new BuffOnPartyTrigger(botAI, "legacy of the emperor");
    }
    static Trigger* legacy_tiger_party(PlayerbotAI* botAI)
    {
        return new BuffOnPartyTrigger(botAI, "legacy of the white tiger");
    }
};

class MonkActionContextInternal : public NamedObjectContext<Action>
{
public:
    MonkActionContextInternal()
    {
        creators["stance of the fierce tiger"] = &MonkActionContextInternal::fierce_tiger_stance;
        creators["stance of the sturdy ox"] = &MonkActionContextInternal::sturdy_ox_stance;
        creators["stance of the wise serpent"] = &MonkActionContextInternal::wise_serpent_stance;
        creators["jab"] = &MonkActionContextInternal::jab;
        creators["tiger palm"] = &MonkActionContextInternal::tiger_palm;
        creators["blackout kick"] = &MonkActionContextInternal::blackout_kick;
        creators["rising sun kick"] = &MonkActionContextInternal::rising_sun_kick;
        creators["fists of fury"] = &MonkActionContextInternal::fists_of_fury;
        creators["spear hand strike"] = &MonkActionContextInternal::spear_hand_strike;
        creators["spinning crane kick"] = &MonkActionContextInternal::spinning_crane_kick;
        creators["fortifying brew"] = &MonkActionContextInternal::fortifying_brew;
        creators["energizing brew"] = &MonkActionContextInternal::energizing_brew;
        creators["tigereye brew"] = &MonkActionContextInternal::tigereye_brew;
        creators["expel harm"] = &MonkActionContextInternal::expel_harm;
        creators["keg smash"] = &MonkActionContextInternal::keg_smash;
        creators["dizzying haze"] = &MonkActionContextInternal::dizzying_haze;
        creators["provoke"] = &MonkActionContextInternal::provoke;
        creators["guard"] = &MonkActionContextInternal::guard;
        creators["elusive brew"] = &MonkActionContextInternal::elusive_brew;
        creators["purifying brew"] = &MonkActionContextInternal::purifying_brew;
        creators["soothing mist on party"] = &MonkActionContextInternal::soothing_mist_party;
        creators["surging mist on party"] = &MonkActionContextInternal::surging_mist_party;
        creators["enveloping mist on party"] = &MonkActionContextInternal::enveloping_mist_party;
        creators["renewing mist on party"] = &MonkActionContextInternal::renewing_mist_party;
        creators["life cocoon on party"] = &MonkActionContextInternal::life_cocoon_party;
        creators["mana tea"] = &MonkActionContextInternal::mana_tea;
        creators["detox"] = &MonkActionContextInternal::detox;
        creators["detox poison on party"] = &MonkActionContextInternal::detox_poison_party;
        creators["detox disease on party"] = &MonkActionContextInternal::detox_disease_party;
        creators["detox magic on party"] = &MonkActionContextInternal::detox_magic_party;
        creators["resuscitate"] = &MonkActionContextInternal::resuscitate;
        creators["legacy of the emperor"] = &MonkActionContextInternal::legacy_emperor;
        creators["legacy of the emperor on party"] = &MonkActionContextInternal::legacy_emperor_party;
        creators["legacy of the white tiger"] = &MonkActionContextInternal::legacy_tiger;
        creators["legacy of the white tiger on party"] = &MonkActionContextInternal::legacy_tiger_party;
    }

private:
    static Action* fierce_tiger_stance(PlayerbotAI* ai) { return new CastStanceOfTheFierceTigerAction(ai); }
    static Action* sturdy_ox_stance(PlayerbotAI* ai) { return new CastStanceOfTheSturdyOxAction(ai); }
    static Action* wise_serpent_stance(PlayerbotAI* ai) { return new CastStanceOfTheWiseSerpentAction(ai); }
    static Action* jab(PlayerbotAI* ai) { return new CastJabAction(ai); }
    static Action* tiger_palm(PlayerbotAI* ai) { return new CastTigerPalmAction(ai); }
    static Action* blackout_kick(PlayerbotAI* ai) { return new CastBlackoutKickAction(ai); }
    static Action* rising_sun_kick(PlayerbotAI* ai) { return new CastRisingSunKickAction(ai); }
    static Action* fists_of_fury(PlayerbotAI* ai) { return new CastFistsOfFuryAction(ai); }
    static Action* spear_hand_strike(PlayerbotAI* ai) { return new CastSpearHandStrikeAction(ai); }
    static Action* spinning_crane_kick(PlayerbotAI* ai) { return new CastSpinningCraneKickAction(ai); }
    static Action* fortifying_brew(PlayerbotAI* ai) { return new CastFortifyingBrewAction(ai); }
    static Action* energizing_brew(PlayerbotAI* ai) { return new CastEnergizingBrewAction(ai); }
    static Action* tigereye_brew(PlayerbotAI* ai) { return new CastTigereyeBrewAction(ai); }
    static Action* expel_harm(PlayerbotAI* ai) { return new CastExpelHarmAction(ai); }
    static Action* keg_smash(PlayerbotAI* ai) { return new CastKegSmashAction(ai); }
    static Action* dizzying_haze(PlayerbotAI* ai) { return new CastDizzyingHazeAction(ai); }
    static Action* provoke(PlayerbotAI* ai) { return new CastProvokeAction(ai); }
    static Action* guard(PlayerbotAI* ai) { return new CastGuardAction(ai); }
    static Action* elusive_brew(PlayerbotAI* ai) { return new CastElusiveBrewAction(ai); }
    static Action* purifying_brew(PlayerbotAI* ai) { return new CastPurifyingBrewAction(ai); }
    static Action* soothing_mist_party(PlayerbotAI* ai) { return new CastSoothingMistOnPartyAction(ai); }
    static Action* surging_mist_party(PlayerbotAI* ai) { return new CastSurgingMistOnPartyAction(ai); }
    static Action* enveloping_mist_party(PlayerbotAI* ai) { return new CastEnvelopingMistOnPartyAction(ai); }
    static Action* renewing_mist_party(PlayerbotAI* ai) { return new CastRenewingMistOnPartyAction(ai); }
    static Action* life_cocoon_party(PlayerbotAI* ai) { return new CastLifeCocoonOnPartyAction(ai); }
    static Action* mana_tea(PlayerbotAI* ai) { return new CastManaTeaAction(ai); }
    static Action* detox(PlayerbotAI* ai) { return new CastDetoxAction(ai); }
    static Action* detox_poison_party(PlayerbotAI* ai) { return new CastDetoxPoisonOnPartyAction(ai); }
    static Action* detox_disease_party(PlayerbotAI* ai) { return new CastDetoxDiseaseOnPartyAction(ai); }
    static Action* detox_magic_party(PlayerbotAI* ai) { return new CastDetoxMagicOnPartyAction(ai); }
    static Action* resuscitate(PlayerbotAI* ai) { return new CastResuscitateAction(ai); }
    static Action* legacy_emperor(PlayerbotAI* ai) { return new CastLegacyOfTheEmperorAction(ai); }
    static Action* legacy_emperor_party(PlayerbotAI* ai) { return new CastLegacyOfTheEmperorOnPartyAction(ai); }
    static Action* legacy_tiger(PlayerbotAI* ai) { return new CastLegacyOfTheWhiteTigerAction(ai); }
    static Action* legacy_tiger_party(PlayerbotAI* ai) { return new CastLegacyOfTheWhiteTigerOnPartyAction(ai); }
};

MonkAiObjectContext::MonkAiObjectContext(PlayerbotAI* botAI) : AiObjectContext(botAI)
{
    strategyContexts.Add(new MonkStrategyFactoryInternal());
    strategyContexts.Add(new MonkCombatStrategyFactoryInternal());
    actionContexts.Add(new MonkActionContextInternal());
    triggerContexts.Add(new MonkTriggerFactoryInternal());
}
