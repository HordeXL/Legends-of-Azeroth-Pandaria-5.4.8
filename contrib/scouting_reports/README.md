# Playable Horde scouting reports

Requires world migrations 2026_09_27_11, 2026_09_27_12, 2026_09_27_14 and 2026_09_27_15 plus the matching worldserver build.
Beyond the Horizon (29941) remains the earlier dispatch quest.

The playable sections are reconstructed from the installed spells, NPCs, objectives and spawn coordinates. Original cinematics and complete dialogue are not reproduced. Gameplay has not yet been verified with a client.

## Manual verification

1. Complete The Scouts Return (29971). Accept Hostile Natives (29730) from Riko. Confirm Gorrok starts on the ground eight yards west of the warning sign, can move freely, and the hidden passenger seat presents Gorrok as the controlled character. Approach the warning sign, private jade statue and private Widow Greenpaw within five yards in that order. Proximity triggers inspection/dialogue while controlling Gorrok; right-click remains supported. Verify approaching the statue before reading the sign gives no credit. Verify each objective advances once, in order, and completion returns to Riko.
2. Accept On the Right Track (29731) from Kiryn. Target a Lurking Tiger and use Smoke Bomb. Verify fear and the native delayed Sniper Shot. Reach the Young Alliance Soldier, verify credit, and return to camp.
3. Accept The Friend of My Enemy (29823) from Riko. Use Uppercut and Fling Filth against the two jinyu waves and the Alliance scout. Verify no final credit before all enemies die, then return to Riko.
4. Accept Like Jinyu in a Barrel (29824) from Shokia. Select a private guard and use Sniper Shot. Clear two guard waves, then three barrels, then the escape guards. Verify Kiryn reaches the starting point before escort credit and return to Shokia.
5. Repeat each report using its gossip option after exiting the vehicle. Abandon the quest and exit during each stage; verify every private actor disappears, no completion credit is awarded, and the living player returns to the giver. Repeat after disconnect/reconnect.
6. Run the same report with two players. Verify neither can shoot or receive completion credit from the other player's targets. Invalid or public targets must reject Sniper Shot, Uppercut and Fling Filth.
7. Check the shared warning sign, statue and Greenpaw still serve the Alliance SI:7 report (29726).

The saved target POIs guide Gorrok. Shokia's Sniper Shot ability is the reconstructed click-and-fire control; selecting a target and pressing the ability is required. A lost actor or a blocked final escort route exits without awarding credit so the report can be restarted.

Vehicle 238 has passenger seat 0 (2241) and control seat 1 (2242). All playable report actors must board the player in seat 1; pilot lookup and ability checks use the same seat. Verify the player model is hidden and WASD moves the report actor.

Hostile Natives: repeat with a bot raid group and verify both NPC objectives advance. Revisit completed inspection steps without duplicate dialogue; approach the widow first and verify no credit. Confirm final jade transformation and return after two seconds. Verify missing scene NPCs and failed boarding return to Riko without awarding credit.
