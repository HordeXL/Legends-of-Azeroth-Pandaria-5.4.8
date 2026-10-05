/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "RSStrategy.h"
#include "RSMultipliers.h"

void RaidRsStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{

    triggers.push_back(new TriggerNode("rs baltharus brand",
        NextAction::array(0, new NextAction("rs baltharus brand", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs baltharus tank position",
        NextAction::array(0, new NextAction("rs baltharus tank position", ACTION_RAID + 6), nullptr)));
    triggers.push_back(new TriggerNode("rs baltharus avoid front",
        NextAction::array(0, new NextAction("rs baltharus avoid front", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("rs baltharus healer position",
        NextAction::array(0, new NextAction("rs baltharus healer position", ACTION_RAID + 4), nullptr)));

    triggers.push_back(new TriggerNode("rs saviana conflagration",
        NextAction::array(0, new NextAction("rs saviana conflagration", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs saviana avoid front",
        NextAction::array(0, new NextAction("rs saviana avoid front", ACTION_RAID + 6), nullptr)));
    triggers.push_back(new TriggerNode("rs saviana tank position",
        NextAction::array(0, new NextAction("rs saviana tank position", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs saviana melee spread",
        NextAction::array(0, new NextAction("rs saviana melee spread", ACTION_RAID + 7), nullptr)));

    triggers.push_back(new TriggerNode("rs zarithrian adds",
        NextAction::array(0, new NextAction("rs zarithrian adds", ACTION_RAID + 5), new NextAction("attack rti target", ACTION_RAID + 4), nullptr)));

    triggers.push_back(new TriggerNode("rs zarithrian tank",
        NextAction::array(0, new NextAction("rs zarithrian tank", ACTION_RAID + 6), nullptr)));

    triggers.push_back(new TriggerNode("rs halion start position",
        NextAction::array(0, new NextAction("rs halion start position", ACTION_RAID + 6), nullptr)));
    triggers.push_back(new TriggerNode("rs halion combustion",
        NextAction::array(0, new NextAction("rs halion combustion", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs halion meteor",
        NextAction::array(0, new NextAction("rs halion meteor", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs halion fire",
        NextAction::array(0, new NextAction("rs halion fire", ACTION_RAID + 10), nullptr)));
    triggers.push_back(new TriggerNode("rs halion tank position",
        NextAction::array(0, new NextAction("rs halion tank position", ACTION_RAID + 6), new NextAction("attack rti target", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("rs halion avoid cones",
        NextAction::array(0, new NextAction("rs halion avoid cones", ACTION_RAID + 5), nullptr)));

    triggers.push_back(new TriggerNode("rs halion adds",
        NextAction::array(0, new NextAction("rs halion adds", ACTION_RAID + 6), new NextAction("attack rti target", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("rs halion add tank",
        NextAction::array(0, new NextAction("rs halion add tank", ACTION_RAID + 6), nullptr)));

    triggers.push_back(new TriggerNode("rs halion enter portal",
        // Realm assignment must win over emergency healing. Otherwise the
        // selected Twilight healer keeps casting in the physical realm and
        // both healers appear to have been assigned to stay outside.
        NextAction::array(0, new NextAction("rs halion enter portal", ACTION_EMERGENCY + 10), nullptr)));
    triggers.push_back(new TriggerNode("rs halion cutter",
        NextAction::array(0, new NextAction("rs halion cutter", ACTION_RAID + 8), nullptr)));
    triggers.push_back(new TriggerNode("rs halion consumption",
        NextAction::array(0, new NextAction("rs halion consumption", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs halion heal consumption",
        NextAction::array(0, new NextAction("rs halion heal consumption", ACTION_RAID + 7), nullptr)));
    triggers.push_back(new TriggerNode("rs halion p2 tank position",
        NextAction::array(0, new NextAction("rs halion p2 tank position", ACTION_RAID + 6), new NextAction("attack rti target", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("rs halion p2 avoid cones",
        NextAction::array(0, new NextAction("rs halion p2 avoid cones", ACTION_RAID + 5), new NextAction("attack rti target", ACTION_RAID + 4), nullptr)));

    triggers.push_back(new TriggerNode("rs trash main tank",
        NextAction::array(0, new NextAction("rs trash main tank", ACTION_RAID + 6), nullptr)));
    triggers.push_back(new TriggerNode("rs trash assist tank",
        NextAction::array(0, new NextAction("rs trash assist tank", ACTION_RAID + 6), nullptr)));
    triggers.push_back(new TriggerNode("rs trash ranged",
        NextAction::array(0, new NextAction("rs trash ranged", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("rs trash melee flank",
        NextAction::array(0, new NextAction("rear flank", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("rs trash adds",
        NextAction::array(0, new NextAction("rs trash adds", ACTION_RAID + 5), new NextAction("attack rti target", ACTION_RAID + 4), nullptr)));
}

void RaidRsStrategy::InitMultipliers(std::vector<Multiplier*>& multipliers)
{
    multipliers.push_back(new RsBaltharusBrandSafeMultiplier(botAI));
    multipliers.push_back(new RsSavianaBeaconMultiplier(botAI));
    multipliers.push_back(new RsSavianaMeleeSpreadMultiplier(botAI));
    multipliers.push_back(new RsZarithrianAddsMultiplier(botAI));
    multipliers.push_back(new RsZarithrianTankSwapMultiplier(botAI));
    multipliers.push_back(new RsHalionCombustionMultiplier(botAI));
    multipliers.push_back(new RsHalionMeteorMultiplier(botAI));
    multipliers.push_back(new RsHalionMeleeFlankMultiplier(botAI));
    multipliers.push_back(new RsHalionP2Multiplier(botAI));
    multipliers.push_back(new RsHalionHpBalanceMultiplier(botAI));
    multipliers.push_back(new RsHalionRealmIsolationMultiplier(botAI));
    multipliers.push_back(new RsTrashAddsMultiplier(botAI));
}
