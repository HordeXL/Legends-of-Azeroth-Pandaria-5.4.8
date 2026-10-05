/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "RSScripts.h"

#include <mutex>

namespace RubySanctumHelpers
{
    static std::mutex stateMutex;
    static std::unordered_map<uint32, RsInstanceState> instanceStates;

    RsInstanceState& RsState(uint32 instanceId)
    {
        std::lock_guard<std::mutex> lock(stateMutex);
        return instanceStates[instanceId];
    }

    void ResetInstance(uint32 instanceId)
    {
        std::lock_guard<std::mutex> lock(stateMutex);
        instanceStates.erase(instanceId);
    }
}

// This core does not expose AzerothCore's AllCreatureScript hook.  The raid
// actions and triggers observe encounter state directly; keep the registration
// function so the module loader remains source-compatible.
void AddSC_RubySanctumBotScripts()
{
}
