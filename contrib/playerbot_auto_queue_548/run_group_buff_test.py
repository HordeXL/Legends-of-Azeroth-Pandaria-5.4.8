#!/usr/bin/env python3
"""Compile the production raid-buff usefulness check against group fixtures."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'modules/mod_playerbots/src/strategy/actions/GenericSpellActions.cpp').read_text()
start = source.index('bool CastBuffSpellAction::isUseful()')
end = source.index('{', start) + 1
depth = 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
production = source[start:end]

fixture = r'''
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <string>
using uint8 = uint8_t;
using uint32 = uint32_t;
using SpellGroup = int;
constexpr int SPELL_GROUP_NONE = 0, MAX_SPELL_EFFECTS = 1;
struct Aura { int id = 1118; int GetId() const { return id; } } aura;
struct AuraApplication { Aura const* GetBase() const { return &aura; } } application;
struct Group;
struct Player
{
    bool alive = true, world = true, los = true, exact = false;
    float distance = 0;
    int map = 1;
    int ownShout = 0;
    Group* group = nullptr;
    std::map<int, AuraApplication*> auras;
    bool IsAlive() { return alive; }
    bool IsInWorld() { return world; }
    int GetMap() { return map; }
    int GetGUID() { return 1; }
    bool HasAura(int spell, int) { return ownShout == spell; }
    Group* GetGroup() { return group; }
    bool IsWithinDistInMap(Player* member, float radius) { return member->distance <= radius; }
    bool IsWithinLOSInMap(Player* member) { return member->los; }
    auto const& GetAppliedAuras() { return auras; }
};
struct GroupReference
{
    Player* player;
    GroupReference* following;
    Player* GetSource() { return player; }
    GroupReference* next() { return following; }
};
struct Group { GroupReference* first; GroupReference* GetFirstMember() { return first; } };
struct Effect
{
    bool IsEffect() const { return true; }
    float CalcRadius(Player*) const { return 30; }
};
struct SpellInfo { Effect Effects[1]; } info;
struct SpellMgr
{
    SpellInfo const* GetSpellInfo(uint32) { return &info; }
    bool IsSpellMemberOfSpellGroup(int id, SpellGroup group) { return id == group; }
} manager;
auto sSpellMgr = &manager;
struct AI { bool HasAura(std::string const&, Player* member) { return member->exact; } } ai;
#define AI_VALUE2(type, name, spell) 1u
struct CastSpellAction { bool allowed = true; bool isUseful() { return allowed; } };
struct CastAuraSpellAction : CastSpellAction
{
    Player* bot;
    AI* botAI = &ai;
    std::string spell;
    Player* target;
    Player* GetTarget() { return target; }
    bool isUseful() { return allowed && target && !target->exact; }
};
struct CastBuffSpellAction : CastAuraSpellAction { bool isUseful(); };
// PRODUCTION
int main()
{
    Player bot, member;
    GroupReference second{&member, nullptr}, first{&bot, &second};
    Group group{&first};
    bot.group = &group;
    bot.exact = true;
    CastBuffSpellAction action;
    action.bot = action.target = &bot;
    action.spell = "blessing of kings";
    assert(action.isUseful()); // Bot buffed; newly joined member still needs it.
    member.exact = true;
    assert(!action.isUseful()); // No repeated casts once everyone is covered.
    member.exact = false;
    member.auras.emplace(1, &application);
    assert(!action.isUseful()); // Equivalent stats buff counts as coverage.
    member.auras.clear();
    member.alive = false;
    assert(!action.isUseful());
    member.alive = true;
    assert(action.isUseful()); // Resurrection triggers rebuff.
    member.distance = 31;
    assert(!action.isUseful());
    member.distance = 30;
    assert(action.isUseful());
    member.map = 2;
    assert(!action.isUseful());
    member.map = 1;
    member.los = false;
    assert(!action.isUseful());
    member.los = true;
    member.world = false;
    assert(!action.isUseful());
    member.world = true;
    for (auto spell : {"blessing of might", "battle shout", "commanding shout", "horn of winter", "dark intent"})
    {
        action.spell = spell;
        assert(action.isUseful());
        member.exact = true;
        assert(!action.isUseful());
        member.exact = false;
    }
    action.spell = "water shield";
    assert(!action.isUseful()); // Personal buffs still check only the caster.
    action.spell = "battle shout";
    bot.ownShout = 469;
    assert(!action.isUseful()); // Do not erase our other assigned shout.
    action.spell = "commanding shout";
    bot.ownShout = 6673;
    assert(!action.isUseful());
    bot.ownShout = 0;
    action.spell = "blessing of kings";
    action.allowed = false;
    assert(!action.isUseful());
    std::cout << "Group buff regression passed\n";
}
'''
with tempfile.TemporaryDirectory(prefix='group-buff-') as directory:
    cpp = Path(directory) / 'test.cpp'
    binary = Path(directory) / 'test'
    cpp.write_text(fixture.replace('// PRODUCTION', production))
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
