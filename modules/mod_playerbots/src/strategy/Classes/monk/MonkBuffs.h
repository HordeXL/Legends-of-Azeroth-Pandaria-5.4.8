/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_MONKBUFFS_H
#define _PLAYERBOT_MONKBUFFS_H

namespace MonkBuffs
{
// These comma-separated qualifiers are consumed by
// PartyMemberWithoutAuraValue.  Include every equivalent MoP raid buff so a
// monk does not recast its legacy forever when another class or hunter pet
// already supplies the same non-stacking effect.
inline char const* StatBuffs()
{
    return "legacy of the emperor,blessing of kings,blessing of forgotten kings,mark of the wild,embrace of the shale spider";
}

inline char const* CriticalStrikeBuffs()
{
    return "legacy of the white tiger,arcane brilliance,dalaran brilliance,leader of the pack,furious howl,still water";
}
}

#endif
