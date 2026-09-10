#include "AffliWarlockStrategy.h"
#include "Playerbots.h"
#include "CombatAssistant.h"

class AfflictionRotationMultiplier : public Multiplier
{
public:
    AfflictionRotationMultiplier(PlayerbotAI* botAI) : Multiplier(botAI, "affliction rotation") {}
    float GetValue(Action* action) override
    {
        if (!UsesAfflictionBotRotation(botAI)) return 1.0f;
        // Old ST, AoE and health/mana triggers can remain in a cached engine
        // after entering PvE. They must not spend shards or overwrite DoTs
        // independently of the shared selector. Movement, pets, encounter
        // mechanics and the group interrupt coordinator keep their priority.
        std::string const name = action->getName();
        for (char const* legacy : {"corruption", "corruption on attacker", "agony", "agony on attacker",
            "unstable affliction", "unstable affliction on attacker", "haunt", "malefic grasp",
            "drain soul", "fel flame", "shadow bolt", "shoot", "seed of corruption",
            "seed of corruption on attacker", "rain of fire", "soul burn", "dark soul: misery",
            "life tap", "drain life", "dark bargain", "twilight ward", "sacrificial pact",
            "unending resolve", "dark regeneration", "curse of the elements", "curse of enfeeblement",
            "mannoroth's fury", "immolation aura", "shadowfury", "summon abyssal"})
            if (name == legacy) return 0.0f;
        return 1.0f;
    }
};

class AffliWarlockStrategyActionNodeFactory : public NamedObjectFactory<ActionNode>
{
public:
    AffliWarlockStrategyActionNodeFactory()
    {
        creators["affliction rotation"] = &affliction_rotation;
        creators["dark soul: misery"] = &dark_soul;
        creators["malefic grasp"] = &malefic_grasp;
        creators["agony"] = &agony;
        creators["drain soul"] = &drain_soul;
        creators["haunt"] = &haunt;
        creators["unstable affliction"] = &unstable_affliction;
        creators["unstable affliction on attacker"] = &unstable_affliction_on_attacker;
        creators["seed of corruption"] = &seed_of_corruption;
    }

private:
    ACTION_NODE(affliction_rotation, "affliction rotation");
    ACTION_NODE(dark_soul, "dark soul: misery");
    ACTION_NODE_A(malefic_grasp, "malefic grasp", "shadow bolt");
    ACTION_NODE(agony, "agony");
    ACTION_NODE_P(drain_soul, "drain soul", "corruption");
    ACTION_NODE(haunt, "haunt");
    ACTION_NODE(unstable_affliction, "unstable affliction");
    ACTION_NODE(unstable_affliction_on_attacker, "unstable affliction on attacker");
    ACTION_NODE(seed_of_corruption, "seed of corruption");
};

AffliWarlockStrategy::AffliWarlockStrategy(PlayerbotAI* botAI) : GenericWarlockStrategy(botAI)
{
    actionNodeFactories.Add(new AffliWarlockStrategyActionNodeFactory());
}

NextAction** AffliWarlockStrategy::getDefaultActions()
{
    if (botAI->IsGroupPveActivity())
        return NextAction::array(0, new NextAction("affliction rotation", ACTION_NORMAL + 1), nullptr);
    return NextAction::array(0,
        new NextAction("dark soul: misery", ACTION_DEFAULT + 0.5f),
        new NextAction("haunt", ACTION_DEFAULT + 0.4f),
        new NextAction("fel flame", 3.0f),
        new NextAction("malefic grasp", ACTION_HIGH),
        nullptr);
}

void AffliWarlockStrategy::InitMultipliers(std::vector<Multiplier*>& multipliers)
{
    multipliers.push_back(new AfflictionRotationMultiplier(botAI));
}

void AffliWarlockStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    GenericWarlockStrategy::InitTriggers(triggers);

    triggers.push_back(new TriggerNode("corruption", NextAction::array(0, new NextAction("corruption", 20.0f), nullptr)));
    triggers.push_back(new TriggerNode("agony", NextAction::array(0, new NextAction("agony", 20.0f), nullptr)));
    triggers.push_back(new TriggerNode("unstable affliction", NextAction::array(0, new NextAction("unstable affliction", 20.0f), nullptr)));

    triggers.push_back(new TriggerNode("target critical health", NextAction::array(0, new NextAction("drain soul", ACTION_HIGH + 20), nullptr)));
}

