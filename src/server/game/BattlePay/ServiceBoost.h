/*
* This file is part of the Pandaria 5.4.8 Project. See THANKS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef CHARACTER_BOOST_H
#define CHARACTER_BOOST_H

enum CharBoostMisc
{
    // Items
    ITEM_HEARTHSTONE                         = 6948,
    ITEM_FROSTWEAVE_BAG                      = 41599,
    ITEM_EMBERSILK_BAG                       = 54443,
    ITEM_BAKED_MANTA_RAY                     = 42942,
    ITEM_HEAVY_FROSTWEAVE_BANDAGE            = 34722,
    ITEM_LEMON_FLAVOUR_PUDING                = 108920,
    // Spells
    SPELL_SWIFT_PURPLE_WIND_RIDER            = 32297,
    SPELL_SWIFT_PURPLE_GRYPGON               = 32292,
    SPELL_APPRENTICE_RIDING                  = 33388,
    SPELL_JOURNEYMAN_RIDING                  = 33391,
    SPELL_EXPERT_RIDING                      = 34090,
    // Misc
    MAP_VALE_OF_ETERNAL_BLOSSOMS             = 870,
    MAIL_CHARRACTER_BOOST_EQUIPED_ITEMS_BODY = 403,
    // Profession spells
    SPELL_FIRST_AID                          = 110406,
    SPELL_COOKING                            = 104381,
    SPELL_FISHING                            = 110410,
    SPELL_ARCHAEOLOGY                        = 110393,
    SPELL_TAILORING                          = 110426,
    SPELL_ENGINEERING                        = 110403,
    SPELL_ALCHEMY                            = 105206,
    SPELL_SKINNING                           = 102216,
    SPELL_MINING                             = 102161,
    SPELL_HERBALISM                          = 110413,
    SPELL_INSCRIPTION                        = 110417,
    SPELL_JEWELCRAFTING                      = 110420,
    SPELL_BLACKSMITHING                      = 110396,
    SPELL_LEATHERWORKING                     = 110423,
    SPELL_ENCHANTING                         = 110400,
    // Riding spells
    SPELL_ARTISAN_RIDING                     = 34091,
    SPELL_COLD_WHEATHER_FLYING               = 54197,
    SPELL_FLIGHT_MASTER_LICENSE              = 90267,
    SPELL_WISDOM_OF_FOUR_WINDS               = 115913,
};

enum CharacterBoostTier : uint8
{
    CHARACTER_BOOST_TIER_LEGACY              = 0,
    CHARACTER_BOOST_TIER_LEVEL_80            = 80,
    CHARACTER_BOOST_TIER_LEVEL_90            = 90,
};

struct CharacterBoostLocation
{
    uint16 map;
    uint16 area;
    float x;
    float y;
    float z;
    float orientation;
};

// Level 80 characters start in their faction capital. Level 90 characters
// start at their faction shrine in the Vale of Eternal Blossoms.
CharacterBoostLocation const boostLocations[2][2] =
{
    {
        { 1, 1637, 1577.41f, -4453.68f, 15.6648f, 1.8708f }, // Horde, Orgrimmar
        { 0, 1519, -8867.68f, 673.373f, 97.9034f, 5.3070f }, // Alliance, Stormwind
    },
    {
        { 870, 6554, 1605.908f, 921.2222f, 470.6227f, 0.124413f }, // Horde shrine
        { 870, 6553, 880.6965f, 296.6945f, 503.1162f, 3.779655f }, // Alliance shrine
    },
};

struct CharacterBoostData
{
    CharacterBoostData() : charGuid(ObjectGuid::Empty), action(0), specialization(0), boostLevel(CHARACTER_BOOST_TIER_LEGACY), allianceFaction(false) { }

    ObjectGuid charGuid;
    uint32 action;
    uint32 specialization;
    uint8 boostLevel;
    bool allianceFaction;
};

struct BoostItems
{
    BoostItems() : spec(0), slot(0), itemId(0) { }

    uint32 spec;
    uint32 slot;
    uint32 itemId;
};
typedef std::vector<BoostItems*> BoostItemsVector;

typedef std::map<uint8 /*slot*/, uint32 /*ItemId*/> PreparedItemsMap;

void LoadBoostItems();
void SetBoosting(WorldSession* session, uint32 accountId, bool boost, uint8 boostLevel = CHARACTER_BOOST_TIER_LEGACY);
bool IsCharacterBoostProduct(uint32 productId);
uint8 GetCharacterBoostTierForProduct(uint32 productId);

static BoostItemsVector mBoostItemsMap;

class CharacterBooster
{
    public:
        CharacterBooster(WorldSession* session);

        uint32 GetCurrentAction() const { return m_charBoostInfo.action; }
        ObjectGuid::LowType GetGuidLow() const { return m_charBoostInfo.charGuid.GetCounter(); }
        void HandleCharacterBoost();
        bool IsBoosting(ObjectGuid::LowType lowGuid) const { return m_boosting && (m_charBoostInfo.charGuid.GetCounter() == lowGuid); }
        void SetBoostedCharInfo(ObjectGuid guid, uint32 action, uint32 specialization, bool allianceFaction);
        void Update(uint32 diff);
        void SendCharBoostPacket(PreparedItemsMap items) const;

    private:
        void _GetCharBoostItems(PreparedItemsMap& itemsToMail, PreparedItemsMap& itemsToEquip) const;
        std::string _EquipItems(CharacterDatabaseTransaction trans, PreparedItemsMap itemsToEquip) const;
        void _GetBoostedCharacterData(uint8& raceId, uint8& classId, uint8& level) const;
        void _HandleCharacterBoost() const;
        void _LearnSpells(CharacterDatabaseTransaction trans, uint8 targetLevel, uint8 raceId, uint8 classId) const;
        void _LearnClassSpells(CharacterDatabaseTransaction trans, uint8 targetLevel, uint8 raceId, uint8 classId) const;
        void _UpdateWeaponSkills(CharacterDatabaseTransaction trans, uint8 targetLevel, uint8 raceId, uint8 classId) const;
        void _PrepareInventory(CharacterDatabaseTransaction trans) const;
        uint32 _PrepareMail(CharacterDatabaseTransaction trans, std::string const subject, std::string const body) const;
        std::string _SetSpecialization(CharacterDatabaseTransaction trans, uint8 const classId) const;
        void _SaveBoostedChar(CharacterDatabaseTransaction trans, std::string items, uint8 targetLevel, uint8 const raceId, uint8 const classId) const;
        void _SendMail(CharacterDatabaseTransaction trans, PreparedItemsMap items) const;
        void _LearnVeteranBonuses(CharacterDatabaseTransaction trans, uint8 const classId) const;
        void LearnNonExistedSpell(CharacterDatabaseTransaction trans, uint32 spell) const;
        void LearnNonExistedSkill(CharacterDatabaseTransaction trans, uint32 skill, uint16 value = 600, uint16 max = 600) const;
        WorldSession* GetSession() const { return m_session; }

        CharacterBoostData m_charBoostInfo;
        WorldSession* m_session;
        uint32 m_timer;
        bool m_boosting;
        bool m_sendPacket;
};

#endif
