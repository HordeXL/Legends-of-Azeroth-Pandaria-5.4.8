#ifndef PLAYERBOT_GROUP_PVE_COMBAT_H
#define PLAYERBOT_GROUP_PVE_COMBAT_H
class Player;
class Unit;
class GroupPveCombat
{
public:
    static bool IsEngaged(Player* player, Unit* target);
    static bool IsCollected(Player* player, Unit* target);
    static Unit* OpeningTarget(Player* player);
    static Unit* ActiveWorldBossTarget(Player* player);
    static bool AoeReady(Player* player, Unit* target);
    static bool DamageAllowed(Player* player, Unit* target);
    static bool NeedsRescue(Player* player, Unit* target);
    static Player* RescueTank(Player* player, Unit* target);
    static unsigned TauntSpell(Player* player);
};
#endif
