#!/usr/bin/env python3
"""Exercise Vexallus's production summon, reset and death callbacks."""
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'src/server/scripts/EasternKingdoms/MagistersTerrace/boss_vexallus.cpp').read_text()
def method(name):
    a=source.index('        void '+name+'(')
    b=source.index('{',a);depth=1;end=b+1
    while depth:
        depth+=(source[end]=='{')-(source[end]=='}');end+=1
    return source[a:end].replace(' override','')
harness=r'''
#include <cassert>
#include <vector>
#include <iostream>
using uint32=unsigned;
enum { DATA_VEXALLUS_EVENT, NOT_STARTED, DONE, SELECT_TARGET_RANDOM, SPELL_ENERGY_BOLT };
struct Unit {};
struct Motion {
    Unit* target=nullptr;
    void MoveFollow(Unit* unit,float,float){target=unit;}
};
struct Creature : Unit {
    bool alive=true,despawned=false;unsigned bolts=0;Motion motion;
    bool IsAlive(){return alive;}
    unsigned GetGUID(){return 1;}
    Motion* GetMotionMaster(){return &motion;}
    void CastSpell(Creature*,int,bool,int,int,unsigned){++bolts;}
    void DespawnOrUnsummon(){despawned=true;motion.target=nullptr;}
};
struct SummonList {
    std::vector<Creature*> tracked;
    void Summon(Creature* creature){tracked.push_back(creature);}
    void DespawnAll(){for(auto c:tracked)c->DespawnOrUnsummon();tracked.clear();}
};
struct Instance {
    int state=-1;
    void SetData(int,int value){state=value;}
};
struct AI {
    Creature* me;Instance* instance;SummonList summons;Unit* target=nullptr;
    uint32 ChainLightningTimer=0,ArcaneShockTimer=0,OverloadTimer=0,IntervalHealthAmount=0;
    bool Enraged=false;
    Unit* SelectTarget(int,int){return target;}
METHODS
};
int main(){
    Creature boss;Instance instance;Unit player;AI ai;
    ai.me=&boss;ai.instance=&instance;ai.target=&player;
    // Both normal (five) and heroic (ten) energy summons must be tracked.
    for (unsigned count:{5u,10u}) {
        std::vector<Creature> adds(count);
        boss.alive=true;ai.Reset();assert(instance.state==NOT_STARTED);
        for (auto& add:adds){ai.JustSummoned(&add);assert(add.bolts==1 && add.motion.target==&player);}
        assert(ai.summons.tracked.size()==count);
        boss.alive=false;ai.JustDied(&player);
        assert(instance.state==DONE && ai.summons.tracked.empty());
        for(auto& add:adds)assert(add.despawned && !add.motion.target);
    }
    boss.alive=true;Creature wipeAdd;ai.JustSummoned(&wipeAdd);ai.Reset();
    assert(wipeAdd.despawned && ai.summons.tracked.empty());
    // Register even if there is no current random target.
    ai.target=nullptr;Creature noTarget;ai.JustSummoned(&noTarget);ai.Reset();
    assert(noTarget.despawned);
    // A late callback after death must not start new movement or casting.
    boss.alive=false;Creature late;ai.JustSummoned(&late);
    assert(late.despawned && !late.bolts && !late.motion.target && ai.summons.tracked.empty());
    // Cleanup must also work without an instance script.
    boss.alive=true;ai.instance=nullptr;Creature isolated;ai.JustSummoned(&isolated);ai.JustDied(&player);
    assert(isolated.despawned);
    std::cout<<"Vexallus summon tracking, death/reset cleanup and late-summon checks passed\n";
}
'''.replace('METHODS','\n'.join(method(name) for name in ['Reset','JustDied','JustSummoned']))
with tempfile.TemporaryDirectory(prefix='vexallus-test-') as d:
    d=Path(d);cpp=d/'test.cpp';cpp.write_text(harness);binary=d/'test'
    subprocess.run(['c++','-std=c++11','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
