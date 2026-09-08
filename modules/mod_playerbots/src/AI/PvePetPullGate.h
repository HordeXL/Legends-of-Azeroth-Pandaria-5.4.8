#ifndef _PLAYERBOT_PVE_PET_PULL_GATE_H
#define _PLAYERBOT_PVE_PET_PULL_GATE_H
#include <cstdint>

// Keys are GUIDs in production; this small state machine is independently testable.
template<class Key> class PvePetPullGate
{
public:
    void Reset() { pending = false; }
    bool Ready(std::uint32_t now, Key const& target, Key const& pet,
        bool ownerEngaged, bool tankCollected)
    {
        if (!ownerEngaged) { Reset(); return false; }
        if (!pending || target != targetKey || pet != petKey)
        {
            targetKey = target;
            petKey = pet;
            started = now;
            pending = true;
        }
        // Unsigned subtraction also handles the millisecond clock wrapping.
        return tankCollected && std::uint32_t(now - started) >= 4000u;
    }
private:
    Key targetKey{};
    Key petKey{};
    std::uint32_t started = 0;
    bool pending = false;
};
#endif
