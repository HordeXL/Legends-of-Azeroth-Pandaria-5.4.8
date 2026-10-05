#!/usr/bin/env python3
"""Compile production instance state transitions against a deterministic fixture."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
base = root / 'src/server/scripts/Kalimdor/CavernsOfTime/TheBlackMorass'
src = (base / 'instance_the_black_morass.cpp').read_text()
def method(signature):
    start = src.index(signature)
    brace = src.index('{', start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (src[end] == '{') - (src[end] == '}')
        end += 1
    return src[start:end].replace(' override', '').replace('ObjectGuid::Empty', '0')
methods = '\n'.join(method(x) for x in [
    'void Clear()', 'void InitWorldState(', 'void OnPlayerEnter(', 'void ResetEvent()',
    'bool CanProgressEvent()', 'uint8 GetRiftWaveId()', 'void SetData(',
    'std::string GetSaveData()', 'void Load(', 'uint32 GetData(',
    'void Update(uint32 diff)', 'void ScheduleEventNextPortal('])
fixture = r'''
#include <cassert>
#include <cstring>
#include <sstream>
#include <string>
#include <vector>
#include <map>
using uint32=unsigned; using uint8=unsigned char; using ObjectGuid=int;
#define TC_LOG_DEBUG(...) ((void)0)
enum {NOT_STARTED, IN_PROGRESS, FAIL, DONE, SPECIAL};
enum {QUEST_STATUS_INCOMPLETE=1, DIRECT_DAMAGE=0, SPELL_SCHOOL_MASK_NORMAL=0, EVENT_NEXT_PORTAL=1};
// HEADER
struct Player {
 bool alive=true; int credit=0; std::map<int,int> states;
 bool IsAlive(){return alive;} bool IsGameMaster(){return false;}
 void SendUpdateWorldState(int id,int value){states[id]=value;}
 int GetQuestStatus(int id){return id==QUEST_OPENING_PORTAL?QUEST_STATUS_INCOMPLETE:0;}
 void AreaExploredOrEventHappens(int){++credit;}
};
struct AI {int resets=0;void Reset(){++resets;} };
struct Creature {
 bool alive=true;int despawns=0;struct AI ai;
 bool IsAlive(){return alive;} void Respawn(){alive=true;}
 void CombatStop(bool){} void RemoveAllAuras(){} int GetMaxHealth(){return 100;}
 void SetHealth(int){} int GetHealth(){return 100;}
 void DealDamage(Creature*,int,void*,int,int,void*,bool){alive=false;}
 void DespawnOrUnsummon(){++despawns;} struct AI* AI(){return &ai;}
};
struct Ref {Player* p;Player* GetSource() const{return p;} };
struct PlayerList:std::vector<Ref>{bool isEmpty()const{return empty();}};
struct Map {
 using PlayerList=::PlayerList;PlayerList players;Creature medivh,add;
 PlayerList const& GetPlayers(){return players;}
 Creature* GetCreature(int id){return id==1?&medivh:&add;}
};
struct EventMap {
 uint32 timer=0; bool active=false;
 void Reset(){timer=0;active=false;}
 void RescheduleEvent(int,uint32 delay){timer=delay;active=true;}
 void Update(uint32 diff){timer=diff>=timer?0:timer-diff;}
 int ExecuteEvent(){if(active&&!timer){active=false;return 1;}return 0;}
};
enum {RIFT_BOSS=1};
// WAVES
struct Instance {
 Map* instance;uint32 m_auiEncounter[EncounterCount];
 uint32 mRiftPortalCount,mShieldPercent;uint8 mRiftWaveCount,mRiftWaveId,_currentRiftId;
 ObjectGuid _medivhGUID=1;uint32 resetTimer=0;std::vector<ObjectGuid> eventSummons;
 EventMap Events;int saves=0;std::vector<int> bosses;
 explicit Instance(Map* map):instance(map){Clear();}
 void DoUpdateWorldState(int,int){} void SaveToDB(){++saves;}
 void DoSpawnPortal(){bosses.push_back(RiftWaves[GetRiftWaveId()].PortalBoss);}
 // METHODS
};
int main(){
 Map map;Player player;map.players.push_back({&player});Instance event(&map);
 event.SetData(TYPE_MEDIVH,IN_PROGRESS);
 event.Update(14000);event.SetData(TYPE_MEDIVH,IN_PROGRESS);
 assert(event.Events.timer==1000);event.Update(1000);
 assert(event.mRiftPortalCount==1);
 event.SetData(TYPE_MEDIVH,SPECIAL);assert(event.mShieldPercent==99);
 Player late;event.OnPlayerEnter(&late);assert(late.states[WORLD_STATE_BM_SHIELD]==99&&late.states[WORLD_STATE_BM_RIFT]==1);
 for(int portal=2;portal<=18;++portal){
  if(portal<=7)event.SetData(TYPE_RIFT,SPECIAL);
  assert(event.Events.active);event.Update(event.Events.timer);
  assert(event.mRiftPortalCount==unsigned(portal));
 }
 assert(event.bosses[5]==NPC_CRONO_LORD_DEJA&&event.bosses[11]==NPC_TEMPORUS&&event.bosses[17]==NPC_AEONUS);
 event.SetData(TYPE_MEDIVH,DONE);assert(player.credit==0);
 event.SetData(TYPE_RIFT,DONE);event.SetData(TYPE_MEDIVH,DONE);
 assert(player.credit==1&&event.saves==1&&!event.Events.active);
 event.SetData(TYPE_MEDIVH,DONE);event.SetData(TYPE_MEDIVH,IN_PROGRESS);assert(player.credit==1);
 Instance loaded(&map);loaded.Load(event.GetSaveData().c_str());assert(loaded.GetData(TYPE_MEDIVH)==DONE);
 loaded.SetData(TYPE_MEDIVH,IN_PROGRESS);assert(loaded.GetData(TYPE_MEDIVH)==DONE);
 for(int mode=0;mode<3;++mode){
  Instance retry(&map);player.alive=true;retry.eventSummons.push_back(2);
  retry.SetData(TYPE_MEDIVH,IN_PROGRESS);retry.Update(15000);
  if(mode==0){player.alive=false;retry.Update(1);}
  if(mode==1){for(int i=0;i<100;++i)retry.SetData(TYPE_MEDIVH,SPECIAL);}
  if(mode==2){retry.SetData(TYPE_MEDIVH,FAIL);}
  assert(retry.GetData(TYPE_MEDIVH)==FAIL);
  retry.SetData(TYPE_MEDIVH,IN_PROGRESS);assert(retry.GetData(TYPE_MEDIVH)==FAIL);
  retry.Update(10000);assert(retry.mShieldPercent==100&&retry.mRiftPortalCount==0&&!retry.Events.active);
  assert(retry.eventSummons.empty()&&map.medivh.alive);
  player.alive=true;retry.SetData(TYPE_MEDIVH,IN_PROGRESS);retry.Update(15000);assert(retry.mRiftPortalCount==1);
 }
 assert(map.add.despawns==3);
 loaded.Load("bad");assert(loaded.GetData(TYPE_MEDIVH)==NOT_STARTED);
}
'''
with tempfile.TemporaryDirectory(prefix='black-morass-') as directory:
    cpp=Path(directory)/'test.cpp'; binary=Path(directory)/'test'
    cpp.write_text(fixture.replace('// HEADER',(base/'the_black_morass.h').read_text()).replace('// METHODS',methods).replace('// WAVES',src[src.index('struct Wave'):src.index('enum EventIds')]))
    subprocess.run(['c++','-std=c++11','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
print('PASS: 18 portals, bosses 6/12/18, duplicate start, late join, completion once, persistence, wipe/shield failure and restart')
