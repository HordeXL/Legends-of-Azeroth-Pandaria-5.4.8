#!/usr/bin/env python3
"""Verify the production escape-spell correction and cross-map LOS exemption."""
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
mgr=(root/'src/server/game/Spells/SpellMgr.cpp').read_text()
a=mgr.index('                case 46841:')
b=mgr.index('                    break;',a)+len('                    break;')
correction=mgr[a:b]
spell=(root/'src/server/game/Spells/Spell.cpp').read_text()
a=spell.index('                // Skip LOS check for self-targeting effects')
b=spell.index('\n                float x, y, z;',a)
los=spell[a:b]
fixture=r'''
#include <cassert>
#include <iostream>
using uint8=unsigned char;
enum { EFFECT_0=0, TARGET_UNIT_CASTER=1, TARGET_DEST_DB=17 };
struct Target {
    unsigned id=0;
    void operator=(unsigned v){id=v;}
    unsigned GetTarget() const{return id;}
};
struct Effect {Target TargetA,TargetB;};
struct SpellInfo {Effect Effects[3];};
void Correct(unsigned id,SpellInfo* spellInfo) {
    switch(id) {
CORRECTION
    }
}
bool CanSkipDestinationLOS(SpellInfo* m_spellInfo,unsigned eff) {
LOS
    return false;
}
int main() {
    {
        SpellInfo info;
        info.Effects[0].TargetA=TARGET_DEST_DB;
        assert(!CanSkipDestinationLOS(&info,0));
        Correct(46841,&info);
        assert(info.Effects[0].TargetA.GetTarget()==TARGET_UNIT_CASTER);
        assert(info.Effects[0].TargetB.GetTarget()==TARGET_DEST_DB);
        assert(CanSkipDestinationLOS(&info,0));
    }
    SpellInfo other;
    other.Effects[0].TargetA=TARGET_DEST_DB;
    Correct(123,&other);
    assert(!CanSkipDestinationLOS(&other,0));
    std::cout<<"Escape teleport self target, DB destination and LOS regression passed\n";
}
'''
with tempfile.TemporaryDirectory(prefix='magisters-escape-') as directory:
    cpp=Path(directory)/'test.cpp'; binary=Path(directory)/'test'
    cpp.write_text(fixture.replace('CORRECTION',correction).replace('LOS\n',los+'\n'))
    subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
