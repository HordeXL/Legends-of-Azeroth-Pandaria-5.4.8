#!/usr/bin/env python3
"""Test production encounter accounting and restored Magisters' Terrace doors."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
s=(root/'src/server/scripts/EasternKingdoms/MagistersTerrace/instance_magisters_terrace.cpp').read_text()
def block(marker):
 a=s.index(marker);b=s.index('{',a)+1;depth=1
 while depth:depth+=(s[b]=='{')-(s[b]=='}');b+=1
 return s[a:b]
header=(root/'src/server/scripts/EasternKingdoms/MagistersTerrace/magisters_terrace.h').read_text()
enums=header[header.index('enum Data'):header.index('\n#endif')]
fixture=r'''
#include <cassert>
#include <map>
#include <iostream>
using uint32=unsigned;using ObjectGuid=unsigned;
enum {NOT_STARTED,IN_PROGRESS,FAIL,DONE,SPECIAL};
constexpr unsigned MAX_ENCOUNTER=4;
DATA
OBJECTS
struct GameObject {unsigned entry;bool open=false;unsigned GetEntry(){return entry;}unsigned GetGUID(){return entry;}};
struct InstanceScript {
 std::map<unsigned,GameObject*> objects;
 virtual ~InstanceScript()=default;
 virtual void SetData(uint32,uint32){}
 virtual void OnGameObjectCreate(GameObject*){}
 void HandleGameObject(unsigned guid,bool open,GameObject* go=nullptr){
  if(!go && objects.count(guid))go=objects.at(guid);
  if(go)go->open=open;
 }
 void SaveToDB(){}
};
struct Instance:InstanceScript {
 uint32 Encounter[4]={},DelrissaDeathCount=0,StatuesState=0;
 bool DelrissaDied=false;
 ObjectGuid VexallusDoorGUID=0,SelinDoorGUID=0,SelinEncounterDoorGUID=0,DelrissaDoorGUID=0,KaelDoorGUID=0,KaelStatue[2]={},EscapeOrbGUID=0;
METHODS
};
int main(){
 // Each possible Delrissa death position among her four lackeys.
 for(unsigned bossPosition=0;bossPosition<5;++bossPosition){
  Instance i;GameObject door{GO_DELRISSA_DOOR};i.objects[door.entry]=&door;i.OnGameObjectCreate(&door);
  assert(!door.open);i.SetData(DATA_DELRISSA_EVENT,IN_PROGRESS);
  for(unsigned death=0;death<5;++death){
   if(death==bossPosition)i.SetData(DATA_DELRISSA_DIED,1);
   else i.SetData(DATA_DELRISSA_DEATH_COUNT,SPECIAL);
   assert(door.open==(death==4));
   if(death<4)i.SetData(DATA_DELRISSA_EVENT,IN_PROGRESS); // Late/repeated engage must not erase kills.
  }
  assert(i.Encounter[2]==DONE && i.DelrissaDeathCount==4);
  i.SetData(DATA_DELRISSA_EVENT,FAIL);assert(i.Encounter[2]==DONE);
  door.open=false;i.OnGameObjectCreate(&door);assert(door.open);
 }
 // All death signals before the port loads, including boss corpse removal.
 Instance delayed;delayed.SetData(DATA_DELRISSA_EVENT,IN_PROGRESS);delayed.SetData(DATA_DELRISSA_DIED,1);
 for(unsigned n=0;n<4;++n)delayed.SetData(DATA_DELRISSA_DEATH_COUNT,SPECIAL);
 GameObject late{GO_DELRISSA_DOOR};delayed.OnGameObjectCreate(&late);assert(late.open);
 // Failed attempts reset both counters, never completing from an earlier pull.
 Instance retry;retry.SetData(DATA_DELRISSA_EVENT,IN_PROGRESS);retry.SetData(DATA_DELRISSA_DIED,1);
 retry.SetData(DATA_DELRISSA_DEATH_COUNT,SPECIAL);retry.SetData(DATA_DELRISSA_EVENT,FAIL);
 assert(!retry.DelrissaDied && retry.DelrissaDeathCount==0);
 retry.SetData(DATA_DELRISSA_EVENT,IN_PROGRESS);
 for(unsigned n=0;n<4;++n)retry.SetData(DATA_DELRISSA_DEATH_COUNT,SPECIAL);
 assert(retry.Encounter[2]!=DONE);
 retry.SetData(DATA_DELRISSA_DIED,1);assert(retry.Encounter[2]==DONE);
 std::cout<<"Delrissa death orders, late engage, missing/loaded doors and wipe reset passed\n";
}
'''
fixture=fixture.replace('DATA',enums,1).replace('OBJECTS',block('enum GameObjects')+';').replace('METHODS',block('void SetData(')+'\n'+block('void OnGameObjectCreate('))
with tempfile.TemporaryDirectory(prefix='delrissa-test-') as directory:
 cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test';cpp.write_text(fixture)
 subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
