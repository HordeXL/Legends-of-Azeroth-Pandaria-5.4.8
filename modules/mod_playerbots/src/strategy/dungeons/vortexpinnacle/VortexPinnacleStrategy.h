/*
 * Playerbot strategy for The Vortex Pinnacle (normal and heroic).
 */

#ifndef _PLAYERBOT_VORTEX_PINNACLE_STRATEGY_H
#define _PLAYERBOT_VORTEX_PINNACLE_STRATEGY_H

#include "AttackActions.h"
#include "MovementActions.h"
#include "Multiplier.h"
#include "NamedObjectContext.h"
#include "Strategy.h"
#include "Trigger.h"

namespace VortexPinnacleBot
{
enum Ids : uint32
{
    MAP_VORTEX_PINNACLE          = 657,

    NPC_GRAND_VIZIER_ERTAN       = 43878,
    NPC_ALTAIRUS                 = 43873,
    NPC_ASAAD                    = 43875,
    NPC_LURKING_TEMPEST          = 45704,
    NPC_TEMPLE_ADEPT             = 45935,
    NPC_MINISTER_OF_AIR          = 45930,
    NPC_YOUNG_STORM_DRAGON       = 45919,
    NPC_HOWLING_GALE             = 45572,
    NPC_TWISTER                  = 47342,
    NPC_AIR_CURRENT              = 47305,
    NPC_UNSTABLE_GROUNDING_FIELD = 46492,
    NPC_SKYFALL_STAR             = 52019,

    SPELL_DOWNWIND_OF_ALTAIRUS   = 88286,
    SPELL_UPWIND_OF_ALTAIRUS     = 88282,
    SPELL_STATIC_CLING           = 87618
};

class VortexPinnacleStrategy : public Strategy
{
public:
    explicit VortexPinnacleStrategy(PlayerbotAI* ai) : Strategy(ai) { }
    std::string const getName() override { return "cata-vp"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
    void InitMultipliers(std::vector<Multiplier*>& multipliers) override;
};

class ErtanSafeRingTrigger : public Trigger
{
public:
    explicit ErtanSafeRingTrigger(PlayerbotAI* ai) : Trigger(ai, "vp ertan safe ring") { }
    bool IsActive() override;
};

class LurkingTempestTrigger : public Trigger
{
public:
    explicit LurkingTempestTrigger(PlayerbotAI* ai) : Trigger(ai, "vp face lurking tempest") { }
    bool IsActive() override;
};

class AltairusUpwindTrigger : public Trigger
{
public:
    explicit AltairusUpwindTrigger(PlayerbotAI* ai) : Trigger(ai, "vp altairus upwind") { }
    bool IsActive() override;
};

class AltairusTwisterTrigger : public Trigger
{
public:
    explicit AltairusTwisterTrigger(PlayerbotAI* ai) : Trigger(ai, "vp avoid twister") { }
    bool IsActive() override;
};

class AsaadGroundingFieldTrigger : public Trigger
{
public:
    explicit AsaadGroundingFieldTrigger(PlayerbotAI* ai) : Trigger(ai, "vp asaad grounding field") { }
    bool IsActive() override;
};

class AsaadStaticClingTrigger : public Trigger
{
public:
    explicit AsaadStaticClingTrigger(PlayerbotAI* ai) : Trigger(ai, "vp asaad static cling") { }
    bool IsActive() override;
};

class PriorityTargetTrigger : public Trigger
{
public:
    explicit PriorityTargetTrigger(PlayerbotAI* ai) : Trigger(ai, "vp priority target") { }
    bool IsActive() override;
};

class MoveInsideErtanRingAction : public MovementAction
{
public:
    explicit MoveInsideErtanRingAction(PlayerbotAI* ai) : MovementAction(ai, "vp move inside ertan ring") { }
    bool Execute(Event event) override;
};

class FaceLurkingTempestAction : public Action
{
public:
    explicit FaceLurkingTempestAction(PlayerbotAI* ai) : Action(ai, "vp face lurking tempest") { }
    bool Execute(Event event) override;
};

class FaceAltairusWindAction : public Action
{
public:
    explicit FaceAltairusWindAction(PlayerbotAI* ai) : Action(ai, "vp face altairus wind") { }
    bool Execute(Event event) override;
};

class AvoidAltairusTwisterAction : public MovementAction
{
public:
    explicit AvoidAltairusTwisterAction(PlayerbotAI* ai) : MovementAction(ai, "vp avoid twister") { }
    bool Execute(Event event) override;
};

class MoveToAsaadGroundingFieldAction : public MovementAction
{
public:
    explicit MoveToAsaadGroundingFieldAction(PlayerbotAI* ai) : MovementAction(ai, "vp move to asaad grounding field") { }
    bool Execute(Event event) override;
};

class JumpStaticClingAction : public MovementAction
{
public:
    explicit JumpStaticClingAction(PlayerbotAI* ai) : MovementAction(ai, "vp jump static cling") { }
    bool Execute(Event event) override;
};

class AttackPriorityTargetAction : public AttackAction
{
public:
    explicit AttackPriorityTargetAction(PlayerbotAI* ai) : AttackAction(ai, "vp attack priority target") { }
    bool Execute(Event event) override;
};

class VortexPinnacleMultiplier : public Multiplier
{
public:
    explicit VortexPinnacleMultiplier(PlayerbotAI* ai) : Multiplier(ai, "vortex pinnacle mechanics") { }
    float GetValue(Action* action) override;
};

class VortexPinnacleStrategyContext : public NamedObjectContext<Strategy>
{
public:
    VortexPinnacleStrategyContext()
    {
        creators["cata-vp"] = [](PlayerbotAI* ai) -> Strategy* { return new VortexPinnacleStrategy(ai); };
    }
};

class VortexPinnacleTriggerContext : public NamedObjectContext<Trigger>
{
public:
    VortexPinnacleTriggerContext();
};

class VortexPinnacleActionContext : public NamedObjectContext<Action>
{
public:
    VortexPinnacleActionContext();
};
}

#endif
