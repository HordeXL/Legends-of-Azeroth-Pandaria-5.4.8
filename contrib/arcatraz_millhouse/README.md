# Millhouse assistance in The Arcatraz

The live NPC template sets UNIT_FLAG_IMMUNE_TO_NPC. Both CanStartAttack and
IsValidAttackTarget reject attacks by an NPC carrying this flag, but Millhouse's
script never removed it after preparing. Keep the protection during the intro,
then remove only this flag on readiness, including resets after the intro.

Once ready, Millhouse checks once per second for active later-wave enemies,
Skyriss or his images within 100 yards. Candidates must already be in combat,
alive, attackable and in line of sight. It does not pick players, Mellichar or
unrelated enemies. Repeated target checks preserve his existing chase generator.
The existing preparation dialogue, spell rotation and event progression remain.

Run `python3 contrib/arcatraz_millhouse/run_tests.py` to compile the actual
reset, preparation, attack and assist methods against a small mock encounter.
Tests cover no attacks before readiness, preserving other flags, assisting
beyond normal aggro range, filtering inactive/dead/blocked/unrelated enemies,
retargeting and stopping acquisition after encounter completion.

Build/install worldserver and restart; no database migration is needed.
A new in-game encounter is still needed to verify movement and spell damage.
