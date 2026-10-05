# The Plains of Nasam tank fixes

Requires migrations 2026_09_27_23 and 2026_09_27_24/25 and matching installed worldserver.

Manual checks (not yet performed in-game):

1. Accept 11652, board Horde Siege Tank, and select an Injured Warsong Mage within 15 yards. Use Rescue Injured Soldier (slot 3). Verify the soldier is healed, thanks the player, disappears without a death animation or corpse, gives exactly one rescued-soldier credit, and respawns visibly after 60 seconds. Repeat for warrior, shaman and engineer. An enemy, out-of-range target or already rescued soldier must give no rescue credit.
2. Two tanks attempt to rescue the same soldier: only the first successful rescue should credit.
3. Select a hostile target within 100 yards with line of sight, fire The Demoralizer, and verify impact at that target position. Try facing away and different camera angles. Clear selection and verify original ground aiming. Dead, friendly, out-of-range and obstructed targets must reject the selected-target cast.
4. Kill Scourge at existing Nasam positions: verify Scourge Unit credit and 30-second respawn. Verify unrelated Scourge outside the bounded Nasam region keep existing respawn settings.
5. Check Meatpounder still works and boarding, movement and dismount work both in Borean Tundra and battlegrounds.

This patch restores rescue and selected-target cannon aim; it does not implement missing landmine, fuel mechanics.

6. Drive the tank into area trigger 4963 around the central structure (2418.66, 6455.67, 54.48; radius 70 yards). Verify Scourge leader identified advances once, including if the client sends no area-trigger event. Stay outside the sphere, leave/re-enter, and use the tank without quest 11652: no premature or duplicate credit. Verify the quest completes only after all three objectives.

7. Reconnect with already saved leader credit (including quest status complete): verify the leader checkbox displays complete without redoing the quest. Verify identification changes no objectives of other active quests.
