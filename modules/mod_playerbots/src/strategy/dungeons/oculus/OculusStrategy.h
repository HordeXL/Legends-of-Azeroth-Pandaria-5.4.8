/*
 * Oculus playerbot strategy, ported from mod-playerbots for the Pandaria
 * 5.4.8 playerbot API.
 */

#ifndef _PLAYERBOT_OCULUS_STRATEGY_H
#define _PLAYERBOT_OCULUS_STRATEGY_H

#include "Action.h"
#include "MovementActions.h"
#include "Multiplier.h"
#include "NamedObjectContext.h"
#include "Strategy.h"
#include "Trigger.h"

namespace OculusBot
{
enum Ids : uint32
{
    MAP_OCULUS                         = 578,

    NPC_UNSTABLE_SPHERE               = 28166,
    NPC_MAGE_LORD_UROM                = 27655,
    NPC_LEY_GUARDIAN_EREGOS           = 27656,
    NPC_AMBER_DRAKE                   = 27755,
    NPC_EMERALD_DRAKE                 = 27692,
    NPC_RUBY_DRAKE                    = 27756,

    ITEM_AMBER_ESSENCE                = 37859,
    ITEM_EMERALD_ESSENCE              = 37815,
    ITEM_RUBY_ESSENCE                 = 37860,

    SPELL_AMBER_ESSENCE               = 49461,
    SPELL_EMERALD_ESSENCE             = 49345,
    SPELL_RUBY_ESSENCE                = 49462,

    SPELL_SHOCK_LANCE                 = 49840,
    SPELL_SHOCK_CHARGE                = 49836,
    SPELL_STOP_TIME                   = 49838,
    SPELL_TEMPORAL_RIFT               = 49592,
    SPELL_LEECHING_POISON             = 50328,
    SPELL_TOUCH_THE_NIGHTMARE         = 50341,
    SPELL_DREAM_FUNNEL                = 50344,
    SPELL_SEARING_WRATH               = 50232,
    SPELL_EVASIVE_MANEUVERS           = 50240,
    SPELL_EVASIVE_CHARGES             = 50241,
    SPELL_MARTYR                      = 50253,

    SPELL_UROM_TIME_BOMB_NORMAL       = 51121,
    SPELL_UROM_TIME_BOMB_HEROIC       = 59376,
    SPELL_UROM_EXPLOSION_NORMAL       = 51110,
    SPELL_UROM_EXPLOSION_HEROIC       = 59377,
    SPELL_EREGOS_ENRAGED_ASSAULT      = 51170,
    SPELL_EREGOS_PLANAR_SHIFT         = 51162
};

bool IsDrake(Unit const* unit);

class OculusStrategy : public Strategy
{
public:
    explicit OculusStrategy(PlayerbotAI* ai) : Strategy(ai) { }
    std::string const getName() override { return "wotlk-occ"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
    void InitMultipliers(std::vector<Multiplier*>& multipliers) override;
};

class UnstableSphereTrigger : public Trigger
{
public:
    explicit UnstableSphereTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus unstable sphere") { }
    bool IsActive() override;
};

class DrakeMountTrigger : public Trigger
{
public:
    explicit DrakeMountTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus drake mount") { }
    bool IsActive() override;
};

class DrakeDismountTrigger : public Trigger
{
public:
    explicit DrakeDismountTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus drake dismount") { }
    bool IsActive() override;
};

class DrakeFlyTrigger : public Trigger
{
public:
    explicit DrakeFlyTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus drake fly") { }
    bool IsActive() override;
};

class DrakeCombatTrigger : public Trigger
{
public:
    explicit DrakeCombatTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus drake combat") { }
    bool IsActive() override;
};

class UromExplosionTrigger : public Trigger
{
public:
    explicit UromExplosionTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus urom explosion") { }
    bool IsActive() override;
};

class UromTimeBombTrigger : public Trigger
{
public:
    explicit UromTimeBombTrigger(PlayerbotAI* ai) : Trigger(ai, "oculus time bomb") { }
    bool IsActive() override;
};

class AvoidUnstableSphereAction : public MovementAction
{
public:
    explicit AvoidUnstableSphereAction(PlayerbotAI* ai) : MovementAction(ai, "oculus avoid unstable sphere") { }
    bool Execute(Event event) override;
};

class MountDrakeAction : public Action
{
public:
    explicit MountDrakeAction(PlayerbotAI* ai) : Action(ai, "oculus mount drake") { }
    bool Execute(Event event) override;
    bool isPossible() override;
};

class DismountDrakeAction : public Action
{
public:
    explicit DismountDrakeAction(PlayerbotAI* ai) : Action(ai, "oculus dismount drake") { }
    bool Execute(Event event) override;
};

class FlyDrakeAction : public MovementAction
{
public:
    explicit FlyDrakeAction(PlayerbotAI* ai) : MovementAction(ai, "oculus fly drake") { }
    bool Execute(Event event) override;
};

class DrakeAttackAction : public Action
{
public:
    explicit DrakeAttackAction(PlayerbotAI* ai) : Action(ai, "oculus drake attack") { }
    bool Execute(Event event) override;

private:
    Unit* SelectTarget();
    bool Cast(Unit* caster, Unit* target, uint32 spellId);
    bool Amber(Unit* drake, Unit* target);
    bool Emerald(Unit* drake, Unit* target);
    bool Ruby(Unit* drake, Unit* target);
};

class AvoidUromExplosionAction : public MovementAction
{
public:
    explicit AvoidUromExplosionAction(PlayerbotAI* ai) : MovementAction(ai, "oculus avoid urom explosion") { }
    bool Execute(Event event) override;
};

class SpreadTimeBombAction : public MovementAction
{
public:
    explicit SpreadTimeBombAction(PlayerbotAI* ai) : MovementAction(ai, "oculus spread time bomb") { }
    bool Execute(Event event) override;
};

class OculusMultiplier : public Multiplier
{
public:
    explicit OculusMultiplier(PlayerbotAI* ai) : Multiplier(ai, "oculus vehicle") { }
    float GetValue(Action* action) override;
};

class OculusStrategyContext : public NamedObjectContext<Strategy>
{
public:
    OculusStrategyContext() { creators["wotlk-occ"] = [](PlayerbotAI* ai) -> Strategy* { return new OculusStrategy(ai); }; }
};

class OculusTriggerContext : public NamedObjectContext<Trigger>
{
public:
    OculusTriggerContext();
};

class OculusActionContext : public NamedObjectContext<Action>
{
public:
    OculusActionContext();
};
}

#endif
