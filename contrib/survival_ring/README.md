# Survival Ring: Flame and Blades

The installed world data had controller 58953, twelve trainers 58744 and ring
posts, but no creature or spell scripts for either quest. Controller 65287 was
not spawned. Both quests now use the existing shared ring without adding spawns.

The controller starts a private progress aura for an eligible, living, unmounted
player inside the ring. The 5.4.8 power bars (112836/127386) both have a 60-point
maximum; progress reaches credit 58967/64895 after 60 uninterrupted seconds.
Leaving the ring, dying, mounting, flying or dropping the quest removes the aura.
A fresh attempt starts at zero. Players do not share timers or completion credit.

Flame uses native trainer firework missile 112875 and impact 112041; impact target
filtering excludes spectators. Blades uses the existing interior posts, native
8%-health spell 127393 within 3.5 yards, and trainers roaming within the ring with
contact knockback. These hazard distances are script parameters and require
live-client verification against the displayed objects. Ready for Raiding III
achievement behavior is outside this change.

Apply `sql/patches/world/2026_09_25_05_world_survival_ring.sql` together with the
code update, then restart worldserver. The installation archive contains the
same database changes. No existing rows or spawns are removed.

Run `python3 contrib/survival_ring/run_tests.py`. It compiles production eligibility,
timer and impact-filter logic with stand-ins. Test in game with each quest, two
players entering at different times, and exiting/remounting before 60 seconds.

The progress aura must have a finite duration: this core calls OnAuraUpdate only
while m_duration is positive. Aura updates have no AuraApplication, so the script
uses GetUnitOwner instead of GetTarget. The apply hook resets previously saved
indefinite attempts to 60 seconds. Regression coverage includes the actual core
duration-dispatch block and the recovery of an old indefinite aura.
