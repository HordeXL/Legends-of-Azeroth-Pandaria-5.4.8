#!/usr/bin/env python3
"""Test production formation eligibility and destinations, including blocked slots."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
source = (root / 'modules/mod_playerbots/src/strategy/actions/FollowActions.cpp').read_text()
start = source.index('bool FollowAction::UseGroupFollowFormation()')
end = source.index('bool FollowAction::Execute(', start)
methods = source[start:end]
fixture = r'''
#include <cassert>
#include <cmath>
#include <iostream>
#include <vector>
#include "GroupFollowFormation.h"
using uint32=unsigned;
enum { BOT_STATE_NON_COMBAT, BOT_STATE_COMBAT };
struct Player;
struct Map {
    float maxOffset=100;
    bool CheckCollisionAndGetValidCoords(Player*,float mx,float my,float,float& x,float& y,float&) {
        return std::hypot(x-mx,y-my)<=maxOffset;
    }
};
struct GroupReference {
    Player* player=nullptr; GroupReference* following=nullptr;
    Player* GetSource(){return player;}
    GroupReference* next(){return following;}
};
struct Group {
    GroupReference* first=nullptr;
    GroupReference* GetFirstMember(){return first;}
};
struct Player {
    unsigned guid; Map* map; Group* group;
    bool tank=false, alive=true, world=true, combat=false, bg=false;
    float x=100,y=100,z=10,orientation=0;
    unsigned GetGUID(){return guid;}
    Map* GetMap(){return map;}
    unsigned GetMapId(){return 545;}
    Group* GetGroup(){return group;}
    bool IsInWorld(){return world;} bool IsAlive(){return alive;}
    bool IsInCombat(){return combat;} bool InBattleground(){return bg;}
    float GetPositionX(){return x;} float GetPositionY(){return y;} float GetPositionZ(){return z;}
    float GetOrientation(){return orientation;}
};
namespace PlayerBotSpec { bool IsTank(Player* p,bool) {return p->tank;} }
struct AI {int state=BOT_STATE_NON_COMBAT;int GetState(){return state;}};
struct WorldLocation {
    unsigned map; float x,y,z;
    WorldLocation(unsigned m,float a,float b,float c):map(m),x(a),y(b),z(c){}
};
struct FollowAction {
    Player* bot; Player* master; AI* botAI;
    Player* GetMaster(){return master;}
    bool UseGroupFollowFormation(); WorldLocation GetGroupFollowLocation();
};
METHODS
int main() {
    Map map,otherMap; Group group,otherGroup; AI ai;
    Player master{99,&map,&group}, tank{1,&map,&group}, dps1{2,&map,&group}, dps2{3,&map,&group}, healer{4,&map,&group};
    tank.tank=true;
    GroupReference refs[]={{&healer,nullptr},{&tank,nullptr},{&master,nullptr},{&dps2,nullptr},{&dps1,nullptr}};
    for(int i=0;i<4;++i) refs[i].following=&refs[i+1];
    group.first=&refs[0];
    FollowAction action{&tank,&master,&ai};
    assert(action.UseGroupFollowFormation());
    auto p=action.GetGroupFollowLocation();
    assert(p.x==105 && p.y==100);
    master.orientation=static_cast<float>(M_PI/2);
    p=action.GetGroupFollowLocation();
    assert(std::abs(p.x-100)<0.001f && std::abs(p.y-105)<0.001f);
    master.orientation=0;
    std::vector<WorldLocation> positions;
    for(Player* bot:{&dps1,&dps2,&healer}) {
        action.bot=bot; p=action.GetGroupFollowLocation();
        assert(p.x==96); positions.push_back(p);
    }
    for(unsigned i=0;i<positions.size();++i)
        for(unsigned j=i+1;j<positions.size();++j)
            assert(std::hypot(positions[i].x-positions[j].x,positions[i].y-positions[j].y)>=3);
    // Roster iteration order does not change a member's slot.
    action.bot=&dps2; auto before=action.GetGroupFollowLocation();
    refs[0].player=&dps1; refs[4].player=&healer;
    p=action.GetGroupFollowLocation(); assert(p.x==before.x && p.y==before.y);
    action.bot=&tank;
    map.maxOffset=3; p=action.GetGroupFollowLocation(); assert(p.x==102.5f);
    map.maxOffset=0; p=action.GetGroupFollowLocation(); assert(p.x==master.x && p.y==master.y);
    master.combat=true; assert(!action.UseGroupFollowFormation()); master.combat=false;
    tank.combat=true; assert(!action.UseGroupFollowFormation()); tank.combat=false;
    ai.state=BOT_STATE_COMBAT; assert(!action.UseGroupFollowFormation()); ai.state=BOT_STATE_NON_COMBAT;
    tank.alive=false; assert(!action.UseGroupFollowFormation()); tank.alive=true;
    master.map=&otherMap; assert(!action.UseGroupFollowFormation()); master.map=&map;
    master.group=&otherGroup; assert(!action.UseGroupFollowFormation()); master.group=&group;
    tank.bg=true; assert(!action.UseGroupFollowFormation()); tank.bg=false;
    action.master=nullptr; assert(!action.UseGroupFollowFormation());
    // Larger groups retain separate rows instead of reusing the same three slots.
    for(bool isTank:{false,true}) for(unsigned i=0;i<12;++i) {
        auto a=GroupFollowFormation::GetOffset(isTank,i);
        assert(isTank ? a.forward>=5 : a.forward<=-4);
        for(unsigned j=0;j<i;++j) {
            auto b=GroupFollowFormation::GetOffset(isTank,j);
            assert(std::hypot(a.forward-b.forward,a.sideways-b.sideways)>=3);
        }
    }
    std::cout<<"Group formation: tank lead, spacing, rotation, collision and combat guards passed\n";
}
'''
with tempfile.TemporaryDirectory(prefix='group-formation-') as directory:
    cpp=Path(directory)/'test.cpp'; binary=Path(directory)/'test'
    cpp.write_text(fixture.replace('METHODS',methods))
    subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror','-I',str(root/'modules/mod_playerbots/src/strategy/value'),str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
