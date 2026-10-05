#ifndef PLAYERBOT_MANAGED_PVE_EQUIPMENT_POLICY_H
#define PLAYERBOT_MANAGED_PVE_EQUIPMENT_POLICY_H
#include <algorithm>
#include <cstdint>
#include <limits>

namespace ManagedPveEquipmentPolicy
{
// Some later-expansion templates have RequiredLevel 0/1 in this database.
// Conservative leveling budgets also protect against those malformed templates.
// Expansion end levels allow raid gear; intermediate levels use leveling gear.
inline std::uint32_t MaximumItemLevel(std::uint32_t level, bool genuinePve)
{
    if (!genuinePve || level >= 90)
        return std::numeric_limits<std::uint32_t>::max();
    if (level < 60)
        return level + 15;
    if (level == 60)
        return 90;
    if (level < 70)
        return 105 + 3 * (level - 61);
    if (level < 80)
        return 164 + 6 * (level - 70);
    if (level == 80)
        return 284;
    if (level < 85)
        return 308 + 25 * (level - 81);
    return level == 85 ? 416u : 450u;
}

inline bool IsLevelAppropriate(std::uint32_t level, std::uint32_t itemLevel,
    std::uint32_t requiredLevel, bool genuinePve)
{
    return requiredLevel <= level &&
        itemLevel <= MaximumItemLevel(level, genuinePve);
}

// Base ilvl, before upgrades. Both hands, caster off-hands and shields.
// Retain existing stronger weapons; do not change PvP or low-level gearing.
inline std::uint32_t WeaponFloor(std::uint32_t reference, std::uint32_t level,
    bool genuinePve)
{
    reference = std::min(reference, MaximumItemLevel(level, genuinePve));
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
