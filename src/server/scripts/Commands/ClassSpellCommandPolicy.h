#ifndef CLASS_SPELL_COMMAND_POLICY_H
#define CLASS_SPELL_COMMAND_POLICY_H

#include <cstdint>

namespace ClassSpellCommandPolicy
{
    // Restore a normal class/spec spellbook without granting talents, spells
    // above the player's level, or abilities belonging only to another spec.
    inline bool Learn(std::uint32_t playerLevel, std::uint32_t spellLevel,
        bool talent, bool baseline, bool activeSpec, bool specializationSpell)
    {
        return !talent && spellLevel <= playerLevel && (baseline || activeSpec) &&
            (!specializationSpell || activeSpec);
    }

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
