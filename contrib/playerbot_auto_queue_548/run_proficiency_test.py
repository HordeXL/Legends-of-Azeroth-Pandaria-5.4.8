#!/usr/bin/env python3
"""Regression for a bot with a present but unusable mail proficiency (0/0)."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
source = (root / 'modules/mod_playerbots/src/Factory/BotFactory.cpp').read_text()
start = source.index('void BotFactory::RepairEquipmentProficiencies()')
end = source.index('\n}\n', start) + 2
harness = r'''
#include <cassert>
#include <map>
#include <vector>
#include <iostream>
using uint32=unsigned;
enum { SKILL_CATEGORY_ARMOR=8, SKILL_CATEGORY_WEAPON=6, SKILL_CATEGORY_PROFESSION=11 };
struct SkillRaceClassInfoEntry { uint32 SkillId,ReqLevel; };
struct SkillLineEntry { uint32 categoryId; };
template<class T> struct Store {
    std::map<uint32,T> entries;
    T const* LookupEntry(uint32 id){auto i=entries.find(id);return i==entries.end()?nullptr:&i->second;}
};
Store<SkillRaceClassInfoEntry> sSkillRaceClassInfoStore;
Store<SkillLineEntry> sSkillLineStore;
struct PlayerInfo { std::vector<uint32> skills; };
struct ObjectMgr {
    PlayerInfo shaman;
    PlayerInfo const* GetPlayerInfo(uint32 race,uint32 cl){return race==1 && cl==7?&shaman:nullptr;}
} objectMgr;
auto sObjectMgr=&objectMgr;
struct Player {
    uint32 race=1,cl=7,level=60;
    std::map<uint32,std::pair<uint32,uint32>> skills;
    uint32 learned=0;
    uint32 GetRace(){return race;} uint32 GetClass(){return cl;} uint32 GetLevel(){return level;}
    uint32 GetSkillValue(uint32 id){return skills[id].first;}
    uint32 GetMaxSkillValue(uint32 id){return skills[id].second;}
    void LearnDefaultSkill(SkillRaceClassInfoEntry const* row){skills[row->SkillId]={1,1};++learned;}
};
struct BotFactory { Player* bot; bool botAI; void RepairEquipmentProficiencies(); };
FUNCTION
int main() {
    objectMgr.shaman.skills={1,2,3,4,5,6,7};
    sSkillRaceClassInfoStore.entries={{1,{413,40}},{2,{414,1}},{3,{43,1}},
        {4,{164,1}},{5,{293,80}},{6,{9999,1}}};
    sSkillLineStore.entries={{413,{SKILL_CATEGORY_ARMOR}},{414,{SKILL_CATEGORY_ARMOR}},
        {43,{SKILL_CATEGORY_WEAPON}},{164,{SKILL_CATEGORY_PROFESSION}},{293,{SKILL_CATEGORY_ARMOR}}};
    Player bot;bot.skills={{413,{0,0}},{414,{1,1}},{43,{150,300}},{164,{0,0}}};
    BotFactory factory{&bot,true};factory.RepairEquipmentProficiencies();
    assert(bot.GetSkillValue(413)==1 && bot.GetMaxSkillValue(413)==1);
    assert(bot.GetSkillValue(43)==150 && bot.GetMaxSkillValue(43)==300);
    assert(bot.GetSkillValue(164)==0 && bot.GetSkillValue(293)==0);
    assert(bot.learned==1);
    factory.RepairEquipmentProficiencies();assert(bot.learned==1);
    bot.skills[413]={1,0};factory.RepairEquipmentProficiencies();assert(bot.GetMaxSkillValue(413)==1);
    bot.skills.erase(413);factory.RepairEquipmentProficiencies();assert(bot.GetSkillValue(413)==1);
    bot.skills[413]={0,0};bot.level=20;factory.RepairEquipmentProficiencies();assert(bot.GetSkillValue(413)==0);
    bot.level=60;factory.botAI=false;factory.RepairEquipmentProficiencies();assert(bot.GetSkillValue(413)==0);
    factory.botAI=true;bot.cl=1;factory.RepairEquipmentProficiencies();assert(bot.GetSkillValue(413)==0);
    factory.bot=nullptr;factory.RepairEquipmentProficiencies();
    std::cout<<"Equipment proficiency repair checks passed\n";
}
'''
with tempfile.TemporaryDirectory(prefix='proficiency-test-') as directory:
    directory=Path(directory)
    (directory/'test.cpp').write_text(harness.replace('FUNCTION',source[start:end]))
    subprocess.run(['c++','-std=c++17','-Wall','-Wextra','-Werror',str(directory/'test.cpp'),'-o',str(directory/'test')],check=True)
    subprocess.run([str(directory/'test')],check=True,timeout=10)
