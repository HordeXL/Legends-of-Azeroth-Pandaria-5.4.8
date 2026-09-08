#ifndef PLAYERBOT_SHAMAN_TOTEM_SUPPORT_H
#define PLAYERBOT_SHAMAN_TOTEM_SUPPORT_H
#include <string>
class Player;
class PlayerbotAI;
namespace ShamanTotemSupport
{
bool IsWaterAction(std::string const& action);
bool HasProtectedWaterTotem(Player* bot);
bool CanPlaceWaterTotem(Player* bot, std::string const& action);
bool NeedsWaterTotem(PlayerbotAI* ai, Player* bot);
bool CanRecallTotems(PlayerbotAI* ai, Player* bot);
}
#endif
