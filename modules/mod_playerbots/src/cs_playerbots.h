#pragma once

#include "Define.h"

class Player;

void AddSC_playerbots_commandscript();
void HandleSoloArenaClientLeave(Player* player);
bool HandleSoloArenaAutomaticJoinRequest(Player* player, uint8 arenaSlot);
void UpdateSoloArenaAutomaticQueue(uint32 diff);
void UpdateSoloArenaAutomaticExit(uint32 diff);
