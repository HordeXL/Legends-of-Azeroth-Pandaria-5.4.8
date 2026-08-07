#pragma once

#include "Define.h"

class Player;

void AddSC_playerbots_commandscript();
void HandleSoloArenaClientLeave(Player* player);
void UpdateSoloArenaAutomaticExit(uint32 diff);
