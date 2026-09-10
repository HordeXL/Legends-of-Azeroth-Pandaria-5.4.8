#ifndef PLAYERBOTS_COMBAT_ASSISTANT_H
#define PLAYERBOTS_COMBAT_ASSISTANT_H

#include "ObjectGuid.h"

class PlayerbotAI;
class Unit;

// Owned by each bot action. Bot AI workers must not use the player addon's
// world-thread state map for projectile tracking or Life Tap health samples.
struct AfflictionRotationRuntime
{
    uint32 DamageWindowTimer = 0;
    float DamageWindowStartPct = 100.0f;
    float RecentDamagePct = 0.0f;
    ObjectGuid HauntTarget;
    uint32 HauntPendingTimer = 0;
    uint32 LastUpdate = 0;
};

bool UsesAfflictionBotRotation(PlayerbotAI* botAI);
bool RunAfflictionBotRotation(PlayerbotAI* botAI, Unit* target, AfflictionRotationRuntime& runtime);

void AddSC_playerbots_combat_assistant();

#endif
