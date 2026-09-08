# Pestilence crash and delayed PvE pet pull — 2026-09-08

## Confirmed crash cause

`Archive_worldserver.exe_[8-9_13-27-10].txt` records an access violation in `CastPestilenceAction::isUseful`, `DKActions.cpp:22`.

The preceding rotation audit requested `attackers` as `std::list<ObjectGuid>`. Its registered `AttackersValue` inherits `ObjectGuidListCalculatedValue`, which stores **GuidVector**. `AiObjectContext::GetValue<T>` uses `dynamic_cast`; the wrong requested type returns null and `AI_VALUE` dereferences it. The crash is a regression introduced by the preceding audit, not a pet movement crash.

The lookup now uses `GuidVector`. The isolated regression exercises the actual copied Pestilence function with a typed mock context, including empty/missing targets and disease/range checks. It demonstrates that the old list lookup returns null. The runner rejects a stale function copy and checks the production value storage declaration.

## Pet pull policy

- Applies to bot-controlled guardian-slot combat pets in dungeon, raid and Boss Caller PvE, including hunter pets, warlock pets, DK ghoul and water elemental. It does not redesign independently scripted temporary summons such as every Army of the Dead ghoul.
- Requires the owner to engage this exact target. A different DPS or pet taking aggro is not permission to start.
- Starts a **minimum 4000 ms delay** when this owner/target/pet engagement is observed. Changing target, replacing the pet or disengaging resets the delay.
- Even after the delay, the target must be attacking a living, same-map group player with a tank specialization, within that tank's melee range. This accepts either legitimate tank; it does not change the separate diamond/taunt policy.
- Applies the same check at trigger, action execution and pet maintenance. A pet on a stale/uncollected target is stopped, its current cast interrupted and it is recalled to follow its owner.
- Autocast maintenance and initialization do not enable active pet speed boosts/charges/leaps in group PvE. Active known rush auras are removed on maintenance; the explicit bot spell path also refuses to re-enable them. Normal run/follow speed and passive movement bonuses are not globally rewritten.
- Local 5.4.8 DBC verification covers Dash 61684, Dive 23145 and Pursuit 30151. DK Leap 47482 is a dummy wrapper, so it and its scripted normal/transformed spells 91809/91802 are explicitly classified too.
- No new four-second/tank-collection gate or rush restriction in PvP or solo open world. Existing passive pet policy is retained.

This is deliberately conservative: a target that has not reached a tank, is being kited out of melee, or has switched to a DPS does not pass collection. The 4 seconds are a minimum, not a promise that the next AI tick issues the command at exactly 4.000 seconds.

## Verification and limits

Run `contrib/playerbot_auto_queue_548/test_pet_pull.ps1` from x64 Visual Studio Developer PowerShell. It compiles and runs 30 isolated checks, covering the typed lookup, delay boundary, target/pet changes, reset, collection and clock wrap. These are not a full spell-engine or server integration simulation.

Also rerun `test_pve_rotation.ps1` for the existing 1028 profile/state checks. Compile `worldserver.vcxproj` in `RelWithDebInfo|x64`.

The server is left stopped for the user to start the new build. In-game acceptance still requires repeating a ranged tank pull with hunter/warlock/DK/mage pets, waiting for collection, and exercising DK Pestilence with multiple targets. Passing compilation/isolated tests does not establish that no other crash remains.
