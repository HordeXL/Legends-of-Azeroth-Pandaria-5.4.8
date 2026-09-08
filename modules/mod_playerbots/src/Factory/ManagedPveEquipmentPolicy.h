#ifndef PLAYERBOT_MANAGED_PVE_EQUIPMENT_POLICY_H
#define PLAYERBOT_MANAGED_PVE_EQUIPMENT_POLICY_H
#include <algorithm>
#include <cstdint>

namespace ManagedPveEquipmentPolicy
{
// Base ilvl, before upgrades. Both hands, caster off-hands and shields.
// Retain existing stronger weapons; do not change PvP or low-level gearing.
inline std::uint32_t WeaponFloor(std::uint32_t reference, std::uint32_t level,
    bool genuinePve)
{
    std::uint32_t const relative = reference > 35 ? reference - 35 : reference;
    return genuinePve && level >= 90 ? std::max(relative, 559u) : relative;
}

// Script-driven healing procs may not expose their trigger chain. These are
// proc driver IDs shared by all item difficulties, not an item-name blacklist.
inline bool IsHealingProc(std::uint32_t spell)
{
    switch (spell)
    {
        case 126590: // Qin-xi: heals -> Intellect
        case 126641: // Spirits of the Sun: heals -> Spirit
        case 138849: // Horridon's Last Gasp: heals -> mana
        case 138924: // Hydra-Spawn: heals -> absorb
        case 146315: // Prismatic Prison: healer-only Intellect
        case 146316: // Dysmorphic Samophlange: heals -> Spirit
            return true;
        default:
            return false;
    }
}
}
#endif
