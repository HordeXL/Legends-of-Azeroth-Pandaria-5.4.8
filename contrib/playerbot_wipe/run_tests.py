#!/usr/bin/env python3
"""Compile production dungeon release eligibility against a simulated party."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'modules/mod_playerbots/src/strategy/Dead/ReleaseSpiritAction.cpp').read_text()
def block(marker):
    a=source.index(marker);b=source.index('{',a)+1;depth=1
    while depth:
        depth+=(source[b]=='{')-(source[b]=='}');b+=1
    return source[a:b]
fixture=r'''
#include <cassert>
#include <iostream>
using uint32=unsigned;
enum {PLAYER_FLAGS_GHOST};
struct Map {bool dungeon=true; bool IsDungeon(){return dungeon;}};
struct InstanceScript {bool combat=false;bool IsEncounterInProgress(){return combat;}};
struct Player;
struct GroupReference {
    Player* member=nullptr;GroupReference* following=nullptr;
    Player* GetSource(){return member;} GroupReference* next(){return following;}
};
struct Group {GroupReference* first;GroupReference* GetFirstMember(){return first;}};
struct Player {
    Map* map;InstanceScript* instance;Group* group=nullptr;
    bool alive=false,combat=false,world=true,ghost=false,request=false,bg=false,arena=false;
    bool IsAlive(){return alive;} bool isDead(){return !alive;} bool IsInCombat(){return combat;}
    bool IsInWorld(){return world;} Map* GetMap(){return map;} Group* GetGroup(){return group;}
    InstanceScript* GetInstanceScript(){return instance;}
    bool HasPlayerFlag(int){return ghost;} bool IsRessurectRequested(){return request;}
    bool InArena(){return arena;} bool InBattleground(){return bg;}
};
HELPER
bool IsActivePandariaWorldBossFight(Player*){return false;}
struct AI {Player* master;Player* GetGroupMaster(){return master;} bool HasActivePlayerMaster(){return true;}};
struct Config {float sightDistance=90;} config;
auto sPlayerbotAIConfig=&config;
struct Facade {bool IsDistanceGreaterThan(float a,float b){return a>b;}} facade;
auto sServerFacade=&facade;
#define AI_VALUE2(type,name,qualifier) 0.0f
struct AutoReleaseSpiritAction {Player* bot;AI* botAI;bool isUseful();};
USEFUL
int main(){
    Map map,other;InstanceScript instance;
    Player bot{&map,&instance},master{&map,&instance},survivor{&map,&instance};
    GroupReference refs[]={{&bot,nullptr},{&master,nullptr},{&survivor,nullptr}};
    refs[0].following=&refs[1];refs[1].following=&refs[2];Group group{refs};
    bot.group=master.group=survivor.group=&group;
    AI ai{&master}; AutoReleaseSpiritAction action{&bot,&ai};
    assert(action.isUseful()); // Whole group dead, encounter reset.
    master.alive=true;
    assert(action.isUseful()); // Master already revived nearby: previous failure.
    survivor.alive=true;survivor.combat=true;
    assert(!action.isUseful()); // Trash still fighting a survivor.
    survivor.combat=false;instance.combat=true;
    assert(!action.isUseful()); // Boss has not reset yet.
    bot.request=true;assert(action.isUseful()); // Accept legitimate battle res.
    bot.request=false;instance.combat=false;
    assert(action.isUseful());
    bot.ghost=true;assert(!action.isUseful()); // No repeated release packets.
    bot.ghost=false;bot.alive=true;assert(!action.isUseful());bot.alive=false;
    survivor.combat=true;survivor.map=&other;
    assert(action.isUseful()); // Other instances do not block recovery.
    survivor.map=&map;survivor.world=false;
    assert(action.isUseful());
    map.dungeon=false;survivor.world=true;survivor.combat=false;
    assert(!action.isUseful()); // Outdoor bot still waits for nearby living master.
    master.alive=false;assert(action.isUseful());
    bot.arena=true;assert(!action.isUseful());bot.arena=false;
    bot.bg=true;assert(action.isUseful());
    std::cout<<"Dungeon wipe release: master recovery, combat barriers, resurrection and ghost checks passed\n";
}
'''
fixture=fixture.replace('HELPER',block('bool CanReleaseDungeonSpirit(')).replace('USEFUL',block('bool AutoReleaseSpiritAction::isUseful()'))
with tempfile.TemporaryDirectory(prefix='bot-wipe-') as directory:
    cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test';cpp.write_text(fixture)
    subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
