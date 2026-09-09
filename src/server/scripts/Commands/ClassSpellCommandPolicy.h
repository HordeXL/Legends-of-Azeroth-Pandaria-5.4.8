#ifndef CLASS_SPELL_COMMAND_POLICY_H
#define CLASS_SPELL_COMMAND_POLICY_H

#include <cstdint>

namespace ClassSpellCommandPolicy
{
    // DBC ownership is authoritative, including generic-family spells and
    // abilities shared by several classes. Family is only a fallback for
    // known internal/triggered class spells without an explicit owner.
    inline bool Select(std::uint32_t playerMask, std::uint32_t playerFamily,
        std::uint32_t spellFamily, std::uint32_t ownerMask, bool protectedSpell)
    {
        if (protectedSpell)
            return false;
        if (ownerMask)
            return (ownerMask & playerMask) != 0;
        return playerFamily != 0 && spellFamily == playerFamily;
    }
}

#endif
