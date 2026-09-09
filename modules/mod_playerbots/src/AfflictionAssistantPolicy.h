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
    UnendingResolve = 104773, Soulstone = 20707
};

enum GlyphSlot : unsigned
{
    GlyphUA, GlyphSoulstone, GlyphLifeTap, GlyphNightmares,
    GlyphUnendingBreath, GlyphGateway, GlyphEternalResolve,
    GlyphSiphonLife, GlyphHealthstone, GlyphCount
};
struct GlyphInfo { uint32_t Aura; char const* Name; };
static std::array<GlyphInfo, GlyphCount> const GlyphCatalog = {{
    {56233, "Unstable Affliction"}, {56231, "Soulstone"}, {63320, "Life Tap"},
    {56232, "Nightmares"}, {58079, "Unending Breath"}, {135557, "Gateway Attunement"},
    {148683, "Eternal Resolve"}, {56218, "Siphon Life"}, {56224, "Healthstone"}
}};
using GlyphProfile = std::array<bool, GlyphCount>;
template<class HasAura>
GlyphProfile ReadGlyphs(HasAura hasAura)
{
    GlyphProfile result{};
    for (unsigned i = 0; i < GlyphCount; ++i) result[i] = hasAura(GlyphCatalog[i].Aura);
    return result;
}

inline int DotRefreshLead(unsigned castTime, unsigned globalCooldown)
{
    // A cast-time DoT lands before its GCD ends when Glyph of UA is active.
    return static_cast<int>(castTime ? castTime : globalCooldown) + 250;
}

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
    GlyphProfile Glyphs{};
    float HealAbsorbPct = 0;
    float NextTapAbsorbPct = 15;
    float NextTapHealthCostPct = 15;
    bool TakingDamage = false;
    bool SelectedDeadAlly = false;
    bool ResurrectionPending = false;
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

inline bool CanLifeTap(State const& state, bool critical)
{
    if (state.Health <= 15) return false; // the core's spell check, even with glyph
    if (!state.Glyphs[GlyphLifeTap])
        return state.Health > (critical ? 45 : 65) &&
            state.Health - state.NextTapHealthCostPct > (critical ? 30 : 50);

    // Glyphed taps cost future healing, not current health. Permit low-health
    // recovery when not taking damage, but bound the projected absorb stack.
    float const projected = state.HealAbsorbPct + state.NextTapAbsorbPct;
    if (state.TakingDamage)
        return state.Health > (critical ? 40 : 65) && projected <= (critical ? 30 : 15);
    return state.Health > (critical ? 15 : 40) && projected <= (critical ? 60 : 30);
}

template<class CanUse>
Action Select(State const& state, CanUse canUse)
{
    if (state.Casting) return {};
    if (state.SelectedDeadAlly)
    {
        Action const resurrection = {Soulstone, 0,
            state.Glyphs[GlyphSoulstone] ? "SOULSTONE_GLYPH" : "SOULSTONE_REZ"};
        return !state.ResurrectionPending && canUse(resurrection) ? resurrection : Action{};
    }
    if (state.Targets.empty()) return {};
    std::vector<Action> actions;
    auto add = [&](uint32_t spell, int target, char const* reason)
    { actions.push_back({spell, target, reason}); };
    if (state.InCombat && state.Health <= 40 && !state.Glyphs[GlyphEternalResolve])
        add(UnendingResolve, -1, "BURST_DEFENSE");
    char const* const tapReason = state.Glyphs[GlyphLifeTap] ? "RESTORE_MANA_GLYPH" : "RESTORE_MANA";
    if (state.Mana < 15 && CanLifeTap(state, true))
        add(LifeTap, -1, tapReason);

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
    if (state.Mana < 30 && CanLifeTap(state, false))
        add(LifeTap, -1, tapReason);
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
