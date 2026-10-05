# Evie Stormstout (31077)

Chen 67138 had no script to award objective 65408 (meet Chen) or 62964
(eulogize Evie), leaving the quest turn-in Continue button disabled.

Approaching within 10 yards with the incomplete quest starts a private sequence
using existing localized broadcast texts 62392–62396. Stay within 20 yards until
the dialogue finishes to receive completion credit. Each player has independent
timing. Death, logout, abandonment or leaving cancels the sequence; approach again
to retry. Reset clears listeners. The first line plays after one second and the
remaining lines at five-second intervals, followed by credit after five seconds.

This restores objective progression; it does not recreate the carry/burial scene.
Dialogue timing is reconstructed. The encounter description is documented at
[Warcraft Wiki](https://warcraft.wiki.gg/wiki/Evie_Stormstout_%28quest%29).

Run `python3 contrib/evie_stormstout/run_tests.py` for production callback tests.
Apply `sql/patches/world/2026_09_25_08_world_evie_stormstout.sql`, build with
`make -j16` in `build`, install and restart. A live client test remains necessary.
