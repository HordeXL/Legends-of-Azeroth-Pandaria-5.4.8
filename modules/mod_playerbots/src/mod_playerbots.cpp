/*
** Made by Traesh https://github.com/Traesh
** AzerothCore 2019 http://www.azerothcore.org/
** Conan513 https://github.com/conan513
** Made into a module by Micrah https://github.com/milestorme/
*/

#include "Chat.h"
#include "BattlegroundMgr.h"
#include "ChannelMgr.h"
#include "Config.h"
#include "Creature.h"
#include "cs_playerbots.h"
#include "GossipDef.h"
#include "Log.h"
#include "Map.h"
#include "Opcodes.h"
#include "Player.h"
#include "RatedPvp.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSocket.h"

#include "Playerbots.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "RandomItemManager.h"
#include "RandomPlayerbotBracketMgr.h"

#include "Authentication/AuthCrypt.h"
#include "CharacterHandler.h"

#include <boost/filesystem.hpp>
#include <vector>
#include <future>
#include <unordered_set>
#include <random>
#include <thread>

#include "CombatAssistant.h"

#ifndef _PLAYERBOT_CONFIG
# define _PLAYERBOT_CONFIG  "playerbots.conf"
#endif

namespace
{
uint32 constexpr SOLO_ARENA_GOSSIP_MENU = 8218;
uint32 constexpr SOLO_ARENA_GOSSIP_2V2 = 20;
uint32 constexpr SOLO_ARENA_GOSSIP_3V3 = 21;
uint32 constexpr SOLO_ARENA_GOSSIP_5V5 = 22;
}

class mod_playerbots : public PlayerScript
{
public:
    mod_playerbots() : PlayerScript("mod_playerbots") {}

    void OnLogin(Player* player) override
    {
        // Announce Module
        ChatHandler(player->GetSession()).SendSysMessage("This server is running the |cff4CFF00mod playerbots |rmodule.");
    }

};

class PlayerbotsWorldScript : public WorldScript
{
public:
    PlayerbotsWorldScript() : WorldScript("PlayerbotsWorldScript") {}

    void OnConfigLoad(bool reloaded) override
    {
        if (!reloaded)
        {
            uint32 oldMSTime = getMSTime();
            std::string conf_file = boost::filesystem::absolute(_PLAYERBOT_CONFIG).generic_string();

            TC_LOG_INFO("playerbots", " ");
            TC_LOG_INFO("playerbots", "Loading Playerbots Config at %s ...", conf_file.c_str());

            std::string err;
            if (!sConfigMgr->LoadAdditionalFile(conf_file, true, err))
            {
                TC_LOG_FATAL("playerbots", ">> Load playerbots failed, %s", err.c_str());
                std::this_thread::sleep_for(std::chrono::seconds(5));
                sWorld->StopNow(1);
                return;
            }
            sPlayerbotAIConfig->Initialize();

            TC_LOG_INFO("playerbots", ">> Loaded playerbots config in %u ms", GetMSTimeDiffToNow(oldMSTime));
            TC_LOG_INFO("playerbots", " ");

            sRandomPlayerbotMgr->Reserve(sPlayerbotAIConfig->maxRandomBots);
            sRandomItemMgr->Init();

            TC_LOG_INFO("playerbots", "Playerbots enabled: %s", sPlayerbotAIConfig->enabled ? "Yes" : "No");
            TC_LOG_INFO("playerbots", "Playerbots min/max to load: %u/%u", sPlayerbotAIConfig->minRandomBots, sPlayerbotAIConfig->maxRandomBots);
            TC_LOG_INFO("playerbots", "Playerbots autologin: %s", sPlayerbotAIConfig->randomBotAutologin ? "Yes" : "No");
        }
    }
    void OnUpdate(uint32 diff) override
    {
        sBracketMgr->Update(diff);
        UpdateAutomatedPvpLoadoutRecovery(diff);
        UpdateSoloArenaAutomaticQueue(diff);
        UpdateSoloArenaAutomaticExit(diff);
    }
};

class PlayerbotsServerScript : public ServerScript
{
public:
    PlayerbotsServerScript() : ServerScript("PlayerbotsServerScript") {}
    void OnPacketReceive(WorldSession* sessionBot, WorldPacket& packet) override
    {
        if (!sessionBot)
            return;

        if (packet.GetOpcode() == CMSG_BATTLEFIELD_LEAVE)
            HandleSoloArenaClientLeave(sessionBot->GetPlayer());

        if (packet.GetOpcode() == CMSG_BATTLEMASTER_JOIN_ARENA && packet.size() >= 1)
        {
            Player* player = sessionBot->GetPlayer();
            if (player && !player->GetGroup())
            {
                size_t readPosition = packet.rpos();
                uint8 arenaSlot = 0;
                packet >> arenaSlot;
                packet.rpos(readPosition);
                HandleSoloArenaAutomaticJoinRequest(player, arenaSlot);
            }
        }

        // MoP 5.4.8 disables the native Arena Join buttons for a solo player.
        // The shared Arena Battlemaster gossip menu therefore exposes three
        // explicit server-side choices. The original battlefield option and
        // normal group registration remain untouched.
        if (packet.GetOpcode() == CMSG_GOSSIP_SELECT_OPTION && packet.size() >= 8)
        {
            Player* player = sessionBot->GetPlayer();
            if (player)
            {
                size_t readPosition = packet.rpos();
                uint32 gossipListId = 0;
                uint32 menuId = 0;
                packet >> gossipListId >> menuId;

                GossipMenu const& gossipMenu = player->PlayerTalkClass->GetGossipMenu();
                GossipMenuItem const* item = gossipMenu.GetItem(gossipListId);
                uint8 arenaSlot = PVP_SLOT_MAX;
                if (gossipListId == SOLO_ARENA_GOSSIP_2V2)
                    arenaSlot = PVP_SLOT_ARENA_2v2;
                else if (gossipListId == SOLO_ARENA_GOSSIP_3V3)
                    arenaSlot = PVP_SLOT_ARENA_3v3;
                else if (gossipListId == SOLO_ARENA_GOSSIP_5V5)
                    arenaSlot = PVP_SLOT_ARENA_5v5;

                if (menuId == SOLO_ARENA_GOSSIP_MENU &&
                    menuId == gossipMenu.GetMenuId() && item &&
                    item->OptionType == GOSSIP_OPTION_GOSSIP && arenaSlot != PVP_SLOT_MAX)
                {
                    // GossipMenu::_senderGUID is not populated by this 5.4.8 core.
                    // Decode the sender from CMSG_GOSSIP_SELECT_OPTION just as the
                    // core opcode handler does instead of relying on that field.
                    ObjectGuid senderGuid;
                    uint8 boxTextLength = 0;
                    senderGuid[3] = packet.ReadBit();
                    senderGuid[0] = packet.ReadBit();
                    senderGuid[1] = packet.ReadBit();
                    senderGuid[4] = packet.ReadBit();
                    senderGuid[7] = packet.ReadBit();
                    senderGuid[5] = packet.ReadBit();
                    senderGuid[6] = packet.ReadBit();
                    boxTextLength = packet.ReadBits(8);
                    senderGuid[2] = packet.ReadBit();

                    packet.ReadByteSeq(senderGuid[7]);
                    packet.ReadByteSeq(senderGuid[3]);
                    packet.ReadByteSeq(senderGuid[4]);
                    packet.ReadByteSeq(senderGuid[6]);
                    packet.ReadByteSeq(senderGuid[0]);
                    packet.ReadByteSeq(senderGuid[5]);
                    if (item->IsCoded)
                        packet.ReadString(boxTextLength);
                    packet.ReadByteSeq(senderGuid[2]);
                    packet.ReadByteSeq(senderGuid[1]);
                    packet.rpos(readPosition);

                    if (!sPlayerbotAIConfig->autoQueueArenaAutomaticBattlemasterSolo)
                    {
                        ChatHandler(player->GetSession()).SendSysMessage(
                            "Automatic Solo Arena through Arena Battlemasters is disabled.");
                    }
                    else if (Creature* battlemaster = player->GetNPCIfCanInteractWith(senderGuid, UNIT_NPC_FLAG_BATTLEMASTER))
                    {
                        if (sBattlegroundMgr->GetBattleMasterBG(battlemaster->GetEntry()) == BATTLEGROUND_AA)
                        {
                            player->PlayerTalkClass->SendCloseGossip();
                            HandleSoloArenaAutomaticJoinRequest(player, arenaSlot);
                        }
                        else
                            ChatHandler(player->GetSession()).SendSysMessage(
                                "This NPC is not registered as an Arena Battlemaster.");
                    }
                    else
                        ChatHandler(player->GetSession()).SendSysMessage(
                            "The Arena Battlemaster is no longer close enough to use.");
                }
                else
                    packet.rpos(readPosition);
            }
        }

        Player* playerBot = sessionBot->GetPlayer();
            if (PlayerbotMgr* playerbotMgr = GET_PLAYERBOT_MGR(playerBot))
                playerbotMgr->HandleMasterIncomingPacket(packet);
    }
};

class PlayerbotsScript : public PlayerbotScript
{
public:
    PlayerbotsScript() : PlayerbotScript("PlayerbotsScript") {}

    void OnPlayerbotCheckKillTask(Player* /*player*/, Unit* /*victim*/) override
    {
    }

    void OnPlayerbotCheckPetitionAccount(Player* player, bool& found) override
    {
        if (found && GET_PLAYERBOT_AI(player))
            found = false;
    }

    bool OnPlayerbotCheckUpdatesToSend(Player* player) override
    {
        if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(player))
            return botAI->IsRealPlayer();

        return true;
    }

    void OnPlayerbotPacketSent(Player* player, WorldPacket const* packet) override
    {
        if (!player)
            return;
        
        if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(player))
        {
            botAI->HandleBotOutgoingPacket(*packet);
        }
        if (PlayerbotMgr* playerbotMgr = GET_PLAYERBOT_MGR(player))
        {
            playerbotMgr->HandleMasterOutgoingPacket(*packet);
        }
    }

    void OnPlayerbotUpdate(uint32 diff) override
    {
        sRandomPlayerbotMgr->UpdateAI(diff);
        sRandomPlayerbotMgr->UpdateSessions();
    }

    void OnPlayerbotUpdateSessions(Player* player) override
    {
        if (player)
            if (PlayerbotMgr* playerbotMgr = GET_PLAYERBOT_MGR(player))
                playerbotMgr->UpdateSessions();
    }

    void OnPlayerbotLogout(Player* player) override
    {
        if (PlayerbotMgr* playerbotMgr = GET_PLAYERBOT_MGR(player))
        {
            PlayerbotAI* botAI = GET_PLAYERBOT_AI(player);
            if (!botAI || botAI->IsRealPlayer())
            {
                playerbotMgr->LogoutAllBots();
            }
        }

        sRandomPlayerbotMgr->OnPlayerLogout(player);
    }

    void OnPlayerbotLogoutBots() override { sRandomPlayerbotMgr->LogoutAllBots(); }
};
class PlayerbotsPlayerScript : public PlayerScript
{
public:
    PlayerbotsPlayerScript() : PlayerScript("PlayerbotsPlayerScript") {}

    void OnLogin(Player* player) override
    {
        if (!player->GetSession()->IsBot())
        {
            sPlayerbotsMgr->AddPlayerbotData(player, false);
            sRandomPlayerbotMgr->OnPlayerLogin(player);

            if (sPlayerbotAIConfig->enabled || sPlayerbotAIConfig->randomBotAutologin)
            {
                std::string roundedTime =
                    std::to_string(std::ceil((sPlayerbotAIConfig->maxRandomBots * 0.11 / 60) * 10) / 10.0);
                roundedTime = roundedTime.substr(0, roundedTime.find('.') + 2);

                ChatHandler(player->GetSession()).SendSysMessage(std::string("Playerbots: bot initialization at server startup takes about '" + roundedTime + "' minutes.").c_str());
            }
        }
    }

    void OnAfterUpdate(Player* player, uint32 diff) override
    {
        if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(player))
        {
            botAI->UpdateAI(diff);
        }

        if (PlayerbotMgr* playerbotMgr = GET_PLAYERBOT_MGR(player))
        {
            playerbotMgr->UpdateAI(diff);
        }
    }
};
void AddSC_mod_playerbots()
{
    new mod_playerbots();

    new PlayerbotsServerScript();
    new PlayerbotsWorldScript();
    new PlayerbotsScript();
    new PlayerbotsPlayerScript();

    AddSC_playerbots_commandscript();
    AddSC_playerbots_combat_assistant();
}
