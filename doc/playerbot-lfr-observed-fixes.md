# Follow-up to the observed LFR pull — 2026-09-08

## Evidence

The client combat log segment 14:08:34–14:09:24 and server movement log showed:

- Daristos (Guardian) walking towards ranged-pulled Iron Sentinels before Palstest had collected them, then using Growl. This was ordinary `reach melee`, not a logged Wild Charge cast. `WaitForTankPull` explicitly exempted every tank.
- Sperick using Stealth/Sprint at 14:08:34.614, with first damage only at 14:08:51.314. The generic out-of-melee trigger requested Stealth during an active pull and the old stealth strategy could wait for an opener/position instead of normal builders.
- Baphelle (Elemental) casting Lightning Shield at 14:08:33.394 and replacing it with Water Shield at 14:08:34.832. Combat and noncombat Elemental factory branches still selected `bmana`.
- No Kill Command from Berinny. Its old action targeted `pet target`, whose value is the pet itself, rather than the enemy.
- No Starfall from Adalain, and no Mangle/Thrash from Daristos. Matching by spell name alone did not distinguish cat/bear variants; Starfall safety also treated undotted neighbouring packs as potential targets despite Guided Stars.

The missing casts identify paths requiring correction, not proof that each one explains the entire DPS difference. The screenshot is sorted by total damage; role, pet damage and active time must also be considered. Geronie's lower total alone did not justify an arbitrary damage multiplier or another unproven rotation rewrite.

## Changes

1. **Pull tank:** purple diamond takes precedence; otherwise a same-map real tank master, then the group's tank leader. The secondary tank waits for the target to reach that tank's melee range. It may defend itself locally or take over when the designated tank dies. The same anchor governs bot taunts, so Growl cannot pull an enemy away from a living real tank merely because no diamond was assigned. No automatic icon changes or encounter tank-swap automation.
2. **Rogue:** do not enter Stealth during an authorized live pull. Keep the normal PvE DPS strategy available while stealthed. Once in melee with the engaged target, try a legal Ambush/Garrote; if neither is possible, remove ordinary Stealth rather than stall. This does not remove Shadow Dance or redesign PvP stealth strategy. Existing hostile-target and melee-range checks remain.
3. **Shaman:** Elemental group-PvE combat and noncombat strategies use the DPS shield. Shield triggers independently enforce Restoration -> Water Shield and DPS -> Lightning Shield so competing strategies cannot alternate them. Existing preparation already made this choice and is retained.
4. **Hunter:** group-PvE Kill Command targets the enemy, not the pet. It requires the pet already attacking that enemy in melee and the existing delayed-pull gate to pass; it cannot substitute for the four-second wait by charging the pet into the pull.
5. **Druid forms:** group-PvE Mangle/Swipe/Thrash name resolution filters learned candidates through the core's `CheckShapeshift` for the intended Guardian/Feral form. No spell is taught or allowed to bypass cast checks. Local DBCs contain distinct form masks for 33876/33878, 62078/779, 106830/77758.
6. **Starfall:** use the caster as its group-PvE cast target and area centre; do not spam an already active aura. With Guided Stars 146655, the area safety check excludes enemies without this caster's Moonfire/Sunfire, matching `spell_dru_starfall_damage`. Checks for engagement, CC and tank collection still apply to eligible enemies. No blanket removal of AoE safety.

PvP talent profiles and PvP rotation branches are not changed by these follow-up fixes.

## Verification

- Successful `worldserver.vcxproj` build for `RelWithDebInfo|x64`.
- `test_lfr_observed.ps1`: 25 checks with exact production function bodies and lightweight mocks for pull-tank selection, secondary-tank movement and Kill Command. Includes dead tank, diamond priority, missing target/pet, range, wrong map and PvP cases. The runner rejects stale copied bodies.
- Existing `test_pve_rotation.ps1`: 1028 checks passed; `test_pet_pull.ps1`: 30 checks passed.
- `audit_pve_rotation.ps1 -CheckDbc`: validates spell/glyph IDs, aliases and six druid form masks against local 5.4.8 DBCs. This does not simulate the live spell scheduler.

The user stopped worldserver before deployment. It is left stopped; no client session, character inventory or database was altered for the test. Live validation is still required: repeat ranged pulls, then record longer single-target and gathered-pack fights. Confirm the off-tank stays back, rogue begins promptly, Elemental keeps Lightning Shield, and Mangle/Thrash/Starfall/Kill Command appear when their normal conditions permit. These changes do not claim equal or optimal DPS across classes.
