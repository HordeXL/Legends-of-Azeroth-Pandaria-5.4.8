#!/usr/bin/env python3
"""Test production Han gossip callbacks and credit gates."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
src = (root / 'src/server/scripts/Pandaria/zone_dread_wastes.cpp').read_text()
code = src[src.index('class npc_han_stormstout_quest'):src.index('void AddSC_dread_wastes()')].replace(' override', '')
fixture = r"""
#include <cassert>
using uint32 = unsigned;
enum { QUEST_STATUS_INCOMPLETE=1, GOSSIP_ICON_CHAT=0, GOSSIP_SENDER_MAIN=1, GOSSIP_ACTION_INFO_DEF=1000, DEFAULT_GOSSIP_MESSAGE=1, INTERACTION_DISTANCE=5 };
struct Menu { void ClearMenus() {} };
struct Player {
    Menu menu; Menu* PlayerTalkClass=&menu;
    bool alive=true; int status=1, credits=0, options=0;
    bool IsAlive() { return alive; }
    int GetQuestStatus(int id) { assert(id==31078); return status; }
    void ADD_GOSSIP_ITEM(int, char const*, int, int) { ++options; }
    void SEND_GOSSIP_MENU(int, int) {}
    void CLOSE_GOSSIP_MENU() {}
    void KilledMonsterCredit(int id) { assert(id==62776); ++credits; status=2; }
};
struct Creature {
    bool near=true, los=true;
    int GetGUID() { return 1; }
    bool IsWithinDistInMap(Player*, int) { return near; }
    bool IsWithinLOSInMap(Player*) { return los; }
};
struct CreatureScript { explicit CreatureScript(char const*) {} };
// CODE
int main() {
    Creature han; npc_han_stormstout_quest script;
    for (int mode=0; mode<7; ++mode) {
        Player p; han.near=han.los=true;
        if (mode==0) p.status=0;
        if (mode==1) p.status=2;
        if (mode==2) p.alive=false;
        if (mode==3) han.near=false;
        if (mode==4) han.los=false;
        script.OnGossipSelect(&p,&han,mode==5?99:1,mode==6?99:1000);
        assert(p.credits==0);
    }
    Player p; han.near=han.los=true;
    script.OnGossipHello(&p,&han); assert(p.options==1 && p.credits==0);
    script.OnGossipSelect(&p,&han,1,1000); assert(p.credits==1);
    script.OnGossipSelect(&p,&han,1,1000); assert(p.credits==1);
}
"""
with tempfile.TemporaryDirectory(prefix='han-test-') as directory:
    cpp=Path(directory)/'test.cpp'; binary=Path(directory)/'test'
    cpp.write_text(fixture.replace('// CODE', code))
    subprocess.run(['c++','-std=c++11','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
print('PASS: inspection, quest/death/distance/LOS/action gates, duplicate credit')
