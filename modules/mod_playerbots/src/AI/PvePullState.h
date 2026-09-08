#ifndef PLAYERBOT_PVE_PULL_STATE_H
#define PLAYERBOT_PVE_PULL_STATE_H
#include <algorithm>
#include <cstdint>
#include <vector>

// One clock for the engaged pack. Target/pet changes do not restart it.
template<class Key> class PvePullState
{
public:
    void Observe(std::uint32_t now, std::vector<Key> const& engaged)
    {
        bool overlap = false;
        for (Key const& key : engaged)
            if (std::find(enemies.begin(), enemies.end(), key) != enemies.end())
                overlap = true;
        if (engaged.empty()) { active = false; enemies.clear(); focus = Key{}; return; }
        if (!active || !overlap) { started = now; focus = engaged.front(); }
        if (std::find(engaged.begin(), engaged.end(), focus) == engaged.end())
            focus = engaged.front();
        enemies = engaged;
        active = true;
    }
    bool Ready(std::uint32_t now) const { return active && std::uint32_t(now - started) >= 3000u; }
    Key OpeningTarget(std::uint32_t now) const { return active && !Ready(now) ? focus : Key{}; }
private:
    std::vector<Key> enemies;
    Key focus{};
    std::uint32_t started = 0;
    bool active = false;
};
#endif
