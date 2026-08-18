/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_MONKBUFFS_H
#define _PLAYERBOT_MONKBUFFS_H

namespace MonkBuffs
{
// These qualifiers are consumed by PartyMemberWithoutAuraValue.  The world
// database spell groups contain every equivalent MoP raid buff, including
// triggered aura variants.  Player-only selection avoids repeatedly trying
// to apply a raid buff directly to a controlled pet which does not retain it.
inline char const* StatBuffs()
{
    return "player spell group:1118";
}

inline char const* CriticalStrikeBuffs()
{
    return "player spell group:1141";
}
}

#endif
