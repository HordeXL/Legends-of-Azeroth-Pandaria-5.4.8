#ifndef _PLAYERBOT_BOTFACTORY_H
#define _PLAYERBOT_BOTFACTORY_H

#include <string>

#include "Player.h"
#include "PlayerbotAI.h"

class BotFactory
{
public:
    enum class ManagedLoadoutMode : uint8
    {
        Pve,
        Pvp
    };

    BotFactory(Player* bot, uint32 level, uint32 itemQuality = 0, uint32 gearScoreLimit = 0);

    static ObjectGuid GetRandomBot();
    static void Init();
    void Refresh();
    void Randomize(bool incremental);
    void ClearEverything();

    void InitBags();
    void InitEquipment(bool incremental, bool second_chance = false);
    void InitMissingEquipment();
    void InitEquipmentForSpec();
    void InitManagedEquipmentForSpec(uint32 minimumItemLevel);
    uint32 InitManagedEnhancements(ManagedLoadoutMode mode);
    bool PrepareManagedLoadout(ManagedLoadoutMode mode,
                               uint32 minimumItemLevel,
                               std::string* reason = nullptr);
    bool HasRequiredEquipmentForSpec(std::string* reason = nullptr) const;
    bool HasRequiredWeaponSetForSpec(std::string* reason = nullptr) const;
    void InitPet();
    void InitTalentsTree(bool reset);
    void InitGlyphs();
private:
    void InitEquipmentInternal(bool incremental, bool second_chance,
                               bool missingOnly, bool specCompatible,
                               uint32 minimumItemLevel = 0,
                               bool preserveReplaced = true);
    bool MoveEquippedItemToBag(uint8 slot);
    uint32 GetWeaponReferenceItemLevel() const;
    void Prepare();
    void CancelAuras();

    // -- GEARING
    bool CanEquipItem(ItemTemplate const* proto);
    bool CanEquipUnseenItem(uint8 slot, uint16& dest, uint32 item);
    std::vector<InventoryType> GetPossibleInventoryTypeListBySlot(EquipmentSlots slot);

    uint32 level;
protected:
    Player* bot;
    PlayerbotAI* botAI;
};

#endif
