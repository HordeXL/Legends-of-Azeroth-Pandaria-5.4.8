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
    std::cout << "Affliction assistant: " << checks << " checks passed\n";
}
