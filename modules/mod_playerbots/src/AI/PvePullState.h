#ifndef PLAYERBOT_PVE_PULL_STATE_H
#define PLAYERBOT_PVE_PULL_STATE_H
#include <algorithm>
#include <cstdint>
#include <vector>

// One clock for the engaged pack. Target/pet changes do not restart it.
template<class Key> class PvePullState
{
public:
    void Observe(std::uint32_t now, std::vector<Key> const& engaged,
        std::uint32_t firstContact = 0)
    {
        bool overlap = false;
        for (Key const& key : engaged)
            if (std::find(enemies.begin(), enemies.end(), key) != enemies.end())
                overlap = true;
        if (engaged.empty()) { active = false; enemies.clear(); focus = Key{}; return; }
        // A staged world-boss raid begins spreading on first contact.  Keep
        // that contact as the pull epoch even if target acquisition briefly
        // disappears or changes while bots move into formation.  The normal
        // dungeon/LFG path supplies no explicit epoch and retains its current
        // pack-overlap behaviour.
        if (!active || !overlap)
        {
            started = firstContact ? firstContact : now;
            focus = engaged.front();
        }
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
