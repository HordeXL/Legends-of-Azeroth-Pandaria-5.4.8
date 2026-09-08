#pragma once

#include <algorithm>
#include <array>
#include <cstdint>
#include <vector>

// Pure priorities shared by the live assistant and its regression tests.
namespace AfflictionAssistant
{
enum SpellId : uint32_t
{
    Agony = 980, Corruption = 172, CorruptionAura = 146739,
    UnstableAffliction = 30108, Haunt = 48181, MaleficGrasp = 103103,
    DrainSoul = 1120, LifeTap = 1454, DarkSoul = 113860,
    Soulburn = 74434, SoulSwap = 86121, SoulburnSwap = 119678,
    Seed = 27243, SoulburnSeed = 114790, FelFlame = 77799,
    UnendingResolve = 104773
};

struct Dot
{
    int Remaining = 0;
    int BaseDuration = 0;
    int CastLead = 1500;

    bool Urgent() const { return Remaining <= CastLead; }
    bool Refresh(bool pandemic) const
    {
        // Never use the aura's extended maximum as the next Pandemic window.
        return Remaining <= (pandemic ? std::max(CastLead, BaseDuration / 2) : CastLead);
    }
};

struct Target
{
    std::array<Dot, 3> Dots;
    int HauntRemaining = 0;
    int HauntLead = 1800;
    int SeedRemaining = 0;
    bool Execute = false;
};

struct State
{
    std::vector<Target> Targets; // selected enemy first, then engaged secondary enemies
    float Health = 100;
    float Mana = 100;
    unsigned Shards = 0; // whole shards, not the core's units of 100
    bool InCombat = false;
    bool Pandemic = false;
    bool DarkSoulActive = false;
    bool SoulburnActive = false;
    bool CanSoulburnSwap = false;
    bool CanSoulburnSeed = false;
    bool SeedSafe = false; // >=4 engaged enemies, no idle/CC targets in splash radius
    bool Casting = false;
    uint32_t Channel = 0;
    bool ChannelOnSelected = false;
    bool JustTicked = false;
};

struct Action
{
    uint32_t Spell = 0;
    int TargetIndex = 0; // -1 means self
    char const* Reason = "WAIT";
    explicit operator bool() const { return Spell != 0; }
};

template<class CanUse>
Action Select(State const& state, CanUse canUse)
{
    if (state.Casting || state.Targets.empty()) return {};
    std::vector<Action> actions;
    auto add = [&](uint32_t spell, int target, char const* reason)
    { actions.push_back({spell, target, reason}); };
    if (state.InCombat && state.Health <= 40)
        add(UnendingResolve, -1, "BURST_DEFENSE");
    if (state.Mana < 15 && state.Health > 45)
        add(LifeTap, -1, "RESTORE_MANA");

    Target const& primary = state.Targets.front();
    bool urgent = false;
    for (Dot const& dot : primary.Dots) urgent = urgent || dot.Urgent();
    // Repeated clicks must not restart a channel before its next tick. Urgent
    // maintenance and target/execute changes can pre-empt this boundary.
    bool const keepChannel = state.Channel && state.ChannelOnSelected &&
        !state.JustTicked && !urgent &&
        state.Channel == (primary.Execute ? DrainSoul : MaleficGrasp);
    if (keepChannel)
    {
        for (Action const& action : actions)
            if (canUse(action)) return action;
        return {state.Channel, 0, "CHANNELING"};
    }

    if (state.InCombat && !state.DarkSoulActive)
        add(DarkSoul, -1, "DARK_SOUL");

    unsigned const targetCount = state.SeedSafe ? 1u :
        static_cast<unsigned>(std::min<size_t>(3, state.Targets.size()));
    int swapTarget = -1;
    for (unsigned i = 0; i < targetCount; ++i)
    {
        unsigned due = 0;
        for (Dot const& dot : state.Targets[i].Dots)
            if (dot.Refresh(state.Pandemic)) ++due;
        if (due >= 2) { swapTarget = static_cast<int>(i); break; }
    }
    bool const seedDue = state.SeedSafe && primary.SeedRemaining <= 0;
    if (state.SoulburnActive)
    {
        if (seedDue && state.CanSoulburnSeed) add(Seed, 0, "SOULBURN_SEED");
        if (swapTarget >= 0 && state.CanSoulburnSwap)
            add(SoulSwap, swapTarget, "SOULBURN_SWAP");
    }
    else if (state.InCombat && state.Shards > 0 &&
        ((seedDue && state.CanSoulburnSeed) ||
         (swapTarget >= 0 && state.CanSoulburnSwap &&
          (state.Shards >= 2 || primary.Dots[0].Remaining <= 0))))
        add(Soulburn, -1, "PREPARE_SOULBURN");

    std::array<uint32_t, 3> const dotSpells = {{Agony, Corruption, UnstableAffliction}};
    // Keep primary DoTs ticking while setting up cleave or a Seed explosion.
    for (unsigned d = 0; d < 3; ++d)
        if (primary.Dots[d].Urgent()) add(dotSpells[d], 0, "DOT_REFRESH");
    if (seedDue) add(Seed, 0, "SEED_AOE");
    for (unsigned i = 0; i < targetCount; ++i)
        for (unsigned d = 0; d < 3; ++d)
            if (state.Targets[i].Dots[d].Refresh(state.Pandemic))
                add(dotSpells[d], static_cast<int>(i), i ? "MULTIDOT" : "DOT_REFRESH");

    // Reserve the last shard outside execute/burst; cooldown and cost checks
    // are still performed by the normal spell engine for every candidate.
    if (primary.HauntRemaining <= primary.HauntLead && state.Shards > 0 &&
        (state.Shards >= 2 || state.DarkSoulActive || primary.Execute))
        add(Haunt, 0, "HAUNT");
    if (state.Mana < 30 && state.Health > 65)
        add(LifeTap, -1, "RESTORE_MANA");
    add(primary.Execute ? DrainSoul : MaleficGrasp, 0,
        primary.Execute ? "EXECUTE" : "CHANNEL_DAMAGE");
    add(FelFlame, 0, "MOVING_DAMAGE");

    for (Action const& action : actions)
    {
        if (action.Spell == state.Channel && action.TargetIndex == 0 && state.ChannelOnSelected)
            return {state.Channel, 0, "CHANNELING"};
        if (canUse(action)) return action;
    }
    return {};
}
}
