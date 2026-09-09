#include "../../modules/mod_playerbots/src/AfflictionAssistantPolicy.h"
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <set>

using namespace AfflictionAssistant;
unsigned checks = 0;
void check(bool condition, char const* name)
{
    ++checks;
    if (!condition) { std::cerr << "FAIL: " << name << '\n'; std::exit(1); }
}

State maintained(unsigned targets = 1)
{
    State state;
    state.InCombat = true;
    state.Pandemic = true;
    Target target;
    target.Dots = {{{24000, 24000, 1500}, {18000, 18000, 1500}, {14000, 14000, 1500}}};
    state.Targets.assign(targets, target);
    return state;
}

Action select(State const& state, std::set<uint32_t> extra = {}, std::set<uint32_t> blocked = {})
{
    std::set<uint32_t> known = {Agony, Corruption, UnstableAffliction, MaleficGrasp,
        DrainSoul, Haunt, LifeTap, FelFlame};
    known.insert(extra.begin(), extra.end());
    return Select(state, [&](Action const& action)
        { return known.count(action.Spell) && !blocked.count(action.Spell); });
}

int main()
{
    auto state = maintained();
    check(select(state).Spell == MaleficGrasp, "normal filler above execute");
    state.Targets[0].Execute = true;
    check(select(state).Spell == DrainSoul, "Drain Soul during execute");
    state = maintained();
    state.Targets.clear();
    check(!select(state), "no selected enemy");
    state = maintained(); state.Casting = true;
    check(!select(state), "do not restart an in-progress cast");

    for (unsigned d = 0; d < 3; ++d)
    {
        uint32_t const spells[] = {Agony, Corruption, UnstableAffliction};
        state = maintained(); state.Targets[0].Dots[d].Remaining = 0;
        check(select(state).Spell == spells[d], "apply each missing own DoT");
        state.Targets[0].Dots[d].Remaining = state.Targets[0].Dots[d].BaseDuration / 2;
        check(select(state).Spell == spells[d], "Pandemic at half base duration");
        ++state.Targets[0].Dots[d].Remaining;
        check(select(state).Spell == MaleficGrasp, "do not refresh above Pandemic window");
        state.Pandemic = false;
        check(select(state).Spell == MaleficGrasp, "no premature refresh without Pandemic");
        state.Targets[0].Dots[d].Remaining = 1500;
        check(select(state).Spell == spells[d], "refresh at cast lead without Pandemic");
        state.Targets[0].Dots[d].Remaining = state.Targets[0].Dots[d].BaseDuration * 3 / 4;
        state.Pandemic = true;
        check(select(state).Spell == MaleficGrasp, "extended aura does not enlarge next window");
    }

    state = maintained(); state.Shards = 1;
    check(select(state).Spell == MaleficGrasp, "reserve last shard");
    state.Shards = 2;
    check(select(state).Spell == Haunt, "spend surplus shards on Haunt");
    state.Shards = 4;
    check(select(state).Spell == Haunt, "avoid shard cap");
    state.Targets[0].HauntRemaining = 8000;
    check(select(state).Spell == MaleficGrasp, "do not overwrite fresh Haunt");
    state.Targets[0].HauntRemaining = state.Targets[0].HauntLead;
    check(select(state).Spell == Haunt, "refresh Haunt accounting for cast/travel");
    state.Shards = 1; state.DarkSoulActive = true;
    check(select(state).Spell == Haunt, "last shard allowed during Dark Soul");
    state.DarkSoulActive = false; state.Targets[0].Execute = true;
    check(select(state).Spell == Haunt, "last shard allowed during execute");
    state.Shards = 0;
    check(select(state).Spell == DrainSoul, "execute regenerates shards");

    state = maintained(); state.Mana = 10;
    check(select(state).Spell == LifeTap, "recover critical mana");
    state.Health = 45;
    check(select(state).Spell != LifeTap, "critical Life Tap health floor");
    state.Health = 46;
    check(select(state).Spell == LifeTap, "critical Life Tap above health floor");
    state.Mana = 25; state.Health = 65;
    check(select(state).Spell != LifeTap, "maintenance Life Tap health floor");
    state.Health = 66;
    check(select(state).Spell == LifeTap, "maintenance mana before filler");
    state.Health = 30;
    check(select(state, {UnendingResolve}).Spell == UnendingResolve, "defense before damage");
    state = maintained();
    check(select(state, {DarkSoul}).Spell == DarkSoul, "use available burst cooldown");
    state.InCombat = false;
    check(select(state, {DarkSoul}).Spell != DarkSoul, "do not waste burst before pull");

    state = maintained(3); state.Targets[1].Dots[1].Remaining = 0;
    auto action = select(state);
    check(action.Spell == Corruption && action.TargetIndex == 1, "two-target DoT spread");
    state.Targets[1] = maintained().Targets[0]; state.Targets[2].Dots[2].Remaining = 0;
    action = select(state);
    check(action.Spell == UnstableAffliction && action.TargetIndex == 2, "three-target DoT spread");
    state.Targets.push_back(Target{}); state.Targets[2] = maintained().Targets[0];
    check(select(state).Spell == MaleficGrasp, "bound multidot maintenance to three enemies");
    state = maintained(3);
    check(select(state, {Seed}).Spell != Seed, "no Seed without a safe four-target pack");
    state.SeedSafe = true;
    check(select(state, {Seed}).Spell == Seed, "Seed on safe engaged pack");
    state.Targets[0].SeedRemaining = 10000;
    check(select(state, {Seed}).Spell == MaleficGrasp, "amplify DoTs to detonate existing Seed");
    state.Targets[1].Dots[0].Remaining = 0;
    check(select(state, {Seed}).Spell == MaleficGrasp, "Seed mode does not spend every cast multidotting");
    state.Targets[0].Dots[0].Remaining = 0;
    check(select(state, {Seed}).Spell == Agony, "maintain primary Agony during Seed mode");

    state = maintained(); state.Targets[0].Dots = {}; state.Shards = 3;
    state.CanSoulburnSwap = true;
    check(select(state, {Soulburn}).Spell == Soulburn, "prepare learned instant DoT application");
    state.SoulburnActive = true;
    check(select(state, {Soulburn, SoulSwap}).Spell == SoulSwap, "consume Soulburn with Soul Swap");
    state.SoulburnActive = false; state.CanSoulburnSwap = false;
    check(select(state, {Soulburn}).Spell == Agony, "unknown follow-up must not waste Soulburn");
    state.CanSoulburnSwap = true; state.Shards = 0;
    check(select(state, {Soulburn}).Spell == Agony, "manual DoTs without shards");
    state = maintained(); state.SeedSafe = true; state.CanSoulburnSeed = true; state.Shards = 1;
    check(select(state, {Soulburn, Seed}).Spell == Soulburn, "prepare Soulburn Seed");
    state.SoulburnActive = true;
    check(select(state, {Soulburn, Seed}).Spell == Seed, "consume Soulburn with Seed");
    state.SeedSafe = false;
    check(select(state, {Soulburn, Seed}).Spell != Seed, "new idle or CC neighbour vetoes Seed");

    state = maintained(); state.Channel = MaleficGrasp; state.ChannelOnSelected = true;
    check(!std::strcmp(select(state).Reason, "CHANNELING"), "rapid clicks preserve channel");
    state.Shards = 4;
    check(!std::strcmp(select(state).Reason, "CHANNELING"), "wait for tick before nonurgent Haunt");
    state.JustTicked = true;
    check(select(state).Spell == Haunt, "Haunt may replace channel just after tick");
    check(!std::strcmp(select(state, {}, {Haunt}).Reason, "CHANNELING"), "failed candidate preserves channel");
    state.JustTicked = false; state.Targets[0].Dots[0].Remaining = 500;
    check(select(state).Spell == Agony, "urgent Agony may interrupt between ticks");
    state = maintained(); state.Channel = MaleficGrasp; state.ChannelOnSelected = true;
    state.Targets[0].Execute = true;
    check(select(state).Spell == DrainSoul, "switch to execute channel without waiting");
    state.Targets[0].Execute = false; state.ChannelOnSelected = false;
    check(std::strcmp(select(state).Reason, "CHANNELING") != 0, "target switch allows fresh channel");
    state = maintained();
    check(select(state, {}, {MaleficGrasp}).Spell == FelFlame, "moving fallback when channel is not castable");
    check(!Select(state, [](Action const&) { return false; }), "GCD/range/LoS failures produce no cast");

    // Effective glyphs are re-read, including removal and non-rotational minors.
    std::set<uint32_t> activeGlyphs = {56233, 56231, 63320, 56232, 58079, 135557};
    auto readGlyphs = [&]() { return ReadGlyphs([&](uint32_t id) { return activeGlyphs.count(id) != 0; }); };
    auto glyphs = readGlyphs();
    for (unsigned i = 0; i < 6; ++i) check(glyphs[i], "recognize each selected major/minor glyph");
    check(!glyphs[GlyphEternalResolve], "do not infer an unequipped glyph");
    activeGlyphs.erase(63320);
    check(!readGlyphs()[GlyphLifeTap], "glyph removal changes next snapshot");
    activeGlyphs.insert(63320);
    check(readGlyphs()[GlyphLifeTap], "glyph insertion changes next snapshot");

    state = maintained(); state.Glyphs = readGlyphs(); state.Health = 20; state.Mana = 10;
    check(select(state).Spell == LifeTap, "glyphed recovery below old health floor when not taking damage");
    check(!std::strcmp(select(state).Reason, "RESTORE_MANA_GLYPH"), "show glyph-aware mana recovery reason");
    state.Health = 15;
    check(select(state).Spell != LifeTap, "glyph respects core 15 percent health restriction");
    state.Health = 100; state.HealAbsorbPct = 45;
    check(select(state).Spell == LifeTap, "critical glyphed recovery up to projected absorb limit");
    state.HealAbsorbPct = 46;
    check(select(state).Spell != LifeTap, "block excessive accumulated healing absorb");
    state.HealAbsorbPct = 0;
    check(select(state).Spell == LifeTap, "absorbed heals or expiry permit recovery again");
    state.Mana = 25; state.HealAbsorbPct = 15;
    check(select(state).Spell == LifeTap, "maintenance permits bounded absorb stack");
    state.HealAbsorbPct = 16;
    check(select(state).Spell != LifeTap, "maintenance uses lower absorb limit");
    state.HealAbsorbPct = 0; state.Health = 40;
    check(select(state).Spell != LifeTap, "maintenance retains a health reserve with glyph");
    state.Health = 41;
    check(select(state).Spell == LifeTap, "glyph permits maintenance below old 65 percent floor");
    state.TakingDamage = true;
    check(select(state).Spell != LifeTap, "incoming damage tightens maintenance threshold");
    state.Health = 70;
    check(select(state).Spell == LifeTap, "one small absorb allowed with sufficient health under pressure");
    state.HealAbsorbPct = 1;
    check(select(state).Spell != LifeTap, "avoid extending heal absorb during incoming damage");
    state.Mana = 10; state.HealAbsorbPct = 15;
    check(select(state).Spell == LifeTap, "urgent mana uses bounded higher pressure limit");
    state.HealAbsorbPct = 16;
    check(select(state).Spell != LifeTap, "urgent recovery respects pressure absorb cap");
    state.HealAbsorbPct = 0; state.Health = 40;
    check(select(state).Spell != LifeTap, "do not block healing while taking damage at low health");
    state.Health = 41;
    check(select(state).Spell == LifeTap, "pressure health boundary permits urgent mana");
    state.Glyphs[GlyphLifeTap] = false;
    check(select(state).Spell != LifeTap, "removing glyph restores health-cost guard");
    state.Health = 46; state.NextTapHealthCostPct = 20;
    check(select(state).Spell != LifeTap, "normal tap accounts for actual health cost");
    state = maintained(); state.Glyphs[GlyphLifeTap] = true;
    state.Mana = 10; state.NextTapAbsorbPct = 20; state.HealAbsorbPct = 45;
    check(select(state).Spell != LifeTap, "read next absorb amount instead of assuming fixed cost");

    state = maintained(); state.Health = 30; state.Glyphs[GlyphEternalResolve] = true;
    check(select(state, {UnendingResolve}).Spell == MaleficGrasp, "Eternal Resolve skips disabled active ability");
    state.Glyphs[GlyphEternalResolve] = false;
    check(select(state, {UnendingResolve}).Spell == UnendingResolve, "removing Eternal Resolve restores active defense");
    check(DotRefreshLead(1500, 1500) == 1750, "normal UA cast lead");
    check(DotRefreshLead(1125, 1500) == 1375, "UA glyph shortens completion lead below GCD");
    check(DotRefreshLead(750, 1000) == 1000, "UA haste and glyph combine in native cast time");
    check(DotRefreshLead(0, 1000) == 1250, "instant DoT retains GCD input margin");

    state = State{}; state.SelectedDeadAlly = true;
    check(select(state, {Soulstone}).Spell == Soulstone, "explicit dead group target permits Soulstone");
    state.Glyphs[GlyphSoulstone] = true;
    check(!std::strcmp(select(state, {Soulstone}).Reason, "SOULSTONE_GLYPH"), "show glyphed resurrection");
    state.ResurrectionPending = true;
    check(!select(state, {Soulstone}), "do not repeat resurrection while confirmation is pending");
    state.ResurrectionPending = false; state.Casting = true;
    check(!select(state, {Soulstone}), "do not restart Soulstone cast");
    state.Casting = false;
    check(!select(state), "unknown or unavailable Soulstone is not offered");
    state.SelectedDeadAlly = false;
    check(!select(state, {Soulstone}), "no automatic resurrection target selection");
    state = maintained(); state.Glyphs = readGlyphs();
    check(select(state, {Soulstone}).Spell == MaleficGrasp, "utility glyphs do not insert utility casts into DPS");
    std::cout << "Affliction assistant: " << checks << " checks passed\n";
}
