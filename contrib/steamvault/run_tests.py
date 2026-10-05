#!/usr/bin/env python3
"""Exercise the production Steamvault panel/door lifecycle with lightweight objects."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/scripts/Outland/CoilfangReservoir/SteamVault/instance_steam_vault.cpp').read_text()

def method(marker):
    start = source.index(marker)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]

fixture = r'''
#include <cassert>
#include <map>
#include <iostream>
using uint32 = unsigned;
using ObjectGuid = unsigned;
enum EncounterState { NOT_STARTED, IN_PROGRESS, FAIL, DONE, SPECIAL, TO_BE_DECIDED };
enum { DATA_HYDROMANCER_THESPIA, DATA_MEKGINEER_STEAMRIGGER, DATA_WARLORD_KALITHRESH };
enum { GO_MAIN_CHAMBERS_DOOR=183049, GO_ACCESS_PANEL_HYDRO=184125, GO_ACCESS_PANEL_MEK=184126 };
enum { GAMEOBJECT_FIELD_FLAGS, OBJECT_FIELD_DYNAMIC_FLAGS, GO_FLAG_NOT_SELECTABLE=32, GO_STATE_ACTIVE=0, GO_STATE_READY=1, GO_DYNFLAG_LO_ACTIVATE=2, GO_DYNFLAG_LO_SPARKLE=16 };
struct GameObject {
    uint32 entry, flags=48, state=GO_STATE_READY, dynamic=0;
    uint32 GetEntry() const { return entry; }
    ObjectGuid GetGUID() const { return entry; }
    void RemoveFlag(uint32 field, uint32 flag) { (field==GAMEOBJECT_FIELD_FLAGS ? flags : dynamic) &= ~flag; }
    void SetFlag(uint32 field, uint32 flag) { (field==GAMEOBJECT_FIELD_FLAGS ? flags : dynamic) |= flag; }
    void SetGoState(uint32 value) { state=value; }
    bool selectable() const { return !(flags & GO_FLAG_NOT_SELECTABLE); }
};
struct Map {
    std::map<ObjectGuid, GameObject*> objects;
    GameObject* GetGameObject(ObjectGuid guid) { return objects.count(guid) ? objects.at(guid) : nullptr; }
};
struct InstanceScript {
    Map* instance;
    EncounterState states[3] = {NOT_STARTED,NOT_STARTED,NOT_STARTED};
    explicit InstanceScript(Map* map) : instance(map) {}
    virtual ~InstanceScript() = default;
    virtual void OnGameObjectCreate(GameObject*) {}
    EncounterState GetBossState(uint32 id) const { return states[id]; }
    virtual bool SetBossState(uint32 id, EncounterState state) {
        if (states[id]==state) return false;
        bool loading=states[id]==TO_BE_DECIDED;
        states[id]=state;
        return !loading;
    }
    void HandleGameObject(ObjectGuid guid, bool open, GameObject* go=nullptr) {
        if (!go) go=instance->GetGameObject(guid);
        if (go) go->SetGoState(open ? GO_STATE_ACTIVE : GO_STATE_READY);
    }
};
struct TestInstance : InstanceScript {
    using InstanceScript::InstanceScript;
    ObjectGuid MainChambersDoorGUID=0, HydroDoor=0, MekDoor=0;
// METHODS
};
int main() {
    Map map;
    TestInstance test(&map);
    GameObject hydro{GO_ACCESS_PANEL_HYDRO}, mek{GO_ACCESS_PANEL_MEK}, door{GO_MAIN_CHAMBERS_DOOR};
    auto add=[&](GameObject& go) { map.objects[go.entry]=&go; test.OnGameObjectCreate(&go); };
    add(hydro); add(door);
    assert(!hydro.selectable() && hydro.dynamic==0);
    test.SetBossState(DATA_HYDROMANCER_THESPIA,DONE);
    assert(hydro.selectable() && hydro.flags==16 && hydro.dynamic==18);
    test.SetBossState(DATA_HYDROMANCER_THESPIA,SPECIAL);
    assert(door.state==GO_STATE_READY && hydro.dynamic==0);
    // Second panel did not exist at the time its boss died.
    test.SetBossState(DATA_MEKGINEER_STEAMRIGGER,DONE);
    add(mek);
    assert(mek.selectable() && mek.state==GO_STATE_READY && mek.dynamic==18);
    test.SetBossState(DATA_MEKGINEER_STEAMRIGGER,SPECIAL);
    assert(door.state==GO_STATE_ACTIVE && mek.dynamic==0);
    assert(!test.SetBossState(DATA_MEKGINEER_STEAMRIGGER,NOT_STARTED));
    assert(!test.SetBossState(DATA_MEKGINEER_STEAMRIGGER,DONE));
    assert(test.GetBossState(DATA_MEKGINEER_STEAMRIGGER)==SPECIAL);
    // Reloaded objects recover the saved panel/door state.
    mek.flags=48; mek.state=GO_STATE_READY; door.state=GO_STATE_READY;
    test.OnGameObjectCreate(&mek); test.OnGameObjectCreate(&door);
    assert(mek.selectable() && mek.state==GO_STATE_ACTIVE && door.state==GO_STATE_ACTIVE);
    // Loading boss states before any objects are created must also work.
    Map savedMap;
    TestInstance saved(&savedMap);
    saved.states[0]=saved.states[1]=TO_BE_DECIDED;
    saved.SetBossState(0,DONE); saved.SetBossState(1,SPECIAL);
    assert(!saved.SetBossState(0,NOT_STARTED));
    hydro.flags=mek.flags=48;
    saved.OnGameObjectCreate(&hydro); saved.OnGameObjectCreate(&mek); saved.OnGameObjectCreate(&door);
    assert(hydro.selectable() && hydro.state==GO_STATE_READY && hydro.dynamic==18);
    assert(mek.selectable() && mek.state==GO_STATE_ACTIVE && mek.dynamic==0);
    assert(door.state==GO_STATE_READY);
    std::cout << "Steamvault panel lifecycle checks passed\n";
}
'''
fixture = fixture.replace('// METHODS', '\n'.join(method(marker) for marker in [
    'void OnGameObjectCreate(GameObject* go) override',
    'void UpdateAccessPanel(GameObject* panel, uint32 boss)',
    'bool SetBossState(uint32 type, EncounterState state) override']))
with tempfile.TemporaryDirectory(prefix='steamvault-test-') as directory:
    cpp=Path(directory)/'test.cpp'
    binary=Path(directory)/'test'
    cpp.write_text(fixture)
    subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
