#!/usr/bin/env python3
"""Exercise the real C'Thun damage limiter independently of the bot planner."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/scripts/Kalimdor/TempleOfAhnQiraj/boss_cthun.cpp').read_text()
start = source.index('void ReduceCthunPlayerDamage(')
end = source.index('\n}\n}', start) + 2
for name in ('eye_of_cthunAI', 'cthunAI', 'eye_tentacleAI', 'claw_tentacleAI',
             'giant_claw_tentacleAI', 'giant_eye_tentacleAI', 'flesh_tentacleAI'):
    begin = source.index('struct ' + name + ' :')
    constructor = source.index(name + '(Creature*', begin)
    assert 'ReduceCthunPlayerDamage(victim, damage);' in source[begin:constructor], name

harness = r'''
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
using uint32 = uint32_t;
constexpr uint32 TYPEID_PLAYER = 4;
struct Unit {
    uint32 type, health;
    uint32 GetTypeId() const { return type; }
    uint32 CountPctFromMaxHealth(int percent) const { return uint32(uint64_t(health) * percent / 100); }
};
FUNCTION
int main() {
    for (uint32 hp : {1u, 100u, 6000u, 10000u, 500000u}) {
        Unit player{TYPEID_PLAYER, hp};
        for (uint32 original : {0u, 1u, 100u, 3000u, 50000u, UINT32_MAX}) {
            uint32 damage = original;
            ReduceCthunPlayerDamage(&player, damage);
            assert(damage <= original / 2);
            assert(damage <= player.CountPctFromMaxHealth(35));
            assert(damage < hp);
        }
    }
    Unit player{TYPEID_PLAYER, 10000};
    uint32 ordinary=2000;
    ReduceCthunPlayerDamage(&player, ordinary);
    assert(ordinary == 1000);
    uint32 glare=50000;
    ReduceCthunPlayerDamage(&player, glare);
    assert(glare == 3500 && 3 * glare >= player.health); // standing still is still lethal
    Unit creature{3,10000};
    uint32 unchanged=50000;
    ReduceCthunPlayerDamage(&creature, unchanged);
    assert(unchanged == 50000);
    ReduceCthunPlayerDamage(nullptr, unchanged);
    assert(unchanged == 50000);
    std::cout << "C'Thun damage limiter: 34 cases and 7 AI hooks passed\n";
}
'''
with tempfile.TemporaryDirectory(prefix='cthun-damage-') as directory:
    directory = Path(directory)
    (directory / 'test.cpp').write_text(harness.replace('FUNCTION', source[start:end]))
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    str(directory / 'test.cpp'), '-o', str(directory / 'test')], check=True)
    subprocess.run([str(directory / 'test')], check=True, timeout=10)
