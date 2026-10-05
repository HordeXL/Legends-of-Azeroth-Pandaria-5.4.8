#!/usr/bin/env python3
"""Compile production eulogy callbacks against a minimal player fixture."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/scripts/Pandaria/zone_dread_wastes.cpp').read_text()
code = source[source.index('struct npc_chen_evie_eulogy'):source.index('// Han Stormstout (31078)')].replace(' override', '')
fixture = r'''
#include <cassert>
#include <map>
#include <vector>
#include <cstdint>
using uint32 = uint32_t; using uint8 = uint8_t; using ObjectGuid = int;
enum { QUEST_STATUS_INCOMPLETE = 1 };
struct Player;
struct Unit { virtual Player* ToPlayer() { return nullptr; } };
struct Player : Unit {
    int id, status = 1, meet = 0, complete = 0;
    bool alive = true, online = true, los = true;
    float distance = 0;
    std::vector<int> lines;
    explicit Player(int guid) : id(guid) {}
    Player* ToPlayer() override { return this; }
    bool IsAlive() { return alive; }
    int GetQuestStatus(int) { return status; }
    int GetGUID() { return id; }
    void KilledMonsterCredit(int entry) {
        if (entry == 65408) ++meet;
        else { assert(entry == 62964); ++complete; status = 2; }
    }
};
struct Creature {
    bool IsWithinDistInMap(Player* p, float dist) { return p->distance <= dist; }
    bool IsWithinLOSInMap(Player* p) { return p->los; }
    void Whisper(int text, Player* p) { p->lines.push_back(text); }
};
struct ScriptedAI { Creature* me; explicit ScriptedAI(Creature* c) : me(c) {} };
namespace ObjectAccessor {
    std::map<int, Player*> players;
    Player* GetPlayer(Creature&, int id) {
        auto it = players.find(id);
        return it != players.end() && it->second->online ? it->second : nullptr;
    }
}
// SCRIPT
int main() {
    Creature chen; Unit bot;
    npc_chen_evie_eulogy ai(&chen);
    Player a(1), b(2);
    ObjectAccessor::players = {{1, &a}, {2, &b}};
    ai.MoveInLineOfSight(&bot);
    a.status = 0; ai.MoveInLineOfSight(&a); assert(a.meet == 0);
    a.status = 1; a.los = false; ai.MoveInLineOfSight(&a); assert(a.meet == 0);
    a.los = true; a.distance = 11; ai.MoveInLineOfSight(&a); assert(a.meet == 0);
    a.distance = 0; ai.MoveInLineOfSight(&a); ai.MoveInLineOfSight(&a);
    assert(a.meet == 1);
    ai.UpdateAI(1000); assert(a.lines.size() == 1 && a.complete == 0);
    ai.MoveInLineOfSight(&b);
    for (int i = 0; i < 4; ++i) ai.UpdateAI(5000);
    assert(a.lines.size() == 5 && a.complete == 0 && b.lines.size() == 4);
    ai.UpdateAI(5000); assert(a.complete == 1 && b.complete == 0);
    ai.UpdateAI(5000); assert(b.complete == 1);
    assert(a.lines == std::vector<int>({62392,62393,62394,62395,62396}));
    ai.MoveInLineOfSight(&a); ai.UpdateAI(60000); assert(a.complete == 1);
    for (int failure = 0; failure < 4; ++failure) {
        Player p(3); ObjectAccessor::players[3] = &p;
        ai.MoveInLineOfSight(&p);
        if (failure == 0) p.distance = 21;
        if (failure == 1) p.alive = false;
        if (failure == 2) p.online = false;
        if (failure == 3) p.status = 0;
        ai.UpdateAI(60000); assert(p.complete == 0 && ai.listeners.empty());
        p.distance = 0; p.alive = p.online = true; p.status = 1;
        ai.MoveInLineOfSight(&p); assert(ai.listeners.size() == 1);
        ai.Reset(); assert(ai.listeners.empty());
    }
}
'''
with tempfile.TemporaryDirectory(prefix='evie-test-') as directory:
    cpp = Path(directory) / 'test.cpp'
    binary = Path(directory) / 'test'
    cpp.write_text(fixture.replace('// SCRIPT', code))
    subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
print('PASS: quest gates, duplicate proximity, timed dialogue, separate players, cancellation and retry')
