#ifndef SPELL_POWER_VISUALS_H
#define SPELL_POWER_VISUALS_H

#include <array>
#include <cstdint>

class Player;

namespace SpellPowerVisuals
{
    enum class WarlockSpec { None, Affliction, Demonology, Destruction };
    // Each bit in the mask below corresponds to one existing client aura.
    constexpr std::array<std::uint32_t, 10> WarlockSpells = {
        104756, 104759, 123171, // Soul Shards: 1/3, 2/3/4, fourth
        123728, 123730, 123731, // Glyph of Verdant Spheres equivalents
        116855, 116920,        // Searing Embers, Cremation
        122738, 131755         // Master Demonologist, Maximum Fury
    };

    inline std::uint16_t WarlockMask(WarlockSpec spec, int shards, int embers, int fury, bool spheres)
    {
        std::uint16_t mask = 0;
        if (spec == WarlockSpec::Affliction || (spec == WarlockSpec::Destruction && spheres))
        {
            int count = spec == WarlockSpec::Affliction ? shards / 100 : embers / 10;
            if (count < 0) count = 0;
            if (count > 4) count = 4;
            // Four resources use the two-sphere model plus the fourth model.
            constexpr std::uint16_t counts[] = { 0, 1, 2, 3, 6 };
            mask = counts[count] << (spheres ? 3 : 0);
        }
        else if (spec == WarlockSpec::Destruction)
        {
            if (embers >= 20) mask |= 1u << 6;
            if (embers >= 30) mask |= 1u << 7;
        }
        else if (spec == WarlockSpec::Demonology)
        {
            if (fury >= 500) mask |= 1u << 8;
            if (fury >= 980) mask |= 1u << 9;
        }
        return mask;
    }

    void UpdateWarlock(Player* player);
    void UpdatePaladin(Player* player);
}

#endif
