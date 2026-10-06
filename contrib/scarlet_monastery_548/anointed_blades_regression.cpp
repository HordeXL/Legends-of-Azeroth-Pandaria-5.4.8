// Exercise the production OnCheckCast implementation. The core invokes this
// hook in CheckCast before TakeCastItem; failed checks must leave the item intact.
#include <cassert>
#include <cstdint>
#include <iostream>
using uint32 = std::uint32_t;
enum SpellCastResult { SPELL_CAST_OK, SPELL_FAILED_BAD_TARGETS, SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW, SPELL_FAILED_OUT_OF_RANGE };
enum { DUNGEON_DIFFICULTY_NORMAL = 1, DUNGEON_DIFFICULTY_HEROIC = 2,
       QUEST_STATUS_INCOMPLETE = 3, BOSS_WHITEMANE = 2, DONE = 3,
       NPC_HIGH_INQUISITOR_WHITEMANE = 3977 };
struct ObjectGuid
{
    uint32 value;
    ObjectGuid(uint32 id = 0) : value(id) { }
    bool IsEmpty() const { return value == 0; }
    bool operator!=(ObjectGuid other) const { return value != other.value; }
};
struct Player;
struct Unit
{
    ObjectGuid guid = 100;
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
    ObjectGuid GetGUID() const { return guid; }
};
struct Creature : Unit
{
    uint32 entry = 3977;
    bool dead = true;
    uint32 GetEntry() const { return entry; }
    bool isDead() const { return dead; }
};
struct Map { uint32 difficulty = 1; uint32 GetDifficulty() const { return difficulty; } };
struct InstanceScript
{
    uint32 state = DONE;
    Creature* corpse = nullptr;
    uint32 GetBossState(uint32) const { return state; }
    ObjectGuid GetGuidData(uint32) const { return corpse ? corpse->guid : ObjectGuid(); }
};
struct Player : Unit
{
    Map map;
    uint32 mapId = 1004, questId = 31514, questStatus = QUEST_STATUS_INCOMPLETE;
    ObjectGuid selected;
    InstanceScript* instance = nullptr;
    float distance = 5.0f;
    bool sameMap = true;
    Player* ToPlayer() override { return this; }
    uint32 GetMapId() const { return mapId; }
    Map* GetMap() { return &map; }
    uint32 GetQuestStatus(uint32 id) const { return id == questId ? questStatus : 0; }
    InstanceScript* GetInstanceScript() { return instance; }
    ObjectGuid GetTarget() const { return selected; }
    bool IsWithinDistInMap(Creature*, float range) const { return sameMap && distance <= range; }
};
namespace ObjectAccessor
{
    Creature* GetCreature(Player& player, ObjectGuid guid)
    {
        return player.instance && player.instance->corpse && !(player.instance->corpse->guid != guid) ? player.instance->corpse : nullptr;
    }
}
struct SpellInfo { uint32 Id = 126787; };
struct SpellScript
{
    Unit* caster = nullptr;
    Unit* explicitTarget = nullptr;
    SpellInfo info;
    struct Hook { template<class T> void operator+=(T) { } } OnCheckCast;
    virtual ~SpellScript() = default;
    virtual void Register() { }
    Unit* GetCaster() { return caster; }
    Unit* GetExplTargetUnit() { return explicitTarget; }
    SpellInfo const* GetSpellInfo() { return &info; }
};
#define PrepareSpellScript(name) public:
#define SpellCheckCastFn(function) &function
#include "blades.inc"
struct Fixture
{
    Player player;
    Creature corpse;
    InstanceScript instance;
    spell_sc_blades_of_the_anointed spell;
    unsigned items = 1, credits = 0;
    explicit Fixture(bool heroic)
    {
        instance.corpse = &corpse;
        player.instance = &instance;
        player.map.difficulty = heroic ? 2 : 1;
        player.questId = heroic ? 31516 : 31514;
        spell.info.Id = heroic ? 126843 : 126787;
        spell.caster = &player;
    }
    void Use(bool allowed)
    {
        SpellCastResult result = spell.CheckCast();
        if (result == SPELL_CAST_OK) { --items; ++credits; }
        assert((result == SPELL_CAST_OK) == allowed);
        assert(items == (allowed ? 0u : 1u));
        assert(credits == (allowed ? 1u : 0u));
    }
};
int main()
{
    for (bool heroic : { false, true })
    {
        { Fixture f(heroic); f.player.selected = f.corpse.guid; f.Use(true); }
        { Fixture f(heroic); f.Use(true); } // Nearby corpse, no manual target.
        { Fixture f(heroic); f.player.selected = 60040; f.Use(false); } // Durand selected.
        { Fixture f(heroic); Unit wrong; wrong.guid = 60040; f.spell.explicitTarget = &wrong; f.Use(false); }
        { Fixture f(heroic); f.corpse.dead = false; f.Use(false); }
        { Fixture f(heroic); f.corpse.entry = 60040; f.Use(false); }
        { Fixture f(heroic); f.instance.corpse = nullptr; f.Use(false); }
        { Fixture f(heroic); f.instance.state = 1; f.Use(false); }
        { Fixture f(heroic); f.player.instance = nullptr; f.Use(false); }
        { Fixture f(heroic); f.player.distance = 10.1f; f.Use(false); }
        { Fixture f(heroic); f.player.sameMap = false; f.Use(false); }
        { Fixture f(heroic); f.player.mapId = 189; f.Use(false); }
        { Fixture f(heroic); f.player.map.difficulty = heroic ? 1 : 2; f.Use(false); }
        { Fixture f(heroic); f.player.map.difficulty = 8; f.Use(false); }
        { Fixture f(heroic); f.player.questStatus = 0; f.Use(false); }
        { Fixture f(heroic); f.player.questStatus = 1; f.Use(false); }
        { Fixture f(heroic); f.player.questId = heroic ? 31514 : 31516; f.Use(false); }
        { Fixture f(heroic); Unit nonPlayer; f.spell.caster = &nonPlayer; f.Use(false); }
    }
    std::cout << "Blades cast checks passed: both variants; invalid corpse, selection, range, quest and mode preserve the item.\n";
}
