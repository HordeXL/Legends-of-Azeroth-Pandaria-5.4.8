# Group PvE pull coordination — September 8, 2026

This supersedes the four-second per-target pet gate and the requirement that
every member of a pack currently attack a tank. It applies to bot group PvE;
PvP and solo pet behavior retain their existing paths.

## Player starts as DPS

A real attack starts the pull even when the requester is DPS. Party attackers,
active attack targets and positive threat on an active hostile qualify. Merely
selecting an idle creature or the creature's zone-combat flag does not qualify.
The designated tank may approach immediately. A second tank may also approach
to rescue a non-tank. With no diamond, real tank master or tank group leader,
the lowest-GUID living same-map tank is the stable pull-tank fallback.

## Opening and area damage

The group shares a three-second clock and initial target. During the opening,
bot DPS focus that target; friendly healing, defenses, interrupts and tank
collection remain available. Melee approach checks still prevent meeting a
ranged tank pull halfway. After three seconds, AoE and assisting pets may engage
the pack collected within eight yards of either living tank, even if one enemy
has temporarily taken aggro on a non-tank. Each area spell still checks its
possible victims for unpulled enemies and breakable crowd control.

Changing targets or pets does not restart the clock. When the opening target
dies, another observed pack member becomes the focus without restarting it.
No remaining engaged targets resets the state; a disjoint newly observed pack
also starts a new opening. State is keyed by group/map/instance, contains GUIDs
rather than retained unit pointers, and expires when unused.

## Tank cooperation

Normal attacks from either tank are allowed. Automatic taunts only rescue
non-tanks, not transfer tank-held bosses. The closest available bot tank is
chosen, with GUID as a tie breaker; learning, cooldown, control loss, range,
line of sight and spell immunity checks remain in force. The threat manager's
victim distinguishes a boss targeting someone with an ability from an aggro
loss. The actual attack victim also suppresses a duplicate taunt before the
cached threat reference catches up. Automatic mass taunts remain suppressed.
This does not implement encounter-specific boss tank swaps.

## Protection CombatAssistant548

The one-button server recommendation has a dedicated Protection path: emergency
survival, Righteous Fury, rescue taunt, interrupt, Sacred Shield/Seal of Insight,
Shield of the Righteous mitigation/resource cap, then collection and Holy Power
builders. Its automatic defensive list does not choose Divine Shield while
tanking. Recommendations are recalculated on the actual button press. The Lua
change adds explanations for the three new tank reasons.

## Verification

- `test_pull_coordination.ps1` compiles seven extracted production helper bodies
  with mocks: DPS pulls, opening focus, collection by either tank, taunt election
  and fallback, stale threat references, CC, immunity and separate pulls.
- `test_pet_pull.ps1` tests the production shared clock, including target changes,
  pack replacement, combat end and the wrapping millisecond counter.
- Updated LFR movement/fallback checks, shaman totem, loadout and PvE rotation
  regression suites run alongside these checks.
- Build `worldserver` for `RelWithDebInfo|x64` before deployment.

Live validation remains necessary: pull as DPS with two bot tanks, then as tank;
check the opening focus and AoE after collection, force a non-tank aggro loss,
and repeat with one taunt unavailable. Verify pets switch without a new wait,
an untouched nearby pack remains untouched, and a boss targeting a DPS with a
spell does not provoke a taunt war. The server is not started by this change.
