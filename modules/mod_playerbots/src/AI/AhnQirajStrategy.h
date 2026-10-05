#ifndef PLAYERBOT_AHNQIRAJ_STRATEGY_H
#define PLAYERBOT_AHNQIRAJ_STRATEGY_H

#include "Common.h"
#include "Position.h"
class Player;
class Unit;

namespace AhnQirajStrategy
{
struct Plan
{
    Unit* target = nullptr;
    Position destination;
    bool move = false;
    bool emergency = false;
};

bool IsActive(Player* bot);
Plan BuildPlan(Player* bot);
bool AllowsTarget(Player* bot, Unit const* target);
}
#endif
