#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <vector>
using uint8 = uint8_t;
using uint16 = uint16_t;
using uint32 = uint32_t;
constexpr uint8 MAX_QUEST_LOG_SIZE = 25;
constexpr int QUEST_STATUS_COMPLETE = 1, QUEST_STATUS_INCOMPLETE = 3;
constexpr int QUEST_OBJECTIVE_ITEM = 1, QUEST_OBJECTIVE_MIN_REPUTATION = 6,
    QUEST_OBJECTIVE_MAX_REPUTATION = 7;
struct ObjectGuid { static constexpr int Empty = 0; };
struct FactionEntry { uint32 ID; };
struct Objective { uint32 ID; int Type; uint32 ObjectID; int Amount; };
struct Quest
{
    std::vector<Objective> Objectives;
    bool HasQuestObjectiveType(int type) const
    {
        return std::any_of(Objectives.begin(), Objectives.end(),
            [type](auto const& o) { return o.Type == type; });
    }
};
struct ObjectMgr
{
    std::map<uint32, Quest> quests;
    Quest const* GetQuestTemplate(uint32 id) const
    {
        auto it = quests.find(id);
        return it == quests.end() ? nullptr : &it->second;
    }
} objectMgr;
ObjectMgr* sObjectMgr = &objectMgr;
struct QuestStatusData { int Status = QUEST_STATUS_INCOMPLETE; };
struct ReputationMgr
{
    std::map<uint32, int> values;
    int GetReputation(FactionEntry const* f) const { return values.at(f->ID); }
};
struct Player
{
    std::array<uint32, MAX_QUEST_LOG_SIZE> slots{};
    std::map<uint32, QuestStatusData> m_QuestStatus;
    std::map<uint32, uint32> m_questObjectiveStatus;
    ReputationMgr rep;
    int worldUpdates = 0, creditUpdates = 0;
    uint32 GetQuestSlotQuestId(uint8 i) const { return slots[i]; }
    uint32 GetQuestObjectiveCounter(uint32 id) const
    {
        auto it = m_questObjectiveStatus.find(id);
        return it == m_questObjectiveStatus.end() ? 0 : it->second;
    }
    ReputationMgr& GetReputationMgr() { return rep; }
    void MarkQuestObjectiveToSave(uint32, uint32) {}
    void SendQuestUpdateAddCredit(Quest const*, Objective const*, int, uint32, uint16) { ++creditUpdates; }
    bool CanCompleteQuest(uint32 id) const
    {
        for (auto const& o : sObjectMgr->quests.at(id).Objectives)
        {
            if (o.Type == QUEST_OBJECTIVE_ITEM && GetQuestObjectiveCounter(o.ID) < uint32(o.Amount))
                return false;
            if (o.Type == QUEST_OBJECTIVE_MIN_REPUTATION && rep.values.at(o.ObjectID) < o.Amount)
                return false;
            if (o.Type == QUEST_OBJECTIVE_MAX_REPUTATION && rep.values.at(o.ObjectID) > o.Amount)
                return false;
        }
        return true;
    }
    void CompleteQuest(uint32 id) { m_QuestStatus[id].Status = QUEST_STATUS_COMPLETE; }
    void IncompleteQuest(uint32 id) { m_QuestStatus[id].Status = QUEST_STATUS_INCOMPLETE; }
    void UpdateForQuestWorldObjects() { ++worldUpdates; }
    void ItemAddedQuestCheck(uint32, uint32);
    void ReputationChangedQuestCheck(FactionEntry const*);
};
#include "methods.inc"
int main()
{
    // Hunter boots and helm both require Stone Scarabs; looting five must
    // update both objectives even while the first quest is not yet complete.
    sObjectMgr->quests = {
        {8626, {{{1, QUEST_OBJECTIVE_ITEM, 20858, 5}, {2, QUEST_OBJECTIVE_MIN_REPUTATION, 910, 0}}}},
        {8657, {{{3, QUEST_OBJECTIVE_ITEM, 20858, 5}, {4, QUEST_OBJECTIVE_MIN_REPUTATION, 910, 3000}}}},
        {9999, {{{5, QUEST_OBJECTIVE_ITEM, 20859, 5}}}},
        {9998, {{{6, QUEST_OBJECTIVE_MAX_REPUTATION, 910, 100}}}}
    };
    Player p;
    p.slots[0] = 8626; p.slots[2] = 8657; p.slots[3] = 9999;
    p.rep.values = {{910, -100}, {609, -1000}};
    p.ItemAddedQuestCheck(20858, 3);
    assert(p.GetQuestObjectiveCounter(1) == 3 && p.GetQuestObjectiveCounter(3) == 3);
    assert(p.GetQuestObjectiveCounter(5) == 0);
    p.ItemAddedQuestCheck(20858, 9);
    assert(p.GetQuestObjectiveCounter(1) == 5 && p.GetQuestObjectiveCounter(3) == 5);
    assert(p.worldUpdates == 2 && p.creditUpdates == 4);
    FactionEntry brood{910}, cenarion{609};
    p.rep.values[910] = 0;
    p.ReputationChangedQuestCheck(&brood);
    assert(p.m_QuestStatus[8626].Status == QUEST_STATUS_COMPLETE);
    assert(p.m_QuestStatus[8657].Status == QUEST_STATUS_INCOMPLETE);
    p.ReputationChangedQuestCheck(&cenarion);
    assert(p.m_QuestStatus[8626].Status == QUEST_STATUS_COMPLETE); // Unrelated faction must not invalidate it.
    p.rep.values[910] = 3000;
    p.ReputationChangedQuestCheck(&brood);
    assert(p.m_QuestStatus[8657].Status == QUEST_STATUS_COMPLETE);
    p.rep.values[910] = 2999;
    p.ReputationChangedQuestCheck(&brood);
    assert(p.m_QuestStatus[8657].Status == QUEST_STATUS_INCOMPLETE);
    assert(p.m_QuestStatus[8626].Status == QUEST_STATUS_COMPLETE);
    p.slots[4] = 9998;
    p.m_QuestStatus[9998].Status = QUEST_STATUS_INCOMPLETE;
    p.rep.values[910] = 100;
    p.ReputationChangedQuestCheck(&brood);
    assert(p.m_QuestStatus[9998].Status == QUEST_STATUS_COMPLETE);
    p.rep.values[609] = 500;
    p.ReputationChangedQuestCheck(&cenarion);
    assert(p.m_QuestStatus[9998].Status == QUEST_STATUS_COMPLETE);
    p.rep.values[910] = 101;
    p.ReputationChangedQuestCheck(&brood);
    assert(p.m_QuestStatus[9998].Status == QUEST_STATUS_INCOMPLETE);
    assert(!p.m_QuestStatus.count(0));
    std::cout << "AQ40 quest progress regression checks passed\n";
}
