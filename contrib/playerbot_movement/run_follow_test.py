#!/usr/bin/env python3
"""Compile production follow-target lookup and follow command submission."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
facade = (root / 'modules/mod_playerbots/src/Utils/ServerFacade.cpp').read_text()
start = facade.index('Unit* ServerFacade::GetFollowTarget(')
end = facade.index('\nvoid ServerFacade::SendPacket', start)
lookup = facade[start:end]
movement = (root / 'modules/mod_playerbots/src/strategy/actions/MovementActions.cpp').read_text()
start = movement.index('    // Keep the active follow generator')
end = movement.index('\nconst Movement::PointsArray MovementAction::SearchForBestPath', start)
submission = 'bool MovementAction::Follow(Unit* target, float distance, float angle)\n{\n' + movement[start:end]
harness = r'''
#include <cassert>
#include <iostream>
#include <memory>
#include <string>
enum { TYPEID_PLAYER, TYPEID_UNIT, IDLE_MOTION_TYPE, FOLLOW_MOTION_TYPE, CHASE_MOTION_TYPE, UNIT_STAND_STATE_STAND };
struct Unit;
struct MovementGenerator {
    virtual ~MovementGenerator()=default;
    virtual int GetMovementGeneratorType() const { return IDLE_MOTION_TYPE; }
};
template<class T> struct FollowMovementGenerator : MovementGenerator {
    Unit* target;
    explicit FollowMovementGenerator(Unit* t):target(t){}
    int GetMovementGeneratorType() const override {return FOLLOW_MOTION_TYPE;}
    Unit* GetTarget() const {return target;}
};
struct Chase : MovementGenerator {
    int GetMovementGeneratorType() const override{return CHASE_MOTION_TYPE;}
};
struct MotionMaster {
    MovementGenerator* active=nullptr;
    std::unique_ptr<MovementGenerator> owned;
    unsigned moves=0,clears=0;
    MovementGenerator* top(){return active;}
    int GetCurrentMovementGeneratorType(){return active?active->GetMovementGeneratorType():IDLE_MOTION_TYPE;}
    void Clear(){++clears;active=nullptr;}
    void MoveFollow(Unit*,float,float);
};
struct Unit {
    int type;unsigned guid;
    MotionMaster motion;
    Unit(int t,unsigned g):type(t),guid(g){}
    MotionMaster* GetMotionMaster(){return &motion;}
    int GetTypeId(){return type;}
    unsigned GetGUID(){return guid;}
    float GetPositionX(){return 0;}float GetPositionY(){return 0;}float GetPositionZ(){return 0;}
};
struct Player : Unit {
    unsigned castsStopped=0,emotes=0;
    Player(unsigned g):Unit(TYPEID_PLAYER,g){}
    bool IsSitState(){return false;}
    void SetStandState(int){}
    bool IsNonMeleeSpellCasted(bool){return true;}
    void CastStop(){++castsStopped;}
    void HandleEmoteCommand(int){++emotes;}
};
struct Creature : Unit {Creature(unsigned g):Unit(TYPEID_UNIT,g){}};
void MotionMaster::MoveFollow(Unit* target,float,float) {
    ++moves;owned.reset(new FollowMovementGenerator<Player>(target));active=owned.get();
}
struct ServerFacade {Unit* GetFollowTarget(Unit*);};
ServerFacade facade;
auto sServerFacade=&facade;
LOOKUP
struct AI {unsigned interrupts=0;void InterruptSpell(){++interrupts;}};
struct MovementAction {
    Player* bot; AI* botAI;unsigned idleCleared=0;
    void ClearIdleState(){++idleCleared;}
    std::string getName(){return "follow";}
    bool Follow(Unit*,float,float);
};
template<class... T> void TraceManagedPveMovement(T...){}
SUBMISSION
int main() {
    Player bot(1),leader(2),otherLeader(3);AI ai;
    MovementAction action{&bot,&ai};
    assert(!facade.GetFollowTarget(&bot));
    assert(action.Follow(&leader,2,3.14f));
    assert(bot.motion.moves==1 && facade.GetFollowTarget(&bot)==&leader);
    for (int i=0;i<200;++i) assert(!action.Follow(&leader,2,3.14f));
    assert(bot.motion.moves==1 && bot.motion.clears==1);
    assert(bot.castsStopped==1 && ai.interrupts==1 && bot.emotes==1);
    assert(action.idleCleared==1); // redundant follows do not touch any of these
    assert(action.Follow(&otherLeader,2,3.14f));
    assert(bot.motion.moves==2 && facade.GetFollowTarget(&bot)==&otherLeader);
    Chase chase;bot.motion.active=&chase;
    assert(!facade.GetFollowTarget(&bot));
    assert(action.Follow(&leader,2,3.14f));
    assert(bot.motion.moves==3 && bot.motion.clears==2);
    Creature pet(4);FollowMovementGenerator<Creature> petFollow(&leader);
    pet.motion.active=&petFollow;
    assert(facade.GetFollowTarget(&pet)==&leader);
    pet.motion.active=&chase;assert(!facade.GetFollowTarget(&pet));
    std::cout<<"Follow regression passed: 200 repeated decisions keep one movement command; retargeting and chase transitions still work\n";
}
'''.replace('LOOKUP', lookup).replace('SUBMISSION', submission)
with tempfile.TemporaryDirectory(prefix='bot-follow-test-') as directory:
    directory=Path(directory)
    cpp=directory/'test.cpp';cpp.write_text(harness)
    binary=directory/'test'
    subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
