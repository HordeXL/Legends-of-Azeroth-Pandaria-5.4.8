#ifndef PLAYERBOT_AHNQIRAJ_POLICY_H
#define PLAYERBOT_AHNQIRAJ_POLICY_H

#include <cmath>
#include <algorithm>

namespace AhnQirajPolicy
{
constexpr unsigned MapId = 531;
constexpr unsigned Veknilash = 15275, Veklor = 15276;
constexpr unsigned Eye = 15589, Body = 15809, Flesh = 15802;
constexpr unsigned Acid = 26476;
constexpr float Pi = 3.14159265358979323846f;

inline float AngleDelta(float angle)
{
    return std::atan2(std::sin(angle), std::cos(angle));
}

// The local script rotates Dark Glare by pi/35 every second. Keep a wide
// margin ahead of its next tick; walk around the eye, never through it.
inline bool NeedsGlareDodge(float bearing, float facing)
{
    return std::fabs(AngleDelta(bearing - facing)) < Pi * 0.45f;
}

inline float GlareStep(float bearing, float facing)
{
    float const delta = AngleDelta(bearing - facing);
    return bearing + (delta < 0.0f ? -0.35f : 0.35f);
}

inline bool LeaveStomach(unsigned acidStacks, float healthPct, bool hasTentacle)
{
    return acidStacks >= 8 || healthPct < 35.0f || !hasTentacle;
}

// Roles are split separately, so both sides get tanks, healers and casters.
// The roster rank includes dead members to avoid swapping sides on a death.
struct Slot { float radius; float angle; };
inline Slot SpreadSlot(unsigned rank)
{
    return rank < 16 ? Slot{30.0f, 2.0f * Pi * rank / 16.0f} :
        Slot{44.0f, 2.0f * Pi * (rank - 16) / 24.0f + Pi / 24.0f};
}

constexpr float SpreadTolerance = 0.5f;

inline unsigned Side(unsigned roleRank) { return roleRank % 2; }
// Stationary emperors: send all magic/physical DPS to the matching boss.
// Tanks and healers still split between the two platforms.
inline unsigned TwinSide(unsigned role, unsigned roleRank)
{
    return role == 2 ? 1u : role == 3 ? 0u : Side(roleRank);
}
inline bool CanDamageTwin(bool magic, unsigned entry)
{
    return magic ? entry == Veklor : entry == Veknilash;
}
}
#endif
